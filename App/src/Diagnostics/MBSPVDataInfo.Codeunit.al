namespace MBS.PrintVisPulse.Diagnostics;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Apps;
using System.Reflection;

/// <summary>
/// Diagnostic only. Profiles the PrintVis tables the dashboards depend on, using RecordRef so no PrintVis dependency is needed.
/// It reads data (first rows per table) and writes nothing. The dashboards never use this path for KPI values.
/// Output is a plain text report: environment, installed PrintVis apps, table list, and per table the key, fields,
/// date ranges, option and boolean value counts, and non-zero decimal ranges.
/// </summary>
codeunit 50027 "MBS PV Data Info"
{
    Access = Internal;

    var
        TableNotFoundLbl: Label 'Table "%1" was not found.', Locked = true;
        OtherValuesTxt: Label '(other values)', Locked = true;
        TableFailedLbl: Label 'Table %1 could not be profiled: %2', Locked = true;

    procedure Collect(): Text
    var
        Output: TextBuilder;
    begin
        AddEnvironment(Output);
        AddInstalledApps(Output);
        AddTableList(Output);
        ProfileByName(Output, 'PVS Case');
        ProfileByName(Output, 'PVS Job Planning Unit');
        ProfileByName(Output, 'PVS Job Costing Entry');
        ProfileByName(Output, 'PVS Job Costing Labor Entry');
        ProfileByName(Output, 'PVS Job');
        ProfileByName(Output, 'PVS Job Shipment');
        ProfileByName(Output, 'PVS Job Calculation Unit');
        ProfileByName(Output, 'PVS Job Process');
        ProfileByName(Output, 'PVS Quote Probability');
        exit(Output.ToText());
    end;

    local procedure MaxRows(): Integer
    begin
        exit(3000);
    end;

    local procedure AddEnvironment(var Output: TextBuilder)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LcyCode: Code[10];
    begin
        if GeneralLedgerSetup.Get() then
            LcyCode := GeneralLedgerSetup."LCY Code";
        Output.AppendLine('MBS PrintVis Pulse data info');
        Output.AppendLine('Company: ' + CompanyName());
        Output.AppendLine('Work date: ' + Format(WorkDate(), 0, 9));
        Output.AppendLine('Today: ' + Format(Today(), 0, 9));
        Output.AppendLine('LCY code: ' + LcyCode);
        Output.AppendLine('Rows scanned per table (max): ' + Format(MaxRows()));
        Output.AppendLine('');
    end;

    local procedure AddInstalledApps(var Output: TextBuilder)
    var
        InstalledApp: Record "NAV App Installed App";
    begin
        Output.AppendLine('--- Installed apps (PrintVis and Base Application) ---');
        InstalledApp.SetFilter(Publisher, '@*PrintVis*');
        if InstalledApp.FindSet() then
            repeat
                Output.AppendLine(FormatApp(InstalledApp));
            until InstalledApp.Next() = 0;

        InstalledApp.Reset();
        InstalledApp.SetFilter(Name, '@*PrintVis*|Base Application');
        if InstalledApp.FindSet() then
            repeat
                Output.AppendLine(FormatApp(InstalledApp));
            until InstalledApp.Next() = 0;
        Output.AppendLine('');
    end;

    local procedure FormatApp(var InstalledApp: Record "NAV App Installed App"): Text
    begin
        exit(StrSubstNo('%1 | %2 | %3.%4.%5.%6 | %7',
            InstalledApp.Name, InstalledApp.Publisher,
            InstalledApp."Version Major", InstalledApp."Version Minor", InstalledApp."Version Build", InstalledApp."Version Revision",
            Format(InstalledApp."App ID")));
    end;

    local procedure AddTableList(var Output: TextBuilder)
    var
        TableMetadata: Record "Table Metadata";
        Listed: Integer;
    begin
        Output.AppendLine('--- PrintVis tables related to cases, jobs, shipments, costing, quotes (ID | name) ---');
        TableMetadata.SetFilter(Name, '@PVS*');
        if TableMetadata.FindSet() then
            repeat
                if IsRelevantTable(TableMetadata.Name) and (Listed < 400) then begin
                    Listed += 1;
                    Output.AppendLine(StrSubstNo('%1 | %2', TableMetadata.ID, TableMetadata.Name));
                end;
            until TableMetadata.Next() = 0;
        Output.AppendLine('Listed: ' + Format(Listed));
        Output.AppendLine('');
    end;

    local procedure IsRelevantTable(TableName: Text): Boolean
    var
        LowerName: Text;
    begin
        LowerName := TableName.ToLower();
        exit(
            LowerName.Contains('case') or LowerName.Contains('job') or LowerName.Contains('ship') or
            LowerName.Contains('costing') or LowerName.Contains('quote') or LowerName.Contains('planning'));
    end;

    local procedure ProfileByName(var Output: TextBuilder; TableName: Text)
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.SetRange(Name, CopyStr(TableName, 1, MaxStrLen(TableMetadata.Name)));
        if not TableMetadata.FindFirst() then begin
            Output.AppendLine(StrSubstNo(TableNotFoundLbl, TableName));
            Output.AppendLine('');
            exit;
        end;
        if not TryProfileTable(TableMetadata.ID, Output) then begin
            Output.AppendLine(StrSubstNo(TableFailedLbl, TableName, GetLastErrorText()));
            Output.AppendLine('');
        end;
    end;

    [TryFunction]
    local procedure TryProfileTable(TableId: Integer; var Output: TextBuilder)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        FieldNos: List of [Integer];
        FieldNo: Integer;
        MinDates: Dictionary of [Integer, Date];
        MaxDates: Dictionary of [Integer, Date];
        MinDecimals: Dictionary of [Integer, Decimal];
        MaxDecimals: Dictionary of [Integer, Decimal];
        Counts: Dictionary of [Integer, Integer];
        Distribution: Dictionary of [Integer, Dictionary of [Text, Integer]];
        Index: Integer;
        RowsScanned: Integer;
    begin
        RecRef.Open(TableId);
        Output.AppendLine('=== ' + RecRef.Name + ' (table ' + Format(TableId) + ') ===');
        Output.AppendLine('Records: ' + Format(RecRef.Count()));

        KeyRef := RecRef.KeyIndex(1);
        Output.Append('Primary key: ');
        for Index := 1 to KeyRef.FieldCount() do begin
            FldRef := KeyRef.FieldIndex(Index);
            Output.Append(FldRef.Name + ' ');
        end;
        Output.AppendLine('');

        Output.AppendLine('Fields (no. | name | type | length):');
        for Index := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(Index);
            if (FldRef.Class = FieldClass::Normal) and FldRef.Active() then begin
                FieldNos.Add(FldRef.Number);
                Output.AppendLine(StrSubstNo('%1 | %2 | %3 | %4', FldRef.Number, FldRef.Name, Format(FldRef.Type), FldRef.Length));
            end;
        end;

        if RecRef.FindSet() then
            repeat
                RowsScanned += 1;
                foreach FieldNo in FieldNos do
                    ScanField(RecRef.Field(FieldNo), MinDates, MaxDates, MinDecimals, MaxDecimals, Counts, Distribution);
            until (RecRef.Next() = 0) or (RowsScanned >= MaxRows());

        Output.AppendLine('Rows scanned: ' + Format(RowsScanned));
        Output.AppendLine('Value profile (only fields with data):');
        foreach FieldNo in FieldNos do
            WriteFieldProfile(Output, RecRef.Field(FieldNo), MinDates, MaxDates, MinDecimals, MaxDecimals, Counts, Distribution);
        Output.AppendLine('');
        RecRef.Close();
    end;

    local procedure ScanField(FldRef: FieldRef; var MinDates: Dictionary of [Integer, Date]; var MaxDates: Dictionary of [Integer, Date]; var MinDecimals: Dictionary of [Integer, Decimal]; var MaxDecimals: Dictionary of [Integer, Decimal]; var Counts: Dictionary of [Integer, Integer]; var Distribution: Dictionary of [Integer, Dictionary of [Text, Integer]])
    var
        DateValue: Date;
        DateTimeValue: DateTime;
        DecimalValue: Decimal;
    begin
        case FldRef.Type of
            FieldType::Date:
                begin
                    DateValue := FldRef.Value;
                    if DateValue <> 0D then
                        TrackDate(FldRef.Number, DateValue, MinDates, MaxDates, Counts);
                end;
            FieldType::DateTime:
                begin
                    DateTimeValue := FldRef.Value;
                    if DateTimeValue <> 0DT then
                        TrackDate(FldRef.Number, DT2Date(DateTimeValue), MinDates, MaxDates, Counts);
                end;
            FieldType::Decimal:
                begin
                    DecimalValue := FldRef.Value;
                    if DecimalValue <> 0 then
                        TrackDecimal(FldRef.Number, DecimalValue, MinDecimals, MaxDecimals, Counts);
                end;
            FieldType::Boolean,
            FieldType::Option,
            FieldType::Integer,
            FieldType::Code:
                TrackValue(FldRef.Number, Format(FldRef.Value), Distribution);
        end;
    end;

    local procedure TrackDate(FieldNo: Integer; Value: Date; var MinDates: Dictionary of [Integer, Date]; var MaxDates: Dictionary of [Integer, Date]; var Counts: Dictionary of [Integer, Integer])
    begin
        if MinDates.ContainsKey(FieldNo) then begin
            if Value < MinDates.Get(FieldNo) then
                MinDates.Set(FieldNo, Value);
            if Value > MaxDates.Get(FieldNo) then
                MaxDates.Set(FieldNo, Value);
        end else begin
            MinDates.Add(FieldNo, Value);
            MaxDates.Add(FieldNo, Value);
        end;
        IncrementCount(FieldNo, Counts);
    end;

    local procedure TrackDecimal(FieldNo: Integer; Value: Decimal; var MinDecimals: Dictionary of [Integer, Decimal]; var MaxDecimals: Dictionary of [Integer, Decimal]; var Counts: Dictionary of [Integer, Integer])
    begin
        if MinDecimals.ContainsKey(FieldNo) then begin
            if Value < MinDecimals.Get(FieldNo) then
                MinDecimals.Set(FieldNo, Value);
            if Value > MaxDecimals.Get(FieldNo) then
                MaxDecimals.Set(FieldNo, Value);
        end else begin
            MinDecimals.Add(FieldNo, Value);
            MaxDecimals.Add(FieldNo, Value);
        end;
        IncrementCount(FieldNo, Counts);
    end;

    local procedure IncrementCount(FieldNo: Integer; var Counts: Dictionary of [Integer, Integer])
    begin
        if Counts.ContainsKey(FieldNo) then
            Counts.Set(FieldNo, Counts.Get(FieldNo) + 1)
        else
            Counts.Add(FieldNo, 1);
    end;

    local procedure TrackValue(FieldNo: Integer; ValueText: Text; var Distribution: Dictionary of [Integer, Dictionary of [Text, Integer]])
    var
        ValueCounts: Dictionary of [Text, Integer];
    begin
        if Distribution.ContainsKey(FieldNo) then
            ValueCounts := Distribution.Get(FieldNo);

        if ValueCounts.ContainsKey(ValueText) then
            ValueCounts.Set(ValueText, ValueCounts.Get(ValueText) + 1)
        else
            if ValueCounts.Count() < 15 then
                ValueCounts.Add(ValueText, 1)
            else
                if ValueCounts.ContainsKey(OtherValuesTxt) then
                    ValueCounts.Set(OtherValuesTxt, ValueCounts.Get(OtherValuesTxt) + 1)
                else
                    ValueCounts.Add(OtherValuesTxt, 1);

        if Distribution.ContainsKey(FieldNo) then
            Distribution.Set(FieldNo, ValueCounts)
        else
            Distribution.Add(FieldNo, ValueCounts);
    end;

    local procedure WriteFieldProfile(var Output: TextBuilder; FldRef: FieldRef; var MinDates: Dictionary of [Integer, Date]; var MaxDates: Dictionary of [Integer, Date]; var MinDecimals: Dictionary of [Integer, Decimal]; var MaxDecimals: Dictionary of [Integer, Decimal]; var Counts: Dictionary of [Integer, Integer]; var Distribution: Dictionary of [Integer, Dictionary of [Text, Integer]])
    var
        ValueCounts: Dictionary of [Text, Integer];
        ValueText: Text;
        Line: Text;
    begin
        case FldRef.Type of
            FieldType::Date,
            FieldType::DateTime:
                if MinDates.ContainsKey(FldRef.Number) then
                    Output.AppendLine(StrSubstNo('DATE %1 | non-blank %2 | %3 .. %4',
                        FldRef.Name, Counts.Get(FldRef.Number), Format(MinDates.Get(FldRef.Number), 0, 9), Format(MaxDates.Get(FldRef.Number), 0, 9)));
            FieldType::Decimal:
                if MinDecimals.ContainsKey(FldRef.Number) then
                    Output.AppendLine(StrSubstNo('DECIMAL %1 | non-zero %2 | %3 .. %4',
                        FldRef.Name, Counts.Get(FldRef.Number), Format(MinDecimals.Get(FldRef.Number), 0, 9), Format(MaxDecimals.Get(FldRef.Number), 0, 9)));
            FieldType::Boolean,
            FieldType::Option,
            FieldType::Integer,
            FieldType::Code:
                if Distribution.ContainsKey(FldRef.Number) then begin
                    ValueCounts := Distribution.Get(FldRef.Number);
                    Line := '';
                    foreach ValueText in ValueCounts.Keys() do
                        Line += StrSubstNo('%1=%2; ', ValueText, ValueCounts.Get(ValueText));
                    if FldRef.Type = FieldType::Option then
                        Line := Line + '| options: ' + FldRef.OptionMembers;
                    Output.AppendLine(StrSubstNo('VALUES %1 | %2', FldRef.Name, Line));
                end;
        end;
    end;
}
