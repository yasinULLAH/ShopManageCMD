@echo off
:: ShopManager.cmd - Integrated Shop Management System
:: Requirements: Python 3.x installed on Windows.
:: This script extracts and runs an embedded Python application.

setlocal enabledelayedexpansion
set "PY_FILE=%~dp0shop_app.py"

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python 3 is required to run this application.
    pause
    exit /b
)

:: Run Python script (The script is embedded below)
python -x "%~f0" %*
goto :eof

'''
'''
# <Python Code Starts Here>
import os
import sys
import sqlite3
import csv
import hashlib
import uuid
import json
import shutil
from datetime import datetime, date
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from textwrap import fill

# --- Constants & Config ---
DB_NAME = "shop_manager.db"
VERSION = "1.0.0"

# --- Database Setup ---
def get_db():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    
    # Tables
    cursor.executescript('''
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        );

        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password_hash TEXT,
            salt TEXT,
            role TEXT, -- Admin, Manager, Cashier, Viewer
            active INTEGER DEFAULT 1,
            last_login TEXT,
            force_pw_change INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY, name TEXT UNIQUE);
        CREATE TABLE IF NOT EXISTS brands (id INTEGER PRIMARY KEY, name TEXT UNIQUE);
        CREATE TABLE IF NOT EXISTS units (id INTEGER PRIMARY KEY, name TEXT UNIQUE);

        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE,
            barcode TEXT UNIQUE,
            name TEXT,
            category_id INTEGER,
            brand_id INTEGER,
            unit_id INTEGER,
            purchase_price TEXT,
            sale_price TEXT,
            wholesale_price TEXT,
            min_stock INTEGER DEFAULT 5,
            current_stock REAL DEFAULT 0,
            tax_percent TEXT DEFAULT '0',
            active INTEGER DEFAULT 1,
            FOREIGN KEY(category_id) REFERENCES categories(id),
            FOREIGN KEY(brand_id) REFERENCES brands(id),
            FOREIGN KEY(unit_id) REFERENCES units(id)
        );

        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE,
            name TEXT,
            phone TEXT,
            address TEXT,
            balance TEXT DEFAULT '0',
            credit_limit TEXT DEFAULT '10000',
            active INTEGER DEFAULT 1
        );

        CREATE TABLE IF NOT EXISTS suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT UNIQUE,
            name TEXT,
            phone TEXT,
            balance TEXT DEFAULT '0',
            active INTEGER DEFAULT 1
        );

        CREATE TABLE IF NOT EXISTS sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT UNIQUE,
            customer_id INTEGER,
            total_amount TEXT,
            discount TEXT,
            tax TEXT,
            grand_total TEXT,
            paid_amount TEXT,
            payment_method TEXT,
            created_at TEXT,
            created_by INTEGER
        );

        CREATE TABLE IF NOT EXISTS sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER,
            product_id INTEGER,
            qty REAL,
            price TEXT,
            subtotal TEXT
        );

        CREATE TABLE IF NOT EXISTS purchases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT UNIQUE,
            supplier_id INTEGER,
            grand_total TEXT,
            paid_amount TEXT,
            created_at TEXT
        );

        CREATE TABLE IF NOT EXISTS purchase_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            purchase_id INTEGER,
            product_id INTEGER,
            qty REAL,
            price TEXT
        );

        CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_type TEXT, -- CUSTOMER, SUPPLIER, CASH, BANK
            account_id INTEGER,
            type TEXT, -- DEBIT, CREDIT
            amount TEXT,
            description TEXT,
            created_at TEXT
        );

        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount TEXT,
            description TEXT,
            created_at TEXT
        );

        CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            action TEXT,
            details TEXT,
            created_at TEXT
        );
    ''')

    # Default Settings
    defaults = {
        "shop_name": "My Desktop Shop",
        "currency": "$",
        "low_stock_lvl": "5",
        "invoice_prefix": "INV-",
        "tax_enabled": "0"
    }
    for k, v in defaults.items():
        cursor.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", (k, v))

    # Default Admin
    cursor.execute("SELECT count(*) FROM users")
    if cursor.fetchone()[0] == 0:
        salt = uuid.uuid4().hex
        pw_hash = hashlib.sha256((salt + "admin123").encode()).hexdigest()
        cursor.execute("INSERT INTO users (username, password_hash, salt, role) VALUES (?,?,?,?)",
                       ("admin", pw_hash, salt, "Admin"))
    
    conn.commit()
    conn.close()

