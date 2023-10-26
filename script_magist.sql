
Magist/Eniac Project
-----------------------------------------------------------------------------------------------------

USE magist;

------------------------------------------------------------------------------------------------------


 #### 3.1. In relation to the products:  
 
 
#1 What categories of tech products does Magist have?

SELECT product_category_name 
FROM products 
WHERE product_category_name LIKE 'ele%'
OR product_category_name LIKE 'computer%'
OR product_category_name LIKE 'tel%'
OR product_category_name LIKE 'tabl%'; 



--------------------------------------------------------------------------------    


# 2 How many products of these tech categories have been sold 
#(within the time window of the database snapshot)?     tech prod cosld =9347 tot prod sold=112650 tech perc= 8.29


WITH TechSales AS (
    SELECT COUNT(*) AS tech_products_sold
    FROM order_items AS s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.product_category_name LIKE 'ele%'
    OR p.product_category_name LIKE 'computer%'
    OR p.product_category_name LIKE 'tel%'
    OR p.product_category_name LIKE 'tabl%'
) 

#SELECT tech_products_sold 
#FROM TechSales;

# What percentage does that represent from the overall number of products sold?
SELECT tech_products_sold, 
       (SELECT COUNT(*) FROM order_items) AS total_products_sold,
       (tech_products_sold * 100.0 / (SELECT COUNT(*) FROM order_items)) AS tech_percentage
FROM TechSales;



------------------------------------------------------------------------------------------------------


#3 What’s the average price of the products being sold?  avg price = 100.049


SELECT AVG(s.price) AS average_sold_price
FROM order_items AS s
JOIN products p ON s.product_id = p.product_id
WHERE p.product_category_name LIKE 'ele%'
    OR p.product_category_name LIKE 'computer%'
    OR p.product_category_name LIKE 'tel%'
    OR p.product_category_name LIKE 'tabl%';


--------------------------------------------------------------------------------------------------------------


#4 Are expensive tech products popular? 
# avg sales expensive tech 3.7672


WITH TechAvgPrice AS (
    SELECT AVG(price) AS average_tech_price
    FROM order_items AS s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.product_category_name LIKE 'ele%'
    OR p.product_category_name LIKE 'computer%'
    OR p.product_category_name LIKE 'tel%'
    OR p.product_category_name LIKE 'tabl%'
)
, ExpensiveTechSales AS (
    SELECT p.product_id, COUNT(*) AS sales_count
    FROM order_items AS s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.product_category_name LIKE 'ele%'
    OR p.product_category_name LIKE 'computer%'
    OR p.product_category_name LIKE 'tel%'
    OR p.product_category_name LIKE 'tabl%' AND s.price > (SELECT average_tech_price FROM TechAvgPrice)
    GROUP BY p.product_id
)

SELECT AVG(sales_count) AS average_sales_expensive_tech
FROM ExpensiveTechSales;



----------------------------------------------------------------------------------------------


# 3.2. In relation to the sellers:
#1 How many months of data are included in the magist database? tot month 25



SELECT COUNT(DISTINCT YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)) AS total_months
FROM orders;

#or 

SELECT COUNT(DISTINCT CONCAT(YEAR(order_purchase_timestamp), '-', MONTH(order_purchase_timestamp))) AS total_months
FROM orders;


---------------------------------------------------------------------------------------------------------


# 2 How many sellers are there? 
#How many Tech sellers are there? 
# What percentage of overall sellers are Tech sellers?

-- 1. Total Sellers   3095
WITH TotalSellers AS (
    SELECT COUNT(DISTINCT seller_id) as total_sellers
    FROM order_items
),
-- 2. Tech Sellers  401
TechSellers AS (
    SELECT COUNT(DISTINCT s.seller_id) as tech_sellers
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.product_category_name LIKE 'ele%'
    OR p.product_category_name LIKE 'computer%'
    OR p.product_category_name LIKE 'tel%'
    OR p.product_category_name LIKE 'tabl%'
)
-- 3. Results  12.965
SELECT   
    ts.total_sellers,
    techs.tech_sellers,
    (techs.tech_sellers * 100.0 / ts.total_sellers) as tech_sellers_percentage
