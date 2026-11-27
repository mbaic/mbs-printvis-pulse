# MBS PrintVis Pulse

Main Business Central Demo PTE for native PrintVis performance dashboards. Part of the [MBS PrintVis Pulse](../README.md) repository.

## Architecture

- **Readers (`50030..50032`) and Runner (`50034`):** each reader raises `OnReadSource` for a PrintVis binding and runs inside `Codeunit.Run`, so a reader error degrades the dashboard to `Unavailable`. The runner also logs refresh telemetry (`MBSPV0001`) and reader failures (`MBSPV0002`) with `TelemetryScope::ExtensionPublisher`.
- **Calculators (`50020..50022`):** pure, deterministic AL logic. They compute KPIs, dynamic captions, `N/A` and `Unavailable` states, top-5 chart JSON, and top-10 ranked exception rows into one bounded snapshot. They never read the clock or the database.
- **Support codeunits (`50023..50025`):** chart JSON builder, period arithmetic, KPI display text.
- **Role Center (`50010`) overview parts (`50018..50020`):** one part per dashboard with the three KPIs and the top-5 chart for the last 30 days, built when the Role Center opens.
- **Data Info (`50021`, `50027`):** diagnostic page that profiles PrintVis tables with `RecordRef` and downloads a text report. It needs no PrintVis dependency and is not used for KPI values.
- **Pages (`50010..50017`):** an optional Role Center (`50010`) with declarative links, three searchable `ListPlus` dashboard hosts (`50011..50013`), the shared KPI `CardPart` (`50014`), and three exception `ListParts` (`50015..50017`).
- **Access:** buffers, readers, runner, calculators, and pages are `Access = Internal` and exposed to `App.Test` through `internalsVisibleTo`.

![Production dashboard page: period filter, KPI part, chart add-in and exception list part](../docs/images/production-dashboard-page.png)

*Production dashboard in a CRONUS sandbox with demo data: host page with period filter, KPI part, chart add-in and exception list part.*

### Role Center

![Role Center Insights with Sales, Production, and Profitability tabs](../docs/images/role-center-insights-all.png)

*Insights part on the Role Center. Tabs: All, Sales, Production, Profitability. More screenshots are in the [main README](../README.md#role-center-insights).*

### Object summary

| Range | Area | Objects |
| --- | --- | --- |
| `50000..50007` | Buffers | Snapshot, three input buffers, three exception row tables, chart group buffer (all temporary) |
| `50010..50021` | Pages | Role Center, 3 dashboards, KPI part, 3 exception parts, 3 overview parts, data info |
| `50020..50027` | Calculators and support | Sales, Production, Profitability calculators, chart JSON, period, display, refresh orchestration, data info |
| `50030..50034` | Readers and navigation | Sales, Production, Profitability readers, drill-down manager, reader runner |
| `50040..50042` | Enums | Dashboard type, period filter, KPI availability |
| `50050` | Permissions | `MBS PV Pulse Users` (execute rights on Pulse objects only) |
| Control add-in | Visualization | `MBS PV Chart Host` (local vanilla JS and CSS) |
| Profile | Role | `MBS PV Pulse` (optional) |

### KPI rules

| Dashboard | KPI 1 | KPI 2 | KPI 3 |
| --- | --- | --- | --- |
| Sales | Current Open Quotes | Current Open Quote Value (`N/A` on mixed or unverified currency) | Quote Hit Rate % (`N/A` without decisions) |
| Production | On-Time Shipments % (`Unavailable` until the promise field is named) | At-Risk Operations (caption falls back unless an operation-level due date is used) | In-Progress Operations |
| Profitability | Realized Margin % (`N/A` when net sales are not positive) | Cases Over Estimate | Current WIP (`Unavailable` until verified) |

![Profitability dashboard page with Current WIP shown as Unavailable](../docs/images/profitability-dashboard-page.png)

*Profitability: WIP stays `Unavailable` until the binding verifies it.*

### Chart control add-in

`MBS PV Chart Host` is a control add-in with one vanilla JavaScript file and one CSS file, packaged in the app (no CDN, no npm packages). AL sends a bounded JSON payload through `RenderBarChart(ChartJson)`. The script draws it with DOM text APIs only and raises `OnControlReady` when it is loaded. Why this way, and a note on security for add-ins that load external components, is in the [main README](../README.md#control-add-in-showcase).

## Notes

- **Object ID range:** `50000..50099`.
- **Data contract:** see [`DATA-CONTRACT.md`](DATA-CONTRACT.md) for the PrintVis gates and the reader binding rules.
- **License:** [MIT](../LICENSE)
