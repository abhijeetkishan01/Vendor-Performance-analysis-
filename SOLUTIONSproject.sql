-- start 

use vendor_performance;

-- all files successfully imported

-- check that our data was important
select count(*) from sales_1;

select count(*) from vendor_invoice;

select count(*) from purchases;

select count(*) from  purchase_prices;

select count(*) from end_inventory ;

select count(*) from begin_inventory ;

-- cleaning the data
-- to clean Radha, first, we have to disable safe mode;

SET SQL_SAFE_UPDATES = 0;

UPDATE purchase_prices
SET Volume = null
WHERE Volume = 'Unknown';

UPDATE purchase_prices
SET size = null 
WHERE size = 'Unknown'; 
-- compare and checked all data was clean , added null values in some rows where data was misguided or different types


-- now we are changing data types, altering the table with new data types, which are more reliable

-- changing data type of begin_inventory
SELECT startDate
FROM begin_inventory
LIMIT 100;

SELECT * FROM begin_inventory;

ALTER TABLE begin_inventory
MODIFY InventoryId VARCHAR(35),
MODIFY Store INT,
MODIFY City VARCHAR(70),
MODIFY Brand INT,
MODIFY Description VARCHAR(150),
MODIFY Size VARCHAR(30),
MODIFY onHand INT,
MODIFY Price DECIMAL(10,2),
MODIFY startDate DATE;

-- changing Data type of end_inventory
SELECT * from end_inventory;

ALTER TABLE end_inventory
MODIFY InventoryId VARCHAR(30),
 MODIFY Store INT,
MODIFY City VARCHAR(70),
MODIFY Brand INT,
MODIFY Description VARCHAR(150),
MODIFY Size VARCHAR(30),
MODIFY onHand INT,
MODIFY Price DECIMAL(10,2),
MODIFY endDate DATE;

-- changing data type of purchase_prices;
SELECT * from purchase_prices;

ALTER TABLE purchase_prices
MODIFY Brand INT,
MODIFY Description VARCHAR(255),
MODIFY Price DECIMAL(10,2),
MODIFY Size VARCHAR(20),
MODIFY Volume INT,
MODIFY Classification INT,
MODIFY PurchasePrice DECIMAL(10,2),
MODIFY VendorNumber INT,
MODIFY VendorName VARCHAR(255);

SHOW WARNINGS;

SELECT *
FROM purchase_prices
WHERE Volume = '';

UPDATE purchase_prices
SET Volume = NULL
WHERE Volume = '';

UPDATE purchase_prices
SET Size = NULL
WHERE Size = '';

-- siri, start of the purchases table
SELECT * FROM purchases;

ALTER TABLE purchases
MODIFY InventoryId VARCHAR(30),
MODIFY Store INT,
MODIFY Brand INT,
MODIFY Description VARCHAR(255),
MODIFY Size VARCHAR(20),
MODIFY VendorNumber INT,
MODIFY VendorName VARCHAR(255),
MODIFY PONumber INT,
MODIFY PODate DATE,
MODIFY ReceivingDate DATE,
MODIFY InvoiceDate DATE,
MODIFY PayDate DATE,
MODIFY PurchasePrice DECIMAL(10,2),
MODIFY Quantity INT,
MODIFY Dollars DECIMAL(12,2),
MODIFY Classification TINYINT;


SHOW WARNINGS;

-- changing type of sales table

ALTER TABLE sales_1
MODIFY InventoryId VARCHAR(30),
MODIFY Store INT,
MODIFY Brand INT,
MODIFY Description VARCHAR(255),
MODIFY Size VARCHAR(20),
MODIFY SalesQuantity INT,
MODIFY SalesDollars DECIMAL(12,2),
MODIFY SalesPrice DECIMAL(10,2),
MODIFY SalesDate DATE,
MODIFY Volume INT,
MODIFY Classification TINYINT,
MODIFY ExciseTax DECIMAL(10,2),
MODIFY VendorNo INT,
MODIFY VendorName VARCHAR(255);

SHOW WARNINGS;



-- change the data type of vendor_invoice table

