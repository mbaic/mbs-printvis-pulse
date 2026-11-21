# Dashboard mockups

Static mockups of the PrintVis Pulse dashboards. Each screen exists as a self-contained HTML file (open it in a browser, light and dark mode follow the system) and as a PNG rendered from it.

These are **illustrations with sample data**, not screenshots of a running Business Central. They show the information layout the AL pages produce: period filter and Refresh action, status header, three KPIs with dynamic captions and notes, a top-5 bar chart, and a top-10 exception list with the **Open PrintVis Case** action. The real pages use the Business Central web client styling.

| Mockup | Shows |
| --- | --- |
| [Sales dashboard](01-sales-dashboard.png) ([html](01-sales-dashboard.html)) | Open quotes, open quote value, hit rate, value by product group, top open quotes by value |
| [Production dashboard](02-production-dashboard.png) ([html](02-production-dashboard.html)) | On-time shipments with the promise field named, at-risk operations with the fallback caption and due date source, planned vs. spent hours, at-risk list by due date |
| [Profitability dashboard](03-profitability-dashboard.png) ([html](03-profitability-dashboard.html)) | Realized margin, cases over estimate, WIP shown as `Unavailable` until verified, estimate vs. actual cost, overrun list |
| [Unavailable state](04-unavailable-state.png) ([html](04-unavailable-state.html)) | What users see until a verified PrintVis binding exists, or when a reader fails. KPIs show `Unavailable`, never `0` |
| [Mixed currency state](05-mixed-currency-state.png) ([html](05-mixed-currency-state.html)) | KPI 2 shows `N/A`, the chart carries the message, and the list switches to `Open Quotes by Deadline` |

Display rules shown here: `Available` shows the value, `NotApplicable` shows `N/A`, `Unavailable` shows `Unavailable`, and a real zero stays `0`.
