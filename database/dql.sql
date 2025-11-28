-- ============================================
-- Personal Finance Management - DQL Script
-- Phase Four - Team #5
-- ============================================
-- Assumes the schema from phase4_schema.sql and
-- sample data from phase4_data.sql are already loaded.
-- ============================================


/* =====================================================
   1. BASIC LISTING QUERIES (from "Basic Operations")
   ===================================================== */

-- 1.1 Get a user profile with some basic stats
-- (number of accounts, total balance in native currencies)
SELECT
    u.user_id,
    u.full_name,
    u.email,
    u.subscription,
    u.status,
    u.created_at,
    COUNT(DISTINCT a.account_id) AS account_count,
    SUM(a.current_balance) FILTER (WHERE a.currency_code = 'AMD') AS total_balance_amd,
    SUM(a.current_balance) FILTER (WHERE a.currency_code = 'USD') AS total_balance_usd
FROM users u
LEFT JOIN accounts a ON a.user_id = u.user_id
WHERE u.user_id = 1
GROUP BY u.user_id, u.full_name, u.email, u.subscription, u.status, u.created_at;


-- 1.2 List all accounts for a given user (with current balance)
SELECT
    a.account_id,
    a.account_name,
    a.account_type,
    a.currency_code,
    a.current_balance,
    a.created_at,
    a.closed_at,
    a.is_active,
    a.allow_overdraft
FROM accounts a
WHERE a.user_id = 1
ORDER BY a.created_at;


-- 1.3 List parent categories and their direct children for a user
--   (a) Parent categories (no parent_category_id)
SELECT
    c.category_id,
    c.category_name,
    c.category_type
FROM categories c
WHERE c.user_id = 1
  AND c.parent_category_id IS NULL
ORDER BY c.category_type, c.category_name;

--   (b) Children of a given parent category (example: parent_category_id = 3)
SELECT
    c.category_id,
    c.category_name,
    c.category_type,
    c.parent_category_id
FROM categories c
WHERE c.user_id = 1
  AND c.parent_category_id = 3
ORDER BY c.category_name;


-- 1.4 List all budgets for a user
SELECT
    b.budget_id,
    c.category_name,
    b.limit_amount,
    b.alert_threshold,
    b.period_type,
    b.is_active
FROM budgets b
JOIN categories c ON c.category_id = b.category_id
WHERE b.user_id = 1
ORDER BY c.category_name;


-- 1.5 Bills list:
--     unpaid, upcoming, and overdue with days remaining/overdue
SELECT
    b.bill_id,
    b.bill_name,
    b.amount_due,
    b.due_date,
    b.recurring_frequency,
    b.is_paid,
    b.status,
    (b.due_date - CURRENT_DATE) AS days_until_due,
    CASE
      WHEN b.is_paid THEN 'paid'
      WHEN b.due_date < CURRENT_DATE THEN 'overdue'
      WHEN b.due_date = CURRENT_DATE THEN 'due_today'
      ELSE 'upcoming'
    END AS due_state
FROM bills b
WHERE b.user_id = 1
ORDER BY b.is_paid, b.due_date;


-- 1.6 Loans list:
--     active/closed with remaining amount, next due date, days past due
SELECT
    l.loan_id,
    l.loan_name,
    l.principal_amount,
    l.remaining_amount,
    l.payment_amount,
    l.interest_rate_pct,
    l.next_due_date,
    l.status,
    GREATEST((CURRENT_DATE - l.next_due_date), 0) AS days_past_due
FROM loans l
WHERE l.user_id = 1
ORDER BY l.status, l.next_due_date NULLS LAST;


-- 1.7 Goals list:
--     progress %, and simple ETA based on saved_amount vs target
--     (NOTE: precise ETA based on "recent contributions" would usually
--      need more logic; this is a simple approximation.)
SELECT
    g.goal_id,
    g.goal_name,
    g.target_amount,
    g.saved_amount,
    g.deadline,
    g.status,
    ROUND(
        CASE
            WHEN g.target_amount > 0 THEN (g.saved_amount * 100.0 / g.target_amount)
            ELSE 0
        END, 2
    ) AS percent_complete
