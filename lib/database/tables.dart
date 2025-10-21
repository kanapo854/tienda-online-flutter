import 'package:drift/drift.dart';

// Tabla de Empresas/Organizaciones
@DataClassName('Company')
class Companies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get ruc => text().withLength(min: 8, max: 20).unique()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Tiendas
@DataClassName('Store')
class Stores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get companyId => integer().references(Companies, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();
  TextColumn get address => text()();
  TextColumn get city => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Almacenes
@DataClassName('Warehouse')
class Warehouses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get companyId => integer().references(Companies, #id)();
  IntColumn get storeId => integer().references(Stores, #id).nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();
  TextColumn get address => text()();
  TextColumn get warehouseType => text()(); // 'central', 'store', 'external'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Empleados
@DataClassName('Employee')
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get companyId => integer().references(Companies, #id)();
  IntColumn get storeId => integer().references(Stores, #id).nullable()();
  IntColumn get warehouseId => integer().references(Warehouses, #id).nullable()();
  TextColumn get firstName => text().withLength(min: 1, max: 50)();
  TextColumn get lastName => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().unique()();
  TextColumn get phone => text().nullable()();
  TextColumn get documentType => text()(); // 'dni', 'passport', 'ce'
  TextColumn get documentNumber => text().unique()();
  TextColumn get role => text()(); // 'admin', 'store_manager', 'warehouse_manager', 'cashier', 'employee'
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  DateTimeColumn get lastLogin => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Categorías de Productos
@DataClassName('ProductCategory')
class ProductCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();
  TextColumn get description => text().nullable()();
  IntColumn get parentId => integer().references(ProductCategories, #id).nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Productos
@DataClassName('Product')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(ProductCategories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().withLength(min: 1, max: 50).unique()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  RealColumn get purchasePrice => real()();
  RealColumn get salePrice => real()();
  TextColumn get unit => text()(); // 'metro2', 'metro', 'unidad', 'caja', 'rollo', 'kg', 'litro'
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().nullable()();
  TextColumn get imageUrls => text().nullable()(); // JSON array as string
  TextColumn get specifications => text().nullable()(); // JSON as string
  TextColumn get supplier => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Stock por Almacén
@DataClassName('Stock')
class Stocks extends Table {
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get warehouseId => integer().references(Warehouses, #id)();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get reservedQuantity => real().withDefault(const Constant(0))();
  DateTimeColumn get lastMovementAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {productId, warehouseId};
}

// Tabla de Clientes
@DataClassName('Customer')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text().withLength(min: 1, max: 50)();
  TextColumn get lastName => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get documentType => text()(); // 'dni', 'ruc', 'passport', 'ce'
  TextColumn get documentNumber => text().unique()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get customerType => text()(); // 'individual', 'business', 'contractor', 'architect', 'designer'
  TextColumn get companyName => text().nullable()();
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Proveedores
@DataClassName('Supplier')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get ruc => text().withLength(min: 8, max: 20).unique()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  RealColumn get creditDays => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}