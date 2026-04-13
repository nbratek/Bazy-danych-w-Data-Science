
# Indeksy,  optymalizator <br>Lab1

<!-- <style scoped>
 p,li {
    font-size: 12pt;
  }
</style>  -->

<!-- <style scoped>
 pre {
    font-size: 8pt;
  }
</style>  -->


---

**Imiona i nazwiska:**

--- 

Celem ćwiczenia jest zapoznanie się z planami wykonania zapytań (execution plans), oraz z budową i możliwością wykorzystaniem indeksów.

Swoje odpowiedzi wpisuj w miejsca oznaczone jako:

---
> Wyniki: 

```sql
--  ...
```

---

Ważne/wymagane są komentarze.

Zamieść kod rozwiązania oraz zrzuty ekranu pokazujące wyniki
- dołącz kod rozwiązania w formie tekstowej/źródłowej
- najlepiej plik  .md 
	- ewentualnie sql

Zwróć uwagę na formatowanie kodu

## Oprogramowanie - co jest potrzebne?

Do wykonania ćwiczenia potrzebne jest następujące oprogramowanie
- MS SQL Server
- SSMS - SQL Server Management Studio    
	- ewentualnie inne narzędzie umożliwiające komunikację z MS SQL Server i analizę planów zapytań
- przykładowa baza danych AdventureWorks2017.
    
Oprogramowanie dostępne jest na przygotowanej maszynie wirtualnej


## Przygotowanie  
    
Stwórz swoją bazę danych o nazwie lab1. 

```sql
create database lab1  
go  
  
use lab1 
go
```


# Część 1

Celem tej części ćwiczenia jest zapoznanie się z planami wykonania zapytań (execution plans) oraz narzędziem do automatycznego generowania indeksów.

## Dokumentacja/Literatura

