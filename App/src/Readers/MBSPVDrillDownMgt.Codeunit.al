namespace MBS.PrintVisPulse.Readers;

/// <summary>
/// Read-only navigation from an exception row to the PrintVis case card.
/// The PrintVis binding opens the verified Case Card page in OnOpenCase. It must confirm that the record exists in the current company
/// and that the user can read it before it calls Page.Run. Without a binding the user gets a clear error and nothing opens.
/// </summary>
codeunit 50033 "MBS PV DrillDown Mgt."
{
    Access = Internal;

    var
        NoSourceErr: Label 'This row has no PrintVis source record to open.';
        CaseCardNotVerifiedErr: Label 'The PrintVis case card is not verified for this tenant. See App/DATA-CONTRACT.md.';

    procedure OpenCase(SourceSystemId: Guid)
    var
        Handled: Boolean;
    begin
        if IsNullGuid(SourceSystemId) then
            Error(NoSourceErr);

        OnOpenCase(SourceSystemId, Handled);
        if not Handled then
            Error(CaseCardNotVerifiedErr);
    end;

    /// <summary>Raised when the user chooses Open PrintVis Case. A subscriber opens the verified card and sets Handled to true.</summary>
    [IntegrationEvent(false, false)]
    procedure OnOpenCase(SourceSystemId: Guid; var IsHandled: Boolean)
    begin
    end;
}
