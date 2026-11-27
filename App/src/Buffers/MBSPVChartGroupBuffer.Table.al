namespace MBS.PrintVisPulse.Buffers;

table 50007 "MBS PV Chart Group Buffer"
{
    Access = Internal;
    Caption = 'MBS PV Chart Group Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Group Code"; Code[20])
        {
            Caption = 'Group Code';
        }
        field(2; "Series 1"; Decimal)
        {
            Caption = 'Series 1';
        }
        field(3; "Series 2"; Decimal)
        {
            Caption = 'Series 2';
        }
        field(4; "Sort Amount"; Decimal)
        {
            Caption = 'Sort Amount';
        }
        field(5; "Display Rank"; Integer)
        {
            Caption = 'Display Rank';
        }
    }

    keys
    {
        key(PK; "Group Code")
        {
            Clustered = true;
        }
        key(Rank; "Sort Amount", "Group Code")
        {
        }
    }
}
