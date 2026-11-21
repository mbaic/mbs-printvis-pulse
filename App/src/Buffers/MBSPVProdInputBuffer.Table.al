namespace MBS.PrintVisPulse.Buffers;

table 50003 "MBS PV Prod Input Buffer"
{
    Access = Internal;
    Caption = 'MBS PV Prod Input Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Operation Key Text"; Text[100])
        {
            Caption = 'Operation Key Text';
        }
        field(2; "Row Type"; Option)
        {
            Caption = 'Row Type';
            OptionMembers = Operation,Shipment;
            OptionCaption = 'Operation,Shipment';
        }
        field(3; "Source SystemId"; Guid)
        {
            Caption = 'Source SystemId';
        }
        field(4; "Case No."; Code[20])
        {
            Caption = 'Case No.';
        }
        field(5; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(6; "Capacity Unit"; Code[20])
        {
            Caption = 'Capacity Unit';
        }
        field(7; "Is Active"; Boolean)
        {
            Caption = 'Is Active';
        }
        field(8; "Is Archived"; Boolean)
        {
            Caption = 'Is Archived';
        }
        field(9; "Is Current Version"; Boolean)
        {
            Caption = 'Is Current Version';
        }
        field(10; "Is Complete"; Boolean)
        {
            Caption = 'Is Complete';
        }
        field(11; "Is Started"; Boolean)
        {
            Caption = 'Is Started';
        }
        field(12; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(13; "Due Date Source"; Option)
        {
            Caption = 'Due Date Source';
            OptionMembers = Operation,CaseDueDate,RequestedDelivery;
            OptionCaption = 'Operation Due Date,Case Due Date,Requested Delivery Date';
        }
        field(14; "Planned Hours"; Decimal)
        {
            Caption = 'Planned Hours';
        }
        field(15; "Spent Hours"; Decimal)
        {
            Caption = 'Spent Hours';
        }
        field(16; "Is Shipped"; Boolean)
        {
            Caption = 'Is Shipped';
        }
        field(17; "Actual Shipment Date"; Date)
        {
            Caption = 'Actual Shipment Date';
        }
        field(18; "Promise Date"; Date)
        {
            Caption = 'Promise Date';
        }
    }

    keys
    {
        key(PK; "Operation Key Text")
        {
            Clustered = true;
        }
    }
}