ALTER TABLE vendor_invoice
MODIFY VendorNumber INT,
MODIFY VendorName VARCHAR(255),
MODIFY InvoiceDate DATE,
MODIFY PONumber INT,
MODIFY PODate DATE,
MODIFY PayDate DATE,
MODIFY Quantity INT,
MODIFY Dollars DECIMAL(12,2),
MODIFY Freight DECIMAL(10,2),
MODIFY Approval VARCHAR(50);

SHOW WARNINGS;

-- Data type of all the tables was changed


WITH PurchaseSummary AS (
    SELECT
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Description,
        SUM(p.Quantity) AS TotalPurchaseQuantity,
        SUM(p.Dollars) AS TotalPurchaseDollars,
        SUM(vi.Freight) AS TotalFreightCost
    FROM purchases p
    LEFT JOIN vendor_invoice vi
        ON p.VendorNumber = vi.VendorNumber
        AND p.PONumber = vi.PONumber
    GROUP BY
        p.VendorNumber, p.VendorName, p.Brand, p.Description
)
SELECT * FROM PurchaseSummary LIMIT 20;

WITH SalesSummary AS (
    SELECT
        s.VendorNo,
        s.VendorName,
        s.Brand,
        s.Description,
        SUM(s.SalesQuantity) AS TotalSalesQuantity,
        SUM(s.SalesDollars) AS TotalSalesDollars,
        SUM(s.ExciseTax) AS TotalExciseTax
    FROM sales_1 s
    GROUP BY
        s.VendorNo, s.VendorName, s.Brand, s.Description
)
SELECT * FROM SalesSummary LIMIT 20;

-- made correction in my school server that query takes more time to run
-- DBMS connection read timeout in seconds"
-- Change it from 30 to something like 300
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;


WITH PurchaseSummary AS (
    SELECT
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Description,
        SUM(p.Quantity) AS TotalPurchaseQuantity,
        SUM(p.Dollars) AS TotalPurchaseDollars,
        SUM(vi.Freight) AS TotalFreightCost
    FROM purchases p
    LEFT JOIN vendor_invoice vi
        ON p.VendorNumber = vi.VendorNumber
        AND p.PONumber = vi.PONumber
    GROUP BY
        p.VendorNumber, p.VendorName, p.Brand, p.Description
),

SalesSummary AS (
    SELECT
        s.VendorNo,
        s.VendorName,
        s.Brand,
        s.Description,
        SUM(s.SalesQuantity) AS TotalSalesQuantity,
        SUM(s.SalesDollars) AS TotalSalesDollars,
        SUM(s.ExciseTax) AS TotalExciseTax
    FROM sales_1 s
    GROUP BY
        s.VendorNo, s.VendorName, s.Brand, s.Description
),

MasterSummary AS (
    -- Side 1: everything from Purchases, matched to Sales where it exists
    SELECT
        ps.VendorNumber,
        ps.VendorName,
        ps.Brand,
        ps.Description,
        ps.TotalPurchaseQuantity,
        ps.TotalPurchaseDollars,
        ps.TotalFreightCost,
        ss.TotalSalesQuantity,
        ss.TotalSalesDollars,
        ss.TotalExciseTax
    FROM PurchaseSummary ps
    LEFT JOIN SalesSummary ss
        ON ps.VendorNumber = ss.VendorNo
        AND ps.Brand = ss.Brand

    UNION

    -- Side 2: everything from Sales, matched to Purchases where it exists
    -- (catches vendor-brands that sold but have no purchase record)
    SELECT
        ss.VendorNo AS VendorNumber,
        ss.VendorName,
        ss.Brand,
        ss.Description,
        ps.TotalPurchaseQuantity,
        ps.TotalPurchaseDollars,
        ps.TotalFreightCost,
        ss.TotalSalesQuantity,
        ss.TotalSalesDollars,
        ss.TotalExciseTax
    FROM SalesSummary ss
    LEFT JOIN PurchaseSummary ps
        ON ss.VendorNo = ps.VendorNumber
        AND ss.Brand = ps.Brand
)

SELECT * FROM MasterSummary LIMIT 50;





WITH PurchaseSummary AS (
    SELECT
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Description,
        SUM(p.Quantity) AS TotalPurchaseQuantity,
        SUM(p.Dollars) AS TotalPurchaseDollars,
        SUM(vi.Freight) AS TotalFreightCost
    FROM purchases p
    LEFT JOIN vendor_invoice vi
        ON p.VendorNumber = vi.VendorNumber
        AND p.PONumber = vi.PONumber
    GROUP BY
        p.VendorNumber, p.VendorName, p.Brand, p.Description
),

