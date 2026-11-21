namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Pure, deterministic Production Pulse calculator. It never reads the clock or the database.
/// The reader supplies hours already converted to hours and dates already converted with DT2Date.
/// </summary>
codeunit 50021 "MBS PV Prod Calculator"
{
    Access = Internal;

    var
        ChartJsonMgt: Codeunit "MBS PV Chart Json";
        OnTimeCaptionLbl: Label 'On-Time Shipments %';
        AtRiskCaptionLbl: Label 'At-Risk Operations';
        AtRiskFallbackCaptionLbl: Label 'Incomplete Operations Near Requested Delivery';
        InProgressCaptionLbl: Label 'In-Progress Operations';
        ChartTitleLbl: Label 'Planned vs. Spent Hours by Capacity Unit';
        PlannedHoursLbl: Label 'Planned Hours';
        SpentHoursLbl: Label 'Spent Hours';
        ListCaptionLbl: Label 'Top At-Risk Operations by Due Date';
        NoDataMsgLbl: Label 'No data for selected period.';
        SourceUnavailableMsgLbl: Label 'PrintVis source data is unavailable.';
        PromiseFieldNoteLbl: Label 'Promise date field: %1.', Comment = '%1 = verified PrintVis promise date field name';
        PromiseFieldMissingNoteLbl: Label 'Promise date field is not verified.';
        DueDateSourceNoteLbl: Label 'Due date source: %1.', Comment = '%1 = list of due date sources';
        OperationDueDateTxt: Label 'operation due date';
        CaseDueDateTxt: Label 'case due date';
        RequestedDeliveryTxt: Label 'requested delivery date';

    procedure Calculate(
        var InputRows: Record "MBS PV Prod Input Buffer" temporary;
        FromDate: Date;
        ToDate: Date;
        BusinessDate: Date;
        GeneratedAt: DateTime;
        PromiseFieldName: Text[80];
        SourceAvailable: Boolean;
        var Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        var TopRisks: Record "MBS PV Prod Risk Row" temporary;
        var Groups: Record "MBS PV Chart Group Buffer" temporary;
        var ChartJson: Text)
    var
        EligibleShipments: Integer;
        OnTimeShipments: Integer;
        ExcludedShipments: Integer;
        AtRiskCount: Integer;
        InProgressCount: Integer;
        MissingDueDateCount: Integer;
        HasOperationSource: Boolean;
        HasCaseSource: Boolean;
        HasRequestedSource: Boolean;
    begin
        Snapshot.Reset();
        Snapshot.DeleteAll();
        TopRisks.Reset();
        TopRisks.DeleteAll();
        Groups.Reset();
        Groups.DeleteAll();

        Snapshot.Init();
        Snapshot."Primary Key" := 'PROD';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Production;
        Snapshot."Generated At" := GeneratedAt;
        Snapshot."Business Date" := BusinessDate;
        Snapshot."Period From" := FromDate;
        Snapshot."Period To" := ToDate;
        Snapshot."KPI 1 Caption" := OnTimeCaptionLbl;
        Snapshot."KPI 2 Caption" := AtRiskFallbackCaptionLbl;
        Snapshot."KPI 3 Caption" := InProgressCaptionLbl;
        Snapshot."Chart Caption" := ChartTitleLbl;
        Snapshot."List Caption" := ListCaptionLbl;

        if not SourceAvailable then begin
            Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Unavailable;
            Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Unavailable;
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Unavailable;
            Snapshot.Insert();
            ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, PlannedHoursLbl, SpentHoursLbl, SourceUnavailableMsgLbl, Groups);
            exit;
        end;

        InputRows.Reset();
        if InputRows.FindSet() then
            repeat
                if InputRows."Row Type" = InputRows."Row Type"::Shipment then
                    CountShipment(InputRows, FromDate, ToDate, EligibleShipments, OnTimeShipments, ExcludedShipments)
                else
                    if IsEligibleOperation(InputRows) then begin
                        if InputRows."Is Started" then
                            InProgressCount += 1;

                        ChartJsonMgt.AddGroupTotal(Groups, InputRows."Capacity Unit", InputRows."Planned Hours", InputRows."Spent Hours", false);

                        if InputRows."Due Date" = 0D then
                            MissingDueDateCount += 1
                        else begin
                            case InputRows."Due Date Source" of
                                InputRows."Due Date Source"::Operation:
                                    HasOperationSource := true;
                                InputRows."Due Date Source"::CaseDueDate:
                                    HasCaseSource := true;
                                InputRows."Due Date Source"::RequestedDelivery:
                                    HasRequestedSource := true;
                            end;
                            if InputRows."Due Date" <= BusinessDate + 1 then begin
                                AtRiskCount += 1;
                                InsertRiskRow(TopRisks, InputRows);
                            end;
                        end;
                    end;
            until InputRows.Next() = 0;

        // KPI 1: on-time shipments
        Snapshot."Excluded Count 1" := ExcludedShipments;
        if PromiseFieldName = '' then begin
            Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Unavailable;
            Snapshot."KPI 1 Note" := PromiseFieldMissingNoteLbl;
        end else begin
            Snapshot."KPI 1 Note" := StrSubstNo(PromiseFieldNoteLbl, PromiseFieldName);
            if EligibleShipments = 0 then
                Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::NotApplicable
            else begin
                Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Available;
                Snapshot."KPI 1 Decimal" := Round((OnTimeShipments / EligibleShipments) * 100, 0.1);
            end;
        end;

        // KPI 2: at-risk operations. The standard caption is allowed only when every dated operation uses an operation-level due date.
        Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Available;
        Snapshot."KPI 2 Int" := AtRiskCount;
        Snapshot."Excluded Count 2" := MissingDueDateCount;
        if HasOperationSource and (not HasCaseSource) and (not HasRequestedSource) then
            Snapshot."KPI 2 Caption" := AtRiskCaptionLbl;
        Snapshot."KPI 2 Note" := CopyStr(StrSubstNo(DueDateSourceNoteLbl, BuildSourceList(HasOperationSource, HasCaseSource, HasRequestedSource)), 1, MaxStrLen(Snapshot."KPI 2 Note"));

        // KPI 3: in-progress operations
        Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Available;
        Snapshot."KPI 3 Int" := InProgressCount;

        TrimToTop10(TopRisks);
        ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, PlannedHoursLbl, SpentHoursLbl, NoDataMsgLbl, Groups);
        Snapshot.Insert();
    end;

    local procedure IsEligibleOperation(var Row: Record "MBS PV Prod Input Buffer" temporary): Boolean
    begin
        exit(Row."Is Active" and (not Row."Is Archived") and Row."Is Current Version" and (not Row."Is Complete"));
    end;

    local procedure CountShipment(var Row: Record "MBS PV Prod Input Buffer" temporary; FromDate: Date; ToDate: Date; var Eligible: Integer; var OnTime: Integer; var Excluded: Integer)
    begin
        if not Row."Is Shipped" then
            exit;
        if Row."Actual Shipment Date" = 0D then begin
            Excluded += 1;
            exit;
        end;
        if (Row."Actual Shipment Date" < FromDate) or (Row."Actual Shipment Date" > ToDate) then
            exit;
        if Row."Promise Date" = 0D then begin
            Excluded += 1;
            exit;
        end;
        Eligible += 1;
        if Row."Actual Shipment Date" <= Row."Promise Date" then
            OnTime += 1;
    end;

    local procedure BuildSourceList(HasOperation: Boolean; HasCase: Boolean; HasRequested: Boolean): Text
    var
        SourceList: Text;
    begin
        if HasOperation then
            SourceList := OperationDueDateTxt;
        if HasCase then
            SourceList := AppendSource(SourceList, CaseDueDateTxt);
        if HasRequested then
            SourceList := AppendSource(SourceList, RequestedDeliveryTxt);
        exit(SourceList);
    end;

    local procedure AppendSource(SourceList: Text; NewSource: Text): Text
    begin
        if SourceList = '' then
            exit(NewSource);
        exit(SourceList + ', ' + NewSource);
    end;

    local procedure InsertRiskRow(var TopRisks: Record "MBS PV Prod Risk Row" temporary; var InputRow: Record "MBS PV Prod Input Buffer" temporary)
    begin
        TopRisks.Init();
        TopRisks."Operation Key Text" := InputRow."Operation Key Text";
        TopRisks."Source SystemId" := InputRow."Source SystemId";
        TopRisks."Case No." := InputRow."Case No.";
        TopRisks."Customer Name" := InputRow."Customer Name";
        TopRisks."Capacity Unit" := InputRow."Capacity Unit";
        TopRisks."Due Date" := InputRow."Due Date";
        TopRisks."Planned Hours" := InputRow."Planned Hours";
        TopRisks."Spent Hours" := InputRow."Spent Hours";
        // Earliest due date first: the date serial number is the ascending sort value.
        TopRisks."Sort Amount" := InputRow."Due Date" - 0D;
        TopRisks.Insert();
    end;

    local procedure TrimToTop10(var TopRisks: Record "MBS PV Prod Risk Row" temporary)
    var
        RankNo: Integer;
    begin
        TopRisks.Reset();
        TopRisks.SetCurrentKey("Sort Amount", "Operation Key Text");
        if TopRisks.FindSet() then
            repeat
                RankNo += 1;
                TopRisks."Display Rank" := RankNo;
                TopRisks.Modify();
            until TopRisks.Next() = 0;

        TopRisks.SetFilter("Display Rank", '>%1', 10);
        TopRisks.DeleteAll();
        TopRisks.Reset();
    end;
}
