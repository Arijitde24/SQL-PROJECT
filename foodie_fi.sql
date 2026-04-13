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
SELECT customer_churned,total_customers, round((customer_churned*100.0/total_customers),1) || '%' AS churn_percentage FROM churned,Total











