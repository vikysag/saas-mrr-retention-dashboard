WITH base_subs AS (
  SELECT
    subscription_id,
    account_id,
    plan_tier,
    start_date,
    COALESCE(end_date, DATE '2024-12-31') AS end_date,
    mrr_amount,
    is_trial,
    churn_flag,
    upgrade_flag,
    downgrade_flag
  FROM `subscription_and_churn_analytics.ravenstack_subscriptions`
  WHERE mrr_amount > 0 AND is_trial = FALSE
),


-- Expanded monthly MRR rows

mrr AS (
  SELECT
    subscription_id,
    account_id,
    plan_tier,
    start_date,
    end_date,
    DATE_ADD(start_date, INTERVAL nkl MONTH) AS mrr_month,
    DATE_DIFF(end_date, DATE_ADD(start_date, INTERVAL nkl MONTH), MONTH) AS d_f,
    EXTRACT(YEAR  FROM DATE_ADD(start_date, INTERVAL nkl MONTH)) AS year,
    EXTRACT(MONTH FROM DATE_ADD(start_date, INTERVAL nkl MONTH)) AS month,
    mrr_amount,
    churn_flag,
    upgrade_flag,
    downgrade_flag
  FROM base_subs
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, DATE_DIFF(end_date, start_date, MONTH))) AS nkl
),


-- Monthly MRR by account_id

mrr_by_account_id AS (
  SELECT
    account_id,
    year,
    month,
    MAX(plan_tier) AS plan_tier,
    SUM(mrr_amount) AS total_account_monthly_mrr
  FROM mrr
  GROUP BY account_id, year, month
),


-- New MRR (first paid month only)

first_paid_month AS (
  SELECT
    account_id,
    DATE_TRUNC(MIN(start_date), MONTH) AS first_month
  FROM base_subs
  GROUP BY account_id
),
new_mrr AS (
  SELECT
    s.account_id,
    EXTRACT(YEAR  FROM s.start_date) AS year,
    EXTRACT(MONTH FROM s.start_date) AS month,
    SUM(s.mrr_amount) AS total_new_mrr
  FROM base_subs s
  JOIN first_paid_month f USING (account_id)
  WHERE DATE_TRUNC(s.start_date, MONTH) = f.first_month
  GROUP BY 1,2,3
),


-- Churn, Expansion, Contraction

churn_mrr AS (
  SELECT
    account_id,
    EXTRACT(YEAR  FROM DATE_ADD(end_date, INTERVAL 1 MONTH)) AS year,
    EXTRACT(MONTH FROM DATE_ADD(end_date, INTERVAL 1 MONTH)) AS month,
    SUM(mrr_amount) AS total_churn_mrr
  FROM base_subs
  WHERE churn_flag = TRUE
  GROUP BY account_id, year, month
),

expansion_mrr AS (
  SELECT
    account_id,
    EXTRACT(YEAR  FROM start_date) AS year,
    EXTRACT(MONTH FROM start_date) AS month,
    SUM(mrr_amount) AS total_expansion_mrr
  FROM base_subs
  WHERE upgrade_flag = TRUE AND downgrade_flag = FALSE
  GROUP BY account_id, year, month
),

contraction_mrr AS (
  SELECT
    account_id,
    EXTRACT(YEAR  FROM start_date) AS year,
    EXTRACT(MONTH FROM start_date) AS month,
    SUM(mrr_amount) AS total_contraction_mrr
  FROM base_subs
  WHERE downgrade_flag = TRUE AND upgrade_flag = FALSE
  GROUP BY account_id, year, month
),


-- Month grid per account (Jan 2023 - Dec 2024)

tab_c_1 AS (
  SELECT
    a.account_id,
    DATE_ADD(DATE '2023-01-01', INTERVAL nm MONTH) AS dat,
    EXTRACT(MONTH FROM DATE_ADD(DATE '2023-01-01', INTERVAL nm MONTH)) AS c_m,
    EXTRACT(YEAR  FROM DATE_ADD(DATE '2023-01-01', INTERVAL nm MONTH)) AS c_y
  FROM (SELECT DISTINCT account_id FROM base_subs) a
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, 24)) AS nm
),


-- Combine all components

