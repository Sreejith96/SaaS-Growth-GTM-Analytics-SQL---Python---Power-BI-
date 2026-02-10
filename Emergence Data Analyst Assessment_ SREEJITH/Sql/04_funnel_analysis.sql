-- 04_funnel_analysis
-- FUNNEL: Signup → Trial → Activated → Paid → Churned


-- 1) OVERALL FUNNEL (Signup → Trial → Activated → Paid(Ever) → Active Now → Churned) 
;WITH event_counts AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'signup'     THEN customer_id END) AS signups,
        COUNT(DISTINCT CASE WHEN event_type = 'trial_start' THEN customer_id END) AS trial_starts,
        COUNT(DISTINCT CASE WHEN event_type = 'activated'  THEN customer_id END) AS activated_users
    FROM events
),
sub_counts AS (
    SELECT
        COUNT(DISTINCT customer_id) AS ever_paid_users,
        COUNT(DISTINCT CASE WHEN status = 'active'   THEN customer_id END) AS active_users,
        COUNT(DISTINCT CASE WHEN status = 'canceled' THEN customer_id END) AS canceled_users
    FROM subscriptions
)
SELECT stage, users, conversion_from_previous_pct
FROM (
    SELECT 1 AS sort_key, 'Signup' AS stage, ec.signups AS users, 100 AS conversion_from_previous_pct
    FROM event_counts ec

    UNION ALL
    SELECT 2, 'Trial Start', ec.trial_starts,
           ROUND(100 * ec.trial_starts / NULLIF(ec.signups, 0), 1)
    FROM event_counts ec

    UNION ALL
    SELECT 3, 'Activated', ec.activated_users,
           ROUND(100 * ec.activated_users / NULLIF(ec.trial_starts, 0), 1)
    FROM event_counts ec

    UNION ALL
    SELECT 4, 'Paid (Ever)', sc.ever_paid_users,
           ROUND(100 * sc.ever_paid_users / NULLIF(ec.activated_users, 0), 1)
    FROM event_counts ec
    CROSS JOIN sub_counts sc

    UNION ALL
    SELECT 5, 'Active Now', sc.active_users,
           ROUND(100 * sc.active_users / NULLIF(sc.ever_paid_users, 0), 1)
    FROM sub_counts sc

    UNION ALL
    SELECT 6, 'Churned (Canceled)', sc.canceled_users,
           ROUND(100 * sc.canceled_users / NULLIF(sc.ever_paid_users, 0), 1)
    FROM sub_counts sc
) u
ORDER BY u.sort_key;

-- 2) FUNNEL BY ACQUISITION SOURCE (Paid Ever + Active Now + Canceled) 

SELECT
    COALESCE(source, 'Unknown') AS source,
    COUNT(DISTINCT CASE WHEN e.event_type = 'signup'      THEN c.customer_id END) AS signups,
    COUNT(DISTINCT CASE WHEN e.event_type = 'trial_start' THEN c.customer_id END) AS trials,
    COUNT(DISTINCT CASE WHEN e.event_type = 'activated'   THEN c.customer_id END) AS activated,

    COUNT(DISTINCT CASE WHEN s.customer_id IS NOT NULL THEN c.customer_id END) AS paid_ever,
    COUNT(DISTINCT CASE WHEN s.status = 'active'         THEN c.customer_id END) AS active_now,
    COUNT(DISTINCT CASE WHEN s.status = 'canceled'       THEN c.customer_id END) AS churned_canceled,

    ROUND(
        100 * COUNT(DISTINCT CASE WHEN s.customer_id IS NOT NULL THEN c.customer_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN e.event_type = 'signup' THEN c.customer_id END), 0),
        1
    ) AS signup_to_paid_ever_pct
FROM customers c
LEFT JOIN events e
    ON e.customer_id = c.customer_id
LEFT JOIN subscriptions s
    ON s.customer_id = c.customer_id
GROUP BY COALESCE(source, 'Unknown')
ORDER BY signups DESC;


-- 3) DROP-OFF (uses ever-paid instead of active-only)
;WITH user_flags AS (
    SELECT
        e.customer_id,
        MAX(CASE WHEN e.event_type = 'signup'      THEN 1 ELSE 0 END) AS did_signup,
        MAX(CASE WHEN e.event_type = 'trial_start' THEN 1 ELSE 0 END) AS did_trial,
        MAX(CASE WHEN e.event_type = 'activated'   THEN 1 ELSE 0 END) AS did_activate,
        MAX(CASE WHEN s.customer_id IS NOT NULL    THEN 1 ELSE 0 END) AS ever_paid
    FROM events e
    LEFT JOIN subscriptions s
        ON s.customer_id = e.customer_id
    GROUP BY e.customer_id
)
SELECT
    CASE
        WHEN did_signup = 1 AND did_trial = 0 THEN 'Stuck after Signup'
        WHEN did_trial = 1 AND did_activate = 0 THEN 'Stuck in Trial'
        WHEN did_activate = 1 AND ever_paid = 0 THEN 'Stuck after Activation'
        ELSE 'Completed/Other'
    END AS dropoff_stage,
    COUNT(*) AS users,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM user_flags
GROUP BY
    CASE
        WHEN did_signup = 1 AND did_trial = 0 THEN 'Stuck after Signup'
        WHEN did_trial = 1 AND did_activate = 0 THEN 'Stuck in Trial'
        WHEN did_activate = 1 AND ever_paid = 0 THEN 'Stuck after Activation'
        ELSE 'Completed/Other'
    END
ORDER BY users DESC;