------------------------------------------------------------
-- PERSONAL FINANCE APP - SAMPLE DML
-- Assumes all tables & ENUMs from your final DDL already exist
------------------------------------------------------------

------------------------------------------------------------
-- USERS
------------------------------------------------------------
INSERT INTO users (full_name, email, password_hash, status, subscription) VALUES
('Sheldon Cooper','sheldon@caltech.edu','hash_sheldon','active','premium'),
('Leonard Hofstadter','leonard@caltech.edu','hash_leonard','active','pro'),
('Penny','penny@cheesecakefactory.com','hash_penny','active','free'),
('Howard Wolowitz','howard@nasa.gov','hash_howard','active','pro'),
('Raj Koothrappali','raj@caltech.edu','hash_raj','active','free'),
('Amy Farrah Fowler','amy@caltech.edu','hash_amy','active','pro'),
('Bernadette Rostenkowski','bernadette@pharma.com','hash_bernie','active','premium'),
('Sheldon Test','test_sheldon@caltech.edu','hash_sheldon_test','inactive','premium_pro_max'),
('Armenian Neighbor', 'hovik_abrahamyan@mail.ru', 'hash_mukik', 'active', 'free')
;

------------------------------------------------------------
-- CURRENCIES
------------------------------------------------------------
INSERT INTO currencies (currency_code, name, symbol, is_default) VALUES
('AMD','Armenian Dram','֏',TRUE),
('USD','US Dollar','$',FALSE),
('EUR','Euro','€',FALSE),
('GBP','British Pound','£',FALSE),
('INR','Indian Rupee','₹',FALSE)
;

------------------------------------------------------------
-- EXCHANGE RATES
------------------------------------------------------------
INSERT INTO exchange_rates (base_currency_code, target_currency_code, rate, updated_at) VALUES
('USD','EUR',0.92,'2024-12-01 10:00:00'),
('EUR','USD',1.09,'2024-12-01 10:00:00'),
('USD','GBP',0.80,'2024-12-01 10:00:00'),
('GBP','USD',1.25,'2024-12-01 10:00:00'),
('USD','AMD',400.00,'2024-12-01 10:00:00'),
('AMD','USD',0.0025,'2024-12-01 10:00:00'),
('USD','EUR',0.93,'2025-02-01 10:00:00'),
('USD','EUR',0.95,'2025-03-01 10:00:00');

------------------------------------------------------------
-- ACCOUNTS
-- We fix account_id explicitly for easier FK usage
------------------------------------------------------------
INSERT INTO accounts (account_id, user_id, currency_code, account_name, account_number, account_type, allow_overdraft, current_balance)
VALUES
(1,1,'USD','Sheldon Checking','US-SHELDON-CHK','current account',TRUE,3000.00),
(2,1,'USD','Sheldon Cash Wallet',NULL,'cash',FALSE,73),
(3,2,'USD','Leonard Checking','US-LEONARD-CHK','current account',TRUE,2800.00),
(4,3,'USD','Penny Checking','US-PENNY-CHK','debit card',TRUE,900.00),
(5,4,'USD','Howard NASA Payroll','US-HOWARD-CHK','current account',TRUE,3500.00),
(6,5,'USD','Raj Main Account','US-RAJ-CHK','current account',TRUE,4500.00),
(7,6,'USD','Amy Research Account','US-AMY-CHK','current account',TRUE,6200.00),
(8,7,'USD','Bernadette Pharma Account','US-BERNIE-CHK','current account',TRUE,9000.00),
(9,5,'INR','Raj Hindu Account','IN-RAJ-CHK','current account',TRUE,5318008),
(10,1,'AMD','Sheldon Safe No-One-Knows','AMD-SHELDON-CHK','cash',FALSE,314159265.35)
;

------------------------------------------------------------
-- CATEGORIES (with hierarchy)
------------------------------------------------------------
INSERT INTO categories (category_id, user_id, category_name, category_type, parent_category_id) VALUES
-- Sheldon (user_id = 1)
(1, 1,'Physics salary','income',NULL),
(2, 1,'Consulting income','income',1),

(3, 1,'Rent','expense',NULL),
(4, 1,'Rent - Apartment 4A','expense',3),

(5, 1,'Comics','expense',NULL),
(6, 1,'Comics - DC','expense',5),
(7, 1,'Comics - Marvel','expense',5),

