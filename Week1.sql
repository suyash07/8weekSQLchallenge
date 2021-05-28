--What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id, 
	SUM(m.price) AS [Total amount spent]
	FROM 
sales AS s JOIN
menu AS m ON
s.product_id = m.product_id
	GROUP BY s.customer_id
ORDER BY s.customer_id;

GO
--How many days has each customer visited the restaurant?

SELECT 
		customer_id, 
		COUNT(order_date) AS [Number of Days Visited]
	FROM
		sales
	GROUP BY 
		customer_id;

GO

--What was the first item from the menu purchased by each customer?

WITH cte 
AS 
(
	SELECT 
			customer_id,
			order_date,
			product_id,
			ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS [order_rank]
		FROM 
			sales
)

SELECT c.customer_id,m.product_name
	FROM 
		cte	AS	c 
	JOIN
		menu AS	m 
	ON
		c.product_id = m.product_id
	WHERE
		order_rank = 1;

GO

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte
AS
(
SELECT 
		product_id
		,COUNT(product_id) AS [Count]
		,RANK() OVER (ORDER BY COUNT(product_id) DESC) AS [order_rank]
	FROM
		sales
	GROUP BY 
		product_id
)
SELECT 
		s.customer_id AS [Customer]
		,m.product_name AS [Most Purchased Product]
		,COUNT(s.product_id) AS [Number of Times Product Purchased]
	FROM 
		cte c 
	JOIN
		sales s 
	ON 
		c.product_id = s.product_id
	JOIN
		menu m
	ON
		m.product_id = s.product_id
	WHERE 
		order_rank = 1
	GROUP BY 
		m.product_name,s.customer_id

GO

--Which item was the most popular for each customer?
WITH cte
AS
(
SELECT 
		product_id
		,COUNT(product_id) AS [Count]
		,RANK() OVER (ORDER BY COUNT(product_id) DESC) AS [order_rank]
	FROM
		sales
	GROUP BY 
		product_id
)
SELECT 
		s.customer_id AS [Customer]
		,m.product_name AS [Most Popular Product]
	FROM 
		cte c 
	JOIN
		sales s 
	ON 
		c.product_id = s.product_id
	JOIN
		menu m
	ON
		m.product_id = s.product_id
	WHERE 
		order_rank = 1
	GROUP BY 
		m.product_name,s.customer_id
GO
-- Which item was purchased first by the customer after they became a member?
WITH cte
AS
(
SELECT 
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date) as rnk
		,customer_id
		,product_name
    FROM 
(SELECT 
		sales.customer_id
		,product_name
		,order_date
	FROM 
		sales 
	JOIN 
		members
    ON 
		sales.customer_id = members.customer_id
    JOIN 
		menu
    ON 
		sales.product_id = menu.product_id
    WHERE 
		order_date >= join_date
) AS t
)

SELECT 
		customer_id
		,product_name
	FROM 
		cte
	WHERE 
		rnk = 1;
GO

--Which item was purchased just before the customer became a member?
WITH cte
AS
(
SELECT 
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) as rnk
		,customer_id
		,product_name
    FROM 
(SELECT 
		sales.customer_id
		,product_name
		,order_date
	FROM 
		sales 
	JOIN 
		members
    ON 
		sales.customer_id = members.customer_id
    JOIN 
		menu
    ON 
		sales.product_id = menu.product_id
    WHERE 
		order_date < join_date
) AS t
)

SELECT 
		customer_id
		,product_name
	FROM 
		cte
	WHERE 
		rnk = 1;

--What is the total items and amount spent for each member before they became a member?
SELECT 
		s.customer_id
		,COUNT(s.product_id) AS num_of_orders
		,SUM(m.price) AS total_amt_spent
	FROM 
		sales AS s
	JOIN
		menu AS m
	ON
		s.product_id = m.product_id
	JOIN
		members mem
	ON
		mem.customer_id = s.customer_id
	WHERE 
		s.order_date < mem.join_date
	GROUP BY
		s.customer_id;
GO
--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
		s.customer_id
		,SUM(CASE
			WHEN
				m.product_name = 'sushi'
			THEN
				m.price * 20
			ELSE
				m.price * 10
			END
			) AS total_points	
	FROM 
		sales AS s
	JOIN
		menu AS m
	ON
		s.product_id = m.product_id
	GROUP BY
		s.customer_id;

/*
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?
*/
SELECT 
		s.customer_id
		,SUM(CASE 
                WHEN
					product_name = 'sushi' 
				THEN 
					20 * price
                WHEN 
					order_date BETWEEN join_date AND DATEADD(dd, 7, join_date)
				THEN 
					20 * price
                ELSE 
					10 * price
            END) AS total_points	
	FROM 
		sales AS s
	JOIN
		menu AS m
	ON
		s.product_id = m.product_id
	JOIN
		members AS mem
	ON
		mem.customer_id = s.customer_id
	WHERE
		s.order_date <= '2021-01-31'
	GROUP BY
		s.customer_id;