FROM goals g
WHERE g.user_id = 1
ORDER BY g.status, g.deadline NULLS LAST;



/* =====================================================
   2. USER-FOCUSED QUERIES (Phase 3 "User-Focused Queries")
   ===================================================== */

-- 2.1 View account history & running balance for one account
-- Example: user_id = 1, account_id = 2, between 2025-01-01 and 2025-03-31
-- Transfers are treated as 0 net effect in this simple version.
WITH tx AS (
    SELECT
        t.tx_id,
        t.account_id,
        t.user_id,
        t.tx_timestamp::date AS tx_date,
        t.tx_timestamp,
        t.tx_type,
        t.amount,
        t.category_id,
        t.description,
        CASE
            WHEN t.tx_type = 'income'  THEN  t.amount
            WHEN t.tx_type = 'expense' THEN -t.amount
            ELSE 0
        END AS signed_amount
    FROM transactions t
    WHERE t.user_id = 1
      AND t.account_id = 2
      AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
)
SELECT
    tx.tx_id,
    tx.tx_timestamp,
    tx.tx_type,
    tx.amount,
    tx.category_id,
    tx.description,
    tx.signed_amount,
    SUM(tx.signed_amount)
        OVER (ORDER BY tx.tx_timestamp, tx.tx_id) AS running_balance
FROM tx
ORDER BY tx.tx_timestamp, tx.tx_id;


-- 2.2 Upcoming scheduled payments (bills + loan payments) for account 2
-- within the next 30 days
WITH upcoming_bills AS (
    SELECT
        'bill' AS item_type,
        b.bill_id AS item_id,
        b.bill_name AS item_name,
        b.amount_due AS scheduled_amount,
        b.due_date,
        (b.due_date - CURRENT_DATE) AS days_until_due,
        b.recurring_frequency,
        b.notes,
        b.account_id
    FROM bills b
    WHERE b.user_id = 1
      AND (b.account_id IS NULL OR b.account_id = 2)
      AND b.is_paid = FALSE
      AND b.due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
),
upcoming_loans AS (
    SELECT
        'loan' AS item_type,
        l.loan_id AS item_id,
        l.loan_name AS item_name,
        l.payment_amount AS scheduled_amount,
        l.next_due_date AS due_date,
        (l.next_due_date - CURRENT_DATE) AS days_until_due,
        NULL::VARCHAR AS recurring_frequency,
        NULL::TEXT AS notes,
        l.account_id
    FROM loans l
    WHERE l.user_id = 1
      AND l.status = 'active'
      AND l.account_id = 2
      AND l.next_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
),
all_items AS (
    SELECT * FROM upcoming_bills
    UNION ALL
    SELECT * FROM upcoming_loans
)
SELECT
    ai.item_type,
    ai.item_id,
    ai.item_name,
    ai.scheduled_amount,
    ai.due_date,
    ai.days_until_due,
    ai.recurring_frequency,
    ai.notes,
    a.account_name,
    a.current_balance,
    (a.current_balance - ai.scheduled_amount) AS projected_balance_after_payment
FROM all_items ai
LEFT JOIN accounts a ON ai.account_id = a.account_id
ORDER BY ai.due_date, ai.item_type;


