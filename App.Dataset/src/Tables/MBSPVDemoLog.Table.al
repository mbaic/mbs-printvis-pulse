namespace MBS.PrintVisPulse.Dataset;

/// <summary>
/// One row per record created by the demo data run. Cleanup deletes every logged record by table number and SystemId.
/// </summary>
table 50200 "MBS PV Demo Log"
{
    Caption = 'PrintVis Pulse Demo Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Table Name"; Text[80])
        {
            Caption = 'Table Name';
        }
        field(4; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(5; "Record Key"; Text[250])
        {
            Caption = 'Record Key';
        }
        field(6; "Created At"; DateTime)
        {
            Caption = 'Created At';
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
