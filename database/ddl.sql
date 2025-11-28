
-- Drop tables
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS OPERATIONS CASCADE;
DROP TABLE IF EXISTS goals CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS bills CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS currencies CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop Enum types
DROP TYPE IF EXISTS goal_status CASCADE;
DROP TYPE IF EXISTS loan_status CASCADE;
DROP TYPE IF EXISTS bill_status CASCADE;
DROP TYPE IF EXISTS recurring_frequency CASCADE;
DROP TYPE IF EXISTS tx_type CASCADE;
DROP TYPE IF EXISTS account_type CASCADE;
DROP TYPE IF EXISTS period_type CASCADE;
DROP TYPE IF EXISTS category_type CASCADE;
DROP TYPE IF EXISTS subscription_type CASCADE;
DROP TYPE IF EXISTS user_status CASCADE;

-- Create ENUM types
CREATE TYPE user_status AS ENUM ('active','inactive','suspended');
CREATE TYPE subscription_type AS ENUM ('free','pro','premium');
CREATE TYPE category_type AS ENUM ('income','expense');
CREATE TYPE period_type AS ENUM ('daily','weekly','monthly','yearly','custom','none');
CREATE TYPE account_type AS ENUM ('cash','debit card','credit card','current account','investment');
CREATE TYPE tx_type AS ENUM ('income','expense','transfer');
CREATE TYPE recurring_frequency AS ENUM ('none','weekly','monthly','yearly');
CREATE TYPE bill_status AS ENUM ('pending','paid','late','cancelled');
CREATE TYPE loan_status AS ENUM ('active','closed','defaulted','pending');
CREATE TYPE goal_status AS ENUM ('active','achieved','completed','cancelled');

-- Users of the system (ERD: User)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status user_status NOT NULL DEFAULT 'active',
    subscription subscription_type NOT NULL DEFAULT 'free'
);

-- Supported currencies (ERD: Currency)
CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE
);

-- FX rates between currencies (ERD: ExchangeRate)
CREATE TABLE exchange_rates (
    exchange_rate_id SERIAL PRIMARY KEY,
    base_currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code) ON DELETE CASCADE,
    target_currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code) ON DELETE CASCADE,
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (base_currency_code, target_currency_code, updated_at),
    CHECK (base_currency_code <> target_currency_code)
);

-- Financial accounts (ERD: Account)
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    account_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(34),
    account_type account_type NOT NULL,
    allow_overdraft BOOLEAN NOT NULL DEFAULT FALSE,
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Categories (income / expense, hierarchical) (ERD: Category)
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_name VARCHAR(100) NOT NULL,
    category_type category_type NOT NULL,
    parent_category_id INTEGER REFERENCES categories(category_id) ON DELETE CASCADE,
    UNIQUE (user_id, category_name, category_type)
);

-- Budgets per category (ERD: Budget)
CREATE TABLE budgets (
    budget_id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(category_id),
    limit_amount NUMERIC(18,2) NOT NULL CHECK (limit_amount >= 0),
    alert_threshold NUMERIC(5,2) DEFAULT 0 CHECK (alert_threshold >= 0 AND alert_threshold <= 100),
    period_type period_type NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (category_id, period_type)
);

-- Bills (ERD: Bill)
CREATE TABLE bills (
    bill_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id INTEGER REFERENCES accounts(account_id),
    bill_name VARCHAR(150) NOT NULL,
    amount_due NUMERIC(18,2) NOT NULL CHECK (amount_due >= 0),
    due_date DATE NOT NULL,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_frequency recurring_frequency,
    status bill_status NOT NULL DEFAULT 'pending',
    notes TEXT
);

-- Loans (ERD: Loan)
CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id INTEGER REFERENCES accounts(account_id),
    loan_name VARCHAR(150) NOT NULL,
    principal_amount NUMERIC(18,2) NOT NULL CHECK (principal_amount >= 0),
    remaining_amount NUMERIC(18,2) NOT NULL CHECK (remaining_amount >= 0),
    interest_rate_pct NUMERIC(5,2) NOT NULL CHECK (interest_rate_pct >= 0),
    payment_amount NUMERIC(18,2),
    next_due_date DATE,
    status loan_status NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL,
    end_date DATE,
    is_paid BOOLEAN NOT NULL DEFAULT FALSE
);

-- Saving goals (ERD: Goal)
CREATE TABLE goals (
    goal_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    goal_name VARCHAR(150) NOT NULL,
    target_amount NUMERIC(18,2) NOT NULL CHECK (target_amount >= 0),
    saved_amount NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (saved_amount >= 0),
    deadline DATE,
    status goal_status NOT NULL DEFAULT 'active',
    notes TEXT
);

-- Operations
CREATE TABLE operations (
    operation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    request_hash TEXT,
    metadata JSONB
);

-- Transactions (ERD: Transaction, plus transfer_id)
CREATE TABLE transactions (
    tx_id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(account_id),
    category_id INTEGER REFERENCES categories(category_id),
    amount NUMERIC(18,2) NOT NULL,
    tx_type tx_type NOT NULL,
    tx_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    bill_id INTEGER REFERENCES bills(bill_id) ON DELETE SET NULL,
    loan_id INTEGER REFERENCES loans(loan_id) ON DELETE SET NULL,
    goal_id INTEGER REFERENCES goals(goal_id) ON DELETE SET NULL,
    description TEXT,
    operation_id UUID NOT NULL REFERENCES operations(operation_id)
);

-- Helpful indexes
CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE INDEX idx_categories_user ON categories(user_id);
CREATE INDEX idx_bills_user ON bills(user_id);
CREATE INDEX idx_loans_user ON loans(user_id);
CREATE INDEX idx_goals_user ON goals(user_id);
CREATE INDEX idx_budgets_category ON budgets(category_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_timestamp ON transactions(tx_timestamp);
