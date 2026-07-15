# 📊 Vendor Performance Analysis

> **End-to-end business analytics project** — from raw transactional data to interactive Power BI dashboard and professional report.

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)

---

## 📌 Project Overview

This project analyzes vendor and brand performance across a retail and wholesale distribution business using **12.8 million raw sales transactions** spanning January–December 2026. The goal is to identify profitability gaps, rank top-performing vendors, and surface actionable insights for pricing and inventory decisions.

**Prepared by:** Abhijeet Kishan  
**Tools Used:** MySQL · Power BI · SQL Analytics  
**Analysis Period:** January 2026 – December 2026  

---

## 🎯 Business Problem

Companies in retail and wholesale face losses due to:
- ❌ Inefficient pricing on specific vendor-brand combinations
- ❌ Poor inventory turnover creating unnecessary holding costs
- ❌ Over-dependence on a small number of key vendors

### The 5 Analysis Goals
1. Identify underperforming brands requiring pricing or promotional adjustments
2. Determine top vendors contributing to sales and gross profit
3. Analyze the impact of bulk purchasing on unit costs
4. Assess inventory turnover to reduce holding costs
5. Investigate profitability variance between high and low performing vendors

---

## 📁 Repository Structure

```
vendor-performance-analysis/
│
├── data/
│   ├── begin_inventory.csv        # Stock on hand — January 1, 2026
│   ├── end_inventory.csv          # Stock on hand — December 31, 2026
│   ├── purchases.csv              # Purchase order line items
│   ├── purchase_prices.csv        # Vendor standard list prices
│   ├── sales.csv                  # 12.8M sales transactions
│   ├── vendor_invoice.csv         # Invoice-level vendor data + freight
│   └── vender_performance_data.csv  # Final aggregated summary table (11,450 rows)
│
├── sql/
│   └── big project.sql            # Complete SQL script — all CTEs, aggregations, final table
│
├── report/
│   └── Vendor_Performance_Report_Abhijeet_Kishan.docx   # Full analysis report
│
└── README.md
```

---

## 🗄️ Database Schema

| Table | Rows (approx.) | Description |
|---|---|---|
| `purchases` | ~300K | Purchase order line items per vendor-brand |
| `sales_1` | **12.8 million** | Individual sales transactions Jan–Dec 2026 |
| `vendor_invoice` | ~50K | Invoice-level data including freight cost |
| `purchase_prices` | ~5K | Standard list prices per vendor-brand |
| `begin_inventory` | ~10K | Store-level stock snapshot, Jan 1 2026 |
| `end_inventory` | ~10K | Store-level stock snapshot, Dec 31 2026 |

---

## ⚙️ SQL Approach

The analysis follows a **SQL-first aggregation strategy** — heavy joins and transformations done in MySQL before visualization in Power BI.

### Key SQL Techniques Used

**CTEs (Common Table Expressions)** — modular, readable multi-step aggregation:
```sql
WITH PurchaseSummary AS (
    SELECT
        p.VendorNumber, p.VendorName, p.Brand, p.Description,
        SUM(p.Quantity) AS TotalPurchaseQuantity,
        SUM(p.Dollars)  AS TotalPurchaseDollars,
        SUM(vi.Freight) AS TotalFreightCost
    FROM purchases p
    LEFT JOIN vendor_invoice vi
        ON p.VendorNumber = vi.VendorNumber
        AND p.PONumber    = vi.PONumber          -- dual-key join prevents fan-out
    GROUP BY p.VendorNumber, p.VendorName, p.Brand, p.Description
),
SalesSummary AS (
    SELECT
        s.VendorNo, s.VendorName, s.Brand, s.Description,
        SUM(s.SalesQuantity) AS TotalSalesQuantity,
        SUM(s.SalesDollars)  AS TotalSalesDollars,
        SUM(s.ExciseTax)     AS TotalExciseTax
    FROM sales_1 s
    GROUP BY s.VendorNo, s.VendorName, s.Brand, s.Description
)
```

**UNION-based Full Outer Join** — MySQL doesn't support FULL OUTER JOIN natively:
```sql
-- Keep all purchase records + all sales records (no silent data loss)
SELECT ps.*, ss.TotalSalesQuantity, ss.TotalSalesDollars
FROM PurchaseSummary ps LEFT JOIN SalesSummary ss
    ON ps.VendorNumber = ss.VendorNo AND ps.Brand = ss.Brand
UNION
SELECT ss.VendorNo, ss.VendorName, ss.Brand, ss.Description,
       ps.TotalPurchaseQuantity, ps.TotalPurchaseDollars, ps.TotalFreightCost,
       ss.TotalSalesQuantity, ss.TotalSalesDollars, ss.TotalExciseTax
FROM SalesSummary ss LEFT JOIN PurchaseSummary ps
    ON ss.VendorNo = ps.VendorNumber AND ss.Brand = ps.Brand
```

