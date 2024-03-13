use toy_store;
select*from Calender;
select*from inventory;
select*from sales;
select*from products;
select*from stores;



1)

SELECT 
   TOP (10) P.Product_Name,sum([PRODUCT_PRICE in dollar]-[Product Cost in dollar]) AS PROFIT_$,
   round(sum(s.units *p.[product_price in dollar]),2) as total_sales_$
FROM 
   PRODUCTS p
   JOIN sales S
     ON p.Product_ID=S.product_id
group by p.Product_Name
ORDER BY PROFIT_$ desc;

2)



	  with cte as
  (SELECT 
  ST.STORE_NAME,round(SUM(S.UNITS *P.[PRODUCT_PRICE in dollar]),2) as total_REVENUE_$,
  SUM
  (P.[PRODUCT_PRICE in dollar]-P.[Product Cost in dollar]) as profit ,
  sum(P.[Product Cost in dollar]) as total_cost
FROM 
  sales S
  JOIN stores ST
    ON S.Store_ID=ST.Store_ID
  JOIN products P
    ON S.Product_ID= P.Product_ID
 group by store_name)

 select STORE_NAME,total_REVENUE_$,concat(round(profit/total_cost *100,2),'%') as profit_margin
 from cte
 order by (profit/total_cost *100) desc;



3)

WITH MonthlySales AS (
  SELECT
     YEAR(c.date) AS year,
     MONTH(c.date) AS month,
     AVG(s.units *p.[product_price in dollar]) AS monthly_average
  FROM sales s
	 join Calender c
	   on s.Date=c.Date
	join products p
	   on s.Product_ID=p.Product_ID	
  GROUP BY
     YEAR(c.Date),
     MONTH(c.date)
),
RollingAverage AS (
   SELECT
      year,
      month,
      monthly_average,
      AVG(monthly_average) OVER (ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_average
   FROM
      MonthlySales
)
SELECT
   CONCAT(year, '-', RIGHT('0' + CAST(month AS VARCHAR(2)), 2), '-01') AS month_start,

   round( monthly_average,2) as monthly_Average,
    round(rolling_average,2) as rolling_Average,
    CASE
        WHEN rolling_average > LAG(rolling_average) OVER (ORDER BY year, month) THEN 'Growth'
        WHEN rolling_average < LAG(rolling_average) OVER (ORDER BY year, month) THEN 'Decline'
        ELSE 'No Change'
    END AS trend
FROM
    RollingAverage
ORDER BY
    year, month;


4)

WITH ProfitMargin as(
  select 
    Product_Category,
     ROUND((
     ([PRODUCT_PRICE in dollar]-[Product Cost in dollar])/[Product Cost in Dollar])*100,2)
     AS PROFIT_MARGIN
  from 
    PRODUCTS
)

  SELECT 
     CONCAT(SUM(PROFIT_MARGIN),' ','%') as CUMULATIVE_DISTRIBUTION,PRODUCT_CATEGORY
  FROM 
     ProfitMargin
  group by PRODUCT_CATEGORY
  HAVING SUM(PROFIT_MARGIN)>0
  ORDER BY SUM(PROFIT_MARGIN) DESC;




5)


Analyze the efficiency of inventory turnover for each store by calculating the Inventory Turnover Ratio.


WITH StoreInventory AS (
   SELECT
     stores.store_id,stores.Store_Name,
     DATEADD(MONTH, DATEDIFF(MONTH, 0, c.date), 0) AS month_start,
     EOMONTH(c.date) AS month_end,
     SUM(i.stock_on_hand) AS total_inventory
   FROM
     sales s
	 join Calender c
	   on s.Date=c.Date
	join inventory i
	   on s.Product_ID=i.Product_ID	
	join stores
	   on s.Store_ID=stores.store_id
      
  GROUP BY
     stores.store_id,stores.Store_Name,
     DATEADD(MONTH, DATEDIFF(MONTH, 0, c.date), 0),
     EOMONTH(c.date)
)

SELECT
    store_name,
    month_start,
    month_end,
    total_inventory,
    LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start) AS prev_total_inventory,
    total_inventory - LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start) AS inventory_change,
    CASE
        WHEN LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start) IS NOT NULL AND
            LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start) <> 0
        THEN
            (total_inventory - LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start)) /
            LAG(total_inventory) OVER (PARTITION BY store_id ORDER BY month_start)
        ELSE
            NULL
    END AS inventory_turnover_ratio
FROM
    StoreInventory;

	
	





