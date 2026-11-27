# PrintVis Data Contract

**Status: partly bound, gates not fully verified.** Gates G0.1 to G0.4 below are still open. No PrintVis symbols are available in this repository. `MBS PV PrintVis Binding` (codeunit 50035) resolves PrintVis tables and fields by name at runtime with `RecordRef`. It binds the Sales reader and the case drill-down only. The Production and Profitability readers have no binding, so those dashboards show `Unavailable`. Current WIP stays `Unavailable` until it is verified as monetary LCY.

Record the exact Business Central version and PrintVis version for every verification below.

| Gate | Required verification | Result | BC version | PrintVis version |
| --- | --- | --- | --- | --- |
| G0.1 Packages | `id`, `name`, `publisher`, installed `version` of every PrintVis `.app` that owns a used object | Pending | | |
| G0.2 Symbols and joins | Namespace, owner, `Access`, `ObsoleteState`, field types, `FieldClass`, primary keys, cardinality, keys and SIFT, enum values. Confirm the `PVS Case.ID` type and full primary key. Check for an operation-level due date (E1) | Pending | | |
| G0.3 Semantics and drill-down | Lifecycle flags, version rules, date meanings, currency basis, additive cost entries, credit memo signs, Case Card page and access (E1, E2, E5, E6, S16) | Pending | | |
| G0.4 Analysis fallback | `Internal` core tables: public analysis table fallback. No `powerbi` v2.0 objects (E3), no API page procedures (E4), `LoadData()` cost measured (E7) | Pending | | |

## Facts confirmed so far

| Fact | Source |
| --- | --- |
| `PVS Case` is table `6010312` | Page Inspection on the sandbox, 2026-11-22 |
| The Sales binding reads `PVS Case` by field name and fails to `Unavailable` if a field is missing | `App/src/Binding/MBSPVPrintVisBinding.Codeunit.al` |
| The case list is page `6010326` `PVS Case Management` (List) | Page Inspection on the sandbox, 2026-11-22 |

Use **Collect Data Info** (Role Center, dashboards, or Tell Me) to profile the PrintVis tables and record the results for G0.1 to G0.3. The report lists the installed PrintVis apps with versions, the table list, and per table the primary key, fields with types, date ranges, option and boolean value counts, and non-zero decimal ranges. It reads the first 3000 rows per table and writes nothing.

## Reader binding contract

A binding subscribes to the reader events and must follow these rules:

| Event | Fills | Also sets |
| --- | --- | --- |
| `MBS PV Sales Reader.OnReadSource` | `MBS PV Quote Input Buffer`, one row per case | `IsHandled := true` |
| `MBS PV Prod Reader.OnReadSource` | `MBS PV Prod Input Buffer`: operation rows and shipment rows | `PromiseFieldNameResult` (exact verified field name, E2), `IsHandled := true` |
| `MBS PV Profit Reader.OnReadSource` | `MBS PV Profit Input Buffer`, one row per case | `WipVerifiedResult` (only when `PVS Case.WIP` is verified as monetary LCY), `IsHandled := true` |
| `MBS PV DrillDown Mgt..OnOpenCase` | n/a | Opens the verified Case Card read-only after checking that the record exists and is readable. Sets `IsHandled := true` |

Rules for every binding:

- Use `ReadIsolation(IsolationLevel::ReadCommitted)` and `SetLoadFields` on normal fields. Handle FlowFields explicitly.
- Convert `DateTime` source fields with `DT2Date` in the user's time zone before period comparison (S16).
- Dedupe to one row per primary key. Carry the verified same-company `SystemId` of the PrintVis case in `Source SystemId`.
- Fill `Normalized Amount` and set `Normalized := true` only when the currency basis is verified. Calculators then show `N/A` for mixed bases.
- Report hours in hours. Report credit memo sales as positive amounts in `Credit Memo Sales`. Set `Labor In Cost Entry` to the verified E5 result so labor is never counted twice.
- Set `Is Sold Version` only for the version that carries the accepted estimate (alternative and superseded versions are excluded).
- Never write to PrintVis tables. Never use dynamic bypasses, guessed substitutions, or same-tenant HTTP calls.

If a KPI's contract is not verified, leave the reader unhandled or return only the verified KPIs' data. Never ship an approximation under the original label.

## Sandbox acceptance log

| Date | BC version | PrintVis version | Dashboard | Rows reconciled | Variance | Elapsed ms | Rows read |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | |
