USE AdventureWorks2022;
GO

-- Kollar dem olika scheman som finns och hur många
SELECT DISTINCT TABLE_SCHEMA 
FROM AdventureWorks2022.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE';

SELECT COUNT(DISTINCT TABLE_SCHEMA) AS 'Total Number Of Schemas' 
FROM AdventureWorks2022.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE';


-- Kollar vad för tabeller som finns och hur många som finns
SELECT TABLE_NAME 
FROM AdventureWorks2022.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE';

SELECT COUNT(table_name) AS 'Total Number Of Tables'
FROM AdventureWorks2022.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE';


-- Kollar totala säljvärdet, totala kostnaderna för produktion av alla varor som sålts och totala vinsten
WITH AvgCostPerItem
AS
(
	SELECT ProductID
		, AVG(StandardCost) AS AverageCost
	FROM Production.ProductCostHistory
	GROUP BY ProductID
)

SELECT ROUND(SUM(C.TotalDue), 2) AS TotalSales
	, ROUND(SUM(A.OrderQty * B.AverageCost), 2) AS TotalProductionCost
	, ROUND(70479332.64, 2) as TotalPurchaseCost
	, ROUND((SUM(A.OrderQty * B.AverageCost) + 70479332.64), 2) AS TotalCost
	, ROUND(SUM(C.TotalDue) - (SUM(A.OrderQty * B.AverageCost) + 70479332.64), 2) AS TotalProfit
FROM Sales.SalesOrderDetail AS A
	INNER JOIN AvgCostPerItem AS B
		ON A.ProductID = B.ProductID
	INNER JOIN Sales.SalesOrderHeader AS C
		ON A.SalesOrderID = C.SalesOrderID;

WITH PurchaseOrderTotal
AS
(
		SELECT POH.PurchaseOrderID
			, AVG(POH.TotalDue) AS OrderTotal
		FROM AdventureWorks2022.Purchasing.PurchaseOrderHeader AS POH
			INNER JOIN Purchasing.PurchaseOrderDetail AS POD
				ON POH.PurchaseOrderID = POD.PurchaseOrderID
		GROUP BY POH.PurchaseOrderID
)

SELECT SUM(OrderTotal) AS PurchaseCostTotal
FROM PurchaseOrderTotal;


-- Kollar info om anställda
SELECT EPH.BusinessEntityID
	, CONCAT(P.FirstName, ' ', P.LastName) AS Name
	, E.JobTitle
	, ED.Department
	, E.BirthDate
	, MaritalStatus
	, Gender
	, E.HireDate
	, P.PersonType
	, vE.CountryRegionName AS Country
	, MAX(EPH.Rate) AS Rate
	, MAX(EPH.Rate) * 160 AS MonthlyPay
FROM HumanResources.EmployeePayHistory AS EPH
	INNER JOIN HumanResources.Employee AS E
		ON EPH.BusinessEntityID = E.BusinessEntityID
	INNER JOIN Person.Person AS P
		ON E.BusinessEntityID = P.BusinessEntityID
	INNER JOIN HumanResources.vEmployeeDepartment AS ED
		ON EPH.BusinessEntityID = ED.BusinessEntityID
	INNER JOIN HumanResources.vEmployee AS vE
		ON E.BusinessEntityID = vE.BusinessEntityID
GROUP BY EPH.BusinessEntityID
	, CONCAT(P.FirstName, ' ', P.LastName)
	, E.JobTitle
	, ED.Department
	, E.BirthDate
	, MaritalStatus
	, Gender
	, E.HireDate
	, P.PersonType
	, vE.CountryRegionName
ORDER BY MonthlyPay DESC;


-- Antal anställda per avdelning
SELECT Department
	, COUNT(*) AS EmployeeCount
FROM HumanResources.vEmployeeDepartment
GROUP BY Department


-- Antal anställda
SELECT COUNT(*) AS EmployeeCount
FROM Person.Person
WHERE PersonType IN ('EM', 'SP');


-- Antal anställda per land
SELECT CountryRegionName AS Country
	, COUNT(DISTINCT BusinessEntityID) AS EmployeeCount
FROM HumanResources.vEmployee
GROUP BY CountryRegionName
ORDER BY EmployeeCount DESC;


-- Snittlön
SELECT ROUND(AVG(Rate), 2) AS AveragePay
FROM (
	SELECT BusinessEntityID
		, MAX(Rate) AS Rate
	FROM HumanResources.EmployeePayHistory
	GROUP BY BusinessEntityID
	) AS CurrentRate;


