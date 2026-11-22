namespace MBS.PrintVisPulse.Dataset;

permissionset 50200 "MBS PV Demo Data"
{
    Assignable = true;
    Caption = 'PrintVis Pulse - Demo Data';

    Permissions =
        tabledata "MBS PV Demo Log" = RIMD,
        table "MBS PV Demo Log" = X,
        page "MBS PV Demo Data" = X,
        codeunit "MBS PV Demo Data Mgt" = X,
        codeunit "MBS PV Demo Writer" = X;
}
