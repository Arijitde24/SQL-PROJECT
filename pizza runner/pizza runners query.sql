SELECT * FROM pizza_runner.customer_orders;
SELECT * INTO clean_customer_orders
FROM 
(
SELECT
		order_id as order_id,
		customer_id as customer_id,
		pizza_id as pizza_id,
		CASE
			WHEN exclusions = '' OR exclusions = 'null' OR exclusions = 'NAN' THEN NULL
			ELSE exclusions
		END AS exclusions,
		
		CASE
			WHEN extras = '' OR extras = 'null' OR extras = 'NAN' THEN NULL
			ELSE extras
		END AS extras,
		order_time 
		FROM pizza_runner.customer_orders)t;
SELECT * FROM clean_customer_orders;

SELECT * FROM pizza_runner.pizza_names;

SELECT * FROM pizza_runner.pizza_recipes;

SELECT * FROM pizza_runner.pizza_toppings;

SELECT * FROM pizza_runner.runner_orders;

SELECT * 
INTO clean_runner_orders
FROM
(
    SELECT 
        order_id,
        runner_id,

        -- pickup_time
        CAST(
            CASE
                WHEN pickup_time = '' OR pickup_time = 'null' OR pickup_time = 'NaN' 
                    THEN NULL
                ELSE pickup_time
            END AS datetime
        ) AS pickup_time,

        -- distance
        CAST(
            CASE
                WHEN distance = '' OR distance = 'null' OR distance = 'NaN' 
                    THEN NULL
                ELSE REPLACE(distance, 'km', '')
            END AS decimal(5,1)
        ) AS distance,

        -- duration_in_mins
        CAST(
            CASE
                WHEN duration = '' OR duration = 'null' OR duration = 'NaN' 
                    THEN NULL
                ELSE REPLACE(
                        REPLACE(
                            REPLACE(duration, 'minutes', ''),
                        'minute', ''),
                    'mins', '')
            END AS numeric(10,2)
        ) AS duration_in_mins,

        -- cancellation
        CASE
            WHEN cancellation = '' OR cancellation = 'null' OR cancellation = 'NaN' 
                THEN NULL
            ELSE cancellation
        END AS cancellation

    FROM pizza_runner.runner_orders
) t;


SELECT * FROM clean_runner_orders ;

SELECT * FROM pizza_runner.runners;

---1. HOW MANY PIZZAS WERE ORDERED

SELECT COUNT(*) AS 'TOTAL PIZZAS ORDERED' FROM clean_customer_orders;


---2. UNIQUE CUSTOMER_ORDERS

SELECT COUNT(DISTINCT(order_id)) AS 'Total Unique order' FROM clean_customer_orders;

--- ANS: 10

---3. SUCCESFULL ORDERS DELIVERED

SELECT runner_id,COUNT(*) AS 'Successfull Deliveries' FROM clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;


---4. EACH TYPE OF PIZZA ORDERED

SELECT CAST(pn.pizza_name AS NVARCHAR(200)) as pizza_name ,COUNT(cco.pizza_id) AS 'pizza ordered' FROM clean_customer_orders as cco
INNER JOIN pizza_runner.pizza_names as pn
ON pn.pizza_id=cco.pizza_id
INNER JOIN clean_runner_orders as cro
ON cro.order_id=cco.order_id
WHERE cro.cancellation IS NULL
GROUP BY CAST(pn.pizza_name AS NVARCHAR(200));


---5. EACH TYPE OF PIZZA ORDERED BY NUMBER OF CUSTOMER

SELECT customer_id,
	SUM(
		CASE
			WHEN pizza_id=1 THEN 1
			ELSE 0
		END) AS Meatlovers,
	SUM(
		CASE
			WHEN pizza_id=2 THEN 1
			ELSE 0
		END) AS Vegeterian
			
FROM clean_customer_orders
GROUP BY customer_id
ORDER BY customer_id


---6. What was max number of pizza delivered in a single order

SELECT TOP 1 cco.order_id,COUNT(cco.pizza_id) AS n_orders FROM clean_customer_orders as cco
INNER JOIN clean_runner_orders as cro
ON cro.order_id = cco.order_id
WHERE cro.cancellation is NULL
GROUP BY cco.order_id
ORDER BY n_orders DESC;


---7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes

SELECT customer_id,
	SUM(
		CASE
			WHEN exclusions IS NOT NULL THEN 1
			ELSE 0
		END) AS with_changes,
	SUM(
		CASE
			WHEN exclusions IS NULL THEN 1
			ELSE 0
		END) AS without_changes

