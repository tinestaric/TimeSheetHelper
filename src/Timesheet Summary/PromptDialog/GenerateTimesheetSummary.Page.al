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
                Caption = 'Additional instructions (optional)';
                MultiLine = true;
                ToolTip = 'Provide any specific requirements for your summary';
            }
        }

        area(Content)
        {
            group(Summary)
            {
                Caption = 'Generated Summary';

                field(SummaryText; SummaryContent)
                {
                    Caption = '';
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
                Caption = 'Copy to Clipboard';
                ToolTip = 'Copy the summary to clipboard and close';
            }
        }
    }

    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetNo: Code[20];
        InstructionsInput: Text;
        SummaryContent: Text;
        CurrentGenerationId: Integer;

    trigger OnAfterGetCurrRecord()
    begin
        LoadSummary(CurrentGenerationId);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = CloseAction::OK then
            Message(SummaryContent);
    end;

    local procedure GenerateSummary()
    var
        TimesheetSummary: Record "Timesheet Summary";
        GenerateTimeSheetSummary: Codeunit "Generate TimeSheet Summary";
    begin
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);

        if not TimeSheetLine.FindSet() then
            Error('No timesheet entries found for the selected timesheet');

        GenerateTimeSheetSummary.Generate(Rec, TimesheetSummary, TimeSheetLine, InstructionsInput);

        if TimesheetSummary.FindLast() then begin
            CurrentGenerationId := TimesheetSummary.GenerationId;
            LoadSummary(CurrentGenerationId);
        end;
    end;

    local procedure LoadSummary(GenerationId: Integer)
    var
        TimesheetSummary: Record "Timesheet Summary";
    begin
        if TimesheetSummary.Get(GenerationId) then
            SummaryContent := TimesheetSummary.GetContent()
        else
            SummaryContent := '';
    end;

    procedure SetTimeSheet(NewTimeSheetNo: Code[20])
    begin
        TimeSheetNo := NewTimeSheetNo;
    end;
}
