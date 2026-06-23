@echo off
REM = """
python -x "%~f0" %*
exit /b %errorlevel%
REM """

import sys
import os
import sqlite3
import csv
import datetime
import hashlib
import getpass
import shutil
import textwrap
import uuid
import json
from decimal import Decimal, ROUND_HALF_UP, InvalidOperation
from pathlib import Path
import ctypes

# =====================================================================
# GLOBAL UTILITIES & HELPERS
# =====================================================================

def D(val):
    if val is None or val == "":
        return Decimal('0.00')
    try:
        return Decimal(str(val)).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    except Exception:
        return Decimal('0.00')

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def setup_console():
    if os.name == 'nt':
        try:
            SW_MAXIMIZE = 3
            ctypes.windll.user32.ShowWindow(
                ctypes.windll.kernel32.GetConsoleWindow(), SW_MAXIMIZE
            )
        except:
            pass
        os.system("mode con: cols=90 lines=50 2>nul")

def print_header(title):
    clear_screen()
    print("=" * 75)
    print(f" {title.center(71)} ")
    print("=" * 75)

def format_table(headers, rows):
    if not rows:
        return " No records found.\n"
    str_rows = [[str(item) if item is not None else "" for item in r] for r in rows]
    col_widths = [len(h) for h in headers]
    for row in str_rows:
        for idx, val in enumerate(row):
            if len(val) > col_widths[idx]:
                col_widths[idx] = len(val)
    max_col_width = 32
    col_widths = [min(w, max_col_width) for w in col_widths]
    
    sep = "+" + "+".join(["-" * (w + 2) for w in col_widths]) + "+"
    head_line = "| " + " | ".join([h.ljust(col_widths[i])[:col_widths[i]] for i, h in enumerate(headers)]) + " |"
    
    output = [sep, head_line, sep]
    for row in str_rows:
        line = "| " + " | ".join([val.ljust(col_widths[i])[:col_widths[i]] for i, val in enumerate(row)]) + " |"
        output.append(line)
    output.append(sep)
    return "\n".join(output)

def input_str(prompt_text, required=True, default=""):
    while True:
        p = prompt_text + (f" [{default}]" if default != "" else "") + ": "
        val = input(p).strip()
        if not val and default != "":
            return default
        if not val and required:
            print(" [!] This field cannot be empty. Please try again.")
            continue
        return val

def input_dec(prompt_text, required=True, min_val=None, default=None):
    while True:
        p = prompt_text + (f" [{default}]" if default is not None else "") + ": "
        val = input(p).strip()
        if not val and default is not None:
            return D(default)
        if not val and not required:
            return D('0.00')
        try:
            d = D(val)
            if min_val is not None and d < D(min_val):
                print(f" [!] Value must be at least {min_val}.")
                continue
            return d
        except Exception:
            print(" [!] Invalid decimal number. Please enter a valid amount.")

def input_int(prompt_text, required=True, min_val=None, default=None):
    while True:
        p = prompt_text + (f" [{default}]" if default is not None else "") + ": "
        val = input(p).strip()
        if not val and default is not None:
            return int(default)
        if not val and not required:
            return 0
        try:
            i = int(val)
            if min_val is not None and i < min_val:
                print(f" [!] Value must be at least {min_val}.")
                continue
            return i
        except Exception:
            print(" [!] Invalid whole number. Please try again.")

def input_date(prompt_text, default_today=True):
    today = datetime.date.today().isoformat()
    while True:
        p = prompt_text + (f" [{today}]" if default_today else "") + (": " if not default_today else " (YYYY-MM-DD): ")
        val = input(p).strip()
        if not val and default_today:
            return today
        try:
            datetime.datetime.strptime(val, "%Y-%m-%d")
            return val
        except ValueError:
            print(" [!] Invalid date format. Please use YYYY-MM-DD.")

def export_csv_file(default_name, headers, rows):
    fname = input_str("Enter filename to export", default=default_name)
    if not fname.lower().endswith(".csv"):
        fname += ".csv"
    try:
        with open(fname, mode='w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            writer.writerows(rows)
        print(f"\n [+] Successfully exported data to {fname}")
    except Exception as e:
        print(f"\n [!] Export failed: {e}")
    input(" Press [Enter] to continue...")

# =====================================================================
# DATABASE MANAGER
# =====================================================================

class Database:
    def __init__(self, db_path="shop_manager.db"):
        self.db_path = db_path
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.create_tables()
        self.init_defaults()

    def create_tables(self):
        schema = """
        CREATE TABLE IF NOT EXISTS settings (
            k TEXT PRIMARY KEY,
            v TEXT
        );
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            role TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            force_password_change INTEGER DEFAULT 0,
            last_login TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        );
        CREATE TABLE IF NOT EXISTS brands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        );
        CREATE TABLE IF NOT EXISTS units (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        );
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            barcode TEXT,
            name TEXT NOT NULL,
            category_id INTEGER,
            brand_id INTEGER,
            unit_id INTEGER,
            purchase_price TEXT DEFAULT '0.00',
            sale_price TEXT DEFAULT '0.00',
            wholesale_price TEXT DEFAULT '0.00',
            retail_price TEXT DEFAULT '0.00',
            min_stock TEXT DEFAULT '0.00',
            opening_stock TEXT DEFAULT '0.00',
            current_stock TEXT DEFAULT '0.00',
            tax_percent TEXT DEFAULT '0.00',
            discount_allowed INTEGER DEFAULT 1,
            expiry_date TEXT,
            batch_number TEXT,
            rack_location TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            updated_at TEXT,
            FOREIGN KEY(category_id) REFERENCES categories(id),
            FOREIGN KEY(brand_id) REFERENCES brands(id),
            FOREIGN KEY(unit_id) REFERENCES units(id)
        );
        CREATE TABLE IF NOT EXISTS product_price_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            old_price TEXT,
            new_price TEXT,
            price_type TEXT,
            changed_by INTEGER,
            changed_at TEXT
        );
        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            email TEXT,
            opening_balance TEXT DEFAULT '0.00',
            current_balance TEXT DEFAULT '0.00',
            credit_limit TEXT DEFAULT '0.00',
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            email TEXT,
            opening_balance TEXT DEFAULT '0.00',
            current_balance TEXT DEFAULT '0.00',
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS cash_bank_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            type TEXT NOT NULL,
            balance TEXT DEFAULT '0.00',
            is_active INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS cash_bank_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            trans_date TEXT,
            trans_type TEXT,
            amount TEXT,
            description TEXT,
            ref_id TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT UNIQUE NOT NULL,
            supplier_id INTEGER,
            purchase_date TEXT,
            subtotal TEXT,
            discount TEXT,
            tax TEXT,
            freight TEXT,
            grand_total TEXT,
            paid_amount TEXT,
            balance_amount TEXT,
            payment_method TEXT,
            account_id INTEGER,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS purchase_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purchase_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            discount TEXT,
            tax TEXT,
            total TEXT,
            batch_no TEXT,
            expiry TEXT
        );
        CREATE TABLE IF NOT EXISTS purchase_returns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_no TEXT UNIQUE NOT NULL,
            purchase_id INTEGER,
            return_date TEXT,
            total_amount TEXT,
            refund_method TEXT,
            account_id INTEGER,
            reason TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS purchase_return_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            refund_amount TEXT
        );
        CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT UNIQUE NOT NULL,
            customer_id INTEGER,
            customer_type TEXT,
            sale_date TEXT,
            subtotal TEXT,
            overall_discount TEXT,
            total_tax TEXT,
            grand_total TEXT,
            paid_amount TEXT,
            balance_amount TEXT,
            payment_method TEXT,
            account_id INTEGER,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            cost_price TEXT,
            discount TEXT,
            tax TEXT,
            total TEXT
        );
        CREATE TABLE IF NOT EXISTS sale_returns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_no TEXT UNIQUE NOT NULL,
            sale_id INTEGER,
            return_date TEXT,
            total_amount TEXT,
            refund_method TEXT,
            account_id INTEGER,
            reason TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS sale_return_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            refund_amount TEXT
        );
        CREATE TABLE IF NOT EXISTS stock_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            move_date TEXT,
            move_type TEXT,
            qty TEXT,
            ref_id TEXT,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS stock_adjustments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            adj_date TEXT,
            adj_type TEXT,
            qty TEXT,
            reason TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS customer_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            trans_date TEXT,
            trans_type TEXT,
            debit TEXT,
            credit TEXT,
            running_balance TEXT,
            description TEXT,
            ref_id TEXT
        );
        CREATE TABLE IF NOT EXISTS supplier_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id INTEGER,
            trans_date TEXT,
            trans_type TEXT,
            debit TEXT,
            credit TEXT,
            running_balance TEXT,
            description TEXT,
            ref_id TEXT
        );
        CREATE TABLE IF NOT EXISTS expense_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        );
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER,
            description TEXT,
            amount TEXT,
            payment_method TEXT,
            account_id INTEGER,
            exp_date TEXT,
            paid_to TEXT,
            notes TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            action TEXT,
            details TEXT,
            timestamp TEXT
        );
        CREATE TABLE IF NOT EXISTS warehouses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            location TEXT,
            is_active INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS warehouse_stock (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            warehouse_id INTEGER,
            product_id INTEGER,
            qty TEXT DEFAULT '0.00',
            UNIQUE(warehouse_id, product_id)
        );
        CREATE TABLE IF NOT EXISTS quotations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quote_no TEXT UNIQUE NOT NULL,
            customer_id INTEGER,
            quote_date TEXT,
            valid_until TEXT,
            subtotal TEXT,
            discount TEXT,
            tax TEXT,
            grand_total TEXT,
            status TEXT DEFAULT 'DRAFT',
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS quotation_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            quotation_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            discount TEXT,
            tax TEXT,
            total TEXT
        );
        CREATE TABLE IF NOT EXISTS sales_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_no TEXT UNIQUE NOT NULL,
            customer_id INTEGER,
            order_date TEXT,
            delivery_date TEXT,
            subtotal TEXT,
            discount TEXT,
            tax TEXT,
            grand_total TEXT,
            paid_amount TEXT DEFAULT '0.00',
            status TEXT DEFAULT 'PENDING',
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS sales_order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            discount TEXT,
            tax TEXT,
            total TEXT,
            delivered_qty TEXT DEFAULT '0.00'
        );
        CREATE TABLE IF NOT EXISTS purchase_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_no TEXT UNIQUE NOT NULL,
            supplier_id INTEGER,
            order_date TEXT,
            expected_date TEXT,
            subtotal TEXT,
            discount TEXT,
            tax TEXT,
            grand_total TEXT,
            status TEXT DEFAULT 'PENDING',
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS purchase_order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            po_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            discount TEXT,
            tax TEXT,
            total TEXT,
            received_qty TEXT DEFAULT '0.00'
        );
        CREATE TABLE IF NOT EXISTS delivery_challans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challan_no TEXT UNIQUE NOT NULL,
            sale_id INTEGER,
            customer_id INTEGER,
            challan_date TEXT,
            vehicle_no TEXT,
            driver_name TEXT,
            driver_phone TEXT,
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS delivery_challan_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challan_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS credit_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            credit_no TEXT UNIQUE NOT NULL,
            customer_id INTEGER,
            sale_id INTEGER,
            credit_date TEXT,
            total_amount TEXT,
            reason TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS credit_note_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            credit_note_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            amount TEXT
        );
        CREATE TABLE IF NOT EXISTS debit_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            debit_no TEXT UNIQUE NOT NULL,
            supplier_id INTEGER,
            purchase_id INTEGER,
            debit_date TEXT,
            total_amount TEXT,
            reason TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS debit_note_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            debit_note_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            amount TEXT
        );
        CREATE TABLE IF NOT EXISTS employees (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            department TEXT,
            designation TEXT,
            salary_type TEXT DEFAULT 'FIXED',
            salary_amount TEXT DEFAULT '0.00',
            commission_rate TEXT DEFAULT '0.00',
            joining_date TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS commissions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            employee_id INTEGER,
            sale_id INTEGER,
            commission_type TEXT,
            commission_rate TEXT,
            commission_amount TEXT,
            paid_status INTEGER DEFAULT 0,
            paid_date TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS loyalty_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            points INTEGER DEFAULT 0,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS loyalty_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            points INTEGER,
            trans_type TEXT,
            ref_id TEXT,
            description TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS price_lists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            list_type TEXT DEFAULT 'SALE',
            is_active INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS price_list_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            price_list_id INTEGER,
            product_id INTEGER,
            sale_price TEXT,
            wholesale_price TEXT,
            discount_percent TEXT DEFAULT '0.00',
            UNIQUE(price_list_id, product_id)
        );
        CREATE TABLE IF NOT EXISTS promotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            promo_type TEXT DEFAULT 'PERCENTAGE',
            discount_value TEXT,
            min_purchase TEXT DEFAULT '0.00',
            max_discount TEXT,
            coupon_code TEXT UNIQUE,
            start_date TEXT,
            end_date TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS promotion_applicable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            promotion_id INTEGER,
            product_id INTEGER,
            category_id INTEGER
        );
        CREATE TABLE IF NOT EXISTS serial_numbers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            serial_no TEXT UNIQUE NOT NULL,
            purchase_id INTEGER,
            sale_id INTEGER,
            status TEXT DEFAULT 'IN_STOCK',
            warehouse_id INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS service_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_no TEXT UNIQUE NOT NULL,
            customer_id INTEGER,
            product_id INTEGER,
            serial_no TEXT,
            issue_description TEXT,
            status TEXT DEFAULT 'PENDING',
            received_date TEXT,
            delivered_date TEXT,
            service_charges TEXT DEFAULT '0.00',
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS service_parts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_job_id INTEGER,
            product_id INTEGER,
            qty TEXT,
            price TEXT,
            total TEXT
        );
        CREATE TABLE IF NOT EXISTS bom (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            finished_product_id INTEGER,
            output_qty TEXT DEFAULT '1.00',
            wastage_percent TEXT DEFAULT '0.00',
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS bom_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bom_id INTEGER,
            raw_product_id INTEGER,
            qty TEXT
        );
        CREATE TABLE IF NOT EXISTS manufacturing_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            job_no TEXT UNIQUE NOT NULL,
            bom_id INTEGER,
            product_id INTEGER,
            planned_qty TEXT,
            produced_qty TEXT DEFAULT '0.00',
            start_date TEXT,
            end_date TEXT,
            status TEXT DEFAULT 'PLANNED',
            notes TEXT,
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS chart_of_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            parent_id INTEGER,
            account_type TEXT NOT NULL,
            is_active INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS general_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            trans_date TEXT,
            trans_type TEXT,
            debit TEXT,
            credit TEXT,
            running_balance TEXT,
            ref_id TEXT,
            description TEXT,
            created_by INTEGER
        );
        CREATE TABLE IF NOT EXISTS fixed_assets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            category TEXT,
            purchase_date TEXT,
            purchase_price TEXT,
            salvage_value TEXT DEFAULT '0.00',
            useful_life INTEGER DEFAULT 5,
            depreciation_method TEXT DEFAULT 'STRAIGHT_LINE',
            current_value TEXT,
            location TEXT,
            notes TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS depreciation_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_id INTEGER,
            dep_date TEXT,
            amount TEXT,
            accumulated_dep TEXT
        );
        CREATE TABLE IF NOT EXISTS budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            fiscal_year TEXT,
            start_date TEXT,
            end_date TEXT,
            total_amount TEXT DEFAULT '0.00',
            is_active INTEGER DEFAULT 1,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS budget_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            budget_id INTEGER,
            account_id INTEGER,
            budgeted_amount TEXT DEFAULT '0.00',
            actual_amount TEXT DEFAULT '0.00'
        );
        CREATE TABLE IF NOT EXISTS cash_registers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            opening_balance TEXT DEFAULT '0.00',
            current_balance TEXT DEFAULT '0.00',
            opening_date TEXT,
            closing_date TEXT,
            status TEXT DEFAULT 'OPEN',
            created_by INTEGER,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS register_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            register_id INTEGER,
            trans_type TEXT,
            amount TEXT,
            description TEXT,
            ref_id TEXT,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS password_policy (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            min_length INTEGER DEFAULT 6,
            require_upper INTEGER DEFAULT 0,
            require_lower INTEGER DEFAULT 0,
            require_digit INTEGER DEFAULT 1,
            require_special INTEGER DEFAULT 0,
            max_age_days INTEGER DEFAULT 0,
            max_login_attempts INTEGER DEFAULT 5,
            lockout_duration INTEGER DEFAULT 30
        );
        CREATE TABLE IF NOT EXISTS login_attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            attempt_time TEXT,
            success INTEGER
        );
        CREATE TABLE IF NOT EXISTS email_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            smtp_server TEXT,
            smtp_port INTEGER DEFAULT 587,
            smtp_user TEXT,
            smtp_pass TEXT,
            sender_email TEXT,
            sender_name TEXT,
            is_active INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS help_topics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic TEXT UNIQUE NOT NULL,
            content TEXT,
            keywords TEXT
        );
        CREATE TABLE IF NOT EXISTS challan_from_po (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challan_id INTEGER,
            po_id INTEGER
        );
        """
        self.conn.executescript(schema)
        self.conn.commit()

    def init_defaults(self):
        cur = self.conn.cursor()
        # Default Settings
        default_settings = {
            'shop_name': 'My Super Retail & Wholesale Shop',
            'shop_address': '123 Main Commercial Street, Cityville',
            'phone': '555-0199',
            'email': 'contact@shopmanager.local',
            'currency': '$',
            'tax_rate': '5.00',
            'inv_prefix': 'INV-',
            'pur_prefix': 'PUR-',
            'ret_prefix': 'RET-',
            'low_stock_warn': '10',
            'backup_path': './backups',
            'date_format': '%Y-%m-%d',
            'footer_msg': 'Thank you for your business! Visit us again.'
        }
        for k, v in default_settings.items():
            cur.execute("INSERT OR IGNORE INTO settings (k, v) VALUES (?, ?)", (k, v))
            
        # Default Admin
        cur.execute("SELECT COUNT(*) FROM users")
        if cur.fetchone()[0] == 0:
            salt = uuid.uuid4().hex
            pw_hash = hashlib.sha256(("admin123" + salt).encode()).hexdigest()
            now = datetime.datetime.now().isoformat()
            cur.execute("""INSERT INTO users (username, password_hash, salt, role, is_active, force_password_change, created_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?)""",
                        ('admin', pw_hash, salt, 'Admin', 1, 0, now))
            # Default Manager
            salt2 = uuid.uuid4().hex
            pw_hash2 = hashlib.sha256(("manager123" + salt2).encode()).hexdigest()
            cur.execute("""INSERT INTO users (username, password_hash, salt, role, is_active, force_password_change, created_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?)""",
                        ('manager', pw_hash2, salt2, 'Manager', 1, 0, now))
            # Default Cashier
            salt3 = uuid.uuid4().hex
            pw_hash3 = hashlib.sha256(("cashier123" + salt3).encode()).hexdigest()
            cur.execute("""INSERT INTO users (username, password_hash, salt, role, is_active, force_password_change, created_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?)""",
                        ('cashier', pw_hash3, salt3, 'Cashier', 1, 0, now))
            # Default Viewer
            salt4 = uuid.uuid4().hex
            pw_hash4 = hashlib.sha256(("viewer123" + salt4).encode()).hexdigest()
            cur.execute("""INSERT INTO users (username, password_hash, salt, role, is_active, force_password_change, created_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?)""",
                        ('viewer', pw_hash4, salt4, 'Viewer', 1, 0, now))

        # Default Accounts
        cur.execute("SELECT COUNT(*) FROM cash_bank_accounts")
        if cur.fetchone()[0] == 0:
            cur.execute("INSERT INTO cash_bank_accounts (name, type, balance) VALUES (?, ?, ?)", ('Cash in Hand', 'CASH', '0.00'))
            cur.execute("INSERT INTO cash_bank_accounts (name, type, balance) VALUES (?, ?, ?)", ('Main Bank Account', 'BANK', '0.00'))

        # Default Units
        cur.execute("SELECT COUNT(*) FROM units")
        if cur.fetchone()[0] == 0:
            for u in ['pcs', 'kg', 'gram', 'liter', 'box', 'packet']:
                cur.execute("INSERT INTO units (name) VALUES (?)", (u,))

        # Default Categories & Brands
        cur.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", ('General',))
        cur.execute("INSERT OR IGNORE INTO brands (name) VALUES (?)", ('Generic',))

        # Default Expense Categories
        cur.execute("SELECT COUNT(*) FROM expense_categories")
        if cur.fetchone()[0] == 0:
            for ec in ['Rent', 'Electricity', 'Salary', 'Maintenance', 'Miscellaneous']:
                cur.execute("INSERT INTO expense_categories (name) VALUES (?)", (ec,))

        # Default Warehouse
        cur.execute("SELECT COUNT(*) FROM warehouses")
        if cur.fetchone()[0] == 0:
            cur.execute("INSERT INTO warehouses (name, location) VALUES (?, ?)", ('Main Warehouse', 'Default Location'))

        # Default Chart of Accounts
        cur.execute("SELECT COUNT(*) FROM chart_of_accounts")
        if cur.fetchone()[0] == 0:
            coa = [
                ('1', 'Assets', 0, 'HEAD'),
                ('1.1', 'Current Assets', 1, 'HEAD'),
                ('1.1.1', 'Cash in Hand', 2, 'ASSET'),
                ('1.1.2', 'Bank Accounts', 2, 'ASSET'),
                ('1.1.3', 'Accounts Receivable', 2, 'ASSET'),
                ('1.1.4', 'Inventory', 2, 'ASSET'),
                ('1.2', 'Fixed Assets', 1, 'HEAD'),
                ('1.2.1', 'Furniture & Fixtures', 7, 'ASSET'),
                ('1.2.2', 'Equipment', 7, 'ASSET'),
                ('2', 'Liabilities', 0, 'HEAD'),
                ('2.1', 'Current Liabilities', 10, 'HEAD'),
                ('2.1.1', 'Accounts Payable', 11, 'LIABILITY'),
                ('2.1.2', 'Tax Payable', 11, 'LIABILITY'),
                ('2.2', 'Long Term Liabilities', 10, 'HEAD'),
                ('2.2.1', 'Bank Loans', 14, 'LIABILITY'),
                ('3', 'Equity', 0, 'HEAD'),
                ('3.1', 'Owner Equity', 16, 'HEAD'),
                ('3.1.1', 'Capital Account', 17, 'EQUITY'),
                ('3.1.2', 'Retained Earnings', 17, 'EQUITY'),
                ('4', 'Revenue', 0, 'HEAD'),
                ('4.1', 'Sales Revenue', 20, 'HEAD'),
                ('4.1.1', 'Retail Sales', 21, 'REVENUE'),
                ('4.1.2', 'Wholesale Sales', 21, 'REVENUE'),
                ('5', 'Expenses', 0, 'HEAD'),
                ('5.1', 'Operating Expenses', 24, 'HEAD'),
                ('5.1.1', 'Cost of Goods Sold', 25, 'EXPENSE'),
                ('5.1.2', 'Salary Expenses', 25, 'EXPENSE'),
                ('5.1.3', 'Rent Expenses', 25, 'EXPENSE'),
                ('5.1.4', 'Utility Expenses', 25, 'EXPENSE'),
                ('5.1.5', 'Depreciation', 25, 'EXPENSE'),
            ]
            for code, name, pid, atype in coa:
                cur.execute("INSERT INTO chart_of_accounts (code, name, parent_id, account_type) VALUES (?, ?, ?, ?)",
                            (code, name, pid, atype))

        # Default Password Policy
        cur.execute("SELECT COUNT(*) FROM password_policy")
        if cur.fetchone()[0] == 0:
            cur.execute("INSERT INTO password_policy DEFAULT VALUES")

        # Default Help Topics
        cur.execute("SELECT COUNT(*) FROM help_topics")
        if cur.fetchone()[0] == 0:
            help_data = [
                ('Getting Started', 'Default logins: admin/admin123 (Admin), manager/manager123 (Manager), cashier/cashier123 (Cashier), viewer/viewer123 (Viewer). Navigate using menu numbers. Press 0 to go back, S for global search.', 'start, login, navigation'),
                ('Sales / POS', 'Select option 2 from main menu. Add products by SKU/barcode/name. Supports walk-in and registered customers. Credit only for registered.', 'sales, pos, billing, invoice'),
                ('Purchases', 'Create purchase invoices, track supplier balances, manage purchase returns.', 'purchase, buying, supplier'),
                ('Products & Inventory', 'Manage products, categories, brands, units. Track stock, price history, stock movements.', 'product, stock, inventory, sku'),
                ('Customers & Khata', 'Customer ledger with debit/credit tracking. Accept payments against outstanding.', 'customer, khata, ledger, credit'),
                ('Suppliers & Khata', 'Supplier ledger management. Make payments against payables.', 'supplier, khata, ledger'),
                ('Reports', 'Access 25+ reports: sales, purchase, profit/loss, stock valuation, tax summary, audit logs.', 'report, analytics, profit, loss'),
                ('Backup & Restore', 'Go to option 13. Creates .db backups. Restore by selecting from available backups.', 'backup, restore, database'),
                ('Multi-Warehouse', 'Manage multiple stock locations. Track product stock per warehouse. Transfer stock between warehouses.', 'warehouse, godown, location'),
                ('Quotations', 'Create price quotations for customers. Convert to sales order or invoice when accepted.', 'quotation, quote, proforma'),
                ('Sales Orders', 'Book orders before delivery. Track delivered vs pending quantities.', 'sales order, booking'),
                ('Purchase Orders', 'Create POs to suppliers. Track received quantities against ordered.', 'purchase order, po'),
                ('Delivery Challan', 'Generate delivery challans for dispatched goods. Track vehicle/driver info.', 'challan, delivery, dispatch'),
                ('Full Accounting', 'Chart of Accounts, General Ledger, Trial Balance, Balance Sheet. Complete double-entry.', 'accounting, ledger, trial balance'),
                ('Service & Repair', 'Track service jobs, customer complaints, parts used, charges.', 'service, repair, job'),
                ('Manufacturing / BOM', 'Define bill of materials for products. Execute manufacturing jobs to produce finished goods.', 'manufacturing, bom, assembly, production'),
                ('Loyalty Program', 'Award points to customers. Redeem on future purchases.', 'loyalty, points, rewards'),
                ('Promotions & Coupons', 'Create percentage/flat discount promotions. Generate coupon codes.', 'promotion, coupon, discount, offer'),
                ('Price Lists', 'Create customer-specific or tiered pricing.', 'price list, pricing, tier'),
                ('Employee Management', 'Track employees, commissions, departments.', 'employee, staff, commission'),
                ('Fixed Assets', 'Register assets, track depreciation (straight-line method).', 'asset, depreciation, fixed asset'),
                ('Budgets', 'Set budget targets by account. Track actual vs budgeted spending.', 'budget, forecast, planning'),
                ('Keyboard Shortcuts', 'S - Global Search at main menu. 0 - Go back/Exit. Enter - Continue prompts.', 'shortcut, key, search'),
            ]
            for topic, content, keywords in help_data:
                cur.execute("INSERT INTO help_topics (topic, content, keywords) VALUES (?, ?, ?)",
                            (topic, content, keywords))

        self.conn.commit()

    def get_setting(self, key, default=""):
        cur = self.conn.cursor()
        cur.execute("SELECT v FROM settings WHERE k=?", (key,))
        row = cur.fetchone()
        return row['v'] if row else default

    def set_setting(self, key, val):
        with self.conn:
            self.conn.execute("INSERT OR REPLACE INTO settings (k, v) VALUES (?, ?)", (key, str(val)))

    def fetch_all(self, query, params=()):
        cur = self.conn.cursor()
        cur.execute(query, params)
        return cur.fetchall()

    def fetch_one(self, query, params=()):
        cur = self.conn.cursor()
        cur.execute(query, params)
        return cur.fetchone()

    def fetch_val(self, query, params=()):
        row = self.fetch_one(query, params)
        return row[0] if row and row[0] is not None else None

    def execute(self, query, params=()):
        with self.conn:
            cur = self.conn.execute(query, params)
            return cur.lastrowid

# =====================================================================
# AUTHENTICATION & AUDIT
# =====================================================================

class AuditManager:
    def __init__(self, db, auth):
        self.db = db
        self.auth = auth

    def log(self, action, details):
        uid = self.auth.current_user['id'] if self.auth.current_user else 0
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.db.execute("INSERT INTO audit_logs (user_id, action, details, timestamp) VALUES (?, ?, ?, ?)",
                        (uid, action, details, now))

class AuthManager:
    def __init__(self, db):
        self.db = db
        self.current_user = None

    def hash_pw(self, pw, salt=None):
        if not salt:
            salt = uuid.uuid4().hex
        h = hashlib.sha256((pw + salt).encode()).hexdigest()
        return h, salt

    def login(self):
        print_header("SHOP MANAGEMENT SYSTEM - LOGIN")
        username = input_str("Username")
        password = getpass.getpass("Password: ")
        
        user = self.db.fetch_one("SELECT * FROM users WHERE username=? AND is_active=1", (username,))
        if user:
            calc_hash, _ = self.hash_pw(password, user['salt'])
            if calc_hash == user['password_hash']:
                self.current_user = dict(user)
                now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                self.db.execute("UPDATE users SET last_login=? WHERE id=?", (now, user['id']))
                
                if self.current_user['force_password_change'] == 1:
                    print("\n [!] You are required to change your password on first login.")
                    self.change_password(forced=True)
                return True
        print("\n [!] Invalid credentials or inactive account.")
        input(" Press [Enter] to retry...")
        return False

    def logout(self, audit):
        if self.current_user:
            audit.log("LOGOUT", f"User {self.current_user['username']} logged out.")
            self.current_user = None

    def change_password(self, forced=False):
        print_header("CHANGE PASSWORD")
        if not forced:
            old_pw = getpass.getpass("Enter Current Password: ")
            calc_hash, _ = self.hash_pw(old_pw, self.current_user['salt'])
            if calc_hash != self.current_user['password_hash']:
                print("\n [!] Incorrect current password.")
                input(" Press [Enter] to cancel...")
                return

        new_pw = getpass.getpass("Enter New Password: ")
        conf_pw = getpass.getpass("Confirm New Password: ")
        if not new_pw or len(new_pw) < 4:
            print("\n [!] Password must be at least 4 characters long.")
            input(" Press [Enter] to continue...")
            return
        if new_pw != conf_pw:
            print("\n [!] Passwords do not match.")
            input(" Press [Enter] to continue...")
            return

        new_hash, new_salt = self.hash_pw(new_pw)
        self.db.execute("UPDATE users SET password_hash=?, salt=?, force_password_change=0 WHERE id=?",
                        (new_hash, new_salt, self.current_user['id']))
        self.current_user['password_hash'] = new_hash
        self.current_user['salt'] = new_salt
        self.current_user['force_password_change'] = 0
        print("\n [+] Password updated successfully!")
        input(" Press [Enter] to continue...")

    def has_role(self, allowed_roles):
        if not self.current_user:
            return False
        return self.current_user['role'] in allowed_roles

    def require_role(self, allowed_roles):
        if not self.has_role(allowed_roles):
            print("\n [!] Access Denied: You do not have permission to perform this action.")
            input(" Press [Enter] to continue...")
            return False
        return True

# =====================================================================
# SUB-MODULES (MASTERS, PARTIES, FINANCE, INVENTORY, ETC.)
# =====================================================================

class MasterManager:
    def __init__(self, db, auth, audit):
        self.db = db
        self.auth = auth
        self.audit = audit

    def menu(self):
        while True:
            print_header("MASTER DATA MANAGEMENT")
            print(" 1. Manage Categories")
            print(" 2. Manage Brands")
            print(" 3. Manage Units")
            print(" 4. Manage Products / Items")
            print(" 5. View Inactive Products")
            print(" 6. Manual Stock Adjustment")
            print(" 7. Product Price Update History")
            print(" 8. Product Stock Movement History")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            choice = input(" Select Option: ").strip()
            if choice == '1': self.manage_simple('categories', 'Category')
            elif choice == '2': self.manage_simple('brands', 'Brand')
            elif choice == '3': self.manage_simple('units', 'Unit')
            elif choice == '4': self.manage_products()
            elif choice == '5': self.view_inactive_products()
            elif choice == '6': self.stock_adjustment()
            elif choice == '7': self.view_price_history()
            elif choice == '8': self.view_stock_history()
            elif choice == '0': break

    def manage_simple(self, table_name, label):
        while True:
            print_header(f"MANAGE {label.upper()}S")
            rows = self.db.fetch_all(f"SELECT * FROM {table_name} ORDER BY id")
            print(format_table(["ID", f"{label} Name"], [[r['id'], r['name']] for r in rows]))
            print("-" * 75)
            print(f" 1. Add {label}")
            print(f" 2. Edit {label}")
            print(f" 3. Delete {label} (if unused)")
            print(" 0. Back")
            c = input(" Select Option: ").strip()
            if c == '1':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                name = input_str(f"Enter new {label} name")
                try:
                    self.db.execute(f"INSERT INTO {table_name} (name) VALUES (?)", (name,))
                    self.audit.log(f"ADD_{label.upper()}", f"Added {label}: {name}")
                except sqlite3.IntegrityError:
                    print(f" [!] {label} already exists.")
                    input(" Press [Enter]...")
            elif c == '2':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                tid = input_int(f"Enter {label} ID to edit")
                row = self.db.fetch_one(f"SELECT * FROM {table_name} WHERE id=?", (tid,))
                if not row:
                    print(" [!] Record not found."); input(" Press [Enter]..."); continue
                new_name = input_str("Enter new name", default=row['name'])
                try:
                    self.db.execute(f"UPDATE {table_name} SET name=? WHERE id=?", (new_name, tid))
                    self.audit.log(f"EDIT_{label.upper()}", f"Updated {label} ID {tid} to {new_name}")
                except sqlite3.IntegrityError:
                    print(f" [!] {label} name already exists."); input(" Press [Enter]...")
            elif c == '3':
                if not self.auth.require_role(['Admin']): continue
                tid = input_int(f"Enter {label} ID to delete")
                col_map = {'categories': 'category_id', 'brands': 'brand_id', 'units': 'unit_id'}
                cnt = self.db.fetch_val(f"SELECT COUNT(*) FROM products WHERE {col_map[table_name]}=?", (tid,))
                if cnt > 0:
                    print(f" [!] Cannot delete: {cnt} product(s) are currently assigned to this {label}.")
                else:
                    self.db.execute(f"DELETE FROM {table_name} WHERE id=?", (tid,))
                    self.audit.log(f"DELETE_{label.upper()}", f"Deleted {label} ID {tid}")
                    print(" [+] Deleted successfully.")
                input(" Press [Enter]...")
            elif c == '0': break

    def manage_products(self):
        while True:
            print_header("PRODUCT / ITEM MANAGEMENT")
            print(" 1. View Active Products")
            print(" 2. Add New Product")
            print(" 3. Edit Product")
            print(" 4. Search Product")
            print(" 5. Deactivate / Activate Product")
            print(" 0. Back")
            c = input(" Select Option: ").strip()
            if c == '1':
                self.list_products(active_only=True)
            elif c == '2':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                self.add_product()
            elif c == '3':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                self.edit_product()
            elif c == '4':
                q = input_str("Enter SKU, Barcode, or Name to search")
                self.list_products(search_q=q)
            elif c == '5':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                self.toggle_product_status()
            elif c == '0': break

    def list_products(self, active_only=False, search_q=None):
        query = """SELECT p.id, p.code, p.barcode, p.name, c.name as cat, b.name as brd, u.name as unt,
                          p.purchase_price, p.sale_price, p.current_stock, p.is_active
                   FROM products p
                   LEFT JOIN categories c ON p.category_id = c.id
                   LEFT JOIN brands b ON p.brand_id = b.id
                   LEFT JOIN units u ON p.unit_id = u.id """
        params = []
        conds = []
        if active_only: conds.append("p.is_active = 1")
        if search_q:
            conds.append("(p.code LIKE ? OR p.barcode LIKE ? OR p.name LIKE ?)")
            params.extend([f"%{search_q}%", f"%{search_q}%", f"%{search_q}%"])
        if conds: query += "WHERE " + " AND ".join(conds)
        query += " ORDER BY p.name"
        
        rows = self.db.fetch_all(query, params)
        curr = self.db.get_setting('currency', '$')
        t_data = []
        for r in rows:
            status = "Active" if r['is_active'] == 1 else "Inactive"
            t_data.append([r['id'], r['code'], r['name'][:20], r['cat'][:10], r['unt'], 
                           f"{curr}{D(r['purchase_price'])}", f"{curr}{D(r['sale_price'])}", 
                           D(r['current_stock']), status])
        print_header("PRODUCT LIST")
        print(format_table(["ID", "SKU", "Name", "Category", "Unit", "Pur.Price", "Sale Price", "Stock", "Status"], t_data))
        input(" Press [Enter] to continue...")

    def select_dropdown(self, table_name, label):
        rows = self.db.fetch_all(f"SELECT * FROM {table_name} ORDER BY name")
        print(f"\n Available {label}s:")
        for r in rows:
            print(f"  [{r['id']}] {r['name']}")
        while True:
            sel = input_int(f"Select {label} ID", required=True)
            if any(r['id'] == sel for r in rows): return sel
            print(f" [!] Invalid {label} ID.")

    def add_product(self):
        print_header("ADD NEW PRODUCT")
        code = input_str("Product Code / SKU")
        if self.db.fetch_one("SELECT id FROM products WHERE code=?", (code,)):
            print(" [!] Product Code already exists."); input(" Press [Enter]..."); return
        barcode = input_str("Barcode (optional)", required=False)
        name = input_str("Product Name")
        cat_id = self.select_dropdown('categories', 'Category')
        brd_id = self.select_dropdown('brands', 'Brand')
        unt_id = self.select_dropdown('units', 'Unit')
        
        pur_p = input_dec("Purchase Price", default='0.00')
        sale_p = input_dec("Retail Sale Price", default='0.00')
        whol_p = input_dec("Wholesale Price", default=str(sale_p))
        ret_p = input_dec("Retail MSRP", default=str(sale_p))
        min_stk = input_dec("Minimum Stock Warning Level", default='5.00')
        opn_stk = input_dec("Opening Stock Quantity", default='0.00')
        tax_pct = input_dec("Tax Percentage", default=self.db.get_setting('tax_rate', '0.00'))
        disc_all = 1 if input_str("Discount Allowed? (Y/N)", default="Y").upper() == 'Y' else 0
        exp_dt = input_str("Expiry Date YYYY-MM-DD (optional)", required=False)
        batch = input_str("Batch Number (optional)", required=False)
        rack = input_str("Rack / Location (optional)", required=False)
        
        now = datetime.datetime.now().isoformat()
        with self.db.conn:
            pid = self.db.execute("""INSERT INTO products (code, barcode, name, category_id, brand_id, unit_id,
                                     purchase_price, sale_price, wholesale_price, retail_price, min_stock,
                                     opening_stock, current_stock, tax_percent, discount_allowed, expiry_date,
                                     batch_number, rack_location, is_active, created_at, updated_at)
                                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?)""",
                                  (code, barcode, name, cat_id, brd_id, unt_id, str(pur_p), str(sale_p),
                                   str(whol_p), str(ret_p), str(min_stk), str(opn_stk), str(opn_stk),
                                   str(tax_pct), disc_all, exp_dt, batch, rack, now, now))
            if opn_stk > 0:
                self.db.execute("""INSERT INTO stock_movements (product_id, move_date, move_type, qty, ref_id, description)
                                   VALUES (?, ?, ?, ?, ?, ?)""",
                                (pid, datetime.date.today().isoformat(), 'OPENING', str(opn_stk), 'INIT', 'Opening Stock'))
        self.audit.log("ADD_PRODUCT", f"Added product {name} (SKU: {code})")
        print("\n [+] Product added successfully!"); input(" Press [Enter]...")

    def edit_product(self):
        pid = input_int("Enter Product ID to Edit")
        p = self.db.fetch_one("SELECT * FROM products WHERE id=?", (pid,))
        if not p:
            print(" [!] Product not found."); input(" Press [Enter]..."); return
            
        print_header(f"EDIT PRODUCT: {p['name']} ({p['code']})")
        name = input_str("Product Name", default=p['name'])
        barcode = input_str("Barcode", required=False, default=p['barcode'] or "")
        
        pur_p = input_dec("Purchase Price", default=p['purchase_price'])
        sale_p = input_dec("Retail Sale Price", default=p['sale_price'])
        whol_p = input_dec("Wholesale Price", default=p['wholesale_price'])
        min_stk = input_dec("Minimum Stock Level", default=p['min_stock'])
        tax_pct = input_dec("Tax Percentage", default=p['tax_percent'])
        disc_all = 1 if input_str("Discount Allowed? (Y/N)", default="Y" if p['discount_allowed']==1 else "N").upper()=='Y' else 0
        rack = input_str("Rack Location", required=False, default=p['rack_location'] or "")
        
        now = datetime.datetime.now().isoformat()
        uid = self.auth.current_user['id']
        with self.db.conn:
            if D(pur_p) != D(p['purchase_price']):
                self.db.execute("INSERT INTO product_price_history (product_id, old_price, new_price, price_type, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?)",
                                (pid, p['purchase_price'], str(pur_p), 'PURCHASE', uid, now))
            if D(sale_p) != D(p['sale_price']):
                self.db.execute("INSERT INTO product_price_history (product_id, old_price, new_price, price_type, changed_by, changed_at) VALUES (?, ?, ?, ?, ?, ?)",
                                (pid, p['sale_price'], str(sale_p), 'SALE', uid, now))
            self.db.execute("""UPDATE products SET name=?, barcode=?, purchase_price=?, sale_price=?, wholesale_price=?,
                               min_stock=?, tax_percent=?, discount_allowed=?, rack_location=?, updated_at=? WHERE id=?""",
                            (name, barcode, str(pur_p), str(sale_p), str(whol_p), str(min_stk), str(tax_pct), disc_all, rack, now, pid))
        self.audit.log("EDIT_PRODUCT", f"Edited product ID {pid}")
        print("\n [+] Product updated successfully!"); input(" Press [Enter]...")

    def toggle_product_status(self):
        pid = input_int("Enter Product ID to Toggle Status")
        p = self.db.fetch_one("SELECT name, is_active FROM products WHERE id=?", (pid,))
        if not p: print(" [!] Product not found."); input(" Press [Enter]..."); return
        new_status = 0 if p['is_active'] == 1 else 1
        self.db.execute("UPDATE products SET is_active=? WHERE id=?", (new_status, pid))
        st_str = "Activated" if new_status==1 else "Deactivated"
        self.audit.log("TOGGLE_PRODUCT", f"{st_str} product ID {pid}")
        print(f"\n [+] Product successfully {st_str}!"); input(" Press [Enter]...")

    def view_inactive_products(self):
        self.list_products(active_only=False, search_q=None)

    def stock_adjustment(self):
        print_header("MANUAL STOCK ADJUSTMENT")
        pid = input_int("Enter Product ID")
        p = self.db.fetch_one("SELECT code, name, current_stock FROM products WHERE id=?", (pid,))
        if not p: print(" [!] Product not found."); input(" Press [Enter]..."); return
        
        print(f" Current Stock for {p['name']}: {D(p['current_stock'])}")
        print(" 1. Increase Stock (+) ")
        print(" 2. Decrease Stock (-) ")
        adj_type = input(" Select Adjustment Type: ").strip()
        if adj_type not in ('1', '2'): return
        
        qty = input_dec("Enter Quantity", min_val='0.01')
        reason = input_str("Enter Reason (e.g., Damaged, Found, Audit correction)")
        
        curr_stk = D(p['current_stock'])
        if adj_type == '1':
            new_stk = curr_stk + qty
            m_type = 'ADJUSTMENT_IN'
        else:
            if curr_stk < qty and self.db.get_setting('allow_negative_stock', '0') != '1':
                print(" [!] Cannot decrease below zero."); input(" Press [Enter]..."); return
            new_stk = curr_stk - qty
            m_type = 'ADJUSTMENT_OUT'
            
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        with self.db.conn:
            self.db.execute("UPDATE products SET current_stock=? WHERE id=?", (str(new_stk), pid))
            self.db.execute("INSERT INTO stock_adjustments (product_id, adj_date, adj_type, qty, reason, created_by) VALUES (?, ?, ?, ?, ?, ?)",
                            (pid, today, m_type, str(qty), reason, uid))
            self.db.execute("INSERT INTO stock_movements (product_id, move_date, move_type, qty, ref_id, description) VALUES (?, ?, ?, ?, ?, ?)",
                            (pid, today, m_type, str(qty if adj_type=='1' else -qty), 'ADJ', reason))
        self.audit.log("STOCK_ADJUSTMENT", f"Adjusted stock for ID {pid} by {qty} ({m_type})")
        print("\n [+] Stock adjusted successfully!"); input(" Press [Enter]...")

    def view_price_history(self):
        pid = input_int("Enter Product ID to View Price History")
        rows = self.db.fetch_all("""SELECT h.*, u.username FROM product_price_history h
                                    LEFT JOIN users u ON h.changed_by = u.id
                                    WHERE h.product_id=? ORDER BY h.id DESC""", (pid,))
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['changed_at'][:16], r['price_type'], f"{curr}{D(r['old_price'])}", f"{curr}{D(r['new_price'])}", r['username']] for r in rows]
        print_header("PRICE UPDATE HISTORY")
        print(format_table(["Date Time", "Type", "Old Price", "New Price", "Changed By"], t_data))
        input(" Press [Enter] to continue...")

    def view_stock_history(self):
        pid = input_int("Enter Product ID to View Stock Movement Ledger")
        rows = self.db.fetch_all("SELECT * FROM stock_movements WHERE product_id=? ORDER BY id DESC LIMIT 50", (pid,))
        t_data = [[r['move_date'], r['move_type'], D(r['qty']), r['ref_id'], r['description'][:30]] for r in rows]
        print_header("STOCK MOVEMENT LEDGER")
        print(format_table(["Date", "Movement Type", "Quantity", "Ref ID", "Description"], t_data))
        input(" Press [Enter] to continue...")

