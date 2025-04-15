codeunit 60100 "Time Sheet Summary Test"
{
    Subtype = Test;

    [Test]
    procedure TestGenerateTimeSheetSummary()
    var
        TimeSheetHeader: Record "Time Sheet Header";
        GenerationBuffer: Record "Generation Buffer";
        TimesheetSummary: Record "Timesheet Summary";
        TimeSheetLine: Record "Time Sheet Line";
        AITTestContext: Codeunit "AIT Test Context";
        GenerateTimeSheetSummary: Codeunit "Generate TimeSheet Summary";
        Name: Text;
        TimeSheetNo: Code[20];
        MinDate: Date;
        MaxDate: Date;
        CustomInstructions: Text;
        SummaryContent: Text;
    begin
        // GIVEN: Parse test case data
        Name := AITTestContext.GetInput().Element('testCase').ToText();

        // GIVEN: Find date range from entries
        FindEntryDateRange(AITTestContext, MinDate, MaxDate);

        // GIVEN: Create a test time sheet with dates based on the entries
        TimeSheetNo := CreateTimeSheet(TimeSheetHeader, MinDate, MaxDate);

        // GIVEN: Create timesheet lines and details based on test entries
        CreateTimeSheetEntries(AITTestContext, TimeSheetNo);

        // Check if custom instructions are provided in the test case
        if HasCustomInstructions(AITTestContext) then
            CustomInstructions := AITTestContext.GetInput().Element('customInstructions').ToText();

        // WHEN: Generate the timesheet summary
        TimeSheetLine.SetRange("Time Sheet No.", TimeSheetNo);
        GenerateTimeSheetSummary.Generate(GenerationBuffer, TimesheetSummary, TimeSheetLine, CustomInstructions);

        // THEN: Validate the timesheet summary against expected results
        TimesheetSummary.Get(GenerationBuffer."Generation ID");
        SummaryContent := TimesheetSummary.GetContent();
        AITTestContext.SetTestOutput(SummaryContent);
        VerifySummaryContainsExpectedText(AITTestContext, SummaryContent);
    end;

    local procedure VerifySummaryContainsExpectedText(AITTestContext: Codeunit "AIT Test Context"; SummaryContent: Text)
    var
        ExpectedTextToken: JsonToken;
        ExpectedText: Text;
        ExpectedTextArray: JsonArray;
    begin
        // Get the array of expected text values from the test case
        ExpectedTextArray := AITTestContext.GetInput().Element('expectedSummaryContains').AsJsonToken().AsArray();

        // Check that each expected text value is contained in the summary
        foreach ExpectedTextToken in ExpectedTextArray do begin
            ExpectedText := ExpectedTextToken.AsValue().AsText();

            if not Contains(SummaryContent, ExpectedText) then
                Error('Summary does not contain expected text: %1', ExpectedText);
        end;
    end;

    local procedure Contains(SourceText: Text; SearchText: Text): Boolean
    begin
        exit(StrPos(LowerCase(SourceText), LowerCase(SearchText)) > 0);
    end;

    local procedure HasCustomInstructions(AITTestContext: Codeunit "AIT Test Context"): Boolean
    var
        CustomInstructionsToken: JsonToken;
    begin
        // Check if the 'customInstructions' element exists
        if AITTestContext.GetInput().AsJsonToken().AsObject().Get('customInstructions', CustomInstructionsToken) then
            exit(true);
        exit(false);
    end;

    local procedure FindEntryDateRange(AITTestContext: Codeunit "AIT Test Context"; var MinDate: Date; var MaxDate: Date)
    var
        TimeSheetEntry: JsonToken;
        EntryObject: JsonObject;
    begin
        MinDate := 0D;
        MaxDate := 0D;

        foreach TimeSheetEntry in AITTestContext.GetInput().Element('timeSheetEntries').AsJsonToken().AsArray() do begin
            EntryObject := TimeSheetEntry.AsObject();
            if MinDate = 0D then
                MinDate := EntryObject.GetDate('date')
            else
                if EntryObject.GetDate('date') < MinDate then
                    MinDate := EntryObject.GetDate('date');

            if EntryObject.GetDate('date') > MaxDate then
                MaxDate := EntryObject.GetDate('date');
        end;

        // If no entries found, use current date for testing
        if MinDate = 0D then begin
            MinDate := WorkDate();
            MaxDate := WorkDate();
        end;
    end;

    local procedure CreateTimeSheetEntries(AITTestContext: Codeunit "AIT Test Context"; TimeSheetNo: Code[20])
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetEntry: JsonToken;
        EntryObject: JsonObject;
        LineNo: Integer;
    begin
        LineNo := 10000;
        foreach TimeSheetEntry in AITTestContext.GetInput().Element('timeSheetEntries').AsJsonToken().AsArray() do begin
            EntryObject := TimeSheetEntry.AsObject();

            // Create time sheet line
            CreateTimeSheetLine(TimeSheetLine, TimeSheetNo, LineNo, EntryObject);

            // Create time sheet detail
            CreateTimeSheetDetail(TimeSheetDetail, TimeSheetNo, LineNo, EntryObject);

            LineNo += 10000;
        end;
    end;

    local procedure CreateTimeSheetLine(var TimeSheetLine: Record "Time Sheet Line"; TimeSheetNo: Code[20]; LineNo: Integer; EntryObject: JsonObject)
    begin
        TimeSheetLine.Init();
        TimeSheetLine."Time Sheet No." := TimeSheetNo;
        TimeSheetLine."Line No." := LineNo;
        TimeSheetLine.Type := TimeSheetLine.Type::Job;
        TimeSheetLine.Description := CopyStr(EntryObject.GetText('description'), 1, MaxStrLen(TimeSheetLine.Description));
        TimeSheetLine."Work Type Code" := CopyStr(EntryObject.GetText('workTypeCode'), 1, MaxStrLen(TimeSheetLine."Work Type Code"));
        TimeSheetLine.Insert(false);
    end;

    local procedure CreateTimeSheetDetail(var TimeSheetDetail: Record "Time Sheet Detail"; TimeSheetNo: Code[20]; LineNo: Integer; EntryObject: JsonObject)
    begin
        TimeSheetDetail.Init();
        TimeSheetDetail."Time Sheet No." := TimeSheetNo;
        TimeSheetDetail."Time Sheet Line No." := LineNo;
        TimeSheetDetail.Date := EntryObject.GetDate('date');
        TimeSheetDetail.Quantity := EntryObject.GetDecimal('quantity');
        TimeSheetDetail.Insert(false);
    end;

    local procedure CreateTimeSheet(var TimeSheetHeader: Record "Time Sheet Header"; StartDate: Date; EndDate: Date) TimeSheetNo: Code[20]
    var
        DefaultNoLbl: Label 'TS0001';
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