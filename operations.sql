
CREATE TRIGGER no_drop_tables
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    PRINT 'Dropping tables is not allowed.'
    ROLLBACK;
END;


CREATE TRIGGER no_alter_columns
ON DATABASE
FOR ALTER_TABLE
AS
BEGIN
    PRINT 'Adding or deleting columns is not allowed.'
    ROLLBACK;
END;












----view products-------
CREATE VIEW vwproducts
AS
SELECT p.productID, p.productName, pd.colorID, pd.sizeID, pd.unitInStokes, p.unitPriceSALE, p.discontinued
FROM [ProductDetails] AS pd
INNER JOIN Products AS p
ON pd.ProductID = p.ProductID

select * from vwproducts
----view orders-------
CREATE VIEW vworders
AS
SELECT o.orderID, o.customerID, od.productID, od.sizeID, od.unitPrice, od.quantity, od.discount,o.orderDate
FROM OrderDetails AS od
INNER JOIN Orders AS o
ON od.OrderID = o.OrderID
select * from vworders
----view Customer-------
CREATE VIEW vwcustomer
AS
select customerID,contactName,companyName,phone
from Customers
select * from vwcustomer


--procedures
alter PROCEDURE loginProcedure
(
    @username varchar(255),
    @password varchar(255),
    @result bit OUTPUT
    
)
AS
BEGIN
    DECLARE @salt varchar(255), @hashedPassword VARBINARY(MAX), @storedPassword varchar(25);

    -- Get the salt, hashed password, and position for the entered username
    SELECT @salt = phone, @storedPassword = userPassword
    FROM Employees
    WHERE Username = @username

    -- Hash the entered password using the salt
    SET @hashedPassword = HASHBYTES('SHA2_256',  @password+@salt)

    -- Compare the hashed password to the stored password
    IF @hashedPassword = @storedPassword
    BEGIN
        SET @result = 1
		
		
    END
    ELSE
    BEGIN
        SET @result = 0
        
    END
END




select * from Employees







--trigger for changing the price of any product;

CREATE TRIGGER Price_changed ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;   --it is removing the rows affected message

    -- Check if the unitPriceSale or unitPriceBuy columns have been updated
    IF (EXISTS (SELECT unitPriceSale FROM INSERTED) AND EXISTS (SELECT unitPriceSale FROM DELETED)) OR
       (EXISTS (SELECT unitPriceBuy FROM INSERTED) AND EXISTS (SELECT unitPriceBuy FROM DELETED))
    BEGIN
        -- Check if the unitPriceSale or unitPriceBuy columns have been changed
        IF (SELECT unitPriceSale FROM INSERTED) <> (SELECT unitPriceSale FROM DELETED) OR
           (SELECT unitPriceBuy FROM INSERTED) <> (SELECT unitPriceBuy FROM DELETED)
        BEGIN
            INSERT INTO PriceHistory(productID, endDate, changedBy, newUnitPriceSale, newUnitPriceBuy)
            SELECT productID, GETDATE(), SUSER_SNAME(), unitPriceSale, unitPriceBuy
            FROM inserted;
        END
    END
END;

select * from Products where productID = 5;


--trigger for updating unit in stokes when new record is added in OrderDetails


CREATE TRIGGER update_unitInStokes
ON OrderDetails
AFTER INSERT
AS
BEGIN
    UPDATE ProductDetails
    SET unitInStokes = unitInStokes - i.quantity
    FROM ProductDetails pd
    INNER JOIN inserted i
        ON pd.productID = i.productID
        AND pd.colorID = i.colorID
        AND pd.sizeID = i.sizeID;
END;


--trigger for returned orders that will update the stokes of the returned product
CREATE TRIGGER update_unitInStokes_returned
ON ReturnOrder
AFTER INSERT
AS
BEGIN
    UPDATE ProductDetails
    SET unitInStokes = unitInStokes + i.quantityReturned
    FROM ProductDetails pd
    INNER JOIN inserted i
        ON pd.productID = i.productID
        AND pd.colorID = i.colorID
        AND pd.sizeID = i.sizeID;
END;




--for inserting in return orders
CREATE PROCEDURE AddReturnOrderDetail
    @orderID INT,
    @productID INT,
    @sizeID INT,
    @colorID INT,
    @quantity INT,
    @result INT OUTPUT
AS
BEGIN
    DECLARE @currentQuantity INT

    -- Check if the record already exists in OrderDetails
    SELECT @currentQuantity = quantity
    FROM OrderDetails
    WHERE orderID = @orderID
    AND productID = @productID
    AND sizeID = @sizeID
    AND colorID = @colorID

    -- If the record does not exist or the input quantity is greater than the current quantity, set the result to 0
    IF @currentQuantity IS NULL OR @quantity > @currentQuantity
    BEGIN
        SET @result = 0
    END
    -- If the record exists and the input quantity is less than or equal to the current quantity, insert a new record in the ReturnOrder table and set the result to 1
    ELSE
    BEGIN
        INSERT INTO ReturnOrder 
        VALUES (@orderID, @productID, @colorID, @sizeID, @quantity, GETDATE())

        SET @result = 1
    END
