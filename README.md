# Sistema Offline-First con Drift + Supabase para Tienda de Decoración y Construcción

## 🏗️ **Arquitectura Empresarial Completa**

Este proyecto implementa un **sistema empresarial offline-first** desarrollado en Flutter utilizando **Drift** como base de datos local y **Supabase** como backend en la nube, diseñado específicamente para empresas de productos de decoración y construcción.

## 📊 **Diseño de Base de Datos Empresarial**

### 🛠️ **Stack Tecnológico**

- **Frontend**: Flutter (Multi-plataforma)
- **Base de datos local**: Drift (SQLite)
- **Backend**: Supabase (PostgreSQL + API REST + Autenticación)
- **Sincronización**: Bidireccional automática
- **Autenticación**: Supabase Auth + Autenticación local offline

### 🏢 **Estructura Organizacional**


#### **1. Gestión de Tiendas**
```sql
Stores (Tiendas):
- id: integer (PK)
- company_id: integer (FK → Companies)
- name: string (Nombre de la tienda)
- code: string (Código único)
- address: string (Dirección)
- city: string (Ciudad)
- phone: string (Teléfono)
- latitude, longitude: real (Ubicación GPS)
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

#### **2. Gestión de Almacenes**
```sql
Warehouses (Almacenes):
- id: integer (PK)
- company_id: integer (FK → Companies)
- store_id: integer (FK → Stores, nullable)
- name: string (Nombre del almacén)
- code: string (Código único)
- address: string (Dirección)
- warehouse_type: string ('central', 'store', 'external')
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

#### **3. Gestión de Empleados y Autenticación**
```sql
Employees (Empleados):
- id: integer (PK)
- company_id: integer (FK → Companies)
- store_id: integer (FK → Stores, nullable)
- warehouse_id: integer (FK → Warehouses, nullable)
- first_name, last_name: string
- email: string (único, para login)
- phone: string
- document_type: string ('dni', 'passport', 'ce')
- document_number: string (único)
- role: string ('admin', 'store_manager', 'warehouse_manager', 'cashier', 'employee')
- password_hash: string (Hash seguro)
- salt: string (Salt para password)
- last_login: datetime
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

**Roles de Usuario:**
- `admin_users`: Administrador usuarios
- `admin_employees`: Administrador empleados
- `admin_inventory`: Administrador de inventario
- `customer`: Cliente

### 📦 **Gestión de Productos**

#### **6. Categorías de Productos**
```sql
ProductCategories (Categorías):
- id: integer (PK)
- name: string (Nombre de categoría)
- code: string (Código único)
- description: string
- parent_id: integer (FK → ProductCategories, para subcategorías)
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

**Categorías Predefinidas para Construcción:**
- Alfombras decorativas
- Piso flotante
- Materiales Pispak
- Cielo falso
- Viniles decorativos
- Materiales cerámicos
- Productos de madera
- Accesorios de instalación
- Herramientas
- Adhesivos y pegamentos

#### **7. Productos**
```sql
Products (Productos):
- id: integer (PK)
- category_id: integer (FK → ProductCategories)
- name: string (Nombre del producto)
- sku: string (Código único)
- barcode: string (Código de barras)
- description: string
- brand: string (Marca)
- model: string (Modelo)
- purchase_price: real (Precio de compra)
- sale_price: real (Precio de venta)
- unit: string ('metro2', 'metro', 'unidad', 'caja', 'rollo', 'kg', 'litro')
- min_stock: real (Stock mínimo)
- max_stock: real (Stock máximo)
- image_urls: string (JSON array de URLs)
- specifications: string (JSON de especificaciones técnicas)
- supplier: string (Proveedor principal)
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

#### **8. Control de Stock por Almacén**
```sql
Stocks (Stock):
- product_id: integer (PK, FK → Products)
- warehouse_id: integer (PK, FK → Warehouses)
- quantity: real (Cantidad disponible)
- reserved_quantity: real (Cantidad reservada)
- last_movement_at: datetime
- updated_at, needs_sync, last_sync_at
```

### 👥 **Gestión de Clientes **

#### **9. Clientes**
```sql
Customers (Clientes):
- id: integer (PK)
- first_name, last_name: string
- email: string
- phone: string
- document_type: string ('dni', 'ruc', 'passport', 'ce')
- document_number: string (único)
- address: string
- city: string
- customer_type: string ('individual', 'business', 'contractor', 'architect', 'designer')
- company_name: string (para empresas)
- credit_limit: real (Límite de crédito)
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```


### 💰 **Sistema de Transacciones**

#### **10. Ventas**
```sql
Sales (Ventas):
- id: integer (PK)
- store_id: integer (FK → Stores)
- customer_id: integer (FK → Customers)
- employee_id: integer (FK → Employees)
- sale_number: string (único)
- sale_date: datetime
- subtotal: real
- tax_amount: real (IGV)
- discount_amount: real
- total_amount: real
- sale_status: string ('pending', 'completed', 'cancelled', 'returned')
- payment_method: string ('cash', 'card', 'transfer', 'credit')
- payment_status: string ('pending', 'paid', 'partial', 'overdue')
- notes: string
- invoice_number: string
- created_at, updated_at, needs_sync, last_sync_at

