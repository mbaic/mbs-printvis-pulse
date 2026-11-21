namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;

page 50017 "MBS PV Profit List Part"
{
    Access = Internal;
    ApplicationArea = All;
    Caption = 'Profitability Exceptions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "MBS PV Profit Overrun Row";
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
                    ToolTip = 'Specifies the rank of the case in the list.';
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
                field("Product Group"; Rec."Product Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the product group of the case.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the case. A blank value means the local currency.';
                }
                field("Estimated Cost"; Rec."Estimated Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the accepted estimate cost.';
                }
                field("Actual Cost"; Rec."Actual Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posted actual cost.';
                }
                field("Overrun Amount"; Rec."Overrun Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how much the actual cost exceeds the accepted estimate.';
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
    procedure ReplaceRows(var Source: Record "MBS PV Profit Overrun Row" temporary)
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
