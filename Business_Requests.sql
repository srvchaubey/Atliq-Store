--#1)Identify high-value products with a Base proice greater than 500 featured in the 'BOGOF' (Buy One Get One Free) promotion.

SELECT distinct p.product_name, f.base_price from fact_events as f
JOIN dim_products as p on f.product_code = p.product_code
WHERE f.promo_type = "BOGOF" AND f.base_price > 500;

--#2)Provide an overview of the number of stores in each city.

SELECT city, count(store_id) as Total_stores from dim_stores
group by city
order by Total_stores DESC;

--#3)Display total revenue generated before and after each promotional campaign.

SELECT c.campaign_name, CONCAT(ROUND(SUM(f.revenue_before) / 1000000, 2), 'M') AS Revenue_Before,
						CONCAT(ROUND(SUM(f.revenue_after) / 1000000, 2), 'M') AS Revenue_After FROM fact_events as f
JOIN dim_campaigns as c ON f.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

--#4)Calculate Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.

WITH RankedData AS (
    SELECT
        p.category,
        SUM(f.ISU) AS ISU,
        ROUND(SUM(f.ISU) / SUM(f.quantity_sold_before) * 100, 2) AS 'ISU%',
        RANK() OVER (ORDER BY SUM(f.ISU) DESC) AS ISU_Rank
    FROM fact_events AS f
    JOIN dim_products AS p ON f.product_code = p.product_code
    JOIN dim_campaigns AS c ON f.campaign_id = c.campaign_id
    WHERE c.campaign_name = 'Diwali'
    GROUP BY p.category;

--#5)Identify the top 5 products ranked by Incremental Revenue Percentage (IR%) across all campaigns.

SELECT p.product_name, p.category,
		ROUND(SUM(f.IR) / SUM(f.revenue_before) * 100, 2 ) AS 'IR%',
        RANK() OVER (ORDER BY SUM(f.IR) / SUM(f.revenue_before) * 100 DESC) AS IR_Ranking
FROM fact_events as f
JOIN dim_products as p ON f.product_code = p.product_code
GROUP BY product_name, category
ORDER BY 'IR%' DESC LIMIT 5;

SELECT *FROM fact_events;
ALTER TABLE fact_events
RENAME COLUMN `quantity_sold(before_promo)` TO quantity_sold_before;
ALTER TABLE fact_events
RENAME COLUMN `quantity_sold(after_promo)` TO quantity_sold_after;

ALTER TABLE fact_events ADD revenue_before float;
UPDATE fact_events
SET revenue_before = base_price * quantity_sold_before;

ALTER TABLE fact_events ADD revenue_after float;
UPDATE fact_events
SET revenue_after = base_price * quantity_sold_after;



SELECT *FROM fact_events;
ALTER TABLE fact_events ADD ISU float;
UPDATE fact_events
SET ISU = CASE WHEN ( quantity_sold_after - quantity_sold_before) < 0 THEN 0 ELSE ( quantity_sold_after - quantity_sold_before) END;