(8, 1,'Food','expense',NULL),
(9, 1,'Food - Thai','expense',8),
(10,1,'Food - Chinese','expense',8),
(11,1,'Food - Forced','expense',8),     -- when he’s forced to eat things he hates

(12,1,'Trains','expense',NULL),
(13,1,'Notebooks & Pens','expense',NULL),
(14,1,'Costumes','expense',NULL),

-- Leonard (user_id = 2)
(21,2,'Physics salary','income',NULL),
(22,2,'Physics bonus','income',21),

(23,2,'Rent','expense',NULL),
(24,2,'Rent - Apartment 4A share','expense',23),

(25,2,'Date night','expense',NULL),
(26,2,'Date night - Penny','expense',25),

(27,2,'Gadgets','expense',NULL),
(28,2,'Gadgets - Lab gear','expense',27),
(29,2,'Costumes','expense',NULL),

-- Penny (user_id = 3)
(31,3,'Waitress tips','income',NULL),
(32,3,'Acting gigs','income',NULL),
(33,3,'Acting - Commercials','income',32),

(34,3,'Rent','expense',NULL),
(35,3,'Rent - Apartment','expense',34),

(36,3,'Wine','expense',NULL),
(37,3,'Wine - Girls night','expense',36),

(38,3,'Clothes','expense',NULL),
(39,3,'Cosmetics','expense',NULL),

-- Howard (user_id = 4)
(41,4,'Engineering salary','income',NULL),
(42,4,'NASA bonus','income',41),

(43,4,'Space toys','expense',NULL),
(44,4,'Takeout','expense',NULL),
(45,4,'Magic tricks','expense',NULL),

-- Raj (user_id = 5)
(51,5,'Allowance from parents','income',NULL),
(52,5,'Astrophysics consulting','income',51),

(53,5,'Coffee','expense',NULL),
(54,5,'Coffee - Fancy','expense',53),

(55,5,'Online shopping','expense',NULL),
(56,5,'Dog expenses','expense',NULL),
(57,5,'Cosmetics','expense',NULL),

-- Amy (user_id = 6)
(61,6,'Neuroscience grant','income',NULL),

(62,6,'Lab equipment','expense',NULL),
(63,6,'Monkeys','expense',NULL),
(64,6,'Crowns & Tiaras','expense',NULL),
(65,6,'Crowns - Tiara','expense',64),   -- “It’s a tiara!”
(66,6,'Romantic gifts','expense',NULL),

-- Bernadette (user_id = 7)
(71,7,'Pharma salary','income',NULL),
(72,7,'Pharma bonus','income',71),

(73,7,'Experiments','expense',NULL),
(74,7,'Family','expense',NULL),
(75,7,'Chemicals','expense',73),
(76,7,'Baby stuff','expense',74)
;

------------------------------------------------------------
-- BUDGETS
------------------------------------------------------------
INSERT INTO budgets (category_id, limit_amount, alert_threshold, period_type, is_active) VALUES
(8,  500.00,80.0,'monthly',TRUE),   -- Sheldon Food
(5,  200.00,70.0,'monthly',TRUE),   -- Sheldon Comics
(36, 150.00,75.0,'monthly',TRUE),   -- Penny Wine
(43, 300.00,80.0,'monthly',TRUE),   -- Howard Space Toys
(53, 120.00,75.0,'monthly',TRUE),   -- Raj Coffee
(64, 200.00,70.0,'monthly',TRUE),   -- Amy Tiaras
(73, 500.00,70.0,'monthly',TRUE) 	 -- Bernadette Experiments
;  

------------------------------------------------------------
-- BILLS
------------------------------------------------------------
INSERT INTO bills (bill_id, user_id, account_id, bill_name, amount_due, due_date, is_paid, recurring_frequency, status, notes) VALUES
(1,1,1,'Internet Bill 4A',79.99,'2025-01-10',TRUE,'monthly','paid',
 'Sheldon: "Leonard, someone used 12% more bandwidth than usual."'),
(2,1,1,'Electricity Bill 4A',73.00,'2025-01-20',FALSE,'monthly','pending',
 'Sheldon: "73 is the best number. The bill amount is acceptable."'),

(3,2,3,'Rent Share 4A',850.00,'2025-01-05',TRUE,'monthly','paid',
 'Leonard: "Paid rent and 100% of the emotional surcharge."'),

