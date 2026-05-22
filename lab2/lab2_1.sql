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



-- zad 2 

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
        productid,
        productname,
        unitprice,
        [date],
        row_number() over (
            partition by productid, YEAR([date]) 
            order by unitprice desc
        ) as rank_pos
    from product_history
    where productid <= 10      
)
select *
from ranking
where rank_pos <= 4
order by year, productid, rank_pos;


WITH base AS (
    SELECT
        productid,
        productname,
        unitprice,
        [date],
        YEAR([date]) AS rok,
        id
    FROM product_history
    WHERE productid <= 10
)
, price_rank AS (
    SELECT
        b1.*,
        COUNT(b2.unitprice) + 1 AS rn
    FROM base b1
    LEFT JOIN base b2
        ON b1.productid = b2.productid
       AND b1.rok = b2.rok
       AND (
            b2.unitprice > b1.unitprice
         OR (b2.unitprice = b1.unitprice AND b2.[date] < b1.[date])
         OR (b2.unitprice = b1.unitprice AND b2.[date] = b1.[date] AND b2.id < b1.id)
       )
    GROUP BY
        b1.productid,
        b1.productname,
        b1.unitprice,
        b1.[date],
        b1.rok,
        b1.id
)
SELECT *
FROM price_rank
WHERE rn <= 4
ORDER BY rok, productid, rn;


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

-- zad 5 


select productid, productname, unitprice, categoryid,  
    first_value(productname) over (partition by categoryid   
order by unitprice desc) first,  
    last_value(productname) over (partition by categoryid   
order by unitprice desc) last  
from products  
order by categoryid, unitprice desc;



select productid, productname, unitprice, categoryid,
    first_value(productname) over (
        partition by categoryid
        order by unitprice desc
    ) as first,
    last_value(productname) over (
        partition by categoryid
        order by unitprice desc
        rows between unbounded preceding and unbounded following
    ) as last
from products
order by categoryid, unitprice desc;


select productid, productname, unitprice, categoryid,
    first_value(productname) over (
        partition by categoryid
        order by unitprice desc
    ) as first,
    last_value(productname) over (
        partition by categoryid
        order by unitprice desc
        rows between current row and unbounded following
    ) as last
from products
order by categoryid, unitprice desc;

-- zad6 

WITH order_values AS (
    SELECT
        o.customerid,
        o.orderid,
        o.orderdate,
        SUM(od.unitprice * od.quantity * (1 - COALESCE(od.discount, 0))) 
            + COALESCE(o.freight, 0) AS order_value,
        to_char(o.orderdate, 'YYYY-MM') AS year_month
    FROM orders o
    JOIN "Order Details" od
        ON o.orderid = od.orderid
    GROUP BY
        o.customerid,
        o.orderid,
        o.orderdate,
        o.freight
)
SELECT
    customerid,
    orderid,
    orderdate,
    order_value,
    -- MIN dla (klient, miesiąc)
    FIRST_VALUE(orderid) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value ASC
    ) AS min_order_id,
    FIRST_VALUE(orderdate) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value ASC
    ) AS min_order_date,
    FIRST_VALUE(order_value) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value ASC
    ) AS min_order_value,
    -- MAX dla (klient, miesiąc)
    FIRST_VALUE(orderid) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value DESC
    ) AS max_order_id,
    FIRST_VALUE(orderdate) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value DESC
    ) AS max_order_date,
    FIRST_VALUE(order_value) OVER (
        PARTITION BY customerid, year_month
        ORDER BY order_value DESC
    ) AS max_order_value
FROM order_values
ORDER BY customerid, year_month, order_value;
