codeunit 50107 "Generate TimeSheet Summary"
{
    /// <summary>
    /// Generates a summary of time sheet entries using the LLM.
    /// </summary>
    /// <param name="GenerationBuffer">The generation buffer to save the input text.</param>
    /// <param name="TimesheetSummary">The timesheet summary record to store the result.</param>
    /// <param name="TimeSheetEntries">The time sheet entries to summarize.</param>
    procedure Generate(
        var GenerationBuffer: Record "Generation Buffer";
        var TimesheetSummary: Record "Timesheet Summary";
        var TimeSheetLine: Record "Time Sheet Line";
        InputText: Text
    )
    var
        Completion: Text;
        SystemPromptTxt: Text;
    begin
        SystemPromptTxt := GetSystemPrompt(TimeSheetLine);

        Completion := GenerateSummary(SystemPromptTxt, InputText);
        SaveGenerationHistory(GenerationBuffer, InputText);
        SaveTimesheetSummary(Completion, TimesheetSummary, GenerationBuffer."Generation ID");
    end;

    [NonDebuggable]
    local procedure GenerateSummary(SystemPromptTxt: Text; UserInput: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        CompletionAnswerTxt: Text;
    begin
        // TODO: Only execute if the capability is enabled. Check using the AzureOpenAI Codeunit

        AzureOpenAI.SetAuthorization("AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        // TODO: Set the capability

        // TODO: Set the max tokens and temperature

        // TODO: Add the system prompt and user input to the chat messages

        // TODO: Generate the chat completion

        if AOAIOperationResponse.IsSuccess() then
            CompletionAnswerTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(CompletionAnswerTxt);
    end;

    local procedure SaveTimesheetSummary(SummaryText: Text; var TimesheetSummary: Record "Timesheet Summary"; GenerationId: Integer)
    begin
        TimesheetSummary.Init();
        TimesheetSummary.GenerationId := GenerationId;
        TimesheetSummary.SetContent(SummaryText);
        TimesheetSummary.Insert(true);
    end;

    local procedure SaveGenerationHistory(var GenerationBuffer: Record "Generation Buffer"; InputText: Text)
    begin
        GenerationBuffer."Generation ID" += 1;
        GenerationBuffer.SetInputText(InputText);
        GenerationBuffer.Insert(true);
    end;

    local procedure GetSystemPrompt(var TimeSheetLine: Record "Time Sheet Line") Prompt: Text
    var
        TimeSheetEntriesList: Text;
    begin
        TimeSheetEntriesList := ListTimeSheetEntries(TimeSheetLine);

        // TODO: Set the system prompt
        Prompt := @'This is the first part
of a multi line
prompt.

';
        Prompt += 'Then I could add something additional here. Like a list of something ;)';
        Prompt += @'
And this is 
the second part
of a multiline prompt';

        exit(Prompt);
    end;

    local procedure ListTimeSheetEntries(var TimeSheetLine: Record "Time Sheet Line"): Text
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetLineTxt: Text;
        TextBuilder: TextBuilder;
    begin
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetDetail.Reset();
                TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
                TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");

                if TimeSheetDetail.FindSet() then
                    repeat
                        TextBuilder.Append('Type: ' + Format(TimeSheetLine.Type));
                        TextBuilder.Append(', Description: ' + TimeSheetLine.Description);
                        TextBuilder.Append(', Work Type Code: ' + TimeSheetLine."Work Type Code");
                        TextBuilder.Append(', Date: ' + Format(TimeSheetDetail.Date));
                        TextBuilder.Append(', Quantity: ' + Format(TimeSheetDetail.Quantity));
                        TextBuilder.AppendLine();
                    until TimeSheetDetail.Next() = 0;
            until TimeSheetLine.Next() = 0;

        TimeSheetLineTxt := TextBuilder.ToText();
        exit(TimeSheetLineTxt);
    end;

    local procedure GetEndpoint(): Text
    var
        CompanialAOAISecrets: Codeunit "Companial AOAI Secrets";
    begin
        exit(CompanialAOAISecrets.GetEndpoint());
    end;

    local procedure GetDeployment(): Text
    begin
        exit(Format(Enum::"Companial AOAI Model"::"gpt-4o"));
    end;

    local procedure GetSecret(): SecretText
    var
        CompanialAOAISecrets: Codeunit "Companial AOAI Secrets";
    begin
        exit(CompanialAOAISecrets.GetSecret());
    end;
}
