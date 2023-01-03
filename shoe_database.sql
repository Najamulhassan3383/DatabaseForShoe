--creating database for shoe store


CREATE DATABASE ShoeStore2;
USE ShoeStore2;

CREATE TABLE Categories (
    catagoryID INT not null,
    catagoryName VARCHAR(30) not null
	constraint PK_Category primary key (catagoryID)
);
GO
 CREATE  INDEX "CategoryName" ON "dbo"."Categories"("CatagoryName")

CREATE TABLE Suppliers (
    supplierID INT ,
    CompanyName VARCHAR(40) NOT NULL,
	supplierAddress VARCHAR(255) NOT NULL,
    city VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    phone VARCHAR(22),
	constraint PK_Supplier primary key (supplierID)
);

CREATE TABLE Products (
    productID INT,
    productName VARCHAR(30) NOT NULL,
    supplierID INT NOT NULL,
    catagoryID INT NOT NULL,
    unitPriceBuy NUMERIC NOT NULL,
	unitPriceSALE NUMERIC NOT NULL,
    discontinued INT NOT NULL default 1,
	constraint PK_Product primary key (productID),
    constraint FK_Product_Supplier FOREIGN KEY (supplierID) REFERENCES Suppliers(supplierID),
    constraint FK_Product_Category FOREIGN KEY (catagoryID) REFERENCES Categories(catagoryID),
	constraint CHK_Price check (unitPriceBuy >= 0 and unitPriceSale >= 0)
);
GO
 CREATE  INDEX "CategoriesProducts" ON "dbo"."Products"("CatagoryID")
GO
 CREATE  INDEX "CategoryID" ON "dbo"."Products"("CatagoryID")
GO
 CREATE  INDEX "ProductName" ON "dbo"."Products"("ProductName")
GO
 CREATE  INDEX "SupplierID" ON "dbo"."Products"("SupplierID")
GO
 CREATE  INDEX "SuppliersProducts" ON "dbo"."Products"("SupplierID")

CREATE TABLE Colors (
    colorID INT,
    colorName VARCHAR(30) NOT NULL,
	constraint PK_Color primary key (colorID),
	constraint PK_color_id check (colorID >=0)
);

CREATE TABLE Sizes (
    sizeID INT,
    sizeName VARCHAR(30) NOT NULL,
	constraint PK_Size primary key (sizeID)
);

CREATE TABLE ProductDetails (   
    productID INT NOT NULL,
    colorID INT NOT NULL,
    sizeID INT NOT NULL,
	unitInStokes INT NOT NULL default 0,
	constraint PK_Product_Detail PRIMARY KEY(productID,colorID,sizeID),
    constraint FK_Product_Detail FOREIGN KEY (productID) REFERENCES Products(productID),
    constraint FK_Color_Detail FOREIGN KEY (colorID) REFERENCES Colors(colorID) ,
    constraint FK_Size_Detail FOREIGN KEY (sizeID) REFERENCES Sizes(sizeID),
	constraint CHK_Stock check (unitInStokes >= 0),

);



CREATE TABLE Customers (
    customerID INT not null,
	contactName varchar(50) not null,
    companyName VARCHAR(40) NOT NULL,   
    customer_address varchar(255) not null,
    city VARCHAR(30) NOT NULL,
    phone VARCHAR(24) NOT NULL,
    constraint PK_Customer primary key (customerID),
	constraint customer_id check (customerID >= 0)
);
GO
 CREATE  INDEX "City" ON "dbo"."Customers"("City")


CREATE TABLE Employees (
    employeeID INT,
    firstName VARCHAR(30) NOT NULL,
    lastName VARCHAR(30) NOT NULL,
    gender CHAR(1) NOT NULL,
    dob DATE NOT NULL,
	 employeeAddress varchar(255) NOT NULL,
    city VARCHAR(30),
    
   
    country VARCHAR(30) NOT NULL,
    phone VARCHAR(14) NOT NULL,
    email VARCHAR(50) NOT NULL,
    position VARCHAR(30) NOT NULL,
    salary NUMERIC NOT NULL default 10000,
    hireDate DATE  NOT NULL default getdate(),
	username varchar(255) not null,
	userPassword varbinary(max) not null,
	constraint PK_Employee primary key (employeeID),
	constraint CHK_Salary check (salary >= 0),
	constraint id check(employeeID >0)
);
GO
 CREATE  INDEX "LastName" ON "dbo"."Employees"("LastName")

