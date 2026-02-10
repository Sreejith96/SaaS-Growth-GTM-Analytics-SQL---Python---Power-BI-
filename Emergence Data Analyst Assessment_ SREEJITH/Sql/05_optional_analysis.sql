-- Reference #5 from 03_core_metrics.sql

CREATE VIEW core_metrics_bymonth AS
SELECT 
    FORMAT(s.start_date, 'yyyy-MM') AS month_year,
    COUNT(DISTINCT s.customer_id) AS active_customers,
    SUM(s.monthly_price) AS mrr,
    SUM(s.monthly_price) * 12 AS arr,
    ROUND(SUM(s.monthly_price) * 1 / NULLIF(COUNT(DISTINCT s.customer_id), 0), 2) AS arpc
FROM subscriptions s
WHERE s.status = 'active'  -- Lowercase consistent with your schema
GROUP BY FORMAT(s.start_date, 'yyyy-MM');

SELECT * FROM core_metrics_bymonth ORDER BY month_year DESC;

-- Reference #2 from 04_funnel_analysis.sql


