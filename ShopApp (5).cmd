@echo off
title Shop Management System
set "CMD_DIR=%~dp0"
python -c "import sys,os; lines=open(sys.argv[1],encoding='utf-8').readlines(); open(sys.argv[2],'w',encoding='utf-8').writelines(lines[12:]);" "%~f0" "%TEMP%\ShopManager_app.py"
if errorlevel 1 (
    echo Error extracting script. Ensure Python is installed and in PATH.
    pause
    exit /b
)
python "%TEMP%\ShopManager_app.py" "%CMD_DIR%"
del "%TEMP%\ShopManager_app.py"
exit /b
# --- Python Code Starts Below ---
import sys, os, sqlite3, csv, datetime, hashlib, getpass, shutil, textwrap, uuid, decimal, json, pathlib

DB = None
USER = None
CMD_DIR = ""
DB_PATH = ""

def now(): return datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
def now_date(): return datetime.datetime.now().strftime("%Y-%m-%d")
def D(v): return decimal.Decimal(str(v)) if v is not None else decimal.Decimal('0')

def get_pwd(prompt):
    try: return getpass.getpass(prompt)
    except: return input(prompt + " (typing visible): ")

def get_decimal(prompt, allow_zero=True):
    while True:
        val = input(prompt).strip()
        if not val:
            if allow_zero: return D('0')
            print("Cannot be empty."); continue
        try:
            d = D(val)
            if not allow_zero and d <= 0: print("Must be > 0."); continue
            return d
        except: print("Invalid number.")

def hash_password(password, salt=None):
    if not salt: salt = uuid.uuid4().hex
    return hashlib.sha256((salt + password).encode('utf-8')).hexdigest(), salt

def check_password(password, salt, hash_val):
    h, _ = hash_password(password, salt)
    return h == hash_val

def audit(action, details=""):
    uid = USER['id'] if USER else 0
    DB.execute("INSERT INTO audit_logs (user_id, action, details, timestamp) VALUES (?,?,?,?)", (uid, action, details, now()))
    DB.commit()

def get_setting(key, default=""):
    r = DB.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
    return r['value'] if r else default

def set_setting(key, val):
    DB.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, val))
    DB.commit()

def setting_bool(key): return get_setting(key, "0") == "1"

def menu(title, options):
    while True:
        print(f"\n--- {title} ---")
        for k, v in options.items(): print(f"{k}. {v[0]}")
        print("0. Back")
        choice = input("Choice: ").strip()
        if choice == '0': return
        if choice in options:
            try: options[choice][1]()
            except SystemExit: raise
            except Exception as e: print(f"Error: {e}"); input("Press Enter...")
        else: print("Invalid choice.")

def check_access(feature, func):
    role = USER['role']
    if role in ['Admin', 'Manager']: func()
    elif role == 'Cashier' and feature in ['POS', 'CUSTOMERS', 'REPORTS']: func()
    elif role == 'Viewer' and feature in ['DASHBOARD', 'REPORTS']: func()
    else: print("Access Denied."); input("Press Enter...")

SCHEMA = """
CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password_hash TEXT, salt TEXT, role TEXT, is_active INTEGER DEFAULT 1, force_pwd_change INTEGER DEFAULT 0, last_login TEXT, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS brands (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS units (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS products (id INTEGER PRIMARY KEY AUTOINCREMENT, sku TEXT UNIQUE, barcode TEXT, name TEXT, category_id INTEGER, brand_id INTEGER, unit_id INTEGER, purchase_price REAL, sale_price REAL, wholesale_price REAL, retail_price REAL, min_stock REAL DEFAULT 0, current_stock REAL DEFAULT 0, tax_pct REAL DEFAULT 0, discount_allowed INTEGER DEFAULT 1, expiry_date TEXT, batch_no TEXT, rack_location TEXT, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS customers (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE, name TEXT, phone TEXT, address TEXT, email TEXT, opening_balance REAL DEFAULT 0, current_balance REAL DEFAULT 0, credit_limit REAL DEFAULT 0, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS suppliers (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE, name TEXT, phone TEXT, address TEXT, email TEXT, opening_balance REAL DEFAULT 0, current_balance REAL DEFAULT 0, is_active INTEGER DEFAULT 1, created_at TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS purchases (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_no TEXT UNIQUE, supplier_id INTEGER, date TEXT, subtotal REAL, discount REAL DEFAULT 0, tax REAL DEFAULT 0, freight REAL DEFAULT 0, grand_total REAL, paid_amount REAL, balance_amount REAL, payment_method TEXT, notes TEXT, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS purchase_items (id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER, product_id INTEGER, quantity REAL, purchase_price REAL, discount REAL DEFAULT 0, tax REAL DEFAULT 0, batch_no TEXT, expiry_date TEXT, total REAL);
CREATE TABLE IF NOT EXISTS sales (id INTEGER PRIMARY KEY AUTOINCREMENT, invoice_no TEXT UNIQUE, customer_id INTEGER, date TEXT, subtotal REAL, discount REAL DEFAULT 0, tax REAL DEFAULT 0, grand_total REAL, paid_amount REAL, balance_amount REAL, payment_method TEXT, notes TEXT, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, product_id INTEGER, quantity REAL, sale_price REAL, discount REAL DEFAULT 0, tax REAL DEFAULT 0, total REAL);
CREATE TABLE IF NOT EXISTS sale_returns (id INTEGER PRIMARY KEY AUTOINCREMENT, return_no TEXT UNIQUE, sale_id INTEGER, date TEXT, grand_total REAL, reason TEXT, refund_method TEXT, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS sale_return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER, product_id INTEGER, quantity REAL, sale_price REAL, total REAL);
CREATE TABLE IF NOT EXISTS purchase_returns (id INTEGER PRIMARY KEY AUTOINCREMENT, return_no TEXT UNIQUE, purchase_id INTEGER, date TEXT, grand_total REAL, reason TEXT, refund_method TEXT, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS purchase_return_items (id INTEGER PRIMARY KEY AUTOINCREMENT, return_id INTEGER, product_id INTEGER, quantity REAL, purchase_price REAL, total REAL);
CREATE TABLE IF NOT EXISTS stock_movements (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, date TEXT, type TEXT, quantity REAL, ref_id INTEGER, notes TEXT);
CREATE TABLE IF NOT EXISTS expenses (id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, description TEXT, amount REAL, payment_method TEXT, date TEXT, paid_to TEXT, notes TEXT, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS cash_bank_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, type TEXT, account TEXT, amount REAL, description TEXT, ref_type TEXT, ref_id INTEGER, created_by INTEGER, created_at TEXT);
CREATE TABLE IF NOT EXISTS audit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, action TEXT, details TEXT, timestamp TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS product_price_history (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, old_price REAL, new_price REAL, changed_by INTEGER, changed_at TEXT);
CREATE TABLE IF NOT EXISTS ledgers (id INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT, entity_id INTEGER, date TEXT, type TEXT, ref_id INTEGER, amount REAL, balance REAL, notes TEXT);
"""