class PartyManager:
    def __init__(self, db, auth, audit, party_type):
        self.db = db
        self.auth = auth
        self.audit = audit
        self.ptype = party_type # 'customers' or 'suppliers'
        self.singular = 'Customer' if party_type == 'customers' else 'Supplier'
        self.prefix = 'CUST-' if party_type == 'customers' else 'SUPP-'

    def menu(self):
        while True:
            print_header(f"{self.singular.upper()} MANAGEMENT & KHATA")
            print(f" 1. Add New {self.singular}")
            print(f" 2. View All {self.singular}s")
            print(f" 3. Edit {self.singular}")
            print(f" 4. Search {self.singular}")
            print(f" 5. {self.singular} Ledger / Khata Statement")
            print(f" 6. Receive / Make Payment")
            print(f" 7. Deactivate / Activate {self.singular}")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            c = input(" Select Option: ").strip()
            if c == '1': self.add_party()
            elif c == '2': self.list_parties()
            elif c == '3': self.edit_party()
            elif c == '4':
                q = input_str("Enter Code, Name, or Phone to search")
                self.list_parties(search_q=q)
            elif c == '5': self.view_khata()
            elif c == '6': self.payment_entry()
            elif c == '7':
                if not self.auth.require_role(['Admin', 'Manager']): continue
                self.toggle_status()
            elif c == '0': break

    def next_code(self):
        cnt = self.db.fetch_val(f"SELECT COUNT(*) FROM {self.ptype}")
        return f"{self.prefix}{cnt+1:04d}"

    def add_party(self):
        print_header(f"ADD NEW {self.singular.upper()}")
        code = input_str(f"{self.singular} Code", default=self.next_code())
        name = input_str("Name / Shop Name")
        phone = input_str("Phone Number", required=False)
        addr = input_str("Address", required=False)
        email = input_str("Email", required=False)
        opn_bal = input_dec("Opening Balance (+ for owing us, - for advance)", required=False, default='0.00')
        limit = input_dec("Credit Limit", required=False, default='0.00') if self.ptype=='customers' else D('0.00')
        
        now = datetime.datetime.now().isoformat()
        today = datetime.date.today().isoformat()
        with self.db.conn:
            if self.ptype == 'customers':
                pid = self.db.execute("""INSERT INTO customers (code, name, phone, address, email, opening_balance, current_balance, credit_limit, is_active, created_at)
                                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?)""",
                                      (code, name, phone, addr, email, str(opn_bal), str(opn_bal), str(limit), now))
                if opn_bal != 0:
                    self.db.execute("INSERT INTO customer_ledger (customer_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                    (pid, today, 'OPENING', str(opn_bal if opn_bal>0 else 0), str(-opn_bal if opn_bal<0 else 0), str(opn_bal), 'Opening Balance', 'INIT'))
            else:
                pid = self.db.execute("""INSERT INTO suppliers (code, name, phone, address, email, opening_balance, current_balance, is_active, created_at)
                                         VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)""",
                                      (code, name, phone, addr, email, str(opn_bal), str(opn_bal), now))
                if opn_bal != 0:
                    self.db.execute("INSERT INTO supplier_ledger (supplier_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                    (pid, today, 'OPENING', str(-opn_bal if opn_bal<0 else 0), str(opn_bal if opn_bal>0 else 0), str(opn_bal), 'Opening Balance', 'INIT'))
        self.audit.log(f"ADD_{self.singular.upper()}", f"Added {self.singular}: {name}")
        print("\n [+] Added successfully!"); input(" Press [Enter]...")

    def list_parties(self, search_q=None):
        q = f"SELECT * FROM {self.ptype} "
        params = []
        if search_q:
            q += "WHERE code LIKE ? OR name LIKE ? OR phone LIKE ?"
            params.extend([f"%{search_q}%", f"%{search_q}%", f"%{search_q}%"])
        q += " ORDER BY name"
        rows = self.db.fetch_all(q, params)
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['id'], r['code'], r['name'][:22], r['phone'], f"{curr}{D(r['current_balance'])}", "Active" if r['is_active']==1 else "Inactive"] for r in rows]
        print_header(f"{self.singular.upper()} LIST")
        print(format_table(["ID", "Code", "Name", "Phone", "Balance", "Status"], t_data))
        input(" Press [Enter] to continue...")

    def edit_party(self):
        pid = input_int(f"Enter {self.singular} ID to Edit")
        p = self.db.fetch_one(f"SELECT * FROM {self.ptype} WHERE id=?", (pid,))
        if not p: print(" [!] Record not found."); input(" Press [Enter]..."); return
        print_header(f"EDIT {self.singular.upper()}: {p['name']}")
        name = input_str("Name", default=p['name'])
        phone = input_str("Phone", required=False, default=p['phone'] or "")
        addr = input_str("Address", required=False, default=p['address'] or "")
        email = input_str("Email", required=False, default=p['email'] or "")
        if self.ptype == 'customers':
            limit = input_dec("Credit Limit", default=p['credit_limit'])
            self.db.execute("UPDATE customers SET name=?, phone=?, address=?, email=?, credit_limit=? WHERE id=?", (name, phone, addr, email, str(limit), pid))
        else:
            self.db.execute("UPDATE suppliers SET name=?, phone=?, address=?, email=? WHERE id=?", (name, phone, addr, email, pid))
        self.audit.log(f"EDIT_{self.singular.upper()}", f"Updated ID {pid}")
        print("\n [+] Updated successfully!"); input(" Press [Enter]...")

    def toggle_status(self):
        pid = input_int(f"Enter {self.singular} ID")
        p = self.db.fetch_one(f"SELECT is_active FROM {self.ptype} WHERE id=?", (pid,))
        if not p: return
        ns = 0 if p['is_active']==1 else 1
        self.db.execute(f"UPDATE {self.ptype} SET is_active=? WHERE id=?", (ns, pid))
        print("\n [+] Status toggled successfully!"); input(" Press [Enter]...")

    def view_khata(self):
        pid = input_int(f"Enter {self.singular} ID for Ledger Statement")
        p = self.db.fetch_one(f"SELECT code, name, current_balance FROM {self.ptype} WHERE id=?", (pid,))
        if not p: print(" [!] Not found."); input(" Press [Enter]..."); return
        
        tbl = 'customer_ledger' if self.ptype == 'customers' else 'supplier_ledger'
        col = 'customer_id' if self.ptype == 'customers' else 'supplier_id'
        rows = self.db.fetch_all(f"SELECT * FROM {tbl} WHERE {col}=? ORDER BY trans_date, id", (pid,))
        
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['trans_date'], r['trans_type'], f"{curr}{D(r['debit'])}", f"{curr}{D(r['credit'])}", f"{curr}{D(r['running_balance'])}", r['description'][:25]] for r in rows]
        print_header(f"KHATA STATEMENT: {p['name']} ({p['code']}) - Bal: {curr}{D(p['current_balance'])}")
        print(format_table(["Date", "Type", "Debit (+)", "Credit (-)", "Running Bal", "Description"], t_data))
        
        print("\n Options: [1] Export CSV  [0] Back")
        if input(" Select: ").strip() == '1':
            export_csv_file(f"Khata_{p['code']}", ["Date", "Type", "Debit", "Credit", "Balance", "Description"], t_data)

    def payment_entry(self):
        print_header(f"{'RECEIVE PAYMENT FROM CUSTOMER' if self.ptype=='customers' else 'PAY TO SUPPLIER'}")
        pid = input_int(f"Enter {self.singular} ID")
        p = self.db.fetch_one(f"SELECT * FROM {self.ptype} WHERE id=?", (pid,))
        if not p: print(" [!] Not found."); input(" Press [Enter]..."); return
        
        curr = self.db.get_setting('currency', '$')
        print(f" Current Outstanding Balance for {p['name']}: {curr}{D(p['current_balance'])}")
        amt = input_dec("Enter Payment Amount", min_val='0.01')
        
        accs = self.db.fetch_all("SELECT * FROM cash_bank_accounts WHERE is_active=1")
        print("\n Select Account for Transaction:")
        for a in accs: print(f"  [{a['id']}] {a['name']} (Bal: {curr}{D(a['balance'])})")
        acc_id = input_int("Account ID", required=True)
        if not any(a['id']==acc_id for a in accs): return
        
        notes = input_str("Reference / Remarks", required=False, default="Cash/Bank Payment")
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        
        with self.db.conn:
            # Update account
            acc = self.db.fetch_one("SELECT balance FROM cash_bank_accounts WHERE id=?", (acc_id,))
            if self.ptype == 'customers':
                new_acc_bal = D(acc['balance']) + amt
                t_type = 'IN'
                # Customer Khata: Credit reduces balance
                new_p_bal = D(p['current_balance']) - amt
                self.db.execute("INSERT INTO customer_ledger (customer_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                (pid, today, 'PAYMENT', '0.00', str(amt), str(new_p_bal), notes, 'PAY'))
            else:
                new_acc_bal = D(acc['balance']) - amt
                t_type = 'OUT'
                # Supplier Khata: Debit reduces balance
                new_p_bal = D(p['current_balance']) - amt
                self.db.execute("INSERT INTO supplier_ledger (supplier_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                (pid, today, 'PAYMENT', str(amt), '0.00', str(new_p_bal), notes, 'PAY'))
                
            self.db.execute(f"UPDATE {self.ptype} SET current_balance=? WHERE id=?", (str(new_p_bal), pid))
            self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(new_acc_bal), acc_id))
            self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            (acc_id, today, t_type, str(amt), f"{self.singular} Payment: {p['name']} - {notes}", f"PTY_{pid}", uid))
                            
        self.audit.log("PARTY_PAYMENT", f"Processed {amt} for {p['name']}")
        print("\n [+] Payment recorded successfully!"); input(" Press [Enter]...")

class FinanceManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        while True:
            print_header("CASH & BANK MANAGEMENT")
            print(" 1. View Accounts & Balances")
            print(" 2. Cash / Bank Deposit (+)")
            print(" 3. Cash / Bank Withdrawal (-)")
            print(" 4. Fund Transfer Between Accounts")
            print(" 5. View Transaction Book")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            c = input(" Select Option: ").strip()
            if c == '1': self.list_accounts()
            elif c == '2': self.transact('IN')
            elif c == '3': self.transact('OUT')
            elif c == '4': self.transfer()
            elif c == '5': self.book()
            elif c == '0': break

    def list_accounts(self):
        rows = self.db.fetch_all("SELECT * FROM cash_bank_accounts")
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['id'], r['name'], r['type'], f"{curr}{D(r['balance'])}", "Active" if r['is_active']==1 else "Inactive"] for r in rows]
        print_header("FINANCIAL ACCOUNTS")
        print(format_table(["ID", "Account Name", "Type", "Current Balance", "Status"], t_data))
        input(" Press [Enter]...")

    def transact(self, t_type):
        lbl = "DEPOSIT" if t_type=='IN' else "WITHDRAWAL"
        print_header(f"ACCOUNT {lbl}")
        self.list_accounts()
        acc_id = input_int("Select Account ID")
        acc = self.db.fetch_one("SELECT * FROM cash_bank_accounts WHERE id=?", (acc_id,))
        if not acc: return
        amt = input_dec("Enter Amount", min_val='0.01')
        desc = input_str("Description / Source")
        
        curr_bal = D(acc['balance'])
        new_bal = (curr_bal + amt) if t_type=='IN' else (curr_bal - amt)
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        
        with self.db.conn:
            self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(new_bal), acc_id))
            self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            (acc_id, today, t_type, str(amt), desc, 'MANUAL', uid))
        self.audit.log(f"ACC_{lbl}", f"{amt} on account {acc['name']}")
        print("\n [+] Transaction saved!"); input(" Press [Enter]...")

    def transfer(self):
        print_header("TRANSFER FUNDS")
        self.list_accounts()
        from_id = input_int("From Account ID")
        to_id = input_int("To Account ID")
        if from_id == to_id: print(" [!] Cannot transfer to same account."); input(" Press [Enter]..."); return
        a_from = self.db.fetch_one("SELECT * FROM cash_bank_accounts WHERE id=?", (from_id,))
        a_to = self.db.fetch_one("SELECT * FROM cash_bank_accounts WHERE id=?", (to_id,))
        if not a_from or not a_to: return
        
        amt = input_dec("Amount to Transfer", min_val='0.01')
        if D(a_from['balance']) < amt:
            print(" [!] Insufficient funds in source account."); input(" Press [Enter]..."); return
        
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        with self.db.conn:
            self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(D(a_from['balance'])-amt), from_id))
            self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(D(a_to['balance'])+amt), to_id))
            self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            (from_id, today, 'OUT', str(amt), f"Transfer to {a_to['name']}", 'XFER', uid))
            self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            (to_id, today, 'IN', str(amt), f"Transfer from {a_from['name']}", 'XFER', uid))
        self.audit.log("FUND_TRANSFER", f"Transferred {amt} from {a_from['name']} to {a_to['name']}")
        print("\n [+] Transfer complete!"); input(" Press [Enter]...")

    def book(self):
        print_header("TRANSACTION BOOK")
        rows = self.db.fetch_all("""SELECT t.*, a.name as acc, u.username FROM cash_bank_transactions t
                                    JOIN cash_bank_accounts a ON t.account_id=a.id
                                    LEFT JOIN users u ON t.created_by=u.id ORDER BY t.id DESC LIMIT 100""")
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['trans_date'], r['acc'][:15], r['trans_type'], f"{curr}{D(r['amount'])}", r['description'][:28], r['username']] for r in rows]
        print(format_table(["Date", "Account", "Type", "Amount", "Description", "User"], t_data))
        input(" Press [Enter]...")

class ExpenseManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        while True:
            print_header("EXPENSE MANAGEMENT")
            print(" 1. Add New Expense")
            print(" 2. View All Expenses")
            print(" 3. Manage Expense Categories")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            c = input(" Select Option: ").strip()
            if c == '1': self.add_expense()
            elif c == '2': self.list_expenses()
            elif c == '3': self.manage_categories()
            elif c == '0': break

    def manage_categories(self):
        while True:
            print_header("EXPENSE CATEGORIES")
            rows = self.db.fetch_all("SELECT * FROM expense_categories")
            print(format_table(["ID", "Category Name"], [[r['id'], r['name']] for r in rows]))
            print("-" * 75)
            print(" 1. Add Category  |  0. Back")
            if input(" Select: ").strip() == '1':
                n = input_str("Category Name")
                try: self.db.execute("INSERT INTO expense_categories (name) VALUES (?)", (n,))
                except Exception: print(" [!] Error or duplicate.")
            else: break

    def add_expense(self):
        print_header("RECORD EXPENSE")
        cats = self.db.fetch_all("SELECT * FROM expense_categories")
        for c in cats: print(f" [{c['id']}] {c['name']}")
        cat_id = input_int("Select Category ID", required=True)
        if not any(c['id']==cat_id for c in cats): return
        
        amt = input_dec("Expense Amount", min_val='0.01')
        desc = input_str("Description")
        paid_to = input_str("Paid To / Vendor", required=False)
        dt = input_date("Expense Date")
        
        accs = self.db.fetch_all("SELECT * FROM cash_bank_accounts WHERE is_active=1")
        for a in accs: print(f" [{a['id']}] {a['name']} (Bal: {D(a['balance'])})")
        acc_id = input_int("Pay From Account ID", required=True)
        if not any(a['id']==acc_id for a in accs): return
        
        uid = self.auth.current_user['id']
        with self.db.conn:
            self.db.execute("""INSERT INTO expenses (category_id, description, amount, payment_method, account_id, exp_date, paid_to, notes, created_by)
                               VALUES (?, ?, ?, 'ACC', ?, ?, ?, '', ?)""",
                            (cat_id, desc, str(amt), acc_id, dt, paid_to, uid))
            acc = self.db.fetch_one("SELECT balance FROM cash_bank_accounts WHERE id=?", (acc_id,))
            self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(D(acc['balance'])-amt), acc_id))
            self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                            (acc_id, dt, 'OUT', str(amt), f"Expense: {desc}", 'EXP', uid))
        self.audit.log("ADD_EXPENSE", f"Recorded expense {amt} ({desc})")
        print("\n [+] Expense saved successfully!"); input(" Press [Enter]...")

    def list_expenses(self):
        rows = self.db.fetch_all("""SELECT e.*, ec.name as cat, u.username FROM expenses e
                                    JOIN expense_categories ec ON e.category_id=ec.id
                                    LEFT JOIN users u ON e.created_by=u.id ORDER BY e.exp_date DESC LIMIT 100""")
        curr = self.db.get_setting('currency', '$')
        t_data = [[r['exp_date'], r['cat'], f"{curr}{D(r['amount'])}", r['paid_to'][:15], r['description'][:25], r['username']] for r in rows]
        print_header("EXPENSE RECORDS")
        print(format_table(["Date", "Category", "Amount", "Paid To", "Description", "Logged By"], t_data))
        input(" Press [Enter]...")

# =====================================================================
# SALES & PURCHASES (TRANSACTIONS)
# =====================================================================

