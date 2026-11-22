namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Enums;

/// <summary>
/// Role Center overview of the Production dashboard: the three KPIs and the top-5 chart for the last 30 days.
/// Builds its own snapshot when the Role Center opens. The full dashboard adds the period filter and the exception list.
/// </summary>
page 50019 "MBS PV Prod Overview"
{
    ApplicationArea = All;
    Caption = 'Production Pulse';
    Editable = false;
    PageType = CardPart;
    SourceTable = "MBS PV Snapshot Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(Kpis)
            {
                ShowCaption = false;
                field(KPI1; KPI1Text)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Rec."KPI 1 Caption";
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies key performance indicator 1 of the dashboard.';
                }
                field(KPI1Note; Rec."KPI 1 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of key performance indicator 1.';
                    Visible = KPI1NoteVisible;
                }
                field(KPI2; KPI2Text)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Rec."KPI 2 Caption";
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies key performance indicator 2 of the dashboard.';
                }
                field(KPI2Note; Rec."KPI 2 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of key performance indicator 2.';
                    Visible = KPI2NoteVisible;
                }
                field(KPI3; KPI3Text)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Rec."KPI 3 Caption";
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies key performance indicator 3 of the dashboard.';
                }
                field(KPI3Note; Rec."KPI 3 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of key performance indicator 3.';
                    Visible = KPI3NoteVisible;
                }
            }
            group(ChartGroup)
            {
                ShowCaption = false;
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
        }
    }

    var
        DisplayMgt: Codeunit "MBS PV Display Mgt";
        KPI1Text: Text;
        KPI2Text: Text;
        KPI3Text: Text;
        KPI1NoteVisible: Boolean;
        KPI2NoteVisible: Boolean;
        KPI3NoteVisible: Boolean;
        ChartReady: Boolean;
        LastChartJson: Text;

    trigger OnOpenPage()
    var
        RefreshMgt: Codeunit "MBS PV Refresh Mgt";
        Snapshot: Record "MBS PV Snapshot Buffer" temporary;
        TopRisks: Record "MBS PV Prod Risk Row" temporary;
        Groups: Record "MBS PV Chart Group Buffer" temporary;
        ChartJson: Text;
    begin
        RefreshMgt.RefreshProduction(Enum::"MBS PV Period Filter"::Last30Days, Snapshot, TopRisks, Groups, ChartJson);

        Rec.Reset();
        Rec.DeleteAll();
        if Snapshot.FindFirst() then begin
            Rec := Snapshot;
            Rec.Insert();
        end;

        LastChartJson := ChartJson;
        RenderChart();
    end;

    trigger OnAfterGetRecord()
    begin
        KPI1Text := DisplayMgt.FormatKpi(Rec, 1);
        KPI2Text := DisplayMgt.FormatKpi(Rec, 2);
        KPI3Text := DisplayMgt.FormatKpi(Rec, 3);
        KPI1NoteVisible := Rec."KPI 1 Note" <> '';
        KPI2NoteVisible := Rec."KPI 2 Note" <> '';
        KPI3NoteVisible := Rec."KPI 3 Note" <> '';
    end;

    local procedure RenderChart()
    begin
        if ChartReady and (LastChartJson <> '') then
            CurrPage.ChartHost.RenderBarChart(LastChartJson);
    end;
}
