namespace MBS.PrintVisPulse.Buffers;

using MBS.PrintVisPulse.Enums;

table 50000 "MBS PV Snapshot Buffer"
{
    Access = Internal;
    Caption = 'MBS PV Snapshot Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Dashboard Type"; Enum "MBS PV Dashboard Type")
        {
            Caption = 'Dashboard Type';
        }
        field(3; "Generated At"; DateTime)
        {
            Caption = 'Generated At';
        }
        field(4; "Period From"; Date)
        {
            Caption = 'Period From';
        }
        field(5; "Period To"; Date)
        {
            Caption = 'Period To';
        }
        field(6; "Business Date"; Date)
        {
            Caption = 'Business Date';
        }
        field(7; "List Caption"; Text[80])
        {
            Caption = 'List Caption';
        }
        field(8; "Chart Caption"; Text[80])
        {
            Caption = 'Chart Caption';
        }
        field(10; "KPI 1 Availability"; Enum "MBS PV KPI Availability")
        {
            Caption = 'KPI 1 Availability';
        }
        field(11; "KPI 1 Int"; Integer)
        {
            Caption = 'KPI 1 Int';
        }
        field(12; "KPI 1 Decimal"; Decimal)
        {
            Caption = 'KPI 1 Decimal';
        }
        field(13; "KPI 1 Caption"; Text[80])
        {
            Caption = 'KPI 1 Caption';
        }
        field(14; "KPI 1 Note"; Text[250])
        {
            Caption = 'KPI 1 Note';
        }
        field(15; "Excluded Count 1"; Integer)
        {
            Caption = 'Excluded Count 1';
        }
        field(20; "KPI 2 Availability"; Enum "MBS PV KPI Availability")
        {
            Caption = 'KPI 2 Availability';
        }
        field(21; "KPI 2 Int"; Integer)
        {
            Caption = 'KPI 2 Int';
        }
        field(22; "KPI 2 Decimal"; Decimal)
        {
            Caption = 'KPI 2 Decimal';
        }
        field(23; "KPI 2 Caption"; Text[80])
        {
            Caption = 'KPI 2 Caption';
        }
        field(24; "KPI 2 Note"; Text[250])
        {
            Caption = 'KPI 2 Note';
        }
        field(25; "Excluded Count 2"; Integer)
        {
            Caption = 'Excluded Count 2';
        }
        field(30; "KPI 3 Availability"; Enum "MBS PV KPI Availability")
        {
            Caption = 'KPI 3 Availability';
        }
        field(31; "KPI 3 Int"; Integer)
        {
            Caption = 'KPI 3 Int';
        }
        field(32; "KPI 3 Decimal"; Decimal)
        {
            Caption = 'KPI 3 Decimal';
        }
        field(33; "KPI 3 Caption"; Text[80])
        {
            Caption = 'KPI 3 Caption';
        }
        field(34; "KPI 3 Note"; Text[250])
        {
            Caption = 'KPI 3 Note';
        }
        field(35; "Excluded Count 3"; Integer)
        {
            Caption = 'Excluded Count 3';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
