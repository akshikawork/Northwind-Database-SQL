-- Q1: Find the top 3 customers with the highest average order value (> $500) along with their rank.
WITH CustomerOrderValues AS (
    SELECT O.CustomerID,
           AVG(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS AvgOrderValue
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY O.CustomerID
    HAVING AVG(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) > 500
)
SELECT CustomerID, AvgOrderValue,
       RANK() OVER (ORDER BY AvgOrderValue DESC) AS CustomerRank
FROM CustomerOrderValues;

-- Q2: List employees who handled orders with both “High” (> $1000) and “Low” (< $100) total values.
WITH OrderTotals AS (
    SELECT O.EmployeeID, O.OrderID,
           SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalValue
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY O.EmployeeID, O.OrderID
)
SELECT EmployeeID
FROM OrderTotals
GROUP BY EmployeeID
HAVING SUM(CASE WHEN TotalValue > 1000 THEN 1 ELSE 0 END) > 0
   AND SUM(CASE WHEN TotalValue < 100 THEN 1 ELSE 0 END) > 0;

-- Q3: For each category, find the product with the highest and second-highest total revenue.
WITH RevenueRanked AS (
    SELECT P.CategoryID, P.ProductName,
           SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalRevenue,
           RANK() OVER (PARTITION BY P.CategoryID ORDER BY SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) DESC) AS RevenueRank
    FROM Products P
    JOIN [Order Details] OD ON P.ProductID = OD.ProductID
    GROUP BY P.CategoryID, P.ProductName
)
SELECT CategoryID, ProductName, TotalRevenue, RevenueRank
FROM RevenueRanked
WHERE RevenueRank IN (1, 2);

-- Q4: Find customers whose orders always contained a discount higher than 10%.
SELECT O.CustomerID
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY O.CustomerID
HAVING MIN(OD.Discount) > 0.10;

-- Q5: List the top 2 employees by number of orders shipped to the USA in 1997.
SELECT TOP 2 EmployeeID, COUNT(OrderID) AS USAOrders
FROM Orders
WHERE ShipCountry = 'USA' AND YEAR(OrderDate) = 1997
GROUP BY EmployeeID
ORDER BY USAOrders DESC;

-- Q6: Show each customer with total number of products ordered and categorize them as 'Big Buyer' or 'Regular'.
SELECT O.CustomerID, SUM(OD.Quantity) AS TotalProducts,
       CASE WHEN SUM(OD.Quantity) > 100 THEN 'Big Buyer'
            ELSE 'Regular'
       END AS BuyerType
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY O.CustomerID;

-- Q7: Find the 5 most expensive products never ordered by any customer from France.
SELECT TOP 5 P.ProductID, P.ProductName, P.UnitPrice
FROM Products P
WHERE P.ProductID NOT IN (
    SELECT DISTINCT OD.ProductID
    FROM [Order Details] OD
    JOIN Orders O ON OD.OrderID = O.OrderID
    JOIN Customers C ON O.CustomerID = C.CustomerID
    WHERE C.Country = 'France'
)
ORDER BY P.UnitPrice DESC;

-- Q8: For each order, calculate its rank based on total value per employee.
WITH OrderValue AS (
    SELECT O.EmployeeID, O.OrderID,
           SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalValue
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY O.EmployeeID, O.OrderID
)
SELECT EmployeeID, OrderID, TotalValue,
       RANK() OVER (PARTITION BY EmployeeID ORDER BY TotalValue DESC) AS OrderRank
FROM OrderValue;

-- Q9: Identify products with unit price higher than average price of their category.
WITH CategoryAvg AS (
    SELECT CategoryID, AVG(UnitPrice) AS AvgPrice
    FROM Products
    GROUP BY CategoryID
)
SELECT P.ProductID, P.ProductName, P.UnitPrice, C.AvgPrice
FROM Products P
JOIN CategoryAvg C ON P.CategoryID = C.CategoryID
WHERE P.UnitPrice > C.AvgPrice;

-- Q10: Find last 3 orders per customer and calculate total order value.
WITH CustomerOrders AS (
    SELECT O.CustomerID, O.OrderID, O.OrderDate,
           SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalValue,
           ROW_NUMBER() OVER (PARTITION BY O.CustomerID ORDER BY O.OrderDate DESC) AS RowNum
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY O.CustomerID, O.OrderID, O.OrderDate
)
SELECT CustomerID, OrderID, TotalValue
FROM CustomerOrders
WHERE RowNum <= 3;

-- Q11: List the top 3 categories by total revenue.
SELECT TOP 3 P.CategoryID, SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS CategoryRevenue
FROM Products P
JOIN [Order Details] OD ON P.ProductID = OD.ProductID
GROUP BY P.CategoryID
ORDER BY CategoryRevenue DESC;