(4,3,4,'Penny Apartment Rent',1200.00,'2025-01-03',TRUE,'monthly','paid',
 'Penny: "A little late, but I brought muffins."'),
(5,3,4,'Acting Workshop Fee',300.00,'2025-01-18',TRUE,'monthly','paid',
 'Penny: "This workshop is totally the one that changes everything."'),

(6,4,5,'Wolowitz Water Bill',60.00,'2025-01-13',TRUE,'monthly','paid',
 'Howard: "Maybe we don’t need three showers a day, Bernie."'),

(7,5,6,'Raj Streaming Services',35.00,'2025-01-20',TRUE,'monthly','paid',
 'Raj: "Streaming dog documentaries is self-care."'),

(8,6,7,'Science Journal Subscription',110.00,'2025-01-07',TRUE,'yearly','paid',
 'Amy: "Neuron Quarterly is the highlight of my month."'),

(9,7,8,'Family Healthcare',600.00,'2025-01-25',FALSE,'monthly','pending',
 'Bernadette: "Howard, if you lose another insurance form, I will end you."')
 ;

------------------------------------------------------------
-- LOANS
------------------------------------------------------------
INSERT INTO loans (loan_id, user_id, account_id, loan_name, principal_amount, remaining_amount,
                   interest_rate_pct, payment_amount, next_due_date, status, start_date, end_date, is_paid)
VALUES
(1,2,3,'Leonard Student Loan',30000.00,12000.00,3.5,400.00,'2025-02-01','active','2015-01-01',NULL,FALSE),
(2,4,5,'Space Toilet Project Loan',20000.00,8000.00,4.0,350.00,'2025-02-03','active','2018-05-01',NULL,FALSE),
(3,5,6,'Raj Telescope Loan',10000.00,3000.00,4.5,250.00,'2025-02-05','active','2019-09-01',NULL,FALSE)
;

------------------------------------------------------------
-- GOALS
------------------------------------------------------------
INSERT INTO goals (goal_id, user_id, goal_name, target_amount, saved_amount, deadline, status, notes)
VALUES
(1,1,'Full-size vintage train set',5000.00,1200.00,'2025-12-31','active',
 'Sheldon: "When this is complete, the living room becomes a railway."'),
(2,2,'Engagement ring fund',4000.00,2500.00,'2025-06-30','active',
 'Leonard: "For Penny. Hopefully she says yes this time."'),
(3,3,'Acting classes in Hollywood',3000.00,600.00,'2025-09-30','active',
 'Penny: "I am NOT dying a waitress."'),
(4,4,'Zero-gravity trip',7000.00,1400.00,'2026-01-01','active',
 'Howard: "I will float again and not die this time."'),
(5,5,'Adopt a dog',800.00,200.00,'2025-07-01','active',
 'Raj: "Cinnamon deserves a friend."'),
(6,6,'Monkey cognition lab fund',6000.00,1500.00,'2026-03-01','active',
 'Amy: "The monkeys will be treated better than Sheldon."'),
(7,7,'Private basement lab',10000.00,4000.00,'2026-12-31','active',
 'Bernadette: "Nothing evil, just… science."')
;

------------------------------------------------------------
-- OPERATIONS (a pool of IDs reused by many transactions)
------------------------------------------------------------
INSERT INTO operations (operation_id, created_at, request_hash, metadata) VALUES
('00000000-0000-0000-0000-000000000001',NOW(),'op_sheldon_salary',NULL),
('00000000-0000-0000-0000-000000000002',NOW(),'op_sheldon_rent',NULL),
('00000000-0000-0000-0000-000000000003',NOW(),'op_sheldon_food',NULL),
('00000000-0000-0000-0000-000000000004',NOW(),'op_sheldon_forced_food',NULL),
('00000000-0000-0000-0000-000000000005',NOW(),'op_sheldon_comics',NULL),
('00000000-0000-0000-0000-000000000006',NOW(),'op_sheldon_notebook',NULL),
('00000000-0000-0000-0000-000000000007',NOW(),'op_sheldon_trains',NULL),
('00000000-0000-0000-0000-000000000008',NOW(),'op_sheldon_transfer',NULL),

('00000000-0000-0000-0000-000000000009',NOW(),'op_leonard_salary',NULL),
('00000000-0000-0000-0000-00000000000a',NOW(),'op_leonard_rent',NULL),
('00000000-0000-0000-0000-00000000000b',NOW(),'op_leonard_date',NULL),
('00000000-0000-0000-0000-00000000000c',NOW(),'op_leonard_gadget',NULL),
('00000000-0000-0000-0000-00000000000d',NOW(),'op_leonard_loan',NULL),

