namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;

/// <summary>
/// Shared KPI card for all three dashboards. Captions and notes come from the snapshot, so the page never hard-codes a KPI name.
/// </summary>
page 50014 "MBS PV KPI Cue Part"
{
    Access = Internal;
    ApplicationArea = All;
    Caption = 'KPIs';
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
                    ToolTip = 'Specifies the first key performance indicator of the dashboard.';
                }
                field(KPI1Note; Rec."KPI 1 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of the first key performance indicator.';
                    Visible = KPI1NoteVisible;
                }
                field(KPI2; KPI2Text)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Rec."KPI 2 Caption";
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the second key performance indicator of the dashboard.';
                }
                field(KPI2Note; Rec."KPI 2 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of the second key performance indicator.';
                    Visible = KPI2NoteVisible;
                }
                field(KPI3; KPI3Text)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + Rec."KPI 3 Caption";
                    Editable = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the third key performance indicator of the dashboard.';
                }
                field(KPI3Note; Rec."KPI 3 Note")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Subordinate;
                    StyleExpr = true;
                    ToolTip = 'Specifies the basis or limitation of the third key performance indicator.';
                    Visible = KPI3NoteVisible;
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

    trigger OnAfterGetRecord()
    begin
        KPI1Text := DisplayMgt.FormatKpi(Rec, 1);
        KPI2Text := DisplayMgt.FormatKpi(Rec, 2);
        KPI3Text := DisplayMgt.FormatKpi(Rec, 3);
        KPI1NoteVisible := Rec."KPI 1 Note" <> '';
        KPI2NoteVisible := Rec."KPI 2 Note" <> '';
        KPI3NoteVisible := Rec."KPI 3 Note" <> '';
    end;

    /// <summary>Replaces the part's snapshot with the one built by the host. The part never reads shared globals.</summary>
    procedure SetSnapshot(var Source: Record "MBS PV Snapshot Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if Source.FindFirst() then begin
            Rec := Source;
            Rec.Insert();
        end;
        CurrPage.Update(false);
    end;
}
