codeunit 50103 "Get Historic Timesheet Tool" implements "AOAI Function"
{
    var
        FunctionNameLbl: Label 'retrieve_timesheets', Locked = true;
        ResourceNo: Code[20];

    procedure GetPrompt(): JsonObject
    var
        ToolDefinition: JsonObject;
        FunctionDefinition: JsonObject;
        ParametersDefinition: JsonObject;
    begin
        ParametersDefinition.ReadFrom(@'
{
    "type": "object",
    "required": [
      "end_date",
      "start_date"
    ],
    "properties": {
      "end_date": {
        "type": "string",
        "description": "The ending date for the timesheet retrieval in ISO 8601 format (YYYY-MM-DD)."
      },
      "start_date": {
        "type": "string",
        "description": "The starting date for the timesheet retrieval in ISO 8601 format (YYYY-MM-DD)."
      }
    },
    "additionalProperties": false
}');

        FunctionDefinition.Add('name', FunctionNameLbl);
        FunctionDefinition.Add('description', 'Takes a starting and ending date as input and retrieves timesheets for that period, returning them as a list of entries.');
        FunctionDefinition.Add('strict', true);
        FunctionDefinition.Add('parameters', ParametersDefinition);

        ToolDefinition.Add('type', 'function');
        ToolDefinition.Add('function', FunctionDefinition);

        exit(ToolDefinition);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        StartDate: Date;
        EndDate: Date;
    begin
        StartDate := Arguments.GetDate('start_date');
        EndDate := Arguments.GetDate('end_date');

        if StartDate = 0D then
            Error('Start date is required');

        if EndDate = 0D then
            Error('End date is required');

        exit(CollectHistoricTimeSheets(StartDate, EndDate));
    end;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    /// <summary>
    /// Sets the resource number to filter time sheets by.
    /// </summary>
    /// <param name="NewResourceNo">The resource number to set.</param>
    procedure SetResourceNo(NewResourceNo: Code[20])
    begin
        ResourceNo := NewResourceNo;
    end;

    local procedure CollectHistoricTimeSheets(StartDate: Date; EndDate: Date): Text
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TextBuilder: TextBuilder;
    begin
        TimeSheetHeader.SetRange("Resource No.", ResourceNo);
        TimeSheetHeader.SetFilter("Starting Date", '>=%1', StartDate);
        TimeSheetHeader.SetFilter("Ending Date", '<=%1', EndDate);

        if TimeSheetHeader.FindSet() then
            repeat
                TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                if TimeSheetLine.FindSet() then
                    repeat
                        TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
                        TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
                        if TimeSheetDetail.FindSet() then
                            repeat
                                TextBuilder.Append('Type: ' + Format(TimeSheetLine.Type));
                                TextBuilder.Append(', Description: ' + TimeSheetLine.Description);
                                TextBuilder.Append(', Work Type Code: ' + TimeSheetLine."Work Type Code");
                                TextBuilder.Append(', Date: ' + Format(TimeSheetDetail.Date));
                                TextBuilder.Append(', Quantity: ' + Format(TimeSheetDetail.Quantity));
                                TextBuilder.AppendLine();
                            until TimeSheetDetail.Next() = 0;
                    until TimeSheetLine.Next() = 0;
            until TimeSheetHeader.Next() = 0;

        exit(TextBuilder.ToText());
    end;
}