('00000000-0000-0000-0000-00000000000e',NOW(),'op_penny_tips',NULL),
('00000000-0000-0000-0000-00000000000f',NOW(),'op_penny_acting',NULL),
('00000000-0000-0000-0000-000000000010',NOW(),'op_penny_rent',NULL),
('00000000-0000-0000-0000-000000000011',NOW(),'op_penny_wine',NULL),
('00000000-0000-0000-0000-000000000012',NOW(),'op_penny_clothes',NULL),
('00000000-0000-0000-0000-000000000013',NOW(),'op_penny_goal',NULL),

('00000000-0000-0000-0000-000000000014',NOW(),'op_howard_salary',NULL),
('00000000-0000-0000-0000-000000000015',NOW(),'op_howard_space_toy',NULL),
('00000000-0000-0000-0000-000000000016',NOW(),'op_howard_takeout',NULL),
('00000000-0000-0000-0000-000000000017',NOW(),'op_howard_magic',NULL),
('00000000-0000-0000-0000-000000000018',NOW(),'op_howard_loan',NULL),

('00000000-0000-0000-0000-000000000019',NOW(),'op_raj_allowance',NULL),
('00000000-0000-0000-0000-00000000001a',NOW(),'op_raj_coffee',NULL),
('00000000-0000-0000-0000-00000000001b',NOW(),'op_raj_shop',NULL),
('00000000-0000-0000-0000-00000000001c',NOW(),'op_raj_loan',NULL),
('00000000-0000-0000-0000-00000000001d',NOW(),'op_raj_dog_goal',NULL),

('00000000-0000-0000-0000-00000000001e',NOW(),'op_amy_grant',NULL),
('00000000-0000-0000-0000-00000000001f',NOW(),'op_amy_lab',NULL),
('00000000-0000-0000-0000-000000000020',NOW(),'op_amy_monkeys',NULL),
('00000000-0000-0000-0000-000000000021',NOW(),'op_amy_tiara',NULL),
('00000000-0000-0000-0000-000000000022',NOW(),'op_amy_romantic',NULL),
('00000000-0000-0000-0000-000000000023',NOW(),'op_amy_goal',NULL),

('00000000-0000-0000-0000-000000000024',NOW(),'op_bernie_salary',NULL),
('00000000-0000-0000-0000-000000000025',NOW(),'op_bernie_experiments',NULL),
('00000000-0000-0000-0000-000000000026',NOW(),'op_bernie_baby',NULL),
('00000000-0000-0000-0000-000000000027',NOW(),'op_bernie_lab_goal',NULL),
('00000000-0000-0000-0000-000000000028',NOW(),'op_misc_pattern',NULL)
;

------------------------------------------------------------
-- TRANSACTIONS
-- Columns:
-- account_id, category_id, amount, tx_type, tx_timestamp,
-- bill_id, loan_id, goal_id, description, operation_id
------------------------------------------------------------
INSERT INTO transactions
(account_id, category_id, amount, tx_type, tx_timestamp, bill_id, loan_id, goal_id, description, operation_id)
VALUES
------------------------------------------------------------
-- SHELDON (user_id = 1, accounts 1 & 2)
------------------------------------------------------------
(1,1,4500.00,'income','2025-01-01 09:00:00',NULL,NULL,NULL,
 'Sheldon: "My salary arrived. It is still insufficient for a mind of my caliber."', '00000000-0000-0000-0000-000000000001'),
(1,4,1500.00,'expense','2025-01-03 10:00:00',1,NULL,NULL,
 'Sheldon: "Rent for 4A paid. Leonard, you are welcome."', '00000000-0000-0000-0000-000000000002'),
(1,9,60.00,'expense','2025-01-06 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Tuesday. It is on the schedule."', '00000000-0000-0000-0000-000000000003'),
(1,11,35.00,'expense','2025-01-07 19:30:00',NULL,NULL,NULL,
 'Sheldon: "Leonard forced me to eat a vegetable. I demand justice."', '00000000-0000-0000-0000-000000000004'),
(1,6,73.00,'expense','2025-01-10 18:30:00',NULL,NULL,NULL,
 'Sheldon: "I spent exactly 73 dollars on comics. Best number, best purchase."', '00000000-0000-0000-0000-000000000005'),
