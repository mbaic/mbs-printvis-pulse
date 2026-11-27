namespace MBS.PrintVisPulse.Dataset;

page 50200 "MBS PV Demo Data"
{
    Caption = 'PrintVis Pulse Demo Data';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "MBS PV Demo Log";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Log)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; ToolTip = 'Specifies the log entry number.'; }
                field("Table No."; Rec."Table No.") { ApplicationArea = All; ToolTip = 'Specifies the PrintVis table the record was created in.'; }
                field("Table Name"; Rec."Table Name") { ApplicationArea = All; ToolTip = 'Specifies the table name.'; }
                field("Record Key"; Rec."Record Key") { ApplicationArea = All; ToolTip = 'Specifies the primary key of the created record.'; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; ToolTip = 'Specifies when the record was created.'; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateDemoData)
            {
                ApplicationArea = All;
                Caption = 'Create Demo Data';
                Image = Create;
                ToolTip = 'Creates the demo cases, jobs, operations, shipments and costing entries, and logs every record.';

                trigger OnAction()
                var
                    DemoDataMgt: Codeunit "MBS PV Demo Data Mgt";
                begin
                    DemoDataMgt.CreateDemoData();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteDemoData)
            {
                ApplicationArea = All;
                Caption = 'Delete Demo Data';
                Image = Delete;
                ToolTip = 'Deletes every record in the log from PrintVis, then clears the log.';

                trigger OnAction()
                var
                    DemoDataMgt: Codeunit "MBS PV Demo Data Mgt";
                begin
                    DemoDataMgt.DeleteDemoData();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CreateDemoData_Promoted; CreateDemoData) { }
            actionref(DeleteDemoData_Promoted; DeleteDemoData) { }
        }
    }
}