-- Q12: Find customers who have ordered products from all categories.
SELECT CustomerID
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY CustomerID
HAVING COUNT(DISTINCT P.CategoryID) = (SELECT COUNT(*) FROM Categories);

-- Q13: Find employees who never handled orders to Germany.
SELECT EmployeeID
FROM Orders
WHERE EmployeeID NOT IN (
    SELECT DISTINCT EmployeeID
    FROM Orders
    WHERE ShipCountry = 'Germany'
);

-- Q14: Calculate total revenue per year per employee.
SELECT EmployeeID, YEAR(OrderDate) AS OrderYear, 
       SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalRevenue
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY EmployeeID, YEAR(OrderDate);

-- Q15: Find products that contributed more than 20% of total revenue in their category.
WITH CategoryRevenue AS (
    SELECT P.CategoryID, SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalCategoryRevenue
    FROM Products P
    JOIN [Order Details] OD ON P.ProductID = OD.ProductID
    GROUP BY P.CategoryID
)
SELECT P.ProductID, P.ProductName, SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS ProductRevenue
FROM Products P
JOIN [Order Details] OD ON P.ProductID = OD.ProductID
JOIN CategoryRevenue CR ON P.CategoryID = CR.CategoryID
GROUP BY P.ProductID, P.ProductName, CR.TotalCategoryRevenue
HAVING SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) > 0.2 * CR.TotalCategoryRevenue;

-- Q16: Find customers whose total purchase is above average of all customers.
WITH CustomerTotal AS (
    SELECT O.CustomerID, SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalSpent
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY O.CustomerID
),
AvgTotal AS (
    SELECT AVG(TotalSpent) AS AvgSpent FROM CustomerTotal
)
SELECT CustomerID, TotalSpent
FROM CustomerTotal, AvgTotal
WHERE TotalSpent > AvgSpent;

-- Q17: Rank orders by total value globally.
SELECT OrderID, SUM(UnitPrice * Quantity * (1 - Discount)) AS OrderValue,
       RANK() OVER (ORDER BY SUM(UnitPrice * Quantity * (1 - Discount)) DESC) AS GlobalRank
FROM [Order Details]
GROUP BY OrderID;

-- Q18: Find products never ordered by top 5 customers by revenue.
WITH TopCustomers AS (
    SELECT CustomerID
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    GROUP BY CustomerID
    ORDER BY SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) DESC
    FETCH FIRST 5 ROWS ONLY
)
SELECT ProductID, ProductName
FROM Products
WHERE ProductID NOT IN (
    SELECT DISTINCT OD.ProductID
    FROM Orders O
    JOIN [Order Details] OD ON O.OrderID = OD.OrderID
    WHERE O.CustomerID IN (SELECT CustomerID FROM TopCustomers)
);

-- Q19: Show employees with the average order value they handle above 500.
SELECT EmployeeID, AVG(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS AvgOrderValue
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY EmployeeID
HAVING AVG(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) > 500;

-- Q20: Find categories with more than 10 products and average unit price above 50.
SELECT CategoryID, COUNT(ProductID) AS ProductCount, AVG(UnitPrice) AS AvgPrice
FROM Products
GROUP BY CategoryID
HAVING COUNT(ProductID) > 10 AND AVG(UnitPrice) > 50;

-- Q21: List customers who ordered the same product more than 5 times in a single order.
SELECT O.CustomerID, OD.ProductID, COUNT(*) AS ProductCount
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY O.CustomerID, OD.ProductID, O.OrderID
HAVING COUNT(*) > 5;

-- Q22: Find the top 3 employees by total revenue generated from their orders.
SELECT TOP 3 O.EmployeeID, SUM(OD.UnitPrice * OD.Quantity * (1 - OD.Discount)) AS TotalRevenue
FROM Orders O
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY O.EmployeeID
ORDER BY TotalRevenue DESC;

-- Q23: List products that generated revenue above the average revenue of all products.
WITH ProductRevenue AS (
    SELECT ProductID, SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue
    FROM [Order Details]
    GROUP BY ProductID
),
AvgRevenue AS (
    SELECT AVG(TotalRevenue) AS AvgRevenue FROM ProductRevenue
)
SELECT ProductID, TotalRevenue
FROM ProductRevenue, AvgRevenue
WHERE TotalRevenue > AvgRevenue;

-- Q24: Find orders where all products have a discount above 10%.
SELECT OrderID
FROM [Order Details]
GROUP BY OrderID
HAVING MIN(Discount) > 0.10;

-- Q25: Find the second most expensive product in each category.
WITH ProductRank AS (
    SELECT ProductID, ProductName, CategoryID, UnitPrice,
           ROW_NUMBER() OVER (PARTITION BY CategoryID ORDER BY UnitPrice DESC) AS RowNum
    FROM Products
)
SELECT ProductID, ProductName, CategoryID, UnitPrice
FROM ProductRank
WHERE RowNum = 2;