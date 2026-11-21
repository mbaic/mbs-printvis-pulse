# MBS PrintVis Pulse - Test

Automated unit test suite for [MBS PrintVis Pulse](../README.md).

## Problem

KPI formulas, period boundaries, currency rules, `N/A` and `Unavailable` guards, and tie-break rankings can regress during refactoring or BC and PrintVis upgrades.

## Architecture

- **Pure calculator testing:** tests feed normalized rows from `MBS PV Test Fixtures` (`50100`) directly into the production calculators (`50020..50022`). Fixed dates keep every test deterministic.
- **Reader seam testing:** `MBS PV Test Reader Stub` (`50106`) is a manual-bind event subscriber that stands in for a PrintVis binding. It drives the reader runner and the drill-down without PrintVis installed.
- **Execution environment:** unit tests run in the AL-Go container pipeline. The SaaS sandbox is for acceptance checks only.
- **Access:** tests call internal calculator and buffer objects through `internalsVisibleTo`.

### Test codeunits

| Codeunit | ID | Focus |
| --- | --- | --- |
| `MBS PV Test Fixtures` | `50100` | Row builders and chart JSON readers |
| `MBS PV Sales Calc Tests` | `50101` | Open, won, rejected, canceled, archived, never-issued quotes, boundaries, mixed currency, `N/A`, `Unavailable`, ranking |
| `MBS PV Prod Calc Tests` | `50102` | On-time %, blank dates, split shipments, versions, due-date window, captions, hours, ranking, `Unavailable` |
| `MBS PV Profit Calc Tests` | `50103` | Margin, credit memos, `N/A` guards, baselines, labor no-double-count, ties, WIP, `Unavailable` |
| `MBS PV Support Tests` | `50104` | Period presets, KPI display text, chart JSON |
| `MBS PV Reader Runner Tests` | `50105` | Reader failure to `Unavailable`, binding pass-through, drill-down errors |
| `MBS PV Test Reader Stub` | `50106` | Manual event subscriber used by `50105` |

## Running tests

1. Run the AL-Go CI container pipeline to publish `App` and `App.Test` and execute codeunits `50101..50105`.
2. For manual sandbox checks, confirm AL Test Toolkit availability first.

## Notes

- **Object ID range:** `50100..50199`
- **Dependencies:** MBS PrintVis Pulse, Microsoft `Library Assert` and `Any`.
- **CI:** registered under `testFolders` in `.AL-Go/settings.json`.
- **License:** [MIT](../LICENSE)