-- 2.3 Monthly account statements:
--   opening balance, income, expenses, net, closing balance per month.
-- Example: user_id = 1, account_id = 2, range 2025-01-01..2025-03-31
WITH bounds AS (
    SELECT
        DATE '2025-01-01' AS start_date,
        DATE '2025-03-31' AS end_date
),
months AS (
    SELECT date_trunc('month', d)::date AS month_start
    FROM bounds b,
         generate_series(b.start_date, b.end_date, INTERVAL '1 month') AS d
),
acc AS (
    SELECT *
    FROM accounts
    WHERE account_id = 2
      AND user_id = 1
),
tx AS (
    SELECT
        t.tx_timestamp::date AS tx_date,
        t.tx_type,
        t.amount,
        CASE
            WHEN t.tx_type = 'income'  THEN  t.amount
            WHEN t.tx_type = 'expense' THEN -t.amount
            ELSE 0
        END AS signed_amount
    FROM transactions t
    WHERE t.user_id = 1
      AND t.account_id = 2
),
tx_with_month AS (
    SELECT
        date_trunc('month', tx.tx_date)::date AS month_start,
        tx.tx_type,
        tx.amount,
        tx.signed_amount
    FROM tx
),
monthly AS (
    SELECT
        m.month_start,
        (m.month_start + INTERVAL '1 month - 1 day')::date AS month_end,
        COALESCE(SUM(CASE WHEN twm.tx_type = 'income'  THEN twm.amount END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN twm.tx_type = 'expense' THEN twm.amount END), 0) AS total_expense,
        COALESCE(SUM(twm.signed_amount), 0) AS net_change
    FROM months m
    LEFT JOIN tx_with_month twm ON twm.month_start = m.month_start
    GROUP BY m.month_start
),
closing_calc AS (
    SELECT
        acc.current_balance,
        m.month_start,
        m.month_end,
        m.total_income,
        m.total_expense,
        m.net_change,
        COALESCE((
            SELECT SUM(tx2.signed_amount)
            FROM tx tx2
            WHERE tx2.tx_date > m.month_end
        ), 0) AS future_net
    FROM acc, monthly m
)
SELECT
    month_start,
    month_end,
    (current_balance - future_net - net_change) AS opening_balance,
    total_income,
    total_expense,
    net_change,
    (current_balance - future_net) AS closing_balance
FROM closing_calc
ORDER BY month_start;


-- 2.4 Category statement for a period
-- Summarize income/expense by root category (respecting parent/child hierarchy).
-- Example: user_id = 1, period 2025-01-01..2025-03-31
WITH RECURSIVE cat_tree AS (
    SELECT
        c.category_id,
        c.parent_category_id,
        c.category_name,
        c.category_id AS root_category_id,
        c.category_name AS root_category_name
    FROM categories c
    WHERE c.user_id = 1
      AND c.parent_category_id IS NULL
    UNION ALL
    SELECT
        c.category_id,
        c.parent_category_id,
        c.category_name,
        ct.root_category_id,
        ct.root_category_name
    FROM categories c
    JOIN cat_tree ct ON c.parent_category_id = ct.category_id
    WHERE c.user_id = 1
),
tx AS (
    SELECT
        t.category_id,
        t.tx_type,
        t.amount
    FROM transactions t
    WHERE t.user_id = 1
      AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
),
agg AS (
    SELECT
        ct.root_category_id,
        ct.root_category_name,
        COALESCE(SUM(CASE WHEN tx.tx_type = 'income'  THEN tx.amount END), 0) AS income_amount,
        COALESCE(SUM(CASE WHEN tx.tx_type = 'expense' THEN tx.amount END), 0) AS expense_amount
    FROM cat_tree ct
    LEFT JOIN tx ON tx.category_id = ct.category_id
    GROUP BY ct.root_category_id, ct.root_category_name
),
totals AS (
    SELECT
        SUM(income_amount)  AS total_income,
        SUM(expense_amount) AS total_expense
    FROM agg
)
SELECT
    a.root_category_id,
    a.root_category_name,
    a.income_amount,
    a.expense_amount,
    CASE WHEN t.total_income  > 0
         THEN ROUND(a.income_amount  * 100.0 / t.total_income,  2)
         ELSE 0 END AS income_pct,
    CASE WHEN t.total_expense > 0
         THEN ROUND(a.expense_amount * 100.0 / t.total_expense, 2)
         ELSE 0 END AS expense_pct