(1,13,42.00,'expense','2025-01-12 09:00:00',NULL,NULL,NULL,
 'Sheldon: "New notebook. The old one was contaminated by Penny''s handwriting."', '00000000-0000-0000-0000-000000000006'),
(1,12,120.00,'expense','2025-01-15 15:00:00',NULL,NULL,1,
 'Sheldon: "New model train bridge. The layout approaches perfection."', '00000000-0000-0000-0000-000000000007'),
(1,6,40.00,'expense','2025-01-20 17:00:00',NULL,NULL,NULL,
 'Sheldon: "Emergency comic-buying after emotional distress. Bazinga therapy."', '00000000-0000-0000-0000-000000000005'),
(1,11,28.00,'expense','2025-01-22 19:30:00',NULL,NULL,NULL,
 'Sheldon: "Penny made me eat kale. This is a hate crime against taste buds."', '00000000-0000-0000-0000-000000000004'),
-- electricity bill
(1,3,73.00,'expense','2025-01-20 12:00:00',2,NULL,NULL,
 'Sheldon: "The electric bill is 73 dollars. Of course it is."', '00000000-0000-0000-0000-000000000002'),

-- transfer: checking -> cash (two legs, one operation)
(1,NULL,100.00,'transfer','2025-01-02 10:00:00',NULL,NULL,NULL,
 'Sheldon: "Transferring emergency comic funds to my wallet."', '00000000-0000-0000-0000-000000000008'),
(2,NULL,100.00,'transfer','2025-01-02 10:00:01',NULL,NULL,NULL,
 'Sheldon: "Wallet topped up. I am now mobile and dangerous."', '00000000-0000-0000-0000-000000000008'),

-- recurring Thai Tuesdays
(1,9,60.00,'expense','2025-01-13 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Tuesday, week two. Consistency is key."', '00000000-0000-0000-0000-000000000003'),
(1,9,60.00,'expense','2025-01-20 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Tuesday, week three. Deviations are unacceptable."', '00000000-0000-0000-0000-000000000003'),
(1,9,60.00,'expense','2025-01-27 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Tuesday, week four. This brings me joy."', '00000000-0000-0000-0000-000000000003'),

-- more comics & notebooks
(1,6,30.00,'expense','2025-02-01 17:30:00',NULL,NULL,NULL,
 'Sheldon: "New issue of The Flash. Leonard is not allowed to touch it."', '00000000-0000-0000-0000-000000000005'),
(1,13,38.00,'expense','2025-02-03 09:10:00',NULL,NULL,NULL,
 'Sheldon: "Fresh notebooks. I filled the last one with string theory and roommate agreements."', '00000000-0000-0000-0000-000000000006'),

------------------------------------------------------------
-- LEONARD (user_id = 2, account 3)
------------------------------------------------------------
(3,21,4300.00,'income','2025-01-01 09:30:00',NULL,NULL,NULL,
 'Leonard: "Payday. Most of this goes to rent and emotional damage."', '00000000-0000-0000-0000-000000000009'),
(3,24,850.00,'expense','2025-01-03 10:05:00',3,NULL,NULL,
 'Leonard: "Rent to Sheldon. Comes with free passive-aggressive comments."', '00000000-0000-0000-0000-00000000000a'),
(3,26,80.00,'expense','2025-01-08 20:00:00',NULL,NULL,NULL,
 'Leonard: "Date night with Penny. Sheldon texted me 27 times."', '00000000-0000-0000-0000-00000000000b'),
(3,27,150.00,'expense','2025-01-12 14:00:00',NULL,NULL,NULL,
 'Leonard: "New gadget for the lab. Sheldon will pretend it was his idea."', '00000000-0000-0000-0000-00000000000c'),
(3,29,60.00,'expense','2025-01-25 18:00:00',NULL,NULL,NULL,
 'Leonard: "Costume for the party. I did not lose the Hulk argument."', '00000000-0000-0000-0000-00000000000c'),
(3,24,400.00,'expense','2025-01-20 09:00:00',NULL,1,NULL,
 'Leonard: "Student loan payment. Should have become a plumber."', '00000000-0000-0000-0000-00000000000d'),
(3,22,200.00,'income','2025-02-01 09:00:00',NULL,NULL,NULL,
 'Leonard: "Small physics bonus. Sheldon called it ''cute''."', '00000000-0000-0000-0000-000000000009'),
