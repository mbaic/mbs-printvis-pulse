namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;

/// <summary>
/// Manual-bind stand-in for a PrintVis binding. It lets the tests drive the reader runner and the drill-down
/// without PrintVis installed.
/// </summary>
codeunit 50106 "MBS PV Test Reader Stub"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        FailReader: Boolean;
        OpenedSystemId: Guid;

    procedure SetFailReader(NewFailReader: Boolean)
    begin
        FailReader := NewFailReader;
    end;

    procedure GetOpenedSystemId(): Guid
    begin
        exit(OpenedSystemId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV Sales Reader", OnReadSource, '', false, false)]
    local procedure OnReadSalesSource(PeriodFrom: Date; PeriodTo: Date; var InputRows: Record "MBS PV Quote Input Buffer" temporary; var IsHandled: Boolean)
    begin
        if FailReader then
            Error('Simulated PrintVis failure.');

        InputRows.Init();
        InputRows."Case Key Text" := 'STUB1';
        InputRows."Is Issued Quote" := true;
        InputRows.Normalized := true;
        InputRows."Normalized Amount" := 100;
        InputRows.Insert();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV Prod Reader", OnReadSource, '', false, false)]
    local procedure OnReadProdSource(PeriodFrom: Date; PeriodTo: Date; var InputRows: Record "MBS PV Prod Input Buffer" temporary; var PromiseFieldNameResult: Text[80]; var IsHandled: Boolean)
    begin
        InputRows.Init();
        InputRows."Operation Key Text" := 'STUB1|10';
        InputRows.Insert();
        PromiseFieldNameResult := 'Shipment Date Job';
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV Profit Reader", OnReadSource, '', false, false)]
    local procedure OnReadProfitSource(PeriodFrom: Date; PeriodTo: Date; var InputRows: Record "MBS PV Profit Input Buffer" temporary; var WipVerifiedResult: Boolean; var IsHandled: Boolean)
    begin
        InputRows.Init();
        InputRows."Case Key Text" := 'STUB1';
        InputRows.Insert();
        WipVerifiedResult := true;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV DrillDown Mgt.", OnOpenCase, '', false, false)]
    local procedure OnOpenCaseStub(SourceSystemId: Guid; var IsHandled: Boolean)
    begin
        OpenedSystemId := SourceSystemId;
        IsHandled := true;
    end;
}
