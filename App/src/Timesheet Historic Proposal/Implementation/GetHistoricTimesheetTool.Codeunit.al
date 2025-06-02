codeunit 50103 "Get Historic Timesheet Tool" implements "AOAI Function"
{
    var
        ResourceNo: Code[20];

    procedure GetPrompt(): JsonObject
    var
        FunctionDefinition: JsonObject;
        ToolDefinition: JsonObject;
    begin
        FunctionDefinition.ReadFrom(@'
        {
          "name": "name_of_the_function",
          "description": "Description of the function. This is the description for AI to understand the function",
          "strict": true,
          "parameters": {
            "type": "object",
            "required": [
              "parameter1",
              "parameter2",
              "parameter3"
            ],
            "properties": {
              "parameter1": {
                "type": "string",
                "description": "Description of parameter 1"
              },
              "parameter2": {
                "type": "string",
                "description": "Description of parameter 2"
              },
              "parameter3": {
                "type": "string",
                "description": "Description of parameter 3"
              }
            },
            "additionalProperties": false
          }
        }
        ');

        ToolDefinition.Add('type', 'function');
        ToolDefinition.Add('function', FunctionDefinition);
        exit(ToolDefinition);
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        //TODO: Take the arguments from the json object and execute some AL code with them
        // this is where you call the CollectHistoricTimeSheets procedure and return the result
    end;

    procedure GetName(): Text
    begin
        //TODO: Return the name of the function
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