SalesSummary AS (
    SELECT
        s.VendorNo,
        s.VendorName,
        s.Brand,
        s.Description,
        SUM(s.SalesQuantity) AS TotalSalesQuantity,
        SUM(s.SalesDollars) AS TotalSalesDollars,
        SUM(s.ExciseTax) AS TotalExciseTax
    FROM sales_1 s
    GROUP BY
        s.VendorNo, s.VendorName, s.Brand, s.Description
),

MasterSummary AS (
    SELECT
        ps.VendorNumber, ps.VendorName, ps.Brand, ps.Description,
        ps.TotalPurchaseQuantity, ps.TotalPurchaseDollars, ps.TotalFreightCost,
        ss.TotalSalesQuantity, ss.TotalSalesDollars, ss.TotalExciseTax
    FROM PurchaseSummary ps
    LEFT JOIN SalesSummary ss
        ON ps.VendorNumber = ss.VendorNo AND ps.Brand = ss.Brand

    UNION

    SELECT
        ss.VendorNo, ss.VendorName, ss.Brand, ss.Description,
        ps.TotalPurchaseQuantity, ps.TotalPurchaseDollars, ps.TotalFreightCost,
        ss.TotalSalesQuantity, ss.TotalSalesDollars, ss.TotalExciseTax
    FROM SalesSummary ss
    LEFT JOIN PurchaseSummary ps
        ON ss.VendorNo = ps.VendorNumber AND ss.Brand = ps.Brand
)

SELECT
    VendorNumber,
    VendorName,
    Brand,
    Description,
    COALESCE(TotalPurchaseQuantity, 0) AS TotalPurchaseQuantity,
    COALESCE(TotalPurchaseDollars, 0)  AS TotalPurchaseDollars,
    COALESCE(TotalFreightCost, 0)      AS TotalFreightCost,
    COALESCE(TotalSalesQuantity, 0)    AS TotalSalesQuantity,
    COALESCE(TotalSalesDollars, 0)     AS TotalSalesDollars,
    COALESCE(TotalExciseTax, 0)        AS TotalExciseTax,

    -- Gross Profit: what you earned minus what you paid for it
    (COALESCE(TotalSalesDollars,0) - COALESCE(TotalPurchaseDollars,0)) AS GrossProfit,

    -- Gross Margin %: profit as a % of revenue — this is THE metric for "underperforming brands" (Goal 1)
    CASE
        WHEN COALESCE(TotalSalesDollars,0) = 0 THEN NULL
        ELSE ROUND(
            (COALESCE(TotalSalesDollars,0) - COALESCE(TotalPurchaseDollars,0))
            / TotalSalesDollars * 100, 2)
    END AS GrossMarginPct,

    -- Sales-to-Purchase ratio: how much of what was bought actually got sold — flags slow movers
    CASE
        WHEN COALESCE(TotalPurchaseQuantity,0) = 0 THEN NULL
        ELSE ROUND(COALESCE(TotalSalesQuantity,0) / TotalPurchaseQuantity, 2)
    END AS SalesToPurchaseRatio

FROM MasterSummary
ORDER BY GrossProfit DESC;










SELECT
    p.VendorNumber,
    p.VendorName,
    p.Brand,
    p.Description,
    p.PONumber,
    p.Quantity AS OrderQuantity,
    p.Dollars AS OrderDollars,
    ROUND(p.Dollars / p.Quantity, 2) AS ActualUnitCost,
    pp.Price AS ListPrice,
    ROUND(pp.Price - (p.Dollars / p.Quantity), 2) AS SavingsPerUnit,

    -- Bucket orders into size tiers so we can compare cost behavior across order sizes
    CASE
        WHEN p.Quantity <= 10 THEN 'Small (1-10)'
        WHEN p.Quantity <= 50 THEN 'Medium (11-50)'
        WHEN p.Quantity <= 200 THEN 'Large (51-200)'
        ELSE 'Bulk (200+)'
    END AS OrderSizeTier

FROM purchases p
JOIN purchase_prices pp
    ON p.Brand = pp.Brand
WHERE p.Quantity > 0
ORDER BY p.Brand, p.Quantity DESC
LIMIT 100;