(3,26,95.00,'expense','2025-02-07 20:30:00',NULL,NULL,2,
 'Leonard: "Valentine''s dinner with Penny. Please don''t let this blow up."', '00000000-0000-0000-0000-00000000000b'),

------------------------------------------------------------
-- PENNY (user_id = 3, account 4)
------------------------------------------------------------
(4,31,250.00,'income','2025-01-02 23:00:00',NULL,NULL,NULL,
 'Penny: "Great shift at Cheesecake Factory. Only two creepy guys."', '00000000-0000-0000-0000-00000000000e'),
(4,33,600.00,'income','2025-01-15 11:00:00',NULL,NULL,NULL,
 'Penny: "I did a hemorrhoid commercial. Money is money."', '00000000-0000-0000-0000-00000000000f'),
(4,35,1200.00,'expense','2025-01-05 09:30:00',4,NULL,NULL,
 'Penny: "Paid rent! And I only had to borrow from Leonard once."', '00000000-0000-0000-0000-000000000010'),
-- fix: correctly specify columns:
(4,35,1200.00,'expense','2025-01-05 09:30:00',4,NULL,NULL,
 'Penny: "Paid rent! And I only had to borrow from Leonard once."', '00000000-0000-0000-0000-000000000010'),
(4,37,45.00,'expense','2025-01-09 21:00:00',NULL,NULL,NULL,
 'Penny: "Girls'' night wine with Amy and Bernie. We roasted the boys."', '00000000-0000-0000-0000-000000000011'),
(4,38,120.00,'expense','2025-01-11 16:00:00',NULL,NULL,NULL,
 'Penny: "New shoes. Totally on sale. Kind of."', '00000000-0000-0000-0000-000000000012'),
(4,39,55.00,'expense','2025-01-18 14:30:00',NULL,NULL,NULL,
 'Penny: "Makeup for auditions. Leonard pretended not to see the receipt."', '00000000-0000-0000-0000-000000000012'),
(4,32,200.00,'expense','2025-01-27 14:00:00',5,NULL,3,
 'Penny: "Putting money aside for acting classes instead of boots. Growth."', '00000000-0000-0000-0000-000000000013'),
(4,36,35.00,'expense','2025-02-10 21:00:00',NULL,NULL,NULL,
 'Penny: "Wine after a terrible audition. The wine nailed it though."', '00000000-0000-0000-0000-000000000011'),

------------------------------------------------------------
-- HOWARD (user_id = 4, account 5)
------------------------------------------------------------
(5,41,5000.00,'income','2025-01-01 08:45:00',NULL,NULL,NULL,
 'Howard: "Engineer salary. Still not enough to impress my mother."', '00000000-0000-0000-0000-000000000014'),
(5,43,220.00,'expense','2025-01-06 13:00:00',NULL,NULL,NULL,
 'Howard: "Limited edition space shuttle model. Totally necessary."', '00000000-0000-0000-0000-000000000015'),
(5,44,60.00,'expense','2025-01-07 19:30:00',NULL,NULL,NULL,
 'Howard: "Takeout again. The kitchen table is full of robot parts."', '00000000-0000-0000-0000-000000000016'),
(5,45,90.00,'expense','2025-01-09 21:00:00',NULL,NULL,NULL,
 'Howard: "New magic trick. Bernadette is only mildly impressed."', '00000000-0000-0000-0000-000000000017'),
(5,44,55.00,'expense','2025-02-11 19:30:00',NULL,NULL,NULL,
 'Howard: "Takeout during a Mars Rover crisis. Again."', '00000000-0000-0000-0000-000000000016'),
(5,43,350.00,'expense','2025-01-21 09:15:00',NULL,2,NULL,
 'Howard: "Loan payment for the space toilet that almost killed me."', '00000000-0000-0000-0000-000000000018'),
(5,41,500.00,'income','2025-02-01 08:30:00',NULL,NULL,NULL,
 'Howard: "NASA bonus. Please address me as Commander Wolowitz."', '00000000-0000-0000-0000-000000000014'),
(5,41,250.00,'expense','2025-01-28 10:00:00',NULL,NULL,4,
 'Howard: "Putting cash into zero-gravity trip fund. Our kids will float."', '00000000-0000-0000-0000-000000000018'),

