table 50105 "Generation Buffer"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Generation ID"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Generation ID';
            ToolTip = 'Specifies the unique identifier for this generation.';
        }
        field(2; "Input Text"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Input Text';
            ToolTip = 'Stores the input text used for generation as a blob to handle large text.';
        }
    }

    keys
    {
        key(PK; "Generation ID")
        {
            Clustered = true;
        }
    }

    procedure SetInputText(InputText: Text)
    var
        OutStream: OutStream;
    begin
        "Input Text".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(InputText);
        Modify();
    end;

    procedure GetInputText() Result: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Input Text");
        "Input Text".CreateInStream(InStream, TextEncoding::UTF8);
        Result := TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator());
    end;
}
