codeunit 50107 "Generate TimeSheet Summary"
{
    /// <summary>
    /// Generates a summary of time sheet entries using the LLM.
    /// </summary>
    /// <param name="GenerationBuffer">The generation buffer to save the input text and track generation history.</param>
    /// <param name="TimesheetSummary">The timesheet summary record to store the generated summary.</param>
    /// <param name="TimeSheetLine">The time sheet lines to include in the summary generation context.</param>
    /// <param name="InputText">Additional context or instructions for the summary generation.</param>
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
        //Only for study purposes with reasoning models
        // Completion := GenerateSummaryWithoutToolkit(SystemPromptTxt, InputText); 
        SaveGenerationHistory(GenerationBuffer, InputText);
        SaveTimesheetSummary(Completion, TimesheetSummary, GenerationBuffer."Generation ID");
    end;

    [NonDebuggable]
    local procedure GenerateSummary(SystemPromptTxt: Text; TimeSheetEntries: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        CompletionAnswerTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::TimesheetSummarization) then
            exit;

        AzureOpenAI.SetAuthorization("AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability("Copilot Capability"::TimesheetSummarization);

        AOAIChatCompletionParams.SetMaxTokens(2500);
        AOAIChatCompletionParams.SetTemperature(1);

        AOAIChatMessages.AddSystemMessage(SystemPromptTxt);
        AOAIChatMessages.AddUserMessage(TimeSheetEntries);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            CompletionAnswerTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(CompletionAnswerTxt);
    end;

    [NonDebuggable]
    local procedure GenerateSummaryWithoutToolkit(SystemPromptTxt: Text; TimeSheetEntries: Text): Text
    var
        CompanialAOAIRequest: Codeunit "Companial AOAI Request";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        ResponseText: Text;
    begin
        // Set up the chat completion parameters
        AOAIChatCompletionParams.SetMaxTokens(2500);
        AOAIChatCompletionParams.SetTemperature(1);

        // Configure the request
        CompanialAOAIRequest.SetSystemPrompt(SystemPromptTxt);
        CompanialAOAIRequest.SetUserPrompt(TimeSheetEntries);
        CompanialAOAIRequest.SetChatCompletionParams(AOAIChatCompletionParams);
        CompanialAOAIRequest.SetModel(Enum::"Companial AOAI Model"::"o3");

        // Send the request
        if not CompanialAOAIRequest.Send(ResponseText) then
            Error('Failed to generate summary: %1', CompanialAOAIRequest.GetErrorMessage());

        // Return the parsed message content
        exit(CompanialAOAIRequest.GetMessageContent());
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

        Prompt := @'This is the first part
of a multiline prompt.

';
        Prompt += 'This is where I can add some more details';
        Prompt += @'
And this is the second part of 
a multiline prompt.

Replace this with the actual prompt
';

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
