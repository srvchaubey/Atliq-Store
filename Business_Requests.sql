--#Identify high-value products with a Base proice greater than 500 featured in the 'BOGOF' (Buy One Get One Free) promotion.

SELECT distinct p.product_name, f.base_price from fact_events as f
JOIN dim_products as p on f.product_code = p.product_code
WHERE f.promo_type = "BOGOF" AND f.base_price > 500;

--# Provide an overview of the number of stores in each city.

SELECT city, count(store_id) as Total_stores from dim_stores
group by city
order by Total_stores DESC;


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

--#Display total revenue generated before and after each promotional campaign.

SELECT c.campaign_name, CONCAT(ROUND(SUM(f.revenue_before) / 1000000, 2), 'M') AS Revenue_Before,
						CONCAT(ROUND(SUM(f.revenue_after) / 1000000, 2), 'M') AS Revenue_After FROM fact_events as f
JOIN dim_campaigns as c ON f.campaign_id = c.campaign_id
GROUP BY c.campaign_name;

SELECT *FROM fact_events;
ALTER TABLE fact_events ADD ISU float;
UPDATE fact_events
SET ISU = CASE WHEN ( quantity_sold_after - quantity_sold_before) < 0 THEN 0 ELSE ( quantity_sold_after - quantity_sold_before) END;

--#Calculate Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.

SELECT p.category, 
	sum(f.ISU) AS ISU, round(SUM(f.ISU) / SUM(f.quantity_sold_before) * 100,2) AS 'ISU%' FROM fact_events as f
JOIN dim_products AS p on f.product_code = p.product_code
JOIN dim_campaigns as c on f.campaign_id = c.campaign_id
WHERE c.campaign_name = 'Diwali'
GROUP BY p.category
ORDER BY 'ISU%' ASC;
