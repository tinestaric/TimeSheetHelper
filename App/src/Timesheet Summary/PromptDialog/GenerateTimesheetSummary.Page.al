page 50107 "Generate Timesheet Summary"
{
    Caption = 'Generate Timesheet Summary with Copilot';
    PageType = PromptDialog;
    PromptMode = Prompt;
    ApplicationArea = All;
    Editable = true;
    Extensible = false;
    SourceTable = "Generation Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Prompt)
        {
            // Properties to keep in mind: MultiLine, ShowCaption, InstructionalText
        }
        area(Content)
        {

        }
    }

    actions
    {
        //TODO: Add Actions to generate, regenerate, cancel and accept (Ok)
        // the generate and regenerate should call the GenerateSummary procedures
        // the cancel should just close the page
        // the accept should close the page and return the summary content
    }

    var
        TimeSheetLine: Record "Time Sheet Line";
        TimesheetSummary: Record "Timesheet Summary";
        TimeSheetNo: Code[20];
        InstructionsInput: Text;
        SummaryContent: Text;

    trigger OnAfterGetCurrRecord()
    begin
        LoadSummary();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            Message(SummaryContent);
    end;

    local procedure GenerateSummary()
    var
        GenerateTimeSheetSummary: Codeunit "Generate TimeSheet Summary";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);

        if not TimeSheetLine.FindSet() then
            Error('No timesheet entries found for the selected timesheet');

        GenerateTimeSheetSummary.Generate(Rec, TimesheetSummary, TimeSheetLine, InstructionsInput);

        LoadSummary();
    end;

    local procedure LoadSummary()
    begin
        if TimesheetSummary.Get(Rec."Generation ID") then
            SummaryContent := TimesheetSummary.GetContent()
        else
            SummaryContent := '';
    end;

    procedure SetTimeSheet(NewTimeSheetNo: Code[20])
    begin
        TimeSheetNo := NewTimeSheetNo;
    end;
}
