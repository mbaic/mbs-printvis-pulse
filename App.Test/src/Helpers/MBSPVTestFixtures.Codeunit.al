namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Normalized input row builders and chart JSON readers for the calculator tests.
/// The fixed dates make every test deterministic: the calculators never read the clock.
/// </summary>
codeunit 50100 "MBS PV Test Fixtures"
{
    Access = Internal;

    procedure PeriodFrom(): Date
    begin
        exit(DMY2Date(1, 6, 2026));
    end;

    procedure PeriodTo(): Date
    begin
        exit(DMY2Date(30, 6, 2026));
    end;

    procedure BusinessDate(): Date
    begin
        exit(DMY2Date(30, 6, 2026));
    end;

    procedure GeneratedAt(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(30, 6, 2026), 120000T));
    end;

    procedure AddQuote(var Rows: Record "MBS PV Quote Input Buffer" temporary; CaseKey: Text[100]; Amount: Decimal)
    begin
        Rows.Init();
        Rows."Case Key Text" := CaseKey;
        Rows."Source SystemId" := CreateGuid();
        Rows."Quote No." := CopyStr(CaseKey, 1, MaxStrLen(Rows."Quote No."));
        Rows."Customer Name" := 'Customer ' + CaseKey;
        Rows."Product Group" := 'CARTON';
        Rows."Quoted Amount" := Amount;
        Rows."Normalized Amount" := Amount;
        Rows.Normalized := true;
        Rows."Is Issued Quote" := true;
        Rows.Deadline := DMY2Date(15, 7, 2026);
        Rows.Insert();
    end;

    procedure SetQuoteDecision(var Rows: Record "MBS PV Quote Input Buffer" temporary; CaseKey: Text[100]; Outcome: Option Open,Won,Lost; DecisionDate: Date)
    begin
        Rows.Get(CaseKey);
        Rows.Outcome := Outcome;
        Rows."Decision Date" := DecisionDate;
        Rows.Modify();
    end;

    procedure AddOperation(var Rows: Record "MBS PV Prod Input Buffer" temporary; OperationKey: Text[100]; DueDate: Date; PlannedHours: Decimal; SpentHours: Decimal)
    begin
        Rows.Init();
        Rows."Operation Key Text" := OperationKey;
        Rows."Row Type" := Rows."Row Type"::Operation;
        Rows."Source SystemId" := CreateGuid();
        Rows."Case No." := CopyStr(OperationKey, 1, MaxStrLen(Rows."Case No."));
        Rows."Customer Name" := 'Customer';
        Rows."Capacity Unit" := 'PRESS1';
        Rows."Is Active" := true;
        Rows."Is Current Version" := true;
        Rows."Due Date" := DueDate;
        Rows."Due Date Source" := Rows."Due Date Source"::Operation;
        Rows."Planned Hours" := PlannedHours;
        Rows."Spent Hours" := SpentHours;
        Rows.Insert();
    end;

    procedure AddShipment(var Rows: Record "MBS PV Prod Input Buffer" temporary; ShipmentKey: Text[100]; ActualDate: Date; PromiseDate: Date)
    begin
        Rows.Init();
        Rows."Operation Key Text" := ShipmentKey;
        Rows."Row Type" := Rows."Row Type"::Shipment;
        Rows."Source SystemId" := CreateGuid();
        Rows."Is Shipped" := true;
        Rows."Actual Shipment Date" := ActualDate;
        Rows."Promise Date" := PromiseDate;
        Rows.Insert();
    end;

    procedure AddCase(var Rows: Record "MBS PV Profit Input Buffer" temporary; CaseKey: Text[100]; EstimatedCost: Decimal; ActualCostEntryAmount: Decimal)
    begin
        Rows.Init();
        Rows."Case Key Text" := CaseKey;
        Rows."Source SystemId" := CreateGuid();
        Rows."Case No." := CopyStr(CaseKey, 1, MaxStrLen(Rows."Case No."));
        Rows."Customer Name" := 'Customer ' + CaseKey;
        Rows."Product Group" := 'CARTON';
        Rows.Normalized := true;
        Rows."Is Active" := true;
        Rows."Is Sold Version" := true;
        Rows."Has Estimate" := EstimatedCost > 0;
        Rows."Estimated Cost" := EstimatedCost;
        Rows."Cost Entry Amount" := ActualCostEntryAmount;
        Rows.Insert();
    end;

    procedure CloseCase(var Rows: Record "MBS PV Profit Input Buffer" temporary; CaseKey: Text[100]; CloseDate: Date; InvoicedSales: Decimal; CreditMemoSales: Decimal)
    begin
        Rows.Get(CaseKey);
        Rows."Is Active" := false;
        Rows."Is Closed" := true;
        Rows."Close Date" := CloseDate;
        Rows."Invoiced Sales" := InvoicedSales;
        Rows."Credit Memo Sales" := CreditMemoSales;
        Rows.Modify();
    end;

    procedure ChartLabelCount(ChartJson: Text): Integer
    var
        Root: JsonObject;
        LabelsToken: JsonToken;
    begin
        Root.ReadFrom(ChartJson);
        Root.Get('labels', LabelsToken);
        exit(LabelsToken.AsArray().Count());
    end;

    procedure ChartLabel(ChartJson: Text; Index: Integer): Text
    var
        Root: JsonObject;
        LabelsToken: JsonToken;
        ItemToken: JsonToken;
    begin
        Root.ReadFrom(ChartJson);
        Root.Get('labels', LabelsToken);
        LabelsToken.AsArray().Get(Index, ItemToken);
        exit(ItemToken.AsValue().AsText());
    end;

    procedure ChartValue(ChartJson: Text; SeriesName: Text; Index: Integer): Decimal
    var
        Root: JsonObject;
        SeriesToken: JsonToken;
        ItemToken: JsonToken;
    begin
        Root.ReadFrom(ChartJson);
        Root.Get(SeriesName, SeriesToken);
        SeriesToken.AsArray().Get(Index, ItemToken);
        exit(ItemToken.AsValue().AsDecimal());
    end;

    procedure ChartHasProperty(ChartJson: Text; PropertyName: Text): Boolean
    var
        Root: JsonObject;
    begin
        Root.ReadFrom(ChartJson);
        exit(Root.Contains(PropertyName));
    end;

    procedure ChartEmptyMessage(ChartJson: Text): Text
    var
        Root: JsonObject;
        MessageToken: JsonToken;
    begin
        Root.ReadFrom(ChartJson);
        Root.Get('emptyMessage', MessageToken);
        exit(MessageToken.AsValue().AsText());
    end;
}