FROM clean_customer_orders

INNER JOIN clean_runner_orders
ON clean_customer_orders.order_id = clean_runner_orders.order_id

WHERE cancellation IS NULL
GROUP BY customer_id


---8. pizza delivered that had both exclusions and extras

SELECT cco.customer_id,COUNT(cco.order_id) AS with_exclusion_and_extras FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cro.order_id = cco.order_id
WHERE cro.cancellation IS NULL AND cco.exclusions IS NOT NULL AND cco.extras IS NOT NULL
GROUP BY cco.customer_id;


---9. what was the total number of pizzas ordered for each hour of the day

SELECT DATEPART(HOUR,order_time) AS hour_in_24_hrs,
FORMAT(order_time,'hh tt') AS hour_in_12hrs,
COUNT(*) AS number_of_pizzas
FROM clean_customer_orders
WHERE order_time IS NOT NULL
GROUP BY DATEPART(HOUR,order_time),FORMAT(order_time,'hh tt')
ORDER BY DATEPART(HOUR,order_time) ASC;


---10. Volume of orders for each day of the week

SELECT DATENAME(WEEKDAY,CAST(order_time as nvarchar)) AS day_of_week,
COUNT(*) AS number_of_pizzas
FROM clean_customer_orders
GROUP BY DATENAME(WEEKDAY,CAST(order_time as nvarchar))
ORDER BY day_of_week;

---11. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

WITH WeeklyPeriods AS (
  SELECT
    runner_id,
    registration_date,
    DATEADD(
      DAY,
      (DATEDIFF(DAY, '2021-01-01', CAST(registration_date AS DATE)) / 7) * 7,
      '2021-01-01'
    ) AS week_start
  FROM pizza_runner.runners
  WHERE registration_date >= '2021-01-01'
)
SELECT week_start,
       COUNT(*) AS runners_count
FROM WeeklyPeriods
GROUP BY week_start
ORDER BY week_start;


---12. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id,AVG(DATEDIFF(MINUTE,order_time,pickup_time)) AS avg_pickup_time FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cro.order_id=cco.order_id
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY avg_pickup_time DESC;

---13. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH cte AS
(
SELECT cco.order_id,COUNT(cco.pizza_id) AS pizzas_delivered,DATEDIFF(MINUTE,order_time,pickup_time) AS making_time FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cro.order_id=cco.order_id
WHERE cancellation IS NULL
GROUP BY cco.order_id,DATEDIFF(MINUTE,order_time,pickup_time)
)
SELECT pizzas_delivered,MAX(making_time) AS avg_making_time FROM cte
GROUP BY pizzas_delivered
ORDER BY avg_making_time DESC;

---14. What was the average distance travelled for each customer?

SELECT cco.customer_id,AVG(cro.distance) AS avg_distance FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cco.order_id=cro.order_id
GROUP BY cco.customer_id
ORDER BY avg_distance DESC;

---15. What was the difference between the longest and shortest delivery times for all orders?

SELECT (MAX(duration_in_mins) - MIN(duration_in_mins)) AS min_max_diff FROM clean_runner_orders

---16. What was the average speed for each runner for each delivery and do you notice any trend for these values

SELECT
    runner_id,
    order_id,
    distance,
    duration_in_mins,
    ROUND(distance / (duration_in_mins / 60.0), 2) AS speed_kmph
FROM clean_runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;

---17. What is the successful delivery percentage for each runner?

WITH cte
AS
(
SELECT runner_id,COUNT(order_id) AS successful_deliveries FROM clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
),
cte2 
AS
(
SELECT runner_id,COUNT(order_id) AS Total_orders FROM clean_runner_orders
GROUP BY runner_id
)
SELECT cte.runner_id,
CAST(successful_deliveries * 100.0 / total_orders AS DECIMAL(5,2)) AS pct_successful_deliveries FROM cte
INNER JOIN cte2
ON cte.runner_id=cte2.runner_id;


--18. What are the standard ingredients for each pizza?

SELECT 
    pn.pizza_id,   -- Select the pizza ID
    CAST(pn.pizza_name AS VARCHAR(MAX)) AS pizza_name,  -- Convert pizza name to VARCHAR(MAX)

    -- Combine all topping names into one comma-separated string
    STRING_AGG(CAST(pt.topping_name AS VARCHAR(MAX)), ', ')
        WITHIN GROUP (ORDER BY pt.topping_id)  -- Ensure toppings appear in a sorted, consistent order
        AS standard_ingredients

