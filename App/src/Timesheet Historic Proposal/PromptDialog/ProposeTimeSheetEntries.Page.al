page 50100 "Propose Time Sheet Entries"
{
    Caption = 'Propose Time Sheet Entries';
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
                InstructionalText = 'Describe how you want to track your time or ask for suggestions based on your historic timesheet patterns (e.g., "suggest entries for this week based on my past 3 weeks")';
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
                Tooltip = 'Generate time entry proposals based on your description and historic patterns';
                trigger OnAction()
                begin
                    if TimeDescriptionInput = '' then
                        Error('Please enter a description of the time entries you want or request suggestions based on historic patterns');

                    GenerateTimeEntries();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                Tooltip = 'Regenerate time entry proposals with updated suggestions';
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
                Caption = 'Accept Proposals';
                ToolTip = 'Accept the current proposals and insert the time entries into your timesheet';
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
        ProposeTimeSheetEntries: Codeunit "Propose Time Sheet Entries";
    begin
        ProposeTimeSheetEntries.Propose(Rec, TimeEntriesGenerated, TimeDescriptionInput, TimeSheet);
        CurrPage.ProposalDetails.Page.Load(TimeEntriesGenerated);
    end;

    local procedure ApplyProposedTimeEntries()
    var
        TimeEntriesGenerated: Record "TimeSheet Entry Suggestion";
        ProposeTimeSheetEntries: Codeunit "Propose Time Sheet Entries";
    begin
        CurrPage.ProposalDetails.Page.GetTempRecord(Rec."Generation ID", TimeEntriesGenerated);
        ProposeTimeSheetEntries.ApplyProposedTimeEntries(TimeEntriesGenerated, TimeSheet."No.");
    end;

    procedure SetTimeSheet(NewTimeSheet: Record "Time Sheet Header")
    begin
        TimeSheet := NewTimeSheet;
    end;
}