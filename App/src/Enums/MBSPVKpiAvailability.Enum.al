namespace MBS.PrintVisPulse.Enums;

enum 50042 "MBS PV KPI Availability"
{
    Access = Internal;
    Extensible = false;

    value(0; Available)
    {
        Caption = 'Available';
    }
    value(1; NotApplicable)
    {
        Caption = 'N/A';
    }
    value(2; Unavailable)
    {
        Caption = 'Unavailable';
    }
}
