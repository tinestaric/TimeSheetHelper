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
        AOAIToken: Codeunit "AOAI Token";
        CompletePromptTokenCount: Integer;
        Completion: Text;
        SystemPromptTxt: Text;
    begin
        SystemPromptTxt := GetSystemPrompt(TimeSheetLine);

        CompletePromptTokenCount := AOAIToken.GetGPT4TokenCount(SystemPromptTxt) + AOAIToken.GetGPT4TokenCount(InputText);
        if CompletePromptTokenCount <= MaxInputTokens() then begin
            Completion := GenerateSummary(SystemPromptTxt, InputText);
            SaveGenerationHistory(GenerationBuffer, InputText);
            SaveTimesheetSummary(Completion, TimesheetSummary);
        end;
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
        AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
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

    local procedure SaveTimesheetSummary(SummaryText: Text; var TimesheetSummary: Record "Timesheet Summary")
    var
        GenerationId: Integer;
    begin
        // Find the next generation ID
        TimesheetSummary.Reset();
        if TimesheetSummary.FindLast() then
            GenerationId := TimesheetSummary.GenerationId + 1
        else
            GenerationId := 1;

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

        Prompt := @'You are a business time tracking assistant.

Below is a list of time sheet entries:

';
        Prompt += TimeSheetEntriesList;
        Prompt += @'

Your task is to:
1. Create a concise summary of the work completed
2. Group activities by project when possible
3. Highlight key accomplishments
4. Format the summary in a professional style suitable for reporting to management

Your summary should:
- Be between 3-5 paragraphs
- Avoid unnecessary details while capturing the essence of the work
- Use professional business language
- Be written in the first person
- Include approximate total hours spent if that information is available

The user may provide preferences for how the summary should be generated. If they do, please adjust your summary accordingly.';

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
    begin
        exit('https://bcaihackathon.openai.azure.com/');
    end;

    local procedure GetDeployment(): Text
    begin
        exit('gpt-4o');
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
        exit(1500);
    end;

    local procedure MaxModelTokens(): Integer
    begin
        exit(4096); //GPT 4o
    end;
}
