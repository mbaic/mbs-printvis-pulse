namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Enums;
using System.TestLibraries.Utilities;

codeunit 50102 "MBS PV Prod Calc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Fixtures: Codeunit "MBS PV Test Fixtures";
        Calculator: Codeunit "MBS PV Prod Calculator";
        Rows: Record "MBS PV Prod Input Buffer" temporary;
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopRisks: Record "MBS PV Prod Risk Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;

    [Test]
    procedure OnTimeAndLateShipmentsGiveOnTimePercentTest()
    begin
        // [SCENARIO] Actual on or before the promise date is on time
        Initialize();
        Fixtures.AddShipment(Rows, 'S1', DMY2Date(10, 6, 2026), DMY2Date(10, 6, 2026));
        Fixtures.AddShipment(Rows, 'S2', DMY2Date(9, 6, 2026), DMY2Date(10, 6, 2026));
        Fixtures.AddShipment(Rows, 'S3', DMY2Date(12, 6, 2026), DMY2Date(10, 6, 2026));

        Run(true, 'Promised Date Of Shipment');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 1 Availability", 'KPI 1 should be available.');
        LibraryAssert.AreNearlyEqual(66.7, Snapshot."KPI 1 Decimal", 0.05, 'Two of three shipments are on time.');
        LibraryAssert.AreEqual('Promise date field: Promised Date Of Shipment.', Snapshot."KPI 1 Note", 'The note names the promise field.');
        LibraryAssert.AreEqual(Enum::"MBS PV Dashboard Type"::Production, Snapshot."Dashboard Type", 'Dashboard type should be Production.');
    end;

    [Test]
    procedure BlankPromiseDateIsExcludedAndCountedTest()
    begin
        // [SCENARIO] A shipment without a promise date leaves the ratio and is counted as excluded
        Initialize();
        Fixtures.AddShipment(Rows, 'S1', DMY2Date(10, 6, 2026), DMY2Date(10, 6, 2026));
        Fixtures.AddShipment(Rows, 'S2', DMY2Date(10, 6, 2026), 0D);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(100, Snapshot."KPI 1 Decimal", 'Only the eligible shipment counts.');
        LibraryAssert.AreEqual(1, Snapshot."Excluded Count 1", 'The blank promise date is counted as excluded.');
    end;

    [Test]
    procedure BlankActualDateIsExcludedAndCountedTest()
    begin
        // [SCENARIO] A shipped record without an actual date cannot be placed in a period
        Initialize();
        Fixtures.AddShipment(Rows, 'S1', 0D, DMY2Date(10, 6, 2026));

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 1 Availability", 'No eligible shipment gives N/A.');
        LibraryAssert.AreEqual(1, Snapshot."Excluded Count 1", 'The blank actual date is counted as excluded.');
    end;

    [Test]
    procedure UnverifiedPromiseFieldMakesOnTimeUnavailableTest()
    begin
        // [SCENARIO] Without a verified promise field the KPI must not show a number
        Initialize();
        Fixtures.AddShipment(Rows, 'S1', DMY2Date(10, 6, 2026), DMY2Date(10, 6, 2026));

        Run(true, '');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 1 Availability", 'The promise field is not verified.');
        LibraryAssert.AreEqual('Promise date field is not verified.', Snapshot."KPI 1 Note", 'The note explains why.');
    end;

    [Test]
    procedure ShipmentOutsidePeriodIsIgnoredTest()
    begin
        // [SCENARIO] Shipments outside the period are neither on time nor excluded
        Initialize();
        Fixtures.AddShipment(Rows, 'S1', Fixtures.PeriodFrom() - 1, Fixtures.PeriodFrom() - 5);
        Fixtures.AddShipment(Rows, 'S2', Fixtures.PeriodTo() + 1, Fixtures.PeriodTo() + 5);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 1 Availability", 'No shipment falls in the period.');
        LibraryAssert.AreEqual(0, Snapshot."Excluded Count 1", 'Out-of-period shipments are not excluded rows.');
    end;

    [Test]
    procedure SplitShipmentsOfOneCaseCountSeparatelyTest()
    begin
        // [SCENARIO] Each shipment record of a split delivery counts on its own
        Initialize();
        Fixtures.AddShipment(Rows, 'CASE1|SHIP1', DMY2Date(10, 6, 2026), DMY2Date(10, 6, 2026));
        Fixtures.AddShipment(Rows, 'CASE1|SHIP2', DMY2Date(20, 6, 2026), DMY2Date(10, 6, 2026));

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(50, Snapshot."KPI 1 Decimal", 'One of two split shipments is on time.');
    end;

    [Test]
    procedure OverlappingEntryNumbersStayDistinctOperationsTest()
    begin
        // [SCENARIO] Operations with the same entry number in different cases are different keys
        Initialize();
        Fixtures.AddOperation(Rows, 'CASE1|10', Fixtures.BusinessDate(), 8, 1);
        Fixtures.AddOperation(Rows, 'CASE2|10', Fixtures.BusinessDate(), 8, 1);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(2, Snapshot."KPI 2 Int", 'Both operations are at risk.');
        LibraryAssert.AreEqual(2, TopRisks.Count(), 'Both operations are listed.');
    end;

    [Test]
    procedure SupersededVersionsAreNotAtRiskTest()
    begin
        // [SCENARIO] Only operations of the current production version count
        Initialize();
        Fixtures.AddOperation(Rows, 'OLD', Fixtures.BusinessDate(), 8, 0);
        Rows.Get('OLD');
        Rows."Is Current Version" := false;
        Rows.Modify();
        Fixtures.AddOperation(Rows, 'NEW', Fixtures.BusinessDate(), 8, 0);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(1, Snapshot."KPI 2 Int", 'Only the current version is at risk.');
    end;

    [Test]
    procedure InactiveArchivedAndCompleteOperationsAreIgnoredTest()
    begin
        // [SCENARIO] Inactive, archived and completed operations are not eligible
        Initialize();
        Fixtures.AddOperation(Rows, 'INACTIVE', Fixtures.BusinessDate(), 8, 0);
        Rows.Get('INACTIVE');
        Rows."Is Active" := false;
        Rows.Modify();
        Fixtures.AddOperation(Rows, 'ARCHIVED', Fixtures.BusinessDate(), 8, 0);
        Rows.Get('ARCHIVED');
        Rows."Is Archived" := true;
        Rows.Modify();
        Fixtures.AddOperation(Rows, 'DONE', Fixtures.BusinessDate(), 8, 8);
        Rows.Get('DONE');
        Rows."Is Complete" := true;
        Rows.Modify();

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(0, Snapshot."KPI 2 Int", 'No operation is eligible.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 2 Availability", 'A real zero stays available.');
    end;

    [Test]
    procedure MissingDueDateIsExcludedAndCountedTest()
    begin
        // [SCENARIO] An operation without a due date cannot be rated and is counted as excluded
        Initialize();
        Fixtures.AddOperation(Rows, 'NODATE', 0D, 8, 0);
        Fixtures.AddOperation(Rows, 'LATE', Fixtures.BusinessDate() - 3, 8, 0);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(1, Snapshot."KPI 2 Int", 'Only the dated operation is at risk.');
        LibraryAssert.AreEqual(1, Snapshot."Excluded Count 2", 'The undated operation is counted as excluded.');
    end;

    [Test]
    procedure DueTomorrowIsAtRiskButDayAfterIsNotTest()
    begin
        // [SCENARIO] The at-risk window ends at business date plus one day, inclusive
        Initialize();
        Fixtures.AddOperation(Rows, 'TODAY', Fixtures.BusinessDate(), 8, 0);
        Fixtures.AddOperation(Rows, 'TOMORROW', Fixtures.BusinessDate() + 1, 8, 0);
        Fixtures.AddOperation(Rows, 'LATER', Fixtures.BusinessDate() + 2, 8, 0);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(2, Snapshot."KPI 2 Int", 'Due today and tomorrow are at risk.');
    end;

    [Test]
    procedure OperationLevelDueDateKeepsStandardCaptionTest()
    begin
        // [SCENARIO] A verified operation due date allows the standard caption
        Initialize();
        Fixtures.AddOperation(Rows, 'OP1', Fixtures.BusinessDate(), 8, 0);

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual('At-Risk Operations', Snapshot."KPI 2 Caption", 'Standard caption for operation-level dates.');
        LibraryAssert.AreEqual('Due date source: operation due date.', Snapshot."KPI 2 Note", 'The note names the source.');
    end;

    [Test]
    procedure FallbackDueDateUsesFallbackCaptionTest()
    begin
        // [SCENARIO] A fallback due date source changes the caption and is named in the note
        Initialize();
        Fixtures.AddOperation(Rows, 'OP1', Fixtures.BusinessDate(), 8, 0);
        Rows.Get('OP1');
        Rows."Due Date Source" := Rows."Due Date Source"::RequestedDelivery;
        Rows.Modify();

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual('Incomplete Operations Near Requested Delivery', Snapshot."KPI 2 Caption", 'Fallback caption expected.');
        LibraryAssert.AreEqual('Due date source: requested delivery date.', Snapshot."KPI 2 Note", 'The note names the source.');
    end;

    [Test]
    procedure MixedDueDateSourcesAreAllNamedTest()
    begin
        // [SCENARIO] Mixed sources use the fallback caption and list every source
        Initialize();
        Fixtures.AddOperation(Rows, 'OP1', Fixtures.BusinessDate(), 8, 0);
        Fixtures.AddOperation(Rows, 'OP2', Fixtures.BusinessDate(), 8, 0);
        Rows.Get('OP2');
        Rows."Due Date Source" := Rows."Due Date Source"::CaseDueDate;
        Rows.Modify();

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual('Incomplete Operations Near Requested Delivery', Snapshot."KPI 2 Caption", 'Fallback caption expected.');
        LibraryAssert.AreEqual('Due date source: operation due date, case due date.', Snapshot."KPI 2 Note", 'Both sources are named.');
    end;

    [Test]
    procedure InProgressCountsStartedIncompleteOperationsTest()
    begin
        // [SCENARIO] Only started, incomplete, eligible operations are in progress
        Initialize();
        Fixtures.AddOperation(Rows, 'STARTED', Fixtures.BusinessDate() + 30, 8, 2);
        Rows.Get('STARTED');
        Rows."Is Started" := true;
        Rows.Modify();
        Fixtures.AddOperation(Rows, 'NOTSTARTED', Fixtures.BusinessDate() + 30, 8, 0);
        Fixtures.AddOperation(Rows, 'DONE', Fixtures.BusinessDate() + 30, 8, 8);
        Rows.Get('DONE');
        Rows."Is Started" := true;
        Rows."Is Complete" := true;
        Rows.Modify();

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(1, Snapshot."KPI 3 Int", 'One operation is in progress.');
    end;

    [Test]
    procedure HoursAreChartedPerCapacityUnitTest()
    begin
        // [SCENARIO] The chart compares planned and spent hours per capacity unit, largest plan first
        Initialize();
        Fixtures.AddOperation(Rows, 'OP1', Fixtures.BusinessDate() + 30, 8, 2.5);
        Fixtures.AddOperation(Rows, 'OP2', Fixtures.BusinessDate() + 30, 4, 1.5);
        Fixtures.AddOperation(Rows, 'OP3', Fixtures.BusinessDate() + 30, 20, 5);
        Rows.Get('OP3');
        Rows."Capacity Unit" := 'DIECUT';
        Rows.Modify();

        Run(true, 'Shipment Date Job');

        LibraryAssert.AreEqual(2, Fixtures.ChartLabelCount(ChartJson), 'Two capacity units.');
        LibraryAssert.AreEqual('DIECUT', Fixtures.ChartLabel(ChartJson, 0), 'Largest planned hours first.');
        LibraryAssert.AreEqual(20, Fixtures.ChartValue(ChartJson, 'series1', 0), 'Planned hours of DIECUT.');
        LibraryAssert.AreEqual(5, Fixtures.ChartValue(ChartJson, 'series2', 0), 'Spent hours of DIECUT.');
        LibraryAssert.AreEqual(12, Fixtures.ChartValue(ChartJson, 'series1', 1), 'Planned hours of PRESS1.');
        LibraryAssert.AreEqual(4, Fixtures.ChartValue(ChartJson, 'series2', 1), 'Spent hours of PRESS1.');
    end;

    [Test]
    procedure RiskListSortsByDueDateThenOperationKeyTest()
    begin
        // [SCENARIO] At-risk rows sort by due date ascending, then by operation key
        Initialize();
        Fixtures.AddOperation(Rows, 'B', Fixtures.BusinessDate(), 8, 0);
        Fixtures.AddOperation(Rows, 'A', Fixtures.BusinessDate(), 8, 0);
        Fixtures.AddOperation(Rows, 'C', Fixtures.BusinessDate() - 2, 8, 0);

        Run(true, 'Shipment Date Job');

        TopRisks.SetCurrentKey("Display Rank");
        TopRisks.FindSet();
        LibraryAssert.AreEqual('C', TopRisks."Operation Key Text", 'Earliest due date first.');
        TopRisks.Next();
        LibraryAssert.AreEqual('A', TopRisks."Operation Key Text", 'Ties sort by operation key.');
        TopRisks.Next();
        LibraryAssert.AreEqual('B', TopRisks."Operation Key Text", 'Ties sort by operation key.');
    end;

    [Test]
    procedure UnavailableSourceNeverShowsZeroTest()
    begin
        // [SCENARIO] A failed source gives Unavailable for every KPI
        Initialize();
        Fixtures.AddOperation(Rows, 'OP1', Fixtures.BusinessDate(), 8, 0);

        Run(false, 'Shipment Date Job');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 1 Availability", 'KPI 1 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 2 Availability", 'KPI 2 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 3 Availability", 'KPI 3 should be unavailable.');
        LibraryAssert.AreEqual(0, TopRisks.Count(), 'No exception rows are shown.');
        LibraryAssert.AreEqual(0, Fixtures.ChartLabelCount(ChartJson), 'The chart is empty.');
    end;

    local procedure Initialize()
    begin
        Rows.Reset();
        Rows.DeleteAll();
        Clear(ChartJson);
    end;

    local procedure Run(SourceAvailable: Boolean; PromiseFieldName: Text[80])
    begin
        Calculator.Calculate(
            Rows, Fixtures.PeriodFrom(), Fixtures.PeriodTo(), Fixtures.BusinessDate(), Fixtures.GeneratedAt(),
            PromiseFieldName, SourceAvailable, Snapshot, TopRisks, Groups, ChartJson);
    end;
}