all_mrr AS (
  SELECT DISTINCT
    a.account_id,
    a.c_y AS year,
    a.c_m AS month,
    DATE(a.c_y, a.c_m, 1) AS month_date,
    COALESCE(f.plan_tier, 'Unknown') AS plan_tier,
    COALESCE(f.total_account_monthly_mrr, 0) AS total_monthly_mrr,
    COALESCE(b.total_new_mrr, 0)        AS total_new_mrr,
    COALESCE(c.total_churn_mrr, 0)      AS total_churn_mrr,
    COALESCE(d.total_expansion_mrr, 0)  AS total_expansion_mrr,
    COALESCE(e.total_contraction_mrr,0) AS total_contraction_mrr
  FROM tab_c_1 a
  LEFT JOIN new_mrr         b ON a.account_id = b.account_id AND a.c_y = b.year AND a.c_m = b.month
  LEFT JOIN churn_mrr       c ON a.account_id = c.account_id AND a.c_y = c.year AND a.c_m = c.month
  LEFT JOIN expansion_mrr   d ON a.account_id = d.account_id AND a.c_y = d.year AND a.c_m = d.month
  LEFT JOIN contraction_mrr e ON a.account_id = e.account_id AND a.c_y = e.year AND a.c_m = e.month
  LEFT JOIN mrr_by_account_id f ON a.account_id = f.account_id AND a.c_y = f.year AND a.c_m = f.month
  WHERE a.c_y <= 2024
),


-- Net New MRR

net_new_mrr AS (
  SELECT
    account_id,
    year,
    month,
    (COALESCE(total_new_mrr,0)
     + COALESCE(total_expansion_mrr,0)
     - COALESCE(total_contraction_mrr,0)
     - COALESCE(total_churn_mrr,0)) AS new_net_mrr
  FROM all_mrr
),


-- Account-level view (core for Tableau)

sd AS (
  SELECT
    account_id,
    plan_tier,
    year,
    month,
    month_date,
    COALESCE(LAG(total_monthly_mrr) OVER (PARTITION BY account_id ORDER BY year, month), 0) AS opening_mrr,
    COALESCE(total_expansion_mrr, 0)  AS expansion_mrr,
    COALESCE(total_contraction_mrr, 0) AS contraction_mrr,
    COALESCE(total_churn_mrr, 0)       AS churn_mrr,
    COALESCE(total_monthly_mrr, 0)     AS closing_mrr
  FROM all_mrr
),

acct_level AS (
  SELECT
    s.account_id,
    s.plan_tier,
    s.year,
    s.month,
    s.month_date,
    s.opening_mrr,
    s.expansion_mrr,
    s.contraction_mrr,
    s.churn_mrr,
    COALESCE(n.new_net_mrr, 0)        AS net_new_mrr,
    s.closing_mrr,

-- Ratios
    SAFE_DIVIDE(s.churn_mrr + s.contraction_mrr, NULLIF(s.opening_mrr, 0))                     AS gross_rcr,
    SAFE_DIVIDE((s.churn_mrr + s.contraction_mrr) - s.expansion_mrr, NULLIF(s.opening_mrr, 0)) AS net_rcr,
    (1 - SAFE_DIVIDE(s.churn_mrr + s.contraction_mrr, NULLIF(s.opening_mrr, 0)))               AS grr,
    (1 - SAFE_DIVIDE((s.churn_mrr + s.contraction_mrr) - s.expansion_mrr, NULLIF(s.opening_mrr, 0))) AS nrr,

    -- Logo flags
    (s.opening_mrr > 0)                             AS opening_active,
    (s.opening_mrr = 0 AND s.closing_mrr > 0)       AS new_logo,
    (s.opening_mrr > 0 AND s.closing_mrr = 0)       AS churned_logo,

    -- Data validation
    ROUND(s.closing_mrr - (s.opening_mrr + COALESCE(n.new_net_mrr, 0)), 2) AS mrr_recon_delta
  FROM sd s
  LEFT JOIN net_new_mrr n USING (account_id, year, month)
)


--FINAL EXPORT FOR TABLEAU

SELECT
  account_id,
  plan_tier,
  year,
  month,
  month_date,
  opening_mrr,
  expansion_mrr,
  contraction_mrr,
  churn_mrr,
  net_new_mrr,
  closing_mrr,
  gross_rcr,
  net_rcr,
  grr,
  nrr,
  opening_active,
  new_logo,
  churned_logo,
  mrr_recon_delta
FROM acct_level
ORDER BY year, month, account_id;