SELECT
    OrderSizeTier,
    AVG(ActualUnitCost) AS AvgUnitCost,
    AVG(ListPrice) AS AvgListPrice,
    AVG(SavingsPerUnit) AS AvgSavingsPerUnit,
    COUNT(*) AS NumOrders,
    SUM(OrderQuantity) AS TotalUnitsOrdered
FROM (
    SELECT
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Quantity AS OrderQuantity,
        p.Dollars AS OrderDollars,
        ROUND(p.Dollars / p.Quantity, 2) AS ActualUnitCost,
        pp.Price AS ListPrice,
        ROUND(pp.Price - (p.Dollars / p.Quantity), 2) AS SavingsPerUnit,
        CASE
            WHEN p.Quantity <= 10 THEN 'Small (1-10)'
            WHEN p.Quantity <= 50 THEN 'Medium (11-50)'
            WHEN p.Quantity <= 200 THEN 'Large (51-200)'
            ELSE 'Bulk (200+)'
        END AS OrderSizeTier
    FROM purchases p
    JOIN purchase_prices pp
        ON p.Brand = pp.Brand
    WHERE p.Quantity > 0
) AS RowLevel
GROUP BY OrderSizeTier
ORDER BY AvgUnitCost;



SELECT MIN(SalesDate), MAX(SalesDate) FROM sales_1;



WITH BegInv AS (
    SELECT
        Brand,
        SUM(onHand) AS TotalBeginInventory
    FROM begin_inventory
    GROUP BY Brand
),

EndInv AS (
    SELECT
        Brand,
        SUM(onHand) AS TotalEndInventory
    FROM end_inventory
    GROUP BY Brand
),

SalesByBrand AS (
    SELECT
        Brand,
        SUM(SalesQuantity) AS TotalSalesQuantity
    FROM sales_1
    GROUP BY Brand
)

SELECT
    COALESCE(b.Brand, e.Brand, s.Brand) AS Brand,
    COALESCE(b.TotalBeginInventory, 0) AS TotalBeginInventory,
    COALESCE(e.TotalEndInventory, 0)   AS TotalEndInventory,
    COALESCE(s.TotalSalesQuantity, 0)  AS TotalSalesQuantity,

    -- Average inventory held over the period
    (COALESCE(b.TotalBeginInventory,0) + COALESCE(e.TotalEndInventory,0)) / 2 AS AvgInventory,

    -- Turnover ratio: guard against divide-by-zero when avg inventory is 0
    CASE
        WHEN (COALESCE(b.TotalBeginInventory,0) + COALESCE(e.TotalEndInventory,0)) / 2 = 0 THEN NULL
        ELSE ROUND(
            COALESCE(s.TotalSalesQuantity,0)
            / ((COALESCE(b.TotalBeginInventory,0) + COALESCE(e.TotalEndInventory,0)) / 2)
        , 2)
    END AS InventoryTurnoverRatio

FROM BegInv b
LEFT JOIN EndInv e ON b.Brand = e.Brand
LEFT JOIN SalesByBrand s ON b.Brand = s.Brand
ORDER BY InventoryTurnoverRatio DESC;












CREATE TABLE vendor_performance.final_vendor_summary AS

WITH PurchaseSummary AS (
    SELECT
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Description,
        SUM(p.Quantity) AS TotalPurchaseQuantity,
        SUM(p.Dollars) AS TotalPurchaseDollars,
        SUM(vi.Freight) AS TotalFreightCost
    FROM purchases p
    LEFT JOIN vendor_invoice vi
        ON p.VendorNumber = vi.VendorNumber
        AND p.PONumber = vi.PONumber
    GROUP BY
        p.VendorNumber, p.VendorName, p.Brand, p.Description
),

SalesSummary AS (
    SELECT
        s.VendorNo,
        s.VendorName,
        s.Brand,
        s.Description,
        SUM(s.SalesQuantity) AS TotalSalesQuantity,
        SUM(s.SalesDollars) AS TotalSalesDollars,
        SUM(s.ExciseTax) AS TotalExciseTax
    FROM sales_1 s
    GROUP BY
        s.VendorNo, s.VendorName, s.Brand, s.Description
),

