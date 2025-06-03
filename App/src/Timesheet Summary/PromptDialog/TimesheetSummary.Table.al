table 50106 "Timesheet Summary"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; GenerationId; Integer)
        {
            Caption = 'Generation ID';
            ToolTip = 'Specifies the unique identifier for this generation of time sheet entries.';
        }
        field(2; Content; Blob)
        {
            Caption = 'Summary Content';
            ToolTip = 'Stores the content of the timesheet generation summary.';
        }
    }

    keys
    {
        key(PK; GenerationId)
        {
            Clustered = true;
        }
    }

    procedure SetContent(NewContent: Text)
    var
        OutStream: OutStream;
    begin
        Clear(Content);
        Content.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(NewContent);
    end;

    procedure GetContent(): Text
    var
        InStream: InStream;
        ContentText: Text;
        ResponseMessage: Text;
    begin
        CalcFields(Content);
        Content.CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(ContentText);
            ResponseMessage += ContentText + '\';
        end;
        exit(ResponseMessage);
    end;
}