------------------------------------------------------------
-- RAJ (user_id = 5, account 6)
------------------------------------------------------------
(6,51,3000.00,'income','2025-01-01 09:15:00',NULL,NULL,NULL,
 'Raj: "Allowance from my parents. Again."', '00000000-0000-0000-0000-000000000019'),
(6,53,75.00,'expense','2025-01-04 10:30:00',NULL,NULL,NULL,
 'Raj: "Coffee to practice talking to women. Silent failure, great latte."', '00000000-0000-0000-0000-00000000001a'),
(6,55,180.00,'expense','2025-01-09 22:00:00',NULL,NULL,NULL,
 'Raj: "Online shopping for dog accessories. Still no dog."', '00000000-0000-0000-0000-00000000001b'),
(6,54,45.00,'expense','2025-02-12 10:00:00',NULL,NULL,NULL,
 'Raj: "Fancy coffee that definitely cost more than my confidence."', '00000000-0000-0000-0000-00000000001a'),
(6,55,250.00,'expense','2025-01-22 09:30:00',NULL,3,NULL,
 'Raj: "Telescope loan payment. I mostly use it to look at Cinnamon."', '00000000-0000-0000-0000-00000000001c'),
(6,56,150.00,'expense','2025-01-29 11:00:00',NULL,NULL,5,
 'Raj: "Saving for a dog. Maybe one that talks so I don''t have to."', '00000000-0000-0000-0000-00000000001d'),
-- streaming bill
(6,53,35.00,'expense','2025-01-20 08:00:00',7,NULL,NULL,
 'Raj: "Streaming services paid. Dog shows and K-dramas are essential."', '00000000-0000-0000-0000-00000000001b'),

------------------------------------------------------------
-- AMY (user_id = 6, account 7)
------------------------------------------------------------
(7,61,7000.00,'income','2025-01-01 10:00:00',NULL,NULL,NULL,
 'Amy: "Grant money arrived. Time to buy morally questionable equipment."', '00000000-0000-0000-0000-00000000001e'),
(7,62,900.00,'expense','2025-01-05 14:00:00',NULL,NULL,NULL,
 'Amy: "Microscope upgrade. Sheldon is not allowed to touch it."', '00000000-0000-0000-0000-00000000001f'),
(7,63,300.00,'expense','2025-01-08 11:30:00',NULL,NULL,NULL,
 'Amy: "Monkey enrichment toys. Ethics board mildly concerned."', '00000000-0000-0000-0000-000000000020'),
(7,65,150.00,'expense','2025-01-09 16:00:00',NULL,NULL,NULL,
 'Amy: "It''s a tiara! I have a tiara!"', '00000000-0000-0000-0000-000000000021'),
(7,66,80.00,'expense','2025-01-14 20:00:00',NULL,NULL,NULL,
 'Amy: "Romantic gift for Sheldon. He responded with a flowchart."', '00000000-0000-0000-0000-000000000022'),
(7,61,400.00,'expense','2025-01-30 09:00:00',NULL,NULL,6,
 'Amy: "Adding to monkey cognition fund. Sheldon is jealous."', '00000000-0000-0000-0000-000000000023'),
-- journal subscription
(7,62,110.00,'expense','2025-01-07 08:30:00',8,NULL,NULL,
 'Amy: "Journal subscription renewed. Science doesn''t read itself."', '00000000-0000-0000-0000-00000000001f'),

------------------------------------------------------------
-- BERNADETTE (user_id = 7, account 8)
------------------------------------------------------------
(8,71,9000.00,'income','2025-01-01 08:30:00',NULL,NULL,NULL,
 'Bernadette: "Big pharma paycheck. I''m tiny, my salary isn''t."', '00000000-0000-0000-0000-000000000024'),
(8,73,500.00,'expense','2025-01-06 15:00:00',NULL,NULL,NULL,
 'Bernadette: "Experiment supplies. Don''t ask, you''ll sleep better."', '00000000-0000-0000-0000-000000000025'),
(8,76,300.00,'expense','2025-01-09 17:00:00',NULL,NULL,NULL,
 'Bernadette: "Baby stuff for Halley. She screams like a smoke alarm."', '00000000-0000-0000-0000-000000000026'),
(8,75,300.00,'expense','2025-01-23 09:45:00',NULL,NULL,NULL,
 'Bernadette: "Lab chemicals. Nothing that would technically violate treaties."', '00000000-0000-0000-0000-000000000025'),