MasterSummary AS (
    SELECT
        ps.VendorNumber, ps.VendorName, ps.Brand, ps.Description,
        ps.TotalPurchaseQuantity, ps.TotalPurchaseDollars, ps.TotalFreightCost,
        ss.TotalSalesQuantity, ss.TotalSalesDollars, ss.TotalExciseTax
    FROM PurchaseSummary ps
    LEFT JOIN SalesSummary ss
        ON ps.VendorNumber = ss.VendorNo AND ps.Brand = ss.Brand

    UNION

    SELECT
        ss.VendorNo, ss.VendorName, ss.Brand, ss.Description,
        ps.TotalPurchaseQuantity, ps.TotalPurchaseDollars, ps.TotalFreightCost,
        ss.TotalSalesQuantity, ss.TotalSalesDollars, ss.TotalExciseTax
    FROM SalesSummary ss
    LEFT JOIN PurchaseSummary ps
        ON ss.VendorNo = ps.VendorNumber AND ss.Brand = ps.Brand
),

BegInv AS (
    SELECT Brand, SUM(onHand) AS TotalBeginInventory
    FROM begin_inventory
    GROUP BY Brand
),

EndInv AS (
    SELECT Brand, SUM(onHand) AS TotalEndInventory
    FROM end_inventory
    GROUP BY Brand
),

Turnover AS (
    SELECT
        b.Brand,
        COALESCE(b.TotalBeginInventory,0) AS TotalBeginInventory,
        COALESCE(e.TotalEndInventory,0)   AS TotalEndInventory,
        (COALESCE(b.TotalBeginInventory,0) + COALESCE(e.TotalEndInventory,0)) / 2 AS AvgInventory
    FROM BegInv b
    LEFT JOIN EndInv e ON b.Brand = e.Brand
)

SELECT
    m.VendorNumber,
    m.VendorName,
    m.Brand,
    m.Description,
    COALESCE(m.TotalPurchaseQuantity, 0) AS TotalPurchaseQuantity,
    COALESCE(m.TotalPurchaseDollars, 0)  AS TotalPurchaseDollars,
    COALESCE(m.TotalFreightCost, 0)      AS TotalFreightCost,
    COALESCE(m.TotalSalesQuantity, 0)    AS TotalSalesQuantity,
    COALESCE(m.TotalSalesDollars, 0)     AS TotalSalesDollars,
    COALESCE(m.TotalExciseTax, 0)        AS TotalExciseTax,

    (COALESCE(m.TotalSalesDollars,0) - COALESCE(m.TotalPurchaseDollars,0)) AS GrossProfit,

    CASE
        WHEN COALESCE(m.TotalSalesDollars,0) = 0 THEN NULL
        ELSE ROUND((COALESCE(m.TotalSalesDollars,0) - COALESCE(m.TotalPurchaseDollars,0))
                    / m.TotalSalesDollars * 100, 2)
    END AS GrossMarginPct,

    CASE
        WHEN COALESCE(m.TotalPurchaseQuantity,0) = 0 THEN NULL
        ELSE ROUND(COALESCE(m.TotalSalesQuantity,0) / m.TotalPurchaseQuantity, 2)
    END AS SalesToPurchaseRatio,

    t.TotalBeginInventory,
    t.TotalEndInventory,
    t.AvgInventory,

    CASE
        WHEN t.AvgInventory = 0 OR t.AvgInventory IS NULL THEN NULL
        ELSE ROUND(COALESCE(m.TotalSalesQuantity,0) / t.AvgInventory, 2)
    END AS InventoryTurnoverRatio

FROM MasterSummary m
LEFT JOIN Turnover t
    ON m.Brand = t.Brand;
    
    
    
    
    
    
    SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN GrossProfit < 0 THEN 1 ELSE 0 END) AS NegativeProfitRows,
    ROUND(SUM(CASE WHEN GrossProfit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS PctNegative
FROM vendor_performance.final_vendor_summary;







SELECT
    ROUND(SUM(CASE WHEN GrossProfit < 0 THEN GrossProfit ELSE 0 END), 2) AS TotalLossAmount,
    ROUND(SUM(CASE WHEN GrossProfit >= 0 THEN GrossProfit ELSE 0 END), 2) AS TotalProfitAmount,
    ROUND(SUM(GrossProfit), 2) AS NetGrossProfit
FROM vendor_performance.final_vendor_summary;




