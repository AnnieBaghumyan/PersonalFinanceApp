import psycopg2
from psycopg2 import sql
from datetime import date
import sys
import getpass

# ==============================
# DB configuration - update this
# ==============================


password = getpass.getpass("Enter password: ")

DB_NAME = "personal_finance_project"
DB_USER = "postgres"
DB_PASSWORD = password
DB_HOST = "localhost"
DB_PORT = 5432


def get_connection():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )


def print_menu():
    print()
    print("Menu:")
    print("  1) List users")
    print("  2) List accounts for a user")
    print("  3) Show recent transactions for an account")
    print("  4) Add a new transaction (income/expense)")
    print("  5) Show monthly cash-flow report for a user")
    print("  0) Exit")


# ==========================
# 1) List users
# ==========================
def list_users(conn):
    query = """
        SELECT user_id, full_name, email, subscription, status, created_at
        FROM users
        ORDER BY user_id;
    """
    with conn.cursor() as cur:
        cur.execute(query)
        rows = cur.fetchall()

    print("Users:")
    for row in rows:
        user_id, full_name, email, subscription, status, created_at = row
        print(
            f"  #{user_id} | {full_name} | {email} | "
            f"{subscription} | {status} | created: {created_at}"
        )


# ==========================
# 2) List accounts for a user
# ==========================
def list_accounts_for_user(conn):
    try:
        user_id = int(input("Enter user_id: ").strip())
    except ValueError:
        print("Invalid user_id.")
        return

    query = """
        SELECT account_id, account_name, account_type, currency_code,
               current_balance, is_active, created_at
        FROM accounts
        WHERE user_id = %s
        ORDER BY account_id;
    """
    with conn.cursor() as cur:
        cur.execute(query, (user_id,))
        rows = cur.fetchall()

    if not rows:
        print(f"No accounts found for user #{user_id}.")
        return

    print(f"Accounts for user #{user_id}:")
    for row in rows:
        account_id, account_name, account_type, currency_code, balance, is_active, created_at = row
        print(
            f"  #{account_id} | {account_name} | type={account_type} | "
            f"{currency_code} {balance:.2f} | active={is_active} | created={created_at}"
        )


# ==========================
# 3) Show recent transactions for an account
# ==========================
def show_recent_transactions(conn):
    try:
        account_id = int(input("Enter account_id: ").strip())
    except ValueError:
        print("Invalid account_id.")
        return

    try:
        limit = int(input("How many recent transactions to show? (e.g. 10): ").strip())
    except ValueError:
        print("Invalid number.")
        return

    query = """
        SELECT t.tx_id,
               t.tx_timestamp,
               t.tx_type,
               t.amount,
               t.description,
               c.category_name,
               t.transfer_id
        FROM transactions t
        LEFT JOIN categories c ON c.category_id = t.category_id
        WHERE t.account_id = %s
        ORDER BY t.tx_timestamp DESC, t.tx_id DESC
        LIMIT %s;
    """
    with conn.cursor() as cur:
        cur.execute(query, (account_id, limit))
        rows = cur.fetchall()

    if not rows:
        print(f"No transactions found for account #{account_id}.")
        return

    print(f"Recent transactions for account #{account_id}:")
    for row in rows:
        tx_id, tx_timestamp, tx_type, amount, description, category_name, transfer_id = row
        category_name = category_name or "-"
        transfer_id = transfer_id or "-"
        description = description or ""
        print(
            f"  #{tx_id} | {tx_timestamp} | {tx_type:<8} | {amount:.2f} | "
            f"cat={category_name} | transfer={transfer_id} | {description}"
        )


# ==========================
# 4) Add a new transaction
# ==========================
def add_transaction(conn):
    try:
        user_id = int(input("Enter user_id: ").strip())
    except ValueError:
        print("Invalid user_id.")
        return

    try:
        account_id = int(input("Enter account_id: ").strip())
    except ValueError:
        print("Invalid account_id.")
        return

    cat_input = input("Enter category_id (or 0 if none): ").strip()
    try:
        category_id = int(cat_input)
    except ValueError:
        print("Invalid category_id.")
        return
    category_id_obj = None if category_id == 0 else category_id

    tx_type = input("Transaction type (income/expense): ").strip().lower()
    if tx_type not in ("income", "expense"):
        print("Invalid type. Only 'income' or 'expense' allowed.")
        return

    try:
        amount = float(input("Amount (positive number): ").strip())
    except ValueError:
        print("Invalid amount.")
        return
    if amount <= 0:
        print("Amount must be positive.")
        return

    description = input("Short description: ").strip()

    operation_id = "APP-" + str(int(date.today().strftime("%Y%m%d")) * 100000 + hash(description) % 100000)

    query = """
        INSERT INTO transactions
            (user_id, account_id, category_id, bill_id, loan_id, goal_id,
             amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
        VALUES
            (%s, %s, %s, NULL, NULL, NULL,
             %s, %s, NOW(), %s, %s, NULL);
    """

    with conn.cursor() as cur:
        cur.execute(
            query,
            (
                user_id,
                account_id,
                category_id_obj,
                amount,
                tx_type,
                description,
                operation_id,
            ),
        )
    conn.commit()
    print(f"Inserted 1 transaction with operation_id={operation_id}.")


# ==========================
# 5) Monthly cash-flow report
# ==========================
def show_monthly_cash_flow(conn):
    try:
        user_id = int(input("Enter user_id: ").strip())
    except ValueError:
        print("Invalid user_id.")
        return

    try:
        year = int(input("Enter year (e.g. 2025): ").strip())
    except ValueError:
        print("Invalid year.")
        return

    start_date = date(year, 1, 1)
    end_date = date(year, 12, 31)

    query = """
        SELECT date_trunc('month', tx_timestamp)::date AS month_start,
               SUM(CASE WHEN tx_type = 'income'  THEN amount END) AS income_amount,
               SUM(CASE WHEN tx_type = 'expense' THEN amount END) AS expense_amount
        FROM transactions
        WHERE user_id = %s
          AND tx_timestamp::date BETWEEN %s AND %s
        GROUP BY month_start
        ORDER BY month_start;
    """

    with conn.cursor() as cur:
        cur.execute(query, (user_id, start_date, end_date))
        rows = cur.fetchall()

    if not rows:
        print(f"No transactions found for user #{user_id} in {year}.")
        return

    print(f"Monthly cash-flow for user #{user_id} in {year}:")
    print("Month       | Income      | Expense     | Net")
    print("------------+-------------+-------------+-------------")

    for row in rows:
        month_start, income, expense = row
        income = income or 0
        expense = expense or 0
        net = income - expense
        month = month_start.strftime("%b %Y")
        print(f"{month:11} | {income:11.2f} | {expense:11.2f} | {net:11.2f}")


def main():
    print("============================================")
    print(" Personal Finance Management - Python Demo  ")
    print("============================================")

    try:
        conn = get_connection()
    except psycopg2.Error as e:
        print("Error connecting to the database:", e)
        sys.exit(1)

    try:
        running = True
        while running:
            print_menu()
            choice = input("Choose an option: ").strip()

            if choice == "1":
                list_users(conn)
            elif choice == "2":
                list_accounts_for_user(conn)
            elif choice == "3":
                show_recent_transactions(conn)
            elif choice == "4":
                add_transaction(conn)
            elif choice == "5":
                show_monthly_cash_flow(conn)
            elif choice == "0":
                running = False
            else:
                print("Unknown option. Please try again.")

            print()
    finally:
        conn.close()
        print("Goodbye!")


if __name__ == "__main__":
    main()
