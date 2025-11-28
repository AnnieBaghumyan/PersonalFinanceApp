from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date
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

# ==============================


def get_db():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )


app = Flask(__name__)
CORS(app)  # allow requests from your JS frontend (localhost)


# ------------------------------
# Helpers
# ------------------------------
def rows_to_json(rows):
    """Convert RealDictCursor rows to something jsonify can handle (convert dates)."""
    result = []
    for row in rows:
        converted = {}
        for k, v in row.items():
            if hasattr(v, "isoformat"):
                converted[k] = v.isoformat()
            else:
                converted[k] = v
        result.append(converted)
    return result


# ------------------------------
# 1) List all users
# ------------------------------
@app.get("/api/users")
def get_users():
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(
        """
        SELECT user_id, full_name, email, subscription, status, created_at
        FROM users
        ORDER BY user_id;
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows_to_json(rows))


# ------------------------------
# 2) List accounts for a user
# ------------------------------
@app.get("/api/users/<int:user_id>/accounts")
def get_accounts_for_user(user_id):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(
        """
        SELECT account_id, account_name, account_type,
               currency_code, current_balance, is_active, created_at
        FROM accounts
        WHERE user_id = %s
        ORDER BY account_id;
        """,
        (user_id,),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows_to_json(rows))


# ------------------------------
# 3) Recent transactions for an account
# ------------------------------
@app.get("/api/accounts/<int:account_id>/transactions")
def get_transactions_for_account(account_id):
    limit = request.args.get("limit", default=20, type=int)

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(
        """
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
        """,
        (account_id, limit),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(rows_to_json(rows))


# ------------------------------
# 4) Add a new income/expense transaction
# ------------------------------
@app.post("/api/transactions")
def create_transaction():
    data = request.get_json(force=True) or {}

    required_fields = ["user_id", "account_id", "tx_type", "amount"]
    missing = [f for f in required_fields if f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    user_id = data["user_id"]
    account_id = data["account_id"]
    tx_type = str(data["tx_type"]).lower()
    amount = float(data["amount"])
    category_id = data.get("category_id")  # can be None
    description = data.get("description", "").strip()

    if tx_type not in ("income", "expense"):
        return jsonify({"error": "tx_type must be 'income' or 'expense'."}), 400
    if amount <= 0:
        return jsonify({"error": "amount must be positive."}), 400

    operation_id = f"WEB-{int(date.today().strftime('%Y%m%d'))}-{abs(hash(description)) % 100000}"

    # Insert transaction + update account balance
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    try:
        cur.execute(
            """
            INSERT INTO transactions
                (user_id, account_id, category_id, bill_id, loan_id, goal_id,
                 amount, tx_type, tx_timestamp, description, operation_id, transfer_id)
            VALUES
                (%s, %s, %s, NULL, NULL, NULL,
                 %s, %s, NOW(), %s, %s, NULL)
            RETURNING tx_id, tx_timestamp;
            """,
            (user_id, account_id, category_id, amount, tx_type, description, operation_id),
        )
        tx_row = cur.fetchone()

        # Update account balance
        delta = amount if tx_type == "income" else -amount
        cur.execute(
            """
            UPDATE accounts
            SET current_balance = current_balance + %s
            WHERE account_id = %s;
            """,
            (delta, account_id),
        )

        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return jsonify({"error": str(e)}), 500

    cur.close()
    conn.close()

    tx_json = rows_to_json([tx_row])[0]
    tx_json["operation_id"] = operation_id
    tx_json["message"] = "Transaction created successfully."

    return jsonify(tx_json), 201


# ------------------------------
# 5) Monthly cash-flow for a user
# ------------------------------
@app.get("/api/users/<int:user_id>/cashflow")
def get_user_cashflow(user_id):
    year = request.args.get("year", type=int)
    if year is None:
        return jsonify({"error": "Query parameter 'year' is required, e.g. ?year=2025"}), 400

    start_date = date(year, 1, 1)
    end_date = date(year, 12, 31)

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute(
        """
        SELECT date_trunc('month', tx_timestamp)::date AS month_start,
               SUM(CASE WHEN tx_type = 'income'  THEN amount END) AS income_amount,
               SUM(CASE WHEN tx_type = 'expense' THEN amount END) AS expense_amount
        FROM transactions
        WHERE user_id = %s
          AND tx_timestamp::date BETWEEN %s AND %s
        GROUP BY month_start
        ORDER BY month_start;
        """,
        (user_id, start_date, end_date),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    # shape into nice JSON (Month label + numbers)
    result = []
    for r in rows:
        month_start = r["month_start"]
        income = r["income_amount"] or 0
        expense = r["expense_amount"] or 0
        net = income - expense

        result.append(
            {
                "month_start": month_start.isoformat(),
                "month_label": month_start.strftime("%b %Y"),
                "income": float(income),
                "expense": float(expense),
                "net": float(net),
            }
        )

    return jsonify(result)


if __name__ == "__main__":
    # debug=True is handy for demo; disable in production
    app.run(host="0.0.0.0", port=5000, debug=True)
