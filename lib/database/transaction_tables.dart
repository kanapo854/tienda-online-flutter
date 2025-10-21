import 'package:drift/drift.dart';
import 'tables.dart';

// Tabla de Ventas
@DataClassName('Sale')
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get storeId => integer().references(Stores, #id)();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get saleNumber => text().unique()();
  DateTimeColumn get saleDate => dateTime()();
  RealColumn get subtotal => real()();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  TextColumn get saleStatus => text()(); // 'pending', 'completed', 'cancelled', 'returned'
  TextColumn get paymentMethod => text()(); // 'cash', 'card', 'transfer', 'credit'
  TextColumn get paymentStatus => text()(); // 'pending', 'paid', 'partial', 'overdue'
  TextColumn get notes => text().nullable()();
  TextColumn get invoiceNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Items de Venta
@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get warehouseId => integer().references(Warehouses, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get discountPercentage => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
}

// Tabla de Compras
@DataClassName('Purchase')
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  IntColumn get warehouseId => integer().references(Warehouses, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get purchaseNumber => text().unique()();
  DateTimeColumn get purchaseDate => dateTime()();
  DateTimeColumn get expectedDate => dateTime().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
  TextColumn get purchaseStatus => text()(); // 'pending', 'ordered', 'received', 'cancelled'
  TextColumn get paymentStatus => text()(); // 'pending', 'paid', 'partial', 'overdue'
  TextColumn get supplierInvoice => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Items de Compra
@DataClassName('PurchaseItem')
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantityOrdered => real()();
  RealColumn get quantityReceived => real().withDefault(const Constant(0))();
  RealColumn get unitCost => real()();
  RealColumn get totalCost => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
}

// Tabla de Transferencias entre Almacenes
@DataClassName('Transfer')
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromWarehouseId => integer().references(Warehouses, #id)();
  IntColumn get toWarehouseId => integer().references(Warehouses, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get transferNumber => text().unique()();
  DateTimeColumn get transferDate => dateTime()();
  TextColumn get transferStatus => text()(); // 'pending', 'in_transit', 'completed', 'cancelled'
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Items de Transferencia
@DataClassName('TransferItem')
class TransferItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transferId => integer().references(Transfers, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantitySent => real()();
  RealColumn get quantityReceived => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
}

// Tabla de Movimientos de Inventario (Auditoría)
@DataClassName('InventoryMovement')
class InventoryMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get warehouseId => integer().references(Warehouses, #id)();
  IntColumn get employeeId => integer().references(Employees, #id).nullable()();
  TextColumn get movementType => text()(); // 'sale', 'purchase', 'transfer_out', 'transfer_in', 'adjustment', 'damage', 'return'
  RealColumn get quantity => real()();
  RealColumn get previousStock => real()();
  RealColumn get newStock => real()();
  TextColumn get reason => text().nullable()();
  TextColumn get referenceType => text().nullable()(); // 'sale', 'purchase', 'transfer'
  IntColumn get referenceId => integer().nullable()();
  DateTimeColumn get movementDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Alertas de Stock
@DataClassName('StockAlert')
class StockAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get warehouseId => integer().references(Warehouses, #id)();
  TextColumn get alertType => text()(); // 'low_stock', 'out_of_stock', 'overstock'
  RealColumn get currentStock => real()();
  RealColumn get threshold => real()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
}

// Tabla de Sesiones de Usuario (para autenticación local)
@DataClassName('UserSession')
class UserSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get sessionToken => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get lastActivity => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// Tabla de Configuraciones del Sistema
@DataClassName('SystemConfig')
class SystemConfigs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}