namespace MBS.PrintVisPulse.Buffers;

table 50006 "MBS PV Profit Overrun Row"
{
    Access = Internal;
    Caption = 'MBS PV Profit Overrun Row';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Case Key Text"; Text[100])
        {
            Caption = 'Case Key Text';
        }
        field(2; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(3; "Case No."; Code[20])
        {
            Caption = 'Case No.';
        }
        field(4; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(5; "Product Group"; Code[20])
        {
            Caption = 'Product Group';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(7; "Estimated Cost"; Decimal)
        {
            Caption = 'Estimated Cost';
        }
        field(8; "Actual Cost"; Decimal)
        {
            Caption = 'Actual Cost';
        }
        field(9; "Overrun Amount"; Decimal)
        {
            Caption = 'Overrun Amount';
        }
        field(10; "Sort Amount"; Decimal)
        {
            Caption = 'Sort Amount';
        }
        field(11; "Display Rank"; Integer)
        {
            Caption = 'Display Rank';
        }
    }

    keys
    {
        key(PK; "Case Key Text")
        {
            Clustered = true;
        }
        key(Rank; "Sort Amount", "Case Key Text")
        {
        }
        key(ByDisplayRank; "Display Rank")
        {
        }
    }
}
