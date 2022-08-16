-- Case Study Set A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS [total_orders]
FROM pizza_runner.customer_orders

-- 2. How many unique customer orders were made?
SELECT customer_id AS [customer],
	COUNT(*) AS [orders_count]
FROM pizza_runner.customer_orders
GROUP BY customer_id

-- 3. How many successful orders were delivered by each runner?
SELECT COUNT(*) AS [successful_runner_orders]
FROM pizza_runner.runner_orders
WHERE
	pickup_time <> 'null' AND -- Excludes row(s) having 'null' value on pickup_time field
	pickup_time <> '' AND -- Excludes row(s) having '' or empty string value on pickup_time field
	pickup_time IS NOT NULL -- Excludes row(s) having NULL value on pickup_time field

-- 4. How many of each type of pizza was delivered?
SELECT CAST(pn.pizza_name AS NVARCHAR) AS [pizza_name], -- Type casted to NVARCHAR to eliminate issue #1
	COUNT(co.pizza_id) AS [pizza_order_count]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON 
	co.order_id = ro.order_id
JOIN pizza_runner.pizza_names pn
ON 
	co.pizza_id = pn.pizza_id
WHERE	
	ro.pickup_time <> 'null' AND -- Excludes row(s) having 'null' value on pickup_time field
	ro.pickup_time <> '' -- Excludes row(s) having '' or empty string value on pickup_time field
GROUP BY co.pizza_id,
	CAST(pn.pizza_name AS NVARCHAR) -- Type cast to NVARCHAR to eliminate issue #1

-- Issues encountered while running the above script on SQL Server 2017:
-- 1. The text, ntext, and image data types cannot be compared or sorted, except when using IS NULL or LIKE operator.

-- Solution(s) applied:
-- 1. Convert/Type casted pizza_runner.pizza_names.pizza_names from TEXT datatype to NVARCHAR/VARCHAR

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT co.customer_id,
	CAST(pn.pizza_name AS NVARCHAR) AS [pizza_name], 
	COUNT(co.pizza_id) AS [order_count]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.pizza_names pn
ON 
	co.pizza_id = pn.pizza_id
GROUP BY co.customer_id,
	CAST(pn.pizza_name AS NVARCHAR)
ORDER BY co.customer_id

-- Issues encountered while running the above script on SQL Server 2017:
-- 1. The text, ntext, and image data types cannot be compared or sorted, except when using IS NULL or LIKE operator.

-- Solution(s) applied:
-- 1. Convert/Type casted pizza_runner.pizza_names.pizza_names from TEXT datatype to NVARCHAR/VARCHAR

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT MAX(max_order_count) AS [max_pizza_delivered_count]
FROM (SELECT co.order_id, COUNT(co.order_id) AS [max_order_count]
		FROM pizza_runner.customer_orders co
		JOIN pizza_runner.runner_orders ro
		ON
			co.order_id = ro.order_id
		WHERE 
			ro.pickup_time <> 'null'
		GROUP BY co.order_id) subquery_tbl
-- or ...
SELECT TOP 1 COUNT(co.order_id) AS [max_pizza_delivered_count]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON
	co.order_id = ro.order_id
WHERE 
	ro.pickup_time <> 'null'
GROUP BY co.order_id
ORDER BY COUNT(co.order_id) DESC

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id,
	ro.pickup_time,
	co.pizza_id
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON 
	co.order_id = ro.order_id
JOIN pizza_runner.pizza_names pn
ON 
	co.pizza_id = pn.pizza_id
WHERE	
	ro.pickup_time <> 'null' AND -- Excludes row(s) having 'null' value on pickup_time field
	ro.pickup_time <> '' AND -- Excludes row(s) having '' or empty string value on pickup_time field
	(co.exclusions <> 'null' AND
	co.exclusions <> '') OR
	(co.extras <> 'null' AND
	co.extras <> '' AND
	co.extras IS NOT NULL)
GROUP BY co.customer_id ,
	ro.pickup_time,
	co.pizza_id

-- Solution #1: 
-- Number of pizza orders (which was successfully delivered by pizza runner) that has atleast 1 exclusions or extras in it
SELECT co.customer_id,
	COUNT(co.pizza_id) AS [w_change_count]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON
	co.order_id = ro.order_id AND
	ro.pickup_time <> 'null'