# --- Helper Logic ---
class Session:
    user = None

def clear():
    os.system('cls' if os.name == 'nt' else 'clear')

def h_line(): print("-" * 60)

def input_d(prompt):
    val = input(prompt).strip()
    try: return Decimal(val) if val else Decimal('0')
    except: return Decimal('0')

def hash_pw(password, salt=None):
    if not salt: salt = uuid.uuid4().hex
    return hashlib.sha256((salt + password).encode()).hexdigest(), salt

def log_action(action, details=""):
    conn = get_db()
    conn.execute("INSERT INTO audit_logs (user_id, action, details, created_at) VALUES (?,?,?,?)",
                 (Session.user['id'] if Session.user else 0, action, details, datetime.now().isoformat()))
    conn.commit()
    conn.close()

# --- Modules ---

def login():
    clear()
    print("=== SHOP MANAGEMENT SYSTEM LOGIN ===")
    u = input("Username: ")
    p = input("Password: ")
    
    conn = get_db()
    user = conn.execute("SELECT * FROM users WHERE username = ? AND active = 1", (u,)).fetchone()
    conn.close()

    if user:
        phash = hashlib.sha256((user['salt'] + p).encode()).hexdigest()
        if phash == user['password_hash']:
            Session.user = user
            log_action("LOGIN", "User logged in")
            return True
    print("Invalid credentials.")
    input("Press Enter...")
    return False

def dashboard():
    clear()
    conn = get_db()
    today = date.today().isoformat()
    
    sales_today = conn.execute("SELECT SUM(grand_total) FROM sales WHERE date(created_at) = ?", (today,)).fetchone()[0] or 0
    purch_today = conn.execute("SELECT SUM(grand_total) FROM purchases WHERE date(created_at) = ?", (today,)).fetchone()[0] or 0
    low_stock = conn.execute("SELECT COUNT(*) FROM products WHERE current_stock <= min_stock").fetchone()[0]
    
    print(f"--- DASHBOARD ({today}) ---")
    print(f"Sales Today:    {sales_today}")
    print(f"Purchases Today: {purch_today}")
    print(f"Low Stock Items: {low_stock}")
    h_line()
    conn.close()
    input("Press Enter to return...")

def pos_sale():
    clear()
    print("--- NEW SALE (POS) ---")
    conn = get_db()
    
    items = []
    while True:
        code = input("Product Code/Barcode (or 'f' to finish): ")
        if code.lower() == 'f': break
        
        prod = conn.execute("SELECT * FROM products WHERE code = ? OR barcode = ?", (code, code)).fetchone()
        if not prod:
            print("Product not found.")
            continue
            
        qty = input_d(f"Quantity for {prod['name']} (Stock: {prod['current_stock']}): ")
        if qty <= 0: continue
        if qty > Decimal(str(prod['current_stock'])):
            print("Insufficient stock!")
            continue
            
        items.append({'id': prod['id'], 'name': prod['name'], 'qty': qty, 'price': Decimal(prod['sale_price'])})
        print(f"Added. Subtotal: {qty * Decimal(prod['sale_price'])}")

    if not items: return

    total = sum(i['qty'] * i['price'] for i in items)
    print(f"Total Amount: {total}")
    paid = input_d("Paid Amount: ")
    
    # Transactional save
    try:
        inv_no = "INV-" + uuid.uuid4().hex[:6].upper()
        conn.execute("INSERT INTO sales (invoice_no, total_amount, grand_total, paid_amount, created_at, created_by) VALUES (?,?,?,?,?,?)",
                     (inv_no, str(total), str(total), str(paid), datetime.now().isoformat(), Session.user['id']))
        s_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        
        for i in items:
            conn.execute("INSERT INTO sale_items (sale_id, product_id, qty, price, subtotal) VALUES (?,?,?,?,?)",
                         (s_id, i['id'], float(i['qty']), str(i['price']), str(i['qty']*i['price'])))
            conn.execute("UPDATE products SET current_stock = current_stock - ? WHERE id = ?", (float(i['qty']), i['id']))
        
        conn.commit()
        print(f"Sale Completed! Invoice: {inv_no}")
        log_action("SALE", f"Invoice {inv_no} created")
    except Exception as e:
        conn.rollback()
        print(f"Error processing sale: {e}")
    
    conn.close()
    input("Press Enter...")

