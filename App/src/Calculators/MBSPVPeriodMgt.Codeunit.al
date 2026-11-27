namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Enums;

/// <summary>
/// Pure period arithmetic. The business date is supplied by the caller (the host page passes WorkDate()).
/// Ranges are inclusive: a rolling 30-day preset covers the business date and the preceding 29 days.
/// </summary>
codeunit 50024 "MBS PV Period Mgt"
{
    Access = Internal;

    procedure GetRange(PeriodFilter: Enum "MBS PV Period Filter"; BusinessDate: Date; var FromDate: Date; var ToDate: Date)
    begin
        ToDate := BusinessDate;
        case PeriodFilter of
            PeriodFilter::Last7Days:
                FromDate := BusinessDate - 6;
            PeriodFilter::Last30Days:
                FromDate := BusinessDate - 29;
            PeriodFilter::Last90Days:
                FromDate := BusinessDate - 89;
            PeriodFilter::MonthToDate:
                FromDate := CalcDate('<-CM>', BusinessDate);
            PeriodFilter::YearToDate:
                FromDate := CalcDate('<-CY>', BusinessDate);
        end;
    end;
}