def init_db():
    DB.executescript(SCHEMA)
    if not DB.execute("SELECT COUNT(*) as c FROM users").fetchone()['c']:
        h, s = hash_password("admin123")
        DB.execute("INSERT INTO users (username, password_hash, salt, role, force_pwd_change, created_at) VALUES (?,?,?,?,?,?)", ("admin", h, s, "Admin", 1, now()))
        DB.commit()

def login():
    print("--- LOGIN ---")
    for _ in range(3):
        u = input("Username: ").strip()
        p = get_pwd("Password: ")
        row = DB.execute("SELECT * FROM users WHERE username=?", (u,)).fetchone()
        if row and check_password(p, row['salt'], row['password_hash']) and row['is_active']:
            global USER
            USER = dict(row)
            DB.execute("UPDATE users SET last_login=? WHERE id=?", (now(), row['id']))
            DB.commit()
            audit("LOGIN")
            if row['force_pwd_change']: change_password()
            return True
        print("Invalid credentials or inactive user.")
    return False

def change_password():
    while True:
        old = get_pwd("Old Password: ")
        if not check_password(old, USER['salt'], USER['password_hash']): print("Incorrect."); continue
        n1 = get_pwd("New Password: ")
        n2 = get_pwd("Confirm: ")
        if n1 != n2 or len(n1) < 4: print("Mismatch/Short."); continue
        h, s = hash_password(n1)
        DB.execute("UPDATE users SET password_hash=?, salt=?, force_pwd_change=0 WHERE id=?", (h, s, USER['id']))
        DB.commit()
        USER['password_hash'], USER['salt'], USER['force_pwd_change'] = h, s, 0
        print("Changed."); break

def simple_add(table, field, prompt):
    val = input(prompt).strip()
    if not val: return
    try:
        DB.execute(f"INSERT INTO {table} ({field}, created_at) VALUES (?, ?)", (val, now()))
        DB.commit(); audit(f"Added {table}: {val}"); print("Added.")
    except: print("Exists.")

def simple_view(table, field):
    rows = DB.execute(f"SELECT id, {field} FROM {table} WHERE is_active=1").fetchall()
    for r in rows: print(f"[{r['id']}] {r[field]}")

def simple_edit(table, field, prompt):
    simple_view(table, field)
    try:
        id = int(input("ID: "))
        val = input(f"New {prompt}: ").strip()
        DB.execute(f"UPDATE {table} SET {field}=? WHERE id=?", (val, id))
        DB.commit(); print("Updated.")
    except: print("Error.")

def simple_delete(table, field):
    simple_view(table, field)
    try:
        id = int(input("ID to deactivate: "))
        DB.execute(f"UPDATE {table} SET is_active=0 WHERE id=?", (id,))
        DB.commit(); print("Deactivated.")
    except: print("Error.")

def sub_crud(table, field, prompt):
    menu(f"Manage {table.title()}", {
        '1': ("Add", lambda: simple_add(table, field, prompt)),
        '2': ("View", lambda: simple_view(table, field)),
        '3': ("Edit", lambda: simple_edit(table, field, prompt)),
        '4': ("Deactivate", lambda: simple_delete(table, field))
    })

def select_id(table, prompt):
    rows = DB.execute(f"SELECT id, name FROM {table} WHERE is_active=1").fetchall()
    if not rows: print(f"No {prompt}s."); return None
    for r in rows: print(f"[{r['id']}] {r['name']}")
    while True:
        val = input(f"Select {prompt} ID (0=none): ").strip()
        if not val: continue
        try:
            i = int(val)
            if i == 0: return None
            if any(r['id'] == i for r in rows): return i
        except: pass
        print("Invalid.")