END;




--for updating the return order details
CREATE PROCEDURE UpdateReturnOrderDetail
    @orderID INT,
    @productID INT,
    @sizeID INT,
    @colorID INT,
    @quantity INT,
    @result INT OUTPUT
AS
BEGIN
    DECLARE @currentQuantity INT

    -- Check if the record already exists in OrderDetails
    SELECT @currentQuantity = quantity
    FROM OrderDetails
    WHERE orderID = @orderID
    AND productID = @productID
    AND sizeID = @sizeID
    AND colorID = @colorID

    -- If the record does not exist or the input quantity is greater than the current quantity, set the result to 0
    IF @currentQuantity IS NULL OR @quantity > @currentQuantity
    BEGIN
        SET @result = 0
    END
    -- If the record exists and the input quantity is less than or equal to the current quantity, update the record in the ReturnOrder table and set the result to 1
    ELSE
    BEGIN
        UPDATE ReturnOrder
        SET quantityReturned = @quantity, returnedDate = GETDATE()
        WHERE orderID = @orderID
        AND productID = @productID
        AND colorID = @colorID
        AND sizeID = @sizeID

        SET @result = 1
    END
END;







--for reports


--for profit
alter FUNCTION getProfitByProduct()
RETURNS TABLE
AS
    RETURN 
    (
        SELECT p.productName,
               SUM(od.quantity * (od.unitPrice - p.unitPriceBuy)* ((100-od.discount)/100))-
                SUM(CASE WHEN ro.quantityReturned>0 THEN ((od.unitPrice - p.unitPriceBuy) * ro.quantityReturned *((100-od.discount)/100)) ELSE 0 END) AS Total_profit
			
        FROM Products p
        INNER JOIN OrderDetails od ON p.productID = od.productID
        LEFT JOIN ReturnOrder ro ON od.orderID = ro.orderID AND od.productID = ro.productID and ro.colorID = od.colorID and ro.sizeID = od.sizeID
        GROUP BY p.productName
    );

	


	select * from getProfitByProduct()
	order by Total_profit desc;

	
	--testing for this function
	insert into ReturnOrder
	values(1,5,1200,11100,25, GETDATE());
	SELECT * FROM ReturnOrder;


	


	SELECT * FROM Products WHERE productID = 5;

	select * from ProductDetails
	where productID = 5;

	select * from OrderDetails where productID = 5;

	--TESTING ENDED HERE



	--profit from single product

	
ALTER FUNCTION getProfitBySingleProduct(@id INT)
RETURNS TABLE
AS
    RETURN 
    (
        SELECT p.productName, SUM(od.quantity * (od.unitPrice - p.unitPriceBuy) *((100-od.discount)/100))-
		SUM(CASE WHEN ro.quantityReturned>0 THEN ((od.unitPrice - p.unitPriceBuy) * ro.quantityReturned*((100-od.discount)/100)) ELSE 0 END)
		AS totalProfit
        FROM Products p
        INNER JOIN OrderDetails od ON p.productID = od.productID
		 LEFT JOIN ReturnOrder ro ON od.orderID = ro.orderID AND od.productID = ro.productID and ro.colorID = od.colorID and ro.sizeID = od.sizeID
        where p.productID = @id
		group by p.productName
    );

	

	SELECT * FROM getProfitBySingleProduct(5);

	alter FUNCTION getMonthlyProfit(@year INT)
RETURNS TABLE
AS
    RETURN 
    (
        SELECT MONTH(o.orderDate) AS month, SUM(od.quantity * (od.unitPrice - p.unitPriceBuy) - ((100-od.discount)/100))-
		SUM(CASE WHEN ro.quantityReturned>0 THEN ((od.unitPrice - p.unitPriceBuy) * ro.quantityReturned *((100-od.discount)/100) ) ELSE 0 END)
		AS totalProfit
        FROM Orders o
        INNER JOIN OrderDetails od ON o.orderID = od.orderID
		inner join Products p on p.productID = od.productID
		LEFT JOIN ReturnOrder ro ON od.orderID = ro.orderID AND od.productID = ro.productID and ro.colorID = od.colorID and ro.sizeID = od.sizeID
        WHERE YEAR(o.orderDate) = @year
        GROUP BY MONTH(o.orderDate)
    );


	select month,totalProfit from getMonthlyProfit(2022)
	order by month asc;



	---yearly profits
	alter FUNCTION getProfitByYear()