FROM pizza_runner.pizza_names pn   -- Main table: list of pizzas

INNER JOIN pizza_runner.pizza_recipes pr 
    ON pn.pizza_id = pr.pizza_id   -- Join to recipes table to get topping ID list (e.g., '1, 2, 3')

-- Split the toppings string into individual topping IDs
CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS VARCHAR(MAX)), ',') AS ts  

INNER JOIN pizza_runner.pizza_toppings pt 
    ON TRY_CAST(LTRIM(RTRIM(ts.value)) AS INT) = pt.topping_id  
    -- Clean each split value, convert to INT, match with topping_id to get topping names

GROUP BY 
    pn.pizza_id,
    CAST(pn.pizza_name AS VARCHAR(MAX))   -- Required because we used STRING_AGG

ORDER BY 
    pn.pizza_id;   -- Output sorted by pizza ID

---19. What was the most commonly added extra?

SELECT TOP 1
    pt.topping_id,
    CAST(pt.topping_name AS VARCHAR(MAX)) AS topping_name,
    COUNT(*) AS extra_count
FROM pizza_runner.customer_orders co
CROSS APPLY STRING_SPLIT(CAST(co.extras AS VARCHAR(MAX)), ',') es
JOIN pizza_runner.pizza_toppings pt
    ON TRY_CAST(LTRIM(RTRIM(CAST(es.value AS VARCHAR(MAX)))) AS INT) = pt.topping_id
WHERE co.extras IS NOT NULL 
  AND co.extras <> ''
GROUP BY 
    pt.topping_id,
    CAST(pt.topping_name AS VARCHAR(MAX))
ORDER BY extra_count DESC;

---20. What was the most common exclusion?

SELECT TOP 1
    pt.topping_id,
    CAST(pt.topping_name AS VARCHAR(MAX)) AS topping_name,
    COUNT(*) AS exclusion_count
FROM pizza_runner.customer_orders co
CROSS APPLY STRING_SPLIT(CAST(co.exclusions AS VARCHAR(MAX)), ',') es
JOIN pizza_runner.pizza_toppings pt
    ON TRY_CAST(LTRIM(RTRIM(CAST(es.value AS VARCHAR(MAX)))) AS INT) = pt.topping_id
WHERE co.exclusions IS NOT NULL 
  AND co.exclusions <> ''
GROUP BY 
    pt.topping_id,
    CAST(pt.topping_name AS VARCHAR(MAX))
ORDER BY exclusion_count DESC;


/*21. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

WITH cte AS (
    SELECT 
        co.order_id,
        CAST(pn.pizza_name AS VARCHAR(MAX)) AS pizza_name,

        -- Exclusions list
        (
            SELECT STRING_AGG(CAST(pt.topping_name AS VARCHAR(MAX)), ', ') 
            FROM STRING_SPLIT(CAST(co.exclusions AS VARCHAR(MAX)), ',') s
            JOIN pizza_runner.pizza_toppings pt
                ON TRY_CAST(LTRIM(RTRIM(s.value)) AS INT) = pt.topping_id
        ) AS exclusion_list,

        -- Extras list
        (
            SELECT STRING_AGG(CAST(pt.topping_name AS VARCHAR(MAX)), ', ') 
            FROM STRING_SPLIT(CAST(co.extras AS VARCHAR(MAX)), ',') s
            JOIN pizza_runner.pizza_toppings pt
                ON TRY_CAST(LTRIM(RTRIM(s.value)) AS INT) = pt.topping_id
        ) AS extras_list
    FROM clean_customer_orders co
    JOIN pizza_runner.pizza_names pn 
        ON co.pizza_id = pn.pizza_id
)
SELECT 
    order_id,
    CASE
        WHEN exclusion_list IS NOT NULL AND extras_list IS NOT NULL
            THEN pizza_name + ' - Exclude ' + exclusion_list + ' - Extra ' + extras_list
        WHEN exclusion_list IS NOT NULL
            THEN pizza_name + ' - Exclude ' + exclusion_list
        WHEN extras_list IS NOT NULL
            THEN pizza_name + ' - Extra ' + extras_list
        ELSE pizza_name
    END AS order_item
FROM cte;

/*22. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
*/