def add_product():
    sku = input("SKU: ").strip()
    name = input("Name: ").strip()
    if not sku or not name: return
    cat = select_id("categories", "Category")
    br = select_id("brands", "Brand")
    un = select_id("units", "Unit")
    pp = float(get_decimal("Purchase Price: "))
    sp = float(get_decimal("Sale Price: "))
    wp = float(get_decimal("Wholesale Price: "))
    rp = float(get_decimal("Retail Price: "))
    ms = float(get_decimal("Min Stock: "))
    os_ = float(get_decimal("Opening Stock: "))
    tax = float(get_decimal("Tax %: "))
    batch = input("Batch No: ").strip()
    exp = input("Expiry Date: ").strip()
    rack = input("Rack: ").strip()
    try:
        DB.execute("INSERT INTO products (sku, name, category_id, brand_id, unit_id, purchase_price, sale_price, wholesale_price, retail_price, min_stock, current_stock, tax_pct, batch_no, expiry_date, rack_location, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                   (sku, name, cat, br, un, pp, sp, wp, rp, ms, os_, tax, batch, exp, rack, now()))
        DB.commit()
        pid = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
        if os_ != 0: update_stock(pid, os_, 'OPENING', 0, "Opening Stock")
        audit(f"Added Product {name}")
        print("Added.")
    except: print("SKU Exists or Error.")

def view_products():
    rows = DB.execute("SELECT id, sku, name, current_stock, sale_price FROM products WHERE is_active=1").fetchall()
    for r in rows: print(f"[{r['id']}] {r['sku']} - {r['name']} | Stock: {r['current_stock']} | Price: {r['sale_price']}")

def search_product():
    q = input("Search SKU/Name: ").strip().lower()
    rows = DB.execute("SELECT id, sku, name, current_stock FROM products WHERE (sku LIKE ? OR name LIKE ?) AND is_active=1", (f"%{q}%", f"%{q}%")).fetchall()
    for r in rows: print(f"[{r['id']}] {r['sku']} - {r['name']} | Stock: {r['current_stock']}")

def update_stock(pid, qty_change, type, ref_id, notes=""):
    DB.execute("UPDATE products SET current_stock = current_stock + ?, updated_at=? WHERE id=?", (float(qty_change), now(), pid))
    DB.execute("INSERT INTO stock_movements (product_id, date, type, quantity, ref_id, notes) VALUES (?,?,?,?,?,?)", (pid, now(), type, float(qty_change), ref_id, notes))

def adjust_stock():
    view_products()
    try:
        pid = int(input("Product ID: "))
        qty = float(get_decimal("Qty (+/-): "))
        reason = input("Reason: ").strip()
        update_stock(pid, qty, 'ADJUSTMENT', 0, reason)
        DB.commit(); print("Adjusted.")
    except: print("Error.")

def products_menu():
    menu("Products", {
        '1': ("Add", add_product), '2': ("View All", view_products), '3': ("Search", search_product),
        '4': ("Adjust Stock", adjust_stock), '5': ("Deactivate", lambda: simple_delete("products", "name"))
    })

def add_entity(table, prompt):
    code = input("Code: ").strip()
    name = input("Name: ").strip()
    if not name: return
    phone = input("Phone: ").strip()
    addr = input("Address: ").strip()
    ob = float(get_decimal("Opening Balance: "))
    DB.execute(f"INSERT INTO {table} (code, name, phone, address, opening_balance, created_at) VALUES (?,?,?,?,?,?)", (code, name, phone, addr, ob, now()))
    DB.commit()
    eid = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
    if ob != 0: add_ledger(table[:-1], eid, 'OPENING', 0, ob, "Opening")
    audit(f"Added {prompt} {name}"); print("Added.")

def view_entities(table, prompt):
    rows = DB.execute(f"SELECT id, code, name, current_balance FROM {table} WHERE is_active=1").fetchall()
    for r in rows: print(f"[{r['id']}] {r['code']} - {r['name']} (Bal: {r['current_balance']})")

def add_ledger(etype, eid, type, ref_id, amount, notes=""):
    row = DB.execute("SELECT balance FROM ledgers WHERE entity_type=? AND entity_id=? ORDER BY id DESC LIMIT 1", (etype, eid)).fetchone()
    prev = D(row['balance']) if row else D(0)
    new_bal = prev + D(amount)
    DB.execute("INSERT INTO ledgers (entity_type, entity_id, date, type, ref_id, amount, balance, notes) VALUES (?,?,?,?,?,?,?,?)",
               (etype, eid, now(), type, ref_id, float(amount), float(new_bal), notes))
    table = "customers" if etype == "customer" else "suppliers"
    DB.execute(f"UPDATE {table} SET current_balance=?, updated_at=? WHERE id=?", (float(new_bal), now(), eid))

def show_ledger(etype, eid):
    rows = DB.execute("SELECT date, type, amount, balance, notes FROM ledgers WHERE entity_type=? AND entity_id=? ORDER BY id", (etype, eid)).fetchall()
    print(f"\n{'Date':<12} {'Type':<10} {'Amount':<10} {'Balance':<10} {'Notes'}")
    for r in rows: print(f"{r['date']:<12} {r['type']:<10} {r['amount']:<10.2f} {r['balance']:<10.2f} {r['notes']}")
    input("Press Enter...")

def ledger_menu(table, prompt):
    view_entities(table, prompt)
    try:
        eid = int(input(f"Select {prompt} ID: "))
        show_ledger(table[:-1], eid)
    except: pass

def entity_menu(table, prompt):
    menu(f"Manage {prompt}s", {
        '1': ("Add", lambda: add_entity(table, prompt)), '2': ("View", lambda: view_entities(table, prompt)),
        '3': ("Deactivate", lambda: simple_delete(table, "name")), '4': ("Ledger", lambda: ledger_menu(table, prompt))
    })

def select_entity(table, prompt):
    print(f"--- Select {prompt} ---\n1. Walk-in / Cash")
    rows = DB.execute(f"SELECT id, code, name FROM {table} WHERE is_active=1").fetchall()
    for r in rows: print(f"[{r['id']}] {r['code']} - {r['name']}")
    while True:
        c = input("ID or Name (0=Walk-in): ").strip()
        if c == '0' or c.lower() == 'walk-in': return None
        try:
            i = int(c)
            for r in rows:
                if r['id'] == i: return dict(r)
        except:
            for r in rows:
                if c.lower() in r['name'].lower() or c == r['code']: return dict(r)
        print("Not found.")

def gen_doc_num(table, prefix):
    r = DB.execute(f"SELECT COUNT(*) as c FROM {table}").fetchone()
    return f"{prefix}-{(r['c'] + 1):05d}"

def pos_menu():
    inv = gen_doc_num("sales", get_setting("inv_prefix", "INV"))
    cust = select_entity("customers", "Customer")
    items = []
    while True:
        print(f"\n--- POS {inv} --- Items: {len(items)}")
        print("1. Add Item\n2. Checkout\n0. Cancel")
        c = input("Choice: ").strip()
        if c == '1':
            q = input("Scan/Enter SKU/Name: ").strip()
            p = DB.execute("SELECT * FROM products WHERE (sku=? OR name=? OR barcode=?) AND is_active=1", (q,q,q)).fetchone()
            if not p: print("Not found."); continue
            qty = float(get_decimal(f"Qty for {p['name']} (Stock: {p['current_stock']}): "))
            if qty <= 0: continue
            if not setting_bool("allow_neg_stock") and qty > p['current_stock']: print("No stock."); continue
            disc = float(get_decimal("Discount %: "))
            items.append({'product_id': p['id'], 'name': p['name'], 'qty': qty, 'price': p['sale_price'], 'disc': disc, 'tax': p['tax_pct']})
        elif c == '2':
            if not items: print("Empty."); continue
            sub = sum(D(i['qty']) * D(i['price']) for i in items)
            odisc = float(get_decimal("Overall Discount: "))
            tax = sum((D(i['qty'])*D(i['price']) - D(i['qty'])*D(i['price'])*D(i['disc'])/100) * D(i['tax'])/100 for i in items)
            grand = float(sub - D(odisc) + tax)
            print(f"Sub: {sub:.2f} | Disc: {odisc:.2f} | Tax: {tax:.2f} | Total: {grand:.2f}")
            pc = float(get_decimal("Cash Paid: "))
            pb = float(get_decimal("Bank Paid: "))
            pcr = grand - pc - pb
            if pcr < 0: print(f"Change: {-pcr:.2f}"); pcr = 0
            try:
                DB.execute("INSERT INTO sales (invoice_no, customer_id, date, subtotal, discount, tax, grand_total, paid_amount, balance_amount, payment_method, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                           (inv, cust['id'] if cust else 0, now_date(), float(sub), odisc, float(tax), grand, pc+pb, pcr, "Mixed", USER['id'], now()))
                DB.commit()
                sid = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
                for i in items:
                    itot = float(D(i['qty'])*D(i['price']) - D(i['qty'])*D(i['price'])*D(i['disc'])/100)
                    DB.execute("INSERT INTO sale_items (sale_id, product_id, quantity, sale_price, discount, tax, total) VALUES (?,?,?,?,?,?,?)",
                               (sid, i['product_id'], i['qty'], i['price'], i['disc'], i['tax'], itot))
                    update_stock(i['product_id'], -i['qty'], 'SALE', sid, "POS")
                if pcr > 0 and cust: add_ledger('customer', cust['id'], 'SALE', sid, pcr, f"Inv {inv}")
                if pc > 0: DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, ref_type, ref_id, created_by) VALUES (?,?,?,?,?,?,?,?)", (now(), "CASH_IN", "CASH", pc, f"Sale {inv}", "SALE", sid, USER['id']))
                if pb > 0: DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, ref_type, ref_id, created_by) VALUES (?,?,?,?,?,?,?,?)", (now(), "BANK_IN", "BANK", pb, f"Sale {inv}", "SALE", sid, USER['id']))
                DB.commit()
                audit(f"Sale {inv}")
                print_receipt(sid)
            except Exception as e:
                DB.rollback(); print("Error:", e)
            break
        elif c == '0': break