CREATE TABLE Expenses (
    expenseID INT,
    employeeID INT NOT NULL,
    expenseDate DATE NOT NULL default getdate(),
    expenseType VARCHAR(30) NOT NULL default 'Miscellaneous',
    amount NUMERIC NOT NULL,
    _description VARCHAR(100) NOT NULL,
	constraint PK_Expense primary key (expenseID),
    constraint FK_Employee_Expense FOREIGN KEY (employeeID) REFERENCES Employees(employeeID),
	constraint CHK_Amount check (amount >= 0),
	constraint CHK_ID CHECK (expenseID>0)
);






CREATE TABLE PriceHistory (
    productID INT NOT NULL,
    endDate DATETIME NOT NULL default getdate(),
	changedBy varchar(50) not null,
	
    newUnitPriceSale NUMERIC NOT NULL,
	newUnitPriceBuy NUMERIC NOT NULL,
	constraint PK_Price_History  PRIMARY KEY(productID,endDate),
    constraint FK_Product_Price_History FOREIGN KEY (productID) REFERENCES Products(productID),
	constraint CHK_Updated_Price check (newUnitPriceSale >= 0 and newUnitPriceBuy >= 0)
);

CREATE TABLE Orders (
    orderID INT IDENTITY(1,1) NOT NULL ,
    customerID INT NOT NULL,
    employeeID INT NOT NULL,
    orderDate DATETIME NOT NULL default getdate(),
    constraint PK_Order primary key  (orderID),
    constraint FK_Order_Customer FOREIGN KEY (customerID) REFERENCES Customers(customerID),
    constraint FK_Order_Employee FOREIGN KEY (employeeID) REFERENCES Employees(employeeID)
);
 CREATE  INDEX "CustomerID" ON "dbo"."Orders"("CustomerID")
GO
 CREATE  INDEX "CustomersOrders" ON "dbo"."Orders"("CustomerID")
GO
 CREATE  INDEX "EmployeeID" ON "dbo"."Orders"("EmployeeID")
GO
 CREATE  INDEX "EmployeesOrders" ON "dbo"."Orders"("EmployeeID")
GO
 CREATE  INDEX "OrderDate" ON "dbo"."Orders"("OrderDate")


CREATE TABLE OrderDetails (
    orderID INT NOT NULL,
    productID INT NOT NULL,
	colorID INT NOT NULL,
	sizeID INT NOT NULL,
    unitPrice NUMERIC NOT NULL,
    quantity INT default 1,
    discount INT NOT NULL default 0,
	constraint PK_Order_Detail PRIMARY KEY(orderID,productID,colorID,sizeID),
    constraint FK_Order_Detail FOREIGN KEY (orderID) REFERENCES Orders(orderID),
    constraint FK_Order_Product_Detail FOREIGN KEY (productID) REFERENCES Products(productID),
	constraint FK_Order_Color_Detail FOREIGN KEY(colorID) REFERENCES Colors(colorID),
	constraint FK_Order_Size_Detail FOREIGN KEY (sizeID) REFERENCES Sizes(sizeID),
	constraint CHK_Order_Price check (unitPrice >= 0),
	constraint CHK_Order_Qty check (quantity >= 1)
);
GO
 CREATE  INDEX "OrderID" ON "dbo"."OrderDetails"("OrderID")
GO
 CREATE  INDEX "OrdersOrder_Details" ON "dbo"."OrderDetails"("OrderID")
GO
 CREATE  INDEX "ProductID" ON "dbo"."OrderDetails"("ProductID")
GO
 CREATE  INDEX "ProductsOrder_Details" ON "dbo"."OrderDetails"("ProductID")
GO

create table ReturnOrder(
	
	orderID INT NOT NULL,
    
	productID INT NOT NULL,
    colorID INT NOT NULL,
    sizeID INT NOT NULL,

	quantityReturned INT NOT NULL default 1,
	returnedDate DATETIME NOT NULL default getdate(),
	constraint FK_Return_Order FOREIGN KEY (orderID) REFERENCES Orders,
	constraint FK_Return_Order_Product FOREIGN KEY (productID) REFERENCES Products,
	constraint FK_Return_Order_Color FOREIGN KEY (colorID) REFERENCES Colors,
    constraint FK_Return_Order_size FOREIGN KEY (Colorid) REFERENCES Colors,
	constraint CHK_Qty_Returned check (quantityReturned >= 1),
	
	constraint PK_Return_Order primary key(orderID,colorID,sizeID,productID)

);











