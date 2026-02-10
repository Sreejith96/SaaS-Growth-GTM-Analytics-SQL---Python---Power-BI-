SaaS Growth & GTM Analytics
SQL+ Python+ PBI
Author: Sreejith S. Nair

1. Overview of the Analysis
Business Problem: Leadership needs clear visibility into revenue growth, customer churn, funnel efficiency, and acquisition channel performance to make data-driven decisions.

What I Delivered:

Cleaned messy CSV data (missing values, duplicates, inconsistencies)

Calculated core SaaS metrics: MRR ($45.2K), ARR ($542K), Logo Churn (5.7%), Revenue Churn (4.2%), ARPC ($184)

| Metric        | Formula                                  | Latest (2025-12) |
| ------------- | ---------------------------------------- | ---------------- |
| MRR           | SUM(monthly_price) WHERE status='ACTIVE' | $45,230          |
| ARR           | MRR × 12                                 | $542,760         |
| Logo Churn    | Active last mo → none this mo (%)        | 5.7%             |
| Revenue Churn | Lost MRR / total MRR (%)                 | 4.2%             |
| ARPC          | MRR / active customers                   | $184             |

Built Signup → Trial → Activated → Paid → Active → Churned funnel (72% Trial→Activated drop-off)

Created executive Power BI dashboard with trends, funnel visualization, and source breakdowns

Identified Organic channel 3x better than Google for signup→paid conversion

Key Finding: Onboarding is killing growth. 72% trial drop-off costs ~$12K MRR/month.

2. Tools Used for the assessment
| Tool              | Purpose                                 | Notes/Version                  |
| ----------------- | ------------------------------------    | ----------------------------   |
| SQL Server (SSMS) | Cleaning, metrics, funnel               | SQL Server Management Studio 21|
| Python (Jupyter)  | Initial data exploration,Data validation| pandas, numpy, pyodbc          |
| Excel             | Initial data checks, salience           | Microsoft 365                  |
| Power BI Desktop  | Executive dashboard with metric trends  | Latest Desktop 2.150.1704.0    |

3. Data Issues Identified & Fixes
3.1 Data Summary:

CUSTOMERS (1,000 unique customer_ids):
├── signup_date missing/bad format: 36 rows (3.6%)
├── segment missing: 243 rows (24.3%)
├── enterprise customers: 250 (no nulls, 25%)
└── No orphan customer_ids in events/subscriptions

EVENTS:
├── Max 2 events/customer/day (94 customers affected)
├── event_type values: signup, trial_start, activated, churned
└── source populated correctly

SUBSCRIPTIONS:
├── Perfect referential integrity (0 orphans)
├── No negative prices, no illogical active subs
└── status: active (current revenue), canceled (churned)

3.2 Critical Issues Fixed:

signup_date mismatch: Customers table signup_date ≠ Events signup event date → Kept Events as source of truth for funnel

Import artifact: '1900-01-01' dates → SET TO NULL in customers.signup_date and subscriptions.end_date

Missing segments: 243 rows → Filled as 'Non-Enterprise' (24% impact on segmentation)

Event duplicates: 94 customers with multiple same-day events → Kept first occurrence per type/day

Import Note: Used SQL Server Import Wizard due to server connection issues preventing BULK INSERT.

4. Metric Definitions
| Metric        | Formula                                  | SQL Logic        			      |
| ------------- | ---------------------------------------- | -----------------------------------------|
| MRR           | SUM(monthly_price) WHERE status='ACTIVE' | SUM(monthly_price) WHERE status='ACTIVE' |
| ARR           | MRR × 12                                 | MRR * 12        			      |
| Logo Churn    | % of customers with active sub last month| churned_customers / customers_with_active|
| Revenue Churn | % of MRR lost from churning customers    | churned_mrr / total_mrr           	      |
| ARPC          | MRR / active customers                   | mrr / COUNT(DISTINCT customer_id)        |

Latest Month Results (2025-12):
MRR: $45,230  | ARR: $542,760  | Logo Churn: 5.7% | Revenue Churn: 4.2% | ARPC: $184

Trends: +12% MoM MRR growth, Q4 flatline tied to churn spike.

5. Key Insights
* Growth Bottleneck #1: 72% Trial → Activated Drop-off
Signup (1,247) → Trial (71.5%) → Activated (35%) → Paid Ever (28.5%)

* MRR Impact: +15% activation = +$6K MRR/mo

* $12K MRR/month opportunity if activation improves to 50%

* Channel Reality: Organic >> Paid
Source     | Signup→Paid | Volume Rank
-----------|-------------|--------
Organic    |    11.6%    | 2nd
Ads        |     4.0%    | 1st (High volume, low quality)

* Organic delivers 3x ROI vs Ads

*AdsHigh volume, poor conversion → Reallocate budget

Churn Signals:
Enterprise Churn: 3.2% vs SMB: 7.1%
Revenue churn (4.2%) > Logo churn (5.7%) = Downgrades happening

6. Dashboard Explanation (Data Sources: Live SQL Server views (core_metrics_monthly)
| Visual         | Purpose               | Insight                         |
| -------------- | --------------------- | ------------------------------- |
| MRR Line Chart | Monthly revenue trend | +12% MoM, Q4 plateau            |
| KPI Cards (4)  | Current health        | MRR $45K, Churn 5.7%, ARPC $184 |
| Funnel Chart   | Lifecycle conversion  | 72% Trial→Activated drop-off    |
| Source Table   | Channel ROI           | Organic 11% vs Google 4%        |
| Drop-off Pie   | User pain points      | 45% stuck in trial              |

7. Assumptions & Limitations
- Key Assumptions (Documented in SQL comments):
- Funnel priority: Events table > Customers.signup_date (more reliable)
- Missing segments → 'Unknown' (24% data loss acceptable)
- NULL end_date → Active through current month
- "Paid Ever" = Any subscription history (not just active)

Limitations:
- No product usage data
- No customer demographics (industry, company size)


8. Instructions to Reproduce
Prerequisites
MS Excel
SQL Server 2019+, SSMS
Python 3.9+ (pandas, numpy)
Power BI Desktop

Exact Steps:
1. git clone: https://github.com/Sreejith96/SaaS-Growth-GTM-Analytics-SQL---Python---Power-BI-.git
2. SSMS → New DB: CREATE DATABASE saas_analytics;
3. Run SQL **in order**:
   ├── sql/01_table_creation.sql
   ├── Import data/*.csv via SSMS Wizard
   ├── sql/02_data_cleaning.sql  
   ├── sql/03_core_metrics.sql (validate)
   └── sql/04_funnel_analysis.sql (validate)
4. Power BI → SQL Server → Import tables + views
5. Open dashboard/PowerBI.pbix → Refresh All