def print_receipt(sid):
    s = DB.execute("SELECT * FROM sales WHERE id=?", (sid,)).fetchone()
    items = DB.execute("SELECT si.*, p.name FROM sale_items si JOIN products p ON si.product_id=p.id WHERE sale_id=?", (sid,)).fetchall()
    print("\n" + "="*30 + f"\n{get_setting('shop_name', 'SHOP').center(30)}\n" + "="*30)
    print(f"Inv: {s['invoice_no']}  Date: {s['date']}\n" + "-"*30)
    for i in items: print(f"{i['name']}\n  {i['quantity']} x {i['sale_price']:.2f} = {i['total']:.2f}")
    print("-"*30 + f"\nSubtotal: {s['subtotal']:.2f}\nDiscount: {s['discount']:.2f}\nTax:      {s['tax']:.2f}\nTOTAL:    {s['grand_total']:.2f}\nPaid:     {s['paid_amount']:.2f}\nBalance:  {s['balance_amount']:.2f}\n" + "="*30 + f"\n{get_setting('footer_msg', 'Thank you!').center(30)}\n" + "="*30 + "\n")

def new_purchase():
    inv = gen_doc_num("purchases", get_setting("pur_prefix", "PUR"))
    supp = select_entity("suppliers", "Supplier")
    if not supp: print("Supplier required."); return
    items = []
    while True:
        print(f"\n--- Purchase {inv} --- Items: {len(items)}")
        print("1. Add Item\n2. Save\n0. Cancel")
        c = input("Choice: ").strip()
        if c == '1':
            view_products()
            pid = int(input("Product ID: "))
            p = DB.execute("SELECT * FROM products WHERE id=?", (pid,)).fetchone()
            if not p: continue
            qty = float(get_decimal("Qty: "))
            pp = float(get_decimal(f"Purchase Price (Old: {p['purchase_price']}): "))
            batch = input("Batch: ").strip()
            exp = input("Expiry: ").strip()
            items.append({'product_id': pid, 'qty': qty, 'price': pp, 'batch': batch, 'exp': exp})
        elif c == '2':
            if not items: print("Empty."); continue
            sub = sum(D(i['qty']) * D(i['price']) for i in items)
            fr = float(get_decimal("Freight/Extra: "))
            grand = float(sub + D(fr))
            paid = float(get_decimal("Paid Amount: "))
            bal = grand - paid
            try:
                DB.execute("INSERT INTO purchases (invoice_no, supplier_id, date, subtotal, freight, grand_total, paid_amount, balance_amount, payment_method, created_by, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                           (inv, supp['id'], now_date(), float(sub), fr, grand, paid, bal, "Mixed", USER['id'], now()))
                DB.commit()
                pid_ = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
                for i in items:
                    DB.execute("INSERT INTO purchase_items (purchase_id, product_id, quantity, purchase_price, batch_no, expiry_date, total) VALUES (?,?,?,?,?,?,?)",
                               (pid_, i['product_id'], i['qty'], i['price'], i['batch'], i['exp'], float(D(i['qty'])*D(i['price']))))
                    update_stock(i['product_id'], i['qty'], 'PURCHASE', pid_, "Purchased")
                if bal > 0: add_ledger('supplier', supp['id'], 'PURCHASE', pid_, bal, f"Inv {inv}")
                if paid > 0: DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, ref_type, ref_id, created_by) VALUES (?,?,?,?,?,?,?,?)", (now(), "CASH_OUT", "CASH", paid, f"Pur {inv}", "PURCHASE", pid_, USER['id']))
                DB.commit()
                audit(f"Purchase {inv}"); print("Saved.")
            except Exception as e: DB.rollback(); print("Error:", e)
            break
        elif c == '0': break