class TradeManager:
    def __init__(self, db, auth, audit, trade_type):
        self.db = db; self.auth = auth; self.audit = audit
        self.ttype = trade_type # 'SALES' or 'PURCHASES'
        self.is_sale = (trade_type == 'SALES')

    def menu(self):
        lbl = "SALES / POS" if self.is_sale else "PURCHASES"
        while True:
            print_header(f"{lbl} MANAGEMENT")
            print(f" 1. Create New {'Sale Invoice (POS)' if self.is_sale else 'Purchase Invoice'}")
            print(f" 2. View {'Sales' if self.is_sale else 'Purchase'} Invoices")
            print(f" 3. Process {'Sale' if self.is_sale else 'Purchase'} Return")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            c = input(" Select Option: ").strip()
            if c == '1': self.create_invoice()
            elif c == '2': self.view_invoices()
            elif c == '3': self.process_return()
            elif c == '0': break

    def create_invoice(self):
        lbl = "SALE INVOICE" if self.is_sale else "PURCHASE INVOICE"
        print_header(f"NEW {lbl}")
        
        # Select Party
        party_id = None
        party_name = "Walk-in Customer"
        cust_type = "WALKIN"
        
        if self.is_sale:
            print(" Customer Type: [1] Walk-in Customer  [2] Registered Customer")
            if input(" Select: ").strip() == '2':
                parties = self.db.fetch_all("SELECT * FROM customers WHERE is_active=1")
                for p in parties: print(f" [{p['id']}] {p['name']} ({p['phone']})")
                party_id = input_int("Select Customer ID", required=True)
                p_row = self.db.fetch_one("SELECT name FROM customers WHERE id=?", (party_id,))
                if not p_row: return
                party_name = p_row['name']
                cust_type = "REGISTERED"
        else:
            parties = self.db.fetch_all("SELECT * FROM suppliers WHERE is_active=1")
            for p in parties: print(f" [{p['id']}] {p['name']}")
            party_id = input_int("Select Supplier ID", required=True)
            p_row = self.db.fetch_one("SELECT name FROM suppliers WHERE id=?", (party_id,))
            if not p_row: return
            party_name = p_row['name']

        # Cart loop
        cart = []
        curr = self.db.get_setting('currency', '$')
        while True:
            print("\n" + "-"*50)
            sq = input_str("Enter Product SKU/Barcode/Name to add (or 'DONE' to finish)")
            if sq.upper() == 'DONE':
                if not cart: print(" [!] Cart is empty."); return
                break
            prods = self.db.fetch_all("""SELECT p.*, u.name as unt FROM products p
                                         LEFT JOIN units u ON p.unit_id=u.id
                                         WHERE p.is_active=1 AND (p.code LIKE ? OR p.barcode LIKE ? OR p.name LIKE ?)""",
                                      (f"%{sq}%", f"%{sq}%", f"%{sq}%"))
            if not prods: print(" [!] No matching products found."); continue
            for pr in prods:
                print(f"  [{pr['id']}] {pr['name']} ({pr['code']}) - Stock: {D(pr['current_stock'])} {pr['unt']} | Price: {curr}{D(pr['sale_price'] if self.is_sale else pr['purchase_price'])}")
            pr_id = input_int("Select Product ID")
            prod = next((x for x in prods if x['id']==pr_id), None)
            if not prod: continue
            
            qty = input_dec("Enter Quantity", min_val='0.01', default='1.00')
            if self.is_sale:
                if D(prod['current_stock']) < qty and self.db.get_setting('allow_negative_stock', '0') != '1':
                    print(" [!] Insufficient stock available!"); continue
            price = input_dec("Unit Price", default=prod['sale_price'] if self.is_sale else prod['purchase_price'])
            disc = input_dec("Discount per unit", default='0.00')
            tax_rate = D(prod['tax_percent'])
            
            net_unit = price - disc
            tax_amt = (net_unit * (tax_rate / D('100.00'))).quantize(Decimal('0.01'))
            item_total = (net_unit + tax_amt) * qty
            
            batch = ""
            expiry = ""
            if not self.is_sale:
                batch = input_str("Batch No (optional)", required=False)
                expiry = input_str("Expiry Date YYYY-MM-DD (optional)", required=False)
                
            cart.append({
                'prod_id': prod['id'], 'name': prod['name'], 'code': prod['code'], 'qty': qty,
                'price': price, 'cost_price': D(prod['purchase_price']), 'disc': disc * qty,
                'tax': tax_amt * qty, 'total': item_total, 'batch': batch, 'expiry': expiry
            })
            print(f" [+] Added {prod['name']} x {qty} to cart.")

        # Summary
        subtotal = sum(x['price'] * x['qty'] for x in cart)
        tot_disc = sum(x['disc'] for x in cart)
        tot_tax = sum(x['tax'] for x in cart)
        overall_disc = input_dec("Overall Additional Discount", default='0.00') if self.is_sale else D('0.00')
        freight = input_dec("Freight / Extra Charges", default='0.00') if not self.is_sale else D('0.00')
        
        grand_total = subtotal - tot_disc - overall_disc + tot_tax + freight
        
        print_header("INVOICE SUMMARY")
        print(f" Party: {party_name}")
        print(f" Subtotal:        {curr}{subtotal}")
        print(f" Total Discounts: {curr}{tot_disc + overall_disc}")
        print(f" Total Tax:       {curr}{tot_tax}")
        if not self.is_sale: print(f" Freight:         {curr}{freight}")
        print(f" GRAND TOTAL:     {curr}{grand_total}")
        print("-" * 50)
        
        paid_amt = input_dec("Paid Amount Now", min_val='0.00', default=str(grand_total))
        if paid_amt > grand_total: paid_amt = grand_total
        bal_due = grand_total - paid_amt
        
        if bal_due > 0 and self.is_sale and cust_type == 'WALKIN':
            print(" [!] Credit sales are not allowed for walk-in customers. Please pay full amount or select registered customer.")
            input(" Press [Enter] to abort..."); return

        acc_id = None
        if paid_amt > 0:
            accs = self.db.fetch_all("SELECT * FROM cash_bank_accounts WHERE is_active=1")
            print("\n Select Payment Account:")
            for a in accs: print(f"  [{a['id']}] {a['name']} (Bal: {D(a['balance'])})")
            acc_id = input_int("Account ID", required=True)
            if not any(a['id']==acc_id for a in accs): return

        # Execute Transaction
        prefix = self.db.get_setting('inv_prefix', 'INV-') if self.is_sale else self.db.get_setting('pur_prefix', 'PUR-')
        tbl = 'sales' if self.is_sale else 'purchases'
        cnt = self.db.fetch_val(f"SELECT COUNT(*) FROM {tbl}")
        inv_no = f"{prefix}{datetime.datetime.now().strftime('%y%m%d')}-{cnt+1:04d}"
        now = datetime.datetime.now().isoformat()
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        
        with self.db.conn:
            if self.is_sale:
                tid = self.db.execute("""INSERT INTO sales (invoice_no, customer_id, customer_type, sale_date, subtotal, overall_discount, total_tax, grand_total, paid_amount, balance_amount, payment_method, account_id, created_by, created_at)
                                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'MIXED', ?, ?, ?)""",
                                      (inv_no, party_id, cust_type, now, str(subtotal), str(overall_disc + tot_disc), str(tot_tax), str(grand_total), str(paid_amt), str(bal_due), acc_id, uid, now))
                for it in cart:
                    self.db.execute("INSERT INTO sale_items (sale_id, product_id, qty, price, cost_price, discount, tax, total) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                                    (tid, it['prod_id'], str(it['qty']), str(it['price']), str(it['cost_price']), str(it['disc']), str(it['tax']), str(it['total'])))
                    p_stk = self.db.fetch_val("SELECT current_stock FROM products WHERE id=?", (it['prod_id'],))
                    self.db.execute("UPDATE products SET current_stock=? WHERE id=?", (str(D(p_stk)-it['qty']), it['prod_id']))
                    self.db.execute("INSERT INTO stock_movements (product_id, move_date, move_type, qty, ref_id, description) VALUES (?, ?, 'SALE', ?, ?, ?)",
                                    (it['prod_id'], today, str(-it['qty']), inv_no, f"POS Sale #{inv_no}"))
                if cust_type == 'REGISTERED':
                    p_bal = self.db.fetch_val("SELECT current_balance FROM customers WHERE id=?", (party_id,))
                    new_bal = D(p_bal) + bal_due
                    self.db.execute("UPDATE customers SET current_balance=? WHERE id=?", (str(new_bal), party_id))
                    self.db.execute("INSERT INTO customer_ledger (customer_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, 'SALE', ?, ?, ?, ?, ?)",
                                    (party_id, today, str(grand_total), str(paid_amt), str(new_bal), f"Invoice #{inv_no}", inv_no))
            else:
                tid = self.db.execute("""INSERT INTO purchases (invoice_no, supplier_id, purchase_date, subtotal, discount, tax, freight, grand_total, paid_amount, balance_amount, payment_method, account_id, created_by, created_at)
                                         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'MIXED', ?, ?, ?)""",
                                      (inv_no, party_id, today, str(subtotal), str(tot_disc), str(tot_tax), str(freight), str(grand_total), str(paid_amt), str(bal_due), acc_id, uid, now))
                for it in cart:
                    self.db.execute("INSERT INTO purchase_items (purchase_id, product_id, qty, price, discount, tax, total, batch_no, expiry) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                    (tid, it['prod_id'], str(it['qty']), str(it['price']), str(it['disc']), str(it['tax']), str(it['total']), it['batch'], it['expiry']))
                    p_stk = self.db.fetch_val("SELECT current_stock FROM products WHERE id=?", (it['prod_id'],))
                    self.db.execute("UPDATE products SET current_stock=?, purchase_price=? WHERE id=?", (str(D(p_stk)+it['qty']), str(it['price']), it['prod_id']))
                    self.db.execute("INSERT INTO stock_movements (product_id, move_date, move_type, qty, ref_id, description) VALUES (?, ?, 'PURCHASE', ?, ?, ?)",
                                    (it['prod_id'], today, str(it['qty']), inv_no, f"Purchase #{inv_no}"))
                p_bal = self.db.fetch_val("SELECT current_balance FROM suppliers WHERE id=?", (party_id,))
                new_bal = D(p_bal) + bal_due
                self.db.execute("UPDATE suppliers SET current_balance=? WHERE id=?", (str(new_bal), party_id))
                self.db.execute("INSERT INTO supplier_ledger (supplier_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, 'PURCHASE', ?, ?, ?, ?, ?)",
                                (party_id, today, str(paid_amt), str(grand_total), str(new_bal), f"Invoice #{inv_no}", inv_no))

            if paid_amt > 0:
                a_bal = self.db.fetch_val("SELECT balance FROM cash_bank_accounts WHERE id=?", (acc_id,))
                new_a_bal = (D(a_bal) + paid_amt) if self.is_sale else (D(a_bal) - paid_amt)
                self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(new_a_bal), acc_id))
                self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                                (acc_id, today, 'IN' if self.is_sale else 'OUT', str(paid_amt), f"{lbl} #{inv_no}", inv_no, uid))

        self.audit.log(f"NEW_{lbl.replace(' ','_')}", f"Created {inv_no} for {grand_total}")
        self.print_receipt(inv_no, party_name, cart, grand_total, paid_amt, bal_due)

    def print_receipt(self, inv_no, party_name, cart, grand_total, paid_amt, bal_due):
        shop_name = self.db.get_setting('shop_name', 'My Shop')
        shop_addr = self.db.get_setting('shop_address', '')
        shop_phone = self.db.get_setting('phone', '')
        curr = self.db.get_setting('currency', '$')
        footer = self.db.get_setting('footer_msg', '')
        
        lines = []
        lines.append("=" * 60)
        lines.append(shop_name.center(60))
        if shop_addr: lines.append(shop_addr.center(60))
        if shop_phone: lines.append(f"Phone: {shop_phone}".center(60))
        lines.append("=" * 60)
        lines.append(f" Inv No: {inv_no:<25} Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M')}")
        lines.append(f" Party:  {party_name}")
        lines.append("-" * 60)
        lines.append(f" {'Item Name':<28} {'Qty':<8} {'Price':<10} {'Total':<10}")
        lines.append("-" * 60)
        for it in cart:
            lines.append(f" {it['name'][:28]:<28} {D(it['qty']):<8} {curr}{D(it['price']):<9} {curr}{D(it['total']):<9}")
        lines.append("-" * 60)
        lines.append(f" {'GRAND TOTAL:':>45} {curr}{grand_total:<10}")
        lines.append(f" {'Paid Amount:':>45} {curr}{paid_amt:<10}")
        lines.append(f" {'Balance Due:':>45} {curr}{bal_due:<10}")
        lines.append("=" * 60)
        if footer: lines.append(footer.center(60))
        lines.append("=" * 60)
        
        txt = "\n".join(lines)
        print("\n" + txt)
        print("\n Options: [S] Save Receipt to Text File  [Enter] Continue")
        if input(" Select: ").strip().upper() == 'S':
            try:
                with open(f"Receipt_{inv_no}.txt", 'w', encoding='utf-8') as f: f.write(txt)
                print(f" [+] Saved to Receipt_{inv_no}.txt")
            except Exception as e: print(f" [!] Error saving receipt: {e}")
        input(" Press [Enter]...")

    def view_invoices(self):
        tbl = 'sales' if self.is_sale else 'purchases'
        ptbl = 'customers' if self.is_sale else 'suppliers'
        pcol = 'customer_id' if self.is_sale else 'supplier_id'
        dtcol = 'sale_date' if self.is_sale else 'purchase_date'
        
        rows = self.db.fetch_all(f"""SELECT i.*, p.name as party FROM {tbl} i
                                     LEFT JOIN {ptbl} p ON i.{pcol} = p.id
                                     ORDER BY i.id DESC LIMIT 50""")
        curr = self.db.get_setting('currency', '$')
        t_data = [[r[dtcol][:10], r['invoice_no'], r['party'] or "Walk-in", f"{curr}{D(r['grand_total'])}", f"{curr}{D(r['paid_amount'])}", f"{curr}{D(r['balance_amount'])}"] for r in rows]
        print_header(f"{'SALES' if self.is_sale else 'PURCHASE'} INVOICE HISTORY")
        print(format_table(["Date", "Invoice No", "Party Name", "Grand Total", "Paid", "Balance Due"], t_data))
        input(" Press [Enter]...")

    def process_return(self):
        lbl = "SALE RETURN" if self.is_sale else "PURCHASE RETURN"
        print_header(lbl)
        inv_no = input_str("Enter original Invoice Number to return")
        tbl = 'sales' if self.is_sale else 'purchases'
        itbl = 'sale_items' if self.is_sale else 'purchase_items'
        fkey = 'sale_id' if self.is_sale else 'purchase_id'
        
        inv = self.db.fetch_one(f"SELECT * FROM {tbl} WHERE invoice_no=?", (inv_no,))
        if not inv: print(" [!] Invoice not found."); input(" Press [Enter]..."); return
        
        items = self.db.fetch_all(f"""SELECT i.*, p.name, p.code FROM {itbl} i
                                      JOIN products p ON i.product_id=p.id WHERE i.{fkey}=?""", (inv['id'],))
        curr = self.db.get_setting('currency', '$')
        print(f"\n Original Items in {inv_no}:")
        for idx, it in enumerate(items):
            print(f"  [{idx+1}] {it['name']} ({it['code']}) - Billed Qty: {D(it['qty'])} @ {curr}{D(it['price'])}")
            
        ret_cart = []
        while True:
            sel = input("\n Select Item Number to Return (or [Enter] if done selecting): ").strip()
            if not sel: break
            try:
                idx = int(sel) - 1
                it = items[idx]
            except Exception: print(" [!] Invalid selection."); continue
            
            rqty = input_dec(f"Enter Quantity to Return (Max {D(it['qty'])})", min_val='0.01', default=str(D(it['qty'])))
            if rqty > D(it['qty']): print(" [!] Cannot return more than billed quantity."); continue
            
            ref_amt = (rqty * D(it['price'])).quantize(Decimal('0.01'))
            ret_cart.append({'prod_id': it['product_id'], 'qty': rqty, 'ref_amt': ref_amt})
            print(f" [+] Added {it['name']} x {rqty} to return.")

        if not ret_cart: return
        tot_refund = sum(x['ref_amt'] for x in ret_cart)
        print(f"\n Total Refund Value: {curr}{tot_refund}")
        reason = input_str("Reason for Return")
        
        acc_id = None
        if input(" Refund Cash/Bank immediately? (Y/N): ").strip().upper() == 'Y':
            accs = self.db.fetch_all("SELECT * FROM cash_bank_accounts WHERE is_active=1")
            for a in accs: print(f"  [{a['id']}] {a['name']} (Bal: {D(a['balance'])})")
            acc_id = input_int("Select Refund Account ID", required=True)
            if not any(a['id']==acc_id for a in accs): return

        prefix = self.db.get_setting('ret_prefix', 'RET-')
        rtbl = 'sale_returns' if self.is_sale else 'purchase_returns'
        ritbl = 'sale_return_items' if self.is_sale else 'purchase_return_items'
        rfkey = 'return_id'
        cnt = self.db.fetch_val(f"SELECT COUNT(*) FROM {rtbl}")
        ret_no = f"{prefix}{datetime.datetime.now().strftime('%y%m%d')}-{cnt+1:04d}"
        today = datetime.date.today().isoformat()
        uid = self.auth.current_user['id']
        party_col = 'customer_id' if self.is_sale else 'supplier_id'
        party_id = inv[party_col]

        with self.db.conn:
            tid = self.db.execute(f"""INSERT INTO {rtbl} (return_no, {fkey}, return_date, total_amount, refund_method, account_id, reason, created_by)
                                      VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                                  (ret_no, inv['id'], today, str(tot_refund), 'ACC' if acc_id else 'CREDIT', acc_id or 0, reason, uid))
            for x in ret_cart:
                self.db.execute(f"INSERT INTO {ritbl} ({rfkey}, product_id, qty, refund_amount) VALUES (?, ?, ?, ?)",
                                (tid, x['prod_id'], str(x['qty']), str(x['ref_amt'])))
                p_stk = self.db.fetch_val("SELECT current_stock FROM products WHERE id=?", (x['prod_id'],))
                # Sale Return increases stock, Purchase Return decreases stock
                new_stk = (D(p_stk) + x['qty']) if self.is_sale else (D(p_stk) - x['qty'])
                self.db.execute("UPDATE products SET current_stock=? WHERE id=?", (str(new_stk), x['prod_id']))
                self.db.execute("INSERT INTO stock_movements (product_id, move_date, move_type, qty, ref_id, description) VALUES (?, ?, ?, ?, ?, ?)",
                                (x['prod_id'], today, 'RETURN', str(x['qty'] if self.is_sale else -x['qty']), ret_no, f"Return against #{inv_no}"))
                                
            # Ledger adjustment
            if party_id:
                if self.is_sale:
                    p_bal = self.db.fetch_val("SELECT current_balance FROM customers WHERE id=?", (party_id,))
                    new_bal = D(p_bal) - tot_refund
                    self.db.execute("UPDATE customers SET current_balance=? WHERE id=?", (str(new_bal), party_id))
                    self.db.execute("INSERT INTO customer_ledger (customer_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, 'RETURN', '0.00', ?, ?, ?, ?)",
                                    (party_id, today, str(tot_refund), str(new_bal), f"Return #{ret_no}", ret_no))
                else:
                    p_bal = self.db.fetch_val("SELECT current_balance FROM suppliers WHERE id=?", (party_id,))
                    new_bal = D(p_bal) - tot_refund
                    self.db.execute("UPDATE suppliers SET current_balance=? WHERE id=?", (str(new_bal), party_id))
                    self.db.execute("INSERT INTO supplier_ledger (supplier_id, trans_date, trans_type, debit, credit, running_balance, description, ref_id) VALUES (?, ?, 'RETURN', ?, '0.00', ?, ?, ?)",
                                    (party_id, today, str(tot_refund), str(new_bal), f"Return #{ret_no}", ret_no))

            if acc_id:
                a_bal = self.db.fetch_val("SELECT balance FROM cash_bank_accounts WHERE id=?", (acc_id,))
                new_a_bal = (D(a_bal) - tot_refund) if self.is_sale else (D(a_bal) + tot_refund)
                self.db.execute("UPDATE cash_bank_accounts SET balance=? WHERE id=?", (str(new_a_bal), acc_id))
                self.db.execute("INSERT INTO cash_bank_transactions (account_id, trans_date, trans_type, amount, description, ref_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
                                (acc_id, today, 'OUT' if self.is_sale else 'IN', str(tot_refund), f"Refund #{ret_no}", ret_no, uid))

        self.audit.log(f"PROCESS_{lbl.replace(' ','_')}", f"Return {ret_no} for {tot_refund}")
        print("\n [+] Return processed successfully!"); input(" Press [Enter]...")

# =====================================================================
# REPORTS ENGINE (25 PRODUCTION REPORTS)
# =====================================================================

class ReportManager:
    def __init__(self, db, auth):
        self.db = db; self.auth = auth

    def menu(self):
        while True:
            print_header("REPORTS & ANALYTICS MODULE")
            print(" 1. Sales Reports (Daily, Date-wise, Product-wise, Customer-wise)")
            print(" 2. Purchase Reports (Daily, Date-wise, Supplier-wise)")
            print(" 3. Financial Reports (Profit/Loss, Gross Margin, Expenses, Cash/Bank Books)")
            print(" 4. Party Khata Reports (Customer Receivables, Supplier Payables)")
            print(" 5. Inventory Reports (Stock Valuation, Low Stock, Dead Stock)")
            print(" 6. Return Reports (Sale Returns, Purchase Returns)")
            print(" 7. Tax & Discount Reports")
            print(" 8. System & Audit Reports (Audit Log, User Activity, Daily Closing)")
            print(" 0. Back to Main Menu")
            print("-" * 75)
            c = input(" Select Option Category: ").strip()
            if c == '1': self.cat_sales()
            elif c == '2': self.cat_purchases()
            elif c == '3': self.cat_financial()
            elif c == '4': self.cat_parties()
            elif c == '5': self.cat_inventory()
            elif c == '6': self.cat_returns()
            elif c == '7': self.cat_tax()
            elif c == '8': self.cat_system()
            elif c == '0': break

    def render_report(self, title, headers, rows):
        print_header(title)
        print(format_table(headers, rows))
        print("\n Options: [1] Export to CSV File  [0] Back")
        if input(" Select: ").strip() == '1':
            export_csv_file(title.replace(" ", "_"), headers, rows)

    def date_range(self):
        print("\n Enter Date Range Filter:")
        sd = input_date("Start Date", default_today=True)
        ed = input_date("End Date", default_today=True)
        return sd, ed

    def cat_sales(self):
        print_header("SALES REPORTS")
        print(" 1. Daily Sales Report (Today)")
        print(" 2. Date-wise Sales Report")
        print(" 3. Product-wise Sales Report")
        print(" 4. Customer-wise Sales Report")
        c = input(" Select Report: ").strip()
        curr = self.db.get_setting('currency', '$')
        today = datetime.date.today().isoformat()
        
        if c == '1':
            rows = self.db.fetch_all("SELECT SUBSTR(sale_date,11,6) as tm, invoice_no, grand_total, paid_amount FROM sales WHERE DATE(sale_date)=?", (today,))
            self.render_report("DAILY SALES REPORT (TODAY)", ["Time", "Invoice No", "Grand Total", "Paid"], [[r['tm'], r['invoice_no'], f"{curr}{D(r['grand_total'])}", f"{curr}{D(r['paid_amount'])}"] for r in rows])
        elif c == '2':
            sd, ed = self.date_range()
            rows = self.db.fetch_all("SELECT DATE(sale_date) as dt, COUNT(*) as cnt, SUM(grand_total) as tot FROM sales WHERE DATE(sale_date) BETWEEN ? AND ? GROUP BY DATE(sale_date)", (sd, ed))
            self.render_report(f"SALES REPORT ({sd} to {ed})", ["Date", "Invoices", "Total Sales"], [[r['dt'], r['cnt'], f"{curr}{D(r['tot'])}"] for r in rows])
        elif c == '3':
            rows = self.db.fetch_all("""SELECT p.code, p.name, SUM(si.qty) as q, SUM(si.total) as tot FROM sale_items si
                                        JOIN products p ON si.product_id=p.id GROUP BY p.id ORDER BY tot DESC""")
            self.render_report("PRODUCT-WISE SALES", ["SKU", "Product Name", "Total Qty Sold", "Total Revenue"], [[r['code'], r['name'][:25], D(r['q']), f"{curr}{D(r['tot'])}"] for r in rows])
        elif c == '4':
            rows = self.db.fetch_all("""SELECT c.name, COUNT(s.id) as cnt, SUM(s.grand_total) as tot FROM sales s
                                        JOIN customers c ON s.customer_id=c.id GROUP BY c.id ORDER BY tot DESC""")
            self.render_report("CUSTOMER-WISE SALES", ["Customer Name", "Invoices", "Total Billed"], [[r['name'][:25], r['cnt'], f"{curr}{D(r['tot'])}"] for r in rows])

    def cat_purchases(self):
        curr = self.db.get_setting('currency', '$')
        today = datetime.date.today().isoformat()
        print_header("PURCHASE REPORTS")
        print(" 1. Daily Purchase Report (Today)  |  2. Date-wise Purchases  |  3. Supplier-wise Purchases")
        c = input(" Select: ").strip()
        if c == '1':
            rows = self.db.fetch_all("SELECT invoice_no, grand_total FROM purchases WHERE purchase_date=?", (today,))
            self.render_report("DAILY PURCHASES (TODAY)", ["Invoice No", "Total Amount"], [[r['invoice_no'], f"{curr}{D(r['grand_total'])}"] for r in rows])
        elif c == '2':
            sd, ed = self.date_range()
            rows = self.db.fetch_all("SELECT purchase_date, COUNT(*), SUM(grand_total) FROM purchases WHERE purchase_date BETWEEN ? AND ? GROUP BY purchase_date", (sd, ed))
            self.render_report("DATE-WISE PURCHASES", ["Date", "Invoices", "Total Purchases"], [[r[0], r[1], f"{curr}{D(r[2])}"] for r in rows])
        elif c == '3':
            rows = self.db.fetch_all("SELECT s.name, COUNT(*), SUM(p.grand_total) FROM purchases p JOIN suppliers s ON p.supplier_id=s.id GROUP BY s.id")
            self.render_report("SUPPLIER-WISE PURCHASES", ["Supplier", "Invoices", "Total Volume"], [[r[0][:25], r[1], f"{curr}{D(r[2])}"] for r in rows])

    def cat_financial(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        curr = self.db.get_setting('currency', '$')
        print_header("FINANCIAL & ACCOUNTING REPORTS")
        print(" 1. Profit & Loss Statement (Net Profit)")
        print(" 2. Gross Profit / Product Margin Report")
        print(" 3. Itemized Expense Report")
        print(" 4. Cash Book Ledger")
        print(" 5. Bank Book Ledger")
        c = input(" Select Report: ").strip()
        
        if c == '1':
            sd, ed = self.date_range()
            rev = self.db.fetch_val("SELECT SUM(grand_total) FROM sales WHERE DATE(sale_date) BETWEEN ? AND ?", (sd, ed)) or 0
            cogs = self.db.fetch_val("SELECT SUM(si.cost_price * si.qty) FROM sale_items si JOIN sales s ON si.sale_id=s.id WHERE DATE(s.sale_date) BETWEEN ? AND ?", (sd, ed)) or 0
            exp = self.db.fetch_val("SELECT SUM(amount) FROM expenses WHERE exp_date BETWEEN ? AND ?", (sd, ed)) or 0
            gp = D(rev) - D(cogs)
            np = gp - D(exp)
            data = [
                ["Total Sales Revenue", f"{curr}{D(rev)}"],
                ["Cost of Goods Sold (COGS)", f"-{curr}{D(cogs)}"],
                ["Gross Profit Margin", f"{curr}{gp}"],
                ["Total Operating Expenses", f"-{curr}{D(exp)}"],
                ["NET PROFIT ESTIMATE", f"{curr}{np}"]
            ]
            self.render_report(f"PROFIT & LOSS ({sd} to {ed})", ["Financial Metric", "Amount"], data)
        elif c == '2':
            rows = self.db.fetch_all("""SELECT p.name, SUM(si.qty) as q, SUM(si.total) as rev, SUM(si.cost_price*si.qty) as cst
                                        FROM sale_items si JOIN products p ON si.product_id=p.id GROUP BY p.id""")
            t_data = [[r['name'][:22], D(r['q']), f"{curr}{D(r['rev'])}", f"{curr}{D(r['cst'])}", f"{curr}{D(r['rev'])-D(r['cst'])}"] for r in rows]
            self.render_report("GROSS PROFIT BY PRODUCT", ["Product", "Qty Sold", "Revenue", "COGS", "Gross Margin"], t_data)
        elif c == '3':
            rows = self.db.fetch_all("SELECT e.exp_date, ec.name, e.description, e.amount FROM expenses e JOIN expense_categories ec ON e.category_id=ec.id ORDER BY e.exp_date DESC")
            self.render_report("EXPENSE REPORT", ["Date", "Category", "Description", "Amount"], [[r[0], r[1], r[2][:25], f"{curr}{D(r[3])}"] for r in rows])
        elif c in ('4', '5'):
            acc_type = 'CASH' if c=='4' else 'BANK'
            rows = self.db.fetch_all("""SELECT t.trans_date, a.name, t.trans_type, t.amount, t.description FROM cash_bank_transactions t
                                        JOIN cash_bank_accounts a ON t.account_id=a.id WHERE a.type=? ORDER BY t.id DESC LIMIT 100""", (acc_type,))
            self.render_report(f"{acc_type} BOOK LEDGER", ["Date", "Account", "Type", "Amount", "Description"], [[r[0], r[1], r[2], f"{curr}{D(r[3])}", r[4][:25]] for r in rows])

    def cat_parties(self):
        curr = self.db.get_setting('currency', '$')
        print_header("PARTY OUTSTANDING BALANCES")
        print(" 1. Customer Receivables (+ Balance owed to us)")
        print(" 2. Supplier Payables (+ Balance we owe)")
        c = input(" Select: ").strip()
        tbl = 'customers' if c=='1' else 'suppliers'
        rows = self.db.fetch_all(f"SELECT code, name, phone, current_balance FROM {tbl} WHERE CAST(current_balance AS REAL) != 0 ORDER BY name")
        self.render_report(f"{tbl.upper()} OUTSTANDING", ["Code", "Name", "Phone", "Outstanding Balance"], [[r[0], r[1][:25], r[2], f"{curr}{D(r[3])}"] for r in rows])

    def cat_inventory(self):
        curr = self.db.get_setting('currency', '$')
        print_header("INVENTORY & STOCK REPORTS")
        print(" 1. Full Inventory Stock Valuation Report")
        print(" 2. Low Stock Warning Report")
        print(" 3. Out of Stock Report")
        print(" 4. Dead / Slow Moving Stock Report")
        c = input(" Select: ").strip()
        if c == '1':
            rows = self.db.fetch_all("SELECT code, name, current_stock, purchase_price, sale_price FROM products WHERE is_active=1")
            t_data = [[r[0], r[1][:22], D(r[2]), f"{curr}{D(r[2])*D(r[3])}", f"{curr}{D(r[2])*D(r[4])}"] for r in rows]
            self.render_report("STOCK VALUATION REPORT", ["SKU", "Product Name", "Stock Qty", "Cost Value", "Retail Value"], t_data)
        elif c == '2':
            lvl = self.db.get_setting('low_stock_warn', '10')
            rows = self.db.fetch_all("SELECT code, name, current_stock, min_stock FROM products WHERE CAST(current_stock AS REAL) <= CAST(min_stock AS REAL) AND is_active=1")
            self.render_report("LOW STOCK WARNINGS", ["SKU", "Product Name", "Current Stock", "Min Level"], [[r[0], r[1][:25], D(r[2]), D(r[3])] for r in rows])
        elif c == '3':
            rows = self.db.fetch_all("SELECT code, name FROM products WHERE CAST(current_stock AS REAL) <= 0 AND is_active=1")
            self.render_report("OUT OF STOCK ITEMS", ["SKU", "Product Name"], [[r[0], r[1]] for r in rows])
        elif c == '4':
            thirty_ago = (datetime.date.today() - datetime.timedelta(days=30)).isoformat()
            rows = self.db.fetch_all("""SELECT p.code, p.name, p.current_stock FROM products p
                                        WHERE p.is_active=1 AND p.id NOT IN (
                                            SELECT DISTINCT product_id FROM sale_items si JOIN sales s ON si.sale_id=s.id WHERE DATE(s.sale_date) >= ?
                                        )""", (thirty_ago,))
            self.render_report("DEAD STOCK (No sales in 30 days)", ["SKU", "Product Name", "Current Stock"], [[r[0], r[1], D(r[2])] for r in rows])

    def cat_returns(self):
        curr = self.db.get_setting('currency', '$')
        print_header("RETURN REPORTS")
        print(" 1. Sale Returns Report  |  2. Purchase Returns Report")
        c = input(" Select: ").strip()
        tbl = 'sale_returns' if c=='1' else 'purchase_returns'
        rows = self.db.fetch_all(f"SELECT return_date, return_no, total_amount, reason FROM {tbl} ORDER BY id DESC")
        self.render_report(f"{tbl.upper()} HISTORY", ["Date", "Return No", "Total Refund", "Reason"], [[r[0], r[1], f"{curr}{D(r[2])}", r[3]] for r in rows])

    def cat_tax(self):
        curr = self.db.get_setting('currency', '$')
        sd, ed = self.date_range()
        stax = self.db.fetch_val("SELECT SUM(total_tax) FROM sales WHERE DATE(sale_date) BETWEEN ? AND ?", (sd, ed)) or 0
        ptax = self.db.fetch_val("SELECT SUM(tax) FROM purchases WHERE purchase_date BETWEEN ? AND ?", (sd, ed)) or 0
        sdisc = self.db.fetch_val("SELECT SUM(overall_discount) FROM sales WHERE DATE(sale_date) BETWEEN ? AND ?", (sd, ed)) or 0
        self.render_report(f"TAX & DISCOUNT SUMMARY ({sd} to {ed})", ["Category Type", "Amount"], [
            ["Sales Tax Collected", f"{curr}{D(stax)}"],
            ["Purchase Tax Paid", f"{curr}{D(ptax)}"],
            ["Net Tax Payable Estimate", f"{curr}{D(stax)-D(ptax)}"],
            ["Total Sales Discounts Given", f"{curr}{D(sdisc)}"]
        ])

    def cat_system(self):
        if not self.auth.require_role(['Admin']): return
        print_header("SYSTEM & CLOSING REPORTS")
        print(" 1. Audit Logs Report  |  2. User Activity Report  |  3. Daily Closing Financial Sheet")
        c = input(" Select: ").strip()
        curr = self.db.get_setting('currency', '$')
        
        if c == '1':
            rows = self.db.fetch_all("SELECT a.timestamp, u.username, action, details FROM audit_logs a LEFT JOIN users u ON a.user_id=u.id ORDER BY a.id DESC LIMIT 100")
            self.render_report("AUDIT LOGS (Latest 100)", ["Timestamp", "User", "Action", "Details"], [[r[0][:16], r[1], r[2], r[3][:35]] for r in rows])
        elif c == '2':
            rows = self.db.fetch_all("SELECT u.username, u.role, COUNT(a.id), MAX(a.timestamp) FROM users u LEFT JOIN audit_logs a ON u.id=a.user_id GROUP BY u.id")
            self.render_report("USER ACTIVITY LOG", ["Username", "Role", "Action Count", "Last Active"], [[r[0], r[1], r[2], r[3][:16] if r[3] else "Never"] for r in rows])
        elif c == '3':
            today = datetime.date.today().isoformat()
            s_cash = self.db.fetch_val("SELECT SUM(paid_amount) FROM sales WHERE DATE(sale_date)=?", (today,)) or 0
            p_rec = self.db.fetch_val("SELECT SUM(amount) FROM cash_bank_transactions WHERE trans_type='IN' AND DATE(trans_date)=? AND ref_id LIKE 'PTY_%'", (today,)) or 0
            exp = self.db.fetch_val("SELECT SUM(amount) FROM expenses WHERE exp_date=?", (today,)) or 0
            c_hand = self.db.fetch_val("SELECT balance FROM cash_bank_accounts WHERE type='CASH' AND is_active=1") or 0
            self.render_report(f"DAILY CLOSING SHEET ({today})", ["Flow Component", "Amount"], [
                ["Today Sales Cash Collected", f"{curr}{D(s_cash)}"],
                ["Today Customer Khata Payments", f"{curr}{D(p_rec)}"],
                ["Today Expenses Paid Out", f"-{curr}{D(exp)}"],
                ["CURRENT CASH IN HAND BALANCE", f"{curr}{D(c_hand)}"]
            ])

# =====================================================================
# BACKUP / RESTORE & IMPORT / EXPORT
# =====================================================================

class BackupManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin']): return
        while True:
            print_header("DATABASE BACKUP & RESTORE")
            print(f" Backup Folder: {Path(self.db.get_setting('backup_path','./backups')).resolve()}")
            print("-" * 75)
            print(" 1. Create Manual Backup Now")
            print(" 2. Restore Database From Backup File")
            print(" 0. Back")
            c = input(" Select: ").strip()
            if c == '1': self.backup()
            elif c == '2': self.restore()
            elif c == '0': break

    def backup(self, auto=False):
        bdir = Path(self.db.get_setting('backup_path', './backups'))
        bdir.mkdir(parents=True, exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        dest = bdir / f"shop_manager_{ts}.db"
        try:
            shutil.copy2(self.db.db_path, dest)
            self.audit.log("BACKUP", f"Created backup {dest.name}")
            if not auto: print(f"\n [+] Backup created successfully: {dest.name}"); input(" Press [Enter]...")
        except Exception as e:
            if not auto: print(f"\n [!] Backup failed: {e}"); input(" Press [Enter]...")

    def restore(self):
        bdir = Path(self.db.get_setting('backup_path', './backups'))
        if not bdir.exists(): print(" [!] No backups folder found."); input(" Press [Enter]..."); return
        files = sorted(bdir.glob("shop_manager_*.db"), reverse=True)
        if not files: print(" [!] No backup files available."); input(" Press [Enter]..."); return
        
        print("\n Available Backups:")
        for idx, f in enumerate(files[:15]):
            print(f"  [{idx+1}] {f.name} ({datetime.datetime.fromtimestamp(f.stat().st_mtime).strftime('%Y-%m-%d %H:%M:%S')})")
        sel = input_int("Select Backup Number to Restore (0 to cancel)", required=True)
        if sel == 0 or sel > len(files): return
        
        target = files[sel-1]
        print(f"\n [!] WARNING: This will completely replace current database with {target.name}!")
        if input(" Type 'RESTORE' to confirm: ").strip() != 'RESTORE': return
        
        self.db.conn.close()
        try:
            shutil.copy2(target, self.db.db_path)
            print("\n [+] Database restored successfully! Please restart application.")
            sys.exit(0)
        except Exception as e:
            print(f"\n [!] Restore failed critically: {e}")
            sys.exit(1)

class IOManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("DATA IMPORT & EXPORT (CSV)")
            print(" 1. Export Products Master CSV")
            print(" 2. Export Customers Master CSV")
            print(" 3. Export Suppliers Master CSV")
            print(" 4. Import Products from CSV File")
            print(" 5. Import Customers from CSV File")
            print(" 6. Import Suppliers from CSV File")
            print(" 0. Back")
            c = input(" Select Option: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT code, barcode, name, purchase_price, sale_price, current_stock FROM products WHERE is_active=1")
                export_csv_file("Products_Export", ["SKU", "Barcode", "Name", "PurPrice", "SalePrice", "Stock"], [[r[0],r[1],r[2],D(r[3]),D(r[4]),D(r[5])] for r in rows])
            elif c == '2':
                rows = self.db.fetch_all("SELECT code, name, phone, address, current_balance FROM customers WHERE is_active=1")
                export_csv_file("Customers_Export", ["Code", "Name", "Phone", "Address", "Balance"], [[r[0],r[1],r[2],r[3],D(r[4])] for r in rows])
            elif c == '3':
                rows = self.db.fetch_all("SELECT code, name, phone, address, current_balance FROM suppliers WHERE is_active=1")
                export_csv_file("Suppliers_Export", ["Code", "Name", "Phone", "Address", "Balance"], [[r[0],r[1],r[2],r[3],D(r[4])] for r in rows])
            elif c in ('4','5','6'):
                self.import_csv('products' if c=='4' else 'customers' if c=='5' else 'suppliers')
            elif c == '0': break

    def import_csv(self, target_tbl):
        fname = input_str("Enter CSV exact filename/path to import")
        p = Path(fname)
        if not p.exists(): print(" [!] File not found."); input(" Press [Enter]..."); return
        
        now = datetime.datetime.now().isoformat()
        count = 0
        try:
            with open(p, mode='r', encoding='utf-8') as f:
                reader = csv.reader(f)
                header = next(reader) # skip header
                with self.db.conn:
                    for row in reader:
                        if not row or not row[0]: continue
                        if target_tbl == 'products':
                            # code, barcode, name, pur, sale, stk
                            self.db.execute("""INSERT OR IGNORE INTO products (code, barcode, name, category_id, brand_id, unit_id, purchase_price, sale_price, current_stock, is_active, created_at, updated_at)
                                               VALUES (?, ?, ?, 1, 1, 1, ?, ?, ?, 1, ?, ?)""",
                                            (row[0], row[1] if len(row)>1 else "", row[2] if len(row)>2 else "Unnamed", str(D(row[3] if len(row)>3 else 0)), str(D(row[4] if len(row)>4 else 0)), str(D(row[5] if len(row)>5 else 0)), now, now))
                        elif target_tbl in ('customers', 'suppliers'):
                            # code, name, phone, addr
                            self.db.execute(f"""INSERT OR IGNORE INTO {target_tbl} (code, name, phone, address, is_active, created_at)
                                                VALUES (?, ?, ?, ?, 1, ?)""",
                                            (row[0], row[1] if len(row)>1 else "Unnamed", row[2] if len(row)>2 else "", row[3] if len(row)>3 else "", now))
                        count += 1
            self.audit.log(f"IMPORT_{target_tbl.upper()}", f"Imported {count} rows from {p.name}")
            print(f"\n [+] Successfully imported {count} records!"); input(" Press [Enter]...")
        except Exception as e:
            print(f"\n [!] CSV Import aborted due to format error: {e}"); input(" Press [Enter]...")

# =====================================================================
# WAREHOUSE MANAGEMENT
# =====================================================================

class WarehouseManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("WAREHOUSE MANAGEMENT")
            print(" 1. View All Warehouses\n 2. Add\n 3. Edit\n 4. View Stock\n 5. Transfer Stock\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, name, location, is_active FROM warehouses")
                print(format_table(["ID","Name","Location","Active"],[(r[0],r[1],r[2] or "","Yes" if r[3] else "No") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                name = input_str("Warehouse Name"); loc = input_str("Location", required=False)
                try: self.db.execute("INSERT INTO warehouses (name, location) VALUES (?,?)", (name, loc)); self.audit.log("ADD_WAREHOUSE", f"Created {name}"); print(" [+] Added!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                wid = input_int("Warehouse ID to edit")
                w = self.db.fetch_one("SELECT * FROM warehouses WHERE id=?", (wid,))
                if not w: print(" [!] Not found"); input(" Press [Enter]..."); continue
                nm = input_str("Name", default=w['name']); loc = input_str("Location", required=False, default=w['location'] or "")
                self.db.execute("UPDATE warehouses SET name=?, location=? WHERE id=?", (nm, loc, wid))
                self.audit.log("EDIT_WAREHOUSE", f"Updated {wid}"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '4':
                wid = input_int("Warehouse ID (0=all)")
                if wid > 0:
                    wh = self.db.fetch_one("SELECT name FROM warehouses WHERE id=?", (wid,))
                    rows = self.db.fetch_all("SELECT p.code, p.name, COALESCE(ws.qty,0) FROM products p LEFT JOIN warehouse_stock ws ON ws.product_id=p.id AND ws.warehouse_id=? WHERE p.is_active=1 ORDER BY p.name", (wid,))
                    h = f"Stock in: {wh['name'] if wh else 'Unknown'}"
                else:
                    rows = self.db.fetch_all("SELECT w.name, p.code, p.name, COALESCE(ws.qty,0) FROM warehouse_stock ws JOIN warehouses w ON w.id=ws.warehouse_id JOIN products p ON p.id=ws.product_id ORDER BY w.name, p.name")
                    h = "All Warehouse Stock"
                print_header(h)
                print(format_table(["Warehouse","Code","Product","Qty"],[(r[0],r[1],r[2],D(r[3])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '5':
                rows = self.db.fetch_all("SELECT id, name FROM warehouses WHERE is_active=1")
                if len(rows) < 2: print(" [!] Need 2+ warehouses"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in rows]))
                f = input_int("From WH ID"); t = input_int("To WH ID")
                if f == t: print(" [!] Must differ"); input(" Press [Enter]..."); continue
                pcode = input_str("Product Code"); p = self.db.fetch_one("SELECT id, name, current_stock FROM products WHERE code=? AND is_active=1", (pcode,))
                if not p: print(" [!] Product not found"); input(" Press [Enter]..."); continue
                fs = self.db.fetch_val("SELECT qty FROM warehouse_stock WHERE warehouse_id=? AND product_id=?", (f, p[0])) or 0
                print(f" Source stock: {D(fs)}")
                qty = float(input_dec("Qty to transfer"))
                if qty <= 0 or qty > float(fs): print(" [!] Insufficient"); input(" Press [Enter]..."); continue
                with self.db.conn:
                    self.db.execute("INSERT INTO warehouse_stock (warehouse_id, product_id, qty) VALUES (?,?,?) ON CONFLICT(warehouse_id,product_id) DO UPDATE SET qty=CAST(CAST(qty AS REAL)-? AS TEXT)", (f, p[0], str(-qty), str(qty)))
                    self.db.execute("INSERT INTO warehouse_stock (warehouse_id, product_id, qty) VALUES (?,?,?) ON CONFLICT(warehouse_id,product_id) DO UPDATE SET qty=CAST(CAST(qty AS REAL)+? AS TEXT)", (t, p[0], str(qty), str(qty)))
                    self.db.execute("INSERT INTO stock_movements (product_id, qty, movement_type, ref_id, notes, created_at) VALUES (?,?,'TRANSFER',?,?,?)", (p[0], str(-qty), f"WH{f}->WH{t}", f"Transferred {qty} units", datetime.datetime.now().isoformat()))
                self.audit.log("STOCK_TRANSFER", f"{qty} x {p[1]} WH{f}->WH{t}"); print(" [+] Done!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# QUOTATION MANAGEMENT
# =====================================================================

class QuotationManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager', 'Cashier']): return
        while True:
            print_header("QUOTATIONS")
            print(" 1. View All\n 2. Create\n 3. Details\n 4. Convert to Sale\n 5. Cancel\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT q.quote_no, c.name, q.quote_date, q.grand_total, q.status FROM quotations q LEFT JOIN customers c ON c.id=q.customer_id ORDER BY q.id DESC")
                print(format_table(["Quote#","Customer","Date","Total","Status"],[(r[0],r[1] or "Walk-in",r[2][:10] if r[2] else "",D(r[3]),r[4]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                custs = self.db.fetch_all("SELECT id, code, name FROM customers WHERE is_active=1")
                print(format_table(["ID","Code","Name"],[(r[0],r[1],r[2]) for r in custs]))
                cid = input_int("Customer ID (0=Walk-in)")
                qno = "Q-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
                items = []; curr = self.db.get_setting('currency','$')
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name, sale_price FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    qty = float(input_dec(f"Qty for {p[1]}")); price = float(input_dec("Price", default=str(p[2])))
                    disc = float(input_dec("Disc %", required=False)); tax = float(input_dec("Tax %", required=False))
                    total = qty * price * (1 - disc/100) * (1 + tax/100); items.append((p[0], qty, price, disc, tax, total))
                    print(f" [+] {p[1]} x {qty} = {curr}{total:.2f}")
                if not items: continue
                subt = sum(i[5] for i in items); gdisc = float(input_dec("Global Disc %", required=False)); gtax = float(input_dec("Global Tax %", required=False))
                grand = subt * (1 - gdisc/100) * (1 + gtax/100); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                valid = input_str("Valid Until", required=False, default=(datetime.date.today()+datetime.timedelta(days=15)).isoformat())
                with self.db.conn:
                    self.db.execute("INSERT INTO quotations (quote_no, customer_id, quote_date, valid_until, subtotal, discount, tax, grand_total, status, notes, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,'ACTIVE',?,?,?)", (qno, cid or None, dt, valid, str(subt), str(gdisc), str(gtax), str(grand), notes, self.auth.current_user['id'], now))
                    qid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in items: self.db.execute("INSERT INTO quotation_items (quotation_id, product_id, qty, price, discount, tax, total) VALUES (?,?,?,?,?,?,?)", (qid, it[0], str(it[1]), str(it[2]), str(it[3]), str(it[4]), str(it[5])))
                self.audit.log("CREATE_QUOTE", f"Quote {qno}"); print(f"\n [+] Quote {qno} created!"); input(" Press [Enter]...")
            elif c == '3':
                qno = input_str("Quote Number")
                q = self.db.fetch_one("SELECT q.*, c.name AS cname FROM quotations q LEFT JOIN customers c ON c.id=q.customer_id WHERE q.quote_no=?", (qno,))
                if not q: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Quotation: {q['quote_no']} [{q['status']}]")
                print(f" Customer: {q['cname'] or 'Walk-in'} | Date: {q['quote_date']} | Valid: {q['valid_until']}")
                its = self.db.fetch_all("SELECT p.code, p.name, qi.qty, qi.price, qi.total FROM quotation_items qi JOIN products p ON p.id=qi.product_id WHERE qi.quotation_id=?", (q['id'],))
                print(format_table(["Code","Product","Qty","Price","Total"],[(r[0],r[1],D(r[2]),D(r[3]),D(r[4])) for r in its]))
                print(f" Sub: {D(q['subtotal'])} | Disc: {D(q['discount'])}% | Tax: {D(q['tax'])}% | Grand: {D(q['grand_total'])}")
                if q['notes']: print(f" Notes: {q['notes']}"); input(" Press [Enter]...")
            elif c == '4':
                qno = input_str("Quote to Convert")
                q = self.db.fetch_one("SELECT * FROM quotations WHERE quote_no=? AND status='ACTIVE'", (qno,))
                if not q: print(" [!] Not found/active"); input(" Press [Enter]..."); continue
                inv = "INV-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                with self.db.conn:
                    self.db.execute("""INSERT INTO sales (invoice_no, customer_id, customer_type, sale_date, subtotal, overall_discount, total_tax, grand_total, paid_amount, balance_amount, payment_method, account_id, created_by, created_at)
                                         VALUES (?, ?,'Customer', ?, ?, ?, ?, ?, '0.00', ?, '', ?, ?, ?)""",
                                   (inv, q['customer_id'], dt, q['subtotal'], q['discount'] or '0', q['tax'] or '0', q['grand_total'], q['grand_total'], self.auth.current_user['id'], now))
                    sid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    its = self.db.fetch_all("SELECT * FROM quotation_items WHERE quotation_id=?", (q['id'],))
                    for it in its:
                        p = self.db.fetch_one("SELECT id, purchase_price FROM products WHERE id=?", (it['product_id'],))
                        self.db.execute("INSERT INTO sale_items (sale_id, product_id, qty, price, discount, tax, total, cost_price) VALUES (?,?,?,?,?,?,?,?)", (sid, it['product_id'], it['qty'], it['price'], it['discount'], it['tax'], it['total'], p[1] if p else 0))
                        self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)-? AS TEXT) WHERE id=?", (str(it['qty']), it['product_id']))
                    self.db.execute("UPDATE quotations SET status='CONVERTED' WHERE id=?", (q['id'],))
                self.audit.log("QUOTE_TO_SALE", f"{qno} -> {inv}"); print(f" [+] Converted to {inv}!"); input(" Press [Enter]...")
            elif c == '5':
                qno = input_str("Quote to Cancel")
                self.db.execute("UPDATE quotations SET status='CANCELLED' WHERE quote_no=?", (qno,))
                self.audit.log("CANCEL_QUOTE", f"Cancelled {qno}"); print(" [+] Cancelled!"); input(" Press [Enter]...")
            elif c == '0': break


# =====================================================================
# USERS & SETTINGS CONTROLLERS
# =====================================================================

class SalesOrderManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager', 'Cashier']): return
        while True:
            print_header("SALES ORDERS")
            print(" 1. View All\n 2. Create\n 3. Details\n 4. Mark Delivered\n 5. Cancel\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT s.order_no, c.name, s.order_date, s.grand_total, s.paid_amount, s.status FROM sales_orders s LEFT JOIN customers c ON c.id=s.customer_id ORDER BY s.id DESC")
                print(format_table(["Order#","Customer","Date","Total","Paid","Status"],[(r[0],r[1] or "Walk-in",r[2][:10] if r[2] else "",D(r[3]),D(r[4]),r[5]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                custs = self.db.fetch_all("SELECT id, code, name FROM customers WHERE is_active=1")
                print(format_table(["ID","Code","Name"],[(r[0],r[1],r[2]) for r in custs]))
                cid = input_int("Customer ID (0=Walk-in)")
                ono = "SO-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); items = []; curr = self.db.get_setting("currency","$")
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name, sale_price FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    qty = float(input_dec(f"Qty for {p[1]}")); price = float(input_dec("Price", default=str(p[2])))
                    disc = float(input_dec("Disc %", required=False)); tax = float(input_dec("Tax %", required=False))
                    total = qty * price * (1 - disc/100) * (1 + tax/100); items.append((p[0], qty, price, disc, tax, total))
                    print(f" [+] {p[1]} x {qty} = {curr}{total:.2f}")
                if not items: continue
                subt = sum(i[5] for i in items); gdisc = float(input_dec("Global Disc %", required=False)); gtax = float(input_dec("Global Tax %", required=False))
                grand = subt * (1 - gdisc/100) * (1 + gtax/100); paid = float(input_dec("Advance Payment", required=False)); notes = input_str("Notes", required=False)
                dd = input_str("Delivery Date", required=False); now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                with self.db.conn:
                    self.db.execute("INSERT INTO sales_orders (order_no, customer_id, order_date, delivery_date, subtotal, discount, tax, grand_total, paid_amount, status, notes, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,?,'PENDING',?,?,?)", (ono, cid or None, dt, dd or None, str(subt), str(gdisc), str(gtax), str(grand), str(paid), notes, self.auth.current_user['id'], now))
                    oid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in items: self.db.execute("INSERT INTO sales_order_items (order_id, product_id, qty, price, discount, tax, total) VALUES (?,?,?,?,?,?,?)", (oid, it[0], str(it[1]), str(it[2]), str(it[3]), str(it[4]), str(it[5])))
                self.audit.log("CREATE_SALES_ORDER", f"SO {ono}"); print(f"\n [+] SO {ono} created!"); input(" Press [Enter]...")
            elif c == '3':
                ono = input_str("Order Number")
                o = self.db.fetch_one("SELECT s.*, c.name AS cname FROM sales_orders s LEFT JOIN customers c ON c.id=s.customer_id WHERE s.order_no=?", (ono,))
                if not o: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Sales Order: {o['order_no']} [{o['status']}]")
                print(f" Customer: {o['cname'] or 'Walk-in'} | Date: {o['order_date']} | Delivery: {o['delivery_date'] or 'N/A'}")
                its = self.db.fetch_all("SELECT p.code, p.name, oi.qty, oi.price, oi.total, oi.delivered_qty FROM sales_order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=?", (o['id'],))
                print(format_table(["Code","Product","Qty","Price","Total","Delivered"],[(r[0],r[1],D(r[2]),D(r[3]),D(r[4]),D(r[5])) for r in its]))
                print(f" Sub: {D(o['subtotal'])} | Disc: {D(o['discount'])}% | Tax: {D(o['tax'])}% | Grand: {D(o['grand_total'])} | Paid: {D(o['paid_amount'])}")
                if o['notes']: print(f" Notes: {o['notes']}"); input(" Press [Enter]...")
            elif c == '4':
                ono = input_str("Order to mark Delivered")
                o = self.db.fetch_one("SELECT * FROM sales_orders WHERE order_no=? AND status='PENDING'", (ono,))
                if not o: print(" [!] Not found/pending"); input(" Press [Enter]..."); continue
                its = self.db.fetch_all("SELECT oi.id, p.code, p.name, oi.qty, oi.delivered_qty FROM sales_order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.order_id=?", (o['id'],))
                print(format_table(["#","Code","Product","Qty","Delivered"],[(r[0],r[1],r[2],D(r[3]),D(r[4])) for r in its]))
                with self.db.conn:
                    for it in its:
                        dq = float(input_dec(f"Deliver qty for {it[2]} (max {float(it[3])-float(it[4]):.2f})"))
                        if dq > 0: nd = float(it[4]) + dq; self.db.execute("UPDATE sales_order_items SET delivered_qty=? WHERE id=?", (str(nd), it[0])); self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)-? AS TEXT) WHERE id=?", (str(dq), it[1]))
                    self.db.execute("UPDATE sales_orders SET status='DELIVERED' WHERE id=?", (o['id'],))
                self.audit.log("DELIVER_SO", f"Delivered {ono}"); print(" [+] Delivered!"); input(" Press [Enter]...")
            elif c == '5':
                ono = input_str("Order to Cancel")
                self.db.execute("UPDATE sales_orders SET status='CANCELLED' WHERE order_no=?", (ono,))
                self.audit.log("CANCEL_SO", f"Cancelled {ono}"); print(" [+] Cancelled!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# PURCHASE ORDER MANAGEMENT
# =====================================================================
class PurchaseOrderManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("PURCHASE ORDERS")
            print(" 1. View All\n 2. Create PO\n 3. Details\n 4. Receive Stock\n 5. Cancel\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT p.po_no, s.name, p.order_date, p.grand_total, p.status FROM purchase_orders p LEFT JOIN suppliers s ON s.id=p.supplier_id ORDER BY p.id DESC")
                print(format_table(["PO#","Supplier","Date","Total","Status"],[(r[0],r[1] or "N/A",r[2][:10] if r[2] else "",D(r[3]),r[4]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                supps = self.db.fetch_all("SELECT id, code, name FROM suppliers WHERE is_active=1")
                print(format_table(["ID","Code","Name"],[(r[0],r[1],r[2]) for r in supps]))
                sid = input_int("Supplier ID")
                po = "PO-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); items = []; curr = self.db.get_setting("currency","$")
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name, purchase_price FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    qty = float(input_dec(f"Qty for {p[1]}")); price = float(input_dec("Price", default=str(p[2])))
                    disc = float(input_dec("Disc %", required=False)); tax = float(input_dec("Tax %", required=False))
                    total = qty * price * (1 - disc/100) * (1 + tax/100); items.append((p[0], qty, price, disc, tax, total))
                    print(f" [+] {p[1]} x {qty} = {curr}{total:.2f}")
                if not items: continue
                subt = sum(i[5] for i in items); gdisc = float(input_dec("Global Disc %", required=False)); gtax = float(input_dec("Global Tax %", required=False))
                grand = subt * (1 - gdisc/100) * (1 + gtax/100); notes = input_str("Notes", required=False)
                ed = input_str("Expected Date", required=False); now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                with self.db.conn:
                    self.db.execute("INSERT INTO purchase_orders (po_no, supplier_id, order_date, expected_date, subtotal, discount, tax, grand_total, status, notes, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,'PENDING',?,?,?)", (po, sid, dt, ed or None, str(subt), str(gdisc), str(gtax), str(grand), notes, self.auth.current_user['id'], now))
                    poid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in items: self.db.execute("INSERT INTO purchase_order_items (po_id, product_id, qty, price, discount, tax, total) VALUES (?,?,?,?,?,?,?)", (poid, it[0], str(it[1]), str(it[2]), str(it[3]), str(it[4]), str(it[5])))
                self.audit.log("CREATE_PO", f"PO {po}"); print(f"\n [+] PO {po} created!"); input(" Press [Enter]...")
            elif c == '3':
                pn = input_str("PO Number")
                o = self.db.fetch_one("SELECT p.*, s.name AS sname FROM purchase_orders p LEFT JOIN suppliers s ON s.id=p.supplier_id WHERE p.po_no=?", (pn,))
                if not o: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Purchase Order: {o['po_no']} [{o['status']}]")
                print(f" Supplier: {o['sname']} | Date: {o['order_date']} | Expected: {o['expected_date'] or 'N/A'}")
                its = self.db.fetch_all("SELECT p.code, p.name, oi.qty, oi.price, oi.total, oi.received_qty FROM purchase_order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.po_id=?", (o['id'],))
                print(format_table(["Code","Product","Qty","Price","Total","Received"],[(r[0],r[1],D(r[2]),D(r[3]),D(r[4]),D(r[5])) for r in its]))
                print(f" Sub: {D(o['subtotal'])} | Disc: {D(o['discount'])}% | Tax: {D(o['tax'])}% | Grand: {D(o['grand_total'])}")
                if o['notes']: print(f" Notes: {o['notes']}"); input(" Press [Enter]...")
            elif c == '4':
                pn = input_str("PO to Receive")
                o = self.db.fetch_one("SELECT * FROM purchase_orders WHERE po_no=? AND status='PENDING'", (pn,))
                if not o: print(" [!] Not found/pending"); input(" Press [Enter]..."); continue
                its = self.db.fetch_all("SELECT oi.id, p.code, p.name, oi.qty, oi.price, oi.received_qty FROM purchase_order_items oi JOIN products p ON p.id=oi.product_id WHERE oi.po_id=?", (o['id'],))
                print(format_table(["#","Code","Product","Ordered","Price","Received"],[(r[0],r[1],r[2],D(r[3]),D(r[4]),D(r[5])) for r in its]))
                with self.db.conn:
                    for it in its:
                        rq = float(input_dec(f"Receive qty for {it[2]} (max {float(it[3])-float(it[5]):.2f})"))
                        if rq > 0:
                            nr = float(it[5]) + rq; self.db.execute("UPDATE purchase_order_items SET received_qty=? WHERE id=?", (str(nr), it[0]))
                            self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)+? AS TEXT) WHERE id=?", (str(rq), it[1]))
                            self.db.execute("INSERT INTO stock_movements (product_id, qty, movement_type, ref_id, notes, created_at) VALUES (?,?,'PURCHASE',?,?,?)", (it[1], str(rq), pn, f"Received vs {pn}", datetime.datetime.now().isoformat()))
                    self.db.execute("UPDATE purchase_orders SET status='RECEIVED' WHERE id=?", (o['id'],))
                self.audit.log("RECEIVE_PO", f"Received {pn}"); print(" [+] Received!"); input(" Press [Enter]...")
            elif c == '5':
                pn = input_str("PO to Cancel")
                self.db.execute("UPDATE purchase_orders SET status='CANCELLED' WHERE po_no=?", (pn,))
                self.audit.log("CANCEL_PO", f"Cancelled {pn}"); print(" [+] Cancelled!"); input(" Press [Enter]...")
            elif c == '0': break


# =====================================================================
# DELIVERY CHALLAN MANAGEMENT
# =====================================================================
class DeliveryChallanManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("DELIVERY CHALLANS")
            print(" 1. View All\n 2. Create\n 3. From Sales Order\n 4. Details\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT d.challan_no, c.name, d.challan_date, d.vehicle_no FROM delivery_challans d LEFT JOIN customers c ON c.id=d.customer_id ORDER BY d.id DESC")
                print(format_table(["Challan#","Customer","Date","Vehicle"],[(r[0],r[1] or "",r[2][:10] if r[2] else "",r[3] or "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                custs = self.db.fetch_all("SELECT id, code, name FROM customers WHERE is_active=1")
                print(format_table(["ID","Code","Name"],[(r[0],r[1],r[2]) for r in custs]))
                cid = input_int("Customer ID (0=Walk-in)")

                cno = "DC-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
                dt = datetime.date.today().isoformat(); vno = input_str("Vehicle No", required=False); drv = input_str("Driver", required=False); dph = input_str("Driver Phone", required=False); notes = input_str("Notes", required=False)
                items = []
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name FROM products WHERE code=? AND is_active=1", (sku,))
                    if not p: print(" [!] Not found"); continue
                    qty = float(input_dec(f"Qty for {p[1]}")); desc = input_str("Description", required=False)
                    items.append((p[0], qty, desc))
                if not items: continue
                now = datetime.datetime.now().isoformat()
                with self.db.conn:
                    self.db.execute("INSERT INTO delivery_challans (challan_no, customer_id, challan_date, vehicle_no, driver_name, driver_phone, notes, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,?)", (cno, cid or None, dt, vno or None, drv or None, dph or None, notes, self.auth.current_user["id"], now))
                    dcid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in items: self.db.execute("INSERT INTO delivery_challan_items (challan_id, product_id, qty, description) VALUES (?,?,?,?)", (dcid, it[0], str(it[1]), it[2]))
                self.audit.log("CREATE_CHALLAN", f"DC {cno}"); print(f" [+] DC {cno} created!"); input(" Press [Enter]...")
            elif c == '3':
                sos = self.db.fetch_all("SELECT order_no, customer_id, grand_total FROM sales_orders WHERE status='PENDING' ORDER BY id DESC")
                if not sos: print(" [!] No pending SO"); input(" Press [Enter]..."); continue
                print(format_table(["Order#","Customer","Total"],[(r[0],r[1],D(r[2])) for r in sos]))
                ono = input_str("Sales Order Number")
                so = self.db.fetch_one("SELECT * FROM sales_orders WHERE order_no=? AND status='PENDING'", (ono,))
                if not so: print(" [!] Not found/pending"); input(" Press [Enter]..."); continue
                cno = "DC-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); dt = datetime.date.today().isoformat()
                vno = input_str("Vehicle", required=False); drv = input_str("Driver", required=False); dph = input_str("Phone", required=False); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat()
                with self.db.conn:
                    self.db.execute("INSERT INTO delivery_challans (challan_no, sale_id, customer_id, challan_date, vehicle_no, driver_name, driver_phone, notes, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,?,?)", (cno, so["id"], so["customer_id"], dt, vno or None, drv or None, dph or None, notes, self.auth.current_user["id"], now))
                    dcid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    sits = self.db.fetch_all("SELECT product_id, qty FROM sales_order_items WHERE order_id=?", (so["id"],))
                    for sit in sits: self.db.execute("INSERT INTO delivery_challan_items (challan_id, product_id, qty) VALUES (?,?,?)", (dcid, sit[0], sit[1]))
                    self.db.execute("UPDATE sales_orders SET status='DELIVERED' WHERE id=?", (so['id'],))
                self.audit.log("CHALLAN_FROM_SO", f"DC {cno} from {ono}"); print(f" [+] DC {cno} created!"); input(" Press [Enter]...")
            elif c == '4':
                cn = input_str("Challan Number")
                d = self.db.fetch_one("SELECT d.*, c.name AS cname FROM delivery_challans d LEFT JOIN customers c ON c.id=d.customer_id WHERE d.challan_no=?", (cn,))
                if not d: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Challan: {d['challan_no']}")
                print(f" Customer: {d['cname'] or 'N/A'} | Date: {d['challan_date']} | Vehicle: {d['vehicle_no'] or 'N/A'}")
                its = self.db.fetch_all("SELECT p.code, p.name, di.qty, di.description FROM delivery_challan_items di JOIN products p ON p.id=di.product_id WHERE di.challan_id=?", (d["id"],))
                print(format_table(["Code","Product","Qty","Desc"],[(r[0],r[1],D(r[2]),r[3] or "") for r in its]))
                if d['notes']: print(f" Notes: {d['notes']}"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# CREDIT & DEBIT NOTE MANAGEMENT
# =====================================================================
class CreditDebitManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("CREDIT / DEBIT NOTES")
            print(" 1. View Credit Notes\n 2. Create Credit Note\n 3. View Debit Notes\n 4. Create Debit Note\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT cn.credit_no, c.name, cn.credit_date, cn.total_amount, cn.reason FROM credit_notes cn LEFT JOIN customers c ON c.id=cn.customer_id ORDER BY cn.id DESC")
                print(format_table(["Credit#","Customer","Date","Amount","Reason"],[(r[0],r[1] or "",r[2][:10] if r[2] else "",D(r[3]),r[4][:30] if r[4] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                sid = input_int("Sale Invoice ID to credit"); s = self.db.fetch_one("SELECT * FROM sales WHERE id=?", (sid,))
                if not s: print(" [!] Not found"); input(" Press [Enter]..."); continue
                cno = "CN-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); dt = datetime.date.today().isoformat()
                reason = input_str("Reason"); total = float(input_dec("Total Credit Amount")); now = datetime.datetime.now().isoformat()
                sitems = self.db.fetch_all("SELECT product_id, qty, price FROM sale_items WHERE sale_id=?", (sid,))
                with self.db.conn:
                    self.db.execute("INSERT INTO credit_notes (credit_no, customer_id, sale_id, credit_date, total_amount, reason, created_by, created_at) VALUES (?,?,?,?,?,?,?,?)", (cno, s["customer_id"], sid, dt, str(total), reason, self.auth.current_user["id"], now))
                    cnid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in sitems:
                        q = float(input_dec(f"Return qty for product {it[0]}", default='0'))
                        if q > 0: amt = q * float(it[2]); self.db.execute("INSERT INTO credit_note_items (credit_note_id, product_id, qty, amount) VALUES (?,?,?,?)", (cnid, it[0], str(q), str(amt))); self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)+? AS TEXT) WHERE id=?", (str(q), it[0]))
                    self.db.execute("UPDATE sales SET status='CREDITED' WHERE id=?", (sid,))
                self.audit.log("CREATE_CREDIT_NOTE", f"CN {cno}"); print(f" [+] CN {cno}"); input(" Press [Enter]...")
            elif c == '3':
                rows = self.db.fetch_all("SELECT dn.debit_no, s.name, dn.debit_date, dn.total_amount, dn.reason FROM debit_notes dn LEFT JOIN suppliers s ON s.id=dn.supplier_id ORDER BY dn.id DESC")
                print(format_table(["Debit#","Supplier","Date","Amount","Reason"],[(r[0],r[1] or "",r[2][:10] if r[2] else "",D(r[3]),r[4][:30] if r[4] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '4':
                pid = input_int("Purchase Invoice ID"); p = self.db.fetch_one("SELECT * FROM purchases WHERE id=?", (pid,))
                if not p: print(" [!] Not found"); input(" Press [Enter]..."); continue
                dno = "DN-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); dt = datetime.date.today().isoformat()
                reason = input_str("Reason"); total = float(input_dec("Total Debit Amount")); now = datetime.datetime.now().isoformat()
                pitems = self.db.fetch_all("SELECT product_id, qty, price FROM purchase_items WHERE purchase_id=?", (pid,))
                with self.db.conn:
                    self.db.execute("INSERT INTO debit_notes (debit_no, supplier_id, purchase_id, debit_date, total_amount, reason, created_by, created_at) VALUES (?,?,?,?,?,?,?,?)", (dno, p["supplier_id"], pid, dt, str(total), reason, self.auth.current_user["id"], now))
                    ddid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                    for it in pitems:
                        q = float(input_dec(f"Return qty for product {it[0]}", default='0'))
                        if q > 0: amt = q * float(it[2]); self.db.execute("INSERT INTO debit_note_items (debit_note_id, product_id, qty, amount) VALUES (?,?,?,?)", (ddid, it[0], str(q), str(amt))); self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)-? AS TEXT) WHERE id=?", (str(q), it[0]))
                    self.db.execute("UPDATE purchases SET status='DEBITED' WHERE id=?", (pid,))
                self.audit.log("CREATE_DEBIT_NOTE", f"DN {dno}"); print(f" [+] DN {dno}"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# EMPLOYEE MANAGEMENT
# =====================================================================
class EmployeeManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("EMPLOYEES")
            print(" 1. View All\n 2. Add\n 3. Edit\n 4. Toggle Active\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, code, name, phone, department, designation, salary_type, salary_amount FROM employees WHERE is_active=1")
                print(format_table(["ID","Code","Name","Phone","Dept","Designation","Salary","Amount"],[(r[0],r[1],r[2],r[3] or "",r[4] or "",r[5] or "",r[6],D(r[7])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                code = input_str("Code"); nm = input_str("Name"); ph = input_str("Phone", required=False); em = input_str("Email", required=False)
                dept = input_str("Department", required=False); des = input_str("Designation", required=False)
                st = "FIXED" if input("Type [1]=Fixed [2]=Commission: ").strip()=='1' else "COMMISSION"
                sa = float(input_dec("Amount", required=False)) if st=='FIXED' else 0; cr = float(input_dec("Comm Rate %", required=False)) if st=='COMMISSION' else 0
                jd = input_str("Joining Date", required=False); now = datetime.datetime.now().isoformat()
                try: self.db.execute("INSERT INTO employees (code, name, phone, email, department, designation, salary_type, salary_amount, commission_rate, joining_date, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)", (code, nm, ph or None, em or None, dept or None, des or None, st, str(sa), str(cr), jd or None, now)); self.audit.log("ADD_EMPLOYEE", f"Added {nm}"); print(" [+] Added!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                eid = input_int("Employee ID"); e = self.db.fetch_one("SELECT * FROM employees WHERE id=?", (eid,))
                if not e: print(" [!] Not found"); input(" Press [Enter]..."); continue
                nm = input_str("Name", default=e['name']); ph = input_str("Phone", required=False, default=e['phone'] or "")
                dept = input_str("Department", required=False, default=e['department'] or ""); des = input_str("Designation", required=False, default=e['designation'] or "")
                sa = float(input_dec("Salary", required=False, default=e['salary_amount'])); self.db.execute("UPDATE employees SET name=?, phone=?, department=?, designation=?, salary_amount=? WHERE id=?", (nm, ph or None, dept or None, des or None, str(sa), eid))
                self.audit.log("EDIT_EMPLOYEE", f"Updated {nm}"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '4':
                eid = input_int("Employee ID"); e = self.db.fetch_one("SELECT id, name, is_active FROM employees WHERE id=?", (eid,))
                if not e: print(" [!] Not found"); input(" Press [Enter]..."); continue
                nv = 0 if e[2]==1 else 1; self.db.execute("UPDATE employees SET is_active=? WHERE id=?", (nv, eid))
                self.audit.log("TOGGLE_EMPLOYEE", f"{e[1]} {'Activated' if nv else 'Deactivated'}"); print(" [+] Done!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# COMMISSION MANAGEMENT
# =====================================================================
class CommissionManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("COMMISSIONS")
            print(" 1. View All\n 2. Calculate from Sales\n 3. Mark Paid\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT cm.id, e.name, cm.commission_type, cm.commission_amount, cm.paid_status, cm.created_at FROM commissions cm JOIN employees e ON e.id=cm.employee_id ORDER BY cm.id DESC LIMIT 50")
                print(format_table(["ID","Employee","Type","Amount","Paid","Date"],[(r[0],r[1],r[2],D(r[3]),"Yes" if r[4] else "No",r[5][:10] if r[5] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                emps = self.db.fetch_all("SELECT id, name, commission_rate FROM employees WHERE is_active=1 AND salary_type='COMMISSION'")
                if not emps: print(" [!] No commission employees"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Name","Rate%"],[(r[0],r[1],D(r[2])) for r in emps]))
                eid = input_int("Employee ID"); emp = self.db.fetch_one("SELECT * FROM employees WHERE id=?", (eid,))
                if not emp: print(" [!] Not found"); input(" Press [Enter]..."); continue
                sd = input_str("From Date"); ed = input_str("To Date")
                sales = self.db.fetch_all("SELECT s.id, s.invoice_no, s.grand_total FROM sales s WHERE s.created_by=? AND s.sale_date BETWEEN ? AND ? AND s.status='COMPLETED'", (eid, sd, ed))
                if not sales: print(" [!] No sales"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Invoice","Total"],[(r[0],r[1],D(r[2])) for r in sales]))
                ts = sum(float(r[2]) for r in sales); rate = float(emp['commission_rate']); comm = ts * rate / 100
                print(f" Total Sales: {ts:.2f} x {rate}% = {comm:.2f}")
                if input(" Create entries? (Y/N): ").strip().upper() == 'Y':
                    now = datetime.datetime.now().isoformat()
                    with self.db.conn:
                        for s in sales: amt = float(s[2]) * rate / 100; self.db.execute("INSERT INTO commissions (employee_id, sale_id, commission_type, commission_rate, commission_amount, created_at) VALUES (?,?,?,?,?,?)", (eid, s[0], 'SALES', str(rate), str(amt), now))
                    self.audit.log("CALC_COMM", f"{comm:.2f} for {emp['name']}"); print(f" [+] {comm:.2f} logged!"); input(" Press [Enter]...")
            elif c == '3':
                rows = self.db.fetch_all("SELECT c.id, e.name, c.commission_amount FROM commissions c JOIN employees e ON e.id=c.employee_id WHERE c.paid_status=0")
                if not rows: print(" [!] None unpaid"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Employee","Amount"],[(r[0],r[1],D(r[2])) for r in rows]))
                cid = input_int("Commission ID to pay (0=all)")
                if cid == 0: self.db.execute("UPDATE commissions SET paid_status=1, paid_date=? WHERE paid_status=0", (datetime.date.today().isoformat(),)); self.audit.log("PAY_COMM", "Paid all"); print(" [+] All paid!"); input(" Press [Enter]...")
                else: self.db.execute("UPDATE commissions SET paid_status=1, paid_date=? WHERE id=?", (datetime.date.today().isoformat(), cid)); self.audit.log("PAY_COMM", f"Paid {cid}"); print(" [+] Paid!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# LOYALTY POINTS MANAGEMENT
# =====================================================================
class LoyaltyManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager', 'Cashier']): return
        while True:
            print_header("LOYALTY POINTS")
            print(" 1. View Points\n 2. Add/Adjust\n 3. Redeem\n 4. History\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT c.code, c.name, COALESCE(lp.points,0) FROM customers c LEFT JOIN loyalty_points lp ON lp.customer_id=c.id WHERE c.is_active=1 ORDER BY lp.points DESC")
                print(format_table(["Code","Name","Points"],[(r[0],r[1],r[2]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                ccode = input_str("Customer Code"); cust = self.db.fetch_one("SELECT id, name FROM customers WHERE code=? AND is_active=1", (ccode,))
                if not cust: print(" [!] Not found"); input(" Press [Enter]..."); continue
                pts = input_int("Points (+=earn, -=redeem)"); now = datetime.datetime.now().isoformat()
                with self.db.conn:
                    self.db.execute("INSERT INTO loyalty_points (customer_id, points, updated_at) VALUES (?,?,?) ON CONFLICT(customer_id) DO UPDATE SET points=COALESCE((SELECT points FROM loyalty_points WHERE customer_id=?),0)+?, updated_at=?", (cust[0], pts, now, cust[0], pts, now))
                    tt = "EARNED" if pts > 0 else "REDEEMED"; self.db.execute("INSERT INTO loyalty_transactions (customer_id, points, trans_type, description, created_at) VALUES (?,?,?,?,?)", (cust[0], abs(pts), tt, f"Manual: {self.auth.current_user['username']}", now))
                self.audit.log("LOYALTY", f"{pts} pts for {cust[1]}"); print(" [+] Done!"); input(" Press [Enter]...")
            elif c == '3':
                ccode = input_str("Customer Code")
                cust = self.db.fetch_one("SELECT c.id, c.name, COALESCE(lp.points,0) FROM customers c LEFT JOIN loyalty_points lp ON lp.customer_id=c.id WHERE c.code=? AND c.is_active=1", (ccode,))
                if not cust: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print(f" {cust[1]} has {cust[2]} pts"); pts = input_int("Points to redeem")
                if pts > cust[2]: print(" [!] Insufficient"); input(" Press [Enter]..."); continue
                val = float(input_dec("Cash value")); now = datetime.datetime.now().isoformat()
                with self.db.conn:
                    self.db.execute("UPDATE loyalty_points SET points=points-? WHERE customer_id=?", (pts, cust[0]))
                    self.db.execute("INSERT INTO loyalty_transactions (customer_id, points, trans_type, ref_id, description, created_at) VALUES (?,?,?,'REDEEM',?,?)", (cust[0], pts, 'REDEEMED', f"Redeemed {val:.2f}", now))
                self.audit.log("LOYALTY_REDEEM", f"{pts} pts = {val:.2f}"); print(" [+] Redeemed!"); input(" Press [Enter]...")
            elif c == '4':
                ccode = input_str("Customer Code (empty=all)", required=False)
                if ccode: rows = self.db.fetch_all("SELECT lt.created_at, lt.points, lt.trans_type, lt.description FROM loyalty_transactions lt JOIN customers c ON c.id=lt.customer_id WHERE c.code=? ORDER BY lt.id DESC", (ccode,))
                else: rows = self.db.fetch_all("SELECT lt.created_at, lt.points, lt.trans_type, lt.description FROM loyalty_transactions lt ORDER BY lt.id DESC LIMIT 50")
                print(format_table(["Date","Points","Type","Desc"],[(r[0][:16] if r[0] else "",r[1],r[2],r[3][:40] if r[3] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# PRICE LIST MANAGEMENT
# =====================================================================
class PriceListManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("PRICE LISTS")
            print(" 1. View\n 2. Create\n 3. Add/Update Prices\n 4. Apply to Products\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, name, list_type, is_active FROM price_lists")
                print(format_table(["ID","Name","Type","Active"],[(r[0],r[1],r[2],"Yes" if r[3] else "No") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                nm = input_str("Name"); lt = "SALE" if input("Type [1]=Sale [2]=Wholesale: ").strip()=="1" else "WHOLESALE"
                try: self.db.execute("INSERT INTO price_lists (name, list_type) VALUES (?,?)", (nm, lt)); self.audit.log("ADD_PRICELIST", f"Created {nm}"); print(" [+] Created!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                pls = self.db.fetch_all("SELECT id, name FROM price_lists WHERE is_active=1")
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in pls]))
                plid = input_int("Price List ID"); pl = self.db.fetch_one("SELECT * FROM price_lists WHERE id=?", (plid,))
                if not pl: print(" [!] Not found"); input(" Press [Enter]..."); continue
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name, sale_price FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    sp = float(input_dec("Sale Price", default=str(p[2]))); wp = float(input_dec("Wholesale", required=False)); disc = float(input_dec("Disc %", required=False))
                    self.db.execute("INSERT INTO price_list_items (price_list_id, product_id, sale_price, wholesale_price, discount_percent) VALUES (?,?,?,?,?) ON CONFLICT(price_list_id,product_id) DO UPDATE SET sale_price=?, wholesale_price=?, discount_percent=?", (plid, p[0], str(sp), str(wp), str(disc), str(sp), str(wp), str(disc)))
                    print(f" [+] Updated {p[1]}")
                self.audit.log("EDIT_PRICELIST", f"Updated {pl['name']}"); print(" [+] Price list updated!"); input(" Press [Enter]...")
            elif c == '4':
                pls = self.db.fetch_all("SELECT id, name FROM price_lists WHERE is_active=1")
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in pls]))
                plid = input_int("Price List ID to apply")
                pl = self.db.fetch_one("SELECT * FROM price_lists WHERE id=?", (plid,))
                if not pl: print(" [!] Not found"); input(" Press [Enter]..."); continue
                items = self.db.fetch_all("SELECT product_id, sale_price FROM price_list_items WHERE price_list_id=?", (plid,))
                if not items: print(" [!] No items"); input(" Press [Enter]..."); continue
                with self.db.conn:
                    for it in items: self.db.execute("UPDATE products SET sale_price=? WHERE id=?", (str(it[1]), it[0]))
                self.audit.log("APPLY_PRICELIST", f"Applied {pl['name']} to {len(items)} products"); print(f" [+] Applied to {len(items)} prods!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# PROMOTION MANAGEMENT
# =====================================================================
class PromotionManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("PROMOTIONS")
            print(" 1. View\n 2. Create\n 3. Toggle Active\n 4. Assign Products\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, name, promo_type, discount_value, coupon_code, start_date, end_date, is_active FROM promotions ORDER BY id DESC")
                print(format_table(["ID","Name","Type","Value","Coupon","Start","End","Active"],[(r[0],r[1],r[2],D(r[3]),r[4] or "",r[5][:10] if r[5] else "",r[6][:10] if r[6] else "","Yes" if r[7] else "No") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                nm = input_str("Name"); pt = "PERCENTAGE" if input("Type [1]=% [2]=Fixed: ").strip()=='1' else "FIXED"
                dv = float(input_dec("Discount Value")); mp = float(input_dec("Min Purchase", required=False))
                md = float(input_dec("Max Discount", required=False)) if pt=='PERCENTAGE' else 0
                cc = input_str("Coupon Code", required=False); sd = input_str("Start", required=False); ed = input_str("End", required=False)
                now = datetime.datetime.now().isoformat()
                try: self.db.execute("INSERT INTO promotions (name, promo_type, discount_value, min_purchase, max_discount, coupon_code, start_date, end_date, created_at) VALUES (?,?,?,?,?,?,?,?,?)", (nm, pt, str(dv), str(mp), str(md), cc or None, sd or None, ed or None, now)); self.audit.log("ADD_PROMO", f"Created {nm}"); print(" [+] Created!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                pid = input_int("Promotion ID"); p = self.db.fetch_one("SELECT id, name, is_active FROM promotions WHERE id=?", (pid,))
                if not p: print(" [!] Not found"); input(" Press [Enter]..."); continue
                nv = 0 if p[2]==1 else 1; self.db.execute("UPDATE promotions SET is_active=? WHERE id=?", (nv, pid)); self.audit.log("TOGGLE_PROMO", f"{p[1]} {'Activated' if nv else 'Deactivated'}"); print(" [+] Toggled!"); input(" Press [Enter]...")
            elif c == '4':
                pms = self.db.fetch_all("SELECT id, name FROM promotions WHERE is_active=1")
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in pms]))
                pid = input_int("Promotion ID"); prom = self.db.fetch_one("SELECT * FROM promotions WHERE id=?", (pid,))
                if not prom: print(" [!] Not found"); input(" Press [Enter]..."); continue
                while True:
                    sku = input_str("Product Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    self.db.execute("INSERT OR IGNORE INTO promotion_applicable (promotion_id, product_id) VALUES (?,?)", (pid, p[0]))
                    print(f" [+] Added {p[1]}")
                self.audit.log("ASSIGN_PROMO", f"Products to {prom['name']}"); print(" [+] Done!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# SERIAL NUMBER TRACKING
# =====================================================================
class SerialNumberManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("SERIAL NUMBERS")
            print(" 1. View All\n 2. Register\n 3. Search\n 4. Update Status\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT sn.serial_no, p.code, p.name, sn.status, sn.created_at FROM serial_numbers sn JOIN products p ON p.id=sn.product_id ORDER BY sn.id DESC LIMIT 50")
                print(format_table(["Serial#","Code","Product","Status","Date"],[(r[0],r[1],r[2],r[3],r[4][:10] if r[4] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                sku = input_str("Product Code"); p = self.db.fetch_one("SELECT id, name FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                if not p: print(" [!] Not found"); input(" Press [Enter]..."); continue
                sn = input_str("Serial Number")
                try: self.db.execute("INSERT INTO serial_numbers (product_id, serial_no, status, created_at) VALUES (?,?,'IN_STOCK',?)", (p[0], sn, datetime.datetime.now().isoformat())); self.audit.log("REG_SERIAL", f"{sn} for {p[1]}"); print(" [+] Registered!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                sn = input_str("Serial Number")
                r = self.db.fetch_one("SELECT sn.*, p.code, p.name FROM serial_numbers sn JOIN products p ON p.id=sn.product_id WHERE sn.serial_no=?", (sn,))
                if not r: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print(f" Serial: {r['serial_no']}\n Product: {r['code']}-{r['name']}\n Status: {r['status']}\n Warehouse: {r['warehouse_id'] or 'N/A'}"); input(" Press [Enter]...")
            elif c == '4':
                sn = input_str("Serial Number")
                r = self.db.fetch_one("SELECT * FROM serial_numbers WHERE serial_no=?", (sn,))
                if not r: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print(f" Status: {r['status']}")
                ns = input(" New: IN_STOCK/SOLD/RETURNED/SCRAPPED: ").strip().upper()
                if ns not in ('IN_STOCK','SOLD','RETURNED','SCRAPPED'): print(" [!] Invalid"); input(" Press [Enter]..."); continue
                self.db.execute("UPDATE serial_numbers SET status=? WHERE id=?", (ns, r['id']))
                wh = input_int("Warehouse ID", required=False)
                if wh: self.db.execute("UPDATE serial_numbers SET warehouse_id=? WHERE id=?", (wh, r['id']))
                self.audit.log("SERIAL_UPDATE", f"{sn} -> {ns}"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# SERVICE / REPAIR MANAGEMENT
# =====================================================================
class ServiceManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager', 'Cashier']): return
        while True:
            print_header("SERVICE JOBS")
            print(" 1. View All\n 2. Create\n 3. Update Status\n 4. Add Parts\n 5. Details\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT sj.job_no, c.name, p.name, sj.status, sj.received_date FROM service_jobs sj LEFT JOIN customers c ON c.id=sj.customer_id LEFT JOIN products p ON p.id=sj.product_id ORDER BY sj.id DESC")
                print(format_table(["Job#","Customer","Product","Status","Date"],[(r[0],r[1] or "",r[2] or "",r[3],r[4][:10] if r[4] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                custs = self.db.fetch_all("SELECT id, code, name FROM customers WHERE is_active=1")
                print(format_table(["ID","Code","Name"],[(r[0],r[1],r[2]) for r in custs]))
                cid = input_int("Customer ID (0=Walk-in)")
                jno = "SRV-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
                sku = input_str("Product Code", required=False); pid = None; pname = ""
                if sku:
                    p = self.db.fetch_one("SELECT id, name FROM products WHERE (code=? OR barcode=?)", (sku, sku))
                    if p: pid = p[0]; pname = p[1]
                sn = input_str("Serial", required=False); issue = input_str("Issue"); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                self.db.execute("INSERT INTO service_jobs (job_no, customer_id, product_id, serial_no, issue_description, status, received_date, notes, created_by, created_at) VALUES (?,?,?,?,?,'PENDING',?,?,?,?)", (jno, cid or None, pid, sn or None, issue, dt, notes, self.auth.current_user["id"], now))
                self.audit.log("CREATE_SRV", f"{jno}"); print(f" [+] {jno} created!"); input(" Press [Enter]...")
            elif c == '3':
                jno = input_str("Job Number"); j = self.db.fetch_one("SELECT * FROM service_jobs WHERE job_no=?", (jno,))
                if not j: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print(f" Status: {j['status']}")
                ns = input(" Status (PENDING/IN_PROGRESS/COMPLETED/DELIVERED/CANCELLED): ").strip().upper()
                if ns not in ('PENDING','IN_PROGRESS','COMPLETED','DELIVERED','CANCELLED'): print(" [!] Invalid"); input(" Press [Enter]..."); continue
                dd = datetime.date.today().isoformat() if ns in ('COMPLETED','DELIVERED') else None
                sc = float(input_dec("Charges", required=False)) if ns=='COMPLETED' else 0
                self.db.execute("UPDATE service_jobs SET status=?, delivered_date=COALESCE(?,delivered_date), service_charges=? WHERE id=?", (ns, dd, str(sc) if sc else j['service_charges'], j['id']))
                self.audit.log("UPDATE_SRV", f"{jno} -> {ns}"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '4':
                jno = input_str("Job Number"); j = self.db.fetch_one("SELECT * FROM service_jobs WHERE job_no=?", (jno,))
                if not j: print(" [!] Not found"); input(" Press [Enter]..."); continue
                while True:
                    sku = input_str("Part Code (empty=finish)", required=False)
                    if not sku: break
                    p = self.db.fetch_one("SELECT id, name FROM products WHERE (code=? OR barcode=?)", (sku, sku))
                    if not p: print(" [!] Not found"); continue
                    qty = float(input_dec(f"Qty")); price = float(input_dec("Price"))
                    self.db.execute("INSERT INTO service_parts (service_job_id, product_id, qty, price, total) VALUES (?,?,?,?,?)", (j['id'], p[0], str(qty), str(price), str(qty * price)))
                    print(f" [+] Added {p[1]} x {qty} = {qty*price:.2f}")
                self.audit.log("ADD_SRV_PARTS", f"Parts to {jno}"); print(" [+] Parts added!"); input(" Press [Enter]...")
            elif c == '5':
                jno = input_str("Job Number")
                j = self.db.fetch_one("SELECT sj.*, c.name AS cname, p.name AS pname FROM service_jobs sj LEFT JOIN customers c ON c.id=sj.customer_id LEFT JOIN products p ON p.id=sj.product_id WHERE sj.job_no=?", (jno,))
                if not j: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Service: {j['job_no']} [{j['status']}]")
                print(f" Customer: {j['cname'] or 'N/A'} | Product: {j['pname'] or 'N/A'} | Serial: {j['serial_no'] or 'N/A'}")
                print(f" Received: {j['received_date']} | Delivered: {j['delivered_date'] or 'Pending'}\n Issue: {j['issue_description']}\n Charges: {D(j['service_charges'])}")
                if j['notes']: print(f" Notes: {j['notes']}")
                parts = self.db.fetch_all("SELECT p.code, p.name, sp.qty, sp.price, sp.total FROM service_parts sp JOIN products p ON p.id=sp.product_id WHERE sp.service_job_id=?", (j["id"],))
                if parts: print("\n Parts:"); print(format_table(["Code","Part","Qty","Price","Total"],[(r[0],r[1],D(r[2]),D(r[3]),D(r[4])) for r in parts]))
                input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# BILL OF MATERIALS
# =====================================================================
class BOManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("BILL OF MATERIALS")
            print(" 1. View\n 2. Create\n 3. Details\n 4. Cost\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT b.id, b.name, p.code, p.name, b.output_qty FROM bom b JOIN products p ON p.id=b.finished_product_id ORDER BY b.id")
                print(format_table(["ID","BOM","Code","Product","Output"],[(r[0],r[1],r[2],r[3],D(r[4])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                nm = input_str("BOM Name"); sku = input_str("Finished Product Code")
                fp = self.db.fetch_one("SELECT id, name FROM products WHERE (code=? OR barcode=?) AND is_active=1", (sku, sku))
                if not fp: print(" [!] Product not found"); input(" Press [Enter]..."); continue
                oq = float(input_dec("Output Qty", default="1.00")); wp = float(input_dec("Wastage %", required=False))
                now = datetime.datetime.now().isoformat()
                self.db.execute("INSERT INTO bom (name, finished_product_id, output_qty, wastage_percent, created_at) VALUES (?,?,?,?,?)", (nm, fp[0], str(oq), str(wp), now))
                bid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                print(" Add Raw Materials:")
                while True:
                    rsku = input_str("Raw Material Code (empty=finish)", required=False)
                    if not rsku: break
                    rp = self.db.fetch_one("SELECT id, name, purchase_price FROM products WHERE (code=? OR barcode=?) AND is_active=1", (rsku, rsku))
                    if not rp: print(" [!] Not found"); continue
                    rq = float(input_dec(f"Qty of {rp[1]}")); self.db.execute("INSERT INTO bom_items (bom_id, raw_product_id, qty) VALUES (?,?,?)", (bid, rp[0], str(rq)))
                    print(f" [+] {rp[1]} x {rq}")
                self.audit.log("CREATE_BOM", f"{nm} for {fp[1]}"); print(f" [+] BOM {nm} created!"); input(" Press [Enter]...")
            elif c == '3':
                bid = input_int("BOM ID"); b = self.db.fetch_one("SELECT b.*, p.code, p.name AS pname FROM bom b JOIN products p ON p.id=b.finished_product_id WHERE b.id=?", (bid,))
                if not b: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"BOM: {b['name']}")
                print(f" Product: {b['code']}-{b['pname']} | Output: {D(b['output_qty'])} | Waste: {D(b['wastage_percent'])}%")
                items = self.db.fetch_all("SELECT p.code, p.name, bi.qty, p.purchase_price FROM bom_items bi JOIN products p ON p.id=bi.raw_product_id WHERE bi.bom_id=?", (bid,))
                print(format_table(["Code","Raw","Qty","Cost/U","Total"],[(r[0],r[1],D(r[2]),D(r[3]),D(float(r[2])*float(r[3]))) for r in items]))
                tc = sum(float(r[2])*float(r[3]) for r in items); print(f"\n Total Cost: {tc:.2f}"); input(" Press [Enter]...")
            elif c == '4':
                bid = input_int("BOM ID"); b = self.db.fetch_one("SELECT b.*, p.name AS pname FROM bom b JOIN products p ON p.id=b.finished_product_id WHERE b.id=?", (bid,))
                if not b: print(" [!] Not found"); input(" Press [Enter]..."); continue
                items = self.db.fetch_all("SELECT bi.qty, p.purchase_price FROM bom_items bi JOIN products p ON p.id=bi.raw_product_id WHERE bi.bom_id=?", (bid,))
                total = sum(float(r[0])*float(r[1]) for r in items); oq = float(b['output_qty']); wp = float(b['wastage_percent'])
                uc = total / oq if oq else 0; uw = uc * (1 + wp/100)
                print(f" BOM: {b['name']} -> {b['pname']}\n Raw Cost: {total:.2f} | Output: {oq} | Waste: {wp}%\n Unit Cost: {uc:.2f} | With Waste: {uw:.2f}"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# MANUFACTURING JOBS
# =====================================================================
class ManufacturingManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("MANUFACTURING")
            print(" 1. View Jobs\n 2. Create\n 3. Start\n 4. Complete\n 5. Details\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT mj.job_no, b.name, p.name, mj.planned_qty, mj.produced_qty, mj.status FROM manufacturing_jobs mj JOIN bom b ON b.id=mj.bom_id JOIN products p ON p.id=mj.product_id ORDER BY mj.id DESC")
                print(format_table(["Job#","BOM","Product","Planned","Produced","Status"],[(r[0],r[1],r[2],D(r[3]),D(r[4]),r[5]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                boms = self.db.fetch_all("SELECT b.id, b.name, p.code, p.name, b.output_qty FROM bom b JOIN products p ON p.id=b.finished_product_id")
                if not boms: print(" [!] No BOMs"); input(" Press [Enter]..."); continue
                print(format_table(["ID","BOM","Code","Product","Output"],[(r[0],r[1],r[2],r[3],D(r[4])) for r in boms]))
                bid = input_int("BOM ID"); b = self.db.fetch_one("SELECT b.*, p.name, p.id AS pid FROM bom b JOIN products p ON p.id=b.finished_product_id WHERE b.id=?", (bid,))
                if not b: print(" [!] Not found"); input(" Press [Enter]..."); continue
                jno = "MFG-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S"); pq = float(input_dec("Planned Qty")); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat()
                self.db.execute("INSERT INTO manufacturing_jobs (job_no, bom_id, product_id, planned_qty, status, notes, created_by, created_at) VALUES (?,?,?,?,'PLANNED',?,?,?)", (jno, bid, b['pid'], str(pq), notes, self.auth.current_user['id'], now))
                self.audit.log("CREATE_MFG", f"{jno}"); print(f" [+] {jno} created!"); input(" Press [Enter]...")
            elif c == '3':
                jno = input_str("Job #"); j = self.db.fetch_one("SELECT * FROM manufacturing_jobs WHERE job_no=? AND status='PLANNED'", (jno,))
                if not j: print(" [!] Not found/planned"); input(" Press [Enter]..."); continue
                self.db.execute("UPDATE manufacturing_jobs SET status='IN_PROGRESS', start_date=? WHERE id=?", (datetime.date.today().isoformat(), j['id']))
                self.audit.log("START_MFG", f"Started {jno}"); print(" [+] Started!"); input(" Press [Enter]...")
            elif c == '4':
                jno = input_str("Job #"); j = self.db.fetch_one("SELECT * FROM manufacturing_jobs WHERE job_no=? AND status='IN_PROGRESS'", (jno,))
                if not j: print(" [!] Not found/in progress"); input(" Press [Enter]..."); continue
                b = self.db.fetch_one("SELECT * FROM bom WHERE id=?", (j['bom_id'],))
                if not b: print(" [!] BOM missing"); input(" Press [Enter]..."); continue
                prod = float(input_dec(f"Produced Qty (planned {D(j['planned_qty'])})"))
                with self.db.conn:
                    items = self.db.fetch_all("SELECT raw_product_id, qty FROM bom_items WHERE bom_id=?", (b["id"],))
                    for it in items:
                        rq = float(it[1]) * prod / float(b['output_qty'])
                        self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)-? AS TEXT) WHERE id=?", (str(rq), it[0]))
                        self.db.execute("INSERT INTO stock_movements (product_id, qty, movement_type, ref_id, notes, created_at) VALUES (?,?,'MFG_CONSUME',?,?,?)", (it[0], str(-rq), jno, f"Consumed for {jno}", datetime.datetime.now().isoformat()))
                    self.db.execute("UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL)+? AS TEXT) WHERE id=?", (str(prod), j['product_id']))
                    self.db.execute("INSERT INTO stock_movements (product_id, qty, movement_type, ref_id, notes, created_at) VALUES (?,?,'MFG_OUTPUT',?,?,?)", (j["product_id"], str(prod), jno, f"Produced from {jno}", datetime.datetime.now().isoformat()))
                    self.db.execute("UPDATE manufacturing_jobs SET produced_qty=?, status='COMPLETED', end_date=? WHERE id=?", (str(prod), datetime.date.today().isoformat(), j['id']))
                self.audit.log("COMPLETE_MFG", f"{jno}: {prod} units"); print(f" [+] Completed {prod} units!"); input(" Press [Enter]...")
            elif c == '5':
                jno = input_str("Job #")
                j = self.db.fetch_one("SELECT mj.*, b.name AS bname, p.code, p.name AS pname FROM manufacturing_jobs mj JOIN bom b ON b.id=mj.bom_id JOIN products p ON p.id=mj.product_id WHERE mj.job_no=?", (jno,))
                if not j: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Job: {j['job_no']} [{j['status']}]")
                print(f" BOM: {j['bname']} | Product: {j['code']}-{j['pname']}\n Planned: {D(j['planned_qty'])} | Produced: {D(j['produced_qty'])} | Start: {j['start_date'] or 'N/A'} | End: {j['end_date'] or 'N/A'}")
                if j['notes']: print(f" Notes: {j['notes']}"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# ACCOUNTING MODULE
# =====================================================================
class AccountingManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("ACCOUNTING")
            print(" 1. Chart of Accounts\n 2. Add Account\n 3. General Ledger\n 4. Account Statement\n 5. Post Journal Entry\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT code, name, account_type, is_active FROM chart_of_accounts ORDER BY code")
                print(format_table(["Code","Name","Type","Active"],[(r[0],r[1],r[2],"Yes" if r[3] else "No") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                code = input_str("Code"); nm = input_str("Name")
                print(" Types: ASSET, LIABILITY, EQUITY, INCOME, EXPENSE")
                at = input_str("Type").upper()
                if at not in ('ASSET','LIABILITY','EQUITY','INCOME','EXPENSE'): print(" [!] Invalid"); input(" Press [Enter]..."); continue
                pid = input_int("Parent ID", required=False)
                try: self.db.execute("INSERT INTO chart_of_accounts (code, name, account_type, parent_id) VALUES (?,?,?,?)", (code, nm, at, pid or None)); self.audit.log("ADD_ACCOUNT", f"{code}-{nm}"); print(" [+] Added!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                rows = self.db.fetch_all("SELECT gl.trans_date, c.name, gl.trans_type, gl.debit, gl.credit, gl.running_balance, gl.description FROM general_ledger gl JOIN chart_of_accounts c ON c.id=gl.account_id ORDER BY gl.id DESC LIMIT 50")
                print(format_table(["Date","Account","Type","Debit","Credit","Balance","Desc"],[(r[0][:10] if r[0] else "",r[1],r[2],D(r[3]),D(r[4]),D(r[5]),r[6][:30] if r[6] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '4':
                accts = self.db.fetch_all("SELECT id, code, name FROM chart_of_accounts WHERE is_active=1 ORDER BY code")
                print(format_table(["ID","Code","Account"],[(r[0],r[1],r[2]) for r in accts]))
                aid = input_int("Account ID"); sd = input_str("From", required=False); ed = input_str("To", required=False)
                q = "SELECT trans_date, trans_type, debit, credit, running_balance, description FROM general_ledger WHERE account_id=? "; params = [aid]
                if sd: q += " AND trans_date>=?"; params.append(sd)
                if ed: q += " AND trans_date<=?"; params.append(ed)
                q += " ORDER BY trans_date, id"
                rows = self.db.fetch_all(q, tuple(params))
                acct = self.db.fetch_one("SELECT name, account_type FROM chart_of_accounts WHERE id=?", (aid,))
                print_header(f"Statement: {acct['name']} ({acct['account_type']})")
                print(format_table(["Date","Type","Debit","Credit","Balance","Desc"],[(r[0][:10] if r[0] else "",r[1],D(r[2]),D(r[3]),D(r[4]),r[5][:35] if r[5] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '5':
                print(" Post Journal Entry (Double Entry)"); desc = input_str("Description")
                dt = input_str("Date", required=False) or datetime.date.today().isoformat(); entries = []
                while True:
                    accts = self.db.fetch_all("SELECT id, code, name FROM chart_of_accounts WHERE is_active=1 ORDER BY code")
                    print(format_table(["ID","Code","Account"],[(r[0],r[1],r[2]) for r in accts]))
                    aid = input_int("Account ID (0=finish)")
                    if aid == 0: break
                    amt = float(input_dec("Amount")); tt = input(" D/C: ").strip().upper()
                    if tt not in ('D','C'): print(" [!] Invalid"); continue
                    entries.append((aid, amt, 'DEBIT' if tt=='D' else 'CREDIT'))
                if len(entries) < 2: print(" [!] Need 2+ entries"); input(" Press [Enter]..."); continue
                dtot = sum(e[1] for e in entries if e[2]=='DEBIT'); ctot = sum(e[1] for e in entries if e[2]=='CREDIT')
                if abs(dtot - ctot) > 0.01: print(f" [!] Unbalanced: Dr={dtot:.2f} Cr={ctot:.2f}"); input(" Press [Enter]..."); continue
                now = datetime.datetime.now().isoformat(); ref = "JV-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
                with self.db.conn:
                    for e in entries:
                        bal = self.db.fetch_val("SELECT running_balance FROM general_ledger WHERE account_id=? ORDER BY id DESC LIMIT 1", (e[0],)) or 0
                        nbal = float(bal) + e[1] if e[2]=='DEBIT' else float(bal) - e[1]
                        self.db.execute("INSERT INTO general_ledger (account_id, trans_date, trans_type, debit, credit, running_balance, ref_id, description, created_by) VALUES (?,?,?,?,?,?,?,?,?)", (e[0], dt, e[2], str(e[1]) if e[2]=='DEBIT' else '0.00', str(e[1]) if e[2]=='CREDIT' else '0.00', str(nbal), ref, desc[:200], self.auth.current_user['id']))
                self.audit.log("JOURNAL_ENTRY", f"{ref}"); print(f" [+] JV {ref} posted!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# FINANCIAL STATEMENTS
# =====================================================================
class FinancialStatementManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("FINANCIAL STATEMENTS")
            print(" 1. Trial Balance\n 2. Profit & Loss\n 3. Balance Sheet\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                as_on = input_str("As On", required=False) or datetime.date.today().isoformat()
                rows = self.db.fetch_all("SELECT c.code, c.name, c.account_type, COALESCE((SELECT running_balance FROM general_ledger WHERE account_id=c.id ORDER BY id DESC LIMIT 1),0) FROM chart_of_accounts c WHERE c.is_active=1 ORDER BY c.code")
                print_header(f"TRIAL BALANCE AS ON {as_on}")
                print(format_table(["Code","Account","Type","Balance"],[(r[0],r[1],r[2],D(r[3])) for r in rows]))
                td = sum(float(r[3]) for r in rows if float(r[3])>0); tc = sum(abs(float(r[3])) for r in rows if float(r[3])<0)
                print(f"\n Dr: {td:.2f} | Cr: {tc:.2f} | Diff: {abs(td-tc):.2f}"); input(" Press [Enter]...")
            elif c == '2':
                sd = input_str("From"); ed = input_str("To")
                income = self.db.fetch_all("SELECT c.code, c.name, COALESCE(SUM(CAST(gl.credit AS REAL)-CAST(gl.debit AS REAL)),0) FROM general_ledger gl JOIN chart_of_accounts c ON c.id=gl.account_id WHERE c.account_type='INCOME' AND gl.trans_date BETWEEN ? AND ? GROUP BY c.id HAVING SUM(CAST(gl.credit AS REAL)-CAST(gl.debit AS REAL))<>0", (sd, ed))
                expenses = self.db.fetch_all("SELECT c.code, c.name, COALESCE(SUM(CAST(gl.debit AS REAL)-CAST(gl.credit AS REAL)),0) FROM general_ledger gl JOIN chart_of_accounts c ON c.id=gl.account_id WHERE c.account_type='EXPENSE' AND gl.trans_date BETWEEN ? AND ? GROUP BY c.id HAVING SUM(CAST(gl.debit AS REAL)-CAST(gl.credit AS REAL))<>0", (sd, ed))
                print_header(f"P&L: {sd} TO {ed}")
                print(" [INCOME]"); ti = sum(float(r[2]) for r in income)
                print(format_table(["Code","Account","Amount"],[(r[0],r[1],D(r[2])) for r in income])); print(f" Total: {ti:.2f}\n")
                print(" [EXPENSES]"); te = sum(float(r[2]) for r in expenses)
                print(format_table(["Code","Account","Amount"],[(r[0],r[1],D(r[2])) for r in expenses])); print(f" Total: {te:.2f}")
                net = ti - te; print(f"\n {'PROFIT' if net>=0 else 'LOSS'}: {abs(net):.2f}"); input(" Press [Enter]...")
            elif c == '3':
                as_on = input_str("As On", required=False) or datetime.date.today().isoformat()
                assets = self.db.fetch_all("SELECT c.code, c.name, COALESCE((SELECT running_balance FROM general_ledger WHERE account_id=c.id ORDER BY id DESC LIMIT 1),0) FROM chart_of_accounts c WHERE c.account_type='ASSET' AND c.is_active=1 ORDER BY c.code")
                liab = self.db.fetch_all("SELECT c.code, c.name, COALESCE((SELECT running_balance FROM general_ledger WHERE account_id=c.id ORDER BY id DESC LIMIT 1),0) FROM chart_of_accounts c WHERE c.account_type='LIABILITY' AND c.is_active=1 ORDER BY c.code")
                equity = self.db.fetch_all("SELECT c.code, c.name, COALESCE((SELECT running_balance FROM general_ledger WHERE account_id=c.id ORDER BY id DESC LIMIT 1),0) FROM chart_of_accounts c WHERE c.account_type='EQUITY' AND c.is_active=1 ORDER BY c.code")
                print_header(f"BALANCE SHEET AS ON {as_on}")
                print(" [ASSETS]"); ta = sum(abs(float(r[2])) for r in assets)
                print(format_table(["Code","Account","Amount"],[(r[0],r[1],D(r[2])) for r in assets])); print(f" Total: {ta:.2f}\n")
                print(" [LIABILITIES]"); tl = sum(abs(float(r[2])) for r in liab)
                print(format_table(["Code","Account","Amount"],[(r[0],r[1],D(r[2])) for r in liab])); print(f" Total: {tl:.2f}\n")
                print(" [EQUITY]"); tq = sum(abs(float(r[2])) for r in equity)
                print(format_table(["Code","Account","Amount"],[(r[0],r[1],D(r[2])) for r in equity])); print(f" Total: {tq:.2f}")
                print(f"\n Liab+Equity: {tl+tq:.2f} | Assets: {ta:.2f}"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# FIXED ASSETS MANAGEMENT
# =====================================================================
class FixedAssetManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("FIXED ASSETS")
            print(" 1. View All\n 2. Add\n 3. Calc Depreciation\n 4. Depreciation Schedule\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, code, name, category, purchase_date, purchase_price, current_value, useful_life FROM fixed_assets WHERE is_active=1 ORDER BY code")
                print(format_table(["ID","Code","Name","Category","Date","Price","Current","Life"],[(r[0],r[1],r[2][:25],r[3] or "",r[4][:10] if r[4] else "",D(r[5]),D(r[6]),r[7]) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                code = input_str("Code"); nm = input_str("Name"); cat = input_str("Category", required=False)
                pd = input_str("Purchase Date", required=False); pp = float(input_dec("Purchase Price")); sv = float(input_dec("Salvage", required=False))
                ul = input_int("Useful Life (years)", min_val=1); loc = input_str("Location", required=False); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat()
                try: self.db.execute("INSERT INTO fixed_assets (code, name, category, purchase_date, purchase_price, salvage_value, useful_life, current_value, location, notes, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)", (code, nm, cat or None, pd or None, str(pp), str(sv), ul, str(pp), loc or None, notes, now)); self.audit.log("ADD_ASSET", f"{code}-{nm}"); print(" [+] Added!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                rows = self.db.fetch_all("SELECT id, code, name, purchase_price, salvage_value, useful_life, current_value FROM fixed_assets WHERE is_active=1 ORDER BY code")
                if not rows: print(" [!] No assets"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Code","Name","Purchase","Salvage","Life","Current"],[(r[0],r[1],r[2][:25],D(r[3]),D(r[4]),r[5],D(r[6])) for r in rows]))
                aid = input_int("Asset ID (0=all)")
                dep_date = datetime.date.today().isoformat()
                with self.db.conn:
                    assets = [self.db.fetch_one("SELECT * FROM fixed_assets WHERE id=?", (aid,))] if aid>0 else [self.db.fetch_one("SELECT * FROM fixed_assets WHERE id=?", (r[0],)) for r in rows]
                    for a in assets:
                        if not a: continue
                        cv = float(a['current_value']); sv = float(a['salvage_value']); ul = a['useful_life']
                        dep = (cv - sv) / ul if ul > 0 else 0
                        if dep <= 0 or cv <= sv: continue
                        acc = self.db.fetch_val("SELECT accumulated_dep FROM depreciation_entries WHERE asset_id=? ORDER BY id DESC LIMIT 1", (a["id"],)) or 0
                        na = float(acc) + dep; nv = cv - dep
                        self.db.execute("INSERT INTO depreciation_entries (asset_id, dep_date, amount, accumulated_dep) VALUES (?,?,?,?)", (a['id'], dep_date, str(dep), str(na)))
                        self.db.execute("UPDATE fixed_assets SET current_value=? WHERE id=?", (str(nv), a['id']))
                self.audit.log("DEPRECIATE", f"{'All' if aid==0 else aid} assets"); print(" [+] Depreciation recorded!"); input(" Press [Enter]...")
            elif c == '4':
                aid = input_int("Asset ID"); a = self.db.fetch_one("SELECT code, name FROM fixed_assets WHERE id=?", (aid,))
                if not a: print(" [!] Not found"); input(" Press [Enter]..."); continue
                rows = self.db.fetch_all("SELECT dep_date, amount, accumulated_dep FROM depreciation_entries WHERE asset_id=? ORDER BY dep_date", (aid,))
                print_header(f"Depreciation: {a['code']}-{a['name']}")
                print(format_table(["Date","Amount","Accum"],[(r[0][:10] if r[0] else "",D(r[1]),D(r[2])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# BUDGET MANAGEMENT
# =====================================================================
class BudgetManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("BUDGETS")
            print(" 1. View\n 2. Create\n 3. Details & Variance\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, name, fiscal_year, total_amount, is_active FROM budgets ORDER BY id DESC")
                print(format_table(["ID","Name","FY","Amount","Active"],[(r[0],r[1],r[2] or "",D(r[3]),"Yes" if r[4] else "No") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                nm = input_str("Name"); fy = input_str("Fiscal Year"); sd = input_str("Start"); ed = input_str("End")
                ta = float(input_dec("Total Amount")); now = datetime.datetime.now().isoformat()
                self.db.execute("INSERT INTO budgets (name, fiscal_year, start_date, end_date, total_amount, created_at) VALUES (?,?,?,?,?,?)", (nm, fy, sd, ed, str(ta), now))
                bid = self.db.db.conn.execute("SELECT last_insert_rowid()").fetchone()[0]
                print(" Add Budget Items:")
                accts = self.db.fetch_all("SELECT id, code, name FROM chart_of_accounts WHERE account_type IN ('INCOME','EXPENSE') AND is_active=1 ORDER BY code")
                print(format_table(["ID","Code","Account"],[(r[0],r[1],r[2]) for r in accts]))
                while True:
                    aid = input_int("Account ID (0=finish)")
                    if aid == 0: break
                    ba = float(input_dec("Budgeted Amount")); self.db.execute("INSERT INTO budget_items (budget_id, account_id, budgeted_amount) VALUES (?,?,?)", (bid, aid, str(ba))); print(" [+] Added")
                self.audit.log("CREATE_BUDGET", f"{nm} FY{fy}"); print(f" [+] Budget {nm} created!"); input(" Press [Enter]...")
            elif c == '3':
                bid = input_int("Budget ID"); b = self.db.fetch_one("SELECT * FROM budgets WHERE id=?", (bid,))
                if not b: print(" [!] Not found"); input(" Press [Enter]..."); continue
                print_header(f"Budget: {b['name']} ({b['fiscal_year']})")
                items = self.db.fetch_all("SELECT c.code, c.name, bi.budgeted_amount, bi.actual_amount FROM budget_items bi JOIN chart_of_accounts c ON c.id=bi.account_id WHERE bi.budget_id=?", (bid,))
                rows_out = []
                for r in items:
                    actual = self.db.fetch_val("SELECT COALESCE(SUM(CAST(gl.credit AS REAL)-CAST(gl.debit AS REAL)),0) FROM general_ledger gl WHERE gl.account_id=? AND gl.trans_date BETWEEN ? AND ?", (r[0], b["start_date"], b["end_date"])) or 0
                    bgt = float(r[2]); var = actual - bgt; vp = (actual/bgt*100) if bgt else 0
                    rows_out.append((r[0], r[1], D(bgt), D(actual), D(var), f"{vp:.1f}%"))
                    self.db.execute("UPDATE budget_items SET actual_amount=? WHERE budget_id=? AND account_id=?", (str(actual), bid, r[0]))
                print(format_table(["Code","Account","Budget","Actual","Var","%"],[(ro[0],ro[1],ro[2],ro[3],ro[4],ro[5]) for ro in rows_out]))
                input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# CASH REGISTER MANAGEMENT
# =====================================================================
class CashRegisterManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager', 'Cashier']): return
        while True:
            print_header("CASH REGISTER")
            print(" 1. View\n 2. Open\n 3. Close\n 4. Transactions\n 5. Add Transaction\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, name, opening_balance, current_balance, status, opening_date, closing_date FROM cash_registers ORDER BY id DESC")
                print(format_table(["ID","Name","Opening","Current","Status","Opened","Closed"],[(r[0],r[1],D(r[2]),D(r[3]),r[4],r[5][:10] if r[5] else "",r[6][:10] if r[6] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                nm = input_str("Name"); ob = float(input_dec("Opening Balance", required=False))
                now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                try: self.db.execute("INSERT INTO cash_registers (name, opening_balance, current_balance, opening_date, status, created_by, created_at) VALUES (?,?,?,?,'OPEN',?,?)", (nm, str(ob), str(ob), dt, self.auth.current_user['id'], now)); self.audit.log("OPEN_REG", f"{nm}"); print(" [+] Opened!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '3':
                regs = self.db.fetch_all("SELECT id, name, current_balance FROM cash_registers WHERE status='OPEN'")
                if not regs: print(" [!] None open"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Name","Balance"],[(r[0],r[1],D(r[2])) for r in regs]))
                rid = input_int("Register ID"); r = self.db.fetch_one("SELECT * FROM cash_registers WHERE id=? AND status='OPEN'", (rid,))
                if not r: print(" [!] Not found/closed"); input(" Press [Enter]..."); continue
                cc = float(input_dec("Closing Cash")); diff = cc - float(r['current_balance']); notes = input_str("Notes", required=False)
                now = datetime.datetime.now().isoformat(); dt = datetime.date.today().isoformat()
                self.db.execute("UPDATE cash_registers SET current_balance=?, closing_date=?, status='CLOSED' WHERE id=?", (str(cc), dt, rid))
                self.db.execute("INSERT INTO register_transactions (register_id, trans_type, amount, description, created_at) VALUES (?,?,?,?,?)", (rid, 'CLOSING', str(diff) if diff!=0 else '0.00', notes or f"Closed. Diff: {diff:.2f}", now))
                self.audit.log("CLOSE_REG", f"{r['name']} diff={diff:.2f}"); print(f" [+] Closed! Diff: {diff:.2f}"); input(" Press [Enter]...")
            elif c == '4':
                regs = self.db.fetch_all("SELECT id, name FROM cash_registers ORDER BY id")
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in regs]))
                rid = input_int("Register ID")
                rows = self.db.fetch_all("SELECT created_at, trans_type, amount, description FROM register_transactions WHERE register_id=? ORDER BY id DESC", (rid,))
                print_header("Transactions")
                print(format_table(["Date","Type","Amount","Desc"],[(r[0][:16] if r[0] else "",r[1],D(r[2]),r[3][:40] if r[3] else "") for r in rows]))
                input(" Press [Enter]...")
            elif c == '5':
                regs = self.db.fetch_all("SELECT id, name FROM cash_registers WHERE status='OPEN'")
                if not regs: print(" [!] None open"); input(" Press [Enter]..."); continue
                print(format_table(["ID","Name"],[(r[0],r[1]) for r in regs]))
                rid = input_int("Register ID"); tt = 'IN' if input(" [1]=In [2]=Out: ").strip()=='1' else 'OUT'
                amt = float(input_dec("Amount")); desc = input_str("Desc"); now = datetime.datetime.now().isoformat()
                with self.db.conn:
                    bal = self.db.fetch_val("SELECT current_balance FROM cash_registers WHERE id=?", (rid,)) or 0
                    nb = float(bal) + (amt if tt=='IN' else -amt); self.db.execute("UPDATE cash_registers SET current_balance=? WHERE id=?", (str(nb), rid))
                    self.db.execute("INSERT INTO register_transactions (register_id, trans_type, amount, description, created_at) VALUES (?,?,?,?,?)", (rid, tt, str(amt), desc, now))
                self.audit.log("REG_TXN", f"{tt} {amt:.2f} on {rid}"); print(" [+] Recorded!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# EMAIL CONFIGURATION
# =====================================================================
class EmailConfigManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin']): return
        while True:
            print_header("EMAIL CONFIG")
            print(" 1. View\n 2. Edit\n 3. Test (Placeholder)\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                r = self.db.fetch_one("SELECT * FROM email_config LIMIT 1")
                if not r: print(" No email config"); input(" Press [Enter]..."); continue
                print(f" Server: {r['smtp_server'] or 'N/A'}\n Port: {r['smtp_port']}\n User: {r['smtp_user'] or 'N/A'}\n Sender: {r['sender_email'] or 'N/A'} ({r['sender_name'] or 'N/A'})\n Active: {'Yes' if r['is_active'] else 'No'}"); input(" Press [Enter]...")
            elif c == '2':
                r = self.db.fetch_one("SELECT * FROM email_config LIMIT 1")
                if not r: self.db.execute("INSERT INTO email_config DEFAULT VALUES"); r = self.db.fetch_one("SELECT * FROM email_config LIMIT 1")
                sv = input_str("SMTP Server", required=False, default=r["smtp_server"] or "")
                sp = input_int("Port", default=r['smtp_port']); su = input_str("User", required=False, default=r['smtp_user'] or "")
                spw = input_str("Password", required=False, default=""); se = input_str("Sender Email", required=False, default=r["sender_email"] or "")
                sn = input_str("Sender Name", required=False, default=r["sender_name"] or "")
                self.db.execute("UPDATE email_config SET smtp_server=?, smtp_port=?, smtp_user=?, smtp_pass=?, sender_email=?, sender_name=?, is_active=1 WHERE id=?", (sv or None, sp, su or None, spw or r['smtp_pass'], se or None, sn or None, r['id']))
                self.audit.log("EDIT_EMAIL", "Updated"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '3':
                print(" NOTE: SMTP test placeholder. Full test requires smtplib integration."); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# HELP & SUPPORT
# =====================================================================
class HelpManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        while True:
            print_header("HELP & SUPPORT")
            print(" 1. Browse Topics\n 2. Search\n 3. Add Topic (Admin)\n 4. Edit Topic (Admin)\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                rows = self.db.fetch_all("SELECT id, topic FROM help_topics ORDER BY topic")
                print(format_table(["ID","Topic"],[(r[0],r[1]) for r in rows]))
                hid = input_int("Topic ID (0=back)")
                if hid > 0:
                    h = self.db.fetch_one("SELECT * FROM help_topics WHERE id=?", (hid,))
                    if h: print(f"\n{h['topic']}\n{'='*50}\n{h['content']}\nKeywords: {h['keywords']}"); input(" Press [Enter]...")
            elif c == '2':
                kw = input_str("Keyword")
                rows = self.db.fetch_all("SELECT id, topic, content FROM help_topics WHERE topic LIKE ? OR content LIKE ? OR keywords LIKE ?", (f"%{kw}%", f"%{kw}%", f"%{kw}%"))
                if not rows: print(" No results")
                else:
                    for r in rows: print(f"\n [{r[0]}] {r[1]}\n {r[2][:200]}...")
                input(" Press [Enter]...")
            elif c == '3':
                if not self.auth.require_role(['Admin']): continue
                topic = input_str("Topic"); content = input_str("Content", required=False); keywords = input_str("Keywords", required=False)
                try: self.db.execute("INSERT INTO help_topics (topic, content, keywords) VALUES (?,?,?)", (topic, content, keywords)); self.audit.log("ADD_HELP", f"{topic}"); print(" [+] Added!"); input(" Press [Enter]...")
                except Exception as e: print(f" [!] {e}"); input(" Press [Enter]...")
            elif c == '4':
                if not self.auth.require_role(['Admin']): continue
                hid = input_int("Topic ID"); h = self.db.fetch_one("SELECT * FROM help_topics WHERE id=?", (hid,))
                if not h: print(" [!] Not found"); input(" Press [Enter]..."); continue
                topic = input_str("Topic", default=h['topic']); content = input_str("Content", required=False, default=h['content'] or ""); keywords = input_str("Keywords", required=False, default=h['keywords'] or "")
                self.db.execute("UPDATE help_topics SET topic=?, content=?, keywords=? WHERE id=?", (topic, content, keywords, hid))
                self.audit.log("EDIT_HELP", f"{topic}"); print(" [+] Updated!"); input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# UTILITY FUNCTIONS
# =====================================================================
class UtilityManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin', 'Manager']): return
        while True:
            print_header("UTILITIES")
            print(" 1. Low Stock Report\n 2. Expired Products\n 3. DB Statistics\n 4. Bulk Price Update\n 5. Rebuild Stock\n 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                warn = self.db.get_setting('low_stock_warn','10')
                rows = self.db.fetch_all("SELECT code, name, current_stock FROM products WHERE CAST(current_stock AS REAL) <= CAST(? AS REAL) AND is_active=1 ORDER BY CAST(current_stock AS REAL) ASC", (warn,))
                print_header(f"LOW STOCK (<= {warn})")
                print(format_table(["Code","Product","Stock"],[(r[0],r[1],D(r[2])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '2':
                rows = self.db.fetch_all("SELECT p.code, p.name, p.expiry_date, p.current_stock FROM products p WHERE p.expiry_date IS NOT NULL AND p.expiry_date <= ? AND p.is_active=1 ORDER BY p.expiry_date", (datetime.date.today().isoformat(),))
                print_header("EXPIRED PRODUCTS")
                print(format_table(["Code","Product","Expiry","Stock"],[(r[0],r[1],r[2][:10] if r[2] else "",D(r[3])) for r in rows]))
                input(" Press [Enter]...")
            elif c == '3':
                print_header("DB STATISTICS")
                stats = [("Products",self.db.fetch_val("SELECT COUNT(*) FROM products") or 0),("Active",self.db.fetch_val("SELECT COUNT(*) FROM products WHERE is_active=1") or 0),("Customers",self.db.fetch_val("SELECT COUNT(*) FROM customers") or 0),("Suppliers",self.db.fetch_val("SELECT COUNT(*) FROM suppliers") or 0),("Sales",self.db.fetch_val("SELECT COUNT(*) FROM sales") or 0),("Purchases",self.db.fetch_val("SELECT COUNT(*) FROM purchases") or 0),("Users",self.db.fetch_val("SELECT COUNT(*) FROM users") or 0),("Categories",self.db.fetch_val("SELECT COUNT(*) FROM categories") or 0),("Brands",self.db.fetch_val("SELECT COUNT(*) FROM brands") or 0),("Units",self.db.fetch_val("SELECT COUNT(*) FROM units") or 0),("Accounts",self.db.fetch_val("SELECT COUNT(*) FROM cash_bank_accounts") or 0),("Employees",self.db.fetch_val("SELECT COUNT(*) FROM employees") or 0),("Service",self.db.fetch_val("SELECT COUNT(*) FROM service_jobs") or 0),("MFG",self.db.fetch_val("SELECT COUNT(*) FROM manufacturing_jobs") or 0),("Quotes",self.db.fetch_val("SELECT COUNT(*) FROM quotations") or 0),("SO",self.db.fetch_val("SELECT COUNT(*) FROM sales_orders") or 0),("PO",self.db.fetch_val("SELECT COUNT(*) FROM purchase_orders") or 0)]
                for s in stats: print(f"  {s[0].ljust(15)} {s[1]}")
                input(" Press [Enter]...")
            elif c == '4':
                print(" Bulk Price Update"); opt = input(" [1]=Increase % [2]=Set Fixed: ").strip()
                pct = float(input_dec("%", required=False)) if opt=='1' else 0; fp = float(input_dec("Fixed", required=False)) if opt=='2' else 0
                cat = input_str("Category ID (empty=all)", required=False)
                q = "SELECT id, sale_price FROM products WHERE is_active=1"; params = ()
                if cat: q += " AND category_id=?"; params = (cat,)
                rows = self.db.fetch_all(q, params)
                with self.db.conn:
                    for r in rows:
                        np_ = float(r[1])*(1+pct/100) if opt=='1' else fp; self.db.execute("UPDATE products SET sale_price=? WHERE id=?", (str(np_), r[0]))
                        self.db.execute("INSERT INTO product_price_history (product_id, old_price, new_price, changed_by, changed_at) VALUES (?,?,?,?,?)", (r[0], str(r[1]), str(np_), self.auth.current_user["id"], datetime.datetime.now().isoformat()))
                self.audit.log("BULK_PRICE", f"Updated {len(rows)} prods"); print(f" [+] Updated {len(rows)} products!"); input(" Press [Enter]...")
            elif c == '5':
                if input(" Rebuild from transactions? (Y/N): ").strip().upper() != 'Y': continue
                with self.db.conn:
                    self.db.execute("UPDATE products SET current_stock='0'")
                    for t, sgn in [("SELECT product_id, SUM(CAST(qty AS REAL)) FROM purchase_items GROUP BY product_id", "+"), ("SELECT product_id, SUM(CAST(qty AS REAL)) FROM purchase_return_items GROUP BY product_id", "-"), ("SELECT product_id, SUM(CAST(qty AS REAL)) FROM sale_items GROUP BY product_id", "-"), ("SELECT product_id, SUM(CAST(qty AS REAL)) FROM sale_return_items GROUP BY product_id", "+")]:
                        for r in (self.db.fetch_all(t) or []):
                            if r[0] and r[1]: self.db.execute(f"UPDATE products SET current_stock=CAST(CAST(current_stock AS REAL){sgn}? AS TEXT) WHERE id=?", (str(r[1]), r[0]))
                self.audit.log("REBUILD_STOCK", "Done"); print(" [+] Stock rebuilt!"); input(" Press [Enter]...")
            elif c == '0': break


class SecurityManager:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        while True:
            print_header("USERS & SECURITY MODULE")
            print(" 1. Add New System User")
            print(" 2. View / Edit Users & Roles")
            print(" 3. Change My Password")
            print(" 4. View System Audit Log")
            print(" 0. Back")
            c = input(" Select: ").strip()
            if c == '1':
                if not self.auth.require_role(['Admin']): continue
                uname = input_str("New Username")
                pw = input_str("Password")
                print(" Roles: [1] Admin  [2] Manager  [3] Cashier  [4] Viewer")
                rc = input(" Select Role: ").strip()
                role = "Admin" if rc=='1' else "Manager" if rc=='2' else "Cashier" if rc=='3' else "Viewer"
                force = 1 if input(" Force password change on login? (Y/N): ").strip().upper()=='Y' else 0
                h, s = self.auth.hash_pw(pw)
                now = datetime.datetime.now().isoformat()
                try:
                    self.db.execute("INSERT INTO users (username, password_hash, salt, role, is_active, force_password_change, created_at) VALUES (?, ?, ?, ?, 1, ?, ?)",
                                    (uname, h, s, role, force, now))
                    self.audit.log("ADD_USER", f"Created user {uname} ({role})")
                    print("\n [+] User created!"); input(" Press [Enter]...")
                except Exception: print(" [!] Username already exists."); input(" Press [Enter]...")
            elif c == '2':
                if not self.auth.require_role(['Admin']): continue
                rows = self.db.fetch_all("SELECT id, username, role, is_active, last_login FROM users")
                print(format_table(["ID", "Username", "Role", "Status", "Last Login"], [[r[0],r[1],r[2],"Active" if r[3]==1 else "Inactive",r[4][:16] if r[4] else "Never"] for r in rows]))
                uid = input_int("Enter User ID to Deactivate/Activate (0 to exit)")
                if uid > 0 and uid != self.auth.current_user['id']:
                    u = self.db.fetch_one("SELECT is_active FROM users WHERE id=?", (uid,))
                    if u: self.db.execute("UPDATE users SET is_active=? WHERE id=?", (0 if u[0]==1 else 1, uid))
            elif c == '3': self.auth.change_password()
            elif c == '4':
                if not self.auth.require_role(['Admin']): continue
                rows = self.db.fetch_all("SELECT timestamp, action, details FROM audit_logs ORDER BY id DESC LIMIT 50")
                print(format_table(["Time", "Action", "Details"], [[r[0][:16], r[1], r[2][:45]] for r in rows]))
                input(" Press [Enter]...")
            elif c == '0': break

# =====================================================================
# SALES ORDER MANAGEMENT
# =====================================================================
class SettingsController:
    def __init__(self, db, auth, audit):
        self.db = db; self.auth = auth; self.audit = audit

    def menu(self):
        if not self.auth.require_role(['Admin']): return
        while True:
            print_header("SHOP SETTINGS & CONFIGURATION")
            rows = self.db.fetch_all("SELECT * FROM settings ORDER BY k")
            print(format_table(["Setting Key", "Current Value"], [[r['k'], r['v']] for r in rows]))
            print("-" * 75)
            print(" 1. Edit Setting Value  |  0. Back")
            if input(" Select: ").strip() == '1':
                key = input_str("Enter Setting Key exactly as shown")
                if any(r['k']==key for r in rows):
                    val = input_str(f"Enter New Value for {key}")
                    self.db.set_setting(key, val)
                    self.audit.log("EDIT_SETTING", f"Updated {key} to {val}")
                else: print(" [!] Key not found.")
            else: break

# =====================================================================
# DASHBOARD CONTROLLER
# =====================================================================

class Dashboard:
    def __init__(self, db):
        self.db = db

    def show(self):
        today = datetime.date.today().isoformat()
        curr = self.db.get_setting('currency', '$')
        
        s_today = self.db.fetch_val("SELECT SUM(grand_total) FROM sales WHERE DATE(sale_date)=?", (today,)) or 0
        p_today = self.db.fetch_val("SELECT SUM(grand_total) FROM purchases WHERE purchase_date=?", (today,)) or 0
        c_in = self.db.fetch_val("SELECT SUM(amount) FROM cash_bank_transactions WHERE trans_type='IN' AND DATE(trans_date)=?", (today,)) or 0
        c_out = self.db.fetch_val("SELECT SUM(amount) FROM cash_bank_transactions WHERE trans_type='OUT' AND DATE(trans_date)=?", (today,)) or 0
        e_today = self.db.fetch_val("SELECT SUM(amount) FROM expenses WHERE exp_date=?", (today,)) or 0
        
        # Profit estimate today
        s_rev = self.db.fetch_val("SELECT SUM(si.total) FROM sale_items si JOIN sales s ON si.sale_id=s.id WHERE DATE(s.sale_date)=?", (today,)) or 0
        cogs = self.db.fetch_val("SELECT SUM(si.cost_price * si.qty) FROM sale_items si JOIN sales s ON si.sale_id=s.id WHERE DATE(s.sale_date)=?", (today,)) or 0
        profit = D(s_rev) - D(cogs) - D(e_today)
        
        warn_lvl = self.db.get_setting('low_stock_warn', '10')
        low_stk = self.db.fetch_val("SELECT COUNT(*) FROM products WHERE CAST(current_stock AS REAL) <= CAST(? AS REAL) AND is_active=1", (warn_lvl,)) or 0
        
        cust_bal = self.db.fetch_val("SELECT SUM(current_balance) FROM customers") or 0
        supp_bal = self.db.fetch_val("SELECT SUM(current_balance) FROM suppliers") or 0
        avail_cash = self.db.fetch_val("SELECT SUM(balance) FROM cash_bank_accounts WHERE is_active=1") or 0
        
        pend_s = self.db.fetch_val("SELECT SUM(balance_amount) FROM sales WHERE CAST(balance_amount AS REAL) > 0") or 0
        pend_p = self.db.fetch_val("SELECT SUM(balance_amount) FROM purchases WHERE CAST(balance_amount AS REAL) > 0") or 0

        print_header("EXECUTIVE SYSTEM DASHBOARD")
        print(f" Date: {today.ljust(25)} Shop: {self.db.get_setting('shop_name','')[:35]}")
        print("-" * 75)
        print(f" Today Sales:    {curr}{D(s_today):<16} Today Purchases:  {curr}{D(p_today)}")
        print(f" Cash Received:  {curr}{D(c_in):<16} Cash Paid Out:    {curr}{D(c_out)}")
        print(f" Today Expenses: {curr}{D(e_today):<16} Est. Net Profit:  {curr}{profit}")
        print("-" * 75)
        print(f" Low Stock Items:{low_stk:<17} Available Cash:   {curr}{D(avail_cash)}")
        print(f" Cust Balances:  {curr}{D(cust_bal):<16} Supp Payables:    {curr}{D(supp_bal)}")
        print(f" Pending Sales:  {curr}{D(pend_s):<16} Pending Pur:      {curr}{D(pend_p)}")
        print("=" * 75)
        input(" Press [Enter] to return to Main Menu...")

# =====================================================================
# MAIN APPLICATION CONTROLLER
# =====================================================================

class ShopManagerApp:
    def __init__(self):
        self.db = Database()
        self.auth = AuthManager(self.db)
        self.audit = AuditManager(self.db, self.auth)
        
        self.dash = Dashboard(self.db)
        self.sales = TradeManager(self.db, self.auth, self.audit, 'SALES')
        self.purchases = TradeManager(self.db, self.auth, self.audit, 'PURCHASES')
        self.masters = MasterManager(self.db, self.auth, self.audit)
        self.customers = PartyManager(self.db, self.auth, self.audit, 'customers')
        self.suppliers = PartyManager(self.db, self.auth, self.audit, 'suppliers')
        self.finance = FinanceManager(self.db, self.auth, self.audit)
        self.expenses = ExpenseManager(self.db, self.auth, self.audit)
        self.reports = ReportManager(self.db, self.auth)
        self.settings = SettingsController(self.db, self.auth, self.audit)
        self.security = SecurityManager(self.db, self.auth, self.audit)
        self.backups = BackupManager(self.db, self.auth, self.audit)
        self.io = IOManager(self.db, self.auth, self.audit)
        self.warehouse = WarehouseManager(self.db, self.auth, self.audit)
        self.quotations = QuotationManager(self.db, self.auth, self.audit)
        self.sales_orders = SalesOrderManager(self.db, self.auth, self.audit)
        self.purchase_orders = PurchaseOrderManager(self.db, self.auth, self.audit)
        self.challans = DeliveryChallanManager(self.db, self.auth, self.audit)
        self.credit_debit = CreditDebitManager(self.db, self.auth, self.audit)
        self.employees = EmployeeManager(self.db, self.auth, self.audit)
        self.commissions = CommissionManager(self.db, self.auth, self.audit)
        self.loyalty = LoyaltyManager(self.db, self.auth, self.audit)
        self.price_lists = PriceListManager(self.db, self.auth, self.audit)
        self.promotions = PromotionManager(self.db, self.auth, self.audit)
        self.serials = SerialNumberManager(self.db, self.auth, self.audit)
        self.service = ServiceManager(self.db, self.auth, self.audit)
        self.bom = BOManager(self.db, self.auth, self.audit)
        self.manufacturing = ManufacturingManager(self.db, self.auth, self.audit)
        self.accounting = AccountingManager(self.db, self.auth, self.audit)
        self.financial = FinancialStatementManager(self.db, self.auth, self.audit)
        self.assets = FixedAssetManager(self.db, self.auth, self.audit)
        self.budgets = BudgetManager(self.db, self.auth, self.audit)
        self.cash_register = CashRegisterManager(self.db, self.auth, self.audit)
        self.email_cfg = EmailConfigManager(self.db, self.auth, self.audit)
        self.help = HelpManager(self.db, self.auth, self.audit)
        self.utilities = UtilityManager(self.db, self.auth, self.audit)

    def run(self):
        setup_console()
        while True:
            if not self.auth.current_user:
                if not self.auth.login():
                    continue
            self.main_menu()

    def main_menu(self):
        while self.auth.current_user:
            u = self.auth.current_user
            print_header(f"MAIN MENU - Logged in as: {u['username']} ({u['role']})")
            items = [
                ("1",  "Dashboard & Today Summary"),
                ("2",  "Sales / POS Terminal"),
                ("3",  "Products & Inventory Masters"),
                ("4",  "Customers & Khata Ledger"),
                ("5",  "Reports & Analytics"),
                ("6",  "Purchases Management"),
                ("7",  "Suppliers & Khata Ledger"),
                ("8",  "Cash & Bank Accounts"),
                ("9",  "Expenses Manager"),
                ("10", "Returns Processing"),
                ("11", "Shop Settings"),
                ("12", "Users & Security Control"),
                ("13", "Backup & Restore DB"),
                ("14", "Import / Export Data CSV"),
                ("15", "Quotations"),
                ("16", "Sales Orders"),
                ("17", "Purchase Orders"),
                ("18", "Delivery Challans"),
                ("19", "Warehouses & Stock Transfer"),
                ("20", "Credit / Debit Notes"),
                ("21", "Employees"),
                ("22", "Commissions"),
                ("23", "Loyalty Points"),
                ("24", "Price Lists"),
                ("25", "Promotions & Coupons"),
                ("26", "Serial Numbers"),
                ("27", "Service / Repair Jobs"),
                ("28", "Bill of Materials"),
                ("29", "Manufacturing Jobs"),
                ("30", "Accounting (Chart / Ledger)"),
                ("31", "Financial Statements"),
                ("32", "Fixed Assets"),
                ("33", "Budgets"),
                ("34", "Cash Register"),
                ("35", "Email Config"),
                ("36", "Help & Support"),
                ("37", "Utility Functions"),
                ("38", "Logout"),
            ]
            mid = (len(items) + 1) // 2
            col1 = items[:mid]
            col2 = items[mid:]
            for i in range(len(col1)):
                left = f"{col1[i][0]:>2}. {col1[i][1]}"
                right = f"{col2[i][0]:>2}. {col2[i][1]}" if i < len(col2) else ""
                print(f"  {left:<38}  {right:<38}")
            print("  S. Global Quick Search                        0. Exit Application Safely")
            print("-" * 75)
            c = input(" Select Option: ").strip().upper()

            if c == '1': self.dash.show()
            elif c == '2': self.sales.menu()
            elif c == '3': self.masters.menu()
            elif c == '4': self.customers.menu()
            elif c == '5': self.reports.menu()
            elif c == '6': self.purchases.menu()
            elif c == '7': self.suppliers.menu()
            elif c == '8': self.finance.menu()
            elif c == '9': self.expenses.menu()
            elif c == '10': self.returns_menu()
            elif c == '11': self.settings.menu()
            elif c == '12': self.security.menu()
            elif c == '13': self.backups.menu()
            elif c == '14': self.io.menu()
            elif c == '15': self.quotations.menu()
            elif c == '16': self.sales_orders.menu()
            elif c == '17': self.purchase_orders.menu()
            elif c == '18': self.challans.menu()
            elif c == '19': self.warehouse.menu()
            elif c == '20': self.credit_debit.menu()
            elif c == '21': self.employees.menu()
            elif c == '22': self.commissions.menu()
            elif c == '23': self.loyalty.menu()
            elif c == '24': self.price_lists.menu()
            elif c == '25': self.promotions.menu()
            elif c == '26': self.serials.menu()
            elif c == '27': self.service.menu()
            elif c == '28': self.bom.menu()
            elif c == '29': self.manufacturing.menu()
            elif c == '30': self.accounting.menu()
            elif c == '31': self.financial.menu()
            elif c == '32': self.assets.menu()
            elif c == '33': self.budgets.menu()
            elif c == '34': self.cash_register.menu()
            elif c == '35': self.email_cfg.menu()
            elif c == '36': self.help.menu()
            elif c == '37': self.utilities.menu()
            elif c == '38': self.auth.logout(self.audit)
            elif c == 'S': self.global_search()
            elif c == '0':
                if self.db.get_setting('auto_backup_exit','1')=='1':
                    self.backups.backup(auto=True)
                print("\n [+] Thank you for using Shop Manager. Goodbye!\n")
                sys.exit(0)

    def returns_menu(self):
        print_header("RETURNS PROCESSING MODULE")
        print(" 1. Process Customer Sale Return")
        print(" 2. Process Supplier Purchase Return")
        print(" 0. Back")
        c = input(" Select: ").strip()
        if c == '1': self.sales.process_return()
        elif c == '2': self.purchases.process_return()

    def global_search(self):
        print_header("GLOBAL SEARCH")
        q = input_str("Enter keyword (SKU, Name, Phone, Inv No)")
        curr = self.db.get_setting('currency', '$')
        
        print("\n [Products Found]")
        prods = self.db.fetch_all("SELECT code, name, current_stock, sale_price FROM products WHERE code LIKE ? OR name LIKE ?", (f"%{q}%", f"%{q}%"))
        for p in prods[:5]: print(f"  SKU: {p[0]} | {p[1]} | Stock: {D(p[2])} | Price: {curr}{D(p[3])}")
        
        print("\n [Parties Found]")
        pty = self.db.fetch_all("SELECT code, name, phone, current_balance FROM customers WHERE name LIKE ? OR phone LIKE ? UNION SELECT code, name, phone, current_balance FROM suppliers WHERE name LIKE ? OR phone LIKE ?", (f"%{q}%",f"%{q}%",f"%{q}%",f"%{q}%"))
        for pt in pty[:5]: print(f"  {pt[0]} | {pt[1]} ({pt[2]}) | Bal: {curr}{D(pt[3])}")
        
        print("\n [Invoices Found]")
        invs = self.db.fetch_all("SELECT invoice_no, sale_date, grand_total FROM sales WHERE invoice_no LIKE ? UNION SELECT invoice_no, purchase_date, grand_total FROM purchases WHERE invoice_no LIKE ?", (f"%{q}%", f"%{q}%"))
        for iv in invs[:5]: print(f"  Inv: {iv[0]} | Date: {iv[1][:10]} | Total: {curr}{D(iv[2])}")
        
        input("\n Press [Enter]...")

if __name__ == '__main__':
    app = ShopManagerApp()
    app.run()