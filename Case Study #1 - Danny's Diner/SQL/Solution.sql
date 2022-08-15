-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id AS [customer], 
	SUM(menu.price) as [total_amount]
FROM weekone.sales sales, weekone.menu menu
WHERE 
	sales.product_id = menu.product_id
GROUP BY sales.customer_id

-- Used SUM() to get the total amount (menu.price) for each customer (sales.customer_id)
-- Used JOIN to join sales table to menu table referencing it's `product_id` to get the price for each menu
-- Used AS for renaming/providing an alias to a field

-- 2. How many days has each customer visited the restaurant?
SELECT sales.customer_id AS [customer], 
	COUNT(DISTINCT sales.order_date) as [days_visited]
FROM weekone.sales
GROUP BY sales.customer_id

-- Used COUNT() to count number of date(s) (order_date)
-- Used DISTINCT to eliminate duplicate values within a field.
-- Used AS for renaming/providing an alias to a field

-- 3. What is the first item from the menu purchased by each customer?
SELECT subquery_tbl.customer, 
	subquery_tbl.first_item_purchased
FROM (SELECT sales.customer_id AS [customer], -- Start of inner/subquery ...
		 menu.product_name AS [first_item_purchased],
		 DENSE_RANK() OVER (ORDER BY sales.order_date ASC) AS [rank]
	FROM weekone.sales sales
	JOIN weekone.menu menu
	ON	
		sales.product_id = menu.product_id) subquery_tbl -- End of inner/subquery ...
WHERE 
	subquery_tbl.rank = '1'
GROUP BY subquery_tbl.customer, subquery_tbl.first_item_purchased

-- Used window function DENSE_RANK(), to rank each row within a set of partition (sales.order_date)
-- Used JOIN to join sales table to menu table referencing it's `product_id` to get menu product_name
-- Used a subquery/nested query

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 menu.product_name AS [product_name],
	COUNT(sales.product_id) AS [times_purchased]
FROM weekone.sales sales
JOIN weekone.menu menu
ON 
	sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY COUNT(sales.product_id) DESC

-- Used TOP to limit the number of rows being returned by a query
-- Used JOIN to join sales table to menu table referencing it's `product_id` to get menu product_name
-- Used COUNT() aggregate function to count the occurence of sales.product_id within a result set
-- Used ORDER BY to sort result either descending (DESC/desc) or ascending (ASC/asc)

-- 5. Which item was the most popular for each customer?
SELECT sales.customer_id AS [customer],
	menu.product_name
FROM weekone.sales sales
JOIN weekone.menu menu
ON 
	sales.product_id = menu.product_id

-- 6. Which item was purchased first by the customer after they became a member?
;WITH table_cte AS (
	SELECT members.customer_id AS [customer], 
		menu.product_name,
		DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY order_date ASC) as [rank]
	FROM weekone.sales sales, weekone.members members, weekone.menu menu
	WHERE 
		sales.customer_id = members.customer_id AND
		sales.order_date > members.join_date AND
		sales.product_id = menu.product_id
)

SELECT table_cte.customer, table_cte.product_name
FROM table_cte
WHERE
	table_cte.rank = '1'

-- 7. Which item was purchased just before the customer became a member?
;WITH table_cte AS (
	SELECT sales.customer_id AS [customer], 
		menu.product_name,
		DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS [rank],
		order_date
	FROM weekone.sales sales
	RIGHT JOIN weekone.members members
	ON
		sales.customer_id = members.customer_id AND
		sales.order_date < members.join_date
	JOIN weekone.menu menu
	ON 
		sales.product_id = menu.product_id
)

SELECT table_cte.customer,
	table_cte.product_name,
	table_cte.order_date
FROM table_cte
WHERE 
	table_cte.rank IN (SELECT MAX(table_cte.rank) 
							FROM table_cte 
							GROUP BY table_cte.customer) AND
	table_cte.customer IN (SELECT DISTINCT (table_cte.customer)
							FROM table_cte 
							GROUP BY table_cte.customer)

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id AS [customer], -- Start of inner/subquery ...
	COUNT(*) AS [total_items],
	SUM(menu.price) AS [total_amount_spent]
FROM weekone.sales sales
JOIN weekone.menu menu
ON
	sales.product_id = menu.product_id
JOIN weekone.members members
ON
	sales.customer_id = members.customer_id AND
	sales.order_date < members.join_date
WHERE 
	sales.product_id = menu.product_id
GROUP BY sales.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT subquery_tbl.customer, 
	SUM(subquery_tbl.points) as [total_points]
FROM (SELECT sales.customer_id AS [customer], -- Start of inner/subquery ...
		CASE menu.product_name
		WHEN 'sushi'
			THEN (menu.price * 10) * 2 -- Evaluates to: if item purchased is sushi, then activate the 2x multiplier
		ELSE menu.price * 10
		END AS [points]
	FROM weekone.sales sales, weekone.menu menu
	WHERE 
		sales.product_id = menu.product_id) subquery_tbl -- End of inner/subquery ...
GROUP BY subquery_tbl.customer

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT members.customer_id AS [customer],
	SUM((menu.price * 10) * 2)
FROM weekone.sales sales
JOIN weekone.menu menu
ON 
	sales.product_id = menu.product_id
JOIN weekone.members members
ON 
	sales.customer_id = members.customer_id AND
	sales.order_date >= members.join_date
WHERE DATEPART(month, sales.order_date) = 1 -- This will make sure that the computed points are for the month of January only ...
GROUP BY members.customer_id 