def purchase_menu():
    menu("Purchases", {'1': ("New", new_purchase), '2': ("View", lambda: [print(f"{r['invoice_no']} {r['date']} {r['grand_total']}") for r in DB.execute("SELECT * FROM purchases").fetchall()])})

def add_cb_txn(type):
    amt = float(get_decimal("Amount: "))
    if amt <= 0: return
    desc = input("Desc: ").strip()
    acc = "CASH" if "CASH" in type else "BANK"
    DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, created_by, created_at) VALUES (?,?,?,?,?,?,?)", (now(), type, acc, amt, desc, USER['id'], now()))
    DB.commit(); print("Recorded.")

def transfer(frm, to):
    amt = float(get_decimal("Amount: "))
    if amt <= 0: return
    DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, created_by) VALUES (?,?,?,?,?,?)", (now(), "OUT", frm, amt, f"To {to}", USER['id']))
    DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, created_by) VALUES (?,?,?,?,?,?)", (now(), "IN", to, amt, f"From {frm}", USER['id']))
    DB.commit(); print("Transferred.")

def cash_bank_menu():
    menu("Cash & Bank", {
        '1': ("Cash In", lambda: add_cb_txn("CASH_IN")), '2': ("Cash Out", lambda: add_cb_txn("CASH_OUT")),
        '3': ("Bank In", lambda: add_cb_txn("BANK_IN")), '4': ("Bank Out", lambda: add_cb_txn("BANK_OUT")),
        '5': ("Cash to Bank", lambda: transfer("CASH", "BANK")), '6': ("Bank to Cash", lambda: transfer("BANK", "CASH"))
    })

def add_expense():
    cat = input("Category: ").strip()
    desc = input("Desc: ").strip()
    amt = float(get_decimal("Amount: "))
    meth = input("Method (cash/bank): ").strip().upper()
    paid = input("Paid to: ").strip()
    DB.execute("INSERT INTO expenses (category, description, amount, payment_method, date, paid_to, created_by, created_at) VALUES (?,?,?,?,?,?,?,?)", (cat, desc, amt, meth, now_date(), paid, USER['id'], now()))
    DB.execute("INSERT INTO cash_bank_transactions (date, type, account, amount, description, created_by) VALUES (?,?,?,?,?,?)", (now(), f"{meth}_OUT", meth, amt, f"Exp: {desc}", USER['id']))
    DB.commit(); audit("Expense"); print("Added.")

def expenses_menu():
    menu("Expenses", {'1': ("Add", add_expense), '2': ("View", lambda: [print(f"{r['date']} {r['category']} {r['amount']}") for r in DB.execute("SELECT * FROM expenses").fetchall()])})