def manage_products():
    while True:
        clear()
        print("--- PRODUCT MANAGEMENT ---")
        print("1. View Products")
        print("2. Add Product")
        print("3. Adjust Stock")
        print("0. Back")
        choice = input(">> ")
        
        conn = get_db()
        if choice == '1':
            prods = conn.execute("SELECT * FROM products").fetchall()
            print(f"{'Code':<10} {'Name':<20} {'Price':<10} {'Stock':<10}")
            h_line()
            for p in prods:
                print(f"{p['code']:<10} {p['name']:<20} {p['sale_price']:<10} {p['current_stock']:<10}")
            input("\nPress Enter...")
        elif choice == '2':
            name = input("Name: ")
            code = input("Code: ")
            price = input("Sale Price: ")
            stock = input("Initial Stock: ")
            conn.execute("INSERT INTO products (name, code, sale_price, current_stock) VALUES (?,?,?,?)", (name, code, price, stock))
            conn.commit()
            log_action("PROD_ADD", f"Added {name}")
        elif choice == '0':
            conn.close()
            break
        conn.close()

def reports_menu():
    clear()
    print("--- REPORTS ---")
    print("1. Inventory Report")
    print("2. Sales Report (All)")
    print("3. Export Products to CSV")
    choice = input(">> ")
    
    conn = get_db()
    if choice == '1':
        prods = conn.execute("SELECT name, current_stock, sale_price FROM products").fetchall()
        for p in prods:
            print(f"{p[0]}: {p[1]} in stock. Value: {float(p[1])*float(p[2])}")
    elif choice == '2':
        sales = conn.execute("SELECT invoice_no, grand_total, created_at FROM sales").fetchall()
        for s in sales:
            print(f"{s[0]} | {s[1]} | {s[2]}")
    elif choice == '3':
        prods = conn.execute("SELECT * FROM products").fetchall()
        with open("products_export.csv", "w", newline='') as f:
            writer = csv.writer(f)
            writer.writerow(['ID', 'Code', 'Name', 'Price', 'Stock'])
            for p in prods: writer.writerow([p['id'], p['code'], p['name'], p['sale_price'], p['current_stock']])
        print("Exported to products_export.csv")
    
    conn.close()
    input("\nPress Enter...")

def backup_db():
    try:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        shutil.copy(DB_NAME, f"backup_{ts}.db")
        print(f"Backup created: backup_{ts}.db")
    except Exception as e:
        print(f"Backup failed: {e}")
    input("Press Enter...")

def main_menu():
    while True:
        clear()
        print(f"=== {DB_NAME} - SHOP MANAGER v{VERSION} ===")
        print(f"User: {Session.user['username']} [{Session.user['role']}]")
        h_line()
        print("1. Dashboard")
        print("2. Sales (POS)")
        print("3. Product Management")
        print("4. Reports / Export")
        print("5. Database Backup")
        print("6. Logout")
        print("0. Exit")
        
        choice = input("Select Option: ")
        
        if choice == '1': dashboard()
        elif choice == '2': pos_sale()
        elif choice == '3': manage_products()
        elif choice == '4': reports_menu()
        elif choice == '5': backup_db()
        elif choice == '6': 
            Session.user = None
            return True
        elif choice == '0': return False

if __name__ == "__main__":
    init_db()
    while True:
        if not Session.user:
            if not login():
                continue
        if not main_menu():
            break
# <Python Code Ends Here>