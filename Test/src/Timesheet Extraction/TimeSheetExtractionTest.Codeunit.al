codeunit 60104 "Time Sheet Extraction Test"
{
    Subtype = Test;

    [Test]
    procedure TestTimeSheetExtraction()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        GenerationBuffer: Record "Generation Buffer";
        TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        AITTestContext: Codeunit "AIT Test Context";
        ExtractTimeSheetEntries: Codeunit "Extract Time Sheet Entries";
        StartDate: Date;
        EndDate: Date;
        InputText: Text;
        ExpectedEntries: JsonArray;
    begin
        // GIVEN: Get time sheet period from the test case
        StartDate := AITTestContext.GetInput().Element('timeSheetPeriod').ValueAsJsonObject().GetDate('startDate');
        EndDate := AITTestContext.GetInput().Element('timeSheetPeriod').ValueAsJsonObject().GetDate('endDate');

        // GIVEN: Create a test time sheet with the specified dates
        CreateTimeSheet(TimeSheetHeader, StartDate, EndDate);

        // GIVEN: Get the input text from the test case
        InputText := AITTestContext.GetInput().Element('inputText').ToText();

        // GIVEN: Get the expected entries from the test case
        ExpectedEntries := AITTestContext.GetInput().Element('expectedEntries').AsJsonToken().AsArray();

        // Check if we expect an error for this test case
        if HasExpectedError(AITTestContext) then begin
            // THEN: Validate that the extraction does not process empty input
            asserterror ExtractTimeSheetEntries.Extract(GenerationBuffer, TimeSheetEntrySuggestion, InputText, TimeSheetHeader);
            VerifyExpectedError(AITTestContext);
            exit;
        end;

        // WHEN: Extract the timesheet entries
        ExtractTimeSheetEntries.Extract(GenerationBuffer, TimeSheetEntrySuggestion, InputText, TimeSheetHeader);

        // THEN: Validate the extracted entries against expected results
        VerifyExtractedEntries(TimeSheetEntrySuggestion, ExpectedEntries);

        // Set the output for the test
        AITTestContext.SetTestOutput(Format(TimeSheetEntrySuggestion.Count) + ' entries successfully extracted and verified');
    end;

    local procedure VerifyExtractedEntries(var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion"; ExpectedEntries: JsonArray)
    var
        ExpectedEntry: JsonToken;
        ExpectedEntryObject: JsonObject;
        EntryFound: Boolean;
        ExpectedDate: Date;
        ExpectedHours: Decimal;
        ExpectedDescription: Text;
        ExpectedProject: Text;
        ExpectedTask: Text;
        ExpectedType: Text;
    begin
        // For each expected entry, verify that we have a matching extracted entry
        foreach ExpectedEntry in ExpectedEntries do begin
            ExpectedEntryObject := ExpectedEntry.AsObject();

            // Get the expected values
            ExpectedDate := ExpectedEntryObject.GetDate('date');
            ExpectedHours := ExpectedEntryObject.GetDecimal('hours');
            ExpectedDescription := ExpectedEntryObject.GetText('description');
            ExpectedProject := ExpectedEntryObject.GetText('project');
            ExpectedTask := ExpectedEntryObject.GetText('task');
            ExpectedType := ExpectedEntryObject.GetText('type');

            // Look for matching entry in the extracted results
            EntryFound := FindMatchingEntry(
                TimeSheetEntrySuggestion,
                ExpectedDate,
                ExpectedHours,
                ExpectedDescription,
                ExpectedProject,
                ExpectedTask,
                ExpectedType
            );

            // Assert that the expected entry was found in the extracted results
            if not EntryFound then
                Error('Expected entry not found: %1 on %2 for %3 hours',
                    ExpectedDescription, Format(ExpectedDate), Format(ExpectedHours));
        end;

        // Also verify that we don't have more entries than expected
        TimeSheetEntrySuggestion.Reset();
        if TimeSheetEntrySuggestion.Count <> ExpectedEntries.Count then
            Error('Expected %1 entries but got %2', ExpectedEntries.Count, TimeSheetEntrySuggestion.Count);
    end;

    local procedure FindMatchingEntry(
        var TimeSheetEntrySuggestion: Record "TimeSheet Entry Suggestion";
        ExpectedDate: Date;
        ExpectedHours: Decimal;
        ExpectedDescription: Text;
        ExpectedProject: Text;
        ExpectedTask: Text;
        ExpectedType: Text
    ): Boolean
    begin
        TimeSheetEntrySuggestion.Reset();

        // Look for any entry with matching properties
        TimeSheetEntrySuggestion.SetRange(EntryDate, ExpectedDate);

        if TimeSheetEntrySuggestion.FindSet() then
            repeat
                // Check if this entry matches all expected values
                if (TimeSheetEntrySuggestion.Hours = ExpectedHours) and
                   (TimeSheetEntrySuggestion.Description = ExpectedDescription) and
                   (TimeSheetEntrySuggestion."Project No." = ExpectedProject) and
                   (TimeSheetEntrySuggestion."Task No." = ExpectedTask) and
                   (TimeSheetEntrySuggestion.EntryType = ExpectedType) then
                    exit(true);
            until TimeSheetEntrySuggestion.Next() = 0;

        exit(false);
    end;

    local procedure HasExpectedError(AITTestContext: Codeunit "AIT Test Context"): Boolean
    var
        ExpectedErrorToken: JsonToken;
    begin
        // Check if the 'expectedError' element exists and is true
        if AITTestContext.GetInput().AsJsonToken().AsObject().Get('expectedError', ExpectedErrorToken) then
            exit(ExpectedErrorToken.AsValue().AsBoolean());
        exit(false);
    end;

    local procedure VerifyExpectedError(AITTestContext: Codeunit "AIT Test Context")
    var
        ErrorMessageValue: Text;
    begin
        // Get the expected error message from the test case
        ErrorMessageValue := AITTestContext.GetInput().Element('errorMessage').ToText();

        // Verify that the actual error contains the expected error message
        if StrPos(GetLastErrorText, ErrorMessageValue) = 0 then
            Error('Expected error message "%1" but got "%2"', ErrorMessageValue, GetLastErrorText);
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