# MBS PrintVis Pulse - Dataset

Demo data for [MBS PrintVis Pulse](../README.md) so the three dashboards load on a sandbox with no usable PrintVis history.

## Use

1. Publish the Pulse app and this dataset app.
2. Open **PrintVis Pulse Demo Data** (Tell Me), set the **work date** to today, choose **Create Demo Data**.
3. Open a Pulse dashboard and refresh.
4. When finished, choose **Delete Demo Data**. Every created record is in the log and is removed in one run, then the log is cleared.

## What it creates (14 cases, dated relative to the work date, SEK/LCY, no currency code)

| PrintVis table | Rows | Feeds |
|---|---|---|
| `PVS Case` (6010312) | 14: 5 open quotes, 2 lost quotes, 4 closed and invoiced orders, 3 open orders | Open quotes and value, product-group chart, hit rate (6 won : 2 lost), closed cases, WIP |
| `PVS Job` (6010313) | 14, version 1 | Quoted price, net profit (estimate baseline) |
| `PVS Job Planning Unit` (6010323) | 11 operations on offset press, digital press, die-cutter, guillotine, folder-gluer | At-risk and in-progress operations, planned vs. spent hours |
| `PVS Job Costing Labor Entry` (6010325) | 1 per operation with spent hours | Labor hours |
| `PVS Job Shipment` (6010314) | 7 (4 shipped: 2 on time, 2 late) | On-Time Shipments % |
| `PVS Job Costing Entry` (6010342) | 14: material and labor per order | Cases over estimate, realized margin |

## How it works

- Writes through `RecordRef` by table and field number (PrintVis 28.1.2.13 definitions), so there is no compile-time dependency on PrintVis. Inserts do not run PrintVis triggers.
- Log table `MBS PV Demo Log` (50200) stores table number and `SystemId` per record. Cleanup deletes newest first by `SystemId`.
- Creation is blocked while the log has rows, and when `PVS Case` 990001 already exists. Case IDs and job IDs use 990001 and up.
- Object IDs 50200..50299.

## Limits

- Sandbox use only. The data bypasses PrintVis business logic, and cost estimates are held in `PVS Job` net profit fields, not in calculation detail.
- `PVS Job` estimate cost fields (`Total Cost Calc.`) are FlowFields and are not populated.
