-- =========================================
-- Personal Finance Management - DML Script
-- =========================================
-- Assumes the DDL has already been run.

-- 1. Users
INSERT INTO users (full_name, email, password_hash, subscription)
VALUES
  ('Nvard Meliksetyan', 'nvard@example.com', 'hashed_password_1', 'premium'),
  ('Ani Baghumyan', 'ani@example.com', 'hashed_password_2', 'free'),
  ('Hrachya Khachatryan', 'hrachya@example.com', 'hashed_password_3', 'premium');

-- 2. Currencies
INSERT INTO currencies (currency_code, name, symbol, is_default)
VALUES
  ('AMD', 'Armenian Dram', '֏', TRUE),
  ('USD', 'US Dollar', '$', FALSE),
  ('EUR', 'Euro', '€', FALSE),
  ('GBP', 'British Pound', '£', FALSE);

-- 3. Exchange rates (simplified snapshot)
INSERT INTO exchange_rates (base_currency_code, target_currency_code, rate, updated_at)
VALUES
  ('AMD','USD',0.0025,'2025-01-01'),
  ('USD','AMD',400.00,'2025-01-01'),
  ('AMD','EUR',0.0022,'2025-01-01'),
  ('EUR','AMD',450.00,'2025-01-01'),
  ('AMD','GBP',0.0019,'2025-01-01'),
  ('GBP','AMD',520.00,'2025-01-01');

-- 4. Accounts (9 total)
INSERT INTO accounts
    (user_id, currency_code, account_name, account_number,
     account_type, allow_overdraft, current_balance)
VALUES
  (1,'AMD','Nvard Wallet',NULL,'cash',FALSE,75000),
  (1,'AMD','Nvard Main Card','4095 1234 5678 0001','debit_card',FALSE,250000),
  (1,'USD','Nvard USD Savings','US123456789','investment',FALSE,1500),
  (2,'AMD','Ani Wallet',NULL,'cash',FALSE,35000),
  (2,'AMD','Ani Salary Card','4095 9876 1111 2222','debit_card',FALSE,180000),
  (2,'EUR','Ani Travel Savings','EU99887766','investment',FALSE,800),
  (3,'AMD','Hrachya Wallet',NULL,'cash',FALSE,50000),
  (3,'AMD','Hrachya Salary Card','4095 0000 2222 3333','debit_card',TRUE,320000),
  (3,'USD','Hrachya USD Investment','US77776666','investment',FALSE,2500);

-- 5. Categories
-- User 1 categories (ids will be 1-10)
INSERT INTO categories (user_id, category_name, category_type)
VALUES
  (1,'Salary','income'),
  (1,'Freelance','income'),
  (1,'Groceries','expense'),
  (1,'Utilities','expense'),
  (1,'Transport','expense'),
  (1,'Rent','expense'),
  (1,'Entertainment','expense'),
  (1,'Healthcare','expense'),
  (1,'Education','expense'),
  (1,'Subscriptions','expense');

-- User 2 categories (ids 11-20)
INSERT INTO categories (user_id, category_name, category_type)
VALUES
  (2,'Salary','income'),
  (2,'Bonus','income'),
  (2,'Groceries','expense'),
  (2,'Utilities','expense'),
  (2,'Transport','expense'),
  (2,'Rent','expense'),
  (2,'Entertainment','expense'),
  (2,'Healthcare','expense'),
  (2,'Gifts','expense'),
  (2,'Subscriptions','expense');

-- User 3 categories (ids 21-30)
INSERT INTO categories (user_id, category_name, category_type)
VALUES
  (3,'Salary','income'),
  (3,'Consulting','income'),
  (3,'Groceries','expense'),
  (3,'Utilities','expense'),
  (3,'Transport','expense'),
  (3,'Rent','expense'),
  (3,'Entertainment','expense'),
  (3,'Healthcare','expense'),
  (3,'Education','expense'),
  (3,'Subscriptions','expense');

-- 6. Budgets (4 per user, 12 total)
INSERT INTO budgets (user_id, category_id, limit_amount,
                     alert_threshold, period_type, is_active)
