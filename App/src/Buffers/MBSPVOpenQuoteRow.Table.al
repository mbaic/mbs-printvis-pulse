namespace MBS.PrintVisPulse.Buffers;

table 50002 "MBS PV Open Quote Row"
{
    Access = Internal;
    Caption = 'MBS PV Open Quote Row';
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
        field(3; "Quote No."; Code[20])
        {
            Caption = 'Quote No.';
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
        field(7; "Deadline"; Date)
        {
            Caption = 'Deadline';
        }
        field(8; "Quoted Amount"; Decimal)
        {
            Caption = 'Quoted Amount';
        }
        field(9; "Normalized Amount"; Decimal)
        {
            Caption = 'Normalized Amount';
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
        key(ByDeadline; Deadline, "Case Key Text")
        {
        }
        key(ByDisplayRank; "Display Rank")
        {
        }
    }
}
