-- zad1


select productid, productname, unitprice, categoryid,  
    row_number() over(partition by categoryid order by unitprice desc) as rowno,  
    rank() over(partition by categoryid order by unitprice desc) as rankprice,  
    dense_rank() over(partition by categoryid order by unitprice desc) as denserankprice  
from products;



select p.productid,
       p.productname,
       p.unitprice,
       p.categoryid,
       (select count(pp.productid) + 1 as c
        from products pp
        where (pp.categoryid = p.categoryid and pp.unitprice > p.unitprice)
           or (pp.categoryid = p.categoryid and pp.unitprice = p.unitprice and pp.productid < p.productid)) as rowno,
       (select count(pp.productid) + 1
        from products pp
        where pp.categoryid = p.categoryid
          and pp.unitprice > p.unitprice) as rankprice,
       (select count(t.c) + 1
        from (select distinct pp.unitprice as c
              from products pp
              where pp.categoryid = p.categoryid
                and pp.unitprice > p.unitprice) t) as denserankprice
from products p
order by p.categoryid, p.unitprice desc, p.productid


-- zad2 

with ranking as (
    select 
        YEAR([date]) as year,
        productid,
        productname,
        unitprice,
        [date],
        row_number() over (
            partition by productid, YEAR([date]) 
            order by unitprice desc
        ) as rank_pos
    from product_history
)
select *
from ranking
where rank_pos <= 4
order by year, productid, rank_pos;



with ranking as (
    select 
        YEAR([date]) as year,
        p.productid,
        p.productname,
        p.unitprice,
        p.[date],
        (
            select count(distinct p2.unitprice) + 1
            from product_history p2
            where p2.productid = p.productid
              and YEAR(p2.[date]) = YEAR(p.[date])
              and p2.unitprice > p.unitprice
        ) as rank_pos
    from product_history p
    where p.productid < 10 
)
select *
from ranking
where rank_pos <= 4
order by year, productid, rank_pos;



-- zad3

select productid, productname, categoryid, date, unitprice,  
       lag(unitprice) over (partition by productid order by date)   
as previousprodprice,  
       lead(unitprice) over (partition by productid order by date)   
as nextprodprice  
from product_history  
where productid = 1 and year(date) = 2022  
order by date;  
  
with t as (select productid, productname, categoryid, date, unitprice,  
                  lag(unitprice) over (partition by productid   
order by date) as previousprodprice,  
                  lead(unitprice) over (partition by productid   
order by date) as nextprodprice  
           from product_history  
           )  
select * from t  
where productid = 1 and year(date) = 2022  
order by date;



select p.productid,
       p.productname,
       p.categoryid,
       p.date,
       p.unitprice,

       (select top 1 p1.unitprice
        from product_history p1
        where p1.productid = p.productid
          and year(p1.date) = 2022
          and p1.date < p.date
        order by p1.date desc) as previousprodprice,

       (select top 1 p1.unitprice
        from product_history p1
        where p1.productid = p.productid
          and year(p1.date) = 2022
          and p1.date > p.date
        order by p1.date asc) as nextprodprice

from product_history p
where p.productid = 1
  and year(p.date) = 2022
order by p.date;



-- zad4
with order_values as (
    select 
        c.CompanyName,
        o.CustomerID,
        o.OrderID,
        o.OrderDate,
        o.Freight,
        CAST(
            SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)) + o.Freight 
            AS decimal(10,2)
        ) as order_total
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Customers c on o.CustomerID = c.CustomerID
    group by 
        c.CompanyName, o.CustomerID, o.OrderID, o.OrderDate, o.Freight
)

select 
    CompanyName,
    OrderID,
    OrderDate,
    order_total,

    lag(OrderID) over (partition by CustomerID order by OrderDate) as prev_order_id,
    lag(OrderDate) over (partition by CustomerID order by OrderDate) as prev_order_date,
    lag(order_total) over (partition by CustomerID order by OrderDate) as prev_order_value

from order_values
order by CompanyName, OrderDate;