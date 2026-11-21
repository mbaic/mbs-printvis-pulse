namespace MBS.PrintVisPulse.Buffers;

table 50004 "MBS PV Prod Risk Row"
{
    Access = Internal;
    Caption = 'MBS PV Prod Risk Row';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Operation Key Text"; Text[100])
        {
            Caption = 'Operation Key Text';
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
        field(5; "Capacity Unit"; Code[20])
        {
            Caption = 'Capacity Unit';
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(7; "Planned Hours"; Decimal)
        {
            Caption = 'Planned Hours';
        }
        field(8; "Spent Hours"; Decimal)
        {
            Caption = 'Spent Hours';
        }
        field(9; "Sort Amount"; Decimal)
        {
            Caption = 'Sort Amount';
        }
        field(10; "Display Rank"; Integer)
        {
            Caption = 'Display Rank';
        }
    }

    keys
    {
        key(PK; "Operation Key Text")
        {
            Clustered = true;
        }
        key(Rank; "Sort Amount", "Operation Key Text")
        {
        }
        key(ByDisplayRank; "Display Rank")
        {
        }
    }
}
