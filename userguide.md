# Shop Manager — User Guide

> **Version**: 1.0 | **Platform**: Windows / Linux / Mac | **Database**: SQLite (`shop_manager.db`)

---

## Table of Contents

1. [Getting Started](#1-getting-started)
2. [Login & User Roles](#2-login--user-roles)
3. [Main Menu Overview](#3-main-menu-overview)
4. [Dashboard (Menu 1)](#4-dashboard-menu-1)
5. [Sales / POS (Menu 2)](#5-sales--pos-menu-2)
6. [Products & Inventory (Menu 3)](#6-products--inventory-menu-3)
7. [Customers & Khata (Menu 4)](#7-customers--khata-menu-4)
8. [Reports & Analytics (Menu 5)](#8-reports--analytics-menu-5)
9. [Purchases (Menu 6)](#9-purchases-menu-6)
10. [Suppliers & Khata (Menu 7)](#10-suppliers--khata-menu-7)
11. [Cash & Bank Accounts (Menu 8)](#11-cash--bank-accounts-menu-8)
12. [Expenses (Menu 9)](#12-expenses-menu-9)
13. [Returns (Menu 10)](#13-returns-menu-10)
14. [Shop Settings (Menu 11)](#14-shop-settings-menu-11)
15. [Users & Security (Menu 12)](#15-users--security-menu-12)
16. [Backup & Restore (Menu 13)](#16-backup--restore-menu-13)
17. [Import / Export CSV (Menu 14)](#17-import--export-csv-menu-14)
18. [Quotations (Menu 15)](#18-quotations-menu-15)
19. [Sales Orders (Menu 16)](#19-sales-orders-menu-16)
20. [Purchase Orders (Menu 17)](#20-purchase-orders-menu-17)
21. [Delivery Challans (Menu 18)](#21-delivery-challans-menu-18)
22. [Warehouses (Menu 19)](#22-warehouses-menu-19)
23. [Credit / Debit Notes (Menu 20)](#23-credit--debit-notes-menu-20)
24. [Employees (Menu 21)](#24-employees-menu-21)
25. [Commissions (Menu 22)](#25-commissions-menu-22)
26. [Loyalty Points (Menu 23)](#26-loyalty-points-menu-23)
27. [Price Lists (Menu 24)](#27-price-lists-menu-24)
28. [Promotions (Menu 25)](#28-promotions-menu-25)
29. [Serial Numbers (Menu 26)](#29-serial-numbers-menu-26)
30. [Service & Repair (Menu 27)](#30-service--repair-menu-27)
31. [Bill of Materials (Menu 28)](#31-bill-of-materials-menu-28)
32. [Manufacturing (Menu 29)](#32-manufacturing-menu-29)
33. [Accounting (Menu 30)](#33-accounting-menu-30)
34. [Financial Statements (Menu 31)](#34-financial-statements-menu-31)
35. [Fixed Assets (Menu 32)](#35-fixed-assets-menu-32)
36. [Budgets (Menu 33)](#36-budgets-menu-33)
37. [Cash Register (Menu 34)](#37-cash-register-menu-34)
38. [Email Config (Menu 35)](#38-email-config-menu-35)
39. [Help & Support (Menu 36)](#39-help--support-menu-36)
40. [Utility Functions (Menu 37)](#40-utility-functions-menu-37)
41. [Logout & Exit (Menus 38 & 0)](#41-logout--exit-menus-38--0)
42. [Keyboard Shortcuts](#42-keyboard-shortcuts)
43. [Sample Data & Default Values](#43-sample-data--default-values)
44. [System Behaviors — How Things Work Together](#44-system-behaviors--how-things-work-together)

---

## 1. Getting Started

### How to Launch

```bash
# Windows
python ShopApp.cmd

# Linux / Mac
python3 ShopApp.cmd
```

The CMD window will **auto-maximize** on launch. The console is set to **90 columns × 50 lines** with **no scrollbar** — all menus fit on screen, and the input prompt is always visible at the bottom.

### Default Login

| Username | Password | Role |
|----------|----------|------|
| `admin` | `admin123` | **Admin** (full access) |
| `manager` | `manager123` | **Manager** (operations) |
| `cashier` | `cashier123` | **Cashier** (POS/sales) |
| `viewer` | `viewer123` | **Viewer** (read-only) |

> **Important**: Change passwords immediately after first login (the app will force password change on first login for security).

---

## 2. Login & User Roles

### How Login Works

1. App starts → shows `SHOP MANAGEMENT SYSTEM - LOGIN` screen
2. Enter your **Username** and **Password** (password is hidden while typing)
3. System verifies credentials against the database
4. If `force_password_change` is set (first login), you must set a new password immediately
5. On success → main menu appears. On failure → try again

### User Roles & Permissions

The main menu dynamically hides options that your role cannot access. Each role has a predefined permission set:

| # | Menu Option | Admin | Manager | Cashier | Viewer |
|---|-------------|:-----:|:-------:|:-------:|:------:|
| 1 | Dashboard & Today Summary | ✓ | ✓ | ✓ | ✓ |
| 2 | Sales / POS Terminal | ✓ | ✓ | ✓ | |
| 3 | Products & Inventory | ✓ | ✓ | ✓ | |
| 4 | Customers & Khata | ✓ | ✓ | ✓ | |
| 5 | Reports & Analytics | ✓ | ✓ | ✓ | ✓ |
| 6 | Purchases Management | ✓ | ✓ | | |
| 7 | Suppliers & Khata | ✓ | ✓ | | |
| 8 | Cash & Bank Accounts | ✓ | ✓ | ✓ | |
| 9 | Expenses Manager | ✓ | ✓ | | |
| 10 | Returns Processing | ✓ | ✓ | ✓ | |
| 11 | Shop Settings | ✓ | | | |
| 12 | Users & Security | ✓ | ✓* | ✓* | ✓* |
| 13 | Backup & Restore DB | ✓ | | | |
| 14 | Import / Export CSV | ✓ | ✓ | | |
| 15 | Quotations | ✓ | ✓ | ✓ | |
| 16 | Sales Orders | ✓ | ✓ | ✓ | |
| 17 | Purchase Orders | ✓ | ✓ | | |
| 18 | Delivery Challans | ✓ | ✓ | | |
| 19 | Warehouses | ✓ | ✓ | | |
| 20 | Credit / Debit Notes | ✓ | ✓ | | |
| 21 | Employees | ✓ | ✓ | | |
| 22 | Commissions | ✓ | ✓ | | |
| 23 | Loyalty Points | ✓ | ✓ | ✓ | |
| 24 | Price Lists | ✓ | ✓ | | |
| 25 | Promotions & Coupons | ✓ | ✓ | | |
| 26 | Serial Numbers | ✓ | ✓ | | |
| 27 | Service / Repair Jobs | ✓ | ✓ | ✓ | |
| 28 | Bill of Materials | ✓ | ✓ | | |
| 29 | Manufacturing Jobs | ✓ | ✓ | | |
| 30 | Accounting (Ledger) | ✓ | ✓ | | |
| 31 | Financial Statements | ✓ | ✓ | | |
| 32 | Fixed Assets | ✓ | ✓ | | |
| 33 | Budgets | ✓ | ✓ | | |
| 34 | Cash Register | ✓ | ✓ | ✓ | |
| 35 | Email Config | ✓ | | | |
| 36 | Help & Support | ✓ | ✓ | ✓ | ✓ |
| 37 | Utility Functions | ✓ | ✓ | | |
| 38 | Logout | ✓ | ✓ | ✓ | ✓ |
| S | Global Quick Search | ✓ | ✓ | ✓ | ✓ |

> \* Users & Security — only "Change My Password" is available to all roles; user management and audit log are Admin-only.

**Role summaries:**

| Role | What They Can Do |
|------|------------------|
| **Admin** | Everything — all menus, settings, user management, backups, audit logs, full configuration |
| **Manager** | All operational tasks (sales, purchases, products, customers, suppliers, accounts, expenses, reports, warehouses, manufacturing, service, etc.) but **cannot** access system settings, user management, backup/restore, email config, or clear sample data |
| **Cashier** | Point of sale, customer management, quotations, sales orders, loyalty, cash register, returns, service job viewing. **Cannot** manage purchases, suppliers, expenses, accounting, or any admin functions |
| **Viewer** | Read-only access to dashboard, reports, and help topics. Can change own password and use global search. **Cannot** create, edit, or delete any data |

### Where Permissions Take Effect

Permissions are enforced at **two levels**:

1. **Frontend (Menu Filtering)**: The main menu only shows options your role is allowed to access. Hidden options cannot be selected.
2. **Backend (Method Guards)**: Even if a restricted option number is entered manually, a second check inside each module blocks access and displays *"Access Denied"*.

**Role access groups:**
- **Admin-only**: Settings (menu 11), Users & Security — full (menu 12), Backup (menu 13), Email Config (menu 35), Clear Sample Data, Audit Reports
- **Admin/Manager-only**: Purchases (6), Suppliers (7), Expenses (9), Purchase Orders (17), Delivery Challans (18), Warehouses (19), Credit/Debit Notes (20), Employees (21), Commissions (22), Price Lists (24), Promotions (25), Serial Numbers (26), BOM (28), Manufacturing (29), Accounting (30), Financial Statements (31), Fixed Assets (32), Budgets (33), Import/Export (14), Utilities (37)
- **Admin/Manager/Cashier**: Sales (2), Products (3), Customers (4), Cash & Bank (8), Returns (10), Quotations (15), Sales Orders (16), Service (27), Loyalty (23), Cash Register (34)
- **All roles**: Dashboard (1), Reports (5), Help (36), Logout (38), Global Search (S)
- **All roles (limited)**: Users & Security — "Change My Password" only (menu 12)

---

## 3. Main Menu Overview

The main menu uses a **two-column layout** with 38 options. Most-used features are at the top.

### Quick Menu Reference

```
 1. Dashboard & Today Summary  20. Credit / Debit Notes
 2. Sales / POS Terminal       21. Employees
 3. Products & Inventory        22. Commissions
 4. Customers & Khata           23. Loyalty Points
 5. Reports & Analytics         24. Price Lists
 6. Purchases Management        25. Promotions & Coupons
 7. Suppliers & Khata           26. Serial Numbers
 8. Cash & Bank Accounts        27. Service / Repair Jobs
 9. Expenses Manager            28. Bill of Materials
10. Returns Processing           29. Manufacturing Jobs
11. Shop Settings               30. Accounting
12. Users & Security            31. Financial Statements
13. Backup & Restore            32. Fixed Assets
14. Import / Export CSV         33. Budgets
15. Quotations                  34. Cash Register
16. Sales Orders                35. Email Config
17. Purchase Orders             36. Help & Support
18. Delivery Challans           37. Utility Functions
19. Warehouses & Stock Transfer 38. Logout
  S. Global Quick Search         0. Exit Application
```

**Navigation**: Press the number/letter and Enter. Press `0` in any submenu to go back.

---

## 4. Dashboard (Menu 1)

### What It Does
Shows a **real-time executive summary** of today's business — sales, purchases, cash flow, expenses, and estimated profit.

### What You See
```
Today Sales: $1,500     Today Purchases: $800     Cash In: $1,200
Cash Out: $400          Today Expenses: $150      Est. Net Profit: $550
Low Stock Items: 3      Available Cash: $5,000    Cust Balances: $2,300
Supp Payables: $1,100   Pending Sales: $200       Pending Pur: $0
```

### How It Affects Other Areas
- All values are **calculated live** from actual transactions
- Sales, purchases, expenses, and payments you enter elsewhere update this dashboard automatically
- Low stock count comes from the `low_stock_warn` threshold in Settings

### How to Use
Press `1` at the main menu. Review the data. Press Enter to return to main menu. No data entry here — it's read-only.

---

## 5. Sales / POS (Menu 2)

### What It Does
Creates **sales invoices** (bills) for customers. Supports walk-in and registered customers. Automatically updates stock, customer balance, and cash/bank accounts.

### How to Use

1. Press `2` at the main menu → Sales Menu
2. Choose **1 = Create Invoice**
3. **Select customer**: Enter customer code, or type `walk` for walk-in customer (no ledger tracking)
4. **Add products**: Enter SKU, barcode, or partial name — system searches and shows matching products
5. For each product: enter **quantity**, **price** (editable), **discount %** (if applicable), **tax %**
6. Type `DONE` when cart is complete
7. Review the invoice summary (subtotal, discount, tax, grand total)
8. **Enter payment**: Amount paid (can be partial — balance becomes receivable)
9. **Select payment account** (Cash in Hand, Bank Account, etc.)
10. Invoice is generated with number format: `INV-YYMMDD-NNNN`
11. Option to **save receipt to text file**

### What Happens Behind the Scenes
- Product stock **decreases** by the sold quantity
- Customer balance **increases** (if credit sale or unpaid balance)
- Cash/Bank account balance **increases** (if payment taken)
- Customer ledger gets a **debit entry** (if registered customer)
- Stock movement log updated
- Sale recorded for reports

### Sales Submenu Options
| Option | What It Does |
|--------|--------------|
| 1. Create Invoice | Full POS workflow (described above) |
| 2. View Invoices | Lists last 50 sales with totals and payment status |
| 3. Process Return | Reverse a sale (see Returns section) |

---

## 6. Products & Inventory (Menu 3)

### What It Does
Manages your entire **product catalog** — categories, brands, units, and individual products. Also handles stock adjustments, price history, and stock movement tracking.

### Submenu Overview
| Option | What It Does |
|--------|--------------|
| 1. Manage Categories | Add/Edit/Delete product categories |
| 2. Manage Brands | Add/Edit/Delete brands |
| 3. Manage Units | Add/Edit/Delete units (pcs, kg, liter, etc.) |
| 4. Manage Products | View active products, Add new, Edit, Search, Deactivate |
| 5. View Inactive Products | See products that have been deactivated |
| 6. Stock Adjustment | Manually increase or decrease stock (requires reason) |
| 7. Price Update History | See who changed prices and when |
| 8. Stock Movement History | Complete log of all stock changes |

### Adding a Product

1. In Products submenu, choose **Add New Product**
2. Fill in the form:
   - **Code/SKU** — unique product identifier (auto-suggested)
   - **Barcode** — optional barcode number
   - **Name** — product name
   - **Category** — select from existing categories
   - **Brand** — select from existing brands
   - **Unit** — select from existing units (pcs, kg, etc.)
   - **Purchase Price** — cost price
   - **Sale Price** — retail selling price
   - **Wholesale Price** — bulk price
   - **Retail MSRP** — manufacturer's suggested price
   - **Min Stock** — warning level (low stock alert triggers at this)
   - **Opening Stock** — initial stock quantity
   - **Tax %** — default tax rate for this product
   - **Discount Allowed** — whether discount can be given (Y/N)
   - **Expiry Date, Batch Number, Rack Location** — optional

### Stock Adjustment

- Choose **Increase (+)** or **Decrease (-)**
- Enter quantity and **reason** (required for audit trail)
- System checks `allow_negative_stock` setting — prevents going below zero if disabled
- Recorded in `stock_adjustments` and `stock_movements` tables

### How It Affects Other Areas
- Products are **referenced everywhere**: sales, purchases, returns, reports, manufacturing
- Price changes are **tracked** with who changed them and when
- Stock adjustments affect product availability in sales

---

## 7. Customers & Khata (Menu 4)

### What It Does
Manages **customer records** and the **Khata (credit ledger)** system. Every sale on credit and every payment is tracked here.

### Submenu Options
| Option | What It Does |
|--------|--------------|
| 1. Add Customer | Register a new customer (auto-code: CUST-0001) |
| 2. View All Customers | List all customers with current balance |
| 3. Edit Customer | Update details and credit limit |
| 4. Search Customer | Find by code, name, or phone |
| 5. Customer Khata | View full ledger statement (debit/credit/running balance) |
| 6. Receive Payment | Record payment received from customer |
| 7. Toggle Status | Activate or deactivate customer |

### Adding a Customer

Fields: Name, Phone, Address, Email, Opening Balance, Credit Limit.
- Opening Balance creates an initial ledger entry
- Credit Limit shows a warning if exceeded (does not block)

### Customer Khata (Ledger Statement)

- Shows: Date, Transaction Type, Debit, Credit, Running Balance, Description
- Types: OPENING, SALE, PAYMENT, SALE_RETURN, CREDIT_NOTE
- All amounts in your configured currency
- Option to **export to CSV**

### Receive Payment

1. Select customer by code/name
2. Enter payment amount
3. Select payment account (Cash/Bank)
4. Press confirm — customer balance decreases, account increases

### How It Affects Other Areas
- **Sales on credit** → customer balance increases, ledger has debit entry
- **Payments received** → customer balance decreases, ledger has credit entry
- **Sale returns** → customer balance decreases
- Cash/Bank accounts update on every payment

---

## 8. Reports & Analytics (Menu 5)

### What It Does
Provides **25+ reports** across all business areas. Every report can be **exported to CSV**.

### Report Categories

| Category | Reports Available |
|----------|-------------------|
| **Sales Reports** | Daily Sales, Date-wise Sales, Product-wise Sales, Customer-wise Sales |
| **Purchase Reports** | Daily Purchases, Date-wise Purchases, Supplier-wise Purchases |
| **Financial Reports** | Profit & Loss, Gross Margin by Product, Itemized Expenses, Cash Book, Bank Book |
| **Party Reports** | Customer Receivables, Supplier Payables |
| **Inventory Reports** | Stock Valuation, Low Stock Warning, Out of Stock, Dead Stock (no sales in 30 days) |
| **Return Reports** | Sale Returns History, Purchase Returns History |
| **Tax & Discount** | Tax Summary, Discount Summary |
| **System & Audit** | Audit Logs, User Activity, Daily Closing Sheet |

### How to Use

1. Select a category → select a specific report
2. Some reports ask for a **date range**
3. Report is displayed as a formatted table
4. Option to **export to CSV** — enter filename, saved to current directory

### How Each Report Works & Affects Your Business

| Report | What It Shows | Why It Matters |
|--------|---------------|----------------|
| Daily Sales | Today's invoices with time, total, paid | Know your daily revenue instantly |
| Product-wise Sales | Which products sold, quantity, revenue | Identify best-sellers and slow-movers |
| Customer-wise Sales | Customer names, invoice count, total | See who your top customers are |
| Profit & Loss | Revenue - COGS - Expenses = Net Profit | Know if you're making money |
| Gross Margin | (Sale Price - Cost) per product | See which products have best margins |
| Stock Valuation | Current stock × cost price = total value | Know your inventory worth |
| Low Stock | Products below warning level | Reorder before you run out |
| Dead Stock | No sales in 30 days | Clear slow-moving inventory |
| Customer Receivables | Who owes you money | Follow up on payments |
| Supplier Payables | Who you owe money to | Plan your payments |
| Daily Closing Sheet | Complete day financial snapshot | End-of-day reconciliation |

---

## 9. Purchases (Menu 6)

### What It Does
Creates **purchase invoices** from suppliers. Automatically increases stock and updates supplier balance.

### How to Use
Same workflow as Sales (menu 2), but for buying:
1. Select supplier
2. Add products (search by SKU/barcode/name)
3. Enter qty, price, discount, tax, freight charges
4. Review summary
5. Make payment (full/partial) from Cash/Bank account
6. Invoice generated: `PUR-YYMMDD-NNNN`

### What Happens Behind the Scenes
- Product stock **increases**
- Product purchase price **updates** to latest
- Supplier balance **increases** (if unpaid)
- Supplier ledger gets entry
- Cash/Bank account balance **decreases** (if paid)
- Stock movement logged

---

## 10. Suppliers & Khata (Menu 7)

### What It Does
Same structure as Customers (menu 4), but for suppliers. Tracks how much you owe to each supplier.

### Key Differences from Customers
- Code prefix: `SUPP-0001`
- No credit limit field
- Payments go **to** supplier (decreases what you owe)
- Purchases increase supplier balance (what you owe)

---

## 11. Cash & Bank Accounts (Menu 8)

### What It Does
Manages your **cash in hand** and **bank accounts** with full transaction tracking.

### Default Accounts
| Account | Type |
|---------|------|
| Cash in Hand | Cash |
| Main Bank Account | Bank |

### Submenu Options
| Option | What It Does |
|--------|--------------|
| 1. View All Accounts | Shows all accounts with current balances |
| 2. Deposit (+) | Add money to an account |
| 3. Withdrawal (-) | Take money out of an account |
| 4. Fund Transfer | Move money between accounts |
| 5. Transaction Book | View last 100 transactions |

### How It Affects Other Areas
- **Sale payments** → account balance increases
- **Purchase payments** → account balance decreases
- **Expenses** → account balance decreases
- **Customer payments** → account balance increases
- **Supplier payments** → account balance decreases
- **Fund transfers** → source decreases, destination increases
- Every transaction is recorded with user and timestamp

---

## 12. Expenses (Menu 9)

### What It Does
Records business expenses (rent, electricity, salary, etc.) and tracks them by category.

### Default Expense Categories
Rent, Electricity, Salary, Maintenance, Miscellaneous

### Adding an Expense
1. Select category (or add new one)
2. Enter amount, description, paid-to vendor
3. Select date and payment account
4. Expense is recorded → account balance decreases

### How It Affects Other Areas
- Reduces the selected Cash/Bank account balance
- Expense appears in P&L report and Daily Closing Sheet
- Tracked in Cash Book as outflow

---

## 13. Returns (Menu 10)

### What It Does
Processes **sale returns** (customer returns goods) and **purchase returns** (you return goods to supplier).

### Sale Return Flow
1. Enter the original sale invoice number
2. System shows invoice items with quantities
3. Select items being returned and quantities
4. Choose refund method: **Cash/Bank refund** or **Credit note**
5. Return generated: `RET-YYMMDD-NNNN`

### What Happens (Sale Return)
- Stock **increases** (items come back)
- Customer balance **decreases** (credit note)
- Cash/Bank **decreases** (if immediate refund)
- Customer ledger gets credit entry

### Purchase Return Flow
Same concept but to supplier:
- Stock **decreases** (items sent back)
- Supplier balance **decreases**
- Cash/Bank **increases** (if refund received)

---

## 14. Shop Settings (Menu 11)

### What It Does
Configure all **system-wide settings**. Admin only.

### Settings Table

| Setting | What It Controls | Default |
|---------|-----------------|---------|
| `shop_name` | Business name on receipts | My Super Retail & Wholesale Shop |
| `shop_address` | Address on receipts | 123 Main Commercial Street |
| `phone` | Phone on receipts | 555-0199 |
| `email` | Contact email | contact@shopmanager.local |
| `currency` | Currency symbol ($, Rs, etc.) | $ |
| `tax_rate` | Default tax % for new products | 5.00 |
| `inv_prefix` | Sales invoice prefix | INV- |
| `pur_prefix` | Purchase invoice prefix | PUR- |
| `ret_prefix` | Return prefix | RET- |
| `low_stock_warn` | Low stock threshold | 10 |
| `backup_path` | Backup directory | ./backups |
| `date_format` | Date display format | %Y-%m-%d |
| `footer_msg` | Receipt footer text | Thank you for your business! |
| `allow_negative_stock` | Allow stock below zero? | 0 (No) |
| `auto_backup_exit` | Auto backup on exit? | 1 (Yes) |

### How to Use
1. Menu 11 → see all settings displayed
2. Enter the setting key name to edit
3. Enter new value → setting updates immediately
4. All modules use the new value from this point

---

## 15. Users & Security (Menu 12)

### What It Does
Manage system users, roles, passwords, and view audit logs. Admin only (except Change My Password).

### Options
| Option | What It Does | Who Can Use |
|--------|--------------|-------------|
| 1. Add New User | Create username, password, role | Admin |
| 2. View/Edit Users | See all users, toggle active/inactive | Admin |
| 3. Change My Password | Any user changes own password | All users |
| 4. View Audit Log | Complete activity log | Admin |

### Security Features
- Passwords hashed with **SHA-256 + unique salt**
- **Force password change** on first login
- **Last login** tracking per user
- Complete **audit trail** of all actions

---

## 16. Backup & Restore (Menu 13)

### What It Does
Creates and restores database backups. Admin only.

### Options
| Option | What It Does |
|--------|--------------|
| 1. Create Backup | Copies database with timestamp to backup folder |
| 2. Restore | Lists available backups — select one to restore |

### Auto Backup
When exiting the app (option 0), if `auto_backup_exit` is enabled, a backup is created automatically.

### Restore Warning
Restoring completely **replaces** the current database. The app will exit after restore — launch again to continue.

---

## 17. Import / Export CSV (Menu 14)

### What It Does
Bulk import/export master data via CSV files. Admin/Manager only.

### Export Options
- **Products**: code, name, barcode, purchase price, sale price, stock, etc.
- **Customers**: code, name, phone, address, balance
- **Suppliers**: code, name, phone, address, balance

### Import Options
- **Products**: Import from CSV — uses INSERT OR IGNORE (existing codes are skipped)
- **Customers**: Import from CSV
- **Suppliers**: Import from CSV

### How to Export
Select export type → enter filename → file saved to current directory.

### How to Import
Prepare CSV with headers → select import type → enter filename → data imported.

---

## 18. Quotations (Menu 15)

### What It Does
Creates **price quotations** for customers. Can convert accepted quotations into sale invoices.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | List all quotations with status |
| 2. Create | New quotation with products, discounts, valid-until date |
| 3. Details | See full quotation items and totals |
| 4. Convert to Sale | Convert active quotation → creates sale invoice |
| 5. Cancel | Cancel a quotation |

### Statuses
- **DRAFT** — being prepared
- **ACTIVE** — sent to customer
- **CONVERTED** — turned into a sale
- **CANCELLED** — no longer valid

### Convert to Sale Effect
Stock is deducted, sale invoice created with all quotation items carried over.

---

## 19. Sales Orders (Menu 16)

### What It Does
Books **customer orders** for future delivery. Tracks partial deliveries and advance payments.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | List all orders with status |
| 2. Create | New order with products, delivery date, advance payment |
| 3. Details | See full order including delivered vs ordered quantities |
| 4. Mark Delivered | Record partial or full delivery — updates stock |
| 5. Cancel | Cancel an order |

### How Delivery Works
- Each order item tracks `delivered_qty`
- You can deliver in multiple batches
- When `delivered_qty >= ordered_qty`, status becomes DELIVERED
- Stock deducted only when marked delivered

---

## 20. Purchase Orders (Menu 17)

### What It Does
Creates **purchase orders** to suppliers. Tracks partial stock receipts.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | List all POs with status |
| 2. Create | New PO with products, expected delivery date |
| 3. Details | See full PO including received vs ordered quantities |
| 4. Receive Stock | Record partial or full receipt — updates stock |
| 5. Cancel | Cancel a PO |

### Receive Stock Effect
Product stock increases by the received quantity, stock movement logged.

---

## 21. Delivery Challans (Menu 18)

### What It Does
Generates **delivery challans** for dispatched goods with vehicle/driver tracking.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | List all challans |
| 2. Create | Manual challan with products, vehicle no, driver info |
| 3. From Sales Order | Auto-populate challan from existing sales order |
| 4. Details | See full challan details |

### From Sales Order
Creates a challan from a sales order and marks the order as DELIVERED.

---

## 22. Warehouses (Menu 19)

### What It Does
Manages **multiple warehouses** for inventory storage and stock transfers between them.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | List all warehouses |
| 2. Add | Create a new warehouse (name, location) |
| 3. Edit | Update warehouse details |
| 4. View Stock | See stock levels per warehouse or all warehouses |
| 5. Transfer Stock | Move stock from one warehouse to another |

### Stock Transfer Effect
- Deducts from **source** warehouse
- Adds to **destination** warehouse
- Stock movements table updated

---

## 23. Credit / Debit Notes (Menu 20)

### What It Does
Issues **credit notes** to customers (reducing what they owe) and **debit notes** to suppliers (reducing what you owe).

### Credit Note (To Customer)
- Reduces customer outstanding balance
- Increases product stock (if items returned)
- Creates ledger entry

### Debit Note (To Supplier)
- Reduces supplier payable balance
- Decreases product stock (if items returned)
- Creates ledger entry

---

## 24. Employees (Menu 21)

### What It Does
Manages **employee records** — departments, designations, and salary types.

### Fields
Code, Name, Phone, Email, Department, Designation, Salary Type (FIXED or COMMISSION), Salary Amount, Commission Rate %, Joining Date.

### How It Affects Other Areas
Employees with COMMISSION salary type are used in the Commissions module (menu 22).

---

## 25. Commissions (Menu 22)

### What It Does
Calculates and tracks **employee commissions** based on sales.

### How to Use
1. **Calculate from Sales**: Select date range → system calculates commission for each commission-based employee as a percentage of their total sales
2. **View All**: See all commission entries and their paid status
3. **Mark Paid**: Mark individual or all commissions as paid

---

## 26. Loyalty Points (Menu 23)

### What It Does
Runs a **customer loyalty program** — award and redeem points.

### How to Use
| Option | What It Does |
|--------|--------------|
| 1. View Points | See all customers with their point balances |
| 2. Add/Adjust | Award points (positive) or deduct (negative) |
| 3. Redeem | Convert points to cash value (reduces customer balance) |
| 4. History | Complete loyalty transaction log |

### How It Works
1 point = some cash value (you define on redemption). Points earned/redeemed are tracked in the `loyalty_transactions` table.

---

## 27. Price Lists (Menu 24)

### What It Does
Creates **custom pricing tiers** — for example, a wholesale price list or a festival discount list.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View | See all price lists |
| 2. Create | New list (name, type: Sale or Wholesale) |
| 3. Add/Update Prices | Add products to the list with custom prices |
| 4. Apply to Products | Bulk-update product sale_prices from this list |

### Apply to Products
When you "apply" a price list, it updates the `sale_price` field of all products in the list — and records the change in price history.

---

## 28. Promotions (Menu 25)

### What It Does
Creates **percentage or fixed-discount promotions** with coupon codes.

### Creating a Promotion
1. Choose percentage or fixed amount discount
2. Set discount value, minimum purchase amount, max discount cap (for % type)
3. Optionally generate a **coupon code** (auto-generated)
4. Set start and end dates
5. Assign specific products or categories to the promotion
6. Toggle active/inactive

---

## 29. Serial Numbers (Menu 26)

### What It Does
Tracks **individual serial numbers** for products — useful for electronics, appliances, warranty tracking.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | See all registered serial numbers |
| 2. Register | Add a serial number for a product/warehouse |
| 3. Search | Find by serial number |
| 4. Update Status | Change: IN_STOCK, SOLD, RETURNED, SCRAPPED |

---

## 30. Service & Repair (Menu 27)

### What It Does
Manages **customer service and repair jobs** — from receiving to delivery.

### Full Workflow
1. **Create Job**: Customer name, product, serial number, issue description
2. **Update Status**: PENDING → IN_PROGRESS → COMPLETED → DELIVERED
3. **Add Parts**: Use products from inventory (auto-deducts stock)
4. **Set charges**: Service charges, part costs
5. **Deliver**: Mark as delivered when customer picks up

### How It Affects Other Areas
- Adding parts **deducts** stock from inventory
- Status tracking gives full job history

---

## 31. Bill of Materials (Menu 28)

### What It Does
Defines **recipes/formulas** for making finished products from raw materials.

### Example
To make 1 Cake: 200g Flour + 1 Egg + 100g Sugar + 50g Butter
- Finished Product: "Cake"
- Raw Materials: Flour, Egg, Sugar, Butter with quantities
- Wastage: 5% (some material is lost in process)

### Options
| Option | What It Does |
|--------|--------------|
| 1. View | See all BOMs |
| 2. Create | New BOM with finished product and raw materials |
| 3. Details | See BOM items with costs |
| 4. Cost Calculation | Shows raw material cost, unit cost, cost with wastage |

---

## 32. Manufacturing (Menu 29)

### What It Does
Executes **manufacturing jobs** using BOMs to produce finished goods from raw materials.

### Workflow
1. **Create Job**: Select BOM, set planned quantity → status: PLANNED
2. **Start Job**: Status → IN_PROGRESS
3. **Complete Job**:
   - Raw materials **deducted** from stock (based on BOM ratios × qty)
   - Finished product **added** to stock
   - Stock movements logged for both
   - Status → COMPLETED

### How It Affects Other Areas
- Raw material stock **decreases**
- Finished product stock **increases**
- Both movements tracked in stock_movements

---

## 33. Accounting (Menu 30)

### What It Does
Full **double-entry accounting** system — chart of accounts, general ledger, and journal entries.

### Chart of Accounts Structure
```
1 Assets
  1.1 Current Assets (Cash, Bank, Receivables, Inventory)
  1.2 Fixed Assets (Furniture, Equipment)
2 Liabilities
  2.1 Current Liabilities (Payables, Tax Payable)
  2.2 Long Term Liabilities (Bank Loans)
3 Equity (Capital, Retained Earnings)
4 Revenue (Sales)
5 Expenses (COGS, Salary, Rent, Utilities, Depreciation)
```

### Options
| Option | What It Does |
|--------|--------------|
| 1. Chart of Accounts | View the hierarchical account tree |
| 2. Add Account | New account with code, name, type, parent |
| 3. General Ledger | See all journal entries |
| 4. Account Statement | Filter by account and date range |
| 5. Post Journal Entry | Double-entry posting (debits must equal credits) |

### Journal Entry Validation
Every entry must have total debits = total credits. If not, the system rejects it.

---

## 34. Financial Statements (Menu 31)

### What It Does
Generates formal **financial statements** from the general ledger data.

### Reports
| Report | What It Shows |
|--------|---------------|
| **Trial Balance** | All accounts with debit/credit balances as of a date |
| **Profit & Loss** | Income vs Expenses for a date range + net profit/loss |
| **Balance Sheet** | Assets = Liabilities + Equity as of a date |

> Accuracy depends on proper journal entries in the Accounting module.

---

## 35. Fixed Assets (Menu 32)

### What It Does
Registers **fixed assets** (machinery, vehicles, furniture) and calculates depreciation.

### Adding an Asset
Fields: Code, Name, Category, Purchase Date, Purchase Price, Salvage Value, Useful Life (years), Location, Notes.

### Depreciation
- Method: **Straight-line**
- Formula: `(Current Value - Salvage Value) ÷ Useful Life`
- Calculates annual depreciation
- Creates entries in `depreciation_entries` table
- Updates asset's `current_value`

### Options
| Option | What It Does |
|--------|--------------|
| 1. View All | See all assets with current values |
| 2. Add | Register a new asset |
| 3. Calculate Depreciation | Run depreciation for one or all assets |
| 4. Depreciation Schedule | See depreciation history per asset |

---

## 36. Budgets (Menu 33)

### What It Does
Sets **budget targets** by account and tracks actual vs budgeted amounts.

### Creating a Budget
1. Name, Fiscal Year, Date Range, Total Amount
2. Add budget items: select accounts (Income/Expense types) and set budgeted amounts
3. System auto-calculates `actual_amount` from general ledger entries

### Budget vs Actual
Shows: Account, Budgeted Amount, Actual Amount, Variance, Percentage.

---

## 37. Cash Register (Menu 34)

### What It Does
Manages **daily cash registers** — opening balance, transactions, closing with variance tracking.

### Workflow
1. **Open Register**: Set opening balance
2. **Add Transactions**: Record cash IN/OUT during the day
3. **Close Register**: Enter actual cash count → system calculates expected vs actual variance
4. **View Transactions**: See register activity

---

## 38. Email Config (Menu 35)

### What It Does
Configure **SMTP email settings**. Currently a **placeholder** — email sending is not yet implemented.

### Options
| Option | What It Does |
|--------|--------------|
| 1. View | See current SMTP config |
| 2. Edit | Update SMTP server, port, user, password, sender details |
| 3. Test | Placeholder (no actual test) |

---

## 39. Help & Support (Menu 36)

### What It Does
Built-in **help system** with searchable topics.

### Options
| Option | What It Does | Who Can Use |
|--------|--------------|-------------|
| 1. Browse Topics | See all help topics | All |
| 2. Search | Find topic by keyword | All |
| 3. Add Topic | Create new help topic | Admin |
| 4. Edit Topic | Update existing topic | Admin |

### Pre-loaded Topics
Getting Started, Sales/POS, Purchases, Products & Inventory, Customers & Khata, Suppliers & Khata, Reports, Backup & Restore, Multi-Warehouse, Quotations, Sales Orders, Purchase Orders, Delivery Challan, Full Accounting, Service & Repair, Manufacturing/BOM, Loyalty Program, Promotions & Coupons, Price Lists, Employee Management, Fixed Assets, Budgets, Keyboard Shortcuts.

---

## 40. Utility Functions (Menu 37)

### What It Does
Quick utility tools for common system tasks.

### Options
| Option | What It Does |
|--------|--------------|
| 1. Low Stock Report | Products below warning level |
| 2. Expired Products | Products past their expiry date |
| 3. DB Statistics | Record counts for all database tables |
| 4. Bulk Price Update | Increase prices by % or set fixed amount across products |
| 5. Rebuild Stock | Recalculate all stock levels from transactions |
| 6. Clear Sample Data | Delete all sample data, keep only default logins |

### Bulk Price Update
- Choose % increase or fixed amount
- Optionally filter by category
- Updates product `sale_price` and records in `product_price_history`

### Rebuild Stock
Use this if stock levels get out of sync. It recalculates `current_stock` for all products from sales, purchases, returns, and adjustments.

### Clear Sample Data (Admin Only)
Deletes all sample/transactional data from the system while preserving:
- Default user logins (admin, manager, cashier, viewer)
- System settings and configuration (categories, brands, units)
- Chart of accounts and expense categories
- Account balances are reset to $0.00

> **Warning**: This action cannot be undone. Type `CONFIRM` to proceed. All products, customers, suppliers, employees, sales, purchases, expenses, and transactions will be permanently deleted.

---

## 41. Logout & Exit (Menus 38 & 0)

### Logout (Menu 38)
- Returns to login screen
- Audit log records the logout

### Exit (Menu 0)
- If `auto_backup_exit` is enabled, creates a backup automatically
- Prints goodbye message
- Exits the application completely

---

## 42. Keyboard Shortcuts

| Key | Context | Action |
|-----|---------|--------|
| `0` | Any menu | Go back to previous menu |
| `S` | Main menu | Global Quick Search |
| `DONE` | Cart entry | Finish adding items |
| `Y` / `N` | Confirm prompts | Yes / No |
| `Enter` | Input prompts | Accept default / submit |

### Global Search (S)
Searches across all:
- **Products** by SKU or name (shows stock, price)
- **Customers/Suppliers** by name or phone (shows balance)
- **Invoices** by invoice number (shows date, total)

---

## 43. Sample Data & Default Values

### Default Login
| Username | Password | Role |
|----------|----------|------|
| `admin` | `admin123` | Admin |
| `manager` | `manager123` | Manager |
| `cashier` | `cashier123` | Cashier |
| `viewer` | `viewer123` | Viewer |

### Default Accounts (Cash/Bank)
| Account | Type |
|---------|------|
| Cash in Hand | Cash |
| Main Bank Account | Bank |

### Default Expense Categories
Rent, Electricity, Salary, Maintenance, Miscellaneous

### Default Settings

| Setting | Default |
|---------|---------|
| Currency | `$` |
| Tax Rate | `5%` |
| Low Stock Warning | `10` units |
| Invoice Prefix | `INV-` |
| Purchase Prefix | `PUR-` |
| Return Prefix | `RET-` |
| Allow Negative Stock | `No` |
| Auto Backup on Exit | `Yes` |

### Sample Product Categories
Groceries, Beverages, Snacks, Dairy, Bakery

### Sample Brands
Nestle, Kraft, P&G, Unilever, Local

### Sample Units
Pcs, Kg, Liter, Packet, Dozen

### Default Warehouses
Main Warehouse

### Default Chart of Accounts
- Assets: Cash in Hand, Bank Accounts, Accounts Receivable, Inventory, Fixed Assets
- Liabilities: Accounts Payable, Tax Payable, Bank Loans
- Equity: Capital Account, Retained Earnings
- Revenue: Retail Sales, Wholesale Sales
- Expenses: Cost of Goods Sold, Salary, Rent, Utilities, Depreciation

### Password Policy (Default)
| Rule | Value |
|------|-------|
| Min Length | 6 |
| Require Uppercase | No |
| Require Lowercase | No |
| Require Digit | No |
| Require Special | No |
| Max Age | 90 days |
| Max Login Attempts | 5 |
| Lockout Duration | 30 minutes |

---

## 44. System Behaviors — How Things Work Together

### Stock Flow
```
                    +-----------+
                    | PURCHASE  | ---> Stock INCREASES
                    +-----------+
                         |
                         v
    +--------+     +----------+     +----------+
    | SALE   | <---| INVENTORY|--->| ADJUST   |
    | (dec)  |     | (stock)  |     | (+/-)    |
    +--------+     +----------+     +----------+
         |              ^                ^
         v              |                |
    +----------+   +----------+    +-----------+
    | SALE     |   | MANUFACT |    | SERVICE   |
    | RETURN   |   | (adds)   |    | (uses     |
    | (inc)    |   |          |    |  parts)   |
    +----------+   +----------+    +-----------+
```

### Customer Balance Flow
```
SALE (credit)  ---> Customer Balance INCREASES (debit)
PAYMENT        ---> Customer Balance DECREASES (credit)
SALE RETURN    ---> Customer Balance DECREASES (credit note)
CREDIT NOTE    ---> Customer Balance DECREASES
```

### Supplier Balance Flow
```
PURCHASE (credit) --> Supplier Balance INCREASES (credit)
PAYMENT           --> Supplier Balance DECREASES (debit)
PURCHASE RETURN   --> Supplier Balance DECREASES (debit)
DEBIT NOTE        --> Supplier Balance DECREASES
```

### Cash/Bank Account Flow
```
SALE PAYMENT IN     --> Balance INCREASES
PURCHASE PAYMENT    --> Balance DECREASES
EXPENSE PAID        --> Balance DECREASES
CUSTOMER PAYMENT    --> Balance INCREASES
SUPPLIER PAYMENT    --> Balance DECREASES
DEPOSIT             --> Balance INCREASES
WITHDRAWAL          --> Balance DECREASES
FUND TRANSFER (from)--> Balance DECREASES
FUND TRANSFER (to)  --> Balance INCREASES
```

### Invoice Numbering Format
| Type | Format | Example |
|------|--------|---------|
| Sales | `inv_prefix + YYMMDD + - + NNNN` | INV-260623-0001 |
| Purchases | `pur_prefix + YYMMDD + - + NNNN` | PUR-260623-0001 |
| Returns | `ret_prefix + YYMMDD + - + NNNN` | RET-260623-0001 |

### Party Code Format
| Type | Format | Example |
|------|--------|---------|
| Customer | `CUST-` + 4-digit sequence | CUST-0001 |
| Supplier | `SUPP-` + 4-digit sequence | SUPP-0001 |

### Database
- **File**: `shop_manager.db` (auto-created in the app directory)
- **Backups**: Stored in `./backups/` folder with timestamp
- **71 tables** covering all features
- All monetary values stored as TEXT for precision (Decimal type in Python)

---

> **Shop Manager** — Complete Business Management Solution
>
> GitHub: [https://github.com/yasinULLAH/ShopManageCMD](https://github.com/yasinULLAH/ShopManageCMD)