FROM agg a
CROSS JOIN totals t
ORDER BY a.expense_amount DESC, a.income_amount DESC;


-- 2.5 See all logs of a transfer between accounts
-- Example: transfer_id = 'TR-1'
SELECT
    t.transfer_id,
    t.tx_id,
    t.tx_timestamp,
    t.tx_type,
    t.amount,
    a.account_id,
    a.account_name,
    a.account_type,
    a.currency_code,
    t.description
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
WHERE t.transfer_id = 'TR-1'
ORDER BY t.tx_timestamp, t.tx_id;


-- 2.6 Track current and historical exchange rates
-- (a) Latest rate per currency pair
SELECT DISTINCT ON (er.base_currency_code, er.target_currency_code)
    er.base_currency_code,
    er.target_currency_code,
    er.rate,
    er.updated_at
FROM exchange_rates er
ORDER BY er.base_currency_code, er.target_currency_code, er.updated_at DESC;

-- (b) Effective rate for a given transaction (example tx_id = 1) to AMD
WITH tx_info AS (
    SELECT
        t.tx_id,
        t.tx_timestamp,
        a.currency_code AS account_currency
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.tx_id = 1
)
SELECT
    ti.tx_id,
    ti.tx_timestamp,
    ti.account_currency AS base_currency_code,
    'AMD'::CHAR(3)      AS target_currency_code,
    er.rate,
    er.updated_at
FROM tx_info ti
JOIN LATERAL (
    SELECT er.rate, er.updated_at
    FROM exchange_rates er
    WHERE er.base_currency_code   = ti.account_currency
      AND er.target_currency_code = 'AMD'
      AND er.updated_at <= ti.tx_timestamp
    ORDER BY er.updated_at DESC
    LIMIT 1
) er ON TRUE;


-- 2.7 Get all transactions involving:
--     (a) a specific category and its descendants, or
--     (b) a specific bill/loan/goal.
-- Example: category_id = 3, bill_id = 1, loan_id = 1, goal_id = 1
WITH RECURSIVE cat_tree AS (
    SELECT c.category_id
    FROM categories c
    WHERE c.user_id = 1
      AND c.category_id = 3
    UNION ALL
    SELECT c.category_id
    FROM categories c
    JOIN cat_tree ct ON c.parent_category_id = ct.category_id
    WHERE c.user_id = 1
)
SELECT
    t.tx_id,
    t.tx_timestamp,
    t.tx_type,
    t.amount,
    t.category_id,
    t.bill_id,
    t.loan_id,
    t.goal_id,
    t.description
FROM transactions t
WHERE t.user_id = 1
  AND (
        t.category_id IN (SELECT category_id FROM cat_tree)
     OR t.bill_id = 1
     OR t.loan_id = 1
     OR t.goal_id = 1
  )
ORDER BY t.tx_timestamp;

-- Aggregated counts and totals for the same selection:
WITH RECURSIVE cat_tree AS (
    SELECT c.category_id
    FROM categories c
    WHERE c.user_id = 1
      AND c.category_id = 3
    UNION ALL
    SELECT c.category_id
    FROM categories c
    JOIN cat_tree ct ON c.parent_category_id = ct.category_id
    WHERE c.user_id = 1
),
filtered AS (
    SELECT *
    FROM transactions t
    WHERE t.user_id = 1
      AND (
            t.category_id IN (SELECT category_id FROM cat_tree)
         OR t.bill_id = 1
         OR t.loan_id = 1
         OR t.goal_id = 1
      )
)
SELECT
    COUNT(*) AS tx_count,
    SUM(CASE WHEN tx_type = 'income'  THEN amount END) AS total_income,
    SUM(CASE WHEN tx_type = 'expense' THEN amount END) AS total_expense
FROM filtered;



/* =====================================================
   3. REPORTING & ANALYTICS (Phase 3 "Reporting Queries")
   ===================================================== */