(8,71,800.00,'expense','2025-01-31 08:30:00',NULL,NULL,7,
 'Bernadette: "Saving for my own secret lab. Nothing ominous."', '00000000-0000-0000-0000-000000000027'),
-- healthcare bill
(8,74,600.00,'expense','2025-01-25 13:00:00',9,NULL,NULL,
 'Bernadette: "Family healthcare. Howard, fill in your forms on time!"', '00000000-0000-0000-0000-000000000024'),

------------------------------------------------------------
-- MORE PATTERN / RECURRING TRANSACTIONS
-- These give you enough density for reports (monthly, per-category, etc.)
-- You can copy/extend these patterns to reach 200+ rows easily.
------------------------------------------------------------

-- More Sheldon Thai Tuesdays & comics in February
(1,9,60.00,'expense','2025-02-03 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Monday is insanity, Thai food Tuesday is order."', '00000000-0000-0000-0000-000000000003'),
(1,9,60.00,'expense','2025-02-10 19:00:00',NULL,NULL,NULL,
 'Sheldon: "Thai food Tuesday. I love consistency almost as much as trains."', '00000000-0000-0000-0000-000000000003'),
(1,6,30.00,'expense','2025-02-15 17:30:00',NULL,NULL,NULL,
 'Sheldon: "New issue of Green Lantern. Leonard may observe from a distance."', '00000000-0000-0000-0000-000000000005'),

-- Leonard extra dates & gadgets
(3,26,90.00,'expense','2025-02-14 20:00:00',NULL,NULL,2,
 'Leonard: "Valentine''s dinner with Penny. No breakups this time."', '00000000-0000-0000-0000-00000000000b'),
(3,28,110.00,'expense','2025-02-21 15:30:00',NULL,NULL,NULL,
 'Leonard: "New laser pointer for experiments and annoying Sheldon."', '00000000-0000-0000-0000-00000000000c'),

-- Penny regular wine nights & clothes
(4,37,50.00,'expense','2025-02-06 21:30:00',NULL,NULL,NULL,
 'Penny: "Wine night with Amy. We ranked Sheldon''s breakdowns."', '00000000-0000-0000-0000-000000000011'),
(4,38,95.00,'expense','2025-02-17 16:30:00',NULL,NULL,NULL,
 'Penny: "New dress for date night. Leonard almost fainted."', '00000000-0000-0000-0000-000000000012'),

-- Howard more takeout & toys
(5,44,48.00,'expense','2025-02-05 19:40:00',NULL,NULL,NULL,
 'Howard: "Takeout during a late-night engineering crisis."', '00000000-0000-0000-0000-000000000016'),
(5,43,180.00,'expense','2025-02-19 13:30:00',NULL,NULL,NULL,
 'Howard: "New rocket model. Halley tried to eat the fins."', '00000000-0000-0000-0000-000000000015'),

-- Raj more coffee & shopping
(6,53,39.00,'expense','2025-02-08 10:20:00',NULL,NULL,NULL,
 'Raj: "Another coffee to build courage. Talked to barista''s dog instead."', '00000000-0000-0000-0000-00000000001a'),
(6,55,95.00,'expense','2025-02-22 22:10:00',NULL,NULL,NULL,
 'Raj: "Online shopping. Bought sweater for Cinnamon. She hates it."', '00000000-0000-0000-0000-00000000001b'),

-- Amy more lab & romantic gestures
(7,62,520.00,'expense','2025-02-03 14:10:00',NULL,NULL,NULL,
 'Amy: "Ordered fancy electrodes. Sheldon asked if he could wear them."', '00000000-0000-0000-0000-00000000001f'),
(7,66,65.00,'expense','2025-02-25 19:00:00',NULL,NULL,NULL,
 'Amy: "Another present for Sheldon. He countered with a new clause in the Relationship Agreement."', '00000000-0000-0000-0000-000000000022'),

-- Bernadette more experiments & family stuff
(8,73,280.00,'expense','2025-02-04 15:45:00',NULL,NULL,NULL,
 'Bernadette: "Experiment supplies. Howard doesn''t need to know the details."', '00000000-0000-0000-0000-000000000025'),
(8,74,220.00,'expense','2025-02-18 17:20:00',NULL,NULL,NULL,
 'Bernadette: "Family dinner out. I threatened Howard for tipping badly."', '00000000-0000-0000-0000-000000000024')
 ;
