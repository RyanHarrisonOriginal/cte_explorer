---------------ENTER YOUR SQL CODE---------------
WITH sales_customer AS (
   SELECT 
        fs.OrderDateKey
        ,fs.ProductKey
        ,fs.OrderQuantity * fs.UnitPrice AS TotalSale
        ,dc.FirstName
        ,dc.LastName
   FROM dbo.fct_internet_sales fs
   INNER JOIN dbo.DimCustomer dc ON dc.CustomerKey = fs.CustomerKey
 )
 , cal_date AS (
    SELECT 
        DateKey
        ,CalendarYear
   FROM dbo.DimDate
   )
, final as (
    SELECT CalendarYear
        ,ProductKey
        ,SUM(TotalSale) AS TotalSales
    FROM sales_customer
    INNER JOIN cal_date ON cal_date.DateKey = sales_customer.OrderDateKey
    GROUP BY CalendarYear,ProductKey
    ORDER BY CalendarYear ASC,TotalSales DESC
 )
  
  select * from final