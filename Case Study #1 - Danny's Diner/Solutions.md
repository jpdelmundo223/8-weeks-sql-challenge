## Case Study #1 - Danny's Diner (Solutions)

---

### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT sales.customer_id AS [customer],
	SUM(menu.price) as [total_amount]
FROM weekone.sales sales, weekone.menu menu
WHERE
	sales.product_id = menu.product_id
GROUP BY sales.customer_id
```

_Output:_
| customer | total_amount |
|---|---|
| A | $76 |
| B | $74 |
| C | $36 |

#### <strong>Notes:</strong>

- Used [SUM()](https://docs.microsoft.com/en-us/sql/t-sql/functions/sum-transact-sql?view=sql-server-ver16), to get the total amount (menu.price) for each customer (sales.customer_id)
- Used `DISTINCT`, to eliminate duplicate values within a field.
- Used `AS`, for renaming/providing an alias to a field

### 2. How many days has each customer visited the restaurant?

```sql
SELECT sales.customer_id AS [customer],
	COUNT(DISTINCT sales.order_date) as [days_visited]
FROM weekone.sales
GROUP BY sales.customer_id
```

_Output:_
| customer | days_visited |
|---|---|
| A | 4 |
| B | 6 |
| C | 2 |

### 3. What is the first item from the menu purchased by each customer?

```sql
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
GROUP BY subquery_tbl.customer,
	subquery_tbl.first_item_purchased
```

_Output:_
| customer | first_item_purchased |
|---|---|
| A | curry |
| A | sushi |
| B | curry |
| C | ramen |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
SELECT TOP 1 menu.product_name AS [product_name],
	COUNT(sales.product_id) AS [times_purchased]
FROM weekone.sales sales
JOIN weekone.menu menu
ON
	sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY COUNT(sales.product_id) DESC
```

_Output:_
| product_name | times_purchased |
|---|---|
| ramen | 8 |

### 5. Which item was the most popular for each customer?

```sql
;WITH favorite_item_cte AS (
	SELECT sales.customer_id AS [customer],
		menu.product_name,
		COUNT(menu.product_name) AS [product_count],
		DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(menu.product_name) DESC) AS [rank]
	FROM weekone.sales sales
	JOIN weekone.menu menu
	ON
		sales.product_id = menu.product_id
	GROUP BY sales.customer_id, menu.product_name
)

SELECT favorite_item_cte.customer,
	favorite_item_cte.product_name
FROM favorite_item_cte
WHERE favorite_item_cte.rank = '1'
```

_Output:_
| customer | favorite_item_on_menu |
|---|---|
| A | ramen |
| B | sushi |
| B | curry |
| B | ramen |
| C | ramen |

### 6. Which item was purchased first by the customer after they became a member?

```sql
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
```

_Output:_
| customer | product_name |
|---|---|
| A | ramen |
| B | sushi |

### 7. Which item was purchased just before the customer became a member?

```sql
;WITH table_cte AS (
	SELECT sales.customer_id AS [customer],
		menu.product_name,
		DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS [rank],
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
	table_cte.product_name
FROM table_cte
WHERE
	table_cte.rank = '1'
```

_Output:_
| customer | product_name |
|---|---|
| A | sushi |
| A | curry |
| B | sushi |

### 8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT sales.customer_id AS [customer],
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
```

_Output:_
| customer | total_items | total_amount_spent |
|---|---|---|
| A | 2 | $25 |
| B | 3 | $40 |

### 9. If each $1 spent equates to points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
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
```

_Output:_
| customer | total_points |
|---|---|
| A | 860 |
| B | 940 |
| B | 360 |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
SELECT members.customer_id AS [customer],
	SUM((menu.price * 10) * 2) AS [total_points]
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
```

_Output:_
| customer | total_points |
|---|---|
| A | 1020 |
| B | 440 |