VALUES
  -- User 1 (categories 3,5,7,10)
  (1,3,120000,80,'monthly',TRUE),   -- Groceries
  (1,5,40000,75,'monthly',TRUE),    -- Transport
  (1,7,60000,80,'monthly',TRUE),    -- Entertainment
  (1,10,15000,90,'monthly',TRUE),   -- Subscriptions
  -- User 2 (categories 13,15,17,20)
  (2,13,100000,80,'monthly',TRUE),
  (2,15,30000,75,'monthly',TRUE),
  (2,17,50000,80,'monthly',TRUE),
  (2,20,12000,90,'monthly',TRUE),
  -- User 3 (categories 23,25,27,30)
  (3,23,110000,80,'monthly',TRUE),
  (3,25,35000,75,'monthly',TRUE),
  (3,27,55000,80,'monthly',TRUE),
  (3,30,14000,90,'monthly',TRUE);

-- 7. Bills (4 per user, 12 total)
INSERT INTO bills
    (user_id, account_id, bill_name, amount_due,
     due_date, is_paid, recurring_frequency, status, notes)
VALUES
  -- User 1 bills (account 2)
  (1,2,'Electricity',15000,'2025-03-10',FALSE,'monthly','pending','Home electricity bill'),
  (1,2,'Water',8000,'2025-03-15',FALSE,'monthly','pending','Water supply'),
  (1,2,'Internet',12000,'2025-03-05',FALSE,'monthly','pending','Home internet'),
  (1,2,'Mobile Phone',6000,'2025-03-20',FALSE,'monthly','pending','Mobile operator'),
  -- User 2 bills (account 5)
  (2,5,'Electricity',13000,'2025-03-08',FALSE,'monthly','pending','Home electricity'),
  (2,5,'Water',7000,'2025-03-14',FALSE,'monthly','pending','Water supply'),
  (2,5,'Internet',11000,'2025-03-03',FALSE,'monthly','pending','Internet'),
  (2,5,'Gym Membership',18000,'2025-03-25',FALSE,'monthly','pending','Fitness subscription'),
  -- User 3 bills (account 8)
  (3,8,'Electricity',14000,'2025-03-09',FALSE,'monthly','pending','Home electricity'),
  (3,8,'Water',7500,'2025-03-16',FALSE,'monthly','pending','Water supply'),
  (3,8,'Internet',11500,'2025-03-04',FALSE,'monthly','pending','Home internet'),
  (3,8,'Streaming Service',9000,'2025-03-22',FALSE,'monthly','pending','Streaming subscription');

-- 8. Loans (2 per user, 6 total)
INSERT INTO loans
    (user_id, account_id, loan_name, principal_amount,
     remaining_amount, interest_rate_pct, payment_amount,
     next_due_date, status, start_date, end_date, is_paid)
VALUES
  -- User 1 loans (account 2)
  (1,2,'Car Loan',3000000,2200000,10.5,85000,'2025-03-18','active','2023-01-01',NULL,FALSE),
  (1,2,'Laptop Loan',600000,150000,12.0,50000,'2025-03-05','active','2024-06-01',NULL,FALSE),
  -- User 2 loans (account 5)
  (2,5,'Mortgage',12000000,9500000,8.5,220000,'2025-03-12','active','2022-09-01',NULL,FALSE),
  (2,5,'Car Loan',4000000,2800000,9.9,95000,'2025-03-20','active','2023-02-01',NULL,FALSE),
  -- User 3 loans (account 8)
  (3,8,'Education Loan',2500000,1700000,7.2,70000,'2025-03-11','active','2023-09-01',NULL,FALSE),
  (3,8,'Phone Installment',450000,90000,13.0,45000,'2025-03-06','active','2024-04-01',NULL,FALSE);

-- 9. Goals (2 per user, 6 total)
INSERT INTO goals (user_id, goal_name, target_amount,
                   saved_amount, deadline, status, notes)
