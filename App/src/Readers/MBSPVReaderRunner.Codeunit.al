namespace MBS.PrintVisPulse.Readers;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Enums;

/// <summary>
/// Runs each reader inside Codeunit.Run so a reader error never reaches the user. On failure the caller marks every KPI
/// of the dashboard Unavailable, and the raw error text goes to telemetry only. Also owns refresh telemetry.
/// </summary>
codeunit 50034 "MBS PV Reader Runner"
{
    Access = Internal;

    var
        ReaderFailedTelemetryLbl: Label 'PrintVis Pulse reader failed.', Locked = true;
        RefreshTelemetryLbl: Label 'PrintVis Pulse dashboard refreshed.', Locked = true;

    procedure ReadSales(FromDate: Date; ToDate: Date; var InputRows: Record "MBS PV Quote Input Buffer" temporary; var RowsRead: Integer): Boolean
    var
        SalesReader: Codeunit "MBS PV Sales Reader";
    begin
        InputRows.Reset();
        InputRows.DeleteAll();
        RowsRead := 0;
        SalesReader.SetPeriod(FromDate, ToDate);
        ClearLastError();
        if not SalesReader.Run() then begin
            LogReaderFailure(Enum::"MBS PV Dashboard Type"::Sales);
            exit(false);
        end;
        RowsRead := SalesReader.GetResult(InputRows);
        exit(true);
    end;

    procedure ReadProduction(FromDate: Date; ToDate: Date; var InputRows: Record "MBS PV Prod Input Buffer" temporary; var PromiseFieldName: Text[80]; var RowsRead: Integer): Boolean
    var
        ProdReader: Codeunit "MBS PV Prod Reader";
    begin
        InputRows.Reset();
        InputRows.DeleteAll();
        PromiseFieldName := '';
        RowsRead := 0;
        ProdReader.SetPeriod(FromDate, ToDate);
        ClearLastError();
        if not ProdReader.Run() then begin
            LogReaderFailure(Enum::"MBS PV Dashboard Type"::Production);
            exit(false);
        end;
        RowsRead := ProdReader.GetResult(InputRows, PromiseFieldName);
        exit(true);
    end;

    procedure ReadProfitability(FromDate: Date; ToDate: Date; var InputRows: Record "MBS PV Profit Input Buffer" temporary; var WipVerified: Boolean; var RowsRead: Integer): Boolean
    var
        ProfitReader: Codeunit "MBS PV Profit Reader";
    begin
        InputRows.Reset();
        InputRows.DeleteAll();
        WipVerified := false;
        RowsRead := 0;
        ProfitReader.SetPeriod(FromDate, ToDate);
        ClearLastError();
        if not ProfitReader.Run() then begin
            LogReaderFailure(Enum::"MBS PV Dashboard Type"::Profitability);
            exit(false);
        end;
        RowsRead := ProfitReader.GetResult(InputRows, WipVerified);
        exit(true);
    end;

    /// <summary>Logs one telemetry event per refresh: dashboard type, elapsed milliseconds, rows read and availability per KPI.</summary>
    procedure LogRefresh(DashboardType: Enum "MBS PV Dashboard Type"; ElapsedMs: Integer; RowsRead: Integer; var Snapshot: Record "MBS PV Snapshot Buffer" temporary)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('dashboardType', Format(DashboardType, 0, 9));
        Dimensions.Add('elapsedMs', Format(ElapsedMs, 0, 9));
        Dimensions.Add('rowsRead', Format(RowsRead, 0, 9));
        Dimensions.Add('kpi1Availability', Format(Snapshot."KPI 1 Availability", 0, 9));
        Dimensions.Add('kpi2Availability', Format(Snapshot."KPI 2 Availability", 0, 9));
        Dimensions.Add('kpi3Availability', Format(Snapshot."KPI 3 Availability", 0, 9));
        Session.LogMessage('MBSPV0001', RefreshTelemetryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure LogReaderFailure(DashboardType: Enum "MBS PV Dashboard Type")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('dashboardType', Format(DashboardType, 0, 9));
        Dimensions.Add('errorText', GetLastErrorText());
        Session.LogMessage('MBSPV0002', ReaderFailedTelemetryLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;
}
