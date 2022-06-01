---------------ENTER YOUR SQL CODE---------------
WITH Sales_Cust_Join_CTE
AS (
   SELECT fs.OrderDateKey
      ,fs.ProductKey
      ,fs.OrderQuantity * fs.UnitPrice AS TotalSale
      ,dc.FirstName
      ,dc.LastName
   FROM dbo.FactInternetSales fs
   INNER JOIN dbo.DimCustomer dc ON dc.CustomerKey = fs.CustomerKey
   )
   ,Date_CTE
AS (
   SELECT DateKey
      ,CalendarYear
   FROM dbo.DimDate
   )
 , final as (
SELECT CalendarYear
   ,ProductKey
   ,SUM(TotalSale) AS TotalSales
FROM Sales_Cust_Join_CTE
INNER JOIN Date_CTE ON Date_CTE.DateKey = Sales_Cust_Join_CTE.OrderDateKey
GROUP BY CalendarYear
   ,ProductKey
ORDER BY CalendarYear ASC
   ,TotalSales DESC
  )
  
  select * from final