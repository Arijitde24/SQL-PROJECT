--1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT(customer_id)) AS Total_Customers FROM foodie_fi.subscriptions;


--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT plan_name,
DATE_TRUNC('month', start_date)::DATE AS month_start,
COUNT(*) AS trial_plan_per_month
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY plan_name,month_start
ORDER BY month_start;


--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT plan_name, EXTRACT(YEAR FROM start_date) as Year,COUNT(plan_name) as plan_count FROM foodie_fi.subscriptions as s
INNER JOIN foodie_fi.plans as p
ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY plan_name,YEAR;


--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

with churned as
(SELECT COUNT(DISTINCT(customer_id)) as customer_churned FROM foodie_fi.subscriptions as s
INNER JOIN foodie_fi.plans as p
ON p.plan_id = s.plan_id
WHERE plan_name = 'churn'), 
Total as
(SELECT COUNT(DISTINCT(customer_id)) as total_customers FROM foodie_fi.subscriptions)
SELECT customer_churned,total_customers, round((customer_churned*100.0/total_customers),1) || '%' AS churn_percentage FROM churned,Total;


--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?


WITH next_plan_cte AS

(
SELECT s.customer_id,p.plan_name,
LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) as next_plan
FROM foodie_fi.subscriptions as s
JOIN foodie_fi."plans" as p
ON s.plan_id = p.plan_id
)

SELECT COUNT(DISTINCT CASE
WHEN plan_name = 'trial' AND next_plan = 'churn'
THEN customer_id
END) AS churned_after_trial,

(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions
WHERE plan_id = 0) AS trial_customers,

(100 * COUNT(DISTINCT CASE
WHEN plan_name = 'trial' AND next_plan = 'churn'
THEN customer_id
END)
/
(SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions
WHERE plan_id = 0) 
)AS churn_percentage

FROM next_plan_cte;


--6. What is the number and percentage of customer plans after their initial free trial?

WITH next_plan_cte AS

(
SELECT s.customer_id,p.plan_name,
LEAD(p.plan_name) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) as next_plan
FROM foodie_fi.subscriptions as s
JOIN foodie_fi."plans" as p
ON s.plan_id = p.plan_id
), next_plan_clean AS
(SELECT * FROM next_plan_cte
WHERE next_plan IS NOT NULL)

SELECT plan_name,next_plan,COUNT(DISTINCT customer_id) AS customer_count,
ROUND(100.0 * COUNT(DISTINCT customer_id)
/
SUM(COUNT(DISTINCT customer_id)) OVER() 
,2) AS percentage
FROM next_plan_clean
WHERE plan_name = 'trial'
GROUP BY next_plan,plan_name
ORDER BY customer_count DESC;

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH latest_plan AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date DESC
        ) AS rn
    FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p
      ON s.plan_id = p.plan_id
    WHERE s.start_date <= '2020-12-31'
)

SELECT plan_name,COUNT(DISTINCT customer_id) AS customer_count,
ROUND(100.0 * COUNT(DISTINCT customer_id) 
/
SUM(COUNT(DISTINCT customer_id)) OVER()
,2) AS percentage
FROM latest_plan
WHERE rn = 1
GROUP BY plan_name
ORDER BY customer_count DESC;

--8. How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(customer_id) as customer_count FROM foodie_fi.subscriptions as s
JOIN foodie_fi."plans" as p
on p.plan_id = s.plan_id
where plan_name = 'pro annual'
AND s.start_date >= '2020-01-01'
AND s.start_date < '2021-01-01';

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_cte AS (
    SELECT customer_id, start_date AS trial_date
    FROM foodie_fi.subscriptions
    WHERE plan_id = 0
),
annual_cte AS (
    SELECT customer_id, start_date AS annual_date
    FROM foodie_fi.subscriptions
    WHERE plan_id = 3
)

SELECT 
    ROUND(AVG(annual_date - trial_date), 0) AS avg_days
FROM trial_cte t
JOIN annual_cte a
ON t.customer_id = a.customer_id;

--10. Can you further breakdown this average value into 30 day periods.

SELECT CASE WHEN bucket = 0 THEN '0 - 30'
			ELSE CONCAT(bucket * 30 + 1, '-', bucket * 30 + 30) 
			END AS bucket, 
			COUNT(*) as customer_count

FROM (
SELECT customer_id,FLOOR(
(
MIN(CASE WHEN plan_id = 3 Then start_date END) - 
MIN(CASE WHEN plan_id = 0 THEN start_date END)
)/30
)AS bucket
FROM foodie_fi.subscriptions
GROUP BY customer_id
HAVING(MIN(CASE WHEN plan_id = 3 Then start_date END)) IS NOT NULL
)
GROUP BY bucket;


--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH transitions AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        LEAD(p.plan_name) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS next_plan,
        LEAD(s.start_date) OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.start_date
        ) AS next_start_date
    FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p
      ON s.plan_id = p.plan_id
)

SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM transitions 
WHERE plan_name = 'pro monthly'
    AND next_plan = 'basic monthly'
    AND next_start_date >= '2020-01-01'
    AND next_start_date < '2021-01-01';


/*The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table 
with the following requirements:

monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments */

WITH base as 
(
SELECT s.customer_id,
p.plan_id,LEAD(p.plan_id) OVER (Partition By s.customer_id ORDER BY s.start_date) AS next_plan_id,
p.Plan_name,LEAD(p.plan_name) OVER (Partition By s.customer_id ORDER BY s.start_date) AS next_plan_name,
s.start_date,LEAD(s.start_date) OVER (Partition By s.customer_id ORDER BY s.start_date) AS next_start_date,
LAG(p.price) OVER (Partition By s.customer_id ORDER BY s.start_date) AS prev_price,p.price 
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi."plans" AS p
ON s.plan_id = p.plan_id
),
payments AS
(
SELECT customer_id,plan_id,plan_name,price,prev_price,
generate_series(start_date,
COALESCE(next_start_date - INTERVAL '1 day', DATE '2020-12-31'),
INTERVAL '1 month'
):: date AS payment_date
FROM base
WHERE plan_name IN ('basic monthly','pro monthly')
UNION ALL
SELECT customer_id,plan_id,plan_name,price,prev_price,start_date AS payment_date 
FROM base
WHERE plan_name = 'pro annual'
),
final_cte AS
(
SELECT customer_id,plan_id,plan_name,payment_date,
CASE 
	WHEN prev_price IS NOT NULL AND plan_name IN ('pro_monthly','pro_annual')
	THEN price - prev_price 
	ELSE price
	END
	AS amount
FROM payments
)
SELECT customer_id,plan_id,plan_name,payment_date,ROUND(amount,2) AS amount,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date)
AS payment_order
FROM final_cte
WHERE payment_date >= DATE '2020-01-01'
AND payment_date < DATE '2021-01-01'
ORDER BY customer_id ASC,payment_date ASC 
