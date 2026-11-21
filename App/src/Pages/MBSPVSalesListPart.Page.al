namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;

page 50015 "MBS PV Sales List Part"
{
    Access = Internal;
    ApplicationArea = All;
    Caption = 'Sales Exceptions';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "MBS PV Open Quote Row";
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
                    ToolTip = 'Specifies the rank of the quote in the list.';
                }
                field("Quote No."; Rec."Quote No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the PrintVis quote number.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer of the quote.';
                }
                field("Product Group"; Rec."Product Group")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the product group of the quote.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency of the quote. A blank value means the local currency.';
                }
                field("Deadline"; Rec."Deadline")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quote deadline.';
                }
                field("Quoted Amount"; Rec."Quoted Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quoted amount in the quote currency.';
                }
                field("Normalized Amount"; Rec."Normalized Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quote amount on the common currency basis used for the KPIs.';
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
    procedure ReplaceRows(var Source: Record "MBS PV Open Quote Row" temporary)
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
