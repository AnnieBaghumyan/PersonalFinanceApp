-- =========================================
-- Personal Finance Management - DDL Script
-- Target DB: PostgreSQL
-- =========================================

-- Drop tables in reverse order to satisfy foreign keys
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS bills CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS currencies CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- -----------------------------
-- Users of the system (ERD: User)
-- -----------------------------
CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status          VARCHAR(20) NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','inactive')),
    subscription    VARCHAR(20) NOT NULL DEFAULT 'free'
                    CHECK (subscription IN ('free','premium'))
);

-- -----------------------------
-- Supported currencies (ERD: Currency)
-- -----------------------------
CREATE TABLE currencies (
    currency_code   CHAR(3) PRIMARY KEY,
    name            VARCHAR(50) NOT NULL,
    symbol          VARCHAR(10) NOT NULL,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE
);

-- -----------------------------
-- FX rates between currencies (ERD: ExchangeRate)
-- -----------------------------
CREATE TABLE exchange_rates (
    exchange_rate_id     SERIAL PRIMARY KEY,
    base_currency_code   CHAR(3) NOT NULL
                          REFERENCES currencies(currency_code) ON DELETE CASCADE,
    target_currency_code CHAR(3) NOT NULL
                          REFERENCES currencies(currency_code) ON DELETE CASCADE,
    rate                 NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_exchange_rate UNIQUE (base_currency_code, target_currency_code, updated_at)
);

-- -----------------------------
-- Financial accounts (ERD: Account)
-- -----------------------------
CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL
                    REFERENCES users(user_id) ON DELETE CASCADE,
    currency_code   CHAR(3) NOT NULL
                    REFERENCES currencies(currency_code),
    account_name    VARCHAR(100) NOT NULL,
    account_number  VARCHAR(34),
    account_type    VARCHAR(30) NOT NULL
                    CHECK (account_type IN ('cash',
                                            'debit_card',
                                            'credit_card',
                                            'current_account',
                                            'investment')),
    allow_overdraft BOOLEAN NOT NULL DEFAULT FALSE,
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- -----------------------------
-- Categories (income / expense, hierarchical) (ERD: Category)
-- -----------------------------
CREATE TABLE categories (
    category_id         SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL
                        REFERENCES users(user_id) ON DELETE CASCADE,
    category_name       VARCHAR(100) NOT NULL,
    category_type       VARCHAR(20) NOT NULL
                        CHECK (category_type IN ('income','expense')),
    parent_category_id  INTEGER REFERENCES categories(category_id),
    CONSTRAINT uq_user_category UNIQUE (user_id, category_name, category_type)
);

-- -----------------------------
-- Budgets per category (ERD: Budget)
-- -----------------------------
CREATE TABLE budgets (
    budget_id       SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL
                    REFERENCES users(user_id) ON DELETE CASCADE,
    category_id     INTEGER NOT NULL
                    REFERENCES categories(category_id),
    limit_amount    NUMERIC(18,2) NOT NULL CHECK (limit_amount >= 0),
    alert_threshold NUMERIC(5,2) DEFAULT 0
                    CHECK (alert_threshold >= 0 AND alert_threshold <= 100),
    period_type     VARCHAR(20) NOT NULL
                    CHECK (period_type IN ('monthly','weekly','custom')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

-- -----------------------------
-- Bills (ERD: Bill)
-- -----------------------------
CREATE TABLE bills (
    bill_id             SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL
                        REFERENCES users(user_id) ON DELETE CASCADE,
    account_id          INTEGER REFERENCES accounts(account_id),
    bill_name           VARCHAR(150) NOT NULL,
    amount_due          NUMERIC(18,2) NOT NULL CHECK (amount_due >= 0),
    due_date            DATE NOT NULL,
    is_paid             BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_frequency VARCHAR(20),    -- e.g. monthly / yearly
    status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','paid','overdue',
                                           'cancelled','archived')),
    notes               TEXT
);

-- -----------------------------
-- Loans (ERD: Loan)
-- -----------------------------
CREATE TABLE loans (
    loan_id             SERIAL PRIMARY KEY,
    user_id             INTEGER NOT NULL
                        REFERENCES users(user_id) ON DELETE CASCADE,
    account_id          INTEGER REFERENCES accounts(account_id),
    loan_name           VARCHAR(150) NOT NULL,
    principal_amount    NUMERIC(18,2) NOT NULL CHECK (principal_amount >= 0),
    remaining_amount    NUMERIC(18,2) NOT NULL CHECK (remaining_amount >= 0),
    interest_rate_pct   NUMERIC(5,2) NOT NULL CHECK (interest_rate_pct >= 0),
    payment_amount      NUMERIC(18,2),
    next_due_date       DATE,
    status              VARCHAR(20) NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','closed','defaulted','archived')),
    start_date          DATE NOT NULL,
    end_date            DATE,
    is_paid             BOOLEAN NOT NULL DEFAULT FALSE
);

-- -----------------------------
-- Saving goals (ERD: Goal)
-- -----------------------------
CREATE TABLE goals (
    goal_id         SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL
                    REFERENCES users(user_id) ON DELETE CASCADE,
    goal_name       VARCHAR(150) NOT NULL,
    target_amount   NUMERIC(18,2) NOT NULL CHECK (target_amount >= 0),
    saved_amount    NUMERIC(18,2) NOT NULL DEFAULT 0
                    CHECK (saved_amount >= 0),
    deadline        DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active','achieved','archived','cancelled')),
    notes           TEXT
);

-- -----------------------------
-- Transactions (ERD: Transaction, plus transfer_id)
-- -----------------------------
CREATE TABLE transactions (
    tx_id           SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL
                    REFERENCES users(user_id) ON DELETE CASCADE,
    account_id      INTEGER NOT NULL
                    REFERENCES accounts(account_id),
    category_id     INTEGER REFERENCES categories(category_id),
    bill_id         INTEGER REFERENCES bills(bill_id),
    loan_id         INTEGER REFERENCES loans(loan_id),
    goal_id         INTEGER REFERENCES goals(goal_id),
    amount          NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    tx_type         VARCHAR(20) NOT NULL
                    CHECK (tx_type IN ('income','expense','transfer')),
    tx_timestamp    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description     TEXT,
    operation_id    VARCHAR(64) NOT NULL,
    transfer_id     VARCHAR(64),
    CONSTRAINT uq_operation UNIQUE (operation_id)
);

-- -----------------------------
-- Helpful indexes for typical queries
-- -----------------------------
CREATE INDEX idx_accounts_user           ON accounts(user_id);
CREATE INDEX idx_categories_user         ON categories(user_id);
CREATE INDEX idx_budgets_user            ON budgets(user_id);
CREATE INDEX idx_bills_user              ON bills(user_id);
CREATE INDEX idx_loans_user              ON loans(user_id);
CREATE INDEX idx_goals_user              ON goals(user_id);

CREATE INDEX idx_transactions_user       ON transactions(user_id);
CREATE INDEX idx_transactions_account    ON transactions(account_id);
CREATE INDEX idx_transactions_category   ON transactions(category_id);
CREATE INDEX idx_transactions_timestamp  ON transactions(tx_timestamp);
