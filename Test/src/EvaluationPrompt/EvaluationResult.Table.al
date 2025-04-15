table 60100 "Evaluation Result"
{
    DataClassification = CustomerContent;
    Caption = 'Evaluation Result';

    fields
    {
        field(1; "Evaluation ID"; Guid)
        {
            Caption = 'Evaluation ID';
            DataClassification = SystemMetadata;
        }
        field(2; Success; Boolean)
        {
            Caption = 'Success';
            DataClassification = CustomerContent;
        }
        field(3; Explanation; Text[2048])
        {
            Caption = 'Explanation';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Evaluation ID")
        {
            Clustered = true;
        }
    }
}