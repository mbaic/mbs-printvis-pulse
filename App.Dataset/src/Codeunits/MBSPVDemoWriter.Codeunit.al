namespace MBS.PrintVisPulse.Dataset;

/// <summary>
/// Inserts one PrintVis record through RecordRef (field numbers verified with the PrintVis 28.1 table definitions)
/// and logs it. No compile-time dependency on PrintVis, and no PrintVis triggers run (Insert(false)).
/// </summary>
codeunit 50201 "MBS PV Demo Writer"
{
    Access = Internal;

    var
        RecRef: RecordRef;
        InsertedCount: Integer;
        InsertFailedErr: Label 'Could not insert the demo record into %1 (%2).', Comment = '%1 = table caption, %2 = record position';

    procedure StartRecord(TableNo: Integer)
    begin
        if RecRef.Number() <> 0 then
            RecRef.Close();
        RecRef.Open(TableNo);
        RecRef.Init();
    end;

    procedure SetInt(FieldNo: Integer; Value: Integer)
    begin
        RecRef.Field(FieldNo).Value := Value;
    end;

    procedure SetDec(FieldNo: Integer; Value: Decimal)
    begin
        RecRef.Field(FieldNo).Value := Value;
    end;

    procedure SetText(FieldNo: Integer; Value: Text)
    begin
        RecRef.Field(FieldNo).Value := Value;
    end;

    procedure SetBool(FieldNo: Integer; Value: Boolean)
    begin
        RecRef.Field(FieldNo).Value := Value;
    end;

    procedure SetDate(FieldNo: Integer; Value: Date)
    begin
        RecRef.Field(FieldNo).Value := Value;
    end;

    /// <summary>Option fields take the ordinal value.</summary>
    procedure SetOption(FieldNo: Integer; Ordinal: Integer)
    begin
        RecRef.Field(FieldNo).Value := Ordinal;
    end;

    procedure InsertAndLog()
    var
        DemoLog: Record "MBS PV Demo Log";
        PrimaryKey: KeyRef;
        i: Integer;
        KeyText: Text;
    begin
        if not RecRef.Insert(false) then
            Error(InsertFailedErr, RecRef.Caption(), RecRef.GetPosition());

        PrimaryKey := RecRef.KeyIndex(1);
        for i := 1 to PrimaryKey.FieldCount() do begin
            if KeyText <> '' then
                KeyText += ', ';
            KeyText += Format(PrimaryKey.FieldIndex(i).Value);
        end;

        DemoLog.Init();
        DemoLog."Table No." := RecRef.Number();
        DemoLog."Table Name" := CopyStr(RecRef.Name(), 1, MaxStrLen(DemoLog."Table Name"));
        DemoLog."Source SystemId" := RecRef.Field(RecRef.SystemIdNo()).Value;
        DemoLog."Record Key" := CopyStr(KeyText, 1, MaxStrLen(DemoLog."Record Key"));
        DemoLog."Created At" := CurrentDateTime();
        DemoLog.Insert();
        InsertedCount += 1;
    end;

    procedure NextEntryNo(TableNo: Integer; EntryNoField: Integer): Integer
    var
        Probe: RecordRef;
        LastNo: Integer;
    begin
        Probe.Open(TableNo);
        if Probe.FindLast() then begin
            Evaluate(LastNo, Format(Probe.Field(EntryNoField).Value));
            exit(LastNo + 1);
        end;
        exit(1);
    end;

    procedure KeyExists(TableNo: Integer; KeyField: Integer; KeyValue: Integer): Boolean
    var
        Probe: RecordRef;
    begin
        Probe.Open(TableNo);
        Probe.Field(KeyField).SetRange(KeyValue);
        exit(not Probe.IsEmpty());
    end;

    procedure GetInsertedCount(): Integer
    begin
        exit(InsertedCount);
    end;
}
