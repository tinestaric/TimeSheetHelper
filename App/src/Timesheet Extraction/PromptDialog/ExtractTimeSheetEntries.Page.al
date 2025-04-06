page 50102 "Extract Time Sheet Entries"
{
    Caption = 'Extract Time Sheet Entries with Copilot';
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
            field(TimeDescription; TimeDescriptionInput)
            {
                ShowCaption = false;
                MultiLine = true;
            }
        }

        area(Content)
        {
            part(ProposalDetails; "TimeSheet Entry Suggestion Sub")
            {
                Caption = 'Time Entry Suggestions';
                ShowFilter = false;
                ApplicationArea = All;
                Editable = true;
                Enabled = true;
                SubPageLink = GenerationId = field("Generation ID");
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Tooltip = 'Generate time entries based on your description';
                trigger OnAction()
                begin
                    if TimeDescriptionInput = '' then
                        Error('Please enter a time description');

                    GenerateTimeEntries();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                Tooltip = 'Regenerate time entries based on your description';
                trigger OnAction()
                begin
                    GenerateTimeEntries();
                end;
            }
            systemaction(Cancel)
            {
                ToolTip = 'Discard all suggestions and close the dialog';
            }
            systemaction(Ok)
            {
                Caption = 'Keep it';
                ToolTip = 'Accept the current suggestion and insert the time entries';
            }
        }
    }

    var
        TimeSheet: Record "Time Sheet Header";
        TimeDescriptionInput: Text;
        GenerationIdInputText: Text;

    trigger OnAfterGetCurrRecord()
    begin
        GenerationIdInputText := Rec.GetInputText();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
    begin
        if CloseAction = CloseAction::OK then
            ApplyProposedTimeEntries();
    end;

    local procedure GenerateTimeEntries()
    var
        TimeEntriesGenerated: Record "TimeSheet Entry Suggestion";
        ExtractTimeSheetEntries: Codeunit "Extract Time Sheet Entries";
    begin
        ExtractTimeSheetEntries.Extract(Rec, TimeEntriesGenerated, TimeDescriptionInput, TimeSheet);
        CurrPage.ProposalDetails.Page.Load(TimeEntriesGenerated);
    end;

    local procedure ApplyProposedTimeEntries()
    var
        TimeEntriesGenerated: Record "TimeSheet Entry Suggestion";
        ExtractTimeSheetEntries: Codeunit "Extract Time Sheet Entries";
    begin
        CurrPage.ProposalDetails.Page.GetTempRecord(Rec."Generation ID", TimeEntriesGenerated);
        ExtractTimeSheetEntries.ApplyProposedTimeEntries(TimeEntriesGenerated, TimeSheet."No.");
    end;

    procedure SetTimeSheet(NewTimeSheet: Record "Time Sheet Header")
    begin
        TimeSheet := NewTimeSheet;
    end;
}