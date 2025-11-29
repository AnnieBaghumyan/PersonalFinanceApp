-- PERSONAL FINANCE APP - DQL QUERIES (Phase 4)
-- Works with ddl.sql + dml.sql (updated schema and data)


/* =========================================================
   1. BASIC LISTING QUERIES
   ========================================================= */

-- 1.1 User profile + account stats (per currency)
SELECT
    u.user_id,
    u.full_name,
    u.email,
    u.subscription,
    u.status,
    COUNT(a.account_id) AS account_count,	
    SUM(a.current_balance) FILTER (WHERE a.currency_code = 'USD') AS total_balance_usd,	-- only include rows with 
    SUM(a.current_balance) FILTER (WHERE a.currency_code = 'AMD') AS total_balance_amd	-- the condition specified
FROM users u
LEFT JOIN accounts a ON a.user_id = u.user_id
GROUP BY u.user_id, u.full_name, u.email, u.subscription, u.status;


-- 1.2 List all accounts for a user
SELECT
    a.account_id,
    a.account_name,
    a.account_type,
    a.currency_code,
    a.current_balance,
    a.allow_overdraft,
    a.is_active,
    a.created_at,
    a.closed_at
FROM accounts a
WHERE a.user_id = 1
ORDER BY a.account_id;

-- 1.3 Category hierarchy (parent + children) for a user

-- (a) Parent/root categories (no parent_category_id)
SELECT
    c.category_id,
    c.category_name,
    c.category_type
FROM categories c
WHERE c.user_id = 1
  AND c.parent_category_id IS NULL
ORDER BY c.category_type, c.category_name;

-- (b) Children of a given parent category (example: parent_category_id = 8 => "Food")
SELECT
    c.category_id,
    c.category_name,
    c.category_type,
    c.parent_category_id
FROM categories c
WHERE c.user_id = 1
  AND c.parent_category_id = 8      -- change as needed
ORDER BY c.category_name;


-- 1.4 Budgets for a user (via categories)
SELECT
    b.budget_id,
    c.category_name,
    c.category_type,
    b.limit_amount,
    b.alert_threshold,
    b.period_type,
    b.is_active
FROM budgets b
JOIN categories c ON c.category_id = b.category_id
WHERE c.user_id = 1
ORDER BY c.category_type, c.category_name;


-- 1.5 Bills: unpaid, upcoming, overdue, etc. for a user
SELECT
    b.bill_id,
    b.bill_name,
    b.amount_due,
    b.due_date,
    b.recurring_frequency,
    b.is_paid,
    b.status,
	CASE
		WHEN b.is_paid THEN 0
		ELSE (b.due_date - CURRENT_DATE) 
	END AS days_until_due,
    CASE
        WHEN b.is_paid THEN 'paid'
        WHEN b.due_date < CURRENT_DATE THEN 'overdue'
        WHEN b.due_date = CURRENT_DATE THEN 'due_today'
        ELSE 'upcoming'
    END AS due_state
FROM bills b
WHERE b.user_id = 1
ORDER BY b.is_paid, b.due_date;


-- 1.6 Loans list for a user
SELECT
    l.loan_id,
    l.loan_name,
    l.principal_amount,
    l.remaining_amount,
    l.payment_amount,
    l.interest_rate_pct,
    l.next_due_date,
    l.status,
    l.start_date,
    l.end_date,
    l.is_paid,
    GREATEST((CURRENT_DATE - l.next_due_date), 0) AS days_past_due
FROM loans l
WHERE l.user_id = 2
ORDER BY l.status, l.next_due_date;


-- 1.7 Goals list for a user (with simple progress %)
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
        END,
        2
    ) AS percent_complete
FROM goals g
WHERE g.user_id = 1
ORDER BY g.status, g.deadline;



/* =========================================================
   2. USER-FOCUSED QUERIES (ACCOUNT & CATEGORY VIEWS)
   ========================================================= */