-- 3.1 Monthly cash-flow report for a user
-- Example: user_id = 1, year 2025
WITH tx AS (
    SELECT
        t.user_id,
        t.tx_timestamp::date AS tx_date,
        date_trunc('month', t.tx_timestamp)::date AS month_start,
        t.tx_type,
        t.amount
    FROM transactions t
    WHERE t.user_id = 1
      AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
),
monthly AS (
    SELECT
        month_start,
        SUM(CASE WHEN tx_type = 'income'  THEN amount END) AS income_amount,
        SUM(CASE WHEN tx_type = 'expense' THEN amount END) AS expense_amount
    FROM tx
    GROUP BY month_start
)
SELECT
    month_start,
    income_amount,
    expense_amount,
    (income_amount - expense_amount) AS net_amount,
    LAG(income_amount - expense_amount) OVER (ORDER BY month_start) AS prev_net_amount,
    (income_amount - expense_amount)
      - COALESCE(LAG(income_amount - expense_amount) OVER (ORDER BY month_start), 0)
      AS net_trend_vs_prev
FROM monthly
ORDER BY month_start;


-- 3.2 Income by category for a period
-- Example: user_id = 1, period 2025-01-01..2025-03-31
SELECT
    c.category_id,
    c.category_name,
    SUM(t.amount) AS total_income,
    ROUND(
        SUM(t.amount) * 100.0
        / NULLIF(SUM(SUM(t.amount)) OVER (), 0),
        2
    ) AS pct_of_income
FROM transactions t
JOIN categories c ON c.category_id = t.category_id
WHERE t.user_id = 1
  AND t.tx_type = 'income'
  AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
GROUP BY c.category_id, c.category_name
ORDER BY total_income DESC;


-- 3.3 Largest expenses (descending) for a period
-- Example: user_id = 1, period 2025-01-01..2025-03-31
SELECT
    t.tx_id,
    t.tx_timestamp,
    t.amount,
    c.category_name,
    a.account_name,
    t.description
FROM transactions t
LEFT JOIN categories c ON c.category_id = t.category_id
LEFT JOIN accounts  a ON a.account_id = t.account_id
WHERE t.user_id = 1
  AND t.tx_type = 'expense'
  AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
ORDER BY t.amount DESC
LIMIT 20;


-- 3.4 Daily balance trend for an account across a period
-- Example: user_id = 1, account_id = 2, period 2025-01-01..2025-03-31
WITH bounds AS (
    SELECT
        DATE '2025-01-01' AS start_date,
        DATE '2025-03-31' AS end_date
),
acc AS (
    SELECT *
    FROM accounts
    WHERE user_id = 1
      AND account_id = 2
),
tx AS (
    SELECT
        t.tx_timestamp::date AS tx_date,
        CASE
            WHEN t.tx_type = 'income'  THEN  t.amount
            WHEN t.tx_type = 'expense' THEN -t.amount
            ELSE 0
        END AS signed_amount
    FROM transactions t
    WHERE t.user_id = 1
      AND t.account_id = 2
),
dates AS (
    SELECT generate_series(b.start_date, b.end_date, INTERVAL '1 day')::date AS day
    FROM bounds b
),
daily_future AS (
    SELECT
        d.day,
        COALESCE((
            SELECT SUM(tx2.signed_amount)
            FROM tx tx2
            WHERE tx2.tx_date > d.day
        ), 0) AS future_net
    FROM dates d
)
SELECT
    df.day AS tx_date,
    (acc.current_balance - df.future_net) AS end_of_day_balance
FROM daily_future df
JOIN acc ON TRUE
ORDER BY tx_date;


