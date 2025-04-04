page 50101 "TimeSheet Entry Suggestion Sub"
{
    Caption = 'TimeSheet Entry Suggestions';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "TimeSheet Entry Suggestion";
    SourceTableTemporary = true;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    InherentPermissions = X;
    InherentEntitlements = X;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(EntryDate; Rec.EntryDate) { }
                field(Description; Rec.Description) { }
                field(ProjectNo; Rec."Project No.") { }
                field(TaskNo; Rec."Task No.") { }
                field(Hours; Rec.Hours) { }
            }
        }
    }

    internal procedure Load(var TimeSheetEntries: Record "TimeSheet Entry Suggestion")
    begin
        TimeSheetEntries.Reset();
        if TimeSheetEntries.FindSet() then
            repeat
                Rec := TimeSheetEntries;
                Rec.Insert();
            until TimeSheetEntries.Next() = 0;
    end;

    internal procedure GetTempRecord(GenerationId: Integer; var TimeSheetEntries: Record "TimeSheet Entry Suggestion")
    begin
        TimeSheetEntries.DeleteAll();
        Rec.Reset();
        Rec.SetRange(GenerationId, GenerationId);
        if Rec.FindSet() then
            repeat
                TimeSheetEntries.Copy(Rec, false);
                TimeSheetEntries.Insert();
            until Rec.Next() = 0;
    end;
}