-- PostgreSQL Accounting System Schema
-- Comprehensive database schema for accounting application
-- Created: 2026-01-13

-- =====================================================
-- USERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'user', -- admin, accountant, viewer
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- =====================================================
-- BANK ACCOUNTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS bank_accounts (
    id SERIAL PRIMARY KEY,
    account_name VARCHAR(255) NOT NULL,
    account_number VARCHAR(50) UNIQUE NOT NULL,
    bank_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- Checking, Savings, Money Market
    currency_code VARCHAR(3) DEFAULT 'USD',
    opening_balance NUMERIC(15, 2) DEFAULT 0.00,
    current_balance NUMERIC(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_account_number ON bank_accounts(account_number);

-- =====================================================
-- CHART OF ACCOUNTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    id SERIAL PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(50) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    sub_type VARCHAR(100), -- Current Asset, Fixed Asset, etc.
    description TEXT,
    normal_balance VARCHAR(10) NOT NULL, -- Debit or Credit
    opening_balance NUMERIC(15, 2) DEFAULT 0.00,
    current_balance NUMERIC(15, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    is_system_account BOOLEAN DEFAULT false,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chart_of_accounts_code ON chart_of_accounts(account_code);
CREATE INDEX idx_chart_of_accounts_type ON chart_of_accounts(account_type);

-- =====================================================
-- CUSTOMERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255),
    contact_title VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    fax VARCHAR(20),
    billing_address VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(100),
    shipping_address VARCHAR(255),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(100),
    shipping_postal_code VARCHAR(20),
    shipping_country VARCHAR(100),
    credit_limit NUMERIC(15, 2),
    accounts_receivable_account INT REFERENCES chart_of_accounts(id),
    sales_account INT REFERENCES chart_of_accounts(id),
    tax_id VARCHAR(50),
    payment_terms VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_code ON customers(customer_code);
CREATE INDEX idx_customers_company_name ON customers(company_name);

-- =====================================================
-- VENDORS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vendors (
    id SERIAL PRIMARY KEY,
    vendor_code VARCHAR(50) UNIQUE NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255),
    contact_title VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    fax VARCHAR(20),
    billing_address VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_postal_code VARCHAR(20),
    billing_country VARCHAR(100),
    tax_id VARCHAR(50),
    payment_terms VARCHAR(100),
    accounts_payable_account INT REFERENCES chart_of_accounts(id),
    is_active BOOLEAN DEFAULT true,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_vendors_code ON vendors(vendor_code);
CREATE INDEX idx_vendors_name ON vendors(vendor_name);

-- =====================================================
-- PRODUCTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    unit_of_measure VARCHAR(50), -- Unit, Box, Dozen, etc.
    unit_price NUMERIC(15, 2) NOT NULL,
    cost_price NUMERIC(15, 2),
    is_taxable BOOLEAN DEFAULT true,
    inventory_account INT REFERENCES chart_of_accounts(id),
    cost_of_goods_sold_account INT REFERENCES chart_of_accounts(id),
    revenue_account INT REFERENCES chart_of_accounts(id),
    is_active BOOLEAN DEFAULT true,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_code ON products(product_code);
CREATE INDEX idx_products_name ON products(product_name);

-- =====================================================
-- INVENTORY TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS inventory (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id),
    warehouse_location VARCHAR(100),
    quantity_on_hand NUMERIC(15, 4) DEFAULT 0,
    reorder_level NUMERIC(15, 4),
    reorder_quantity NUMERIC(15, 4),
    last_count_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id)
);

CREATE INDEX idx_inventory_product_id ON inventory(product_id);

-- =====================================================
-- INVENTORY MOVEMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS inventory_movements (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id),
    movement_type VARCHAR(50) NOT NULL, -- Purchase, Sales, Adjustment, Return
    quantity NUMERIC(15, 4) NOT NULL,
    reference_type VARCHAR(50), -- Invoice, PurchaseOrder, Journal Entry
    reference_id INT,
    notes TEXT,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_movements_product_id ON inventory_movements(product_id);
CREATE INDEX idx_inventory_movements_created_at ON inventory_movements(created_at);