-- 3.5 Budget performance summary (current month)
-- For each active budget: limit, actual spend, utilization %, OK/Warn/Exceeded.
WITH current_month AS (
    SELECT
        date_trunc('month', CURRENT_DATE)::date AS month_start,
        (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::date AS month_end
),
budget_spend AS (
    SELECT
        b.budget_id,
        b.user_id,
        b.category_id,
        b.limit_amount,
        b.alert_threshold,
        b.period_type,
        SUM(t.amount) AS actual_spend
    FROM budgets b
    JOIN current_month cm ON TRUE
    LEFT JOIN transactions t
        ON t.user_id = b.user_id
       AND t.category_id = b.category_id
       AND t.tx_type = 'expense'
       AND t.tx_timestamp::date BETWEEN cm.month_start AND cm.month_end
    WHERE b.user_id = 1
      AND b.is_active = TRUE
    GROUP BY b.budget_id, b.user_id, b.category_id,
             b.limit_amount, b.alert_threshold, b.period_type
)
SELECT
    bs.budget_id,
    c.category_name,
    bs.limit_amount,
    COALESCE(bs.actual_spend, 0) AS actual_spend,
    ROUND(
        CASE WHEN bs.limit_amount > 0
             THEN (COALESCE(bs.actual_spend, 0) * 100.0 / bs.limit_amount)
             ELSE 0
        END, 2
    ) AS utilization_pct,
    CASE
        WHEN COALESCE(bs.actual_spend, 0) <= bs.limit_amount * (bs.alert_threshold / 100.0)
            THEN 'OK'
        WHEN COALESCE(bs.actual_spend, 0) <= bs.limit_amount
            THEN 'Warn'
        ELSE 'Exceeded'
    END AS status
FROM budget_spend bs
JOIN categories c ON c.category_id = bs.category_id
ORDER BY c.category_name;


-- 3.6 Recurring subscription detection
-- Heuristic: repeated expense transactions in the same category, with similar
-- amounts, same description, and at least 3 occurrences.
WITH recurring AS (
    SELECT
        t.user_id,
        t.category_id,
        lower(trim(t.description)) AS normalized_desc,
        ROUND(t.amount::numeric, -3) AS rounded_amount,  -- round to nearest 1000
        COUNT(*) AS tx_count,
        MIN(t.tx_timestamp::date) AS first_date,
        MAX(t.tx_timestamp::date) AS last_date,
        AVG(t.amount) AS avg_amount
    FROM transactions t
    JOIN categories c ON c.category_id = t.category_id
    WHERE t.user_id = 1
      AND t.tx_type = 'expense'
      AND c.category_type = 'expense'
      AND t.description IS NOT NULL
    GROUP BY t.user_id, t.category_id, normalized_desc, rounded_amount
    HAVING COUNT(*) >= 3
)
SELECT
    r.user_id,
    r.category_id,
    c.category_name,
    r.normalized_desc AS subscription_label,
    r.tx_count,
    r.first_date,
    r.last_date,
    (r.last_date - r.first_date) AS span_days,
    r.avg_amount
FROM recurring r
JOIN categories c ON c.category_id = r.category_id
ORDER BY r.tx_count DESC, r.avg_amount DESC;


-- 3.7 Account activity comparison
-- Compare number of transactions and average ticket size per account
-- for a user within a timeframe.
-- Example: user_id = 1, period 2025-01-01..2025-03-31
SELECT
    a.account_id,
    a.account_name,
    a.account_type,
    a.currency_code,
    COUNT(t.tx_id) AS tx_count,
    COALESCE(AVG(t.amount), 0) AS avg_ticket_size,
    SUM(CASE WHEN t.tx_type = 'income'  THEN t.amount END) AS total_income,
    SUM(CASE WHEN t.tx_type = 'expense' THEN t.amount END) AS total_expense
FROM accounts a
LEFT JOIN transactions t
    ON t.account_id = a.account_id
   AND t.user_id   = a.user_id
   AND t.tx_timestamp::date BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
WHERE a.user_id = 1
GROUP BY a.account_id, a.account_name, a.account_type, a.currency_code
ORDER BY tx_count DESC, avg_ticket_size DESC;
