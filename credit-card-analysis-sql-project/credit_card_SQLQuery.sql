
-- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

SELECT TOP 5 city, SUM(amount) total_city_spends,
	ROUND((SUM(amount) / (SELECT SUM(c1.amount) FROM credit_card_transactions c1))*100, 2) spend_percentage
FROM credit_card_transactions
GROUP BY city
ORDER BY total_city_spends DESC


-- write a query to print highest spend month and amount in that month for each card type 

WITH transactions AS (SELECT
    card_type,
    DATEPART(YEAR, transaction_date) ty,
    DATEPART(MONTH,  transaction_date) tm,
    sum(amount) as total_spend
FROM credit_card_transactions
GROUP BY card_type, DATEPART(YEAR, transaction_date), DATEPART(MONTH,  transaction_date)
), 
type_rank as (
SELECT *, rank() OVER(PARTITION BY card_type ORDER BY total_spend DESC) AS rnk
FROM transactions
)
SELECT *
FROM type_rank
WHERE rnk = 1


-- write a query to print the transactio details (all columns from the table) for each card type when it reaches a cumulative of 1000000
-- total spends (We should have 4 rows in the o/p one for each card type)

WITH cumulative_amount AS (
SELECT *,
	SUM(amount) OVER(PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS total_spend
FROM credit_card_transactions
)

SELECT *
FROM (SELECT *,
		RANK() OVER(PARTITION BY card_type ORDER BY total_spend) rn
	FROM cumulative_amount
	WHERE total_spend >= 1000000
) AS cumulative_spend
WHERE rn = 1

-- write a query to find city which had lowest percentage spend for gold card type


SELECT city, SUM(amount) total_spend,
	ROUND((SUM(amount) / (SELECT SUM(amount) FROM credit_card_transactions WHERE card_type = 'Gold')) * 100 , 5) as 'percentage'
FROM credit_card_transactions
WHERE card_type = 'Gold'
GROUP BY city
ORDER BY total_spend 

-- write a query to find print 3 columns: city, highest expense type, lowest_expense_type (example format : Delhi, bills, Fuel)


WITH total_transactions AS(
SELECT city, exp_type, SUM(amount) AS total_amount FROM credit_card_transactions
GROUP BY city, exp_type),
city_rank AS
(SELECT *,
	RANK() OVER(PARTITION BY city ORDER BY total_amount DESC) rn_desc,
	RANK() OVER(PARTITION BY city ORDER BY total_amount) rn_asc
FROM total_transactions) 

SELECT
	city , MAX(CASE WHEN rn_asc=1 THEN exp_type END) AS lowest_exp_type, 
	MIN(CASE WHEN rn_desc=1 THEN exp_type END) AS highest_exp_type
FROM city_rank
GROUP BY  city;


-- What is the percentage of total spend by females and males for each expense type, along with the total spend amount
SELECT *, 
	ROUND((female_spend / total_spend)*100, 2) female_spend_Pct, 
	total_spend - female_spend male_spend,
	100 - ROUND((female_spend / total_spend)*100, 2) male_spend_Pct
FROM(
SELECT exp_type, SUM(amount) total_spend,
    SUM(CASE WHEN gender = 'F' THEN amount END) AS female_spend
FROM credit_card_transactions
GROUP BY exp_type) female_spend_analysis 
ORDER BY total_spend DESC;


-- which card and expense type combination saw highest month over month gowth in Jan-2024
-- order by growth percentage
WITH prev_month AS(
SELECT *, LAG(total_spend, 1) OVER(PARTITION BY card_type, exp_type ORDER BY ty, tm)  prev_spend
FROM (
SELECT card_type, exp_type, SUM(amount) total_spend, DATEPART(YEAR, transaction_date) ty, DATEPART(MONTH, transaction_date) tm
FROM credit_card_transactions
GROUP BY card_type, exp_type, DATEPART(YEAR, transaction_date) , DATEPART(MONTH, transaction_date)
)year_month_transactions
)
SELECT top 1 *, (total_spend - prev_spend) growth_in_spend, ROUND(((total_spend - prev_spend) / prev_spend)*100 ,2) growth_percentage
FROM prev_month
WHERE prev_spend IS NOT NULL  AND ty =2014 AND tm=01
ORDER BY growth_percentage DESC

-- order by growth in spend amount
WITH prev_month AS(
SELECT *, LAG(total_spend, 1) OVER(PARTITION BY card_type, exp_type ORDER BY ty, tm)  prev_spend
FROM (
SELECT card_type, exp_type, SUM(amount) total_spend, DATEPART(YEAR, transaction_date) ty, DATEPART(MONTH, transaction_date) tm
FROM credit_card_transactions
GROUP BY card_type, exp_type, DATEPART(YEAR, transaction_date) , DATEPART(MONTH, transaction_date)
)year_month_transactions
)
SELECT top 1 *, (total_spend - prev_spend) growth_in_spend, ROUND(((total_spend - prev_spend) / prev_spend)*100 ,2) growth_percentage
FROM prev_month
WHERE prev_spend IS NOT NULL  AND ty =2014 AND tm=01
ORDER BY growth_in_spend DESC

-- during weekends which city has highest avg spend 
SELECT TOP 1 city, SUM(amount) total_spend, COUNT(*) no_of_transaction, FLOOR(AVG(amount)) transaction_ratio
FROM credit_card_transactions
WHERE DATEPART(WEEKDAY,transaction_date) in (1,7) 
GROUP BY city
ORDER BY transaction_ratio DESC

-- during weekends cities which has highest avg spend with more than 200 transaction records

SELECT city, SUM(amount) total_spend, COUNT(*) no_of_transaction, FLOOR(AVG(amount)) transaction_ratio
FROM credit_card_transactions
WHERE DATEPART(WEEKDAY,transaction_date) in (1,7) 
GROUP BY city
HAVING count(*) > 200
ORDER BY transaction_ratio DESC

-- which city took least number of days to reach it's 500th transaction after the first transaction in that city

WITH rn_cte AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date) rn
FROM credit_card_transactions)
SELECT TOP 1 city, datediff(day, min(transaction_date), max(transaction_date)) no_of_days
FROM rn_cte
WHERE rn = 1 or rn = 500
GROUP BY city
HAVING COUNT(*) = 2
ORDER BY no_of_days



-- What is the total spend for each card type, ranked in descending order
SELECT  card_type, SUM(amount) total_spend
FROM credit_card_transactions
GROUP BY card_type
ORDER BY total_spend DESC

-- total spend by each city
SELECT city, sum(amount) total_spend
FROM credit_card_transactions
GROUP BY city
ORDER BY total_spend desc
