-- Combine base toppings, remove exclusions, add extras, and handle duplicates
-- Step 1: Combine base toppings (minus exclusions) and extras

WITH combined_toppings AS (
    -- Base toppings minus exclusions
    SELECT
        co.order_id,
        CAST(TRIM(value) AS VARCHAR(10)) AS topping_id
    FROM clean_customer_orders co
    INNER JOIN pizza_runner.pizza_recipes pr 
        ON co.pizza_id = pr.pizza_id
    CROSS APPLY STRING_SPLIT(CAST(pr.toppings AS VARCHAR(MAX)), ',') AS t
    WHERE CAST(TRIM(value) AS VARCHAR(10)) NOT IN (
        SELECT CAST(TRIM(value) AS VARCHAR(10))
        FROM STRING_SPLIT(CAST(ISNULL(co.exclusions, '') AS VARCHAR(MAX)), ',')
        WHERE value != ''
    )

    UNION ALL

    -- Extras
    SELECT
        co.order_id,
        CAST(TRIM(value) AS VARCHAR(10)) AS topping_id
    FROM clean_customer_orders co
    CROSS APPLY STRING_SPLIT(CAST(ISNULL(co.extras, '') AS VARCHAR(MAX)), ',') AS e
    WHERE value != ''
),

-- Step 2: Join with topping names and count duplicates
topping_counts AS (
    SELECT
        ct.order_id,
        CAST(pt.topping_name AS VARCHAR(MAX)) AS topping_name,
        COUNT(*) AS qty,
        CASE 
            WHEN COUNT(*) > 1 
            THEN '2x ' + CAST(pt.topping_name AS VARCHAR(MAX))
            ELSE CAST(pt.topping_name AS VARCHAR(MAX))
        END AS display_name
    FROM combined_toppings ct
    INNER JOIN pizza_runner.pizza_toppings pt 
        ON TRY_CAST(ct.topping_id AS INT) = pt.topping_id
    GROUP BY 
        ct.order_id, 
        CAST(pt.topping_name AS VARCHAR(MAX))   -- FIXED: cast added here
)

-- Step 3: Aggregate toppings
SELECT
    order_id,
    STRING_AGG(display_name, ', ') AS ingredients
FROM topping_counts
GROUP BY order_id
ORDER BY order_id;


---23. Total quantity of each ingredient used in delivered pizzas---

WITH fixed_customer AS (
    SELECT
        order_id,
        pizza_id,
        CONVERT(VARCHAR(255), exclusions) AS exclusions,
        CONVERT(VARCHAR(255), extras) AS extras
    FROM clean_customer_orders
),

fixed_recipes AS (
    SELECT
        pizza_id,
        CONVERT(VARCHAR(255), toppings) AS toppings
    FROM pizza_runner.pizza_recipes
),

fixed_toppings AS (
    SELECT
        topping_id,
        CONVERT(VARCHAR(255), topping_name) AS topping_name
    FROM pizza_runner.pizza_toppings
),

delivered_orders AS (
    SELECT DISTINCT fc.order_id
    FROM fixed_customer fc
    JOIN clean_runner_orders ro 
        ON fc.order_id = ro.order_id
    WHERE ISNULL(ro.cancellation, '') = ''
),

base_toppings AS (
    SELECT 
        fc.order_id,
        fc.pizza_id,
        LTRIM(RTRIM(t.value)) AS topping_id
    FROM fixed_customer fc
    JOIN delivered_orders d ON fc.order_id = d.order_id
    JOIN fixed_recipes fr ON fc.pizza_id = fr.pizza_id
    CROSS APPLY STRING_SPLIT(fr.toppings, ',') t
),

excluded_toppings AS (
    SELECT 
        fc.order_id,
        fc.pizza_id,
        LTRIM(RTRIM(e.value)) AS topping_id
    FROM fixed_customer fc
    JOIN delivered_orders d ON fc.order_id = d.order_id
    CROSS APPLY STRING_SPLIT(ISNULL(fc.exclusions, ''), ',') e
    WHERE e.value <> ''
),

extra_toppings AS (
    SELECT 
        fc.order_id,
        fc.pizza_id,
        LTRIM(RTRIM(x.value)) AS topping_id
    FROM fixed_customer fc
    JOIN delivered_orders d ON fc.order_id = d.order_id
    CROSS APPLY STRING_SPLIT(ISNULL(fc.extras, ''), ',') x
    WHERE x.value <> ''
),

