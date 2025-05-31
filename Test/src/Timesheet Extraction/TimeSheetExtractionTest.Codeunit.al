codeunit 60104 "Time Sheet Extraction Test"
{
    Subtype = Test;

    [Test]
    procedure TestTimeSheetExtraction()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        AITTestContext: Codeunit "AIT Test Context";
        StartDate: Date;
        EndDate: Date;
        ExpectedEntries: JsonArray;
    begin
        // GIVEN: Get time sheet period from the test case
        StartDate := AITTestContext.GetInput().Element('timeSheetPeriod').ValueAsJsonObject().GetDate('startDate');
        EndDate := AITTestContext.GetInput().Element('timeSheetPeriod').ValueAsJsonObject().GetDate('endDate');

        // GIVEN: Create a test time sheet with the specified dates
        CreateTimeSheet(TimeSheetHeader, StartDate, EndDate);

        // GIVEN: Get the input text from the test case


        // GIVEN: Get the expected entries from the test case


        // WHEN: Extract the timesheet entries


        // THEN: Validate the extracted entries against expected results
        VerifyExtractedEntries(TimeSheetEntrySuggestion, ExpectedEntries);

        // Set the output for the test with full JSON of suggestions
        AITTestContext.SetTestOutput(ConvertSuggestionsToJson(TimeSheetEntrySuggestion));
    end;

    local procedure ConvertSuggestionsToJson(var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion"): Text
    var
        SuggestionsArray: JsonArray;
        SuggestionObject: JsonObject;
    begin
        TimeSheetEntrySuggestion.Reset();
        if TimeSheetEntrySuggestion.FindSet() then
            repeat
                Clear(SuggestionObject);
                SuggestionObject.Add('generationId', TimeSheetEntrySuggestion.GenerationId);
                SuggestionObject.Add('lineNo', TimeSheetEntrySuggestion.LineNo);
                SuggestionObject.Add('date', Format(TimeSheetEntrySuggestion.EntryDate, 0, '<Year4>-<Month,2>-<Day,2>'));
                SuggestionObject.Add('hours', TimeSheetEntrySuggestion.Hours);
                SuggestionObject.Add('description', TimeSheetEntrySuggestion.Description);
                SuggestionObject.Add('projectNo', TimeSheetEntrySuggestion."Project No.");
                SuggestionObject.Add('taskNo', TimeSheetEntrySuggestion."Task No.");
                SuggestionObject.Add('entryType', TimeSheetEntrySuggestion.EntryType);
                SuggestionsArray.Add(SuggestionObject);
            until TimeSheetEntrySuggestion.Next() = 0;

        exit(Format(SuggestionsArray));
    end;

    local procedure VerifyExtractedEntries(var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion"; ExpectedEntries: JsonArray)
    var
        ExpectedEntry: JsonToken;
        ExpectedDate: Date;
        ExpectedHours: Decimal;
        EntryFound: Boolean;
    begin
        // For each expected entry, verify exact date and hours match
        foreach ExpectedEntry in ExpectedEntries do begin
            //TODO: Extract the date and hours from the expected entry

            // Verify that we have entries for this exact date with exact hours
            EntryFound := VerifyDateHasExactHours(TimeSheetEntrySuggestion, ExpectedDate, ExpectedHours);
            if not EntryFound then
                Error('Expected entry not found: %1 hours on %2',
                    Format(ExpectedHours), Format(ExpectedDate));
        end;
    end;

    local procedure VerifyDateHasExactHours(
        var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        ExpectedDate: Date;
        ExpectedHours: Decimal
    ): Boolean
    var
        DateHours: Decimal;
    begin
        TimeSheetEntrySuggestion.Reset();
        TimeSheetEntrySuggestion.SetRange(EntryDate, ExpectedDate);

        if TimeSheetEntrySuggestion.FindSet() then begin
            repeat
                DateHours += TimeSheetEntrySuggestion.Hours;
            until TimeSheetEntrySuggestion.Next() = 0;

            // Check if total hours for this date match exactly
            exit(DateHours = ExpectedHours);
        end;

        exit(false);
    end;

    local procedure CreateTimeSheet(var TimeSheetHeader: Record "Time Sheet Header"; StartDate: Date; EndDate: Date) TimeSheetNo: Code[20]
    var
        DefaultNoLbl: Label 'TSE001';
    begin
        if TimeSheetHeader.FindLast() then
            TimeSheetNo := IncStr(TimeSheetHeader."No.")
        else
            TimeSheetNo := DefaultNoLbl;

        TimeSheetHeader.Init();
        TimeSheetHeader."No." := TimeSheetNo;
        TimeSheetHeader."Resource No." := GetResourceNo();
        TimeSheetHeader."Starting Date" := StartDate;
        TimeSheetHeader."Ending Date" := EndDate;
        TimeSheetHeader.Insert(false);
    end;

    local procedure GetResourceNo(): Code[20]
    var
        Resource: Record Resource;
        DefaultResourceNoLbl: Label 'RES001';
    begin
        // Try to find an existing resource
        Resource.SetRange("Use Time Sheet", true);
        if Resource.FindSet() then
            exit(Resource."No.");

        // If no resources exist, create a test resource
        Resource.Init();
        Resource."No." := DefaultResourceNoLbl;
        Resource.Name := 'Test Resource';
        Resource.Type := Resource.Type::Person;
        Resource."Use Time Sheet" := true;
        Resource."Time Sheet Owner User ID" := CopyStr(UserId(), 1, MaxStrLen(Resource."Time Sheet Owner User ID"));
        Resource.Insert(false);

        exit(Resource."No.");
    end;
}