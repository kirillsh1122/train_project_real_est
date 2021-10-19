-- TASK 1

/*
 * Compute the difference between units rented in each week and previous one regarding units room quantity
 */
SELECT 	c.calendar_year,
		c.calendar_week_number,
		c.calendar_year||'-'||c.calendar_week_number AS year_week,
		p.room_qty,
		count(ua.item_id) FILTER (WHERE ua.event_type = 'deal-success') AS units_rented,
		LAG(count(ua.item_id) FILTER (WHERE ua.event_type = 'deal-success')) OVER w AS units_rented_prev_week,
		count(ua.item_id) FILTER (WHERE ua.event_type = 'deal-success') - LAG(count(ua.item_id) FILTER (WHERE ua.event_type = 'deal-success')) OVER w AS rented_difference
FROM rp.user_activity ua
LEFT JOIN rp.calendar c ON ua."date" = c."date" 
LEFT JOIN rp.property p ON ua.item_id = p.item_id
WHERE p.room_qty IS NOT NULL
GROUP BY c.calendar_year, c.calendar_week_number, p.room_qty
WINDOW w AS (PARTITION BY p.room_qty ORDER BY c.calendar_year,c.calendar_week_number)
ORDER BY c.calendar_year, c.calendar_week_number, p.room_qty;


-- TASK 2

/*
 * Find users who were included into TOP 300 based on unique objects interactions in each week simultaneously
 */
SELECT tab_4.user_id
FROM (
	SELECT 	tab_3.*,
			count(tab_3.user_id) OVER (PARTITION BY tab_3.user_id) AS user_occurances
	FROM (
		SELECT 	tab_2.*,
				DENSE_RANK() OVER (PARTITION BY tab_2.calendar_year, tab_2.calendar_week_number ORDER BY tab_2.unique_interactions DESC) AS user_rank		
			FROM (
			SELECT 	tab_1.calendar_year,
					tab_1.calendar_week_number,
					tab_1.user_id,
					count(tab_1.user_id) AS unique_interactions		
			FROM (
				SELECT 	c.calendar_year,
						c.calendar_week_number,
						ua.user_id,
						ua.item_id 
				FROM rp.user_activity ua
				LEFT JOIN rp.calendar c ON ua."date" = c."date"
				GROUP BY c.calendar_year, c.calendar_week_number, ua.user_id, ua.item_id 
				) AS tab_1
			GROUP BY tab_1.calendar_year, tab_1.calendar_week_number, tab_1.user_id
			) AS tab_2
		) AS tab_3
	WHERE tab_3.user_rank <= 100
	) AS tab_4
WHERE tab_4.user_occurances = 2
GROUP BY tab_4.user_id;


-- TASK 3

/*
 * Conduct activity analytics regarding room quantity for each week in year:
 * 	- compute unique users (unique_user_activity) who performed any actions for particular group (room_qty)
 * 	- compute unique users week difference (unique_users_week_difference) for previous bullet-point
 * 	- compute total unique users activity for each week (total_unique_users_week)
 * 	- compute total unique users activity difference for each week (total attention % difference)
 * 	- compute % users activity (attention %) for each week
 * 	- compute % users activity difference (attention % difference) for previous bullet-point
 */

SELECT 	tab_2.calendar_year,
		tab_2.calendar_week_number,
		tab_2.calendar_year||'-'||tab_2.calendar_week_number AS year_week,
		tab_2.room_qty,
		tab_2.unique_user_activity,
		tab_2.total_unique_users_week,
		tab_2.unique_users_week_difference,
		to_char(round(tab_2.attention_fraction,2),'999.99')||' %' AS "attention %",
		to_char(round(tab_2.attention_fraction_difference,2),'999.99')||' %' AS "attention % difference",
		to_char(round(tab_2.total_attention_difference,2),'999.99')||' %' AS "total attention % difference"
FROM (
	SELECT 	tab_1.calendar_year,
			tab_1.calendar_week_number,
			tab_1.room_qty,
			count(tab_1.user_id) AS unique_user_activity,
			sum(count(tab_1.user_id)) OVER w1 AS total_unique_users_week,
			LAG(count(tab_1.user_id)) OVER w2 AS unique_users_prev_week,
			count(tab_1.user_id) - LAG(count(tab_1.user_id)) OVER w2 AS unique_users_week_difference,
			count(tab_1.user_id) / sum(count(tab_1.user_id)) OVER w1 * 100 AS attention_fraction,		
			LAG(count(tab_1.user_id)) OVER w2 / sum(count(tab_1.user_id)) OVER w3 * 100 AS attention_fraction_prev_week,
			(count(tab_1.user_id) / sum(count(tab_1.user_id)) OVER w1 - LAG(count(tab_1.user_id)) OVER w2 / sum(count(tab_1.user_id)) OVER w3) * 100 AS attention_fraction_difference,
			sum(count(tab_1.user_id)) OVER w3 AS total_unique_users_prev_week,
			(sum(count(tab_1.user_id)) OVER w1 - sum(count(tab_1.user_id)) OVER w3) / sum(count(tab_1.user_id)) OVER w3 * 100 AS total_attention_difference
	FROM (
		SELECT 	c.calendar_year,
				c.calendar_week_number,
				p.room_qty,
				ua.user_id
		FROM rp.user_activity ua
		LEFT JOIN rp.calendar c ON ua."date" = c."date" 
		LEFT JOIN rp.property p ON ua.item_id = p.item_id
		WHERE p.room_qty IS NOT NULL
		GROUP BY c.calendar_year, c.calendar_week_number, p.room_qty, ua.user_id
		) AS tab_1
	GROUP BY tab_1.calendar_year, tab_1.calendar_week_number, tab_1.room_qty
	WINDOW 	w1 AS (PARTITION BY tab_1.calendar_year, tab_1.calendar_week_number),
			w2 AS (PARTITION BY tab_1.calendar_year, tab_1.room_qty ORDER BY tab_1.calendar_week_number),
			w3 AS (PARTITION BY tab_1.calendar_year ORDER BY tab_1.calendar_week_number RANGE BETWEEN 1 PRECEDING AND CURRENT ROW EXCLUDE GROUP)
	) AS tab_2
