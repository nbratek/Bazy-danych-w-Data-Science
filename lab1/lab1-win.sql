-- zad1 
select avg(unitprice) avgprice
from products p;


select avg(unitprice) over () as avgprice
from products p;


select categoryid, avg(unitprice) avgprice
from products p
group by categoryid


select avg(unitprice) over (partition by categoryid) as avgprice
from products p;


-- zad2 

select p.productid, p.ProductName, p.unitprice,
       (select avg(unitprice) from products) as avgprice
from products p
where productid < 10

select p.productid, p.ProductName, p.unitprice,
       avg(unitprice) over () as avgprice
from products p
where productid < 10


select p.productid, p.ProductName, p.unitprice, 
       avg(p.unitprice) over () as avgprice
from products p
where productid < 10;

select p.productid, p.ProductName, p.unitprice, 
       (select avg(unitprice) from products) as avgprice
from products p
where productid < 10;

-- zad 3

select productid, productname, unitprice, (select avg(unitprice) from products) as avgprice
from products p;

select productid, productname, unitprice,
avg(unitprice) over () as avgprice
from products;


select p.productid, p.productname, p.unitprice, avg(a.unitprice) as avgprice
from products p
cross join products a
group by p.productid, p.productname, p.unitprice;


-- zad4 



select p.productid, p.productname, p.unitprice,
       (
           select avg(x.unitprice)
           from products x
           where x.categoryid = p.categoryid
       ) as avg_category_price
from products p
where p.unitprice > (
    select avg(x.unitprice)
    from products x
    where x.categoryid = p.categoryid
);


select *
from (
    select p.productid, p.productname, p.unitprice,
           avg(p.unitprice) over (partition by p.categoryid) as avg_category_price
    from products p
) t
where t.unitprice > t.avg_category_price;


select p.productid, p.productname, p.unitprice, avg(x.unitprice) as avg_category_price
from products p
left join products x
  on x.categoryid = p.categoryid
group by p.productid, p.productname, p.unitprice
having p.unitprice > avg(x.unitprice);

-- zad5 

select count(*) from product_history;



--zad6

select *
from (
    select
    id,
    productid,
    productname,
    categoryid,
    unitprice,
    avg(unitprice) over (partition by categoryid) as avg_price_in_category
    from product_history
    where id < 100000
) t
where unitprice > avg_price_in_category;

------

with t as (
    select *
    from product_history
    where id < 20000
)
select
    p.id,
    p.productid,
    p.productname,
    p.categoryid,
    p.unitprice,
    avg(pp.unitprice) as avg_price_in_category
from t p
join t pp on p.categoryid = pp.categoryid
group by
    p.id, p.productid, p.productname, p.categoryid, p.unitprice
having p.unitprice > avg(pp.unitprice)
order by p.id;
----

with t as (
	select *
	from product_history
	where id < 100000
)
select *
from (
	select
		id,
		productid,
		productname,
		categoryid,
		unitprice,
		avg(unitprice) over (partition by categoryid) as avg_price_in_category
	from t
) x
where unitprice > avg_price_in_category
order by id;