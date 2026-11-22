namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Enums;
using MBS.PrintVisPulse.Readers;
using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Orchestrates one bounded refresh per dashboard: period, reader (inside the runner), pure calculator, telemetry.
/// The only place that reads the clock (WorkDate and CurrentDateTime) and passes it to the calculators.
/// </summary>
codeunit 50026 "MBS PV Refresh Mgt"
{
    Access = Internal;

    procedure RefreshSales(PeriodFilter: Enum "MBS PV Period Filter"; var Snapshot: Record "MBS PV Snapshot Buffer" temporary; var TopQuotes: Record "MBS PV Open Quote Row" temporary; var Groups: Record "MBS PV Chart Group Buffer" temporary; var ChartJson: Text)
    var
        Runner: Codeunit "MBS PV Reader Runner";
        Calculator: Codeunit "MBS PV Sales Calculator";
        InputRows: Record "MBS PV Quote Input Buffer" temporary;
        StartedAt: DateTime;
        BusinessDate: Date;
        FromDate: Date;
        ToDate: Date;
        RowsRead: Integer;
        SourceAvailable: Boolean;
    begin
        StartedAt := CurrentDateTime();
        GetPeriod(PeriodFilter, BusinessDate, FromDate, ToDate);
        SourceAvailable := Runner.ReadSales(FromDate, ToDate, InputRows, RowsRead);
        Calculator.Calculate(InputRows, FromDate, ToDate, BusinessDate, StartedAt, GetBaseCurrencyCode(), SourceAvailable, Snapshot, TopQuotes, Groups, ChartJson);
        Runner.LogRefresh(Enum::"MBS PV Dashboard Type"::Sales, GetElapsedMs(StartedAt), RowsRead, Snapshot);
    end;

    procedure RefreshProduction(PeriodFilter: Enum "MBS PV Period Filter"; var Snapshot: Record "MBS PV Snapshot Buffer" temporary; var TopRisks: Record "MBS PV Prod Risk Row" temporary; var Groups: Record "MBS PV Chart Group Buffer" temporary; var ChartJson: Text)
    var
        Runner: Codeunit "MBS PV Reader Runner";
        Calculator: Codeunit "MBS PV Prod Calculator";
        InputRows: Record "MBS PV Prod Input Buffer" temporary;
        StartedAt: DateTime;
        BusinessDate: Date;
        FromDate: Date;
        ToDate: Date;
        PromiseFieldName: Text[80];
        RowsRead: Integer;
        SourceAvailable: Boolean;
    begin
        StartedAt := CurrentDateTime();
        GetPeriod(PeriodFilter, BusinessDate, FromDate, ToDate);
        SourceAvailable := Runner.ReadProduction(FromDate, ToDate, InputRows, PromiseFieldName, RowsRead);
        Calculator.Calculate(InputRows, FromDate, ToDate, BusinessDate, StartedAt, PromiseFieldName, SourceAvailable, Snapshot, TopRisks, Groups, ChartJson);
        Runner.LogRefresh(Enum::"MBS PV Dashboard Type"::Production, GetElapsedMs(StartedAt), RowsRead, Snapshot);
    end;

    procedure RefreshProfitability(PeriodFilter: Enum "MBS PV Period Filter"; var Snapshot: Record "MBS PV Snapshot Buffer" temporary; var TopOverruns: Record "MBS PV Profit Overrun Row" temporary; var Groups: Record "MBS PV Chart Group Buffer" temporary; var ChartJson: Text)
    var
        Runner: Codeunit "MBS PV Reader Runner";
        Calculator: Codeunit "MBS PV Profit Calculator";
        InputRows: Record "MBS PV Profit Input Buffer" temporary;
        StartedAt: DateTime;
        BusinessDate: Date;
        FromDate: Date;
        ToDate: Date;
        WipVerified: Boolean;
        RowsRead: Integer;
        SourceAvailable: Boolean;
    begin
        StartedAt := CurrentDateTime();
        GetPeriod(PeriodFilter, BusinessDate, FromDate, ToDate);
        SourceAvailable := Runner.ReadProfitability(FromDate, ToDate, InputRows, WipVerified, RowsRead);
        Calculator.Calculate(InputRows, FromDate, ToDate, BusinessDate, StartedAt, WipVerified, SourceAvailable, Snapshot, TopOverruns, Groups, ChartJson);
        Runner.LogRefresh(Enum::"MBS PV Dashboard Type"::Profitability, GetElapsedMs(StartedAt), RowsRead, Snapshot);
    end;

    local procedure GetPeriod(PeriodFilter: Enum "MBS PV Period Filter"; var BusinessDate: Date; var FromDate: Date; var ToDate: Date)
    var
        PeriodMgt: Codeunit "MBS PV Period Mgt";
    begin
        BusinessDate := WorkDate();
        PeriodMgt.GetRange(PeriodFilter, BusinessDate, FromDate, ToDate);
    end;

    local procedure GetElapsedMs(StartedAt: DateTime): Integer
    var
        Elapsed: Duration;
    begin
        Elapsed := CurrentDateTime() - StartedAt;
        exit(Elapsed);
    end;

    local procedure GetBaseCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.SetLoadFields("LCY Code");
        if GeneralLedgerSetup.Get() then
            exit(GeneralLedgerSetup."LCY Code");
    end;
}