WHERE 
	(co.exclusions <> 'null' AND
	co.exclusions <> '') OR
	(co.extras <> 'null' AND
	co.extras <> '' AND
	co.extras IS NOT NULL)
GROUP BY co.customer_id

-- Number of pizza orders (which was successfully delivered by pizza runner) that didn't have any exclusions and extras in it
SELECT co.customer_id,
	COUNT(co.pizza_id) AS [wo_change_count]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON
	co.order_id = ro.order_id AND
	ro.pickup_time <> 'null'
WHERE 
	(co.exclusions = 'null' OR
	co.exclusions = '') AND
	(co.extras = 'null' OR
	co.extras = '' OR
	co.extras IS NULL)
GROUP BY co.customer_id

-- Solution #2: Joining the result of each query resulting to a single result set 
;WITH w_change_cte AS ( 
	SELECT co.customer_id,
		COUNT(co.pizza_id) AS [w_change_count]
	FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
	ON
		co.order_id = ro.order_id AND
		ro.pickup_time <> 'null'
	WHERE 
		(co.exclusions <> 'null' AND
		co.exclusions <> '') OR
		(co.extras <> 'null' AND
		co.extras <> '' AND
		co.extras IS NOT NULL)
	GROUP BY co.customer_id
), wo_change_cte AS (
	SELECT co.customer_id,
		COUNT(co.pizza_id) AS [wo_change_count]
	FROM pizza_runner.customer_orders co
	JOIN pizza_runner.runner_orders ro
	ON
		co.order_id = ro.order_id AND
		ro.pickup_time <> 'null'
	WHERE 
		(co.exclusions = 'null' OR
		co.exclusions = '') AND
		(co.extras = 'null' OR
		co.extras = '' OR
		co.extras IS NULL)
	GROUP BY co.customer_id
), customer_cte AS ( -- Distinct list of customer_id(s) from customer_orders table
	SELECT DISTINCT (customer_id)
	FROM pizza_runner.customer_orders
)

SELECT a.*,
	ISNULL(b.wo_change_count, 0) AS [wo_change_count], -- same as COALESCE(<expression>, <fall_back_value>)
	ISNULL(c.w_change_count, 0) AS w_change_count -- same as COALESCE(<expression>, <fall_back_value>)
FROM customer_cte a
LEFT JOIN wo_change_cte b
ON 
	a.customer_id = b.customer_id
LEFT JOIN w_change_cte c
ON
	a.customer_id = c.customer_id


-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(co.pizza_id) AS [w_exclusions_and_extras]
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro
ON
	co.order_id = ro.order_id AND
	ro.pickup_time <> 'null'
WHERE 
	co.exclusions <> 'null' AND
	co.exclusions <> '' AND
	co.extras <> 'null' AND
	co.extras <> '' AND
	co.extras IS NOT NULL

-- If you were expecting to get a result of 2 (with order number 9, and 10) since looking at table customer_orders,
-- they do both have exlusions and extras, then you must have forgotten that the order must be delivered first. 
-- Now if we take a look at table runner_orders, it appears that order number 9
-- was cancelled by the customer, which means it hasn't been delivered yet - resulting to 
-- one devivered order with exclusions and extras (which is order number 10)

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(HOUR, CONVERT(TIME, order_time)) AS [hour],
	COUNT(pizza_id) AS [volume]
FROM pizza_runner.customer_orders
GROUP BY DATEPART(hh, CONVERT(TIME, order_time))

-- 10. What was the volume of orders for each day of the week?
SELECT DATENAME(WEEKDAY, CONVERT(DATE, order_time)) AS [day],
	COUNT(*) AS [volume]
FROM pizza_runner.customer_orders
GROUP BY DATENAME(WEEKDAY, CONVERT(DATE, order_time))

-- Case Study Set B. Runner and Customer Experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- Week will start on Sunday
SET DATEFIRST 7 -- Sets start of week to Sunday

SELECT registration_date, 
	DATENAME(WEEKDAY, registration_date),
	DATEPART(WEEK, registration_date) AS [week]
FROM pizza_runner.runners