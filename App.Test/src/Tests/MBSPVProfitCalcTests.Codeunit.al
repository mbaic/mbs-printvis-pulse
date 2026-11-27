namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Enums;
using System.TestLibraries.Utilities;

codeunit 50103 "MBS PV Profit Calc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Fixtures: Codeunit "MBS PV Test Fixtures";
        Calculator: Codeunit "MBS PV Profit Calculator";
        Rows: Record "MBS PV Profit Input Buffer" temporary;
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopOverruns: Record "MBS PV Profit Overrun Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;

    [Test]
    procedure RealizedMarginUsesNetInvoicedSalesTest()
    begin
        // [SCENARIO] Margin = (net sales - cost) / net sales, with credit memos reducing sales
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 600);
        Fixtures.CloseCase(Rows, 'C1', DMY2Date(15, 6, 2026), 1000, 200);

        Run(true, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 1 Availability", 'KPI 1 should be available.');
        LibraryAssert.AreEqual(25, Snapshot."KPI 1 Decimal", '(800 - 600) / 800 = 25 percent.');
        LibraryAssert.AreEqual(Enum::"MBS PV Dashboard Type"::Profitability, Snapshot."Dashboard Type", 'Dashboard type should be Profitability.');
    end;

    [Test]
    procedure CasesClosedOutsideThePeriodAreIgnoredTest()
    begin
        // [SCENARIO] Only cases closed inside the period count for margin
        Initialize();
        Fixtures.AddCase(Rows, 'IN', 0, 500);
        Fixtures.CloseCase(Rows, 'IN', Fixtures.PeriodFrom(), 1000, 0);
        Fixtures.AddCase(Rows, 'OUT', 0, 5000);
        Fixtures.CloseCase(Rows, 'OUT', Fixtures.PeriodFrom() - 1, 1000, 0);

        Run(true, true);

        LibraryAssert.AreEqual(50, Snapshot."KPI 1 Decimal", 'Only the case closed on the first day counts.');
    end;

    [Test]
    procedure ZeroNetSalesMakesMarginNotApplicableTest()
    begin
        // [SCENARIO] Fully credited sales leave no margin base
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 100);
        Fixtures.CloseCase(Rows, 'C1', DMY2Date(15, 6, 2026), 1000, 1000);

        Run(true, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 1 Availability", 'Zero net sales gives N/A.');
    end;

    [Test]
    procedure NegativeNetSalesMakesMarginNotApplicableTest()
    begin
        // [SCENARIO] Credit memos above invoiced sales give N/A, not a negative base
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 100);
        Fixtures.CloseCase(Rows, 'C1', DMY2Date(15, 6, 2026), 500, 800);

        Run(true, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 1 Availability", 'Negative net sales gives N/A.');
    end;

    [Test]
    procedure LifetimeCostCountsForCaseClosedInPeriodTest()
    begin
        // [SCENARIO] Cost is lifetime: cost posted before the period still reduces the margin
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 900);
        Fixtures.CloseCase(Rows, 'C1', DMY2Date(2, 6, 2026), 1000, 0);

        Run(true, true);

        LibraryAssert.AreEqual(10, Snapshot."KPI 1 Decimal", 'All posted cost counts: (1000 - 900) / 1000 = 10 percent.');
    end;

    [Test]
    procedure UnverifiedCurrencyMakesMarginNotApplicableTest()
    begin
        // [SCENARIO] A closed case without a verified currency basis blocks the margin
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 100);
        Fixtures.CloseCase(Rows, 'C1', DMY2Date(15, 6, 2026), 1000, 0);
        Rows.Get('C1');
        Rows.Normalized := false;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 1 Availability", 'Unverified currency gives N/A.');
        LibraryAssert.AreEqual('Margin unavailable: mixed or unverified currency.', Snapshot."KPI 1 Note", 'The note explains why.');
    end;

    [Test]
    procedure OverrunIsCountedOncePerCaseTest()
    begin
        // [SCENARIO] A case whose actual cost exceeds the accepted estimate counts once
        Initialize();
        Fixtures.AddCase(Rows, 'OVER', 1000, 1200);
        Fixtures.AddCase(Rows, 'EQUAL', 1000, 1000);
        Fixtures.AddCase(Rows, 'UNDER', 1000, 800);

        Run(true, true);

        LibraryAssert.AreEqual(1, Snapshot."KPI 2 Int", 'Only the overrun case counts.');
        LibraryAssert.AreEqual(1, TopOverruns.Count(), 'Only the overrun case is listed.');
        TopOverruns.FindFirst();
        LibraryAssert.AreEqual(200, TopOverruns."Overrun Amount", 'Overrun is actual minus estimate.');
        LibraryAssert.AreEqual(-200, TopOverruns."Sort Amount", 'Sort amount is the negated overrun.');
    end;

    [Test]
    procedure SupersededJobVersionBaselineIsExcludedTest()
    begin
        // [SCENARIO] An estimate from an alternative or superseded job version is not a valid baseline
        Initialize();
        Fixtures.AddCase(Rows, 'ALT', 1000, 1500);
        Rows.Get('ALT');
        Rows."Is Sold Version" := false;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(0, Snapshot."KPI 2 Int", 'The case cannot be compared.');
        LibraryAssert.AreEqual(1, Snapshot."Excluded Count 2", 'The case is counted as excluded.');
    end;

    [Test]
    procedure MissingEstimateIsExcludedTest()
    begin
        // [SCENARIO] A case without an accepted estimate is excluded and counted
        Initialize();
        Fixtures.AddCase(Rows, 'NOEST', 0, 500);

        Run(true, true);

        LibraryAssert.AreEqual(0, Snapshot."KPI 2 Int", 'No baseline, no overrun.');
        LibraryAssert.AreEqual(1, Snapshot."Excluded Count 2", 'The case is counted as excluded.');
        LibraryAssert.AreEqual(0, Fixtures.ChartLabelCount(ChartJson), 'An excluded case is not charted.');
    end;

    [Test]
    procedure MultiJobCaseCountsOnceTest()
    begin
        // [SCENARIO] The reader aggregates all jobs of a case into one row, so the case counts once
        Initialize();
        Fixtures.AddCase(Rows, 'MULTI', 1000, 700);
        Rows.Get('MULTI');
        Rows."Cost Entry Amount" := 700 + 600;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(1, Snapshot."KPI 2 Int", 'The case counts once.');
        LibraryAssert.AreEqual(1, TopOverruns.Count(), 'One row per case.');
    end;

    [Test]
    procedure LaborPresentInBothTablesIsNotDoubleCountedTest()
    begin
        // [SCENARIO] Labor already inside the cost entry amount is not added again (E5)
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 1000, 1000);
        Rows.Get('C1');
        Rows."Labor Entry Amount" := 400;
        Rows."Labor In Cost Entry" := true;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(0, Snapshot."KPI 2 Int", 'Labor is already in the cost entry amount, so there is no overrun.');
    end;

    [Test]
    procedure LaborOutsideCostEntryIsAddedOnceTest()
    begin
        // [SCENARIO] Labor that is not in the cost entry amount is added once
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 1000, 1000);
        Rows.Get('C1');
        Rows."Labor Entry Amount" := 400;
        Rows."Labor In Cost Entry" := false;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(1, Snapshot."KPI 2 Int", 'Actual cost is 1400, above the estimate.');
        TopOverruns.FindFirst();
        LibraryAssert.AreEqual(1400, TopOverruns."Actual Cost", 'Labor is added exactly once.');
    end;

    [Test]
    procedure TiedOverrunsRankByCaseKeyTest()
    begin
        // [SCENARIO] Equal overruns rank by case key ascending
        Initialize();
        Fixtures.AddCase(Rows, 'ZZ', 1000, 1100);
        Fixtures.AddCase(Rows, 'AA', 1000, 1100);
        Fixtures.AddCase(Rows, 'MM', 1000, 1500);

        Run(true, true);

        TopOverruns.SetCurrentKey("Display Rank");
        TopOverruns.FindSet();
        LibraryAssert.AreEqual('MM', TopOverruns."Case Key Text", 'Largest overrun first.');
        TopOverruns.Next();
        LibraryAssert.AreEqual('AA', TopOverruns."Case Key Text", 'Tie sorts by case key.');
        TopOverruns.Next();
        LibraryAssert.AreEqual('ZZ', TopOverruns."Case Key Text", 'Tie sorts by case key.');
    end;

    [Test]
    procedure ChartComparesEstimateAndActualPerProductGroupTest()
    begin
        // [SCENARIO] The chart shows estimated and actual cost for the eligible cohort, largest actual first
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 1000, 1200);
        Fixtures.AddCase(Rows, 'C2', 500, 400);
        Rows.Get('C2');
        Rows."Product Group" := 'LABEL';
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(2, Fixtures.ChartLabelCount(ChartJson), 'Two product groups.');
        LibraryAssert.AreEqual('CARTON', Fixtures.ChartLabel(ChartJson, 0), 'Largest actual cost first.');
        LibraryAssert.AreEqual(1000, Fixtures.ChartValue(ChartJson, 'series1', 0), 'Estimated cost of CARTON.');
        LibraryAssert.AreEqual(1200, Fixtures.ChartValue(ChartJson, 'series2', 0), 'Actual cost of CARTON.');
    end;

    [Test]
    procedure WipIsUnavailableUntilVerifiedTest()
    begin
        // [SCENARIO] WIP is shown only when the reader verified it as monetary LCY
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 0, 0);
        Rows.Get('C1');
        Rows."WIP Amount" := 250;
        Rows.Modify();

        Run(true, false);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 3 Availability", 'Unverified WIP is unavailable.');
        LibraryAssert.AreEqual('WIP is not verified as monetary LCY.', Snapshot."KPI 3 Note", 'The note explains why.');
    end;

    [Test]
    procedure VerifiedWipSumsActiveCasesOnlyTest()
    begin
        // [SCENARIO] Verified WIP sums active cases and ignores closed ones
        Initialize();
        Fixtures.AddCase(Rows, 'ACTIVE', 0, 0);
        Rows.Get('ACTIVE');
        Rows."WIP Amount" := 250;
        Rows.Modify();
        Fixtures.AddCase(Rows, 'CLOSED', 0, 0);
        Fixtures.CloseCase(Rows, 'CLOSED', DMY2Date(15, 6, 2026), 100, 0);
        Rows.Get('CLOSED');
        Rows."WIP Amount" := 999;
        Rows.Modify();

        Run(true, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 3 Availability", 'Verified WIP is available.');
        LibraryAssert.AreEqual(250, Snapshot."KPI 3 Decimal", 'Only the active case counts.');
    end;

    [Test]
    procedure UnavailableSourceNeverShowsZeroTest()
    begin
        // [SCENARIO] A failed source gives Unavailable for every KPI
        Initialize();
        Fixtures.AddCase(Rows, 'C1', 1000, 1200);

        Run(false, true);

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 1 Availability", 'KPI 1 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 2 Availability", 'KPI 2 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 3 Availability", 'KPI 3 should be unavailable.');
        LibraryAssert.AreEqual(0, TopOverruns.Count(), 'No exception rows are shown.');
        LibraryAssert.AreEqual(0, Fixtures.ChartLabelCount(ChartJson), 'The chart is empty.');
    end;

    local procedure Initialize()
    begin
        Rows.Reset();
        Rows.DeleteAll();
        Clear(ChartJson);
    end;

    local procedure Run(SourceAvailable: Boolean; WipVerified: Boolean)
    begin
        Calculator.Calculate(
            Rows, Fixtures.PeriodFrom(), Fixtures.PeriodTo(), Fixtures.BusinessDate(), Fixtures.GeneratedAt(),
            WipVerified, SourceAvailable, Snapshot, TopOverruns, Groups, ChartJson);
    end;
}
