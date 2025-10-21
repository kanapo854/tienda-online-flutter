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

#### **1. Gestión de Empresas**
```sql
Companies (Empresas):
- id: integer (PK)
- name: string (Nombre de la empresa)
- ruc: string (RUC/NIT único)
- address: string (Dirección)
- phone: string (Teléfono)
- email: string (Email)
- is_active: boolean
- created_at, updated_at, needs_sync, last_sync_at
```

#### **2. Gestión de Tiendas**
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

#### **3. Gestión de Almacenes**
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

#### **4. Gestión de Empleados y Autenticación**
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
- `admin`: Administrador general
- `store_manager`: Encargado de tienda
- `warehouse_manager`: Encargado de almacén
- `cashier`: Cajero
- `employee`: Empleado general

### 📦 **Gestión de Productos**

#### **5. Categorías de Productos**
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

#### **6. Productos**
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

#### **7. Control de Stock por Almacén**
```sql
Stocks (Stock):
- product_id: integer (PK, FK → Products)
- warehouse_id: integer (PK, FK → Warehouses)
- quantity: real (Cantidad disponible)
- reserved_quantity: real (Cantidad reservada)
- last_movement_at: datetime
- updated_at, needs_sync, last_sync_at
```

### 👥 **Gestión de Clientes y Proveedores**

#### **8. Clientes**
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

#### **9. Proveedores**
```sql
Suppliers (Proveedores):
- id: integer (PK)
- name: string (Nombre del proveedor)
- ruc: string (RUC único)
- contact_person: string (Persona de contacto)
- email: string
- phone: string
- address: string
- city: string
- credit_days: real (Días de crédito)
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

#### **12. Transferencias entre Almacenes**
```sql
Transfers (Transferencias):
- id: integer (PK)
- from_warehouse_id: integer (FK → Warehouses)
- to_warehouse_id: integer (FK → Warehouses)
- employee_id: integer (FK → Employees)
- transfer_number: string (único)
- transfer_date: datetime
- transfer_status: string ('pending', 'in_transit', 'completed', 'cancelled')
- reason: string
- notes: string
- created_at, updated_at, needs_sync, last_sync_at

TransferItems (Items de Transferencia):
- id: integer (PK)
- transfer_id: integer (FK → Transfers)
- product_id: integer (FK → Products)
- quantity_sent: real
- quantity_received: real
- notes: string
- created_at, needs_sync
```

### 📊 **Sistema de Auditoría y Control**

#### **13. Movimientos de Inventario**
```sql
InventoryMovements (Movimientos):
- id: integer (PK)
- product_id: integer (FK → Products)
- warehouse_id: integer (FK → Warehouses)
- employee_id: integer (FK → Employees)
- movement_type: string ('sale', 'purchase', 'transfer_out', 'transfer_in', 'adjustment', 'damage', 'return')
- quantity: real (+ para entradas, - para salidas)
- previous_stock: real
- new_stock: real
- reason: string
- reference_type: string ('sale', 'purchase', 'transfer')
- reference_id: integer
- movement_date: datetime
- notes: string
- needs_sync, last_sync_at
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

## 🚀 **Funcionalidades Implementadas**

### ✅ **Core del Sistema:**
1. **Gestión Empresarial**: Empresas, tiendas, almacenes múltiples
2. **Gestión de Personal**: Empleados con roles y permisos
3. **Autenticación Robusta**: Online/offline con seguridad
4. **Gestión de Productos**: Categorías específicas para construcción
5. **Control de Stock**: Por almacén con alertas automáticas
6. **Sistema de Ventas**: Completo con items y métodos de pago
7. **Sistema de Compras**: Gestión de proveedores y recepciones
8. **Transferencias**: Entre almacenes con seguimiento
9. **Auditoría**: Movimientos de inventario con trazabilidad
10. **Sincronización**: Automática y bidireccional

### 📱 **Interfaces de Usuario:**
- **Splash Screen**: Carga inicial con branding
- **Login Screen**: Autenticación dual (online/offline)
- **Dashboard**: Estadísticas en tiempo real
- **Navegación**: BottomNavigationBar intuitiva

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

## 🎯 **Casos de Uso Empresariales**

### **Escenario 1: Tienda con Múltiples Almacenes**
- Almacén principal + almacén de tienda
- Transferencias automáticas según stock mínimo
- Control independiente por ubicación

### **Escenario 2: Cadena de Tiendas**
- Múltiples tiendas de una empresa
- Sincronización centralizada
- Reportes consolidados

### **Escenario 3: Trabajo Offline**
- Ventas sin conexión a internet
- Sincronización automática al recuperar conexión
- Continuidad operativa garantizada

### **Escenario 4: Gestión de Empleados**
- Roles específicos por tienda/almacén
- Autenticación segura offline
- Trazabilidad de operaciones por usuario

## 🚀 **Próximas Funcionalidades**

- [ ] **Reportes Avanzados**: Ventas, inventario, rentabilidad
- [ ] **Dashboard Analytics**: Gráficos y métricas
- [ ] **Gestión de Promociones**: Descuentos y ofertas
- [ ] **Punto de Venta (POS)**: Interface de cajero
- [ ] **Códigos de Barras**: Escáner integrado
- [ ] **Fotos de Productos**: Gestión de imágenes
- [ ] **Notificaciones Push**: Alertas en tiempo real
- [ ] **Backup Automático**: Respaldo en la nube
- [ ] **Multi-idioma**: Soporte internacional
- [ ] **API REST**: Para integraciones externas

## 📱 **Compatibilidad Multi-plataforma**

- ✅ **Android**: Nativo con rendimiento óptimo
- ✅ **iOS**: Nativo con rendimiento óptimo
- ✅ **Windows Desktop**: Para oficinas
- ✅ **macOS Desktop**: Para oficinas
- ✅ **Linux Desktop**: Para servidores
- ✅ **Web**: Acceso desde cualquier navegador

## 🛡️ **Seguridad y Cumplimiento**

- **Encriptación**: Datos sensibles encriptados
- **Auditoría**: Registro completo de operaciones
- **Roles y Permisos**: Control granular de acceso
- **Backup**: Respaldo automático y manual
- **GDPR Ready**: Cumplimiento de protección de datos

Este sistema proporciona una **solución empresarial completa** para el sector de decoración y construcción, con capacidades offline robustas, sincronización automática y escalabilidad para múltiples tiendas y almacenes.