def sale_return():
    inv = input("Original Sale Invoice No: ").strip()
    s = DB.execute("SELECT * FROM sales WHERE invoice_no=?", (inv,)).fetchone()
    if not s: print("Not found."); return
    items = DB.execute("SELECT * FROM sale_items WHERE sale_id=?", (s['id'])).fetchall()
    for i in items: print(f"{i['product_id']}: Qty {i['quantity']}")
    ret_items = []
    while True:
        pid = input("Product ID to return (0=done): ").strip()
        if pid == '0': break
        try:
            pid = int(pid)
            qty = float(get_decimal("Qty: "))
            ret_items.append({'product_id': pid, 'qty': qty})
        except: pass
    if not ret_items: return
    rno = gen_doc_num("sale_returns", get_setting("ret_prefix", "SRET"))
    tot = sum(float(DB.execute("SELECT sale_price FROM sale_items WHERE product_id=? AND sale_id=?", (i['product_id'], s['id'])).fetchone()[0]) * i['qty'] for i in ret_items)
    DB.execute("INSERT INTO sale_returns (return_no, sale_id, date, grand_total, reason, created_by, created_at) VALUES (?,?,?,?,?,?,?)", (rno, s['id'], now_date(), tot, input("Reason: "), USER['id'], now()))
    rid = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
    for i in ret_items:
        DB.execute("INSERT INTO sale_return_items (return_id, product_id, quantity, total) VALUES (?,?,?,?)", (rid, i['product_id'], i['qty'], tot))
        update_stock(i['product_id'], i['qty'], 'RETURN', rid, "Sale Return")
    if s['customer_id'] > 0: add_ledger('customer', s['customer_id'], 'RETURN', rid, -tot, f"Ret {rno}")
    DB.commit(); audit(f"Sale Return {rno}"); print("Done.")

def purchase_return():
    inv = input("Original Purchase Invoice No: ").strip()
    p = DB.execute("SELECT * FROM purchases WHERE invoice_no=?", (inv,)).fetchone()
    if not p: print("Not found."); return
    items = DB.execute("SELECT * FROM purchase_items WHERE purchase_id=?", (p['id'])).fetchall()
    for i in items: print(f"{i['product_id']}: Qty {i['quantity']}")
    ret_items = []
    while True:
        pid = input("Product ID (0=done): ").strip()
        if pid == '0': break
        try:
            pid = int(pid)
            qty = float(get_decimal("Qty: "))
            ret_items.append({'product_id': pid, 'qty': qty})
        except: pass
    if not ret_items: return
    rno = gen_doc_num("purchase_returns", get_setting("ret_prefix", "PRET"))
    tot = sum(float(DB.execute("SELECT purchase_price FROM purchase_items WHERE product_id=? AND purchase_id=?", (i['product_id'], p['id'])).fetchone()[0]) * i['qty'] for i in ret_items)
    DB.execute("INSERT INTO purchase_returns (return_no, purchase_id, date, grand_total, reason, created_by, created_at) VALUES (?,?,?,?,?,?,?)", (rno, p['id'], now_date(), tot, input("Reason: "), USER['id'], now()))
    rid = DB.execute("SELECT last_insert_rowid()").fetchone()[0]
    for i in ret_items:
        DB.execute("INSERT INTO purchase_return_items (return_id, product_id, quantity, total) VALUES (?,?,?,?)", (rid, i['product_id'], i['qty'], tot))
        update_stock(i['product_id'], -i['qty'], 'RETURN', rid, "Pur Return")
    add_ledger('supplier', p['supplier_id'], 'RETURN', rid, -tot, f"Ret {rno}")
    DB.commit(); audit(f"Pur Return {rno}"); print("Done.")

def returns_menu():
    menu("Returns", {'1': ("Sale Return", sale_return), '2': ("Purchase Return", purchase_return)})

def export_csv(title, rows, headers):
    fname = f"{title.replace(' ', '_')}_{now_date()}.csv"
    with open(fname, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f); w.writerow(headers)
        for r in rows: w.writerow([r[h] for h in headers])
    print(f"Exported {fname}")

def import_csv(table):
    fname = input("CSV File: ").strip()
    if not os.path.exists(fname): print("Not found."); return
    with open(fname, 'r', encoding='utf-8') as f:
        r = csv.DictReader(f); count = 0
        for row in r:
            cols = ', '.join(row.keys())
            vals = ', '.join(['?'] * len(row))
            try: DB.execute(f"INSERT OR IGNORE INTO {table} ({cols}) VALUES ({vals})", tuple(row.values())); count += 1
            except: pass
        DB.commit(); print(f"Imported {count}.")

def import_export_menu():
    menu("Import/Export", {
        '1': ("Export Products", lambda: export_csv("Products", DB.execute("SELECT id,sku,name,sale_price,current_stock FROM products").fetchall(), ["id","sku","name","sale_price","current_stock"])),
        '2': ("Export Customers", lambda: export_csv("Customers", DB.execute("SELECT id,code,name,phone,current_balance FROM customers").fetchall(), ["id","code","name","phone","current_balance"])),
        '3': ("Import Products", lambda: import_csv("products")), '4': ("Import Customers", lambda: import_csv("customers"))
    })

