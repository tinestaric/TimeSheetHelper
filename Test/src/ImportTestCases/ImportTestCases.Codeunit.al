codeunit 60103 "Import Test Cases"
{
    internal procedure ImportTestCases()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        TestCases: List of [Text];
        TestCase: Text;
        InStr: InStream;
    begin
        TestCases := NavApp.ListResources('*.jsonl');
        TestCases.AddRange(NavApp.ListResources('*.yaml'));
        TestCases.AddRange(NavApp.ListResources('*.json'));
        foreach TestCase in TestCases do begin
            NavApp.GetResource(TestCase, InStr);
            AITALTestSuiteMgt.ImportTestInputs(TestCase, InStr);
        end;
    end;
}

