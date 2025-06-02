codeunit 50102 "Propose Time Sheet Entries"
{
    /// <summary>
    /// Proposes time sheet entries based on historic time sheets using AI.
    /// </summary>
    /// <param name="GenerationBuffer">Buffer record to store generation metadata and input text.</param>
    /// <param name="TimeSheetEntrySuggestion">Record to store the generated time sheet entry suggestions.</param>
    /// <param name="InputText">User's description of the time spent.</param>
    /// <param name="TimeSheet">Time sheet header containing date constraints for the entries.</param>
    procedure Propose(
        var GenerationBuffer: Record "Generation Buffer";
        var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        InputText: Text;
        TimeSheet: Record "Time Sheet Header"
    )
    var
        Completion: Text;
        SystemPromptTxt: Text;
    begin
        SystemPromptTxt := GetSystemPrompt(TimeSheet);

        Completion := GenerateTimeEntries(SystemPromptTxt, InputText, TimeSheet."Resource No.");
        SaveGenerationHistory(GenerationBuffer, InputText);
        CreateTimeSheetSuggestions(Completion, TimeSheetEntrySuggestion, GenerationBuffer."Generation ID");
    end;

    [NonDebuggable]
    local procedure GenerateTimeEntries(SystemPromptTxt: Text; InputText: Text; ResourceNo: Code[20]): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        CompletionAnswerTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::TimesheetHistoricProposal) then
            exit;

        AzureOpenAI.SetAuthorization("AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability("Copilot Capability"::TimesheetHistoricProposal);

        //TODO: Specify AOAI Chat Completion Params

        //TODO: Add System and User Prompts

        //TODO: Setup a Tool (call SetResourceNo), add it to the messages and set the invoke preference

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            CompletionAnswerTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(CompletionAnswerTxt);
    end;

    local procedure SaveGenerationHistory(var GenerationId: Record "Generation Buffer"; InputText: Text)
    begin
        GenerationId."Generation ID" += 1;
        GenerationId.SetInputText(InputText);
        GenerationId.Insert(true);
    end;

    local procedure CreateTimeSheetSuggestions(TimeEntriesJson: Text; var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion"; GenerationId: Integer)
    var
        TimeEntry: JsonToken;
        JTimeEntries: JsonObject;
        EntryObject: JsonObject;
        LineNo: Integer;
        OutStream: OutStream;
    begin
        LineNo := 10000;

        JTimeEntries.ReadFrom(TimeEntriesJson);
        foreach TimeEntry in JTimeEntries.GetArray('timeEntries', true) do begin
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
        LineNoOffset: Integer;
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        if TimeSheetLine.FindLast() then
            LineNoOffset := TimeSheetLine."Line No.";

        if TimeSheetEntrySuggestion.FindSet() then
            repeat
                TimeSheetLine.Init();
                TimeSheetLine."Time Sheet No." := TimeSheetNo;
                TimeSheetLine."Line No." := TimeSheetEntrySuggestion.LineNo + LineNoOffset;
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

    local procedure GetSystemPrompt(TimeSheet: Record "Time Sheet Header") Prompt: Text
    begin
        // TODO: Modify this prompt to instruct the AI to use the retrieve_timesheets function when historic data is needed
        Prompt := @'You are a business time tracking assistant.

The user will provide a description of how they want to track their time, which may include:
1. Unstructured descriptions of activities they performed
2. Requests to suggest entries based on their historic timesheet patterns

Your task is to:
1. Break down descriptions into discrete work activities
2. Convert each activity into a properly formatted timesheet entry
3. Generate suggestions that align with work patterns
4. Return entries as a JSON array

Follow these rules:
- Split activities into logical units of work
- Estimate reasonable hours for each activity (0.5 - 8 hours per activity)
- Use realistic project names that would make sense in a business context
- Identify appropriate tasks for each project
- Categorize each entry (Meeting, Development, Analysis, etc.)
- All entries must have dates between ';
        Prompt += Format(TimeSheet."Starting Date") + ' and ' + Format(TimeSheet."Ending Date") + '.';
        Prompt += @' If no date is specified, use a date within this timeframe

Response format:
{
  "timeEntries": [
    {
      "type": "Meeting|Development|Analysis|Documentation|Support|Other",
      "description": "Brief description of the activity",
      "project": "Project identifier/name",
      "task": "Specific task within the project", 
      "hours": 1.5,
      "date": "YYYY-MM-DD"
    }
  ]
}';
    end;

    local procedure GetEndpoint(): Text
    var
        CompanialAOAISecrets: Codeunit "Companial AOAI Secrets";
    begin
        exit(CompanialAOAISecrets.GetEndpoint());
    end;

    local procedure GetDeployment(): Text
    begin
        exit(Format(Enum::"Companial AOAI Model"::o3));
    end;

    local procedure GetSecret(): SecretText
    var
        CompanialAOAISecrets: Codeunit "Companial AOAI Secrets";
    begin
        exit(CompanialAOAISecrets.GetSecret());
    end;
}

