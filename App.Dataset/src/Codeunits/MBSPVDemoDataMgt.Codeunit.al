namespace MBS.PrintVisPulse.Dataset;

/// <summary>
/// Creates a small PrintVis demo set (14 cases) dated relative to the work date, and deletes it again from the log.
/// Table numbers and field numbers come from the PrintVis 28.1.2.13 table definitions.
/// </summary>
codeunit 50202 "MBS PV Demo Data Mgt"
{
    Access = Internal;

    var
        Writer: Codeunit "MBS PV Demo Writer";
        BusinessDate: Date;
        NextPlanId: Integer;
        TableCase: Integer;
        TableJob: Integer;
        TableShipment: Integer;
        TablePlanning: Integer;
        TableCosting: Integer;
        TableLabor: Integer;
        IdBase: Integer;
        CreateQst: Label 'Create the PrintVis Pulse demo data? 14 cases with jobs, operations, shipments and costing entries are added to PrintVis in this company, and every record is logged.';
        DeleteQst: Label 'Delete all demo records listed in the log from PrintVis? This cannot be undone.';
        AlreadyCreatedErr: Label 'Demo data was already created. Run Delete Demo Data first.';
        IdClashErr: Label 'PVS Case %1 already exists. The demo ID range 990001 and up must be free.', Comment = '%1 = case ID';
        CreatedMsg: Label '%1 records created and logged.', Comment = '%1 = number of records';
        NothingToDeleteMsg: Label 'The log is empty. There is nothing to delete.';
        DeletedMsg: Label '%1 records deleted. %2 logged records were already gone.', Comment = '%1 = deleted, %2 = missing';

    procedure CreateDemoData()
    var
        DemoLog: Record "MBS PV Demo Log";
    begin
        if not DemoLog.IsEmpty() then
            Error(AlreadyCreatedErr);
        if not Confirm(CreateQst, false) then
            exit;

        Init();
        if Writer.KeyExists(TableCase, 1, IdBase + 1) then
            Error(IdClashErr, IdBase + 1);

        // Open quotes: Current Open Quotes, value, product group chart, deadline list
        CreateQuote(1, 'Alpine Dairy', 'Yogurt Cup Sleeve 200 gsm', 'FOLDING CARTON', -4, 5, 48000, 20000);
        CreateQuote(2, 'Nordic Cosmetics', 'Perfume Box 350 gsm', 'FOLDING CARTON', -9, 9, 72500, 30000);
        CreateQuote(3, 'Harbor Brewing', 'Beer Bottle Labels 4C + Varnish', 'LABELS', -12, 2, 31000, 15000);
        CreateQuote(4, 'City Library', 'Annual Report 64 pp', 'BROCHURES', -3, 14, 56000, 24000);
        CreateQuote(5, 'Fresh Market', 'Promo Flyer A5 1/1', 'FLYERS', -6, 7, 8900, 3500);
        // Lost quotes: Quote Hit Rate denominator
        CreateLostQuote(13, 'Summit Outdoor', 'Trail Guide 48 pp', 'BROCHURES', -26, -10, 34000);
        CreateLostQuote(14, 'Green Valley Farms', 'Seed Packet Labels', 'LABELS', -18, -3, 12500);

        // Closed (invoiced) orders: Realized Margin, Cases Over Estimate, On-Time Shipments
        CreateOrder(6, 'Alpine Dairy', 'Cheese Carton 300 gsm', 'FOLDING CARTON', -40, -25, -12, true, 40000, 30000, 27500);
        CreateOrder(7, 'Nordic Cosmetics', 'Lipstick Sleeve 300 gsm', 'FOLDING CARTON', -34, -22, -10, true, 26000, 18000, 21500);
        CreateOrder(11, 'Fresh Market', 'Event Tickets 5000 pcs', 'FLYERS', -20, -14, -6, true, 12000, 8500, 8000);
        CreateOrder(12, 'Harbor Brewing', 'Retail Posters B1', 'FLYERS', -38, -28, -16, true, 15000, 9000, 9800);
        // Open production orders: At-Risk, In-Progress, WIP
        CreateOrder(8, 'Harbor Brewing', 'Seasonal Labels 4C', 'LABELS', -22, -15, 1, false, 36000, 26000, 12000);
        CreateOrder(9, 'City Library', 'Museum Brochure 32 pp', 'BROCHURES', -16, -10, 2, false, 22000, 15000, 6000);
        CreateOrder(10, 'Fresh Market', 'Menu Cards A5', 'FLYERS', -12, -6, 0, false, 9000, 6000, 6600);

        // Shipments: promised date vs actual shipment date
        CreateShipment(6, true, -12, -13);
        CreateShipment(7, true, -10, -8);
        CreateShipment(11, true, -6, -6);
        CreateShipment(12, true, -16, -17);
        CreateShipment(8, false, 1, 0);
        CreateShipment(9, false, 2, 0);
        CreateShipment(10, false, 0, 0);

        // Operations (planning units) on press, die-cutter, guillotine and folder-gluer
        CreateOperation(6, 'PRESS-1', 'Offset Press 4C', 5, 4.5, true, true, -30, -27, -12);
        CreateOperation(7, 'PRESS-1', 'Offset Press 4C', 4, 4.8, true, true, -26, -23, -10);
        CreateOperation(11, 'PRESS-2', 'Digital Press', 3, 2.8, true, true, -10, -9, -6);
        CreateOperation(12, 'PRESS-1', 'Offset Press 4C', 6, 6.5, true, true, -22, -20, -16);
        CreateOperation(8, 'PRESS-1', 'Offset Press 4C', 6, 6.2, true, true, -6, -5, 1);
        CreateOperation(8, 'DIECUT-1', 'Die-Cutter Bobst', 5, 2.5, true, false, -2, 0, 1);
        CreateOperation(8, 'GLUER-1', 'Folder-Gluer', 4, 0, false, false, 0, 1, 1);
        CreateOperation(9, 'PRESS-1', 'Offset Press 4C', 8, 3, true, false, -3, 0, 2);
        CreateOperation(9, 'CUTTER-1', 'Guillotine Cutter', 2, 0, false, false, 1, 2, 2);
        CreateOperation(10, 'PRESS-2', 'Digital Press', 3, 0, false, false, 0, 0, 0);
        CreateOperation(10, 'CUTTER-1', 'Guillotine Cutter', 1.5, 0, false, false, 0, 1, 0);

        Message(CreatedMsg, Writer.GetInsertedCount());
    end;

    procedure DeleteDemoData()
    var
        DemoLog: Record "MBS PV Demo Log";
        Target: RecordRef;
        Deleted: Integer;
        Missing: Integer;
    begin
        if DemoLog.IsEmpty() then begin
            Message(NothingToDeleteMsg);
            exit;
        end;
        if not Confirm(DeleteQst, false) then
            exit;

        // Newest first, so children go before their parents
        DemoLog.SetCurrentKey("Entry No.");
        DemoLog.Ascending(false);
        if DemoLog.FindSet() then
            repeat
                Target.Open(DemoLog."Table No.");
                if Target.GetBySystemId(DemoLog."Source SystemId") then begin
                    Target.Delete(false);
                    Deleted += 1;
                end else
                    Missing += 1;
                Target.Close();
            until DemoLog.Next() = 0;

        DemoLog.Reset();
        DemoLog.DeleteAll();
        Message(DeletedMsg, Deleted, Missing);
    end;

    local procedure Init()
    begin
        BusinessDate := WorkDate();
        IdBase := 990000;
        NextPlanId := IdBase;
        TableCase := 6010312;
        TableJob := 6010313;
        TableShipment := 6010314;
        TablePlanning := 6010323;
        TableLabor := 6010325;
        TableCosting := 6010342;
    end;

    local procedure D(Offset: Integer): Date
    begin
        exit(BusinessDate + Offset);
    end;

    local procedure QuoteNo(N: Integer): Text
    begin
        exit('DQ' + PadStr('', 3 - StrLen(Format(N)), '0') + Format(N));
    end;

    local procedure OrderNo(N: Integer): Text
    begin
        exit('DO' + PadStr('', 3 - StrLen(Format(N)), '0') + Format(N));
    end;

    local procedure InsertCase(N: Integer; TypeOrdinal: Integer; Customer: Text; JobName: Text; ProductGroup: Text; QuoteDate: Date; OrderDate: Date; DeadlineDate: Date)
    begin
        Writer.StartRecord(TableCase);
        Writer.SetInt(1, IdBase + N);
        Writer.SetOption(2, TypeOrdinal); // Request, Quote, Order, Production Order
        Writer.SetText(3, QuoteNo(N));
        Writer.SetText(21, Customer);
        Writer.SetText(41, Customer);
        Writer.SetText(61, ProductGroup);
        Writer.SetText(63, JobName);
        Writer.SetDate(10, QuoteDate);
        Writer.SetDate(12, QuoteDate);
        Writer.SetDate(250, QuoteDate);
        Writer.SetDate(82, DeadlineDate);
        Writer.SetDate(190, DeadlineDate);
        if OrderDate <> 0D then begin
            Writer.SetText(4, OrderNo(N));
            Writer.SetDate(11, OrderDate);
            Writer.SetDate(116, OrderDate);
        end else
            Writer.SetDate(116, QuoteDate);
    end;

    local procedure InsertJob(N: Integer; JobName: Text; ProductGroup: Text; Price: Decimal; EstimatedCost: Decimal; RequestedDelivery: Date; IsOrder: Boolean)
    begin
        Writer.StartRecord(TableJob);
        Writer.SetInt(1, IdBase + N);
        Writer.SetInt(2, 1);
        Writer.SetInt(3, 1);
        Writer.SetBool(10, true); // Active
        Writer.SetOption(9, 0); // Alternative: none
        Writer.SetText(6, JobName);
        Writer.SetText(22, JobName);
        Writer.SetText(25, ProductGroup);
        Writer.SetInt(20, 5000);
        Writer.SetText(200, QuoteNo(N));
        Writer.SetBool(190, true); // Quote Calculation
        Writer.SetDate(206, RequestedDelivery);
        Writer.SetDate(220, RequestedDelivery);
        Writer.SetDec(105, Price); // Quoted Price
        Writer.SetDec(112, Price - EstimatedCost); // Net Profit Amount
        Writer.SetDec(107, Price - EstimatedCost); // Contribution Margin
        if Price <> 0 then
            Writer.SetDec(108, Round((Price - EstimatedCost) / Price * 100, 0.1));
        if IsOrder then begin
            Writer.SetText(201, OrderNo(N));
            Writer.SetBool(191, true); // Order Calculation
            Writer.SetBool(192, true); // Production Calculation
        end;
        Writer.InsertAndLog();
    end;

    local procedure CreateQuote(N: Integer; Customer: Text; JobName: Text; ProductGroup: Text; QuoteOffset: Integer; DeadlineOffset: Integer; Price: Decimal; EstimatedCost: Decimal)
    begin
        InsertCase(N, 1, Customer, JobName, ProductGroup, D(QuoteOffset), 0D, D(DeadlineOffset));
        Writer.SetDec(155, Price); // Quoted Sales Price
        Writer.InsertAndLog();
        InsertJob(N, JobName, ProductGroup, Price, EstimatedCost, D(DeadlineOffset), false);
    end;

    local procedure CreateLostQuote(N: Integer; Customer: Text; JobName: Text; ProductGroup: Text; QuoteOffset: Integer; RejectOffset: Integer; Price: Decimal)
    begin
        InsertCase(N, 1, Customer, JobName, ProductGroup, D(QuoteOffset), 0D, D(RejectOffset + 7));
        Writer.SetText(76, 'PRICE'); // Rejection Code
        Writer.SetDate(116, D(RejectOffset)); // Status Changed On
        Writer.SetDec(155, Price); // Quoted Sales Price
        Writer.InsertAndLog();
        InsertJob(N, JobName, ProductGroup, Price, Round(Price * 0.7, 1), D(RejectOffset + 7), false);
    end;

    local procedure CreateOrder(N: Integer; Customer: Text; JobName: Text; ProductGroup: Text; QuoteOffset: Integer; OrderOffset: Integer; DeadlineOffset: Integer; Closed: Boolean; Price: Decimal; EstimatedCost: Decimal; ActualCost: Decimal)
    begin
        InsertCase(N, 2, Customer, JobName, ProductGroup, D(QuoteOffset), D(OrderOffset), D(DeadlineOffset));
        Writer.SetDec(155, Price); // Quoted Sales Price
        Writer.SetBool(16, not Closed); // Can Be Planned
        Writer.SetBool(19, not Closed); // WIP
        if Closed then begin
            Writer.SetBool(9, true); // Invoiced
            Writer.SetBool(18, true); // Ended
            Writer.SetDate(13, D(DeadlineOffset + 1)); // Posting Date
            Writer.SetDate(210, D(DeadlineOffset + 1)); // Statistics Closing Date
            Writer.SetDate(116, D(DeadlineOffset + 1)); // Status Changed On
        end;
        Writer.InsertAndLog();
        InsertJob(N, JobName, ProductGroup, Price, EstimatedCost, D(DeadlineOffset), true);

        // Posted actual cost: material (variable) and labor, additive
        CreateCostEntry(N, D(OrderOffset + 3), Round(ActualCost * 0.55, 1), 0, Round(Price * 0.55, 1), 0, Closed);
        CreateCostEntry(N, D(OrderOffset + 5), 0, ActualCost - Round(ActualCost * 0.55, 1), Price - Round(Price * 0.55, 1), 0, Closed);
    end;

    local procedure CreateCostEntry(N: Integer; PostingDate: Date; VariableCost: Decimal; LaborCost: Decimal; SalesPrice: Decimal; Hours: Decimal; Invoiced: Boolean)
    var
        Total: Decimal;
    begin
        Total := VariableCost + LaborCost;
        Writer.StartRecord(TableCosting);
        Writer.SetInt(1, Writer.NextEntryNo(TableCosting, 1));
        Writer.SetInt(100, IdBase + N);
        Writer.SetInt(111, 1);
        Writer.SetDate(5, PostingDate);
        Writer.SetDec(410, VariableCost);
        Writer.SetDec(420, LaborCost);
        Writer.SetDec(490, Total);
        Writer.SetDec(550, Total);
        Writer.SetDec(600, SalesPrice);
        if Invoiced then
            Writer.SetDec(610, SalesPrice);
        if Hours <> 0 then
            Writer.SetDec(201, Hours);
        Writer.InsertAndLog();
    end;

    local procedure CreateShipment(N: Integer; Shipped: Boolean; PromiseOffset: Integer; ShipOffset: Integer)
    begin
        Writer.StartRecord(TableShipment);
        Writer.SetInt(1, IdBase + N);
        Writer.SetInt(2, 1);
        Writer.SetInt(3, 1);
        Writer.SetBool(6, Shipped);
        Writer.SetBool(7, true); // Active Production Order
        Writer.SetText(99, OrderNo(N));
        Writer.SetDate(11, D(PromiseOffset)); // Promised Date Of Shipment
        Writer.SetDate(550, D(PromiseOffset)); // Destination Delivery Date
        Writer.SetDec(10, 5000); // Qty. To Ship
        Writer.SetDec(14, 5000); // Promised Qty.
        if Shipped then
            Writer.SetDate(12, D(ShipOffset)); // Shipment Date
        Writer.InsertAndLog();
    end;

    local procedure CreateOperation(N: Integer; CapacityUnit: Text; Description: Text; PlannedHours: Decimal; SpentHours: Decimal; Started: Boolean; Completed: Boolean; StartOffset: Integer; EndOffset: Integer; DueOffset: Integer)
    var
        PlanId: Integer;
    begin
        NextPlanId += 1;
        PlanId := NextPlanId;
        Writer.StartRecord(TablePlanning);
        Writer.SetInt(3, 0); // Simulation Version
        Writer.SetInt(1, IdBase + N);
        Writer.SetInt(4, PlanId);
        Writer.SetInt(5, 1);
        Writer.SetInt(2, 1); // Job
        Writer.SetInt(9, 1); // Version
        Writer.SetText(6, CapacityUnit);
        Writer.SetText(40, CapacityUnit);
        Writer.SetText(30, Description);
        Writer.SetText(8, OrderNo(N));
        Writer.SetBool(16, true); // Active
        Writer.SetBool(15, false); // Archived
        Writer.SetDate(20, D(StartOffset));
        Writer.SetDate(22, D(EndOffset));
        Writer.SetDate(26, D(DueOffset)); // Finished No Later Than Date
        Writer.SetDec(60, PlannedHours);
        Writer.SetDec(117, SpentHours); // Actual Time
        Writer.SetBool(457, Started);
        Writer.SetBool(458, Completed);
        if Completed then
            Writer.SetDec(455, 100);
        Writer.InsertAndLog();

        if SpentHours > 0 then begin
            Writer.StartRecord(TableLabor);
            Writer.SetInt(1, Writer.NextEntryNo(TableLabor, 1));
            Writer.SetInt(2, IdBase + N);
            Writer.SetInt(26, PlanId);
            Writer.SetText(27, CapacityUnit);
            Writer.SetDate(9, D(StartOffset));
            Writer.SetDec(16, SpentHours);
            Writer.SetText(22, 'DEMO-OPERATOR');
            Writer.InsertAndLog();
        end;
    end;
}
