table 50104 "TimeSheet Entry Suggestion"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; GenerationId; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Generation ID';
            ToolTip = 'Specifies the unique identifier for this generation of time sheet entries.';
        }
        field(2; LineNo; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the time sheet entry suggestion.';
        }
        field(3; EntryDate; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Date';
            ToolTip = 'Specifies the date when the work was performed.';
        }
        field(4; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
            ToolTip = 'Specifies a description of the work performed.';
        }
        field(5; "Project No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Project No.';
            ToolTip = 'Specifies the project number that the time was spent on.';
        }
        field(6; "Task No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Task No.';
            ToolTip = 'Specifies the task number within the project.';
        }
        field(7; Hours; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Hours';
            ToolTip = 'Specifies the number of hours spent on this task.';
        }
        field(8; GeneratedTimeEntriesJson; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Generated Time Entries JSON';
            ToolTip = 'Stores the complete JSON data of the generated time entries.';
        }
        field(9; EntryType; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Entry Type';
            ToolTip = 'Specifies the type of time entry.';
        }
    }


    keys
    {
        key(PK; GenerationId, LineNo)
        {
            Clustered = true;
        }
    }
}