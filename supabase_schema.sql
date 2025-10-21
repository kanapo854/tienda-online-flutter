-- 🗃️ SCRIPT SQL PARA CREAR TABLAS EN SUPABASE (PostgreSQL)
-- Ejecuta este script en el SQL Editor de Supabase

-- ============================================
-- 1. TABLAS PRINCIPALES (DATOS MAESTROS)
-- ============================================

-- Empresas
CREATE TABLE companies (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  ruc VARCHAR(20) UNIQUE NOT NULL,
  address TEXT,
  phone VARCHAR(20),
  email VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Tiendas
CREATE TABLE stores (
  id SERIAL PRIMARY KEY,
  company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  address TEXT,
  city VARCHAR(100),
  phone VARCHAR(20),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Almacenes
CREATE TABLE warehouses (
  id SERIAL PRIMARY KEY,
  company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
  store_id INTEGER REFERENCES stores(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  address TEXT,
  warehouse_type VARCHAR(20) CHECK (warehouse_type IN ('central', 'store', 'external')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Empleados
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE,
  store_id INTEGER REFERENCES stores(id) ON DELETE SET NULL,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE SET NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20),
  document_type VARCHAR(20) CHECK (document_type IN ('dni', 'passport', 'ce')),
  document_number VARCHAR(50) UNIQUE NOT NULL,
  role VARCHAR(30) CHECK (role IN ('admin', 'store_manager', 'warehouse_manager', 'cashier', 'employee')),
  password_hash VARCHAR(255) NOT NULL,
  salt VARCHAR(255) NOT NULL,
  last_login TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Categorías de productos
CREATE TABLE product_categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  parent_id INTEGER REFERENCES product_categories(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Productos
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  category_id INTEGER REFERENCES product_categories(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  sku VARCHAR(100) UNIQUE NOT NULL,
  barcode VARCHAR(100),
  description TEXT,
  brand VARCHAR(100),
  model VARCHAR(100),
  purchase_price DECIMAL(10, 2),
  sale_price DECIMAL(10, 2),
  unit VARCHAR(20) CHECK (unit IN ('metro2', 'metro', 'unidad', 'caja', 'rollo', 'kg', 'litro')),
  min_stock DECIMAL(10, 2),
  max_stock DECIMAL(10, 2),
  image_urls TEXT, -- JSON array
  specifications TEXT, -- JSON object
  supplier VARCHAR(255),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Stock por almacén
CREATE TABLE stocks (
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE CASCADE,
  quantity DECIMAL(10, 2) DEFAULT 0,
  reserved_quantity DECIMAL(10, 2) DEFAULT 0,
  last_movement_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY (product_id, warehouse_id)
);

-- Clientes
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  document_type VARCHAR(20) CHECK (document_type IN ('dni', 'ruc', 'passport', 'ce')),
  document_number VARCHAR(50) UNIQUE NOT NULL,
  address TEXT,
  city VARCHAR(100),
  customer_type VARCHAR(20) CHECK (customer_type IN ('individual', 'business', 'contractor', 'architect', 'designer')),
  company_name VARCHAR(255),
  credit_limit DECIMAL(10, 2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Proveedores
CREATE TABLE suppliers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  ruc VARCHAR(20) UNIQUE NOT NULL,
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(20),
  address TEXT,
  city VARCHAR(100),
  credit_days DECIMAL(3, 0) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 2. TABLAS DE TRANSACCIONES
-- ============================================

-- Ventas
CREATE TABLE sales (
  id SERIAL PRIMARY KEY,
  store_id INTEGER REFERENCES stores(id) ON DELETE RESTRICT,
  customer_id INTEGER REFERENCES customers(id) ON DELETE SET NULL,
  employee_id INTEGER REFERENCES employees(id) ON DELETE RESTRICT,
  sale_number VARCHAR(50) UNIQUE NOT NULL,
  sale_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  subtotal DECIMAL(10, 2) NOT NULL,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  sale_status VARCHAR(20) CHECK (sale_status IN ('pending', 'completed', 'cancelled', 'returned')),
  payment_method VARCHAR(20) CHECK (payment_method IN ('cash', 'card', 'transfer', 'credit')),
  payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'paid', 'partial', 'overdue')),
  notes TEXT,
  invoice_number VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Items de venta
CREATE TABLE sale_items (
  id SERIAL PRIMARY KEY,
  sale_id INTEGER REFERENCES sales(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE RESTRICT,
  quantity DECIMAL(10, 2) NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  discount_percentage DECIMAL(5, 2) DEFAULT 0,
  total_price DECIMAL(10, 2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false
);

-- Compras
CREATE TABLE purchases (
  id SERIAL PRIMARY KEY,
  supplier_id INTEGER REFERENCES suppliers(id) ON DELETE RESTRICT,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE RESTRICT,
  employee_id INTEGER REFERENCES employees(id) ON DELETE RESTRICT,
  purchase_number VARCHAR(50) UNIQUE NOT NULL,
  purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expected_date TIMESTAMP WITH TIME ZONE,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  purchase_status VARCHAR(20) CHECK (purchase_status IN ('pending', 'ordered', 'received', 'cancelled')),
  payment_status VARCHAR(20) CHECK (payment_status IN ('pending', 'paid', 'partial', 'overdue')),
  supplier_invoice VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Items de compra
CREATE TABLE purchase_items (
  id SERIAL PRIMARY KEY,
  purchase_id INTEGER REFERENCES purchases(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
  quantity_ordered DECIMAL(10, 2) NOT NULL,
  quantity_received DECIMAL(10, 2) DEFAULT 0,
  unit_cost DECIMAL(10, 2) NOT NULL,
  total_cost DECIMAL(10, 2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false
);

-- Transferencias
CREATE TABLE transfers (
  id SERIAL PRIMARY KEY,
  from_warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE RESTRICT,
  to_warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE RESTRICT,
  employee_id INTEGER REFERENCES employees(id) ON DELETE RESTRICT,
  transfer_number VARCHAR(50) UNIQUE NOT NULL,
  transfer_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  transfer_status VARCHAR(20) CHECK (transfer_status IN ('pending', 'in_transit', 'completed', 'cancelled')),
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Items de transferencia
CREATE TABLE transfer_items (
  id SERIAL PRIMARY KEY,
  transfer_id INTEGER REFERENCES transfers(id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
  quantity_sent DECIMAL(10, 2) NOT NULL,
  quantity_received DECIMAL(10, 2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  needs_sync BOOLEAN DEFAULT false
);

-- Movimientos de inventario
CREATE TABLE inventory_movements (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE RESTRICT,
  employee_id INTEGER REFERENCES employees(id) ON DELETE RESTRICT,
  movement_type VARCHAR(20) CHECK (movement_type IN ('sale', 'purchase', 'transfer_out', 'transfer_in', 'adjustment', 'damage', 'return')),
  quantity DECIMAL(10, 2) NOT NULL, -- + para entradas, - para salidas
  previous_stock DECIMAL(10, 2) NOT NULL,
  new_stock DECIMAL(10, 2) NOT NULL,
  reason TEXT,
  reference_type VARCHAR(20) CHECK (reference_type IN ('sale', 'purchase', 'transfer')),
  reference_id INTEGER,
  movement_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  notes TEXT,
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- Alertas de stock
CREATE TABLE stock_alerts (
  id SERIAL PRIMARY KEY,
  product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
  warehouse_id INTEGER REFERENCES warehouses(id) ON DELETE CASCADE,
  alert_type VARCHAR(20) CHECK (alert_type IN ('low_stock', 'out_of_stock', 'overstock')),
  current_stock DECIMAL(10, 2) NOT NULL,
  threshold DECIMAL(10, 2) NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  needs_sync BOOLEAN DEFAULT false,
  last_sync_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 3. TABLAS DE SISTEMA
-- ============================================

-- Sesiones de usuario
CREATE TABLE user_sessions (
  id SERIAL PRIMARY KEY,
  employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
  session_token VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true
);

-- Configuraciones del sistema
CREATE TABLE system_configs (
  key VARCHAR(100) PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. ÍNDICES PARA OPTIMIZACIÓN
-- ============================================

-- Índices de rendimiento
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_stocks_warehouse ON stocks(warehouse_id);
CREATE INDEX idx_sales_store ON sales(store_id);
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_inventory_movements_product ON inventory_movements(product_id);
CREATE INDEX idx_inventory_movements_warehouse ON inventory_movements(warehouse_id);

-- ============================================
-- 5. TRIGGERS PARA UPDATED_AT
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a todas las tablas principales
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_warehouses_updated_at BEFORE UPDATE ON warehouses FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_employees_updated_at BEFORE UPDATE ON employees FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON suppliers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_sales_updated_at BEFORE UPDATE ON sales FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_purchases_updated_at BEFORE UPDATE ON purchases FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_transfers_updated_at BEFORE UPDATE ON transfers FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en tablas sensibles
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;

-- Ejemplo de política RLS (personalizar según necesidades)
-- CREATE POLICY "Users can only see their company data" ON employees
--   FOR ALL USING (company_id = (SELECT company_id FROM auth.jwt() -> 'company_id'));

-- ============================================
-- 7. DATOS INICIALES
-- ============================================

-- Insertar configuraciones del sistema
INSERT INTO system_configs (key, value, description) VALUES
('app_version', '1.0.0', 'Versión de la aplicación'),
('currency', 'PEN', 'Moneda del sistema'),
('tax_rate', '18.0', 'Tasa de impuesto IGV (%)'),
('low_stock_threshold', '10.0', 'Umbral de stock bajo por defecto');

-- Insertar categorías por defecto
INSERT INTO product_categories (name, code, description) VALUES
('Alfombras', 'ALF', 'Alfombras decorativas y funcionales'),
('Piso Flotante', 'PFL', 'Pisos laminados y de madera'),
('Pispak', 'PSP', 'Materiales de construcción Pispak'),
('Cielo Falso', 'CFL', 'Materiales para cielo falso'),
('Viniles', 'VIN', 'Viniles decorativos y adhesivos'),
('Cerámicos', 'CER', 'Materiales cerámicos y porcelanatos'),
('Madera', 'MAD', 'Productos de madera'),
('Accesorios', 'ACC', 'Accesorios de instalación'),
('Herramientas', 'HER', 'Herramientas de trabajo'),
('Adhesivos', 'ADH', 'Adhesivos y pegamentos');