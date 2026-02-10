-- 03_core_metrics
-- Core SaaS Metrics for Leadership Dashboard

USE Emergence;

-- 1. MONTHLY RECURRING REVENUE (MRR)
-- Sum of monthly_price from ACTIVE subs each month
WITH monthly_active_subs AS (
    SELECT 
        FORMAT(start_date, 'yyyy-MM') as month_year,
        SUM(monthly_price) as mrr
    FROM subscriptions 
    WHERE status = 'ACTIVE'
      AND start_date <= EOMONTH(GETDATE())  -- Only subs that started before now
    GROUP BY FORMAT(start_date, 'yyyy-MM')
)
SELECT 
    month_year,
    ROUND(SUM(mrr), 2) as mrr,
    ROUND(SUM(mrr) * 12, 0) as arr  -- ARR = MRR * 12
FROM monthly_active_subs 
GROUP BY month_year 
ORDER BY month_year DESC;

-- 2. CUSTOMER (LOGO) CHURN RATE
-- % of unique customers who had ACTIVE sub last month but none this month
WITH monthly_active_customers AS (
    SELECT 
        c.customer_id,
        FORMAT(DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1), 'yyyy-MM') AS month_year,
        MAX(CASE WHEN s.status = 'ACTIVE' 
                 AND s.start_date <= EOMONTH(DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1))
                 AND (s.end_date >= DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1) OR s.end_date IS NULL)
            THEN 1 ELSE 0 END) AS had_active_sub
    FROM customers c
    LEFT JOIN subscriptions s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, FORMAT(DATEFROMPARTS(YEAR(s.start_date), MONTH(s.start_date), 1), 'yyyy-MM')
),
customer_churn_flags AS (
    SELECT 
        customer_id,
        month_year,
        had_active_sub,
        LAG(had_active_sub) OVER (PARTITION BY customer_id ORDER BY month_year) AS prev_month_active
    FROM monthly_active_customers
),
churn_summary AS (
    SELECT 
        month_year,
        COUNT(DISTINCT CASE WHEN had_active_sub = 1 THEN customer_id END) AS customers_with_active,
        COUNT(DISTINCT CASE WHEN prev_month_active = 1 AND had_active_sub = 0 THEN customer_id END) AS churned_customers
    FROM customer_churn_flags
    GROUP BY month_year
) 
SELECT 
    month_year,
    customers_with_active,
    churned_customers,
    ROUND(100 * churned_customers / customers_with_active, 2) AS logo_churn_pct
FROM churn_summary 
WHERE customers_with_active > 0
ORDER BY month_year DESC;


-- 3. REVENUE CHURN RATE  
-- % of MRR lost when customers churn
-- MRR Revenue Churn by Month (Customer Cohort)
WITH monthly_mrr AS (
    SELECT 
        customer_id,
        CAST(FORMAT(start_date, 'yyyy-MM-01') AS DATE) AS month_start,
        SUM(monthly_price) AS customer_mrr
    FROM subscriptions 
    WHERE status = 'active'  -- Current active subs
      AND start_date <= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)  
    GROUP BY customer_id, 
             CAST(FORMAT(start_date, 'yyyy-MM-01') AS DATE)
),
churned_customers AS (
    SELECT 
        prev.month_start,
        SUM(prev.customer_mrr) AS churned_mrr
    FROM monthly_mrr prev
    LEFT JOIN monthly_mrr curr ON prev.customer_id = curr.customer_id
                              AND curr.month_start = DATEADD(MONTH, 1, prev.month_start)
    WHERE curr.customer_mrr IS NULL  -- No MRR next month = churn
    GROUP BY prev.month_start
),
total_mrr AS (
    SELECT 
        month_start,
        SUM(customer_mrr) AS total_mrr
    FROM monthly_mrr 
    GROUP BY month_start
)
SELECT 
    FORMAT(t.month_start, 'yyyy-MM') AS month_year,
    ISNULL(t.total_mrr, 0) AS total_mrr,
    ISNULL(c.churned_mrr, 0) AS churned_mrr,
    CASE 
        WHEN t.total_mrr = 0 THEN NULL 
        ELSE ROUND(c.churned_mrr * 100 / t.total_mrr, 2) 
    END AS revenue_churn_pct
FROM total_mrr t
LEFT JOIN churned_customers c ON t.month_start = c.month_start
ORDER BY t.month_start DESC;


-- 4. AVERAGE REVENUE PER CUSTOMER (ARPC)
-- MRR / unique active customers each month
WITH monthly_metrics AS (
    SELECT 
        FORMAT(start_date, 'yyyy-MM') as month_year,
        COUNT(DISTINCT s.customer_id) as active_customers,
        SUM(s.monthly_price) as mrr
    FROM subscriptions s
    WHERE s.status = 'ACTIVE'
    GROUP BY FORMAT(start_date, 'yyyy-MM')
)
SELECT 
    month_year,
    active_customers,
    mrr,
    ROUND(mrr * 1 / active_customers, 2) as arpc
FROM monthly_metrics
ORDER BY month_year DESC;

-- 5. SUMMARY DASHBOARD QUERY (for Power BI)
-- All key metrics in one table
SELECT 
    FORMAT(s.start_date, 'yyyy-MM') as month_year,
    COUNT(DISTINCT s.customer_id) as active_customers,
    SUM(s.monthly_price) as mrr,
    SUM(s.monthly_price) * 12 as arr,
    ROUND(SUM(s.monthly_price) * 1 / COUNT(DISTINCT s.customer_id), 2) as arpc
FROM subscriptions s
WHERE s.status = 'ACTIVE'
GROUP BY FORMAT(s.start_date, 'yyyy-MM')
ORDER BY month_year DESC;
