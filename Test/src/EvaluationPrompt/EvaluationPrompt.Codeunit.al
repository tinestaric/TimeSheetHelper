codeunit 60149 "Evaluation Prompt"
{
    /// <summary>
    /// Evaluates an AI completion against a list of expected terms.
    /// </summary>
    /// <param name="Completion">The completion text to evaluate.</param>
    /// <param name="ExpectedTerms">A comma-separated list of terms that should be present in the completion.</param>
    /// <returns>Boolean indicating whether the completion meets the expectations.</returns>
    procedure Evaluate(Completion: Text; ExpectedTerms: Text): Boolean
    var
        EvaluationResult: Record "Evaluation Result";
    begin
        exit(EvaluateWithResult(Completion, ExpectedTerms, EvaluationResult));
    end;

    /// <summary>
    /// Evaluates an AI completion against a list of expected terms and returns detailed results.
    /// </summary>
    /// <param name="Completion">The completion text to evaluate.</param>
    /// <param name="ExpectedTerms">A comma-separated list of terms that should be present in the completion.</param>
    /// <param name="EvaluationResult">Record to store the evaluation result and explanation.</param>
    /// <returns>Boolean indicating whether the completion meets the expectations.</returns>
    procedure EvaluateWithResult(Completion: Text; ExpectedTerms: Text; var EvaluationResult: Record "Evaluation Result"): Boolean
    var
        Response: Text;
    begin
        Response := GenerateEvaluation(Completion, ExpectedTerms);
        ParseEvaluationResponse(Response, EvaluationResult);
        exit(EvaluationResult.Success);
    end;

    [NonDebuggable]
    local procedure GenerateEvaluation(Completion: Text; ExpectedTerms: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        SystemPromptTxt: Text;
        UserPromptTxt: Text;
        EvaluationResponseTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::ContentEvaluation) then
            exit;

        AzureOpenAI.SetAuthorization("AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability("Copilot Capability"::ContentEvaluation);

        AOAIChatCompletionParams.SetMaxTokens(2500);
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);

        SystemPromptTxt := GetSystemPrompt();
        UserPromptTxt := GetUserPrompt(Completion, ExpectedTerms);

        AOAIChatMessages.AddSystemMessage(SystemPromptTxt);
        AOAIChatMessages.AddUserMessage(UserPromptTxt);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            EvaluationResponseTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(EvaluationResponseTxt);
    end;

    local procedure ParseEvaluationResponse(ResponseJson: Text; var EvaluationResult: Record "Evaluation Result")
    var
        JResponse: JsonObject;
        JToken: JsonToken;
        Success: Boolean;
        Explanation: Text;
    begin
        JResponse.ReadFrom(ResponseJson);

        if JResponse.Get('success', JToken) then
            Success := JToken.AsValue().AsBoolean();

        if JResponse.Get('explanation', JToken) then
            Explanation := JToken.AsValue().AsText();

        EvaluationResult.Init();
        EvaluationResult."Evaluation ID" := CreateGuid();
        EvaluationResult.Success := Success;
        EvaluationResult.Explanation := CopyStr(Explanation, 1, 2048);
        EvaluationResult.Insert(true);
    end;

    local procedure GetSystemPrompt() Prompt: Text
    begin
        Prompt := @'You are an AI evaluation assistant. Your job is to evaluate if a completion includes all expected terms or concepts.

Follow these rules:
1. Carefully analyze the completion to check if it addresses all the expected terms
2. Look for semantic equivalents if exact terms are not present
3. Be precise and thorough in your evaluation
4. Return a JSON response with your evaluation

Response format:
{
  "success": true/false,
  "explanation": "A clear explanation of why the completion passed or failed, referencing which terms were missing if applicable"
}';
    end;

    local procedure GetUserPrompt(Completion: Text; ExpectedTerms: Text) Prompt: Text
    begin
        Prompt := 'Completion to evaluate: ' + Completion + '\n\n';
        Prompt += 'Expected terms (comma separated): ' + ExpectedTerms + '\n\n';
        Prompt += 'Please evaluate if this completion adequately addresses all the expected terms.';
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
