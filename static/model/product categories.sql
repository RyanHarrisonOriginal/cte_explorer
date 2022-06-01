
WITH product_cat (CategoryID, CategoryName, NumberOfProducts) AS
(
   SELECT
      CategoryID,
      CategoryName,
      (SELECT COUNT(1) FROM Products p
       WHERE p.CategoryID = c.CategoryID) as NumberOfProducts
   FROM Categories c
),
product_over10 (ProductID, CategoryID, ProductName, UnitPrice) AS
(
   SELECT
      ProductID,
      CategoryID,
      ProductName,
      UnitPrice
   FROM Products p
   WHERE UnitPrice > 10.0
)
, final as (
SELECT c.CategoryName, c.NumberOfProducts,
      p.ProductName, p.UnitPrice
FROM product_over10 p
   INNER JOIN product_cat c ON
      p.CategoryID = c.CategoryID
ORDER BY ProductName
)
select * from final