VALUES
  -- User 1
  (1,'Vacation in Europe',1500000,350000,'2025-08-01','active','Trip to Europe with family'),
  (1,'Emergency Fund',1000000,420000,'2025-12-31','active','3-6 months of expenses'),
  -- User 2
  (2,'New Car',8000000,1200000,'2026-05-01','active','Upgrade family car'),
  (2,'Child Education Fund',5000000,600000,'2028-09-01','active','University fund'),
  -- User 3
  (3,'Home Renovation',3000000,900000,'2026-03-01','active','Kitchen and bathroom'),
  (3,'Retirement Savings',7000000,2000000,'2035-01-01','active','Long-term retirement goal');

-- 10. Hand-crafted transactions that link to bills, loans and goals

-- Salary income transactions
INSERT INTO transactions
    (user_id, account_id, category_id, bill_id, loan_id, goal_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
VALUES
  (1,2,1,NULL,NULL,NULL,450000,'income','2025-02-25 09:00','February salary','OP-M1',NULL),
  (2,5,11,NULL,NULL,NULL,480000,'income','2025-02-25 09:00','February salary','OP-M2',NULL),
  (3,8,21,NULL,NULL,NULL,500000,'income','2025-02-25 09:00','February salary','OP-M3',NULL);

-- Bill payments
INSERT INTO transactions
    (user_id, account_id, category_id, bill_id, loan_id, goal_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
VALUES
  (1,2,4,1,NULL,NULL,15000,'expense','2025-03-09 18:00','Paid electricity bill','OP-M4',NULL),
  (2,5,14,5,NULL,NULL,13000,'expense','2025-03-07 18:00','Paid electricity bill','OP-M5',NULL),
  (3,8,24,9,NULL,NULL,14000,'expense','2025-03-08 18:00','Paid electricity bill','OP-M6',NULL);

-- Loan payments
INSERT INTO transactions
    (user_id, account_id, category_id, bill_id, loan_id, goal_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
VALUES
  (1,2,5,NULL,1,NULL,85000,'expense','2025-03-18 10:00','Car loan payment','OP-M7',NULL),
  (2,5,15,NULL,3,NULL,220000,'expense','2025-03-12 10:00','Mortgage payment','OP-M8',NULL),
  (3,8,25,NULL,5,NULL,70000,'expense','2025-03-11 10:00','Education loan payment','OP-M9',NULL);

-- Goal contribution
INSERT INTO transactions
    (user_id, account_id, category_id, bill_id, loan_id, goal_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
VALUES
  (1,2,2,NULL,NULL,1,100000,'expense','2025-03-01 12:00',
   'Transfer to vacation savings','OP-M10',NULL);

-- 11. Example transfer between two accounts of the same user (wallet -> card)
-- Two legs share the same transfer_id ('TR-1')
INSERT INTO transactions
    (user_id, account_id, category_id, bill_id, loan_id, goal_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
VALUES
  (3,7,23,NULL,NULL,NULL,30000,'transfer','2025-03-02 09:30',
   'Move cash to card','OP-T1','TR-1'),  -- from wallet
  (3,8,23,NULL,NULL,NULL,30000,'transfer','2025-03-02 09:30',
   'Move cash to card','OP-T2','TR-1');  -- to card

-- 12. Auto-generated everyday transactions for user 1 (100 rows)
-- Uses PostgreSQL generate_series to quickly populate realistic data.
INSERT INTO transactions
    (user_id, account_id, category_id,
     amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
SELECT
  1 AS user_id,
  2 AS account_id,                                    -- Nvard Main Card
  3 + (i % 7) AS category_id,                         -- rotate through expense categories 3-9
  (5000 + (i * 250))::NUMERIC(18,2) AS amount,        -- increasing amounts
  CASE WHEN i % 10 = 0 THEN 'income'
       ELSE 'expense'
  END AS tx_type,
  (TIMESTAMPTZ '2025-01-01' + (i || ' days')::interval) AS tx_timestamp,
  'Auto-generated transaction #' || i AS description,
  'OP-G-' || i AS operation_id,
  NULL AS transfer_id
FROM generate_series(1,100) AS s(i);
