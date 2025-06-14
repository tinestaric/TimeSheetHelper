codeunit 50100 "Register Capability"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://example.com/CopilotToolkit', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered("Copilot Capability"::TimesheetEntryExtraction) then
            CopilotCapability.RegisterCapability("Copilot Capability"::TimesheetEntryExtraction, LearnMoreUrlTxt);

        if not CopilotCapability.IsCapabilityRegistered("Copilot Capability"::TimesheetSummarization) then
            CopilotCapability.RegisterCapability("Copilot Capability"::TimesheetSummarization, LearnMoreUrlTxt);

        if not CopilotCapability.IsCapabilityRegistered("Copilot Capability"::TimesheetHistoricProposal) then
            CopilotCapability.RegisterCapability("Copilot Capability"::TimesheetHistoricProposal, LearnMoreUrlTxt);
    end;
}