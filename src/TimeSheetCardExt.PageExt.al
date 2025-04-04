pageextension 50101 "TimeSheet Card Ext" extends "Time Sheet Card"
{
    actions
    {
        addlast(Processing)
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
                    ExtractTimeSheetEntries.SetTimeSheet(Rec."No.");
                    ExtractTimeSheetEntries.LookupMode := true;
                    if ExtractTimeSheetEntries.RunModal() = Action::LookupOK then
                        CurrPage.Update();
                end;
            }
        }
        addlast(Category_Category7)
        {
            actionref(CopilotTimeEntry_Promoted; CopilotTimeEntry) { }
        }
    }
}