namespace MBS.PrintVisPulse.Test;

using MBS.PrintVisPulse.Buffers;
using MBS.PrintVisPulse.Readers;
using System.TestLibraries.Utilities;

codeunit 50105 "MBS PV Reader Runner Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        Runner: Codeunit "MBS PV Reader Runner";
        DrillDownMgt: Codeunit "MBS PV DrillDown Mgt.";

    [Test]
    procedure ReaderWithoutVerifiedBindingDegradesToUnavailableTest()
    var
        InputRows: Record "MBS PV Quote Input Buffer" temporary;
        RowsRead: Integer;
    begin
        // [SCENARIO] With no PrintVis binding the runner reports failure instead of raising an error
        LibraryAssert.IsFalse(Runner.ReadSales(DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026), InputRows, RowsRead), 'The runner should report failure.');
        LibraryAssert.AreEqual(0, RowsRead, 'No rows were read.');
        LibraryAssert.AreEqual(0, InputRows.Count(), 'The buffer stays empty.');
    end;

    [Test]
    procedure ReaderErrorDegradesToUnavailableTest()
    var
        Stub: Codeunit "MBS PV Test Reader Stub";
        InputRows: Record "MBS PV Quote Input Buffer" temporary;
        RowsRead: Integer;
    begin
        // [SCENARIO] A reader error is caught by the runner and never reaches the user (M7)
        Stub.SetFailReader(true);
        BindSubscription(Stub);

        LibraryAssert.IsFalse(Runner.ReadSales(DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026), InputRows, RowsRead), 'The runner should report failure.');
        LibraryAssert.AreEqual(0, InputRows.Count(), 'The buffer stays empty.');

        UnbindSubscription(Stub);
    end;

    [Test]
    procedure HandledSalesReaderReturnsRowsTest()
    var
        Stub: Codeunit "MBS PV Test Reader Stub";
        InputRows: Record "MBS PV Quote Input Buffer" temporary;
        RowsRead: Integer;
    begin
        // [SCENARIO] A handled reader fills the buffer and reports the row count
        BindSubscription(Stub);

        LibraryAssert.IsTrue(Runner.ReadSales(DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026), InputRows, RowsRead), 'The runner should succeed.');
        LibraryAssert.AreEqual(1, RowsRead, 'One row was read.');
        LibraryAssert.IsTrue(InputRows.Get('STUB1'), 'The stub row is in the buffer.');

        UnbindSubscription(Stub);
    end;

    [Test]
    procedure HandledProductionReaderReturnsPromiseFieldNameTest()
    var
        Stub: Codeunit "MBS PV Test Reader Stub";
        InputRows: Record "MBS PV Prod Input Buffer" temporary;
        PromiseFieldName: Text[80];
        RowsRead: Integer;
    begin
        // [SCENARIO] The production reader returns the promise field name chosen by the binding
        BindSubscription(Stub);

        LibraryAssert.IsTrue(Runner.ReadProduction(DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026), InputRows, PromiseFieldName, RowsRead), 'The runner should succeed.');
        LibraryAssert.AreEqual('Shipment Date Job', PromiseFieldName, 'The promise field name is passed through.');
        LibraryAssert.AreEqual(1, RowsRead, 'One row was read.');

        UnbindSubscription(Stub);
    end;

    [Test]
    procedure HandledProfitReaderReturnsWipFlagTest()
    var
        Stub: Codeunit "MBS PV Test Reader Stub";
        InputRows: Record "MBS PV Profit Input Buffer" temporary;
        WipVerified: Boolean;
        RowsRead: Integer;
    begin
        // [SCENARIO] The profitability reader returns the WIP verification flag chosen by the binding
        BindSubscription(Stub);

        LibraryAssert.IsTrue(Runner.ReadProfitability(DMY2Date(1, 6, 2026), DMY2Date(30, 6, 2026), InputRows, WipVerified, RowsRead), 'The runner should succeed.');
        LibraryAssert.IsTrue(WipVerified, 'The WIP flag is passed through.');
        LibraryAssert.AreEqual(1, RowsRead, 'One row was read.');

        UnbindSubscription(Stub);
    end;

    [Test]
    procedure DrillDownWithoutSourceRecordFailsClearlyTest()
    var
        NullGuid: Guid;
    begin
        // [SCENARIO] A row without a source record cannot be opened
        asserterror DrillDownMgt.OpenCase(NullGuid);
        LibraryAssert.ExpectedError('no PrintVis source record');
    end;

    [Test]
    procedure DrillDownWithoutVerifiedCardFailsClearlyTest()
    begin
        // [SCENARIO] Without a verified case card nothing opens and the user sees why
        asserterror DrillDownMgt.OpenCase(CreateGuid());
        LibraryAssert.ExpectedError('not verified');
    end;

    [Test]
    procedure DrillDownPassesSourceSystemIdToBindingTest()
    var
        Stub: Codeunit "MBS PV Test Reader Stub";
        SourceId: Guid;
    begin
        // [SCENARIO] The binding receives the row's source SystemId
        SourceId := CreateGuid();
        BindSubscription(Stub);

        DrillDownMgt.OpenCase(SourceId);

        LibraryAssert.AreEqual(SourceId, Stub.GetOpenedSystemId(), 'The binding gets the row SystemId.');
        UnbindSubscription(Stub);
    end;
}
