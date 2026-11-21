namespace MBS.PrintVisPulse.Enums;

enum 50040 "MBS PV Dashboard Type"
{
    Access = Internal;
    Extensible = false;

    value(0; Sales)
    {
        Caption = 'Sales';
    }
    value(1; Production)
    {
        Caption = 'Production';
    }
    value(2; Profitability)
    {
        Caption = 'Profitability';
    }
}
