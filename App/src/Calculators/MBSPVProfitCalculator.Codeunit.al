namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Pure, deterministic Job Profitability calculator. It never reads the clock or the database.
/// </summary>
codeunit 50022 "MBS PV Profit Calculator"
{
    Access = Internal;

    var
        ChartJsonMgt: Codeunit "MBS PV Chart Json";
        MarginCaptionLbl: Label 'Realized Margin %';
        OverEstimateCaptionLbl: Label 'Cases Over Estimate';
        WipCaptionLbl: Label 'Current WIP';
        ChartTitleLbl: Label 'Estimated vs. Actual Cost by Product Group';
        EstimatedCostLbl: Label 'Estimated Cost';
        ActualCostLbl: Label 'Actual Cost';
        ListCaptionLbl: Label 'Top Cases by Cost Overrun';
        NoDataMsgLbl: Label 'No data for selected period.';
        SourceUnavailableMsgLbl: Label 'PrintVis source data is unavailable.';
        MixedBasisNoteLbl: Label 'Margin unavailable: mixed or unverified currency.';
        WipNotVerifiedNoteLbl: Label 'WIP is not verified as monetary LCY.';

    procedure Calculate(
        var InputRows: Record "MBS PV Profit Input Buffer" temporary;
        FromDate: Date;
        ToDate: Date;
        BusinessDate: Date;
        GeneratedAt: DateTime;
        WipVerified: Boolean;
        SourceAvailable: Boolean;
        var Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        var TopOverruns: Record "MBS PV Profit Overrun Row" temporary;
        var Groups: Record "MBS PV Chart Group Buffer" temporary;
        var ChartJson: Text)
    var
        NetSales: Decimal;
        MarginCost: Decimal;
        MixedBasis: Boolean;
        OverCount: Integer;
        ExcludedBaselines: Integer;
        WipTotal: Decimal;
        ActualCost: Decimal;
    begin
        Snapshot.Reset();
        Snapshot.DeleteAll();
        TopOverruns.Reset();
        TopOverruns.DeleteAll();
        Groups.Reset();
        Groups.DeleteAll();

        Snapshot.Init();
        Snapshot."Primary Key" := 'PROFIT';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Profitability;
        Snapshot."Generated At" := GeneratedAt;
        Snapshot."Business Date" := BusinessDate;
        Snapshot."Period From" := FromDate;
        Snapshot."Period To" := ToDate;
        Snapshot."KPI 1 Caption" := MarginCaptionLbl;
        Snapshot."KPI 2 Caption" := OverEstimateCaptionLbl;
        Snapshot."KPI 3 Caption" := WipCaptionLbl;
        Snapshot."Chart Caption" := ChartTitleLbl;
        Snapshot."List Caption" := ListCaptionLbl;

        if not SourceAvailable then begin
            Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Unavailable;
            Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Unavailable;
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Unavailable;
            Snapshot.Insert();
            ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, EstimatedCostLbl, ActualCostLbl, SourceUnavailableMsgLbl, Groups);
            exit;
        end;

        InputRows.Reset();
        if InputRows.FindSet() then
            repeat
                ActualCost := GetActualCost(InputRows);

                // KPI 1: cases closed in the period, lifetime amounts.
                if InputRows."Is Closed" and (InputRows."Close Date" >= FromDate) and (InputRows."Close Date" <= ToDate) then begin
                    if not InputRows.Normalized then
                        MixedBasis := true;
                    NetSales += InputRows."Invoiced Sales" - InputRows."Credit Memo Sales";
                    MarginCost += ActualCost;
                end;

                // KPI 2 and chart: cases with a valid accepted-estimate baseline.
                if HasValidBaseline(InputRows) then begin
                    ChartJsonMgt.AddGroupTotal(Groups, InputRows."Product Group", InputRows."Estimated Cost", ActualCost, true);
                    if ActualCost > InputRows."Estimated Cost" then begin
                        OverCount += 1;
                        InsertOverrunRow(TopOverruns, InputRows, ActualCost);
                    end;
                end else
                    ExcludedBaselines += 1;

                // KPI 3: WIP of active cases.
                if InputRows."Is Active" then
                    WipTotal += InputRows."WIP Amount";
            until InputRows.Next() = 0;

        if MixedBasis then begin
            Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::NotApplicable;
            Snapshot."KPI 1 Note" := MixedBasisNoteLbl;
        end else
            if NetSales <= 0 then
                Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::NotApplicable
            else begin
                Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Available;
                Snapshot."KPI 1 Decimal" := Round(((NetSales - MarginCost) / NetSales) * 100, 0.1);
            end;

        Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Available;
        Snapshot."KPI 2 Int" := OverCount;
        Snapshot."Excluded Count 2" := ExcludedBaselines;

        if WipVerified then begin
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Available;
            Snapshot."KPI 3 Decimal" := WipTotal;
        end else begin
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Unavailable;
            Snapshot."KPI 3 Note" := WipNotVerifiedNoteLbl;
        end;

        TrimToTop10(TopOverruns);
        ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, EstimatedCostLbl, ActualCostLbl, NoDataMsgLbl, Groups);
        Snapshot.Insert();
    end;

    /// <summary>
    /// Labor cost counts once: it is added only when the reader reports that the labor entry cost is not already inside the cost entry amount (E5).
    /// </summary>
    local procedure GetActualCost(var Row: Record "MBS PV Profit Input Buffer" temporary): Decimal
    begin
        if Row."Labor In Cost Entry" then
            exit(Row."Cost Entry Amount");
        exit(Row."Cost Entry Amount" + Row."Labor Entry Amount");
    end;

    local procedure HasValidBaseline(var Row: Record "MBS PV Profit Input Buffer" temporary): Boolean
    begin
        exit(Row."Has Estimate" and Row."Is Sold Version" and Row.Normalized and (Row."Estimated Cost" > 0));
    end;

    local procedure InsertOverrunRow(var TopOverruns: Record "MBS PV Profit Overrun Row" temporary; var InputRow: Record "MBS PV Profit Input Buffer" temporary; ActualCost: Decimal)
    begin
        TopOverruns.Init();
        TopOverruns."Case Key Text" := InputRow."Case Key Text";
        TopOverruns."Source SystemId" := InputRow."Source SystemId";
        TopOverruns."Case No." := InputRow."Case No.";
        TopOverruns."Customer Name" := InputRow."Customer Name";
        TopOverruns."Product Group" := InputRow."Product Group";
        TopOverruns."Currency Code" := InputRow."Currency Code";
        TopOverruns."Estimated Cost" := InputRow."Estimated Cost";
        TopOverruns."Actual Cost" := ActualCost;
        TopOverruns."Overrun Amount" := ActualCost - InputRow."Estimated Cost";
        TopOverruns."Sort Amount" := -TopOverruns."Overrun Amount";
        TopOverruns.Insert();
    end;

    local procedure TrimToTop10(var TopOverruns: Record "MBS PV Profit Overrun Row" temporary)
    var
        RankNo: Integer;
    begin
        TopOverruns.Reset();
        TopOverruns.SetCurrentKey("Sort Amount", "Case Key Text");
        if TopOverruns.FindSet() then
            repeat
                RankNo += 1;
                TopOverruns."Display Rank" := RankNo;
                TopOverruns.Modify();
            until TopOverruns.Next() = 0;

        TopOverruns.SetFilter("Display Rank", '>%1', 10);
        TopOverruns.DeleteAll();
        TopOverruns.Reset();
    end;
}