REPORTS = {
    '1': ("Daily Sales", "SELECT invoice_no, date, grand_total FROM sales WHERE date=date('now')", ["invoice_no", "date", "grand_total"]),
    '2': ("Date-wise Sales", "SELECT date, SUM(grand_total) as total FROM sales GROUP BY date", ["date", "total"]),
    '3': ("Product Sales", "SELECT p.name, SUM(si.quantity) as qty FROM sale_items si JOIN products p ON si.product_id=p.id GROUP BY p.id", ["name", "qty"]),
    '4': ("Customer Sales", "SELECT c.name, SUM(s.grand_total) as total FROM sales s JOIN customers c ON s.customer_id=c.id GROUP BY c.id", ["name", "total"]),
    '5': ("Daily Pur", "SELECT invoice_no, date, grand_total FROM purchases WHERE date=date('now')", ["invoice_no", "date", "grand_total"]),
    '6': ("Date Pur", "SELECT date, SUM(grand_total) as total FROM purchases GROUP BY date", ["date", "total"]),
    '7': ("Supp Pur", "SELECT sp.name, SUM(p.grand_total) as total FROM purchases p JOIN suppliers sp ON p.supplier_id=sp.id GROUP BY sp.id", ["name", "total"]),
    '8': ("Profit/Loss", "SELECT (SELECT SUM(grand_total) FROM sales) - (SELECT SUM(grand_total) FROM purchases) - (SELECT SUM(amount) FROM expenses) as profit", ["profit"]),
    '9': ("Gross Profit", "SELECT SUM(si.total - (si.quantity * p.purchase_price)) as gp FROM sale_items si JOIN products p ON si.product_id=p.id", ["gp"]),
    '10': ("Expenses", "SELECT date, category, amount FROM expenses", ["date", "category", "amount"]),
    '11': ("Cash Book", "SELECT date, description, amount FROM cash_bank_transactions WHERE account='CASH'", ["date", "description", "amount"]),
    '12': ("Bank Book", "SELECT date, description, amount FROM cash_bank_transactions WHERE account='BANK'", ["date", "description", "amount"]),
    '13': ("Cust Rec", "SELECT c.name, l.balance FROM customers c JOIN (SELECT entity_id, MAX(id) as mid FROM ledgers WHERE entity_type='customer' GROUP BY entity_id) m ON c.id=m.entity_id JOIN ledgers l ON m.mid=l.id WHERE l.balance > 0", ["name", "balance"]),
    '14': ("Supp Pay", "SELECT s.name, l.balance FROM suppliers s JOIN (SELECT entity_id, MAX(id) as mid FROM ledgers WHERE entity_type='supplier' GROUP BY entity_id) m ON s.id=m.entity_id JOIN ledgers l ON m.mid=l.id WHERE l.balance > 0", ["name", "balance"]),
    '15': ("Stock", "SELECT name, current_stock FROM products WHERE is_active=1", ["name", "current_stock"]),
    '16': ("Low Stock", "SELECT name, current_stock, min_stock FROM products WHERE current_stock <= min_stock AND is_active=1", ["name", "current_stock", "min_stock"]),
    '17': ("Out Stock", "SELECT name FROM products WHERE current_stock <= 0 AND is_active=1", ["name"]),
    '18': ("Valuation", "SELECT SUM(current_stock * purchase_price) as val FROM products WHERE is_active=1", ["val"]),
    '19': ("Sale Ret", "SELECT return_no, date, grand_total FROM sale_returns", ["return_no", "date", "grand_total"]),
    '20': ("Pur Ret", "SELECT return_no, date, grand_total FROM purchase_returns", ["return_no", "date", "grand_total"]),
    '21': ("Tax", "SELECT SUM(tax) as tax FROM sales", ["tax"]),
    '22': ("Discount", "SELECT SUM(discount) as disc FROM sales", ["disc"]),
    '23': ("Audit", "SELECT timestamp, action, details FROM audit_logs ORDER BY id DESC LIMIT 100", ["timestamp", "action", "details"]),
    '24': ("User Act", "SELECT u.username, a.action, a.timestamp FROM audit_logs a JOIN users u ON a.user_id=u.id ORDER BY a.id DESC LIMIT 100", ["username", "action", "timestamp"]),
    '25': ("Closing", "SELECT (SELECT SUM(amount) FROM cash_bank_transactions WHERE type='CASH_IN') - (SELECT SUM(amount) FROM cash_bank_transactions WHERE type='CASH_OUT') as cash", ["cash"])
}

def run_report(key):
    title, query, headers = REPORTS[key]
    rows = DB.execute(query).fetchall()
    print(f"\n--- {title} ---")
    print("\t".join(headers))
    for r in rows: print("\t".join(str(r[h]) for h in headers))
    if input("Export CSV? (y/n): ").lower() == 'y': export_csv(title, rows, headers)
    input("Press Enter...")

def reports_menu():
    opts = {str(i): (v[0], lambda k=str(i): run_report(k)) for i, v in REPORTS.items()}
    menu("Reports", opts)

def backup_db():
    bdir = get_setting("backup_path", os.path.join(CMD_DIR, "backups"))
    os.makedirs(bdir, exist_ok=True)
    fname = f"backup_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
    dest = os.path.join(bdir, fname)
    shutil.copy2(DB_PATH, dest)
    audit(f"Backup {fname}"); print(f"Backed up to {dest}")

