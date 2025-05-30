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
            field(Instructions; InstructionsInput)
            {
                MultiLine = true;
                ShowCaption = false;
                InstructionalText = 'Specify any additional instructions for your summary';
            }
        }

        area(Content)
        {
            group(Summary)
            {
                Caption = 'Generated Summary';

                field(SummaryText; SummaryContent)
                {
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'The generated summary of your timesheet entries';
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Tooltip = 'Generate summary based on your timesheet entries';
                trigger OnAction()
                begin
                    GenerateSummary();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                Tooltip = 'Regenerate summary with your instructions';
                trigger OnAction()
                begin
                    GenerateSummary();
                end;
            }
            systemaction(Cancel)
            {
                ToolTip = 'Discard the summary and close the dialog';
            }
            systemaction(Ok)
            {
                Caption = 'Accept';
                ToolTip = 'Accept the summary and close the dialog';
            }
        }
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
