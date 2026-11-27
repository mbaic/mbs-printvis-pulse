namespace MBS.PrintVisPulse.Enums;

enum 50041 "MBS PV Period Filter"
{
    Access = Internal;
    Extensible = false;

    value(0; Last7Days)
    {
        Caption = 'Last 7 Days';
    }
    value(1; Last30Days)
    {
        Caption = 'Last 30 Days';
    }
    value(2; Last90Days)
    {
        Caption = 'Last 90 Days';
    }
    value(3; MonthToDate)
    {
        Caption = 'Month to Date';
    }
    value(4; YearToDate)
    {
        Caption = 'Year to Date';
    }
}
