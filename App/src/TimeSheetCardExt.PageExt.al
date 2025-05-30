pageextension 50101 "TimeSheet Card Ext" extends "Time Sheet Card"
{
    actions
    {
        addlast(Prompting)
        {
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
            actionref(CopilotTimeSummary_Promoted; CopilotTimeSummary) { }
        }
    }
}