-- 2.1 Account history & running balance (may run slow on big data)
-- Example: user_id = 1, account_id = 1, period 2025-01-01..2025-03-31
WITH tx AS (
    SELECT
        t.tx_id,
        t.account_id,
        a.user_id,
        t.tx_timestamp::date AS tx_date,
        t.tx_timestamp,
        t.tx_type,
        t.amount,
        t.category_id,
        t.description,
        t.amount AS signed_amount
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE a.user_id = 1
      AND t.account_id = 1
      AND t.tx_timestamp BETWEEN '2025-01-01' AND '2025-03-31'
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

-- 2.2 Category statement (root category totals for a period)
-- Example: user_id = 1, period 2025-01-01..2025-03-31
WITH RECURSIVE cat_tree AS (
    SELECT
        c.category_id,
        c.parent_category_id,
        c.category_name,
        c.category_type,
        c.category_id AS root_category_id,
        c.category_name AS root_category_name
    FROM categories c
    WHERE c.user_id = 1
      AND c.parent_category_id IS NULL		-- all parent categories
    UNION ALL
    SELECT
        c.category_id,
        c.parent_category_id,
        c.category_name,
        c.category_type,
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
    JOIN accounts a ON a.account_id = t.account_id
    WHERE a.user_id = 1
      AND t.tx_timestamp BETWEEN '2025-01-01' AND '2025-03-31'
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


-- 2.3 View all legs of a transfer operation (using operation_id)
-- Example: operation_id = '00000000-0000-0000-0000-000000000008'
SELECT
    t.operation_id,
    t.tx_id,
    t.tx_timestamp,
    t.tx_type,
    t.amount,
    t.description,
    a.account_id,
    a.account_name,
    a.account_type,
    a.currency_code
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
WHERE t.tx_type = 'transfer'
  AND t.operation_id = '00000000-0000-0000-0000-000000000008'
ORDER BY t.tx_timestamp, t.tx_id;


-- 2.4 Exchange rates: latest per pair + rate for a given transaction

-- Latest available rate per currency pair
SELECT DISTINCT ON (er.base_currency_code, er.target_currency_code)
    er.base_currency_code,
    er.target_currency_code,
    er.rate,
    er.updated_at
FROM exchange_rates er
ORDER BY er.base_currency_code, er.target_currency_code, er.updated_at DESC;



-- 2.5 Get all transactions involving:
--     - a category and its children, OR
--     - a specific bill, loan, or goal
-- Example: user_id = 1, root category_id = 8 (Food), bill_id = 2, loan_id = 1, goal_id = 1
WITH RECURSIVE cat_tree AS (
    SELECT c.category_id
    FROM categories c
    WHERE c.user_id = 1
      AND c.category_id = 8
    UNION ALL
    SELECT c.category_id
    FROM categories c
    JOIN cat_tree ct ON c.parent_category_id = ct.category_id
    WHERE c.user_id = 1
),
filtered AS (
    SELECT t.*
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE a.user_id = 1
      AND (
            t.category_id IN (SELECT category_id FROM cat_tree)
         OR t.bill_id = 2
         OR t.loan_id = 1
         OR t.goal_id = 1
      )
)
SELECT
    f.tx_id,
    f.tx_timestamp,
    f.tx_type,
    f.amount,
    f.category_id,
    f.bill_id,
    f.loan_id,
    f.goal_id,
    f.description
FROM filtered f
ORDER BY f.tx_timestamp;


-- Aggregated counts
WITH RECURSIVE cat_tree AS (
    SELECT c.category_id
    FROM categories c
    WHERE c.user_id = 1
      AND c.category_id = 8
    UNION ALL
    SELECT c.category_id
    FROM categories c
    JOIN cat_tree ct ON c.parent_category_id = ct.category_id
    WHERE c.user_id = 1
),
filtered AS (
    SELECT t.*
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE a.user_id = 1
      AND (
            t.category_id IN (SELECT category_id FROM cat_tree)
         OR t.bill_id = 2
         OR t.loan_id = 1
         OR t.goal_id = 1
      )
)
SELECT
    COUNT(*) AS tx_count,
    SUM(CASE WHEN tx_type = 'income' THEN amount END) AS total_income,
    SUM(CASE WHEN tx_type = 'expense' THEN amount END) AS total_expense
FROM filtered;


/* =========================================================
   3. REPORTING & ANALYTICS
   ========================================================= */

-- 3.1 Income by category for a period
-- Example: user_id = 1, 2025-01-01..2025-03-31
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
JOIN accounts a ON a.account_id = t.account_id
JOIN categories c ON c.category_id = t.category_id
WHERE a.user_id = 1
  AND t.tx_type = 'income'
  AND t.tx_timestamp BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY c.category_id, c.category_name
ORDER BY total_income DESC;


-- 3.2 Largest expenses for a period
-- Example: user_id = 1, 2025-01-01..2025-03-31
SELECT
    t.tx_id,
    t.tx_timestamp,
    t.amount,
    c.category_name,
    a.account_name,
    t.description
FROM transactions t
JOIN accounts a  ON a.account_id = t.account_id
LEFT JOIN categories c ON c.category_id = t.category_id
WHERE a.user_id = 1
  AND t.tx_type = 'expense'
  AND t.tx_timestamp BETWEEN '2025-01-01' AND '2025-03-31'
ORDER BY t.amount DESC
LIMIT 20;


-- 3.3 Budget performance summary for current month (per user)
WITH current_month AS (
    SELECT
        date_trunc('month', CURRENT_DATE) AS month_start,
        (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month - 1 day') AS month_end
),
budgets_for_user AS (
    SELECT
        b.budget_id,
        b.category_id,
        b.limit_amount,
        b.alert_threshold,
        b.period_type,
        b.is_active,
        c.user_id,
        c.category_name,
        c.category_type
    FROM budgets b
    JOIN categories c ON c.category_id = b.category_id
    WHERE c.user_id = 1
      AND b.is_active = TRUE
),
budget_spend AS (
    SELECT
        bf.budget_id,
        bf.category_id,
        bf.limit_amount,
        bf.alert_threshold,
        bf.period_type,
        bf.category_name,
        bf.category_type,
        SUM(t.amount) AS actual_spend
    FROM budgets_for_user bf
    JOIN current_month cm ON TRUE
    LEFT JOIN transactions t
        ON t.category_id = bf.category_id
       AND t.tx_type = 'expense'
       AND t.tx_timestamp BETWEEN cm.month_start AND cm.month_end
    GROUP BY bf.budget_id, bf.category_id,
             bf.limit_amount, bf.alert_threshold, bf.period_type,
             bf.category_name, bf.category_type
)
SELECT
    bs.budget_id,
    bs.category_name,
    bs.category_type,
    bs.limit_amount,
    COALESCE(bs.actual_spend, 0) AS actual_spend,
    ROUND(
        CASE WHEN bs.limit_amount > 0
             THEN (COALESCE(bs.actual_spend, 0) * 100.0 / bs.limit_amount)
             ELSE 0
        END,
        2
    ) AS utilization_pct,
    CASE
        WHEN COALESCE(bs.actual_spend, 0) <= bs.limit_amount * (bs.alert_threshold / 100.0)
            THEN 'OK'
        WHEN COALESCE(bs.actual_spend, 0) <= bs.limit_amount
            THEN 'Warn'
        ELSE 'Exceeded'
    END AS budget_status
FROM budget_spend bs
ORDER BY bs.category_name;
