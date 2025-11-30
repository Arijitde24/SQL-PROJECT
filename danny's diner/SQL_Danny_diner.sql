SELECT * FROM dannys_diner.sales
SELECT * FROM dannys_diner.menu 
SELECT * FROM dannys_diner.members

---1. What is the total amount each customer spent at the restaurant?---

SELECT s.customer_id,SUM(m.price) AS total_price FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
ON s.product_id=m.product_id
GROUP BY s.customer_id;

---2. How many days has each customer visited the restaurant?---

SELECT customer_id,COUNT(DISTINCT order_date) AS total_price FROM dannys_diner.sales
GROUP BY customer_id;

---3. What was the first item from the menu purchased by each customer?---

WITH cte 
AS
(
SELECT s.customer_id,m.product_name,DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS number_by_order FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
)
SELECT DISTINCT customer_id, product_name
FROM cte
WHERE number_by_order = 1;

---4. What is the most purchased item on the menu and how many times was it purchased by all customers?---

SELECT TOP 1 m.product_name,COUNT(s.customer_id) AS total_orders FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_orders DESC;

---5. Which item was the most popular for each customer?---

WITH cte 
AS
(
SELECT s.customer_id,m.product_name,COUNT(s.customer_id) AS total_orders,
DENSE_RANK()OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rk FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY m.product_name,s.customer_id
)
SELECT customer_id,product_name,total_orders FROM cte
WHERE rk=1;

---6. Which item was purchased first by the customer after they became a member?---

WITH cte 
AS
(
SELECT s.customer_id,s.order_date,mb.join_date,m.product_name,
(CASE
	WHEN mb.customer_id IS NOT NULL AND s.order_date>=mb.join_date
	THEN 'Y'
	ELSE NULL
END
) AS member
FROM dannys_diner.sales as s 
INNER JOIN dannys_diner.members as mb
ON s.customer_id=mb.customer_id
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
),
cte_2
AS
(
SELECT customer_id,order_date,join_date,product_name,member,
DENSE_RANK()OVER(PARTITION BY customer_id,member ORDER BY order_date) AS member_menu
FROM cte
)
SELECT * FROM cte_2
WHERE member = 'Y' AND member_menu = 1;

---7. Which item was purchased just before the customer became a member?

WITH cte 
AS
(
SELECT s.customer_id,s.order_date,mb.join_date,m.product_name,
(CASE
	WHEN mb.customer_id IS NOT NULL AND s.order_date>=mb.join_date
	THEN 'Y'
	ELSE NULL
END
) AS member
FROM dannys_diner.sales as s 
INNER JOIN dannys_diner.members as mb
ON s.customer_id=mb.customer_id
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
),
cte_2
AS
(
SELECT customer_id,order_date,join_date,product_name,member,
DENSE_RANK()OVER(PARTITION BY customer_id,member ORDER BY order_date DESC) AS member_menu
FROM cte
)
SELECT * FROM cte_2
WHERE member IS NULL AND member_menu = 1;

---8. What is the total items and amount spent for each member before they became a member?--

SELECT mb.customer_id,COUNT(m.product_name) AS total_product
,SUM(m.price) AS total_price
FROM dannys_diner.sales as s 
LEFT JOIN dannys_diner.members as mb
ON s.customer_id=mb.customer_id
INNER JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
WHERE mb.customer_id IS NOT NULL AND s.order_date<mb.join_date
GROUP BY mb.customer_id;

---9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?---

WITH cte
AS
(
SELECT s.customer_id,m.product_name AS total_price,
CASE
	WHEN m.product_name='sushi' THEN 2*10*m.price
	ELSE 10*m.price
END
AS points 
FROM  dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
ON s.product_id=m.product_id
)
SELECT customer_id,SUM(points) AS total_points FROM cte
GROUP BY customer_id
ORDER BY total_points DESC;

---10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?---

WITH cte AS (
    SELECT 
        s.customer_id,
        m.product_name,
        m.price,
        mb.join_date,
        s.order_date,
        CASE 
            WHEN s.order_date BETWEEN mb.join_date 
                                  AND DATEADD(day, 7, mb.join_date)
                THEN m.price * 20       
            WHEN m.product_name = 'sushi'
                THEN m.price * 20       
            ELSE m.price * 10          
        END AS points
    FROM dannys_diner.sales AS s
    JOIN dannys_diner.menu AS m
        ON s.product_id = m.product_id
    JOIN dannys_diner.members AS mb
        ON s.customer_id = mb.customer_id
WHERE MONTH(s.order_date) = 1
)
SELECT 
    customer_id,
    SUM(points) AS total_points
FROM cte
GROUP BY customer_id
ORDER BY total_points DESC;

---11. customer_id,order_date,product_name,price,member in a single table

SELECT s.customer_id,s.order_date,m.product_name,m.price,
(
CASE
	WHEN mb.customer_id IS NOT NULL AND s.order_date>=mb.join_date THEN 'Y'
	ELSE 'N'
END
) AS member
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members as mb
ON s.customer_id=mb.customer_id
INNER JOIN dannys_diner.menu AS m
ON s.product_id=m.product_id;

-----12 add RANK to the above ------

with cte as
(
SELECT s.customer_id,s.order_date,m.product_name,m.price,
(
CASE
	WHEN mb.customer_id IS NOT NULL AND s.order_date>=mb.join_date THEN 'Y'
	ELSE 'N'
END
) AS member
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.members as mb
ON s.customer_id=mb.customer_id
INNER JOIN dannys_diner.menu AS m
ON s.product_id=m.product_id
)
SELECT*,
(
CASE
	WHEN member='Y' THEN DENSE_RANK()OVER(PARTITION BY customer_id,member ORDER BY order_date)
	ELSE NULL
END
)
FROM cte;