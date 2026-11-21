namespace MBS.PrintVisPulse.Readers;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Reader for the Sales and Quote Pipeline dashboard. Runs under MBS PV Reader Runner (Codeunit.Run), so any error degrades the dashboard to Unavailable.
/// The PrintVis binding is supplied through OnReadSource. A verified binding must follow the rules in App/DATA-CONTRACT.md:
/// ReadIsolation ReadCommitted, SetLoadFields on normal fields, DT2Date for DateTime fields, one row per primary key, no writes.
/// Until a binding handles the event, the reader fails and the dashboard shows Unavailable instead of an unverified number.
/// </summary>
codeunit 50030 "MBS PV Sales Reader"
{
    Access = Internal;

    trigger OnRun()
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        Handled := false;
        OnReadSource(FromDate, ToDate, Buffer, Handled);
        if not Handled then
            Error(SourceNotVerifiedErr);
    end;

    var
        Buffer: Record "MBS PV Quote Input Buffer" temporary;
        FromDate: Date;
        ToDate: Date;
        Handled: Boolean;
        SourceNotVerifiedErr: Label 'The PrintVis data contract for this dashboard is not verified. See App/DATA-CONTRACT.md.';

    procedure SetPeriod(NewFromDate: Date; NewToDate: Date)
    begin
        FromDate := NewFromDate;
        ToDate := NewToDate;
    end;

    /// <summary>Copies the rows read by the last successful run into the caller's buffer and returns the row count.</summary>
    procedure GetResult(var Result: Record "MBS PV Quote Input Buffer" temporary): Integer
    begin
        Result.Reset();
        Result.DeleteAll();
        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                Result := Buffer;
                Result.Insert();
            until Buffer.Next() = 0;
        exit(Buffer.Count());
    end;

    /// <summary>Raised once per refresh. A subscriber fills the buffer and sets Handled to true.</summary>
    [IntegrationEvent(false, false)]
    procedure OnReadSource(PeriodFrom: Date; PeriodTo: Date; var InputRows: Record "MBS PV Quote Input Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
}
