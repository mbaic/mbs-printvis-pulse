namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Enums;

/// <summary>
/// Turns snapshot KPI values into display text. Real zeros stay "0"; N/A and Unavailable never render as a number.
/// </summary>
codeunit 50025 "MBS PV Display Mgt"
{
    Access = Internal;

    var
        PercentFormatTxt: Label '%1%', Locked = true, Comment = '%1 = number';

    procedure FormatKpi(var Snapshot: Record "MBS PV Snapshot Buffer" temporary; KpiNo: Integer): Text
    var
        Availability: Enum "MBS PV KPI Availability";
        IntValue: Integer;
        DecimalValue: Decimal;
        Kind: Option Count,Percent,Amount;
    begin
        case KpiNo of
            1:
                begin
                    Availability := Snapshot."KPI 1 Availability";
                    IntValue := Snapshot."KPI 1 Int";
                    DecimalValue := Snapshot."KPI 1 Decimal";
                end;
            2:
                begin
                    Availability := Snapshot."KPI 2 Availability";
                    IntValue := Snapshot."KPI 2 Int";
                    DecimalValue := Snapshot."KPI 2 Decimal";
                end;
            3:
                begin
                    Availability := Snapshot."KPI 3 Availability";
                    IntValue := Snapshot."KPI 3 Int";
                    DecimalValue := Snapshot."KPI 3 Decimal";
                end;
            else
                exit('');
        end;

        if Availability <> Availability::Available then
            exit(Format(Availability));

        Kind := GetKpiKind(Snapshot."Dashboard Type", KpiNo);
        case Kind of
            Kind::Count:
                exit(Format(IntValue));
            Kind::Percent:
                exit(StrSubstNo(PercentFormatTxt, Format(DecimalValue, 0, '<Precision,1:1><Standard Format,0>')));
            else
                exit(Format(DecimalValue, 0, '<Precision,2:2><Standard Format,0>'));
        end;
    end;

    local procedure GetKpiKind(DashboardType: Enum "MBS PV Dashboard Type"; KpiNo: Integer) Kind: Option Count,Percent,Amount
    begin
        case DashboardType of
            DashboardType::Sales:
                case KpiNo of
                    1:
                        Kind := Kind::Count;
                    2:
                        Kind := Kind::Amount;
                    else
                        Kind := Kind::Percent;
                end;
            DashboardType::Production:
                if KpiNo = 1 then
                    Kind := Kind::Percent
                else
                    Kind := Kind::Count;
            DashboardType::Profitability:
                case KpiNo of
                    1:
                        Kind := Kind::Percent;
                    2:
                        Kind := Kind::Count;
                    else
                        Kind := Kind::Amount;
                end;
        end;
    end;
}
