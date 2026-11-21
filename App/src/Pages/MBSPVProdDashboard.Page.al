namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Enums;
using MBS.PrintVisPulse.Readers;

/// <summary>
/// Production dashboard host. Owns the period filter, the explicit Refresh action and the status header.
/// Each refresh builds one bounded snapshot and hands it to the parts through procedures.
/// </summary>
page 50012 "MBS PV Prod Dashboard"
{
    AdditionalSearchTerms = 'PrintVis, dashboard, pulse, Production';
    Access = Internal;
    ApplicationArea = All;
    Caption = 'MBS PrintVis Production Dashboard';
    PageType = ListPlus;
    SourceTable = "MBS PV Snapshot Buffer";
    SourceTableTemporary = true;
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field(PeriodFilterField; PeriodFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Period';
                    ToolTip = 'Specifies the period used for period-based KPIs. Choose Refresh to apply it.';
                }
            }
            group(Status)
            {
                Caption = 'Status';
                field(GeneratedAtField; Rec."Generated At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when the snapshot was built. Current-state KPIs are valid as of this time.';
                }
                field(BusinessDateField; Rec."Business Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the business date used for current-state KPIs.';
                }
                field(PeriodFromField; Rec."Period From")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the first day of the period, inclusive.';
                }
                field(PeriodToField; Rec."Period To")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the last day of the period, inclusive.';
                }
            }
            part(KpiPart; "MBS PV KPI Cue Part")
            {
                ApplicationArea = All;
                Caption = 'KPIs';
            }
            group(ChartGroup)
            {
                Caption = 'Planned vs. Spent Hours by Capacity Unit';
                usercontrol(ChartHost; "MBS PV Chart Host")
                {
                    ApplicationArea = All;

                    trigger OnControlReady()
                    begin
                        ChartReady := true;
                        RenderChart();
                    end;
                }
            }
            group(ExceptionGroup)
            {
                ShowCaption = false;
                field(ListCaptionField; Rec."List Caption")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies how the exception list below is ranked.';
                }
            }
            part(Exceptions; "MBS PV Prod List Part")
            {
                ApplicationArea = All;
                Caption = 'Exceptions';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Rebuilds the dashboard from PrintVis data for the selected period.';

                trigger OnAction()
                begin
                    RefreshDashboard();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh)
            {
            }
        }
    }

    var
        PeriodFilter: Enum "MBS PV Period Filter";
        ChartReady: Boolean;
        LastChartJson: Text;

    trigger OnOpenPage()
    begin
        PeriodFilter := PeriodFilter::Last30Days;
        RefreshDashboard();
    end;

    local procedure RefreshDashboard()
    var
        Runner: Codeunit "MBS PV Reader Runner";
        PeriodMgt: Codeunit "MBS PV Period Mgt";
        Calculator: Codeunit "MBS PV Prod Calculator";
        InputRows: Record "MBS PV Prod Input Buffer" temporary;
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopRisks: Record "MBS PV Prod Risk Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        StartedAt: DateTime;
        BusinessDate: Date;
        FromDate: Date;
        ToDate: Date;
        ElapsedMs: Integer;
        RowsRead: Integer;
        SourceAvailable: Boolean;
        ChartJson: Text;
        PromiseFieldName: Text[80];
    begin
        StartedAt := CurrentDateTime();
        BusinessDate := WorkDate();
        PeriodMgt.GetRange(PeriodFilter, BusinessDate, FromDate, ToDate);

        SourceAvailable := Runner.ReadProduction(FromDate, ToDate, InputRows, PromiseFieldName, RowsRead);
        Calculator.Calculate(InputRows, FromDate, ToDate, BusinessDate, StartedAt, PromiseFieldName, SourceAvailable, Snapshot, TopRisks, Groups, ChartJson);

        Rec.Reset();
        Rec.DeleteAll();
        if Snapshot.FindFirst() then begin
            Rec := Snapshot;
            Rec.Insert();
        end;

        CurrPage.KpiPart.Page.SetSnapshot(Snapshot);
        CurrPage.Exceptions.Page.ReplaceRows(TopRisks);
        LastChartJson := ChartJson;
        RenderChart();
        CurrPage.Update(false);

        ElapsedMs := CurrentDateTime() - StartedAt;
        Runner.LogRefresh(Enum::"MBS PV Dashboard Type"::Production, ElapsedMs, RowsRead, Snapshot);
    end;

    /// <summary>Renders only when the add-in is ready and a chart exists, in either arrival order. Also replays after the add-in is recreated.</summary>
    local procedure RenderChart()
    begin
        if ChartReady and (LastChartJson <> '') then
            CurrPage.ChartHost.RenderBarChart(LastChartJson);
    end;
}
