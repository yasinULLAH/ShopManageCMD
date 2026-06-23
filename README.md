# Shop Manager - Complete Business Management System

<div align="center">

[![GitHub Repo](https://img.shields.io/badge/GitHub-ShopManageCMD-blue?style=flat-square&logo=github)](https://github.com/yasinULLAH/ShopManageCMD)
[![Python](https://img.shields.io/badge/Python-3.8+-green?style=flat-square&logo=python)](https://python.org)
[![SQLite](https://img.shields.io/badge/Database-SQLite-blue?style=flat-square)](https://sqlite.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
![Platform](https://img.shields.io/badge/Platform-Windows|Linux|Mac-lightgrey?style=flat-square)

</div>

## English Documentation

---

### Overview

Shop Manager is a complete, terminal-based retail and wholesale business management system built in Python with SQLite database. It provides comprehensive tools for managing sales, purchases, inventory, accounting, customers, suppliers, employees, and much more — all from a command-line interface.

### Technology Stack

- **Language**: Python 3
- **Database**: SQLite (single file: `shop_manager.db`)
- **Interface**: Terminal/Console (CLI)
- **OS**: Windows/Linux/Mac compatible

### How to Run

```bash
# Windows (the CMD window will auto-maximize on launch)
python ShopApp.cmd

# Linux/Mac
python3 ShopApp.cmd
```

### Default Login Credentials

> **Username**: `admin` · **Password**: `admin123` · **Role**: Admin (full access)
>
> **Username**: `manager` · **Password**: `manager123` · **Role**: Manager (operations)
>
> **Username**: `cashier` · **Password**: `cashier123` · **Role**: Cashier (POS/sales)
>
> **Username**: `viewer` · **Password**: `viewer123` · **Role**: Viewer (read-only)

**IMPORTANT**: Change default passwords immediately after first login.

---

## Console & Interface Enhancements

This application includes several console optimizations for a seamless terminal experience:

### Auto Fullscreen Mode
- The CMD window automatically maximizes on launch for maximum visibility
- No need to manually press Alt+Enter or resize the window
- Works on Windows (other OSes use default terminal behavior)

### Scrollbar-Free Display
- Console buffer height is set equal to window height
- No scrollbars appear on menus — all content fits on screen
- Input prompt is always visible at the bottom without scrolling

### Two-Column Main Menu Layout
- The main menu (38+ options) is displayed in a compact 2-column grid
- Reduces vertical space usage by ~50% (19 rows instead of 38+)
- All options visible at a glance without any scrolling

### Usage-Based Menu Ordering
- Menu items are ordered by real-world usage frequency
- **Daily drivers** at top: Dashboard, Sales, Products, Customers, Reports
- **Weekly tasks** in middle: Purchases, Suppliers, Accounts, Expenses, Returns
- **Specialized modules** below: Settings, Security, Backup, CSV, Orders, etc.
- **Advanced features** further down: Accounting, Manufacturing, BOM, etc.

---

## Complete Feature Modules

---

### 1. Dashboard & Today Summary (Main Menu Option 1)

**English**: Provides a real-time executive overview of your business for the current day.


**اردو**: آج کے کاروبار کا مکمل جائزہ - آج کی فروخت، خریداری، نقد آمدنی، اخراجات، اور منافع کا تخمینہ۔

**Displays**:
- Today's Sales Total / آج کی کل فروخت
- Today's Purchases Total / آج کی کل خریداری
- Cash Received & Cash Paid Out / نقد آمدنی اور نقد اخراج
- Today's Expenses / آج کے اخراجات
- Estimated Net Profit / تخمینہ خالص منافع
- Low Stock Items Count / کم اسٹاک اشیاء کی تعداد
- Available Cash/Bank Balances / دستیاب نقد/بینک بیلنس
- Customer Outstanding Balances (Receivables) / صارفین کے بقایا جات
- Supplier Outstanding Balances (Payables) / سپلائرز کے بقایا جات
- Pending Sales/Purchases Balance / زیر التوازن فروخت/خریداری

**Effects Throughout App**: All values are calculated live from actual transactions. Sales, purchases, expenses, and payments entered elsewhere automatically update the dashboard.

---

### 2. Sales / POS Terminal (Main Menu Option 2)

**English**: Point-of-Sale billing system for creating sales invoices.

**اردو**: پوائنٹ آف سیل - سیل انوائس بنانے کا نظام۔ واک ان کسٹمر اور رجسٹرڈ دونوں کے لیے۔

**Features**:
- Create new sale invoices with multiple products / متعدد پروڈکٹس کے ساتھ نیا سیل انوائس بنائیں
- Search products by SKU, Barcode, or Name / SKU، بارکوڈ، یا نام سے پروڈکٹ تلاش کریں
- Supports Walk-in Customers and Registered Customers / واک ان اور رجسٹرڈ دونوں صارفین
- Per-item discount and tax calculation / فی آئٹم ڈسکاؤنٹ اور ٹیکس
- Overall additional discount / مجموعی اضافی ڈسکاؤنٹ
- Partial or full payment processing / جزوی یا مکمل ادائیگی
- Credit sales allowed ONLY for registered customers / صرف رجسٹرڈ صارفین کے لیے ادھار
- Automatic stock deduction on sale / فروخت پر خودکار اسٹاک کٹوتی
- Automatic customer ledger update (Khata) / خودکار کسٹمر کھاتا اپڈیٹ
- Automatic cash/bank account update / خودکار نقد/بینک اکاؤنٹ اپڈیٹ
- Print/save receipt to text file / رسید پرنٹ/سیو کریں

**Effects Throughout App**:
- Product stock decreases automatically
- Customer balance increases (if credit sale)
- Cash/Bank account balance increases (if paid)
- Customer ledger gets debit entry
- Sale recorded for reports
- Stock movement log updated

---

### 3. Products & Inventory Masters (Main Menu Option 3)

**English**: Complete product catalog and inventory management.

**اردو**: مکمل پروڈکٹ کیٹلاگ اور انوینٹری مینجمنٹ۔

**Sub-Features**:

#### 4.1 Manage Categories
- Add/Edit/Delete product categories / پروڈکٹ زمرے شامل/تبدیل/حذف کریں
- Cannot delete if products are assigned / اگر پروڈکٹس منسوب ہوں تو حذف نہیں ہوگا

#### 4.2 Manage Brands
- Add/Edit/Delete brands / برانڈز شامل/تبدیل/حذف کریں

#### 4.3 Manage Units
- Add/Edit/Delete measurement units (pcs, kg, liter, etc.) / پیمائش کی اکائیاں

#### 4.4 Manage Products/Items
- **Add New Product**: Code/SKU, Barcode, Name, Category, Brand, Unit, Purchase Price, Sale Price, Wholesale Price, Retail MSRP, Minimum Stock Warning, Opening Stock, Tax %, Discount Allowed, Expiry Date, Batch Number, Rack Location / نئی پروڈکٹ شامل کریں
- **Edit Product**: Update all fields with automatic price history tracking / پروڈکٹ میں ترمیم - قیمت کی تاریخ خودکار
- **Search Product**: By SKU, Barcode, or Name / تلاش
- **Deactivate/Activate**: Soft delete products / پروڈکٹ غیر فعال/فعال کریں

#### 4.5 View Inactive Products
- List all deactivated products / غیر فعال پروڈکٹس کی فہرست

#### 4.6 Manual Stock Adjustment
- Increase (+) or Decrease (-) stock manually / دستی اسٹاک ایڈجسٹمنٹ
- Requires reason for adjustment / وجہ درکار
- Records in stock_adjustments and stock_movements tables / ریکارڈ محفوظ

#### 4.7 Product Price Update History
- View complete price change history per product / پروڈکٹ کی قیمت کی مکمل تاریخ
- Shows old price, new price, changed by, date/time / پرانی قیمت، نئی قیمت، کس نے بدلی، تاریخ

#### 4.8 Product Stock Movement History
- Complete ledger of all stock movements / تمام اسٹاک تحریکات کا ریکارڈ
- Types: SALE, PURCHASE, RETURN, ADJUSTMENT_IN, ADJUSTMENT_OUT, OPENING / اقسام

**Effects Throughout App**: Products are referenced in all sales, purchases, returns, reports, and inventory modules. Price changes are tracked for audit.

---

### 4. Customers & Khata Ledger (Main Menu Option 4)

**English**: Complete customer management with credit ledger (Khata) system.

**اردو**: مکمل کسٹمر مینجمنٹ کھاتا سسٹم کے ساتھ۔

**Features**:
- **Add Customer**: Auto-generated code (CUST-0001), Name, Phone, Address, Email, Opening Balance, Credit Limit / نیا کسٹمر شامل کریں
- **View All Customers**: List with balance and status / تمام کسٹمرز کی فہرست
- **Edit Customer**: Update details and credit limit / ترمیم
- **Search Customer**: By code, name, or phone / تلاش
- **Customer Ledger/Khata Statement**: Complete debit/credit transaction history with running balance / کھاتا بیان - مکمل ڈیبٹ/کریڈٹ تاریخ
- **Receive Payment**: Accept payment from customer against outstanding balance / ادائیگی وصول کریں
- **Deactivate/Activate**: Toggle customer status / غیر فعال/فعال کریں

**Effects Throughout App**:
- Customer balance updated on sales (credit increases balance)
- Customer balance reduced on payments (credit reduces balance)
- Ledger entries created for every transaction
- Cash/Bank account updated on payment receipt
- Credit limit enforced (warning only, not blocking)

---

### 5. Reports & Analytics (Main Menu Option 5)

**English**: 25+ comprehensive reports across all business areas. All reports can be exported to CSV.

**اردو**: 25+ جامع رپورٹس - تمام کاروباری شعبوں میں۔ تمام رپورٹس CSV میں ایکسپورٹ ہو سکتی ہیں۔

**Report Categories**:

#### Sales Reports
1. Daily Sales Report (Today) / آج کی فروخت
2. Date-wise Sales Report / تاریخ وار فروخت
3. Product-wise Sales Report / پروڈکٹ وار فروخت
4. Customer-wise Sales Report / کسٹمر وار فروخت

#### Purchase Reports
5. Daily Purchase Report / آج کی خریداری
6. Date-wise Purchase Report / تاریخ وار خریداری
7. Supplier-wise Purchase Report / سپلائر وار خریداری

#### Financial Reports
8. Profit & Loss Statement (Revenue - COGS - Expenses) / منافع اور نقصان
9. Gross Profit / Product Margin Report / خام منافع
10. Itemized Expense Report / تفصیلی اخراجات
11. Cash Book Ledger / نقد بک
12. Bank Book Ledger / بینک بک

#### Party Khata Reports
13. Customer Receivables (who owes us) / کسٹمر بقایا جات
14. Supplier Payables (who we owe) / سپلائر بقایا جات

#### Inventory Reports
15. Full Stock Valuation (Cost Value + Retail Value) / مکمل اسٹاک ویلیوایشن
16. Low Stock Warning Report / کم اسٹاک وارننگ
17. Out of Stock Report / خالی اسٹاک رپورٹ
18. Dead/Slow Moving Stock (no sales in 30 days) / مردہ اسٹاک

#### Return Reports
19. Sale Returns History / فروخت واپسی
20. Purchase Returns History / خریداری واپسی

#### Tax & Discount Reports
21. Tax Summary (Sales Tax Collected - Purchase Tax Paid) / ٹیکس خلاصہ
22. Total Sales Discounts Given / کل ڈسکاؤنٹس

#### System & Audit Reports
23. Audit Logs (Latest 100) / آڈٹ لاگز
24. User Activity Report / صارف سرگرمی
25. Daily Closing Financial Sheet / روزانہ کلوزنگ شیٹ

---

### 6. Purchases Management (Main Menu Option 6)

**English**: Manage purchase invoices from suppliers.

**اردو**: سپلائرز سے خریداری کے انوائس کا انتظام۔

**Features**:
- Create purchase invoices with batch/expiry tracking / بیچ/ایکسپائری ٹریکنگ کے ساتھ خریداری انوائس
- Search products by SKU/Barcode/Name / پروڈکٹ تلاش کریں
- Per-item discount and tax / فی آئٹم ڈسکاؤنٹ اور ٹیکس
- Freight/extra charges support / فریٹ/اضافی چارجز
- Automatic stock addition on purchase / خریداری پر خودکار اسٹاک اضافہ
- Automatic supplier ledger update / خودکار سپلائر کھاتا اپڈیٹ
- Automatic purchase price update / خودکار خریداری قیمت اپڈیٹ
- Partial/full payment to supplier / سپلائر کو جزوی/مکمل ادائیگی

**Effects Throughout App**:
- Product stock increases
- Product purchase price updates to latest
- Supplier balance increases (if unpaid)
- Supplier ledger gets entry
- Cash/Bank account decreases (if paid)
- Stock movement log updated

---

### 7. Suppliers & Khata Ledger (Main Menu Option 7)

**English**: Complete supplier management with payable ledger system.

**اردو**: مکمل سپلائر مینجمنٹ payable کھاتا سسٹم کے ساتھ۔

**Features**: Same structure as Customers module
- Auto-generated code (SUPP-0001) / خودکار کوڈ
- Opening balance support / اوپننگ بیلنس
- Payment to supplier / سپلائر کو ادائیگی
- Complete supplier ledger / مکمل سپلائر کھاتا

**Effects Throughout App**:
- Supplier balance increases on purchase (credit)
- Supplier balance decreases on payment
- Ledger and cash/bank accounts updated

---

### 8. Cash & Bank Accounts (Main Menu Option 8)

**English**: Manage cash in hand and bank accounts with full transaction tracking.

**اردو**: نقد اور بینک اکاؤنٹس کا مکمل انتظام۔

**Features**:
- View all accounts with current balances / تمام اکاؤنٹس موجودہ بیلنس کے ساتھ
- Cash/Bank Deposit (+) / نقد/بینک ڈپازٹ
- Cash/Bank Withdrawal (-) / نقد/بینک وڈڈرا
- Fund Transfer between accounts / اکاؤنٹس کے درمیان فنڈ ٹرانسفر
- Transaction Book - view all transactions / ٹرانزیکشن بک

**Default Accounts**: "Cash in Hand" (CASH) and "Main Bank Account" (BANK)

**Effects Throughout App**: Every sale payment, purchase payment, expense, and party payment flows through these accounts. Balances update automatically.

---

### 9. Expenses Manager (Main Menu Option 9)

**English**: Record and track business expenses.

**اردو**: کاروباری اخراجات ریکارڈ اور ٹریکنگ۔

**Features**:
- **Add Expense**: Select category, amount, description, paid-to vendor, date, paying account / اخراجات شامل کریں
- **View All Expenses**: Filtered by date with category and user who logged / تمام اخراجات دیکھیں
- **Manage Categories**: Add custom expense categories (Rent, Electricity, Salary, etc.) / اخراجات کی اقسام

**Default Categories**: Rent, Electricity, Salary, Maintenance, Miscellaneous

**Effects Throughout App**:
- Expense reduces the paying cash/bank account balance
- Expense reflected in Profit & Loss reports
- Cash book shows the outflow
- Daily closing sheet includes expenses

---

### 10. Returns Processing (Main Menu Option 10)

**English**: Process sale returns and purchase returns.

**اردو**: فروخت اور خریداری واپسی پروسیس کریں۔

**Sale Return Effects**:
- Stock increases (items return to inventory)
- Customer balance decreases (credit note)
- Customer ledger gets credit entry
- Cash/Bank decreases if immediate refund
- Return number generated (RET-prefix)

**Purchase Return Effects**:
- Stock decreases (items leave inventory)
- Supplier balance decreases
- Supplier ledger gets debit entry
- Cash/Bank increases if refund received

---

### 11. Shop Settings (Main Menu Option 11)

**English**: Configure all system-wide settings. Admin only.

**اردو**: سسٹم کی تمام سیٹنگز - صرف ایڈمن۔

**Configurable Settings**:
| Setting | Description | Default |
|---------|-------------|---------|
| shop_name | Business name | My Super Retail & Wholesale Shop |
| shop_address | Business address | 123 Main Commercial Street |
| phone | Phone number | 555-0199 |
| email | Email | contact@shopmanager.local |
| currency | Currency symbol | $ |
| tax_rate | Default tax percentage | 5.00 |
| inv_prefix | Sales invoice prefix | INV- |
| pur_prefix | Purchase invoice prefix | PUR- |
| ret_prefix | Return prefix | RET- |
| low_stock_warn | Low stock warning level | 10 |
| backup_path | Backup folder path | ./backups |
| date_format | Date format | %Y-%m-%d |
| footer_msg | Receipt footer message | Thank you for your business! |

**Effects Throughout App**: These settings control invoice numbering, receipt formatting, default tax rates, currency display, and backup locations across ALL modules.

---

### 12. Users & Security Control (Main Menu Option 12)

**English**: Manage system users, roles, passwords, and audit logs. Admin only.

**اردو**: سسٹم صارفین، رولز، پاس ورڈز اور آڈٹ لاگز - صرف ایڈمن۔

**Features**:
- **Add New User**: Username, Password, Role selection / نیا صارف شامل کریں
- **View/Edit Users**: See all users, deactivate/activate / صارفین دیکھیں/تبدیل کریں
- **Change My Password**: Any user can change own password / اپنا پاس ورڈ تبدیل کریں
- **View Audit Log**: Complete system activity log / آڈٹ لاگ دیکھیں

**User Roles**:
| Role | Permissions |
|------|-------------|
| Admin | Full access to everything / مکمل رسائی |
| Manager | Most operations except user management & settings / زیادہ تر رسائی |
| Cashier | Sales, POS, Quotations, Loyalty, Service, Cash Register / سیل، POS |
| Viewer | Read-only access to reports and data / صرف دیکھ سکتا ہے |

**Security Features**:
- SHA-256 password hashing with unique salt per user / پاس ورڈ ہیشنگ
- Force password change on first login / پہلی لاگن پر پاس ورڈ تبدیلی لازمی
- Last login tracking / آخری لاگن ٹریکنگ
- Complete audit trail of all actions / تمام اعمال کا آڈٹ ٹریل

---

### 13. Backup & Restore DB (Main Menu Option 13)

**English**: Create and restore database backups. Admin only.

**اردو**: ڈیٹابیس بیک اپ اور بحالی - صرف ایڈمن۔

**Features**:
- Create manual backup (timestamped .db file) / دستی بیک اپ
- Restore from any available backup / بیک اپ سے بحالی
- Auto-backup on application exit (configurable) / ایپ بند ہونے پر خودکار بیک اپ
- Backup folder: ./backups/

**Effects**: Restore completely replaces current database with selected backup. Application restarts after restore.

---

### 14. Import / Export Data CSV (Main Menu Option 14)

**English**: Bulk data import/export via CSV files.

**اردو**: CSV فائلز کے ذریعے بلک ڈیٹا امپورٹ/ایکسپورٹ۔

**Export Options**:
- Products Master CSV / پروڈکٹس
- Customers Master CSV / کسٹمرز
- Suppliers Master CSV / سپلائرز

**Import Options**:
- Import Products from CSV (code, barcode, name, purchase price, sale price, stock) / پروڈکٹس امپورٹ
- Import Customers from CSV (code, name, phone, address) / کسٹمرز امپورٹ
- Import Suppliers from CSV (code, name, phone, address) / سپلائرز امپورٹ

**Note**: Import uses INSERT OR IGNORE - existing records with same code are skipped.

---

### 15. Quotations (Main Menu Option 15)

**English**: Create price quotations for customers. Convert to sale when accepted.

**اردو**: کسٹمرز کے لیے قیمت کوٹیشنز۔ منظور ہونے پر سیل میں تبدیل۔

**Features**:
- Create quotation with multiple products / کوٹیشن بنائیں
- Per-item discount, tax, and global discount / ڈسکاؤنٹ، ٹیکس
- Valid-until date tracking / میعاد کی تاریخ
- Status: DRAFT, ACTIVE, CONVERTED, CANCELLED / اسٹیٹس
- Convert active quotation directly to sale invoice / کوٹیشن کو سیل انوائس میں تبدیل کریں
- Cancel quotations / کوٹیشن منسوخ کریں

**Effects on Conversion**: When converted to sale, stock is deducted and sale invoice is created with all quotation details.

---

### 16. Sales Orders (Main Menu Option 16)

**English**: Book orders for future delivery with partial payment tracking.

**اردو**: مستقبل کی ڈیلیوری کے لیے آرڈرز بک کریں۔

**Features**:
- Create sales order with products / سیل آرڈر بنائیں
- Track ordered vs delivered quantities / آرڈر بمقابلہ ڈیلیور مقدار
- Advance/partial payment support / ایڈوانس ادائیگی
- Status: PENDING, DELIVERED, CANCELLED / اسٹیٹس
- Mark items as delivered (updates stock) / ڈیلیورڈ مارک کریں
- Delivery date tracking / ڈیلیوری تاریخ

**Effects**: When marked delivered, stock is deducted. Sales orders can be converted to delivery challans.

---

### 17. Purchase Orders (Main Menu Option 17)

**English**: Create purchase orders to suppliers. Track received quantities.

**اردو**: سپلائرز کے لیے خریداری آرڈرز۔ موصول مقدار ٹریک کریں۔

**Features**:
- Create PO with products / خریداری آرڈر بنائیں
- Expected delivery date / متوقع ڈیلیوری تاریخ
- Track ordered vs received quantities / آرڈر بمقابلہ موصول مقدار
- Receive stock against PO (updates stock) / اسٹاک موصول کریں
- Status: PENDING, RECEIVED, CANCELLED / اسٹیٹس

**Effects**: When stock is received against PO, product stock increases and stock movement is logged.

---

### 18. Delivery Challans (Main Menu Option 18)

**English**: Generate delivery challans for dispatched goods with vehicle/driver tracking.

**اردو**: ڈیلیوری چالان - گاڑی/ڈرائیور ٹریکنگ کے ساتھ۔

**Features**:
- Create manual delivery challan / دستی چالان بنائیں
- Create challan from Sales Order (auto-populates items) / سیل آرڈر سے چالان
- Track vehicle number, driver name, driver phone / گاڑی نمبر، ڈرائیور
- Notes support / نوٹس
- View challan details / چالان تفصیلات

**Effects**: Creating challan from Sales Order automatically marks the order as DELIVERED.

---

### 19. Warehouses & Stock Transfer (Main Menu Option 19)

**English**: Multi-warehouse inventory management.

**اردو**: متعدد گودام/ویئر ہاؤس انوینٹری مینجمنٹ۔

**Features**:
- View/Add/Edit warehouses / گودام دیکھیں/شامل/تبدیل کریں
- View stock per warehouse / فی گودام اسٹاک دیکھیں
- Transfer stock between warehouses / گوداموں کے درمیان اسٹاک ٹرانسفر
- Stock movement log updated automatically / اسٹاک تحریک خودکار اپڈیٹ

**Effects**: Stock transfers deduct from source warehouse and add to destination warehouse. Stock movements table is updated.

---

### 20. Credit / Debit Notes (Main Menu Option 20)

**English**: Issue credit notes to customers and debit notes to suppliers.

**اردو**: کسٹمرز کو کریڈٹ نوٹ اور سپلائرز کو ڈیبٹ نوٹ جاری کریں۔

**Credit Note** (to customer):
- Reduces customer outstanding balance / کسٹمر بیلنس کم کرتا ہے
- Increases product stock (if items returned) / اسٹاک بڑھاتا ہے
- Creates ledger entry / کھاتا اندراج

**Debit Note** (to supplier):
- Reduces supplier payable balance / سپلائر بیلنس کم کرتا ہے
- Decreases product stock (if items returned) / اسٹاک کم کرتا ہے
- Creates ledger entry / کھاتا اندراج

---

### 21. Employees (Main Menu Option 21)

**English**: Employee management with department, designation, and salary tracking.

**اردو**: ایمپلائیز مینجمنٹ - محکمہ، عہدہ، تنخواہ۔

**Features**:
- Add/Edit/Toggle Active employees / ایمپلائیز شامل/تبدیل/فعال
- Code, Name, Phone, Email, Department, Designation / کوڈ، نام، فون، ای میل
- Salary Type: FIXED or COMMISSION / تنخواہ کی قسم
- Salary Amount / تنخواہ رقم
- Commission Rate % / کمیشن ریٹ
- Joining Date / شمولیت تاریخ

---

### 22. Commissions (Main Menu Option 22)

**English**: Calculate and track employee commissions based on sales.

**اردو**: فروخت کی بنیاد پر ایمپلائز کمیشن کا حساب۔

**Features**:
- View all commission entries / تمام کمیشن اندراجات
- Calculate commissions from sales for commission-based employees / فروخت سے کمیشن نکالیں
- Set date range for calculation / تاریخ کی حد
- Mark commissions as paid (individual or bulk) / ادائیگی مارک کریں

**Effects**: Commissions are calculated as percentage of total sales by the employee within the date range.

---

### 23. Loyalty Points (Main Menu Option 23)

**English**: Customer loyalty program - award and redeem points.

**اردو**: کسٹمر لائلٹی پروگرام - پوائنٹس دیں اور استعمال کریں۔

**Features**:
- View all customers with points balance / پوائنٹس بیلنس دیکھیں
- Add/Adjust points (positive = earn, negative = redeem) / پوائنٹس شامل/ایڈجسٹ
- Redeem points for cash value / پوائنٹس کو نقد قیمت میں تبدیل کریں
- Complete loyalty transaction history / مکمل لائلٹی ٹرانزیکشن تاریخ

**Effects**: Redeeming points reduces customer point balance. Points earned/redeemed are tracked in loyalty_transactions table.

---

### 24. Price Lists (Main Menu Option 24)

**English**: Create custom price lists for specific products or customer groups.

**اردو**: مخصوص پروڈکٹس یا کسٹمر گروپس کے لیے کسٹم پرائس لسٹس۔

**Features**:
- Create price list (Sale or Wholesale type) / پرائس لسٹ بنائیں
- Add/update prices for products in the list / پروڈکٹس کی قیمتیں مقرر کریں
- Per-product sale price, wholesale price, discount percentage / فی پروڈکٹ قیمت
- Apply price list to update all products' sale prices at once / ایک بار میں تمام قیمتیں اپڈیٹ کریں

**Effects**: When a price list is "applied", it bulk-updates the sale_price field of all products in the list.

---

### 25. Promotions & Coupons (Main Menu Option 25)

**English**: Create percentage or fixed-discount promotions with coupon codes.

**اردو**: فیصد یا فکسڈ ڈسکاؤنٹ پروموشنز کوپن کوڈز کے ساتھ۔

**Features**:
- Create promotion (Percentage or Fixed type) / پروموشن بنائیں
- Set discount value / ڈسکاؤنٹ ویلیو
- Minimum purchase requirement / کم از کم خریداری شرط
- Maximum discount cap (for percentage type) / زیادہ سے زیادہ ڈسکاؤنٹ کی حد
- Coupon code generation / کوپن کوڈ
- Start and end date tracking / شروعات اور اختتام تاریخ
- Toggle active/inactive / فعال/غیر فعال
- Assign specific products or categories to promotion / مخصوص پروڈکٹس/زمرے منسوب کریں

---

### 26. Serial Numbers (Main Menu Option 26)

**English**: Track individual product serial numbers for warranty and service.

**اردو**: وارنٹی اور سروس کے لیے پروڈکٹ سیریل نمبرز ٹریکنگ۔

**Features**:
- Register serial numbers for products / سیریل نمبر رجسٹر کریں
- Search by serial number / سیریل نمبر سے تلاش
- Update status: IN_STOCK, SOLD, RETURNED, SCRAPPED / اسٹیٹس اپڈیٹ
- Track warehouse assignment / گودام اسائنمنٹ

---

### 27. Service / Repair Jobs (Main Menu Option 27)

**English**: Track customer service and repair jobs with parts used and charges.

**اردو**: کسٹمر سروس اور مرمت کے کام - استعمال شدہ پارٹس اور چارجز کے ساتھ۔

**Features**:
- Create service job (customer, product, serial, issue description) / سروس جاب بنائیں
- Update status: PENDING, IN_PROGRESS, COMPLETED, DELIVERED, CANCELLED / اسٹیٹس اپڈیٹ
- Add parts used from inventory (auto-deducts stock) / استعمال شدہ پارٹس شامل کریں
- Set service charges / سروس چارجز مقرر کریں
- Track received and delivered dates / تاریخ ٹریکنگ
- Notes support / نوٹس

**Effects**: Adding parts deducts from product stock. Service charges can be added to customer balance.

---

### 28. Bill of Materials (BOM) (Main Menu Option 28)

**English**: Define recipes/formulas for manufacturing finished products from raw materials.

**اردو**: تیار شدہ پروڈکٹس کے لیے بل آف میٹریلز - خام مال سے تیار پروڈکٹ بنانے کا فارمولا۔

**Features**:
- Create BOM with name and finished product / BOM بنائیں
- Set output quantity and wastage percentage / آؤٹ پٹ مقدار اور ضائع فیصد
- Add raw materials with quantities / خام مال شامل کریں
- View BOM details with cost calculation / تفصیلات لاگت کے ساتھ
- Calculate unit cost with wastage / فی یونٹ لاگت

**Effects**: BOMs are used by the Manufacturing module to calculate raw material requirements.

---

### 29. Manufacturing Jobs (Main Menu Option 29)

**English**: Execute manufacturing jobs using BOMs to produce finished goods.

**اردو**: مینوفیکچرنگ جابز - BOM استعمال کر کے تیار شدہ پروڈکٹس بنائیں۔

**Features**:
- Create manufacturing job from existing BOM / مینوفیکچرنگ جاب بنائیں
- Set planned quantity / منصوبہ بند مقدار
- Start job (status: PLANNED -> IN_PROGRESS) / جاب شروع کریں
- Complete job: Automatically deducts raw materials and adds finished product / جاب مکمل
- Track produced vs planned quantities / پیدا شدہ بمقابلہ منصوبہ بند

**Effects on Completion**:
- Raw material stock is deducted based on BOM ratios
- Finished product stock is increased
- Stock movements logged for both consumption and output
- Job status updated to COMPLETED

---

### 30. Accounting - Chart of Accounts / General Ledger (Main Menu Option 30)

**English**: Full double-entry accounting system with chart of accounts and journal entries.

**اردو**: مکمل ڈبل انٹری اکاؤنٹنگ سسٹم - چارٹ آف اکاؤنٹس اور جریدہ اندراجات۔

**Features**:
- **Chart of Accounts**: View hierarchical account structure / چارٹ آف اکاؤنٹس
- **Add Account**: Code, Name, Type (ASSET, LIABILITY, EQUITY, INCOME, EXPENSE), Parent ID / نیا اکاؤنٹ
- **General Ledger**: View all journal entries / جنرل لیجر
- **Account Statement**: Filter by account and date range / اکاؤنٹ بیان
- **Post Journal Entry**: Double-entry journal posting (must balance debit=credit) / جریدہ اندراج

**Default Chart of Accounts**:
```
1 Assets
  1.1 Current Assets
    1.1.1 Cash in Hand
    1.1.2 Bank Accounts
    1.1.3 Accounts Receivable
    1.1.4 Inventory
  1.2 Fixed Assets
    1.2.1 Furniture & Fixtures
    1.2.2 Equipment
2 Liabilities
  2.1 Current Liabilities
    2.1.1 Accounts Payable
    2.1.2 Tax Payable
  2.2 Long Term Liabilities
    2.2.1 Bank Loans
3 Equity
  3.1 Owner Equity
    3.1.1 Capital Account
    3.1.2 Retained Earnings
4 Revenue
  4.1 Sales Revenue
    4.1.1 Retail Sales
    4.1.2 Wholesale Sales
5 Expenses
  5.1 Operating Expenses
    5.1.1 Cost of Goods Sold
    5.1.2 Salary Expenses
    5.1.3 Rent Expenses
    5.1.4 Utility Expenses
    5.1.5 Depreciation
```

---

### 31. Financial Statements (Main Menu Option 31)

**English**: Generate formal financial statements from general ledger data.

**اردو**: جنرل لیجر ڈیٹا سے مالیاتی بیانات۔

**Statements**:
1. **Trial Balance**: All accounts with debit/credit balances as of a specific date / ٹرائل بیلنس
2. **Profit & Loss**: Income vs Expenses for a date range with net profit/loss / منافع اور نقصان
3. **Balance Sheet**: Assets vs Liabilities + Equity as of a specific date / بیلنس شیٹ

**Effects**: These reports pull data directly from the general_ledger table. Accuracy depends on proper journal entries.

---

### 32. Fixed Assets (Main Menu Option 32)

**English**: Register and depreciate fixed assets using straight-line method.

**اردو**: فکسڈ ایسیٹس رجسٹر اور ڈپریسی ایشن - سیدھی لائن طریقہ۔

**Features**:
- Add fixed assets with code, name, category, purchase date, purchase price / فکسڈ ایسیٹ شامل کریں
- Set salvage value and useful life (years) / بچاؤ قیمت اور مفید زندگی
- Location and notes tracking / مقام اور نوٹس
- Calculate depreciation (straight-line method) / ڈپریسی ایشن کا حساب
- Depreciation schedule per asset / ڈپریسی ایشن شیڈول
- Automatic current value update / خودکار موجودہ قیمت اپڈیٹ

**Depreciation Formula**: Annual Depreciation = (Current Value - Salvage Value) / Useful Life

**Effects**: Depreciation reduces asset current_value and creates entries in depreciation_entries table.

---

### 33. Budgets (Main Menu Option 33)

**English**: Set budget targets by account and track actual vs budgeted spending.

**اردو**: اکاؤنٹ وار بجٹ ہدف اور اصل بمقابلہ بجٹ ٹریکنگ۔

**Features**:
- Create budget with name, fiscal year, date range, total amount / بجٹ بنائیں
- Add budget items per account (from Income/Expense accounts) / بجٹ آئٹمز
- View budget vs actual with variance and percentage / بجٹ بمقابلہ اصل
- Automatic actual amount calculation from general ledger / خودکار اصل رقم

**Effects**: Budget items' actual_amount is auto-calculated from general_ledger entries within the budget date range.

---

### 34. Cash Register (Main Menu Option 34)

**English**: Manage daily cash registers with opening/closing and transaction tracking.

**اردو**: روزانہ کیش رجسٹر - اوپننگ/کلوزنگ اور ٹرانزیکشن ٹریکنگ۔

**Features**:
- Open cash register with opening balance / کیش رجسٹر کھولیں
- Add transactions (IN/OUT) / ٹرانزیکشنز شامل کریں
- Close register with actual cash count / رجسٹر بند کریں
- Track variance (expected vs actual cash) / فرق ٹریکنگ
- Transaction history per register / ٹرانزیکشن تاریخ

**Effects**: Register transactions are independent from bank accounts but track cash flow at the point-of-sale level.

---

### 35. Email Configuration (Main Menu Option 35)

**English**: Configure SMTP email settings for future email integration (placeholder).

**اردو**: SMTP ای میل سیٹنگز - مستقبل کے ای میل انٹیگریشن کے لیے۔

**Features**:
- Set SMTP server, port, user, password / SMTP سرور
- Set sender email and name / بھیجنے والا ای میل
- Toggle active/inactive / فعال/غیر فعال
- Test connection (placeholder) / ٹیسٹ کنکشن

---

### 36. Help & Support (Main Menu Option 36)

**English**: Built-in help system with searchable topics and keywords.

**اردو**: بلٹ ان ہیلپ سسٹم - تلاش کے ساتھ۔

**Features**:
- Browse all help topics / تمام ہیلپ ٹاپکس دیکھیں
- Search by keyword / کلیدی لفظ سے تلاش
- Add/Edit help topics (Admin only) / ہیلپ ٹاپک شامل/تبدیل

**Pre-loaded Topics**: Getting Started, Sales/POS, Purchases, Products & Inventory, Customers & Khata, Suppliers & Khata, Reports, Backup & Restore, Multi-Warehouse, Quotations, Sales Orders, Purchase Orders, Delivery Challan, Full Accounting, Service & Repair, Manufacturing/BOM, Loyalty Program, Promotions & Coupons, Price Lists, Employee Management, Fixed Assets, Budgets, Keyboard Shortcuts.

---

### 37. Utility Functions (Main Menu Option 37)

**English**: Quick utility tools for common tasks.

**اردو**: عام کاموں کے لیے فوری یوٹیلٹی ٹولز۔

**Features**:
1. **Low Stock Report**: Products below warning level / کم اسٹاک رپورٹ
2. **Expired Products**: Products past expiry date / ایکسپائرڈ پروڈکٹس
3. **DB Statistics**: Record counts for all tables / ڈیٹابیس شماریات
4. **Bulk Price Update**: Increase prices by % or set fixed amount across products / بلک قیمت اپڈیٹ
5. **Rebuild Stock from Transactions**: Recalculate all stock levels from sales/purchases/returns transactions / ٹرانزیکشنز سے اسٹک دوبارہ بنائیں

**Effects**: Bulk price update modifies product sale_price and logs price history. Rebuild stock recalculates current_stock from all transaction tables.

---

### 38. Logout (Main Menu Option 38)

Logs out current user and returns to login screen. Audit log records the logout.

---

### Global Quick Search (Main Menu Option S)

**English**: Quick search across products, parties, and invoices.

**اردو**: پروڈکٹس، پارٹیز، اور انوائسز میں فوری تلاش۔

**Searches**:
- Products by SKU or Name / پروڈکٹس
- Customers/Suppliers by Name or Phone / کسٹمرز/سپلائرز
- Invoices by Invoice Number / انوائسز

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `0` | Go back / Exit current menu |
| `S` | Global quick search (main menu only) |
| `Enter` | Continue / Submit prompt |

---

## Database Structure Summary

The application uses 50+ SQLite tables including:
- Products, Categories, Brands, Units
- Customers, Suppliers
- Sales, Sale Items, Purchase, Purchase Items
- Sale Returns, Purchase Returns
- Stock Movements, Stock Adjustments
- Customer Ledger, Supplier Ledger
- Cash/Bank Accounts, Cash/Bank Transactions
- Expenses, Expense Categories
- Warehouses, Warehouse Stock
- Quotations, Sales Orders, Purchase Orders
- Delivery Challans
- Credit Notes, Debit Notes
- Employees, Commissions
- Loyalty Points, Loyalty Transactions
- Price Lists, Promotions
- Serial Numbers
- Service Jobs, Service Parts
- BOM, BOM Items, Manufacturing Jobs
- Chart of Accounts, General Ledger
- Fixed Assets, Depreciation Entries
- Budgets, Budget Items
- Cash Registers, Register Transactions
- Users, Audit Logs
- Settings, Password Policy, Login Attempts
- Email Config, Help Topics

---

## Important System Behaviors

### Stock Management
- **Sale**: Stock decreases automatically
- **Purchase**: Stock increases automatically
- **Sale Return**: Stock increases
- **Purchase Return**: Stock decreases
- **Manufacturing**: Raw materials decrease, finished product increases
- **Service Parts**: Stock decreases when parts added
- **Stock Adjustment**: Manual increase/decrease with reason

### Ledger/Khata Behavior
- **Customer Sale (credit)**: Debit increases customer balance
- **Customer Payment**: Credit decreases customer balance
- **Supplier Purchase (credit)**: Credit increases supplier balance
- **Supplier Payment**: Debit decreases supplier balance

### Cash/Bank Behavior
- **Sale Payment Received**: Account balance increases (IN)
- **Purchase Payment Made**: Account balance decreases (OUT)
- **Expense Paid**: Account balance decreases (OUT)
- **Customer Payment Received**: Account balance increases (IN)
- **Supplier Payment Made**: Account balance decreases (OUT)
- **Fund Transfer**: Source decreases, destination increases

### Invoice Numbering
- Sales: `{inv_prefix}{YYMMDD}-{SEQ}` (e.g., INV-260623-0001)
- Purchases: `{pur_prefix}{YYMMDD}-{SEQ}` (e.g., PUR-260623-0001)
- Returns: `{ret_prefix}{YYMMDD}-{SEQ}` (e.g., RET-260623-0001)

---

---

# اردو دستاویزات - مکمل تفصیل

---

### جائزہ

شاپ مینیجر CMD ایک مکمل ٹرمینل بیسڈ ریٹیل اور ہول سیل کاروباری مینجمنٹ سسٹم ہے جو Python اور SQLite ڈیٹابیس پر بنایا گیا ہے۔ یہ فروخت، خریداری، انوینٹری، اکاؤنٹنگ، کسٹمرز، سپلائرز، ایمپلائیز اور بہت کچھ کا انتظام کرتا ہے - سب کچھ کمانڈ لائن انٹرفیس سے۔

### ٹیکنالوجی

- **زبان**: Python 3
- **ڈیٹابیس**: SQLite (ایک فائل: shop_manager.db)
- **انٹرفیس**: ٹرمینل/کنسول (CLI)
- **OS**: Windows/Linux/Mac مطابقت پذیر

### ڈیفالٹ لاگن

| **یوزر نیم** | **پاس ورڈ** | **رول** |
|--------------|-------------|---------|
| `admin` | `admin123` | ایڈمن |
| `manager` | `manager123` | مینیجر |
| `cashier` | `cashier123` | کیشئر |
| `viewer` | `viewer123` | ویوور |

**ضروری**: پہلی لاگن کے فوراً بعد ڈیفالٹ پاس ورڈ تبدیل کریں۔

---

## تمام فیچر ماڈیولز کی تفصیل

### 1. ڈیش بورڈ اور آج کا خلاصہ

آج کے کاروبار کا مکمل جائزہ:
- آج کی کل فروخت
- آج کی کل خریداری
- نقد آمدنی اور نقد اخراج
- آج کے اخراجات
- تخمینہ خالص منافع
- کم اسٹاک اشیاء
- دستیاب نقد/بینک بیلنس
- کسٹمرز کے بقایا جات
- سپلائرز کے بقایا جات

### 2. فروخت / POS ٹرمینل

- سیل انوائس بنائیں متعدد پروڈکٹس کے ساتھ
- واک ان اور رجسٹرڈ دونوں کسٹمرز
- SKU، بارکوڈ، یا نام سے پروڈکٹ تلاش
- فی آئٹم ڈسکاؤنٹ اور ٹیکس
- جزوی یا مکمل ادائیگی
- صرف رجسٹرڈ کسٹمرز کے لیے ادھار
- فروخت پر خودکار اسٹاک کٹوتی
- خودکار کسٹمر کھاتا اپڈیٹ
- رسید پرنٹ/سیو کریں

### 3. پروڈکٹس اور انوینٹری

**زمرے**: شامل/تبدیل/حذف
**برانڈز**: شامل/تبدیل/حذف
**اکائیاں**: شامل/تبدیل/حذف

**پروڈکٹ شامل کریں**:
- کوڈ/SKU، بارکوڈ، نام
- زمرہ، برانڈ، اکائی
- خریداری قیمت، فروخت قیمت، ہول سیل قیمت، ریٹیل MSRP
- کم از کم اسٹاک وارننگ لیول
- اوپننگ اسٹاک
- ٹیکس فیصد
- ڈسکاؤنٹ کی اجازت
- ایکسپائری تاریخ، بیچ نمبر، ریک لوکیشن

**پروڈکٹ ترمیم**: تمام فیلڈز اپڈیٹ - قیمت کی تاریخ خودکار محفوظ
**اسٹاک ایڈجسٹمنٹ**: دستی اضافہ/کٹوتی وجہ کے ساتھ
**قیمت کی تاریخ**: ہر قیمت تبدیلی کا ریکارڈ
**اسٹاک تحریک**: تمام اسٹاک تبدیلیوں کا ریکارڈ

### 4. کسٹمرز اور کھاتا

- نیا کسٹمر شامل کریں (خودکار کوڈ: CUST-0001)
- نام، فون، ایڈریس، ای میل
- اوپننگ بیلنس
- کریڈٹ لمٹ
- مکمل کھاتا بیان (ڈیبٹ/کریڈٹ)
- ادائیگی وصول کریں
- غیر فعال/فعال کریں

**کھاتا اثرات**:
- سیل (ادھار): کسٹمر بیلنس بڑھتا ہے
- ادائیگی: کسٹمر بیلنس کم ہوتا ہے
- نقد/بینک اکاؤنٹ بڑھتا ہے

### 5. رپورٹس (25+)

**فروخت**: آج، تاریخ وار، پروڈکٹ وار، کسٹمر وار
**خریداری**: آج، تاریخ وار، سپلائر وار
**مالیاتی**: منافع/نقصان، خام منافع، اخراجات، نقد بک، بینک بک
**کھاتا**: کسٹمر بقایا، سپلائر بقایا
**انوینٹری**: اسٹاک ویلیوایشن، کم اسٹاک، خالی اسٹاک، مردہ اسٹاک
**واپسی**: فروخت واپسی، خریداری واپسی
**ٹیکس**: ٹیکس خلاصہ، ڈسکاؤنٹس
**سسٹم**: آڈٹ لاگز، صارف سرگرمی، روزانہ کلوزنگ

### 6. خریداری مینجمنٹ

- خریداری انوائس بیچ/ایکسپائری ٹریکنگ کے ساتھ
- سپلائر سے خریداری
- خودکار اسٹاک اضافہ
- خودکار خریداری قیمت اپڈیٹ
- فریٹ/اضافی چارجز
- سپلائر کو ادائیگی

### 7. سپلائرز اور کھاتا

- نیا سپلائر (خودکار کوڈ: SUPP-0001)
- خریداری پر سپلائر بیلنس بڑھتا ہے
- ادائیگی پر سپلائر بیلنس کم ہوتا ہے
- مکمل سپلائر کھاتا

### 8. نقد اور بینک اکاؤنٹس

- ڈیفالٹ: "Cash in Hand" اور "Main Bank Account"
- ڈپازٹ (+) / وڈڈرا (-)
- اکاؤنٹس کے درمیان فنڈ ٹرانسفر
- تمام ٹرانزیکشنز کی کتاب

### 9. اخراجات

- اخراجات شامل کریں (زمرہ، رقم، وضاحت، تاریخ)
- اخراجات کی اقسام مینج کریں
- ڈیفالٹ: Rent, Electricity, Salary, Maintenance, Miscellaneous
- اخراجات منافع/نقصان رپورٹ میں شامل

### 10. واپسی پروسیسنگ

**فروخت واپسی**:
- اسٹاک بڑھتا ہے
- کسٹمر بیلنس کم ہوتا ہے
- نقد واپسی اگر فوراً ری فنڈ

**خریداری واپسی**:
- اسٹاک کم ہوتا ہے
- سپلائر بیلنس کم ہوتا ہے
- نقد واپسی اگر ری فنڈ موصول

### 11. شاپ سیٹنگز (صرف ایڈمن)

کاروبار کا نام، ایڈریس، فون، ای میل، کرنسی، ٹیکس ریٹ، انوائس پریفکس، کم اسٹاک وارننگ، بیک اپ پاتھ، رسید فوٹر میسج۔

### 12. صارفین اور سیکیورٹی (صرف ایڈمن)

- نیا صارف شامل کریں
- رولز: ایڈمن، مینیجر، کیشئر، ویوور
- پاس ورڈ تبدیلی
- آڈٹ لاگ دیکھیں
- SHA-256 ہیشنگ، یونیک سالٹ

### 13. بیک اپ اور بحالی (صرف ایڈمن)

- دستی بیک اپ (ٹائم اسٹیمپڈ .db فائل)
- بیک اپ سے بحالی
- ایپ بند ہونے پر خودکار بیک اپ

### 14. CSV امپورٹ/ایکسپورٹ

- پروڈکٹس، کسٹمرز، سپلائرز ایکسپورٹ
- پروڈکٹس، کسٹمرز، سپلائرز امپورٹ
- INSERT OR IGNORE - موجودہ ریکارڈز.skip

### 15. کوٹیشنز

- قیمت کوٹیشن بنائیں
- منظور ہونے پر سیل میں تبدیل
- اسٹیٹس: DRAFT، ACTIVE، CONVERTED، CANCELLED

### 16. سیل آرڈرز

- مستقبل ڈیلیوری کے لیے آرڈر بک کریں
- ایڈوانس ادائیگی
- ڈیلیورڈ بمقابلہ آرڈرڈ ٹریکنگ

### 17. خریداری آرڈرز

- سپلائر کو PO بنائیں
- متوقع ڈیلیوری تاریخ
- موصول بمقابلہ آرڈرڈ ٹریکنگ

### 18. ڈیلیوری چالان

- ڈیلیوری چالان بنائیں
- سیل آرڈر سے خودکار چالان
- گاڑی نمبر، ڈرائیور، فون ٹریکنگ

### 19. گودام/ویئر ہاؤس

- متعدد گودام مینجمنٹ
- فی گودام اسٹاک
- گوداموں کے درمیان اسٹاک ٹرانسفر

### 20. کریڈٹ/ڈیبٹ نوٹس

- کسٹمر کو کریڈٹ نوٹ
- سپلائر کو ڈیبٹ نوٹ
- بیلنس ایڈجسٹمنٹ

### 21. ایمپلائیز

- کوڈ، نام، فون، ای میل
- محکمہ، عہدہ
- تنخواہ: FIXED یا COMMISSION
- شمولیت تاریخ

### 22. کمیشن

- فروخت سے کمیشن نکالیں
- تاریخ کی حد مقرر کریں
- ادائیگی مارک کریں

### 23. لائلٹی پوائنٹس

- کسٹمر کو پوائنٹس دیں
- پوائنٹس کو نقد میں تبدیل کریں
- مکمل ٹرانزیکشن تاریخ

### 24. پرائس لسٹس

- کسٹم پرائس لسٹ بنائیں
- فی پروڈکٹ قیمتیں مقرر کریں
- ایک بار میں تمام قیمتیں اپڈیٹ

### 25. پروموشنز اور کوپنز

- فیصد یا فکسڈ ڈسکاؤنٹ
- کوپن کوڈ
- کم از کم خریداری شرط
- زیادہ سے زیادہ ڈسکاؤنٹ حد
- شروعات/اختتام تاریخ

### 26. سیریل نمبرز

- پروڈکٹ سیریل نمبر رجسٹر
- اسٹیٹس: IN_STOCK، SOLD، RETURNED، SCRAPPED
- تلاش بذریعہ سیریل نمبر

### 27. سروس/مرمت جابز

- سروس جاب بنائیں
- استعمال شدہ پارٹس (اسٹاک کٹوتی)
- سروس چارجز
- اسٹیٹس ٹریکنگ

### 28. بل آف میٹریلز (BOM)

- تیار پروڈکٹ کا فارمولا
- خام مال کی فہرست
- آؤٹ پٹ مقدار، ضائع فیصد
- لاگت کا حساب

### 29. مینوفیکچرنگ جابز

- BOM سے پیداوار
- خام مال کٹوتی خودکار
- تیار پروڈکٹ اضافہ خودکار

### 30. اکاؤنٹنگ

- چارٹ آف اکاؤنٹس
- جنرل لیجر
- ڈبل انٹری جریدہ اندراجات
- اکاؤنٹ بیان

### 31. مالیاتی بیانات

- ٹرائل بیلنس
- منافع اور نقصان
- بیلنس شیٹ

### 32. فکسڈ ایسیٹس

- ایسیٹ رجسٹر کریں
- سیدھی لائن ڈپریسی ایشن
- موجودہ قیمت خودکار اپڈیٹ

### 33. بجٹس

- بجٹ ہدف مقرر کریں
- اصل بمقابلہ بجٹ
- فرق اور فیصد

### 34. کیش رجسٹر

- روزانہ کیش رجسٹر
- اوپننگ/کلوزنگ
- فرق ٹریکنگ

### 35. ای میل کنفیگریشن

- SMTP سیٹنگز
- مستقبل کے ای میل انٹیگریشن کے لیے

### 36. ہیلپ اور سپورٹ

- تلاش کے ساتھ ہیلپ ٹاپکس
- 23+ پہلے سے لوڈ شدہ ٹاپکس

### 37. یوٹیلٹی فنکشنز

- کم اسٹاک رپورٹ
- ایکسپائرڈ پروڈکٹس
- ڈیٹابیس شماریات
- بلک قیمت اپڈیٹ
- ٹرانزیکشنز سے اسٹاک دوبارہ بنائیں

---

## اہم سسٹم رویے

### اسٹاک مینجمنٹ
- فروخت: اسٹاک کم ہوتا ہے
- خریداری: اسٹاک بڑھتا ہے
- فروخت واپسی: اسٹاک بڑھتا ہے
- خریداری واپسی: اسٹاک کم ہوتا ہے
- مینوفیکچرنگ: خام مال کم، تیار پروڈکٹ بڑھتا ہے
- سروس پارٹس: اسٹاک کم ہوتا ہے

### کھاتا رویہ
- کسٹمر سیل (ادھار): ڈیبٹ - بیلنس بڑھتا ہے
- کسٹمر ادائیگی: کریڈٹ - بیلنس کم ہوتا ہے
- سپلائر خریداری: کریڈٹ - بیلنس بڑھتا ہے
- سپلائر ادائیگی: ڈیبٹ - بیلنس کم ہوتا ہے

### نقد/بینک رویہ
- فروخت ادائیگی موصول: بیلنس بڑھتا ہے
- خریداری ادائیگی: بیلنس کم ہوتا ہے
- اخراجات: بیلنس کم ہوتا ہے

---

## License & Support

This project is **open source** under the MIT License.

- **GitHub Repository**: [https://github.com/yasinULLAH/ShopManageCMD](https://github.com/yasinULLAH/ShopManageCMD)
- **Issues & Feature Requests**: Please open an issue on GitHub
- **Pull Requests**: Contributions are welcome!

---

*Shop Manager - Your Complete Business Management Solution*