ORDER BY tab_2.calendar_year, tab_2.calendar_week_number, tab_2.room_qty;


-- TASK 4

/*
 * Show users activity dynamics through hours and compare it with the previous week
 */

SELECT	tab_2.calendar_year,
		tab_2.calendar_week_number,
		tab_2.calendar_year||'-'||tab_2.calendar_week_number AS year_week,
		tab_2."hour",
		count(tab_2.user_id) AS unique_users,
		count(tab_2.user_id) - LAG(count(tab_2.user_id)) OVER (PARTITION BY tab_2.calendar_year,tab_2."hour" ORDER BY tab_2.calendar_week_number) AS activity_difference
FROM (		
	SELECT 	tab_1.calendar_year,
			tab_1.calendar_week_number,
			tab_1."hour",
			tab_1.user_id	
	FROM (
		SELECT 	ua.*,
				EXTRACT (HOUR FROM ua."time") "hour",
				c.calendar_year,
				c.calendar_week_number
		FROM rp.user_activity ua
		LEFT JOIN rp.calendar c ON ua."date" = c."date"
		) AS tab_1
	GROUP BY tab_1.calendar_year, tab_1.calendar_week_number, tab_1."hour", tab_1.user_id
	) AS tab_2
GROUP BY tab_2.calendar_year, tab_2.calendar_week_number, tab_2."hour"
ORDER BY tab_2.calendar_year, tab_2.calendar_week_number, tab_2."hour";


-- TASK 5

/*
 * Calculate units area searched weighted average deviation from its median through each weekend and room quantity.
 */

SELECT 	tab_4.calendar_year,
		tab_4.calendar_week_number,
		tab_4.calendar_year||'-'||tab_4.calendar_week_number AS year_week,
		tab_4.room_qty,
		to_char(round(tab_4.weighted_average_area_searched,2),'999,999,999.99') AS weighted_average_area_searched,
		to_char(round(tab_5.median_area::numeric,2),'999,999,999.99') AS median_area,
		to_char(round(((tab_4.weighted_average_area_searched - tab_5.median_area)/tab_5.median_area * 100):: numeric,2),'999.99')||' %' AS deviation_from_median
	FROM (
	SELECT 	tab_3.calendar_year,
			tab_3.calendar_week_number,
			tab_3.room_qty,
			tab_3.weighted_average_area_searched
	FROM (
		SELECT 	tab_2.calendar_year,
				tab_2.calendar_week_number,
				tab_2.room_qty,
				tab_2.avg_unit_area,
				count(tab_2.avg_unit_area) AS user_avg_area_count,
				sum(tab_2.avg_unit_area*count(tab_2.avg_unit_area)) OVER w1 / sum(count(*)) OVER w1 AS  weighted_average_area_searched
		FROM (
			SELECT 	tab_1.calendar_year,
					tab_1.calendar_week_number,
					tab_1.room_qty,
					tab_1.user_id,
					avg(tab_1.unit_area) AS avg_unit_area
			FROM (
				SELECT 	c.calendar_year,
						c.calendar_week_number,
						p.room_qty,
						ua.user_id,			
						p.item_id,
						p.unit_area 
				FROM rp.user_activity ua
				LEFT JOIN rp.calendar c ON ua."date" = c."date" 
				LEFT JOIN rp.property p ON ua.item_id = p.item_id
				WHERE p.room_qty IS NOT NULL
				GROUP BY c.calendar_year, c.calendar_week_number, p.room_qty, ua.user_id, p.item_id
				) AS tab_1
			GROUP BY tab_1.calendar_year, tab_1.calendar_week_number, tab_1.room_qty, tab_1.user_id
			) AS tab_2
		GROUP BY tab_2.calendar_year, tab_2.calendar_week_number, tab_2.room_qty, tab_2.avg_unit_area
		WINDOW w1 AS (PARTITION BY tab_2.calendar_year, tab_2.calendar_week_number, tab_2.room_qty)
		) AS tab_3
	GROUP BY tab_3.calendar_year, tab_3.calendar_week_number, tab_3.room_qty, tab_3.weighted_average_area_searched
	) AS tab_4
INNER JOIN
	(
	SELECT 	p.room_qty,
			percentile_cont(0.5) WITHIN GROUP (ORDER BY p.unit_area) AS median_area
	FROM rp.property p 
	WHERE p.room_qty IS NOT NULL
	GROUP BY p.room_qty
	) AS tab_5
ON tab_4.room_qty = tab_5.room_qty;