final_ingredients AS (
    SELECT * 
    FROM base_toppings b
    WHERE NOT EXISTS (
        SELECT 1 
        FROM excluded_toppings e
        WHERE b.order_id = e.order_id
          AND b.pizza_id = e.pizza_id
          AND b.topping_id = e.topping_id
    )

    UNION ALL

    SELECT * FROM extra_toppings
)

SELECT 
    ft.topping_name,
    COUNT(*) AS ingredient_count
FROM final_ingredients fi
JOIN fixed_toppings ft 
    ON TRY_CAST(fi.topping_id AS INT) = ft.topping_id
GROUP BY ft.topping_name
ORDER BY ingredient_count DESC;

---24. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

WITH cte AS
(
SELECT runner_id,pizza_name,
(
CASE

	WHEN pizza_name LIKE 'Meatlovers' THEN 12
	ELSE 10
END
) AS [price($)]
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cco.order_id=cro.order_id
INNER JOIN pizza_runner.pizza_names AS pn
ON cco.pizza_id=pn.pizza_id
)
SELECT runner_id,SUM([price($)]) AS [total_earned($)] FROM cte
GROUP BY runner_id
ORDER BY [total_earned($)] DESC;

---25. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra

WITH cte AS
(
SELECT runner_id,pizza_name,extras,
(
CASE

	WHEN pizza_name LIKE 'Meatlovers' THEN 12
	ELSE 10
END
) AS [price($)],
(
CASE 
	WHEN extras IS NOT NULL THEN 
	(LEN(extras)-LEN(REPLACE(extras, ',', '')) + 1) * 1
	ELSE 0
END
) AS [extra_price($)]
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
ON cco.order_id=cro.order_id
INNER JOIN pizza_runner.pizza_names AS pn
ON cco.pizza_id=pn.pizza_id
),cte2 AS
(
SELECT *,([price($)]+[extra_price($)]) AS total_price FROM cte
)
SELECT runner_id,SUM(total_price) AS [total_earned($)] FROM cte2
GROUP BY runner_id;


---26 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE pizza_runner.rating

SELECT order_id,
    customer_id,
    pizza_id,
    order_time INTO pizza_runner.rating
FROM clean_customer_orders 

ALTER TABLE pizza_runner.rating
	ADD rating FLOAT

-- Add row numbers to match ratings
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY order_time) AS rn
    FROM pizza_runner.rating
),
ratings AS (
    SELECT rating_value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM (VALUES
        (3),(4),(5),(3.5),(4.5),(2.5),
        (3),(3.5),(4.5),(4),(5),(2.5),(4),(3.5)
    ) AS t(rating_value)
)
UPDATE c
SET c.rating = r.rating_value
FROM cte c
JOIN ratings r
    ON c.rn = r.rn;

UPDATE r
SET r.rating = NULL
FROM pizza_runner.rating r
INNER JOIN clean_runner_orders cro
    ON r.order_id = cro.order_id
WHERE cro.cancellation IS NOT NULL;



SELECT * FROM pizza_runner.rating

/* 27. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas */

SELECT customer_id,r.order_id,runner_id,rating,order_time,pickup_time,DATEDIFF(MINUTE,order_time,pickup_time) AS [Time between order and pickup],duration_in_mins,
(cro.distance / (cro.duration_in_mins / 60.0)) AS [avg_speed(kmph)],COUNT(pizza_id) OVER (PARTITION BY r.order_id) AS Total_pizzas
FROM pizza_runner.rating r
INNER JOIN clean_runner_orders cro
ON cro.order_id=r.order_id;


---28.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH cte AS (
    SELECT 
        runner_id,
        pizza_name,
        distance,
        CASE
            WHEN pizza_name LIKE 'Meatlovers' THEN 12
            ELSE 10
        END AS price,
        0.3 AS delivery_charge_per_KM,
        (0.3 * distance) AS total_delivery_charge
    FROM clean_customer_orders cco
    INNER JOIN clean_runner_orders cro
        ON cco.order_id = cro.order_id
    INNER JOIN pizza_runner.pizza_names pn
        ON cco.pizza_id = pn.pizza_id
    WHERE cro.cancellation IS NULL  -- successful deliveries only
),
cte2 AS (
    SELECT *,
           (price - total_delivery_charge) AS profit_per_delivery
    FROM cte
)
S ELECT SUM(profit_per_delivery) AS total_profit
FROM cte2;
