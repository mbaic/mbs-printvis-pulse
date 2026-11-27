namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Diagnostics;
using MBS.PrintVisPulse.Enums;
using System.TestLibraries.Utilities;

codeunit 50104 "MBS PV Support Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Fixtures: Codeunit "MBS PV Test Fixtures";
        PeriodMgt: Codeunit "MBS PV Period Mgt";
        DisplayMgt: Codeunit "MBS PV Display Mgt";
        ChartJsonMgt: Codeunit "MBS PV Chart Json";

    [Test]
    procedure Rolling30DayPeriodIncludesEndDateAndPrecedingTwentyNineDaysTest()
    var
        FromDate: Date;
        ToDate: Date;
    begin
        // [SCENARIO] A rolling 30-day period spans exactly 30 inclusive days
        PeriodMgt.GetRange(Enum::"MBS PV Period Filter"::Last30Days, DMY2Date(30, 6, 2026), FromDate, ToDate);

        LibraryAssert.AreEqual(DMY2Date(1, 6, 2026), FromDate, 'From date is 29 days before the end date.');
        LibraryAssert.AreEqual(DMY2Date(30, 6, 2026), ToDate, 'To date is the business date.');
        LibraryAssert.AreEqual(29, ToDate - FromDate, 'The inclusive span is 30 days.');
    end;

    [Test]
    procedure OtherPeriodPresetsStartOnTheExpectedDayTest()
    var
        FromDate: Date;
        ToDate: Date;
    begin
        // [SCENARIO] Each preset yields the documented first day
        PeriodMgt.GetRange(Enum::"MBS PV Period Filter"::Last7Days, DMY2Date(30, 6, 2026), FromDate, ToDate);
        LibraryAssert.AreEqual(DMY2Date(24, 6, 2026), FromDate, 'Last 7 days starts 6 days before.');

        PeriodMgt.GetRange(Enum::"MBS PV Period Filter"::Last90Days, DMY2Date(30, 6, 2026), FromDate, ToDate);
        LibraryAssert.AreEqual(DMY2Date(30, 6, 2026) - 89, FromDate, 'Last 90 days starts 89 days before.');

        PeriodMgt.GetRange(Enum::"MBS PV Period Filter"::MonthToDate, DMY2Date(17, 6, 2026), FromDate, ToDate);
        LibraryAssert.AreEqual(DMY2Date(1, 6, 2026), FromDate, 'Month to date starts on the first.');
        LibraryAssert.AreEqual(DMY2Date(17, 6, 2026), ToDate, 'Month to date ends on the business date.');

        PeriodMgt.GetRange(Enum::"MBS PV Period Filter"::YearToDate, DMY2Date(17, 6, 2026), FromDate, ToDate);
        LibraryAssert.AreEqual(DMY2Date(1, 1, 2026), FromDate, 'Year to date starts on January 1.');
    end;

    [Test]
    procedure UnavailableAndNotApplicableNeverRenderAsNumbersTest()
    var
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
    begin
        // [SCENARIO] Display text follows the availability mapping
        Snapshot.Init();
        Snapshot."Primary Key" := 'T';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Sales;
        Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Unavailable;
        Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::NotApplicable;
        Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Available;
        Snapshot.Insert();

        LibraryAssert.AreEqual('Unavailable', DisplayMgt.FormatKpi(Snapshot, 1), 'Unavailable shows its label.');
        LibraryAssert.AreEqual('N/A', DisplayMgt.FormatKpi(Snapshot, 2), 'Not applicable shows N/A.');
        LibraryAssert.AreEqual('', DisplayMgt.FormatKpi(Snapshot, 4), 'An unknown KPI number shows nothing.');
    end;

    [Test]
    procedure RealZeroCountStaysZeroTest()
    var
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
    begin
        // [SCENARIO] An available KPI with value zero shows 0
        Snapshot.Init();
        Snapshot."Primary Key" := 'T';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Sales;
        Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Available;
        Snapshot."KPI 1 Int" := 0;
        Snapshot.Insert();

        LibraryAssert.AreEqual('0', DisplayMgt.FormatKpi(Snapshot, 1), 'A real zero stays 0.');
    end;

    [Test]
    procedure PercentKpiShowsPercentSignTest()
    var
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        DisplayText: Text;
    begin
        // [SCENARIO] Percent KPIs end with a percent sign
        Snapshot.Init();
        Snapshot."Primary Key" := 'T';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Production;
        Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Available;
        Snapshot."KPI 1 Decimal" := 66.7;
        Snapshot.Insert();

        DisplayText := DisplayMgt.FormatKpi(Snapshot, 1);

        LibraryAssert.IsTrue(DisplayText.EndsWith('%'), 'A percent KPI ends with a percent sign.');
        LibraryAssert.IsTrue(DisplayText.StartsWith('66'), 'The value is shown.');
    end;

    [Test]
    procedure ChartJsonIsLimitedToFiveGroupsAndOmitsSeries2WithoutLabelTest()
    var
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        Index: Integer;
        ChartJson: Text;
    begin
        // [SCENARIO] Chart JSON keeps the top 5 groups and writes series 2 only when labeled
        for Index := 1 to 6 do
            ChartJsonMgt.AddGroupTotal(Groups, CopyStr('G' + Format(Index), 1, 20), Index * 10, 0, false);

        ChartJson := ChartJsonMgt.BuildTop5ChartJson('T', 'S1', '', 'Empty', Groups);

        LibraryAssert.AreEqual(5, Fixtures.ChartLabelCount(ChartJson), 'Five groups at most.');
        LibraryAssert.AreEqual('G6', Fixtures.ChartLabel(ChartJson, 0), 'Largest first.');
        LibraryAssert.IsFalse(Fixtures.ChartHasProperty(ChartJson, 'series2'), 'Series 2 is omitted without a label.');
    end;

    [Test]
    procedure BlankGroupCodeIsChartedAsUnassignedTest()
    var
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;
    begin
        // [SCENARIO] A blank product group is shown as UNASSIGNED and totals add up
        ChartJsonMgt.AddGroupTotal(Groups, '', 10, 4, true);
        ChartJsonMgt.AddGroupTotal(Groups, '', 5, 1, true);

        ChartJson := ChartJsonMgt.BuildTop5ChartJson('T', 'S1', 'S2', 'Empty', Groups);

        LibraryAssert.AreEqual(1, Fixtures.ChartLabelCount(ChartJson), 'One group.');
        LibraryAssert.AreEqual('UNASSIGNED', Fixtures.ChartLabel(ChartJson, 0), 'Blank group code maps to UNASSIGNED.');
        LibraryAssert.AreEqual(15, Fixtures.ChartValue(ChartJson, 'series1', 0), 'Series 1 total.');
        LibraryAssert.AreEqual(5, Fixtures.ChartValue(ChartJson, 'series2', 0), 'Series 2 total.');
    end;

    [Test]
    procedure RefreshWithoutBindingGivesUnavailableSnapshotsTest()
    var
        RefreshMgt: Codeunit "MBS PV Refresh Mgt";
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopQuotes: Record "MBS PV Open Quote Row" temporary;
        TopRisks: Record "MBS PV Prod Risk Row" temporary;
        TopOverruns: Record "MBS PV Profit Overrun Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;
    begin
        // [SCENARIO] With no PrintVis binding every dashboard refresh ends in an Unavailable snapshot, never in an error
        RefreshMgt.RefreshSales(Enum::"MBS PV Period Filter"::Last30Days, Snapshot, TopQuotes, Groups, ChartJson);
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 1 Availability", 'Sales should be unavailable.');

        RefreshMgt.RefreshProduction(Enum::"MBS PV Period Filter"::Last30Days, Snapshot, TopRisks, Groups, ChartJson);
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 2 Availability", 'Production should be unavailable.');

        RefreshMgt.RefreshProfitability(Enum::"MBS PV Period Filter"::Last30Days, Snapshot, TopOverruns, Groups, ChartJson);
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 3 Availability", 'Profitability should be unavailable.');
    end;

    [Test]
    procedure DataInfoReportRunsWithoutPrintVisTest()
    var
        DataInfo: Codeunit "MBS PV Data Info";
        ReportText: Text;
    begin
        // [SCENARIO] The data info report works on a tenant without PrintVis and says which tables are missing
        ReportText := DataInfo.Collect();

        LibraryAssert.IsTrue(ReportText.Contains('MBS PrintVis Pulse data info'), 'The report has a header.');
        LibraryAssert.IsTrue(ReportText.Contains('Table "PVS Case" was not found.'), 'A missing table is reported, not raised.');
    end;
}