FROM TotalSellers ts, TechSellers techs;


-------------------------------------------------------------------------------------------------------------------


# Can you work out the average monthly income of all sellers? AVG monthly income= 566318.48


WITH MonthlyIncome AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year,
        MONTH(order_purchase_timestamp) AS month,
        SUM(s.price) AS total_income
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    JOIN orders o ON s.order_id = o.order_id
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT AVG(total_income) AS avg_monthly_income
FROM MonthlyIncome;


-----------------------------------------------------------------------------------------------------------------------


# 3.3. In relation to the delivery time:
# 1 What’s the average time between the order being placed and the product being delivered? avg delivery time 0 12.

SELECT AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
FROM orders;

-------------------------------------------------------------------------------------------------------------------------


# 2 How many orders are delivered on time vs orders delivered with a delay? on time= 88649 delayed=7827S

SELECT 
    SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_deliveries
FROM orders;

--------------------------------------------------------------------------------------------------------------------------


# 3 Is there any pattern for delayed orders, e.g. big products being delayed more often? NO
SELECT
    p.product_category_name,
    SUM(CASE WHEN s.order_delivered_customer_date <= s.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_deliveries,
    SUM(CASE WHEN s.order_delivered_customer_date > s.order_estimated_delivery_date THEN 1 ELSE 0 END) AS delayed_deliveries
FROM orders s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY delayed_deliveries DESC;


------------------------------- Implementation in CTE  -----------------------

WITH MonthlyTechIncome AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year,
        MONTH(order_purchase_timestamp) AS month,
        SUM(s.price) AS tech_income
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    JOIN orders o ON s.order_id = o.order_id
    WHERE 
        p.product_category_name LIKE 'ele%'
        OR p.product_category_name LIKE 'computer%'
        OR p.product_category_name LIKE 'tel%'
        OR p.product_category_name LIKE 'tabl%'
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT 
    year,
    month,
    AVG(tech_income) OVER (PARTITION BY month) AS avg_monthly_tech_income
FROM MonthlyTechIncome
ORDER BY year, month;

#######################################



WITH MonthlyIncome AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year,
        MONTH(order_purchase_timestamp) AS month,
        SUM(s.price) AS total_income
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    JOIN orders o ON s.order_id = o.order_id
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT 
    year,
    month,
    total_income
FROM MonthlyIncome
ORDER BY year, month;



#######################################


WITH MonthlyTechIncome AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year,
        MONTH(order_purchase_timestamp) AS month,
        SUM(s.price) AS tech_income
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    JOIN orders o ON s.order_id = o.order_id
    WHERE 
        p.product_category_name LIKE 'ele%'
        OR p.product_category_name LIKE 'computer%'
        OR p.product_category_name LIKE 'tel%'
        OR p.product_category_name LIKE 'tabl%'
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
),
MonthlyIncome AS (
    SELECT 
        YEAR(order_purchase_timestamp) AS year,
        MONTH(order_purchase_timestamp) AS month,
        SUM(s.price) AS total_income
    FROM order_items s
    JOIN products p ON s.product_id = p.product_id
    JOIN orders o ON s.order_id = o.order_id
    GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
)
SELECT 
    MTI.year,
    MTI.month,
    MTI.tech_income AS avg_tech_monthly_income,
    MI.total_income AS total_monthly_income,
    AVG(MI.total_income) OVER (PARTITION BY MI.month) AS avg_monthly_income,
    (AVG(MI.total_income) OVER (PARTITION BY MI.month) - AVG(MTI.tech_income)) AS avg_monthly_income_without_tech
FROM MonthlyTechIncome MTI
JOIN MonthlyIncome MI ON MTI.year = MI.year AND MTI.month = MI.month
GROUP BY MTI.year, MTI.month;
ORDER BY MTI.year, MTI.month;