**Derived Metrics:**
```sql
-- Gross Profit
(TotalSalesDollars - TotalPurchaseDollars) AS GrossProfit,

-- Gross Margin %
CASE WHEN TotalSalesDollars = 0 THEN NULL
     ELSE ROUND((TotalSalesDollars - TotalPurchaseDollars) / TotalSalesDollars * 100, 2)
END AS GrossMarginPct,

-- Inventory Turnover Ratio
CASE WHEN AvgInventory = 0 THEN NULL
     ELSE ROUND(TotalSalesQuantity / AvgInventory, 2)
END AS InventoryTurnoverRatio
```

**Materialized Final Table:**
```sql
CREATE TABLE vendor_performance.final_vendor_summary AS
SELECT ... -- complete aggregated query
```

---

## 📊 Key Findings

| # | Finding | Metric |
|---|---|---|
| 1 | Nearly 1 in 5 vendor-brand combinations are loss-making | **18.58% unprofitable** |
| 2 | Diageo North America Inc leads all vendors by revenue | **$69M in sales** |
| 3 | Bulk orders consistently achieve lower unit costs | Cost decreases: Small → Bulk |
| 4 | High-velocity brands maintain extremely lean stock | Turnover varies widely |
| 5 | Clear profitability gap between top and bottom vendors | **$4.35M in recoverable losses** |

---

## 💡 Key Insights

```
Total Sales Revenue    →  $452.06M
Total Purchase Cost    →  $321.90M
Gross Profit           →  $130.16M  (28.8% margin)
Unprofitable Brands    →  18.58%    (2,127 of 11,450 combinations)
Total Loss Amount      →  -$4.35M   (recoverable through pricing action)
```

> **The headline finding:** Despite strong overall profitability ($130M gross profit),
> 18.58% of vendor-brand combinations are loss-making — representing $4.35M in
> recoverable value through targeted pricing adjustments and vendor renegotiation.

---

## 📈 Power BI Dashboard

The dashboard is built on the `final_vendor_summary` table (11,450 rows, exported as CSV) and includes:

**Page 1 — Executive Overview**
- KPI Cards: Total Sales, Total Purchase, Gross Profit, Unprofitable Brands %
- Donut Chart: Purchase Contribution % by Vendor
- Bar Charts: Top Vendors by Sales | Top Brands by Sales
- Bar Chart: Average Profit Margin % by Vendor

**Page 2 — Loss Analysis**
- KPI Cards: Total Loss Amount | Unprofitable Brands %
- Bar Chart: Loss-Making Vendors (negative GrossProfit, sorted worst-first)
- Bar Chart: Sales Quantity by Vendor

---

## 🚀 How to Reproduce

### 1. Set up the database
```sql
CREATE DATABASE vendor_performance;
USE vendor_performance;
-- Import all 6 CSV files as tables
-- Run: big project.sql
```

### 2. Run the SQL script
The `big project.sql` file contains:
- Table exploration queries
- Index creation for performance (`idx_sales_vendor_brand`)
- All CTE-based aggregations
- `CREATE TABLE final_vendor_summary AS ...`

### 3. Export for Power BI
```sql
SELECT * FROM vendor_performance.final_vendor_summary;
-- Export result grid as CSV from MySQL Workbench
-- Import CSV into Power BI Desktop via Get Data → Text/CSV
```

### 4. Power BI DAX Measures
```
Unprofitable % =
DIVIDE(
    COUNTROWS(FILTER('vender_performance_data', 'vender_performance_data'[GrossProfit] < 0)),
    COUNTROWS('vender_performance_data'), 0) * 100

Total Loss =
SUMX(
    FILTER('vender_performance_data', 'vender_performance_data'[GrossProfit] < 0),
    'vender_performance_data'[GrossProfit])
```

---

## 📋 Recommendations

| Priority | Recommendation |
|---|---|
| 🔴 High | Review pricing for 2,127 loss-making vendor-brand combinations |
| 🔴 High | Renegotiate contracts with top 10 vendors (65%+ purchase concentration) |
| 🟡 Medium | Formalize bulk purchasing agreements where unit cost savings are confirmed |
| 🟡 Medium | Launch promotional clearance for slow-turnover inventory |
| 🔴 High | Implement quarterly vendor performance scorecards |

---

## 👤 About

**Abhijeet Kishan**  
BBA in Logistics — BBD University Lucknow (CGPA: 8.25)  
Skills: SQL · MySQL · Power BI · Tableau · Excel · Business Analytics  

[![LinkedIn] (www.linkedin.com/in/abhijeet-kishan)


---

*This project was built as part of a business analytics portfolio to demonstrate end-to-end data analysis capabilities — from raw data ingestion and SQL aggregation to dashboard creation and report writing.*