Przydatne materiały/dokumentacja. Proszę zapoznać się z dokumentacją:
- [https://docs.microsoft.com/en-us/sql/tools/dta/tutorial-database-engine-tuning-advisor](https://docs.microsoft.com/en-us/sql/tools/dta/tutorial-database-engine-tuning-advisor)
- [https://docs.microsoft.com/en-us/sql/relational-databases/performance/start-and-use-the-database-engine-tuning-advisor](https://docs.microsoft.com/en-us/sql/relational-databases/performance/start-and-use-the-database-engine-tuning-advisor)
- [https://www.simple-talk.com/sql/performance/index-selection-and-the-query-optimizer](https://www.simple-talk.com/sql/performance/index-selection-and-the-query-optimizer)
- [https://blog.quest.com/sql-server-execution-plan-what-is-it-and-how-does-it-help-with-performance-problems/](https://blog.quest.com/sql-server-execution-plan-what-is-it-and-how-does-it-help-with-performance-problems/)


Operatory (oraz reprezentujące je piktogramy/Ikonki) używane w graficznej prezentacji planu zapytania opisane są tutaj:
- [https://docs.microsoft.com/en-us/sql/relational-databases/showplan-logical-and-physical-operators-reference](https://docs.microsoft.com/en-us/sql/relational-databases/showplan-logical-and-physical-operators-reference)

<div style="page-break-after: always;"></div>


Wykonaj poniższy skrypt, aby przygotować dane:

```sql
select * into [salesorderheader]  
from [adventureworks2017].sales.[salesorderheader]  
go  
  
select * into [salesorderdetail]  
from [adventureworks2017].sales.[salesorderdetail]  
go
```


# Zadanie 1 - Obserwacja


Wpisz do MSSQL Managment Studio (na razie nie wykonuj tych zapytań):

```sql
-- zapytanie 1  
select *  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where orderdate = '2008-06-01 00:00:00.000'  
go  

-- zapytanie 1.1
select *  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where orderdate = '2013-01-28 00:00:00.000' 
go  
  
-- zapytanie 2  
select orderdate, productid, sum(orderqty) as orderqty, 
       sum(unitpricediscount) as unitpricediscount, sum(linetotal)  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
group by orderdate, productid  
having sum(orderqty) >= 100  
go  
  
-- zapytanie 3  
select salesordernumber, purchaseordernumber, duedate, shipdate  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where orderdate in ('2008-06-01','2008-06-02', '2008-06-03', '2008-06-04', '2008-06-05')  
go  
  
-- zapytanie 4  
select sh.salesorderid, salesordernumber, purchaseordernumber, duedate, shipdate  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where carriertrackingnumber in ('ef67-4713-bd', '6c08-4c4c-b8')  
order by sh.salesorderid  
go
```


Włącz dwie opcje: **Include Actual Execution Plan** oraz **Include Live Query Statistics**:



<!-- ![[_img/index1-1.png | 500]] -->


<img src="_img/index1-1.png" alt="image" width="500" height="auto">


Teraz wykonaj poszczególne zapytania (najlepiej każde analizuj oddzielnie). Co można o nich powiedzieć? Co sprawdzają? Jak można je zoptymalizować?  

---
> Wyniki: 

- zapytanie 1 

<img src="screen/zad1-1-statistics.png" alt="image" width="500" height="auto">



<img src="screen/zad1-1-plan.png" alt="image" width="500" height="auto">

- zapytanie 1.1 


<img src="screen/zad1-1.1-statistics.png" alt="image" width="500" height="auto">



<img src="screen/zad1-1.1-plan.png" alt="image" width="500" height="auto">

- zapytanie 2 

<img src="screen/zad1-2-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad1-2-plan.png" alt="image" width="500" height="auto">


- zapytanie 3 

<img src="screen/zad1-3-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad1-3-plan.png" alt="image" width="500" height="auto">



- zapytanie 4

<img src="screen/zad1-4-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad1-4-plan.png" alt="image" width="500" height="auto">


---

# Zadanie 2 - Dobór indeksów / optymalizacja

Do wykonania tego ćwiczenia potrzebne jest narzędzie SSMS


Zapytania 1, 2, 3, 4 z  poprzedniego zadania 

```sql
select *  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where orderdate = '2008-06-01 00:00:00.000'  
go  
  
-- zapytanie 2  
select orderdate, productid, sum(orderqty) as orderqty, 
       sum(unitpricediscount) as unitpricediscount, sum(linetotal)  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
group by orderdate, productid  
having sum(orderqty) >= 100  
go  
  
-- zapytanie 3  
select salesordernumber, purchaseordernumber, duedate, shipdate  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where orderdate in ('2008-06-01','2008-06-02', '2008-06-03', '2008-06-04', '2008-06-05')  
go  
  
-- zapytanie 4  
select sh.salesorderid, salesordernumber, purchaseordernumber, duedate, shipdate  
from salesorderheader sh  
inner join salesorderdetail sd on sh.salesorderid = sd.salesorderid  
where carriertrackingnumber in ('ef67-4713-bd', '6c08-4c4c-b8')  
order by sh.salesorderid  
go

```


Zaznacz wszystkie zapytania, i uruchom je w **Database Engine Tuning Advisor**:

<!-- ![[_img/index1-12.png | 500]] -->

<img src="_img/index1-2.png" alt="image" width="500" height="auto">


Sprawdź zakładkę **Tuning Options**, co tam można skonfigurować?

---
> Wyniki: 


<img src="screen/zad2-tuning-options.png" alt="image" width="500" height="auto">

---


Użyj **Start Analysis**:

<!-- ![[_img/index1-3.png | 500]] -->

<img src="_img/index1-3.png" alt="image" width="500" height="auto">


Zaobserwuj wyniki w **Recommendations**.

Przejdź do zakładki **Reports**. Sprawdź poszczególne raporty. Główną uwagę zwróć na koszty i ich poprawę:


<!-- ![[_img/index4-1.png | 500]] -->

<img src="_img/index1-4.png" alt="image" width="500" height="auto">


Zapisz poszczególne rekomendacje:

Uruchom zapisany skrypt w Management Studio.

Opisz, dlaczego dane indeksy zostały zaproponowane do zapytań:

---
> Wyniki: 

<img src="screen/zad2-recommendations.png" alt="image" width="500" height="auto">



<img src="screen/zad2-reports.png" alt="image" width="500" height="auto">

<img src="screen/zad2-index-1.png" alt="image" width="500" height="auto">

<img src="screen/zad2-index-2.png" alt="image" width="500" height="auto">

<img src="screen/zad2-index-3.png" alt="image" width="500" height="auto">
---


Sprawdź jak zmieniły się Execution Plany. Opisz zmiany:

---
> Wyniki: 

- zapytanie 1 

<img src="screen/zad2-1-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad2-1-plan.png" alt="image" width="500" height="auto">

- zapytanie 2

<img src="screen/zad2-2-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad2-2-plan.png" alt="image" width="500" height="auto">

- zapytanie 3

<img src="screen/zad2-3-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad2-3-plan.png" alt="image" width="500" height="auto">


- zapytanie 4

<img src="screen/zad2-4-statistics.png" alt="image" width="500" height="auto">



<img src="screen/zad2-4-plan.png" alt="image" width="500" height="auto">
---

# Część 2

Celem ćwiczenia jest zapoznanie się z różnymi rodzajami  indeksów  oraz możliwością ich wykorzystania

## Dokumentacja/Literatura

Przydatne materiały/dokumentacja. Proszę zapoznać się z dokumentacją:
- [https://docs.microsoft.com/en-us/sql/relational-databases/indexes/indexes](https://docs.microsoft.com/en-us/sql/relational-databases/indexes/indexes)
- [https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide](https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide)
- [https://www.simple-talk.com/sql/performance/14-sql-server-indexing-questions-you-were-too-shy-to-ask/](https://www.simple-talk.com/sql/performance/14-sql-server-indexing-questions-you-were-too-shy-to-ask/)
- [https://www.sqlshack.com/sql-server-query-execution-plans-examples-select-statement/](https://www.sqlshack.com/sql-server-query-execution-plans-examples-select-statement/)

# Zadanie 3 - Indeksy klastrowane I nieklastrowane


Skopiuj tabelę `Customer` do swojej bazy danych:

```sql
select * into customer from adventureworks2017.sales.customer
```

Wykonaj analizy zapytań:

```sql
select * from customer where storeid = 594  
  
select * from customer where storeid between 594 and 610
```

Zanotuj czas zapytania oraz jego koszt koszt:

---
> Wyniki: 


<img src="screen/zad3-1-z2-plan.png" alt="image" width="500" height="auto">


<img src="screen/zad3-1-time.png" alt="image" width="500" height="auto">


Dodaj indeks:

```sql
create  index customer_store_cls_idx on customer(storeid)
```

Jak zmienił się plan i czas? Czy jest możliwość optymalizacji?


---
> Wyniki: 

<img src="screen/zad3-2-z1-plan.png" alt="image" width="500" height="auto">

<img src="screen/zad3-2-z2-plan.png" alt="image" width="500" height="auto">


<img src="screen/zad3-2-time.png" alt="image" width="500" height="auto">



Dodaj indeks klastrowany:

```sql
create clustered index customer_store_cls_idx on customer(storeid)
```

Czy zmienił się plan/koszt/czas? Skomentuj dwa podejścia w wyszukiwaniu krotek.


---
> Wyniki: 


<img src="screen/zad3-3-z1-plan.png" alt="image" width="500" height="auto">

<img src="screen/zad3-3-z2-plan.png" alt="image" width="500" height="auto">


<img src="screen/zad3-3-time.png" alt="image" width="500" height="auto">


# Zadanie 4 - dodatkowe kolumny w indeksie

Celem zadania jest porównanie indeksów zawierających dodatkowe kolumny.

Skopiuj tabelę `Address` do swojej bazy danych:

```sql
select * into address from  adventureworks2017.person.address
```

W tej części będziemy analizować następujące zapytanie:

```sql
select addressline1, addressline2, city, stateprovinceid, postalcode  
from address  
where postalcode between '98000' and '99999'
```

```sql
create index address_postalcode_1  
on address (postalcode)  
include (addressline1, addressline2, city, stateprovinceid);  
go  
  
create index address_postalcode_2  
on address (postalcode, addressline1, addressline2, city, stateprovinceid);  
go
```


Czy jest widoczna różnica w planach/kosztach zapytań? 
- w sytuacji gdy nie ma indeksów
- przy wykorzystaniu indeksu:
	- address_postalcode_1
	- address_postalcode_2

Jeśli tak to jaka? 

Aby wymusić użycie indeksu użyj `WITH(INDEX(Address_PostalCode_1))` po `FROM`

```sql
select addressline1, addressline2, city, stateprovinceid, postalcode
from address  WITH(INDEX(Address_PostalCode_1))
where postalcode between '98000' and '99999'


select addressline1, addressline2, city, stateprovinceid, postalcode
from address  WITH(INDEX(Address_PostalCode_2))
where postalcode between '98000' and '99999'
```


> Wyniki: 
- bez indeksów


<img src="screen/zad3-1-statistics.png" alt="image" width="500" height="auto">



<img src="screen/zad3-1-plan.png" alt="image" width="500" height="auto">




- przy wykorzystaniu  indeksu address_postalcode_1

<img src="screen/zad3-2-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad3-2-plan.png" alt="image" width="500" height="auto">


- przy wykorzystaniu  indeksu address_postalcode_2

<img src="screen/zad3-3-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad3-3-plan.png" alt="image" width="500" height="auto">




Sprawdź rozmiar Indeksów:

```sql
select i.name as indexname, sum(s.used_page_count) * 8 as indexsizekb  
from sys.dm_db_partition_stats as s  
inner join sys.indexes as i on s.object_id = i.object_id and s.index_id = i.index_id  
where i.name = 'address_postalcode_1' or i.name = 'address_postalcode_2'  
group by i.name  
go
```


Który jest większy? Jak można skomentować te dwa podejścia do indeksowania? Które kolumny na to wpływają?


> Wyniki: 

<img src="screen/zad3-iindex-size.png" alt="image" width="500" height="auto">



# Zadanie 5  - kolejność atrybutów


Skopiuj tabelę `Person` do swojej bazy danych:

```sql
select businessentityid  
      ,persontype  
      ,namestyle  
      ,title  
      ,firstname  
      ,middlename  
      ,lastname  
      ,suffix  
      ,emailpromotion  
      ,rowguid  
      ,modifieddate  
into person  
from adventureworks2017.person.person
```
---

Wykonaj analizę planu dla trzech zapytań:

```sql
select * from [person] where lastname = 'Agbonile'  
  
select * from [person] where lastname = 'Agbonile' and firstname = 'Osarumwense'  
  
select * from [person] where firstname = 'Osarumwense'
```

Co można o nich powiedzieć?


---
> Wyniki: 

- zapytanie 1 

<img src="screen/zad5-1-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-1-plan.png" alt="image" width="500" height="auto">

- zapytanie 2

<img src="screen/zad5-2-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-2-plan.png" alt="image" width="500" height="auto">

- zapytanie 3 

<img src="screen/zad5-3-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-3-plan.png" alt="image" width="500" height="auto">


Przygotuj indeks obejmujący te zapytania:

```sql
create index person_first_last_name_idx  
on person(lastname, firstname)
```

Sprawdź plan zapytania. Co się zmieniło?


---
> Wyniki: 

- zapytanie 1 

<img src="screen/zad5-1i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-1i-plan.png" alt="image" width="500" height="auto">

- zapytanie 2

<img src="screen/zad5-2i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-2i-plan.png" alt="image" width="500" height="auto">

- zapytanie 3 

<img src="screen/zad5-3i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5-3i-plan.png" alt="image" width="500" height="auto">


Przeprowadź ponownie analizę zapytań tym razem dla parametrów: `FirstName = ‘Angela’` `LastName = ‘Price’`. (Trzy zapytania, różna kombinacja parametrów). 

Czym różni się ten plan od zapytania o `'Osarumwense Agbonile'` . Dlaczego tak jest?


---
> Wyniki: 

Przed dodaniem indeksu:
- zapytanie 1 

<img src="screen/zad5.2-1-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-1-plan.png" alt="image" width="500" height="auto">

- zapytanie 2

<img src="screen/zad5.2-2-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-2-plan.png" alt="image" width="500" height="auto">

- zapytanie 3 

<img src="screen/zad5.2-3-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-3-plan.png" alt="image" width="500" height="auto">



Po dodaniu indeksu:

- zapytanie 1 

<img src="screen/zad5.2-1i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-1i-plan.png" alt="image" width="500" height="auto">

- zapytanie 2

<img src="screen/zad5.2-2i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-2i-plan.png" alt="image" width="500" height="auto">

- zapytanie 3 

<img src="screen/zad5.2-3i-statistics.png" alt="image" width="500" height="auto">

<img src="screen/zad5.2-3i-plan.png" alt="image" width="500" height="auto">



---

Punktacja:

|         |     |
| ------- | --- |
| zadanie | pkt |
| 1       | 2   |
| 2       | 2   |
| 3       | 2   |
| 4       | 2   |
| 5       | 2   |
| razem   | 10  |
|         |     |
