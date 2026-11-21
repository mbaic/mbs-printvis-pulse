namespace MBS.PrintVisPulse.Buffers;

table 50005 "MBS PV Profit Input Buffer"
{
    Access = Internal;
    Caption = 'MBS PV Profit Input Buffer';
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
        field(7; "Normalized"; Boolean)
        {
            Caption = 'Normalized';
        }
        field(8; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
        }
        field(9; "Is Closed"; Boolean)
        {
            Caption = 'Is Closed';
        }
        field(10; "Close Date"; Date)
        {
            Caption = 'Close Date';
        }
        field(11; "Is Sold Version"; Boolean)
        {
            Caption = 'Is Sold Version';
        }
        field(12; "Invoiced Sales"; Decimal)
        {
            Caption = 'Invoiced Sales';
        }
        field(13; "Credit Memo Sales"; Decimal)
        {
            Caption = 'Credit Memo Sales';
        }
        field(14; "Cost Entry Amount"; Decimal)
        {
            Caption = 'Cost Entry Amount';
        }
        field(15; "Labor Entry Amount"; Decimal)
        {
            Caption = 'Labor Entry Amount';
        }
        field(16; "Labor In Cost Entry"; Boolean)
        {
            Caption = 'Labor In Cost Entry';
        }
        field(17; "Has Estimate"; Boolean)
        {
            Caption = 'Has Estimate';
        }
        field(18; "Estimated Cost"; Decimal)
        {
            Caption = 'Estimated Cost';
        }
        field(19; "WIP Amount"; Decimal)
        {
            Caption = 'WIP Amount';
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