SaleItems (Items de Venta):
- id: integer (PK)
- sale_id: integer (FK → Sales)
- product_id: integer (FK → Products)
- warehouse_id: integer (FK → Warehouses)
- quantity: real
- unit_price: real
- discount_percentage: real
- total_price: real
- notes: string
- created_at, needs_sync
```

#### **11. Compras**
```sql
Purchases (Compras):
- id: integer (PK)
- supplier_id: integer (FK → Suppliers)
- warehouse_id: integer (FK → Warehouses)
- employee_id: integer (FK → Employees)
- purchase_number: string (único)
- purchase_date: datetime
- expected_date: datetime
- subtotal: real
- tax_amount: real
- total_amount: real
- purchase_status: string ('pending', 'ordered', 'received', 'cancelled')
- payment_status: string ('pending', 'paid', 'partial', 'overdue')
- supplier_invoice: string
- notes: string
- created_at, updated_at, needs_sync, last_sync_at

PurchaseItems (Items de Compra):
- id: integer (PK)
- purchase_id: integer (FK → Purchases)
- product_id: integer (FK → Products)
- quantity_ordered: real
- quantity_received: real
- unit_cost: real
- total_cost: real
- notes: string
- created_at, needs_sync
```

#### **14. Alertas de Stock**
```sql
StockAlerts (Alertas):
- id: integer (PK)
- product_id: integer (FK → Products)
- warehouse_id: integer (FK → Warehouses)
- alert_type: string ('low_stock', 'out_of_stock', 'overstock')
- current_stock: real
- threshold: real
- is_read: boolean
- created_at: datetime
- read_at: datetime
- needs_sync, last_sync_at
```

### 🔐 **Sistema de Autenticación y Sesiones**

#### **15. Sesiones de Usuario**
```sql
UserSessions (Sesiones):
- id: integer (PK)
- employee_id: integer (FK → Employees)
- session_token: string (único)
- created_at: datetime
- expires_at: datetime
- last_activity: datetime
- is_active: boolean
```

#### **16. Configuraciones del Sistema**
```sql
SystemConfigs (Configuraciones):
- key: string (PK)
- value: string
- description: string
- updated_at: datetime
```

**Configuraciones Predefinidas:**
- `app_version`: Versión de la aplicación
- `currency`: Moneda del sistema (PEN)
- `tax_rate`: Tasa de impuesto (18.0% IGV)
- `low_stock_threshold`: Umbral de stock bajo por defecto

## 🔄 **Sistema de Sincronización Offline-First**

### **Características de Sincronización:**

1. **Bidireccional**: Sube y descarga cambios automáticamente
2. **Incremental**: Solo sincroniza datos modificados
3. **Conflictos**: Resolución automática (servidor gana)
4. **Retry**: Reintentos automáticos en caso de error
5. **Prioridad**: Datos maestros primero, luego transacciones

### **Flujo de Sincronización:**

```
1. Verificar conectividad a internet
2. Sincronizar datos maestros:
   - Empresas → Tiendas → Almacenes → Empleados
   - Categorías → Productos → Clientes → Proveedores
3. Sincronizar transacciones:
   - Subir: Ventas → Compras → Transferencias locales
   - Descargar: Nuevas transacciones del servidor
4. Sincronizar inventario:
   - Subir: Movimientos locales
   - Descargar: Stock actualizado
5. Marcar como sincronizado
```

## 🔐 **Sistema de Autenticación Dual**

### **Autenticación Online (Supabase):**
- Login con email/password
- Recuperación de contraseña
- Gestión de sesiones JWT
- Metadata de usuario

### **Autenticación Offline (Local):**
- Hash SHA-256 + Salt único
- Sesiones locales con token
- Expiración de 8 horas
- Validación offline completa

## 📋 **Configuración del Proyecto**

### **1. Configurar Supabase:**
```bash
# Crear proyecto en https://supabase.com
# Obtener URL y ANON_KEY
# Actualizar en lib/services/auth_service.dart:
const String supabaseUrl = 'TU_SUPABASE_URL';
const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
```

### **2. Instalación y Ejecución:**
```bash
flutter pub get
dart run build_runner build
flutter run
```

### **3. Estructura de Base de Datos en Supabase:**
```sql
-- Crear todas las tablas en Supabase con la misma estructura
-- Activar Row Level Security (RLS)
-- Configurar políticas de acceso por empresa/tienda
```
Este sistema proporciona el flujo de un sistema para el sector de decoración y construcción, con capacidades offline robustas, sincronización automática y escalabilidad para múltiples tiendas y almacenes.
