namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;

page 50016 "MBS PV Prod List Part"
{
    Access = Internal;
    ApplicationArea = All;
    Caption = 'Production Exceptions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "MBS PV Prod Risk Row";
    SourceTableTemporary = true;
    SourceTableView = sorting("Display Rank");

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("Display Rank"; Rec."Display Rank")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rank of the operation in the list.';
                }
                field("Case No."; Rec."Case No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PrintVis case number.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer of the case.';
                }
                field("Capacity Unit"; Rec."Capacity Unit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the machine or work center of the operation.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the due date used to rate the operation as at risk.';
                }
                field("Planned Hours"; Rec."Planned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planned hours of the operation.';
                }
                field("Spent Hours"; Rec."Spent Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the recorded hours of the operation.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenPrintVisCase)
            {
                ApplicationArea = All;
                Caption = 'Open PrintVis Case';
                Image = Card;
                ToolTip = 'Opens the PrintVis case of the selected row. The case opens read-only for the current user.';

                trigger OnAction()
                begin
                    DrillDownMgt.OpenCase(Rec."Source SystemId");
                end;
            }
        }
    }

    var
        DrillDownMgt: Codeunit "MBS PV DrillDown Mgt.";

    /// <summary>Replaces all rows with the host's ranked exception rows.</summary>
    procedure ReplaceRows(var Source: Record "MBS PV Prod Risk Row" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Source.Reset();
        if Source.FindSet() then
            repeat
                Rec := Source;
                Rec.Insert();
            until Source.Next() = 0;
        CurrPage.Update(false);
    end;
}
