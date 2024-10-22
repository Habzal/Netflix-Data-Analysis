select * from df_orders

-- Find top 10 highest revenue generating products
Select Top 10 product_id, sum(sale_price) as sales
from df_orders 
group by product_id
Order By sales desc

--Find Top 5 highest selling products in each region
With CTE as (
Select product_id, region, sum(sale_price) as sales
from df_orders
group by region, product_id) 

Select * from (
Select *, row_number() over (partition by region order by sales desc) as rn
from CTE ) A
where rn <= 5

--Find Month over Month growth comparison for 2022 and 2023 Sales
WITH CTE as (select year(order_date) as order_year, month(order_date) as order_month, sum(sale_price) as sales
from df_orders 
group by year(order_date), month(order_date))

Select order_month, 
sum(case when order_year = 2022 then sales else 0 end) as sales_2022,
sum(case when order_year = 2023 then sales else 0 end) as sales_2023
from CTE 
group by order_month
order by order_month

--For each category which month had highest sales
WITH CTE as (
select format(order_date, 'yyyyMM') as order_year_month, sum(sale_price) as sales, category 
from df_orders
group by category, format(order_date, 'yyyyMM'))

select * from (
Select *,
row_number() over (partition by category order by sales desc) as rn
from CTE ) a
where rn = 1

-- Which sub category had highest growth profit in 2023 compared to 2022
WITH CTE as (select sub_category, year(order_date) as order_year, sum(profit) as profit
from df_orders 
group by sub_category, year(order_date)),

CTE2 as (
Select sub_category, 
sum(case when order_year = 2022 then profit else 0 end) as profit_2022,
sum(case when order_year = 2023 then profit else 0 end) as profit_2023
from CTE 
group by sub_category)

Select top 1 *, (profit_2023 - profit_2022)*100 / profit_2022 as growth_profit
from CTE2
order by growth_profit desc