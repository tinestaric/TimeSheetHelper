pageextension 50101 "TimeSheet Card Ext" extends "Time Sheet Card"
{
    actions
    {
        addlast(Prompting)
        {
            action(CopilotTimeEntry)
            {
                ApplicationArea = All;
                Caption = 'Draft with Copilot';
                ToolTip = 'Use AI to help you enter time based on your description';
                Image = SparkleFilled;

                trigger OnAction()
                var
                    ExtractTimeSheetEntries: Page "Extract Time Sheet Entries";
                begin
                    ExtractTimeSheetEntries.SetTimeSheet(Rec);
                    ExtractTimeSheetEntries.LookupMode := true;
                    if ExtractTimeSheetEntries.RunModal() = Action::LookupOK then
                        CurrPage.Update();
                end;
            }

            action(CopilotTimeProposal)
            {
                ApplicationArea = All;
                Caption = 'Propose with Copilot';
                ToolTip = 'Use AI to propose time entries based on your historic timesheet patterns';
                Image = SparkleFilled;

                trigger OnAction()
                var
                    ProposeTimeSheetEntries: Page "Propose Time Sheet Entries";
                begin
                    ProposeTimeSheetEntries.SetTimeSheet(Rec);
                    if ProposeTimeSheetEntries.RunModal() = Action::LookupOK then
                        CurrPage.Update();
                end;
            }

            action(CopilotTimeSummary)
            {
                ApplicationArea = All;
                Caption = 'Generate Summary';
                ToolTip = 'Use AI to generate a summary of your timesheet entries';
                Image = SparkleFilled;

                trigger OnAction()
                var
                    GenerateTimesheetSummary: Page "Generate Timesheet Summary";
                begin
                    GenerateTimesheetSummary.SetTimeSheet(Rec."No.");
                    GenerateTimesheetSummary.RunModal();
                end;
            }
        }
        addlast(Category_Category7)
        {
            actionref(CopilotTimeEntry_Promoted; CopilotTimeEntry) { }
            actionref(CopilotTimeProposal_Promoted; CopilotTimeProposal) { }
            actionref(CopilotTimeSummary_Promoted; CopilotTimeSummary) { }
        }
    }
}