namespace MBS.PrintVisPulse.Buffers;

table 50001 "MBS PV Quote Input Buffer"
{
    Access = Internal;
    Caption = 'MBS PV Quote Input Buffer';
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
        field(10; "Normalized"; Boolean)
        {
            Caption = 'Normalized';
        }
        field(11; "Is Issued Quote"; Boolean)
        {
            Caption = 'Is Issued Quote';
        }
        field(12; "Is Archived"; Boolean)
        {
            Caption = 'Is Archived';
        }
        field(13; "Is Canceled"; Boolean)
        {
            Caption = 'Is Canceled';
        }
        field(14; "Outcome"; Option)
        {
            Caption = 'Outcome';
            OptionMembers = Open,Won,Lost;
            OptionCaption = 'Open,Won,Lost';
        }
        field(15; "Decision Date"; Date)
        {
            Caption = 'Decision Date';
        }
    }

    keys
    {
        key(PK; "Case Key Text")
        {
            Clustered = true;
        }
    }
}