RETURNS TABLE
AS
    RETURN 
    (
        SELECT YEAR(o.orderDate) AS year, 
               SUM(od.quantity * (od.unitPrice - p.unitPriceBuy) * ((100-od.discount)/100))
               - SUM(CASE WHEN ro.quantityReturned>0 THEN ((od.unitPrice - p.unitPriceBuy) * ro.quantityReturned  *((100-od.discount)/100) ) ELSE 0 END) AS totalProfit
        FROM Orders o
        INNER JOIN OrderDetails od ON o.orderID = od.orderID
        INNER JOIN Products p ON od.productID = p.productID
        LEFT JOIN ReturnOrder ro ON od.orderID = ro.orderID AND od.productID = ro.productID AND od.colorID = ro.colorID AND od.sizeID = ro.sizeID
        GROUP BY YEAR(o.orderDate)
    );

	select * from getProfitByYear();






alter function getTotalProfit()
returns table
as 
return (
		select sum(Total_profit)as Total_Profit
		from getProfitByProduct() 

		

);

select * from getTotalProfit();













--sales reports


CREATE FUNCTION getTotalSales(@month INT, @year INT)
RETURNS TABLE
AS
RETURN
    
   
    SELECT SUM(od.quantity * od.unitPrice * ((100 - od.discount)/100)) AS TOTAL_SALES
    FROM OrderDetails od
    JOIN Orders o ON od.orderID = o.orderID
    WHERE MONTH(o.orderDate) = @month AND YEAR(o.orderDate) = @year;
    






	SELECT * FROM getTotalSales(2,2022);




--sales of all products based on quantity
create function getTotalSalesAllProducts()
returns table
as
RETURN 
    (
        SELECT p.productName, SUM(od.quantity * od.unitPrice) AS totalSales
        FROM Products p
        INNER JOIN OrderDetails od ON p.productID = od.productID
        GROUP BY p.productName
		
		
    );
	
	SELECT * FROM getTotalSalesAllProducts()
	ORDER BY totalSales desc;


	--sales for specific time range
	CREATE FUNCTION getTotalSalesBetweenDates(@startDate DATE, @endDate DATE)
RETURNS TABLE
AS
RETURN 
    (
        SELECT p.productName, SUM(od.quantity * od.unitPrice) AS totalSales
        FROM Products p
        INNER JOIN OrderDetails od ON p.productID = od.productID
        INNER JOIN Orders o ON od.orderID = o.orderID
        WHERE o.orderDate BETWEEN @startDate AND @endDate
        GROUP BY p.productName
    );




	SELECT * FROM getTotalSalesBetweenDates('2022-09-01', '2022-12-31');

	

	CREATE FUNCTION getTotalSalesForProduct(@productID INT)
RETURNS NUMERIC(18, 2)
AS
BEGIN
    DECLARE @totalSales NUMERIC(18, 2) = 0

    SELECT @totalSales = SUM(od.quantity * od.unitPrice)
    FROM OrderDetails od
    WHERE od.productID = @productID

    RETURN @totalSales
END;

select dbo.getTotalSalesForProduct(5) as [Total Sale];







	--reports for customers

CREATE FUNCTION getCustomersByNumberOfOrders()
RETURNS TABLE
AS
RETURN
    (
        SELECT c.customerID, c.contactName, COUNT(o.orderID) AS numberOfOrders
        FROM Customers c
        LEFT JOIN Orders o ON c.customerID = o.customerID
        GROUP BY c.customerID, c.contactName
        
    );


	select * from getCustomersByNumberOfOrders();


	--report for single customer
	alter function getSingleCustomer(@id INT)
	RETURNS TABLE
	AS	
		RETURN(
			select  
			c.customerID, c.contactName,c.city, c.customer_address,c.phone, sum(o.orderID) as Total_orders_placed
			
			from Customers c
			LEFT JOIN Orders o on c.customerID = o.customerID
			where @id = c.customerID
			GROUP BY c.customerID, c.contactName,c.contactName, c.customer_address,c.city, c.customer_address,c.phone, o.orderID
			
		
		
		);

		
		select * from getSingleCustomer(1);


		--for employees

		-- ordered by total numbers of orders they have handled
		CREATE FUNCTION getEmployeeCustomerCount()
			RETURNS TABLE
			AS
			RETURN
				SELECT e.employeeID, e.firstName + ' ' + e.lastName AS employeeName, COUNT(o.customerID) AS customerCount
				FROM Employees e
				LEFT JOIN Orders o ON e.employeeID = o.employeeID
				GROUP BY e.employeeID, e.firstName, e.lastName;


			--testing 
			select * from getEmployeeCustomerCount();


		-- returns the information of any employee
		CREATE FUNCTION getEmployeeInfo(@id INT)
			RETURNS TABLE
			AS
			RETURN
				SELECT * FROM Employees WHERE employeeID = @id;


				--testing
				SELECT * FROM getEmployeeInfo(1);



				


	--revenue report
	CREATE FUNCTION getMonthlyExpenses(@year INT)
RETURNS TABLE
AS

    RETURN
    (
        SELECT MONTH(e.expenseDate) AS month, SUM(e.amount) AS expenses
        FROM Expenses e
        WHERE YEAR(e.expenseDate) = @year
        GROUP BY MONTH(e.expenseDate)
    );



	select * from getMonthlyExpenses(2022);
	select * from Employ





select * from getRevenue(2022);