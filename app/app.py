from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import date
import getpass

# DB configuration

password = getpass.getpass("Enter password: ")

DB_NAME = "personal_finance_project"
DB_USER = "postgres"
DB_PASSWORD = password
DB_HOST = "localhost"
DB_PORT = 5432


def get_db():
    return psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )


app = Flask(__name__)
CORS(app)


# Helpers
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


def get_enum_values(enum_name):
    """Return a list of allowed ENUM values from PostgreSQL."""
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT enumlabel
        FROM pg_enum
        JOIN pg_type ON pg_enum.enumtypid = pg_type.oid
        WHERE pg_type.typname = %s
        ORDER BY enumsortorder;
        """,
        (enum_name,),
    )
    values = [row[0] for row in cur.fetchall()]
    cur.close()
    conn.close()
    return values


# OPTIONAL: expose enum values via API (useful for frontend)
@app.get("/api/enums/<enum_name>")
def list_enum_values(enum_name):
    try:
        values = get_enum_values(enum_name)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    if not values:
        return jsonify({"error": f"Enum '{enum_name}' not found or has no values."}), 404

    return jsonify({"name": enum_name, "values": values})


# 1) List all users
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


# 2) List accounts for a user
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


# List categories for a user (hierarchical output)
@app.get("/api/users/<int:user_id>/categories")
def get_categories_for_user(user_id):
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute(
        """
        SELECT category_id,
               category_name,
               category_type,
               parent_category_id
        FROM categories
        WHERE user_id = %s
        ORDER BY category_name;
        """,
        (user_id,)
    )

    rows = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(rows_to_json(rows))


# 4) Recent transactions for an account
@app.get("/api/accounts/<int:account_id>/transactions")
def get_transactions_for_account(account_id):
    limit = request.args.get("limit", default=20, type=int)

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute(
        """
        SELECT
            t.tx_id,
            t.tx_timestamp,
            t.tx_type,
            t.amount,
            t.description,
            c.category_name,
            t.category_id,
            t.bill_id,
            t.loan_id,
            t.goal_id
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


