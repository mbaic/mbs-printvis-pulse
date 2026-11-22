namespace MBS.PrintVisPulse.Binding;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;
using System.Reflection;

/// <summary>
/// PrintVis binding for the Sales and Quote Pipeline dashboard and the case drill-down.
/// The PrintVis symbols are not a compile dependency, so tables and fields are resolved by name at runtime with RecordRef.
/// A missing table is not an error: the event stays unhandled and the dashboard shows Unavailable.
/// A missing field raises an error that the reader runner logs, and the dashboard shows Unavailable.
/// Field names come from the PrintVis table definitions of the target tenant, see App/DATA-CONTRACT.md. The binding only reads.
/// </summary>
codeunit 50035 "MBS PV PrintVis Binding"
{
    Access = Internal;

    var
        FieldNos: Dictionary of [Text, Integer];
        CaseTableId: Integer;
        MissingFieldErr: Label 'PrintVis field "%1" was not found in table "%2". The binding does not match the installed PrintVis version.', Comment = '%1 = field name, %2 = table name';
        SystemIdFieldNo: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV Sales Reader", 'OnReadSource', '', false, false)]
    local procedure ReadSales(PeriodFrom: Date; PeriodTo: Date; var InputRows: Record "MBS PV Quote Input Buffer" temporary; var IsHandled: Boolean)
    var
        CaseRef: RecordRef;
    begin
        if IsHandled then
            exit;
        if not ResolveTable('PVS Case', CaseTableId) then
            exit;

        CaseRef.Open(CaseTableId);
        CaseRef.ReadIsolation := IsolationLevel::ReadCommitted;
        LoadCaseFields(CaseRef);
        if CaseRef.FindSet() then
            repeat
                AddQuoteRow(CaseRef, InputRows);
            until CaseRef.Next() = 0;
        CaseRef.Close();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MBS PV DrillDown Mgt.", 'OnOpenCase', '', false, false)]
    local procedure OpenCaseCard(SourceSystemId: Guid; var IsHandled: Boolean)
    var
        CaseRef: RecordRef;
    begin
        if IsHandled then
            exit;
        if not ResolveTable('PVS Case', CaseTableId) then
            exit;

        CaseRef.Open(CaseTableId);
        if not CaseRef.ReadPermission() then
            exit;
        if not CaseRef.GetBySystemId(SourceSystemId) then
            exit;
        CaseRef.SetRecFilter();
        // 6010326 = PVS Case Management, confirmed by Page Inspection. The list opens filtered to this single case; RecordRef cannot be passed to Page.Run, so the web client URL is used.
        Hyperlink(GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 6010326, CaseRef, true));
        IsHandled := true;
    end;

    local procedure AddQuoteRow(var CaseRef: RecordRef; var InputRows: Record "MBS PV Quote Input Buffer" temporary)
    var
        CaseType: Text;
        QuoteNo: Code[20];
        OrderNo: Code[20];
        QuoteDate: Date;
    begin
        CaseType := Format(CaseRef.Field(FldNo('Type')).Value, 0, 9);
        if not (CaseType in ['Quote', 'Order']) then
            exit;

        QuoteNo := CopyStr(Format(CaseRef.Field(FldNo('Quote No.')).Value), 1, MaxStrLen(QuoteNo));
        QuoteDate := CaseRef.Field(FldNo('Quote Date')).Value;
        // An issued quote has a quote number and a quote date. Cases without them are standalone orders or drafts.
        if (QuoteNo = '') or (QuoteDate = 0D) then
            exit;

        OrderNo := CopyStr(Format(CaseRef.Field(FldNo('Order No.')).Value), 1, MaxStrLen(OrderNo));

        InputRows.Init();
        InputRows."Case Key Text" := CopyStr(Format(CaseRef.Field(FldNo('ID')).Value), 1, MaxStrLen(InputRows."Case Key Text"));
        InputRows."Source SystemId" := CaseRef.Field(SystemIdFieldNo).Value;
        InputRows."Quote No." := QuoteNo;
        InputRows."Customer Name" := CopyStr(Format(CaseRef.Field(FldNo('Sell-To Name')).Value), 1, MaxStrLen(InputRows."Customer Name"));
        InputRows."Product Group" := CopyStr(Format(CaseRef.Field(FldNo('Product Group')).Value), 1, MaxStrLen(InputRows."Product Group"));
        InputRows."Currency Code" := CopyStr(Format(CaseRef.Field(FldNo('Currency Code')).Value), 1, MaxStrLen(InputRows."Currency Code"));
        InputRows.Deadline := CaseRef.Field(FldNo('Deadline')).Value;
        InputRows."Quoted Amount" := CaseRef.Field(FldNo('Quoted Sales Price')).Value;
        // The amount is in the case currency. The calculator compares Currency Code with LCY and shows N/A for mixed currencies.
        InputRows."Normalized Amount" := InputRows."Quoted Amount";
        InputRows.Normalized := true;
        InputRows."Is Issued Quote" := true;
        InputRows."Is Archived" := CaseRef.Field(FldNo('Archived')).Value;
        InputRows."Is Canceled" := CaseRef.Field(FldNo('Canceled')).Value;
        SetOutcome(CaseRef, OrderNo, InputRows);
        InputRows.Insert();
    end;

    /// <summary>Won: the quote became an order, decided on the order date. Lost: a rejection code is set, decided on the status change date.</summary>
    local procedure SetOutcome(var CaseRef: RecordRef; OrderNo: Code[20]; var InputRows: Record "MBS PV Quote Input Buffer" temporary)
    var
        RejectionCode: Text;
    begin
        RejectionCode := Format(CaseRef.Field(FldNo('Rejection Code')).Value);
        if OrderNo <> '' then begin
            InputRows.Outcome := InputRows.Outcome::Won;
            InputRows."Decision Date" := CaseRef.Field(FldNo('Order Date')).Value;
        end else
            if RejectionCode <> '' then begin
                InputRows.Outcome := InputRows.Outcome::Lost;
                InputRows."Decision Date" := CaseRef.Field(FldNo('Status Changed On')).Value;
            end else
                InputRows.Outcome := InputRows.Outcome::Open;
    end;

    local procedure LoadCaseFields(var CaseRef: RecordRef)
    var
        Names: List of [Text];
        FieldName: Text;
        Numbers: List of [Integer];
        No: Integer;
    begin
        SystemIdFieldNo := 2000000000;
        Names.AddRange('ID', 'Type', 'Quote No.', 'Order No.', 'Quote Date', 'Order Date', 'Sell-To Name', 'Product Group',
            'Currency Code', 'Deadline', 'Quoted Sales Price', 'Archived', 'Canceled', 'Rejection Code', 'Status Changed On');
        foreach FieldName in Names do begin
            No := ResolveField(CaseTableId, 'PVS Case', FieldName);
            FieldNos.Set(FieldName, No);
            Numbers.Add(No);
        end;
        CaseRef.SetLoadFields(Numbers.Get(1), Numbers.Get(2), Numbers.Get(3), Numbers.Get(4), Numbers.Get(5), Numbers.Get(6), Numbers.Get(7),
            Numbers.Get(8), Numbers.Get(9), Numbers.Get(10), Numbers.Get(11), Numbers.Get(12), Numbers.Get(13), Numbers.Get(14), Numbers.Get(15));
    end;

    local procedure FldNo(FieldName: Text): Integer
    begin
        exit(FieldNos.Get(FieldName));
    end;

    local procedure ResolveTable(TableName: Text; var TableId: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.SetRange(Name, CopyStr(TableName, 1, MaxStrLen(TableMetadata.Name)));
        if not TableMetadata.FindFirst() then
            exit(false);
        TableId := TableMetadata.ID;
        exit(true);
    end;

    local procedure ResolveField(TableId: Integer; TableName: Text; FieldName: Text): Integer
    var
        FieldRec: Record Field;
    begin
        FieldRec.SetRange(TableNo, TableId);
        FieldRec.SetRange(FieldName, CopyStr(FieldName, 1, MaxStrLen(FieldRec.FieldName)));
        if not FieldRec.FindFirst() then
            Error(MissingFieldErr, FieldName, TableName);
        exit(FieldRec."No.");
    end;
}
