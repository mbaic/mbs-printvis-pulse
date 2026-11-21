namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Enums;
using System.TestLibraries.Utilities;

codeunit 50101 "MBS PV Sales Calc Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Fixtures: Codeunit "MBS PV Test Fixtures";
        Calculator: Codeunit "MBS PV Sales Calculator";
        Rows: Record "MBS PV Quote Input Buffer" temporary;
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopQuotes: Record "MBS PV Open Quote Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;

    [Test]
    procedure OpenQuotesAreCountedAndValuedTest()
    begin
        // [SCENARIO] Open issued quotes drive KPI 1 and KPI 2
        Initialize();
        Fixtures.AddQuote(Rows, 'Q1', 100);
        Fixtures.AddQuote(Rows, 'Q2', 250);

        Run(true, '');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 1 Availability", 'KPI 1 should be available.');
        LibraryAssert.AreEqual(2, Snapshot."KPI 1 Int", 'Two quotes are open.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 2 Availability", 'KPI 2 should be available.');
        LibraryAssert.AreEqual(350, Snapshot."KPI 2 Decimal", 'Open value should be the sum of normalized amounts.');
        LibraryAssert.AreEqual('Top Open Quotes by Value', Snapshot."List Caption", 'List caption should rank by value.');
        LibraryAssert.AreEqual(Enum::"MBS PV Dashboard Type"::Sales, Snapshot."Dashboard Type", 'Dashboard type should be Sales.');
    end;

    [Test]
    procedure WonDecisionIsNotOpenAndCountsInHitRateTest()
    begin
        // [SCENARIO] A won quote leaves the open list and counts as won
        Initialize();
        Fixtures.AddQuote(Rows, 'WON', 100);
        Fixtures.AddQuote(Rows, 'LOST', 100);
        Fixtures.AddQuote(Rows, 'OPEN', 100);
        Fixtures.SetQuoteDecision(Rows, 'WON', Rows.Outcome::Won, DMY2Date(10, 6, 2026));
        Fixtures.SetQuoteDecision(Rows, 'LOST', Rows.Outcome::Lost, DMY2Date(11, 6, 2026));

        Run(true, '');

        LibraryAssert.AreEqual(1, Snapshot."KPI 1 Int", 'Only the undecided quote is open.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 3 Availability", 'Hit rate should be available.');
        LibraryAssert.AreEqual(50, Snapshot."KPI 3 Decimal", 'One won and one lost gives 50 percent.');
    end;

    [Test]
    procedure RejectedQuoteIsNotOpenTest()
    begin
        // [SCENARIO] A rejected quote is a lost decision, never open
        Initialize();
        Fixtures.AddQuote(Rows, 'REJ', 500);
        Fixtures.SetQuoteDecision(Rows, 'REJ', Rows.Outcome::Lost, DMY2Date(5, 6, 2026));

        Run(true, '');

        LibraryAssert.AreEqual(0, Snapshot."KPI 1 Int", 'A rejected quote is not open.');
        LibraryAssert.AreEqual(0, Snapshot."KPI 2 Decimal", 'Open value should be zero.');
        LibraryAssert.AreEqual(0, Snapshot."KPI 3 Decimal", 'One lost and no won gives 0 percent.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 3 Availability", 'A real zero stays available.');
    end;

    [Test]
    procedure CanceledQuoteIsNotOpenTest()
    begin
        // [SCENARIO] A canceled quote is excluded from open quotes
        Initialize();
        Fixtures.AddQuote(Rows, 'CAN', 500);
        Rows.Get('CAN');
        Rows."Is Canceled" := true;
        Rows.Modify();

        Run(true, '');

        LibraryAssert.AreEqual(0, Snapshot."KPI 1 Int", 'A canceled quote is not open.');
        LibraryAssert.AreEqual(0, TopQuotes.Count(), 'A canceled quote must not be listed.');
    end;

    [Test]
    procedure ArchivedRevisionIsNotOpenTest()
    begin
        // [SCENARIO] An archived (revised) version is excluded so a case counts once
        Initialize();
        Fixtures.AddQuote(Rows, 'CASE1-V1', 100);
        Fixtures.AddQuote(Rows, 'CASE1-V2', 120);
        Rows.Get('CASE1-V1');
        Rows."Is Archived" := true;
        Rows.Modify();

        Run(true, '');

        LibraryAssert.AreEqual(1, Snapshot."KPI 1 Int", 'Only the current revision is open.');
        LibraryAssert.AreEqual(120, Snapshot."KPI 2 Decimal", 'Only the current revision is valued.');
    end;

    [Test]
    procedure NeverIssuedQuoteIsIgnoredTest()
    begin
        // [SCENARIO] A quote that was never issued is neither open nor a decision
        Initialize();
        Fixtures.AddQuote(Rows, 'DRAFT', 100);
        Rows.Get('DRAFT');
        Rows."Is Issued Quote" := false;
        Rows.Outcome := Rows.Outcome::Won;
        Rows."Decision Date" := DMY2Date(10, 6, 2026);
        Rows.Modify();

        Run(true, '');

        LibraryAssert.AreEqual(0, Snapshot."KPI 1 Int", 'A draft is not open.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 3 Availability", 'A draft is not a decision.');
    end;

    [Test]
    procedure StandaloneOrderIsExcludedFromHitRateTest()
    begin
        // [SCENARIO] A standalone order has no issued quote, so it never inflates the hit rate
        Initialize();
        Fixtures.AddQuote(Rows, 'ORDER', 900);
        Rows.Get('ORDER');
        Rows."Is Issued Quote" := false;
        Rows.Outcome := Rows.Outcome::Won;
        Rows."Decision Date" := DMY2Date(12, 6, 2026);
        Rows.Modify();
        Fixtures.AddQuote(Rows, 'QUOTE', 100);
        Fixtures.SetQuoteDecision(Rows, 'QUOTE', Rows.Outcome::Lost, DMY2Date(12, 6, 2026));

        Run(true, '');

        LibraryAssert.AreEqual(0, Snapshot."KPI 3 Decimal", 'Only the lost quote counts, so the hit rate is 0.');
    end;

    [Test]
    procedure DecisionDatesOnPeriodBoundaryAreInclusiveTest()
    begin
        // [SCENARIO] Decisions on the first and last day count, the day before and after do not
        Initialize();
        Fixtures.AddQuote(Rows, 'ON-FROM', 10);
        Fixtures.AddQuote(Rows, 'ON-TO', 10);
        Fixtures.AddQuote(Rows, 'BEFORE', 10);
        Fixtures.AddQuote(Rows, 'AFTER', 10);
        Fixtures.SetQuoteDecision(Rows, 'ON-FROM', Rows.Outcome::Won, Fixtures.PeriodFrom());
        Fixtures.SetQuoteDecision(Rows, 'ON-TO', Rows.Outcome::Lost, Fixtures.PeriodTo());
        Fixtures.SetQuoteDecision(Rows, 'BEFORE', Rows.Outcome::Won, Fixtures.PeriodFrom() - 1);
        Fixtures.SetQuoteDecision(Rows, 'AFTER', Rows.Outcome::Won, Fixtures.PeriodTo() + 1);

        Run(true, '');

        LibraryAssert.AreEqual(50, Snapshot."KPI 3 Decimal", 'Only the two boundary decisions count: one won, one lost.');
    end;

    [Test]
    procedure MixedCurrencyMakesValueNotApplicableTest()
    begin
        // [SCENARIO] An unverified currency basis hides the value, empties the chart and ranks by deadline
        Initialize();
        Fixtures.AddQuote(Rows, 'B', 100);
        Fixtures.AddQuote(Rows, 'A', 900);
        Fixtures.AddQuote(Rows, 'C', 50);
        Rows.Get('A');
        Rows.Normalized := false;
        Rows."Currency Code" := 'USD';
        Rows.Deadline := DMY2Date(1, 8, 2026);
        Rows.Modify();
        Rows.Get('B');
        Rows.Deadline := DMY2Date(1, 7, 2026);
        Rows.Modify();
        Rows.Get('C');
        Rows.Deadline := DMY2Date(1, 7, 2026);
        Rows.Modify();

        Run(true, 'EUR');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Available, Snapshot."KPI 1 Availability", 'The count stays valid.');
        LibraryAssert.AreEqual(3, Snapshot."KPI 1 Int", 'All three quotes are open.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 2 Availability", 'The value needs a verified single currency basis.');
        LibraryAssert.AreEqual('Value unavailable: mixed or unverified currency.', Snapshot."KPI 2 Note", 'The note should explain why.');
        LibraryAssert.AreEqual('Open Quotes by Deadline', Snapshot."List Caption", 'The list should rank by deadline.');
        LibraryAssert.AreEqual(0, Fixtures.ChartLabelCount(ChartJson), 'The chart must be empty.');
        LibraryAssert.AreEqual('Value unavailable: mixed or unverified currency.', Fixtures.ChartEmptyMessage(ChartJson), 'The chart should carry the M1 message.');

        TopQuotes.SetCurrentKey("Display Rank");
        TopQuotes.FindSet();
        LibraryAssert.AreEqual('B', TopQuotes."Case Key Text", 'Earliest deadline first, ties by case key.');
        TopQuotes.Next();
        LibraryAssert.AreEqual('C', TopQuotes."Case Key Text", 'Same deadline sorts by case key.');
        TopQuotes.Next();
        LibraryAssert.AreEqual('A', TopQuotes."Case Key Text", 'Latest deadline last.');
    end;

    [Test]
    procedure ForeignCurrencyAgainstBaseCurrencyIsMixedTest()
    begin
        // [SCENARIO] A normalized row whose currency differs from the base currency still blocks the value
        Initialize();
        Fixtures.AddQuote(Rows, 'USD1', 100);
        Rows.Get('USD1');
        Rows."Currency Code" := 'USD';
        Rows.Modify();

        Run(true, 'EUR');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 2 Availability", 'Foreign currency against base currency is mixed.');
    end;

    [Test]
    procedure PeriodWithoutDecisionsMakesHitRateNotApplicableTest()
    begin
        // [SCENARIO] No decisions in the period gives N/A, not 0
        Initialize();
        Fixtures.AddQuote(Rows, 'Q1', 100);

        Run(true, '');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::NotApplicable, Snapshot."KPI 3 Availability", 'Hit rate is undefined without decisions.');
    end;

    [Test]
    procedure UnavailableSourceNeverShowsZeroTest()
    begin
        // [SCENARIO] A failed source gives Unavailable for every KPI and an empty chart
        Initialize();
        Fixtures.AddQuote(Rows, 'Q1', 100);

        Run(false, '');

        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 1 Availability", 'KPI 1 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 2 Availability", 'KPI 2 should be unavailable.');
        LibraryAssert.AreEqual(Enum::"MBS PV KPI Availability"::Unavailable, Snapshot."KPI 3 Availability", 'KPI 3 should be unavailable.');
        LibraryAssert.AreEqual(0, TopQuotes.Count(), 'No exception rows are shown.');
        LibraryAssert.AreEqual(0, Fixtures.ChartLabelCount(ChartJson), 'The chart is empty.');
        LibraryAssert.AreEqual('PrintVis source data is unavailable.', Fixtures.ChartEmptyMessage(ChartJson), 'The chart explains the failure.');
    end;

    [Test]
    procedure EqualAmountsRankByCaseKeyTest()
    begin
        // [SCENARIO] Equal amounts rank by case key ascending, which keeps the list stable
        Initialize();
        Fixtures.AddQuote(Rows, 'ZZ', 100);
        Fixtures.AddQuote(Rows, 'AA', 100);
        Fixtures.AddQuote(Rows, 'MM', 300);

        Run(true, '');

        TopQuotes.SetCurrentKey("Display Rank");
        TopQuotes.FindSet();
        LibraryAssert.AreEqual('MM', TopQuotes."Case Key Text", 'Highest amount first.');
        TopQuotes.Next();
        LibraryAssert.AreEqual('AA', TopQuotes."Case Key Text", 'Tie sorts by case key ascending.');
        TopQuotes.Next();
        LibraryAssert.AreEqual('ZZ', TopQuotes."Case Key Text", 'Tie sorts by case key ascending.');
    end;

    [Test]
    procedure ExceptionListIsLimitedToTenRowsTest()
    var
        Index: Integer;
    begin
        // [SCENARIO] Only the top 10 open quotes are listed
        Initialize();
        for Index := 1 to 12 do
            Fixtures.AddQuote(Rows, CopyStr('Q' + Format(Index + 100), 1, 100), Index * 10);

        Run(true, '');

        LibraryAssert.AreEqual(12, Snapshot."KPI 1 Int", 'The KPI counts all open quotes.');
        LibraryAssert.AreEqual(10, TopQuotes.Count(), 'The list is limited to ten rows.');
        TopQuotes.SetCurrentKey("Display Rank");
        TopQuotes.FindFirst();
        LibraryAssert.AreEqual(120, TopQuotes."Normalized Amount", 'The largest quote is ranked first.');
    end;

    [Test]
    procedure ChartIsLimitedToFiveProductGroupsTest()
    var
        Index: Integer;
    begin
        // [SCENARIO] The chart shows the top 5 product groups by value
        Initialize();
        for Index := 1 to 7 do begin
            Fixtures.AddQuote(Rows, CopyStr('Q' + Format(Index), 1, 100), Index * 100);
            Rows.Get(CopyStr('Q' + Format(Index), 1, 100));
            Rows."Product Group" := CopyStr('G' + Format(Index), 1, 20);
            Rows.Modify();
        end;

        Run(true, '');

        LibraryAssert.AreEqual(5, Fixtures.ChartLabelCount(ChartJson), 'The chart is limited to five groups.');
        LibraryAssert.AreEqual('G7', Fixtures.ChartLabel(ChartJson, 0), 'The largest group comes first.');
        LibraryAssert.AreEqual(700, Fixtures.ChartValue(ChartJson, 'series1', 0), 'The value matches the group total.');
        LibraryAssert.AreEqual('G3', Fixtures.ChartLabel(ChartJson, 4), 'The fifth group is G3.');
    end;

    local procedure Initialize()
    begin
        Rows.Reset();
        Rows.DeleteAll();
        Clear(ChartJson);
    end;

    local procedure Run(SourceAvailable: Boolean; BaseCurrencyCode: Code[10])
    begin
        Calculator.Calculate(
            Rows, Fixtures.PeriodFrom(), Fixtures.PeriodTo(), Fixtures.BusinessDate(), Fixtures.GeneratedAt(),
            BaseCurrencyCode, SourceAvailable, Snapshot, TopQuotes, Groups, ChartJson);
    end;
}