# CREATE INCOME / EXPENSE TRANSACTION
# Expenses are stored as NEGATIVE amounts in the DB;
# incomes are stored as POSITIVE amounts.
@app.post("/api/transactions")
def create_transaction():
    data = request.get_json(force=True) or {}

    required_fields = ["account_id", "tx_type", "amount", "operation_id"]
    missing = [f for f in required_fields if f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    account_id = data["account_id"]
    tx_type = str(data["tx_type"]).strip()
    category_id = data.get("category_id")
    description = data.get("description", "").strip()
    operation_id = data["operation_id"]

    # Parse and validate amount: must be positive input;
    # we will apply the sign based on tx_type.
    try:
        amount_raw = float(data["amount"])
    except (TypeError, ValueError):
        return jsonify({"error": "Amount must be a valid number."}), 400

    if amount_raw <= 0:
        return jsonify({"error": "Amount must be positive."}), 400

    # Use DB enum introspection instead of hard-coding tx_type values
    tx_types = get_enum_values("tx_type")
    if tx_type not in tx_types:
        return jsonify({
            "error": f"Invalid tx_type '{tx_type}'. Allowed values: {tx_types}"
        }), 400

    # We handle income/expense here; transfers go via /api/transfers
    if tx_type == "transfer":
        return jsonify({
            "error": "Use /api/transfers endpoint to record transfers."
        }), 400

    # Map semantics: income -> positive, expense -> negative
    if "income" not in tx_types or "expense" not in tx_types:
        return jsonify({
            "error": "tx_type enum must contain 'income' and 'expense'."
        }), 500

    if tx_type == "income":
        signed_amount = abs(amount_raw)      # +ve
    elif tx_type == "expense":
        signed_amount = -abs(amount_raw)     # -ve
    else:
        # In case new tx_type values are added in the future
        return jsonify({
            "error": f"Unsupported tx_type '{tx_type}' for this endpoint."
        }), 400

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    try:
        # ensure operation exists
        cur.execute("SELECT operation_id FROM operations WHERE operation_id = %s;", (operation_id,))
        if not cur.fetchone():
            cur.execute(
                "INSERT INTO operations (operation_id, request_hash) VALUES (%s, %s);",
                (operation_id, f"hash-{abs(hash(description))}")
            )

        # idempotency
        cur.execute("SELECT tx_id FROM transactions WHERE operation_id = %s;", (operation_id,))
        existing = cur.fetchone()
        if existing:
            conn.commit()
            return jsonify({
                "message": "Transaction already processed",
                "tx_id": existing["tx_id"]
            }), 200

        # insert transaction with SIGNED amount
        cur.execute(
            """
            INSERT INTO transactions
              (account_id, category_id, amount, tx_type, description, operation_id, tx_timestamp)
            VALUES (%s, %s, %s, %s, %s, %s, NOW())
            RETURNING tx_id, tx_timestamp, amount, tx_type, category_id, description;
            """,
            (account_id, category_id, signed_amount, tx_type, description, operation_id)
        )
        row = cur.fetchone()

        # update balance by signed amount
        cur.execute(
            "UPDATE accounts SET current_balance = current_balance + %s WHERE account_id = %s",
            (signed_amount, account_id)
        )

        conn.commit()

    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return jsonify({"error": str(e)}), 500

    cur.close()
    conn.close()

    return jsonify(rows_to_json([row])[0]), 201


# Transfers between accounts
@app.post("/api/transfers")
def create_transfer():
    data = request.get_json(force=True) or {}

    required = ["from_account_id", "to_account_id", "amount", "operation_id"]
    missing = [f for f in required if f not in data]
    if missing:
        return jsonify({"error": f"Missing fields: {', '.join(missing)}"}), 400

    from_acc = data["from_account_id"]
    to_acc = data["to_account_id"]
    try:
        amount = float(data["amount"])
    except (TypeError, ValueError):
        return jsonify({"error": "Amount must be a valid number."}), 400

    operation_id = data["operation_id"]
    description = data.get("description", "").strip()

    if from_acc == to_acc:
        return jsonify({"error": "Transfer accounts must differ."}), 400

    if amount <= 0:
        return jsonify({"error": "Amount must be positive."}), 400

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    try:
        # idempotency — does this transfer already exist?
        cur.execute(
            """
            SELECT tx_id FROM transactions WHERE operation_id = %s;
            """,
            (operation_id,),
        )
        existing = cur.fetchall()
        if existing:
            conn.commit()
            return jsonify({
                "message": "Transfer already processed.",
                "operation_id": operation_id,
                "tx_ids": [r["tx_id"] for r in existing]
            }), 200

        # ensure both accounts exist
        cur.execute("SELECT account_id FROM accounts WHERE account_id = %s;", (from_acc,))
        if not cur.fetchone():
            return jsonify({"error": "from_account_id does not exist"}), 404

        cur.execute("SELECT account_id FROM accounts WHERE account_id = %s;", (to_acc,))
        if not cur.fetchone():
            return jsonify({"error": "to_account_id does not exist"}), 404

        # ensure operation exists
        cur.execute("SELECT operation_id FROM operations WHERE operation_id = %s;", (operation_id,))
        if not cur.fetchone():
            cur.execute(
                """
                INSERT INTO operations (operation_id, request_hash)
                VALUES (%s, %s);
                """,
                (operation_id, f"hash-{abs(hash(description))}"),
            )

        # ---------------------------------
        # 1) transaction on source (tx_type = 'transfer')
        #    We keep amount positive here; it is not treated as expense in reports.
        # ---------------------------------
        cur.execute(
            """
            INSERT INTO transactions
                (account_id, amount, tx_type, description, operation_id, tx_timestamp)
            VALUES
                (%s, %s, 'transfer', %s, %s, NOW())
            RETURNING tx_id;
            """,
            (from_acc, amount, description, operation_id),
        )
        tx_out_id = cur.fetchone()["tx_id"]

        # ---------------------------------
        # 2) transaction on target (tx_type = 'transfer')
        # ---------------------------------
        cur.execute(
            """
            INSERT INTO transactions
                (account_id, amount, tx_type, description, operation_id, tx_timestamp)
            VALUES
                (%s, %s, 'transfer', %s, %s, NOW())
            RETURNING tx_id;
            """,
            (to_acc, amount, description, operation_id),
        )
        tx_in_id = cur.fetchone()["tx_id"]

        # update balances
        cur.execute(
            """
            UPDATE accounts SET current_balance = current_balance - %s
            WHERE account_id = %s;
            """,
            (amount, from_acc),
        )

        cur.execute(
            """
            UPDATE accounts SET current_balance = current_balance + %s
            WHERE account_id = %s;
            """,
            (amount, to_acc),
        )

        conn.commit()

    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return jsonify({"error": str(e)}), 500

    cur.close()
    conn.close()

    return jsonify({
        "message": "Transfer completed successfully.",
        "operation_id": operation_id,
        "from_tx_id": tx_out_id,
        "to_tx_id": tx_in_id,
    }), 201


# 5) Monthly cash-flow for a user
# With expenses stored as NEGATIVE, we flip the sign in SQL so that
# "expense_amount" is still reported as a positive number.
@app.get("/api/users/<int:user_id>/cashflow")
def get_user_cashflow(user_id):
    year = request.args.get("year", type=int)
    if year is None:
        return jsonify({"error": "Query parameter 'year' is required"}), 400

    start_date = date(year, 1, 1)
    end_date = date(year, 12, 31)

    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute(
        """
        SELECT date_trunc('month', tx_timestamp)::date AS month_start,
               SUM(CASE WHEN tx_type = 'income'  THEN amount  END)           AS income_amount,
               SUM(CASE WHEN tx_type = 'expense' THEN -amount END)           AS expense_amount
        FROM transactions t
        NATURAL JOIN accounts a
        WHERE a.user_id = %s
          AND tx_timestamp::date BETWEEN %s AND %s
        GROUP BY month_start
        ORDER BY month_start;
        """,
        (user_id, start_date, end_date),
    )

    rows = cur.fetchall()
    cur.close()
    conn.close()

    result = []
    for r in rows:
        month_start = r["month_start"]
        income = r["income_amount"] or 0
        expense = r["expense_amount"] or 0   # already positive
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
    app.run(host="0.0.0.0", port=5000, debug=True)
