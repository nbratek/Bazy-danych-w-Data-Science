use lab2
go

create table OrdersTest
(
    OrderID int identity(1,1),
    CustomerID int,
    ProductID int,
    OrderDate datetime,
    Status varchar(20),
    Quantity int,
    Price money,
    City varchar(50)
)

set nocount on

declare @i int = 1

while @i <= 500000
begin

    insert into OrdersTest
    (
        CustomerID,
        ProductID,
        OrderDate,
        Status,
        Quantity,
        Price,
        City
    )
    values
    (
        abs(checksum(newid())) % 10000,
        abs(checksum(newid())) % 5000,
        dateadd(day, -abs(checksum(newid())) % 1000, getdate()),

        case
            when @i % 10 = 0 then 'Cancelled'
            when @i % 5 = 0 then 'Pending'
            else 'Completed'
        end,

        abs(checksum(newid())) % 20 + 1,
        abs(checksum(newid())) % 5000 + 100,

        case
            when @i % 3 = 0 then 'Warsaw'
            when @i % 3 = 1 then 'Krakow'
            else 'Gdansk'
        end
    )

    set @i += 1
end


use lab2

select * from sys.tables

SET STATISTICS IO ON
SET STATISTICS TIME ON

select count(*) as all_rows from OrdersTest
select count(distinct CustomerID) as unique_clients from OrdersTest

select count(distinct CustomerID) as unique_clients, min(OrderDate) as min_date,
       max(OrderDate) as max_date, datediff(day, min(OrderDate), max(OrderDate)) as max_days_diff from OrdersTest

exec sp_spaceused 'OrdersTest'

ALTER TABLE OrdersTest
ADD CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED (OrderID);


create clustered index ix_OrderDate_clustered on OrdersTest(OrderDate)

SET STATISTICS IO ON;

select * from OrdersTest
where OrderDate between '2026-01-01' and '2026-01-31'

select OrderDate from OrdersTest
where CustomerID = 1000

create nonclustered index ix_customerid_nonclustered on OrdersTest(CustomerID)

SELECT OrderDate
FROM OrdersTest WITH (INDEX(ix_OrderDate_clustered))
WHERE CustomerID = 1000;

select OrderDate from OrdersTest
where CustomerID = 1000

select OrderDate, Status, City from OrdersTest
where customerid = 1000

create nonclustered index ix_customerid_include
    on OrdersTest(CustomerID) include (Status, City)

select Status, count(*) as num from OrdersTest
group by Status

select OrderID, CustomerID, City
from OrdersTest
where status = 'Cancelled'

-- DECLARE @TotalRows INT;
-- DECLARE @TargetCancelled INT;
-- DECLARE @CurrentCancelled INT;
-- DECLARE @RowsToUpdate INT;
--
-- SELECT @TotalRows = COUNT(*)
-- FROM OrdersTest;
--
-- SET @TargetCancelled = @TotalRows * 0.05;
--
-- SELECT @CurrentCancelled = COUNT(*)
-- FROM OrdersTest
-- WHERE Status = 'Cancelled';
--
-- SET @RowsToUpdate = @CurrentCancelled - @TargetCancelled;
-- UPDATE TOP (@RowsToUpdate) OrdersTest
-- SET Status = 'Pending'
-- WHERE Status = 'Cancelled';

create nonclustered index ix_cancelled
on OrdersTest (OrderID)
include (CustomerID, City)
where Status = 'Cancelled'

select OrderID, CustomerID, City
from OrdersTest
where status = 'Cancelled'

DROP INDEX ix_cancelled
ON OrdersTest;

select
    customerID,
    count(*) as orders_count,
    sum(Quantity * Price) as total_spent
from OrdersTest
group by customerID

select
    customerID,
    count(*) as orders_count,
    sum(Quantity) as total_bought
from OrdersTest
group by customerID

CREATE NONCLUSTERED COLUMNSTORE INDEX IX_OrdersTest_CS
ON OrdersTest(CustomerID, Quantity, Price);