-- =====================================================
-- INVOICES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS invoices (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INT NOT NULL REFERENCES customers(id),
    invoice_date DATE NOT NULL,
    due_date DATE,
    po_number VARCHAR(50),
    description TEXT,
    subtotal NUMERIC(15, 2) DEFAULT 0.00,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    total_amount NUMERIC(15, 2) DEFAULT 0.00,
    amount_paid NUMERIC(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'Draft', -- Draft, Open, Partially Paid, Paid, Overdue, Cancelled
    notes TEXT,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoices_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- =====================================================
-- INVOICE DETAILS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS invoice_details (
    id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id),
    description VARCHAR(255) NOT NULL,
    quantity NUMERIC(15, 4) NOT NULL,
    unit_price NUMERIC(15, 2) NOT NULL,
    line_total NUMERIC(15, 2) NOT NULL,
    tax_rate NUMERIC(5, 2) DEFAULT 0.00,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_invoice_details_invoice_id ON invoice_details(invoice_id);
CREATE INDEX idx_invoice_details_product_id ON invoice_details(product_id);

-- =====================================================
-- PAYMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    payment_number VARCHAR(50) UNIQUE NOT NULL,
    payment_type VARCHAR(50) NOT NULL, -- Customer Payment, Vendor Payment
    related_entity_id INT, -- customer_id or vendor_id
    payment_date DATE NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- Check, Cash, Credit Card, Bank Transfer, ACH
    reference_number VARCHAR(100),
    bank_account_id INT REFERENCES bank_accounts(id),
    description TEXT,
    status VARCHAR(50) DEFAULT 'Pending', -- Pending, Cleared, Reconciled, Voided
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_number ON payments(payment_number);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_bank_account_id ON payments(bank_account_id);

-- =====================================================
-- PAYMENT ALLOCATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_allocations (
    id SERIAL PRIMARY KEY,
    payment_id INT NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    invoice_id INT REFERENCES invoices(id),
    allocated_amount NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_allocations_payment_id ON payment_allocations(payment_id);
CREATE INDEX idx_payment_allocations_invoice_id ON payment_allocations(invoice_id);

-- =====================================================
-- JOURNAL ENTRIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS journal_entries (
    id SERIAL PRIMARY KEY,
    entry_number VARCHAR(50) UNIQUE NOT NULL,
    entry_date DATE NOT NULL,
    description TEXT NOT NULL,
    reference_type VARCHAR(50), -- Invoice, Payment, Manual, etc.
    reference_id INT,
    memo TEXT,
    is_posted BOOLEAN DEFAULT false,
    posted_date TIMESTAMP,
    created_by INT REFERENCES users(id),
    posted_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_journal_entries_number ON journal_entries(entry_number);
CREATE INDEX idx_journal_entries_date ON journal_entries(entry_date);
CREATE INDEX idx_journal_entries_is_posted ON journal_entries(is_posted);

-- =====================================================
-- JOURNAL ENTRY DETAILS TABLE (Line Items)
-- =====================================================
CREATE TABLE IF NOT EXISTS journal_entry_details (
    id SERIAL PRIMARY KEY,
    journal_entry_id INT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id INT NOT NULL REFERENCES chart_of_accounts(id),
    debit_amount NUMERIC(15, 2) DEFAULT 0.00,
    credit_amount NUMERIC(15, 2) DEFAULT 0.00,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_journal_entry_details_entry_id ON journal_entry_details(journal_entry_id);
CREATE INDEX idx_journal_entry_details_account_id ON journal_entry_details(account_id);

-- =====================================================
-- ACCOUNT RECONCILIATION TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS account_reconciliations (
    id SERIAL PRIMARY KEY,
    bank_account_id INT NOT NULL REFERENCES bank_accounts(id),
    reconciliation_date DATE NOT NULL,
    statement_balance NUMERIC(15, 2) NOT NULL,
    book_balance NUMERIC(15, 2) NOT NULL,
    difference NUMERIC(15, 2),
    status VARCHAR(50) DEFAULT 'Pending', -- Pending, Reconciled, Requires Review
    notes TEXT,
    reconciled_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reconciliations_bank_account ON account_reconciliations(bank_account_id);
CREATE INDEX idx_reconciliations_date ON account_reconciliations(reconciliation_date);

-- =====================================================
-- BANK RECONCILIATION DETAILS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS bank_reconciliation_details (
    id SERIAL PRIMARY KEY,
    reconciliation_id INT NOT NULL REFERENCES account_reconciliations(id) ON DELETE CASCADE,
    payment_id INT REFERENCES payments(id),
    cleared BOOLEAN DEFAULT false,
    cleared_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_recon_details_reconciliation ON bank_reconciliation_details(reconciliation_id);

-- =====================================================
-- AUDIT LOG TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    user_id INT REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_changed_at ON audit_logs(changed_at);

-- =====================================================
-- TAX CODES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_codes (
    id SERIAL PRIMARY KEY,
    tax_code VARCHAR(50) UNIQUE NOT NULL,
    tax_name VARCHAR(255) NOT NULL,
    tax_rate NUMERIC(5, 2) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tax_codes_code ON tax_codes(tax_code);

-- =====================================================
-- GENERAL LEDGER (MATERIALIZED VIEW FOR PERFORMANCE)
-- =====================================================
CREATE TABLE IF NOT EXISTS general_ledger (
    id SERIAL PRIMARY KEY,
    account_id INT NOT NULL REFERENCES chart_of_accounts(id),
    journal_entry_detail_id INT REFERENCES journal_entry_details(id),
    entry_date DATE NOT NULL,
    debit_amount NUMERIC(15, 2) DEFAULT 0.00,
    credit_amount NUMERIC(15, 2) DEFAULT 0.00,
    running_balance NUMERIC(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_general_ledger_account_id ON general_ledger(account_id);
CREATE INDEX idx_general_ledger_entry_date ON general_ledger(entry_date);

-- =====================================================
-- FINANCIAL PERIODS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS financial_periods (
    id SERIAL PRIMARY KEY,
    period_name VARCHAR(100) NOT NULL,
    period_type VARCHAR(50) NOT NULL, -- Monthly, Quarterly, Annually
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BOOLEAN DEFAULT false,
    closed_date TIMESTAMP,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_financial_periods_dates ON financial_periods(start_date, end_date);

-- =====================================================
-- EXPENSE TABLE (For tracking expenses)
-- =====================================================
CREATE TABLE IF NOT EXISTS expenses (
    id SERIAL PRIMARY KEY,
    expense_number VARCHAR(50) UNIQUE NOT NULL,
    vendor_id INT REFERENCES vendors(id),
    account_id INT NOT NULL REFERENCES chart_of_accounts(id),
    expense_date DATE NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    tax_amount NUMERIC(15, 2) DEFAULT 0.00,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'Draft', -- Draft, Submitted, Approved, Paid
    notes TEXT,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_expenses_number ON expenses(expense_number);
CREATE INDEX idx_expenses_vendor_id ON expenses(vendor_id);
CREATE INDEX idx_expenses_date ON expenses(expense_date);
CREATE INDEX idx_expenses_status ON expenses(status);

-- =====================================================
-- SYSTEM SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description TEXT,
    updated_by INT REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_settings_key ON system_settings(setting_key);

-- =====================================================
-- INSERT SAMPLE DATA
-- =====================================================

-- Insert sample user (password would be hashed in practice)
INSERT INTO users (username, email, password_hash, first_name, last_name, role) 
VALUES ('admin', 'admin@accounting.local', 'hashed_password_here', 'Admin', 'User', 'admin')
ON CONFLICT DO NOTHING;

-- Insert basic chart of accounts structure
INSERT INTO chart_of_accounts (account_code, account_name, account_type, sub_type, normal_balance, is_system_account) VALUES
('1000', 'Cash and Cash Equivalents', 'Asset', 'Current Asset', 'Debit', true),
('1100', 'Accounts Receivable', 'Asset', 'Current Asset', 'Debit', true),
('1200', 'Inventory', 'Asset', 'Current Asset', 'Debit', true),
('1500', 'Fixed Assets', 'Asset', 'Fixed Asset', 'Debit', true),
('2000', 'Accounts Payable', 'Liability', 'Current Liability', 'Credit', true),
('2100', 'Short-term Debt', 'Liability', 'Current Liability', 'Credit', true),
('3000', 'Retained Earnings', 'Equity', 'Equity', 'Credit', true),
('4000', 'Sales Revenue', 'Revenue', 'Operating Revenue', 'Credit', true),
('5000', 'Cost of Goods Sold', 'Expense', 'Cost of Sales', 'Debit', true),
('6000', 'Salaries and Wages', 'Expense', 'Operating Expense', 'Debit', true),
('6100', 'Utilities', 'Expense', 'Operating Expense', 'Debit', true),
('6200', 'Rent Expense', 'Expense', 'Operating Expense', 'Debit', true),
('6300', 'Depreciation Expense', 'Expense', 'Operating Expense', 'Debit', true)
ON CONFLICT (account_code) DO NOTHING;

-- Insert sample tax code
INSERT INTO tax_codes (tax_code, tax_name, tax_rate) 
VALUES ('STANDARD', 'Standard Sales Tax', 8.00)
ON CONFLICT DO NOTHING;

-- =====================================================
-- CREATE STORED FUNCTIONS
-- =====================================================

-- Function to update account balance when journal entry is posted
CREATE OR REPLACE FUNCTION update_account_balance_on_posting()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_posted AND NOT OLD.is_posted THEN
        UPDATE chart_of_accounts
        SET current_balance = current_balance + COALESCE((
            SELECT SUM(CASE 
                WHEN normal_balance = 'Debit' THEN debit_amount - credit_amount
                ELSE credit_amount - debit_amount
            END)
            FROM journal_entry_details
            WHERE journal_entry_id = NEW.id
        ), 0)
        WHERE id IN (SELECT account_id FROM journal_entry_details WHERE journal_entry_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_account_balance
AFTER UPDATE ON journal_entries
FOR EACH ROW
EXECUTE FUNCTION update_account_balance_on_posting();

-- Function to maintain inventory on invoice detail insert
CREATE OR REPLACE FUNCTION update_inventory_on_sale()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - NEW.quantity
    WHERE product_id = NEW.product_id;
    
    INSERT INTO inventory_movements (product_id, movement_type, quantity, reference_type, reference_id)
    VALUES (NEW.product_id, 'Sales', -NEW.quantity, 'Invoice', NEW.invoice_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_inventory_on_sale
AFTER INSERT ON invoice_details
FOR EACH ROW
EXECUTE FUNCTION update_inventory_on_sale();

-- Function to update invoice total
CREATE OR REPLACE FUNCTION update_invoice_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE invoices
    SET subtotal = COALESCE((SELECT SUM(line_total) FROM invoice_details WHERE invoice_id = NEW.invoice_id), 0),
        tax_amount = COALESCE((SELECT SUM(tax_amount) FROM invoice_details WHERE invoice_id = NEW.invoice_id), 0),
        total_amount = COALESCE((SELECT SUM(line_total + tax_amount) FROM invoice_details WHERE invoice_id = NEW.invoice_id), 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.invoice_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_invoice_total
AFTER INSERT OR UPDATE ON invoice_details
FOR EACH ROW
EXECUTE FUNCTION update_invoice_total();

-- =====================================================
-- PERMISSIONS AND COMMENTS
-- =====================================================

COMMENT ON TABLE users IS 'System users with roles for access control';
COMMENT ON TABLE chart_of_accounts IS 'General ledger chart of accounts';
COMMENT ON TABLE invoices IS 'Customer invoices';
COMMENT ON TABLE payments IS 'Payment transactions';
COMMENT ON TABLE journal_entries IS 'General journal entries';
COMMENT ON TABLE inventory IS 'Inventory stock levels';
COMMENT ON TABLE customers IS 'Customer master data';
COMMENT ON TABLE vendors IS 'Vendor master data';
COMMENT ON TABLE products IS 'Product master data';
COMMENT ON TABLE bank_accounts IS 'Bank account master data';

-- =====================================================
-- END OF SCHEMA
-- =====================================================
