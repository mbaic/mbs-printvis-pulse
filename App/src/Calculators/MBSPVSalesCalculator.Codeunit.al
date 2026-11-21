namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Pure, deterministic Sales and Quote Pipeline calculator. It never reads the clock or the database.
/// </summary>
codeunit 50020 "MBS PV Sales Calculator"
{
    Access = Internal;

    var
        ChartJsonMgt: Codeunit "MBS PV Chart Json";
        OpenQuotesCaptionLbl: Label 'Current Open Quotes';
        OpenQuoteValueCaptionLbl: Label 'Current Open Quote Value';
        HitRateCaptionLbl: Label 'Quote Hit Rate %';
        ChartTitleLbl: Label 'Current Open Quote Value by Product Group';
        Series1Lbl: Label 'Open Quote Value';
        ListByValueLbl: Label 'Top Open Quotes by Value';
        ListByDeadlineLbl: Label 'Open Quotes by Deadline';
        MixedCurrencyMsgLbl: Label 'Value unavailable: mixed or unverified currency.';
        NoDataMsgLbl: Label 'No data for selected period.';
        SourceUnavailableMsgLbl: Label 'PrintVis source data is unavailable.';

    procedure Calculate(
        var InputRows: Record "MBS PV Quote Input Buffer" temporary;
        FromDate: Date;
        ToDate: Date;
        BusinessDate: Date;
        GeneratedAt: DateTime;
        BaseCurrencyCode: Code[10];
        SourceAvailable: Boolean;
        var Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        var TopQuotes: Record "MBS PV Open Quote Row" temporary;
        var Groups: Record "MBS PV Chart Group Buffer" temporary;
        var ChartJson: Text)
    var
        OpenCount: Integer;
        OpenValue: Decimal;
        MixedOrUnverifiedCurrency: Boolean;
        WonCount: Integer;
        LostCount: Integer;
    begin
        Snapshot.Reset();
        Snapshot.DeleteAll();
        TopQuotes.Reset();
        TopQuotes.DeleteAll();
        Groups.Reset();
        Groups.DeleteAll();

        Snapshot.Init();
        Snapshot."Primary Key" := 'SALES';
        Snapshot."Dashboard Type" := Snapshot."Dashboard Type"::Sales;
        Snapshot."Generated At" := GeneratedAt;
        Snapshot."Business Date" := BusinessDate;
        Snapshot."Period From" := FromDate;
        Snapshot."Period To" := ToDate;
        Snapshot."KPI 1 Caption" := OpenQuotesCaptionLbl;
        Snapshot."KPI 2 Caption" := OpenQuoteValueCaptionLbl;
        Snapshot."KPI 3 Caption" := HitRateCaptionLbl;
        Snapshot."Chart Caption" := ChartTitleLbl;
        Snapshot."List Caption" := ListByValueLbl;

        if not SourceAvailable then begin
            Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Unavailable;
            Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Unavailable;
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Unavailable;
            Snapshot.Insert();
            ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, Series1Lbl, '', SourceUnavailableMsgLbl, Groups);
            exit;
        end;

        InputRows.Reset();
        if InputRows.FindSet() then
            repeat
                if IsOpenQuote(InputRows) then begin
                    OpenCount += 1;
                    if (not InputRows.Normalized) or ((BaseCurrencyCode <> '') and (InputRows."Currency Code" <> '') and (InputRows."Currency Code" <> BaseCurrencyCode)) then
                        MixedOrUnverifiedCurrency := true
                    else begin
                        OpenValue += InputRows."Normalized Amount";
                        ChartJsonMgt.AddGroupTotal(Groups, InputRows."Product Group", InputRows."Normalized Amount", 0, false);
                    end;
                    InsertCandidateRow(TopQuotes, InputRows);
                end;

                if IsDecisionInPeriod(InputRows, FromDate, ToDate) then
                    if InputRows.Outcome = InputRows.Outcome::Won then
                        WonCount += 1
                    else
                        if InputRows.Outcome = InputRows.Outcome::Lost then
                            LostCount += 1;
            until InputRows.Next() = 0;

        Snapshot."KPI 1 Availability" := Snapshot."KPI 1 Availability"::Available;
        Snapshot."KPI 1 Int" := OpenCount;

        if MixedOrUnverifiedCurrency then begin
            Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::NotApplicable;
            Snapshot."KPI 2 Note" := MixedCurrencyMsgLbl;
            Snapshot."List Caption" := ListByDeadlineLbl;
            Groups.DeleteAll();
            TrimToTop10(TopQuotes, true);
            ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, Series1Lbl, '', MixedCurrencyMsgLbl, Groups);
        end else begin
            Snapshot."KPI 2 Availability" := Snapshot."KPI 2 Availability"::Available;
            Snapshot."KPI 2 Decimal" := OpenValue;
            TrimToTop10(TopQuotes, false);
            ChartJson := ChartJsonMgt.BuildTop5ChartJson(ChartTitleLbl, Series1Lbl, '', NoDataMsgLbl, Groups);
        end;

        if (WonCount + LostCount) = 0 then
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::NotApplicable
        else begin
            Snapshot."KPI 3 Availability" := Snapshot."KPI 3 Availability"::Available;
            Snapshot."KPI 3 Decimal" := Round((WonCount / (WonCount + LostCount)) * 100, 0.1);
        end;

        Snapshot.Insert();
    end;

    local procedure IsOpenQuote(var Row: Record "MBS PV Quote Input Buffer" temporary): Boolean
    begin
        exit(Row."Is Issued Quote" and (not Row."Is Archived") and (not Row."Is Canceled") and (Row.Outcome = Row.Outcome::Open));
    end;

    local procedure IsDecisionInPeriod(var Row: Record "MBS PV Quote Input Buffer" temporary; FromDate: Date; ToDate: Date): Boolean
    begin
        exit(Row."Is Issued Quote" and (Row."Decision Date" >= FromDate) and (Row."Decision Date" <= ToDate));
    end;

    local procedure InsertCandidateRow(var TopQuotes: Record "MBS PV Open Quote Row" temporary; var InputRow: Record "MBS PV Quote Input Buffer" temporary)
    begin
        TopQuotes.Init();
        TopQuotes."Case Key Text" := InputRow."Case Key Text";
        TopQuotes."Source SystemId" := InputRow."Source SystemId";
        TopQuotes."Quote No." := InputRow."Quote No.";
        TopQuotes."Customer Name" := InputRow."Customer Name";
        TopQuotes."Product Group" := InputRow."Product Group";
        TopQuotes."Currency Code" := InputRow."Currency Code";
        TopQuotes.Deadline := InputRow.Deadline;
        TopQuotes."Quoted Amount" := InputRow."Quoted Amount";
        TopQuotes."Normalized Amount" := InputRow."Normalized Amount";
        TopQuotes."Sort Amount" := -InputRow."Normalized Amount";
        TopQuotes.Insert();
    end;

    local procedure TrimToTop10(var TopQuotes: Record "MBS PV Open Quote Row" temporary; RankByDeadline: Boolean)
    var
        RankNo: Integer;
    begin
        TopQuotes.Reset();
        if RankByDeadline then
            TopQuotes.SetCurrentKey(Deadline, "Case Key Text")
        else
            TopQuotes.SetCurrentKey("Sort Amount", "Case Key Text");

        if TopQuotes.FindSet() then
            repeat
                RankNo += 1;
                if RankByDeadline then
                    TopQuotes."Sort Amount" := 0;
                TopQuotes."Display Rank" := RankNo;
                TopQuotes.Modify();
            until TopQuotes.Next() = 0;

        TopQuotes.SetFilter("Display Rank", '>%1', 10);
        TopQuotes.DeleteAll();
        TopQuotes.Reset();
    end;
}