def restore_db():
    bdir = get_setting("backup_path", os.path.join(CMD_DIR, "backups"))
    if not os.path.exists(bdir): print("No backups."); return
    files = [f for f in os.listdir(bdir) if f.endswith('.db')]
    for i, f in enumerate(files, 1): print(f"{i}. {f}")
    c = input("Select (0=cancel): ").strip()
    if not c.isdigit() or int(c) == 0: return
    src = os.path.join(bdir, files[int(c)-1])
    if input("Type 'YES' to confirm overwrite: ").strip() != 'YES': return
    shutil.copy2(src, DB_PATH)
    audit("Restored"); print("Restored. Restarting..."); sys.exit(0)

def backup_menu():
    menu("Backup/Restore", {'1': ("Backup Now", backup_db), '2': ("Restore", restore_db), '3': ("Auto Backup on Exit (Toggle)", lambda: set_setting("auto_backup", "1" if get_setting("auto_backup")=="0" else "0"))})

def create_user():
    u = input("Username: ").strip()
    p = get_pwd("Password: ")
    r = input("Role (Admin/Manager/Cashier/Viewer): ").strip().title()
    h, s = hash_password(p)
    try:
        DB.execute("INSERT INTO users (username, password_hash, salt, role, created_at) VALUES (?,?,?,?,?)", (u, h, s, r, now()))
        DB.commit(); print("Created.")
    except: print("Exists.")

def users_menu():
    menu("Users", {'1': ("Create", create_user), '2': ("Deactivate", lambda: simple_delete("users", "username")), '3': ("Audit Log", lambda: run_report('23'))})

def settings_menu():
    keys = [("shop_name", "Name"), ("address", "Addr"), ("phone", "Phone"), ("currency", "Currency"), ("inv_prefix", "Inv Prefix"), ("pur_prefix", "Pur Prefix"), ("ret_prefix", "Ret Prefix"), ("low_stock", "Low Stock Lvl"), ("backup_path", "Backup Path"), ("footer_msg", "Footer"), ("allow_neg_stock", "Neg Stock (1/0)")]
    while True:
        print("\n--- Settings ---")
        for i, (k, desc) in enumerate(keys, 1): print(f"{i}. {desc}: {get_setting(k, 'N/A')}")
        print("0. Back")
        c = input("Edit: ").strip()
        if c == '0': break
        try:
            idx = int(c) - 1
            if 0 <= idx < len(keys): set_setting(keys[idx][0], input(f"New {keys[idx][1]}: ").strip())
        except: pass

def dashboard():
    today = now_date()
    sales = DB.execute("SELECT SUM(grand_total) FROM sales WHERE date=?", (today,)).fetchone()[0] or 0
    purch = DB.execute("SELECT SUM(grand_total) FROM purchases WHERE date=?", (today,)).fetchone()[0] or 0
    cash_in = DB.execute("SELECT SUM(amount) FROM cash_bank_transactions WHERE date=? AND type IN ('CASH_IN','BANK_IN')", (today,)).fetchone()[0] or 0
    cash_out = DB.execute("SELECT SUM(amount) FROM cash_bank_transactions WHERE date=? AND type IN ('CASH_OUT','BANK_OUT')", (today,)).fetchone()[0] or 0
    exp = DB.execute("SELECT SUM(amount) FROM expenses WHERE date=?", (today,)).fetchone()[0] or 0
    low = DB.execute("SELECT COUNT(*) FROM products WHERE current_stock <= min_stock AND is_active=1").fetchone()[0]
    print(f"--- Dashboard ({today}) ---\nSales: {sales:.2f} | Purch: {purch:.2f}\nCash In: {cash_in:.2f} | Out: {cash_out:.2f}\nExp: {exp:.2f} | Profit: {sales-purch-exp:.2f}\nLow Stock: {low}")
    input("Press Enter...")

def logout():
    audit("LOGOUT")
    global USER
    USER = None
    main()

def sys_exit():
    if get_setting("auto_backup") == "1": backup_db()
    audit("EXIT")
    sys.exit(0)

def show_main_menu():
    opts = {
        '1': ("Dashboard", dashboard), '2': ("Sales/POS", lambda: check_access('POS', pos_menu)),
        '3': ("Purchases", lambda: check_access('PURCHASES', purchase_menu)), '4': ("Products", lambda: check_access('INVENTORY', products_menu)),
        '5': ("Customers", lambda: check_access('CUSTOMERS', lambda: entity_menu("customers", "Customer"))),
        '6': ("Suppliers", lambda: check_access('SUPPLIERS', lambda: entity_menu("suppliers", "Supplier"))),
        '7': ("Cash/Bank", lambda: check_access('CASH', cash_bank_menu)), '8': ("Expenses", lambda: check_access('EXPENSES', expenses_menu)),
        '9': ("Reports", lambda: check_access('REPORTS', reports_menu)), '10': ("Returns", lambda: check_access('RETURNS', returns_menu)),
        '11': ("Settings", lambda: check_access('SETTINGS', settings_menu)), '12': ("Users", lambda: check_access('USERS', users_menu)),
        '13': ("Backup", lambda: check_access('BACKUP', backup_menu)), '14': ("Import/Export", lambda: check_access('IMPORT', import_export_menu)),
        '15': ("Logout", logout), '0': ("Exit", sys_exit)
    }
    menu(f"Main ({USER['username']} - {USER['role']})", opts)

def main():
    global DB, CMD_DIR, DB_PATH
    CMD_DIR = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    DB_PATH = os.path.join(CMD_DIR, 'shop_manager.db')
    DB = sqlite3.connect(DB_PATH)
    DB.row_factory = sqlite3.Row
    init_db()
    if not login(): return
    while True: show_main_menu()

if __name__ == "__main__":
    main()