-- Snittlön utan Executive
SELECT ROUND(AVG(Rate), 2) AS AveragePay
FROM (
	SELECT BusinessEntityID
		, MAX(Rate) AS Rate
	FROM HumanResources.EmployeePayHistory
	GROUP BY BusinessEntityID
	HAVING BusinessEntityID NOT IN (1, 234)
	) AS CurrentRate;


-- Antal registrerade kunder
SELECT COUNT(DISTINCT BusinessEntityID) AS RetailCustomerCount
FROM Person.Person
WHERE PersonType = 'IN';


-- Antal kunder per land
SELECT CountryRegionName AS Country
	, COUNT(DISTINCT BusinessEntityID) AS CustomerCount
FROM Sales.vIndividualCustomer
GROUP BY CountryRegionName
ORDER BY CustomerCount DESC;


-- Kollar antal ordrar och försäljning per kvartal
SELECT YEAR(OrderDate) AS Year
	, DATEPART(qq, OrderDate) AS Quarter
	, CONCAT(YEAR(OrderDate), ' Q', DATEPART(qq, OrderDate)) AS YearQuarter
	, COUNT(SalesOrderID) AS NumberOfOrders
	, (COUNT(SalesOrderID) - LAG(COUNT(SalesOrderID)) OVER (ORDER BY CONCAT(YEAR(OrderDate), 'Q', DATEPART(qq, OrderDate))))
		AS OrderDiffPreviousQ
	, ROUND(SUM(TotalDue), 2) AS TotalSales
	, (SUM(TotalDue) - LAG(SUM(TotalDue)) OVER (ORDER BY CONCAT(YEAR(OrderDate), 'Q', DATEPART(qq, OrderDate))))
		AS SalesDiffPreviousQ
	, ROUND(AVG(TotalDue), 2) AS AvgTotal
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), DATEPART(qq, OrderDate)
ORDER BY YEAR(OrderDate), DATEPART(qq, OrderDate);

SELECT COUNT(*)
FROM Sales.SalesOrderHeader

-- Sålt per år
SELECT YEAR(OrderDate) AS Year
	, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY Year;


-- Hur många av varje produkt som sålts och intäckter för varje produkt
SELECT SOD.ProductID
	, P.Name
	, SUM(SOD.OrderQty) as TotQtySold
	, SUM(SOD.OrderQty * UnitPrice) AS SalesExTax
FROM Sales.SalesOrderDetail as SOD
INNER JOIN Production.Product as P
	ON SOD.ProductID = P.ProductID
GROUP BY SOD.ProductID, P.Name
ORDER BY TotQtySold DESC;


-- Vilka produkter som sålts mest per kvartal
SELECT YEAR(OrderDate) AS Year
	, DATEPART(qq, OrderDate) AS Quarter
	, CONCAT(YEAR(OrderDate), ' Q', DATEPART(qq, OrderDate)) AS YearQuarter
	, P.Name
	, MAX(SOD.OrderQty) AS OrderQty
FROM Sales.SalesOrderHeader AS SOH
	INNER JOIN Sales.SalesOrderDetail AS SOD
		ON SOH.SalesOrderID = SOD.SalesOrderID
	INNER JOIN Production.Product as P
		ON SOD.ProductID = P.ProductID
GROUP BY YEAR(OrderDate)
		, DATEPART(qq, OrderDate)
		, P.Name
ORDER BY OrderQty DESC;


-- Info om kunder
SELECT vDem.BusinessEntityID
	, vDem.BirthDate
	, vDem.MaritalStatus
	, vDem.YearlyIncome
	, vDem.Gender
	, vDem.TotalChildren
	, vDem.NumberChildrenAtHome AS ChildrenAtHome
	, vDem.Education
	, vDem.Occupation
	, vDem.NumberCarsOwned AS CarsOwned
	, SUM(SOH.TotalDue) AS TotalOrderAmount
	, AVG(SOH.TotalDue) AS AvgOrderTotal
FROM Sales.vPersonDemographics AS vDem
	JOIN Sales.SalesOrderHeader AS SOH
		ON vDem.BusinessEntityID = SOH.CustomerID
GROUP BY vDem.BusinessEntityID
	, vDem.BirthDate
	, vDem.MaritalStatus
	, vDem.YearlyIncome
	, vDem.Gender
	, vDem.TotalChildren
	, vDem.NumberChildrenAtHome
	, vDem.Education
	, vDem.Occupation
	, vDem.NumberCarsOwned;

SELECT A.name as ColumnName, 
	(SCHEMA_NAME(B.schema_id) + '.' + B.name) AS 'TableName'
FROM  sys.columns as A INNER JOIN sys.tables as B
	on A.object_id = B.object_id
WHERE A.name LIKE '%Gender%'
ORDER BY TableName, ColumnName;