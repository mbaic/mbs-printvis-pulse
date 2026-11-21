namespace MBS.PrintVisPulse.Permissions;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Calculators;
using MBS.PrintVisPulse.Pages;
using MBS.PrintVisPulse.Readers;

/// <summary>
/// Execute rights on the Pulse objects only. There are no tabledata permissions: all buffers are temporary.
/// PrintVis data access follows the user's existing PrintVis permission sets, so denied records never reach a KPI.
/// </summary>
permissionset 50050 "MBS PV Pulse Users"
{
    Assignable = true;
    Caption = 'PrintVis Pulse - Users';

    Permissions =
        table "MBS PV Snapshot Buffer" = X,
        table "MBS PV Quote Input Buffer" = X,
        table "MBS PV Open Quote Row" = X,
        table "MBS PV Prod Input Buffer" = X,
        table "MBS PV Prod Risk Row" = X,
        table "MBS PV Profit Input Buffer" = X,
        table "MBS PV Profit Overrun Row" = X,
        table "MBS PV Chart Group Buffer" = X,
        page "MBS PV Pulse Role Center" = X,
        page "MBS PV Sales Dashboard" = X,
        page "MBS PV Prod Dashboard" = X,
        page "MBS PV Profit Dashboard" = X,
        page "MBS PV KPI Cue Part" = X,
        page "MBS PV Sales List Part" = X,
        page "MBS PV Prod List Part" = X,
        page "MBS PV Profit List Part" = X,
        codeunit "MBS PV Sales Calculator" = X,
        codeunit "MBS PV Prod Calculator" = X,
        codeunit "MBS PV Profit Calculator" = X,
        codeunit "MBS PV Chart Json" = X,
        codeunit "MBS PV Period Mgt" = X,
        codeunit "MBS PV Display Mgt" = X,
        codeunit "MBS PV Sales Reader" = X,
        codeunit "MBS PV Prod Reader" = X,
        codeunit "MBS PV Profit Reader" = X,
        codeunit "MBS PV DrillDown Mgt." = X,
        codeunit "MBS PV Reader Runner" = X;
}
