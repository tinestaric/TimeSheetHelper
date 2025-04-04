codeunit 50101 "Extract Time Sheet Entries"
{
    /// <summary>
    /// Extracts time sheet entries from a description using the LLM.
    /// </summary>
    /// <param name="GenerationBuffer">The generation buffer to save the input text.</param>
    /// <param name="InputText">The description of the time spent.</param>
    /// <returns>The time sheet entries as a JSON array.</returns>
    procedure Extract(
        GenerationBuffer: Record "Generation Buffer";
        var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        InputText: Text
    )
    var
        AOAIToken: Codeunit "AOAI Token";
        CompletePromptTokenCount: Integer;
        Completion: Text;
        SystemPromptTxt: Text;
    begin
        SystemPromptTxt := GetSystemPrompt();

        CompletePromptTokenCount := AOAIToken.GetGPT4TokenCount(SystemPromptTxt) + AOAIToken.GetGPT4TokenCount(InputText);
        if CompletePromptTokenCount <= MaxInputTokens() then begin
            Completion := GenerateTimeEntries(SystemPromptTxt, InputText);
            SaveGenerationHistory(GenerationBuffer, InputText);
            CreateTimeEntryProposals(Completion, TimeSheetEntrySuggestion);
        end;
    end;

    [NonDebuggable]
    local procedure GenerateTimeEntries(SystemPromptTxt: Text; InputText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        CompletionAnswerTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::TimesheetEntryExtraction) then
            exit;

        AzureOpenAI.SetAuthorization("AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability("Copilot Capability"::TimesheetEntryExtraction);
        AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);
        AOAIChatMessages.AddSystemMessage(SystemPromptTxt);
        AOAIChatMessages.AddUserMessage(InputText);
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if AOAIOperationResponse.IsSuccess() then
            CompletionAnswerTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(CompletionAnswerTxt);
    end;

    local procedure CreateTimeEntryProposals(TimeEntriesJson: Text; var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion")
    var
        JsonObject: JsonObject;
        TimeEntriesArray: JsonArray;
        JsonToken: JsonToken;
        GenerationId: Integer;
    begin
        // Find the next generation ID
        TimeSheetEntrySuggestion.Reset();
        if TimeSheetEntrySuggestion.FindLast() then
            GenerationId := TimeSheetEntrySuggestion.GenerationId + 1
        else
            GenerationId := 1;

        if JsonObject.ReadFrom(TimeEntriesJson) then
            if JsonObject.Get('timeEntries', JsonToken) then
                TimeEntriesArray := JsonToken.AsArray();

        CreateTimeSheetSuggestions(TimeEntriesArray, TimeEntriesJson, GenerationId);
    end;

    local procedure SaveGenerationHistory(var GenerationId: Record "Generation Buffer"; InputText: Text)
    begin
        GenerationId."Generation ID" += 1;
        GenerationId.SetInputText(InputText);
        GenerationId.Insert(true);
    end;

    local procedure CreateTimeSheetSuggestions(TimeEntriesArray: JsonArray; TimeEntriesJson: Text; GenerationId: Integer)
    var
        TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        TimeEntry: JsonToken;
        EntryObject: JsonObject;
        LineNo: Integer;
        OutStream: OutStream;
    begin
        // Start line numbers at 10000
        LineNo := 10000;

        foreach TimeEntry in TimeEntriesArray do begin
            EntryObject := TimeEntry.AsObject();

            // Create entry suggestion
            TimeSheetEntrySuggestion.Init();
            TimeSheetEntrySuggestion.GenerationId := GenerationId;
            TimeSheetEntrySuggestion.LineNo := LineNo;
            TimeSheetEntrySuggestion.Description := CopyStr(EntryObject.GetText('description', true), 1, 100);
            TimeSheetEntrySuggestion."Project No." := CopyStr(EntryObject.GetText('project', true), 1, 20);
            TimeSheetEntrySuggestion."Task No." := CopyStr(EntryObject.GetText('task', true), 1, 20);
            TimeSheetEntrySuggestion.Hours := EntryObject.GetDecimal('hours', true);
            TimeSheetEntrySuggestion.EntryDate := EntryObject.GetDate('date', true);
            TimeSheetEntrySuggestion.EntryType := CopyStr(EntryObject.GetText('type', true), 1, 250);

            // Store JSON as blob to avoid text size limitations
            TimeSheetEntrySuggestion.GeneratedTimeEntriesJson.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(TimeEntriesJson);

            TimeSheetEntrySuggestion.Insert(false);

            LineNo += 10000;
        end;
    end;

    /// <summary>
    /// Applies the proposed time entries to the time sheet.
    /// </summary>
    /// <param name="TimeSheetEntrySuggestion">The time sheet entry suggestions to apply.</param>
    /// <param name="TimeSheetNo">The time sheet to apply the entries to.</param>
    procedure ApplyProposedTimeEntries(var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion"; TimeSheetNo: Code[20])
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        if TimeSheetEntrySuggestion.FindSet() then
            repeat
                TimeSheetLine.Init();
                TimeSheetLine."Time Sheet No." := TimeSheetNo;
                TimeSheetLine."Line No." := TimeSheetEntrySuggestion.LineNo;
                TimeSheetLine.Type := TimeSheetLine.Type::Job;
                TimeSheetLine.Description := TimeSheetEntrySuggestion.Description;
                TimeSheetLine."Job No." := TimeSheetEntrySuggestion."Project No.";
                TimeSheetLine."Job Task No." := TimeSheetEntrySuggestion."Task No.";
                TimeSheetLine.Insert(false);

                TimeSheetDetail.Init();
                TimeSheetDetail."Time Sheet No." := TimeSheetLine."Time Sheet No.";
                TimeSheetDetail."Time Sheet Line No." := TimeSheetLine."Line No.";
                TimeSheetDetail.Date := TimeSheetEntrySuggestion.EntryDate;
                TimeSheetDetail.Quantity := TimeSheetEntrySuggestion.Hours;
                TimeSheetDetail.Insert(false);
            until TimeSheetEntrySuggestion.Next() = 0;
    end;

    local procedure GetSystemPrompt(): Text
    begin
        exit(@'You are a business time tracking assistant.

The user will provide an unstructured description of how they spent their time. Your task is to:
1. Break down this description into discrete work activities
2. Convert each activity into a properly formatted timesheet entry
3. Return the entries as a JSON array

Follow these rules:
- Split activities into logical units of work
- Estimate reasonable hours for each activity (0.5 - 8 hours per activity)
- Use project names that would make sense in a business context
- Identify appropriate tasks for each project
- Categorize each entry (Meeting, Development, Analysis, etc.)
- Use today''s date if no date is specified

Response format:
{
  "timeEntries": [
    {
      "type": "Meeting|Development|Analysis|Documentation|Support|Other",
      "description": "Brief description of the activity",
      "project": "Project identifier/name",
      "task": "Specific task within the project",
      "hours": 1.5,
      "date": "MM/DD/YYYY"
    }
  ]
}');
    end;

    local procedure GetEndpoint(): Text
    begin
        exit('https://bcaihackathon.openai.azure.com/');
    end;

    local procedure GetDeployment(): Text
    begin
        exit('gpt-35-turbo');
    end;

    [NonDebuggable]
    local procedure GetSecret(): Text
    begin
        exit('REMOVED_SECRET');
    end;

    local procedure MaxInputTokens(): Integer
    begin
        exit(MaxModelTokens() - MaxOutputTokens());
    end;

    local procedure MaxOutputTokens(): Integer
    begin
        exit(2500);
    end;

    local procedure MaxModelTokens(): Integer
    begin
        exit(4096); //GPT 3.5 Turbo
    end;
}