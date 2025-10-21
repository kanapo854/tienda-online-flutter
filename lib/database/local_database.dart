import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'transaction_tables.dart';
import 'notification_tables.dart';

part 'local_database.g.dart';

@DriftDatabase(tables: [
  // Tablas principales
  Companies,
  Stores,
  Warehouses,
  Employees,
  ProductCategories,
  Products,
  Stocks,
  Customers,
  Suppliers,
  
  // Tablas de transacciones
  Sales,
  SaleItems,
  Purchases,
  PurchaseItems,
  Transfers,
  TransferItems,
  InventoryMovements,
  StockAlerts,
  UserSessions,
  SystemConfigs,
  
  // Tablas de notificaciones y solicitudes
  EmployeeRegistrationRequests,
  SystemNotifications,
  EmployeeHistories,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // Migración de v1 a v2: Actualizar sucursales
          await _migrateTo2();
        }
        if (from == 2 && to == 3) {
          // Migración de v2 a v3: Crear tablas de notificaciones
          await _migrateTo3(m);
        }
        if (from == 1 && to == 3) {
          // Migración directa de v1 a v3
          await _migrateTo2();
          await _migrateTo3(m);
        }
      },
    );
  }

  // Insertar datos iniciales
  Future<void> _insertInitialData() async {
    // Configuraciones del sistema (una por una)
    try {
      await into(systemConfigs).insert(SystemConfigsCompanion.insert(
        key: 'app_version',
        value: '1.0.0',
        description: const Value('Versión de la aplicación'),
      ));
      
      await into(systemConfigs).insert(SystemConfigsCompanion.insert(
        key: 'currency',
        value: 'PEN',
        description: const Value('Moneda del sistema'),
      ));
      
      await into(systemConfigs).insert(SystemConfigsCompanion.insert(
        key: 'tax_rate',
        value: '18.0',
        description: const Value('Tasa de impuesto (IGV)'),
      ));
      
      await into(systemConfigs).insert(SystemConfigsCompanion.insert(
        key: 'low_stock_threshold',
        value: '10.0',
        description: const Value('Umbral de stock bajo por defecto'),
      ));

      // Empresa por defecto
      await into(companies).insert(CompaniesCompanion.insert(
        name: 'Tienda Online',
        ruc: '20123456789',
        address: const Value('Av. Principal 123'),
        phone: const Value('+51 999 888 777'),
        email: const Value('contacto@tiendaonline.com'),
      ));

      // Sucursales por defecto
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Norte',
        code: 'SN001',
        address: 'Av. Los Olivos 123, Independencia',
        city: 'Lima Norte',
        phone: const Value('+51 999 888 001'),
        isActive: const Value(true),
      ));
      
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Sur',
        code: 'SS001',
        address: 'Av. Villa El Salvador 456, Villa María del Triunfo',
        city: 'Lima Sur',
        phone: const Value('+51 999 888 002'),
        isActive: const Value(true),
      ));
      
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Centro',
        code: 'SC001',
        address: 'Jr. de la Unión 789, Cercado de Lima',
        city: 'Lima Centro',
        phone: const Value('+51 999 888 003'),
        isActive: const Value(true),
      ));

      // Almacenes por sucursal
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Norte',
        code: 'AN001',
        address: 'Av. Los Olivos 123, Independencia',
        warehouseType: 'sucursal',
        storeId: const Value(1), // Sucursal Norte
        isActive: const Value(true),
      ));
      
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Sur',
        code: 'AS001',
        address: 'Av. Villa El Salvador 456, Villa María del Triunfo',
        warehouseType: 'sucursal',
        storeId: const Value(2), // Sucursal Sur
        isActive: const Value(true),
      ));
      
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Centro',
        code: 'AC001',
        address: 'Jr. de la Unión 789, Cercado de Lima',
        warehouseType: 'sucursal',
        storeId: const Value(3), // Sucursal Centro
        isActive: const Value(true),
      ));

      // Categorías de productos por defecto (una por una)
      await into(productCategories).insert(ProductCategoriesCompanion.insert(
        name: 'Alfombras',
        code: 'ALF',
        description: const Value('Alfombras decorativas y funcionales'),
      ));
      
      await into(productCategories).insert(ProductCategoriesCompanion.insert(
        name: 'Piso Flotante',
        code: 'PFL',
        description: const Value('Pisos laminados y de madera'),
      ));
      
      await into(productCategories).insert(ProductCategoriesCompanion.insert(
        name: 'Pispak',
        code: 'PSP',
        description: const Value('Materiales de construcción Pispak'),
      ));
      
      await into(productCategories).insert(ProductCategoriesCompanion.insert(
        name: 'Cielo Falso',
        code: 'CFL',
        description: const Value('Materiales para cielo falso'),
      ));
      
      await into(productCategories).insert(ProductCategoriesCompanion.insert(
        name: 'Viniles',
        code: 'VIN',
        description: const Value('Viniles decorativos y adhesivos'),
      ));
    } catch (e) {
      // Ignorar errores si los datos ya existen
      print('Initial data already exists or error inserting: $e');
    }
  }

  // ============== CRUD Operations ==============
  
  // Empresas
  Future<List<Company>> getAllCompanies() => select(companies).get();
  
  Future<Company?> getCompanyById(int id) => 
    (select(companies)..where((c) => c.id.equals(id))).getSingleOrNull();
    
  Future<int> insertCompany(CompaniesCompanion company) => 
    into(companies).insert(company);
    
  Future<bool> updateCompany(CompaniesCompanion company) => 
    update(companies).replace(company);
    
  Future<int> deleteCompany(int id) => 
    (delete(companies)..where((c) => c.id.equals(id))).go();

  // Tiendas
  Future<List<Store>> getAllStores() => select(stores).get();
  
  Future<List<Store>> getStoresByCompany(int companyId) => 
    (select(stores)..where((s) => s.companyId.equals(companyId))).get();
    
  Future<Store?> getStoreById(int id) => 
    (select(stores)..where((s) => s.id.equals(id))).getSingleOrNull();
    
  Future<int> insertStore(StoresCompanion store) => 
    into(stores).insert(store);
    
  Future<bool> updateStore(StoresCompanion store) => 
    update(stores).replace(store);
    
  Future<int> deleteStore(int id) => 
    (delete(stores)..where((s) => s.id.equals(id))).go();

  // Almacenes
  Future<List<Warehouse>> getAllWarehouses() => select(warehouses).get();
  
  Future<List<Warehouse>> getWarehousesByStore(int storeId) => 
    (select(warehouses)..where((w) => w.storeId.equals(storeId))).get();
    
  Future<Warehouse?> getWarehouseById(int id) => 
    (select(warehouses)..where((w) => w.id.equals(id))).getSingleOrNull();
    
  Future<int> insertWarehouse(WarehousesCompanion warehouse) => 
    into(warehouses).insert(warehouse);
    
  Future<bool> updateWarehouse(WarehousesCompanion warehouse) => 
    update(warehouses).replace(warehouse);
    
  Future<int> deleteWarehouse(int id) => 
    (delete(warehouses)..where((w) => w.id.equals(id))).go();

  // Empleados
  Future<List<Employee>> getAllEmployees() => select(employees).get();
  
  Future<Employee?> getEmployeeByEmail(String email) => 
    (select(employees)..where((e) => e.email.equals(email))).getSingleOrNull();
    
  Future<Employee?> getEmployeeById(int id) => 
    (select(employees)..where((e) => e.id.equals(id))).getSingleOrNull();
    
  Future<int> insertEmployee(EmployeesCompanion employee) => 
    into(employees).insert(employee);
    
  Future<bool> updateEmployee(EmployeesCompanion employee) => 
    update(employees).replace(employee);
    
  Future<int> deleteEmployee(int id) => 
    (delete(employees)..where((e) => e.id.equals(id))).go();

  Future<List<Employee>> getEmployeesByRole(String role) => 
    (select(employees)..where((e) => e.role.equals(role))).get();

  Future<List<Employee>> getActiveEmployees() => 
    (select(employees)..where((e) => e.isActive.equals(true))).get();

  Future<List<Employee>> getEmployeesByCompany(int companyId) => 
    (select(employees)..where((e) => e.companyId.equals(companyId))).get();

  // Productos
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<Product?> getProductById(int id) => 
    (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
    
  Future<Product?> getProductBySku(String sku) => 
    (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();
    
  Future<List<Product>> getProductsByCategory(int categoryId) => 
    (select(products)..where((p) => p.categoryId.equals(categoryId))).get();
    
  Future<List<Product>> searchProducts(String searchTerm) => 
    (select(products)..where((p) => 
      p.name.contains(searchTerm) | 
      p.sku.contains(searchTerm) | 
      p.brand.contains(searchTerm))).get();
      
  Future<int> insertProduct(ProductsCompanion product) => 
    into(products).insert(product);
    
  Future<bool> updateProduct(ProductsCompanion product) => 
    update(products).replace(product);
    
  Future<int> deleteProduct(int id) => 
    (delete(products)..where((p) => p.id.equals(id))).go();

  // Stock
  Future<List<Stock>> getAllStocks() => select(stocks).get();
  
  Future<Stock?> getStockByProductAndWarehouse(int productId, int warehouseId) => 
    (select(stocks)..where((s) => 
      s.productId.equals(productId) & s.warehouseId.equals(warehouseId))).getSingleOrNull();
      
  Future<List<Stock>> getStockByWarehouse(int warehouseId) => 
    (select(stocks)..where((s) => s.warehouseId.equals(warehouseId))).get();
    
  Future<List<Stock>> getStockByProduct(int productId) => 
    (select(stocks)..where((s) => s.productId.equals(productId))).get();
    
  Future<List<Stock>> getLowStockItems(double threshold) => 
    (select(stocks)..where((s) => s.quantity.isSmallerThanValue(threshold))).get();
    
  Future<int> insertStock(StocksCompanion stock) => 
    into(stocks).insert(stock);
    
  Future<bool> updateStock(StocksCompanion stock) => 
    update(stocks).replace(stock);
    
  Future<int> deleteStock(int productId, int warehouseId) => 
    (delete(stocks)..where((s) => 
      s.productId.equals(productId) & s.warehouseId.equals(warehouseId))).go();

  // Actualizar stock después de movimiento
  Future<void> updateStockQuantity(int productId, int warehouseId, double newQuantity) async {
    await (update(stocks)
      ..where((s) => s.productId.equals(productId) & s.warehouseId.equals(warehouseId)))
      .write(StocksCompanion(
        quantity: Value(newQuantity),
        lastMovementAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ));
  }

  // Decrementar stock después de una venta
  Future<bool> decrementStock(int productId, int warehouseId, double quantityToDeduct) async {
    // Primero verificar si hay suficiente stock
    final currentStock = await getStockByProductAndWarehouse(productId, warehouseId);
    
    if (currentStock == null) {
      throw Exception('Stock no encontrado para el producto $productId en warehouse $warehouseId');
    }
    
    if (currentStock.quantity < quantityToDeduct) {
      throw Exception('Stock insuficiente. Disponible: ${currentStock.quantity}, Solicitado: $quantityToDeduct');
    }
    
    final newQuantity = currentStock.quantity - quantityToDeduct;
    
    await updateStockQuantity(productId, warehouseId, newQuantity);
    
    // Crear alerta si el stock está bajo
    await _checkAndCreateLowStockAlert(productId, warehouseId, newQuantity);
    
    return true;
  }

  // Verificar y crear alerta de stock bajo
  Future<void> _checkAndCreateLowStockAlert(int productId, int warehouseId, double currentQuantity) async {
    final config = await getSystemConfiguration('low_stock_threshold');
    final lowStockThreshold = double.tryParse(config?.value ?? '10') ?? 10.0;
    
    if (currentQuantity <= lowStockThreshold) {
      // Verificar si ya existe una alerta no leída para este producto
      final existingAlert = await (select(stockAlerts)
        ..where((sa) => sa.productId.equals(productId) & 
                       sa.warehouseId.equals(warehouseId) & 
                       sa.isRead.equals(false)))
        .getSingleOrNull();
      
      if (existingAlert == null) {
        await into(stockAlerts).insert(
          StockAlertsCompanion.insert(
            productId: productId,
            warehouseId: warehouseId,
            alertType: 'low_stock',
            currentStock: currentQuantity,
            threshold: lowStockThreshold,
          ),
        );
      }
    }
  }

  // Categorías de productos
  Future<List<ProductCategory>> getAllCategories() => select(productCategories).get();
  
  Future<ProductCategory?> getCategoryById(int id) => 
    (select(productCategories)..where((c) => c.id.equals(id))).getSingleOrNull();
    
  Future<int> insertCategory(ProductCategoriesCompanion category) => 
    into(productCategories).insert(category);

  // Clientes
  Future<List<Customer>> getAllCustomers() => select(customers).get();
  
  Future<Customer?> getCustomerById(int id) => 
    (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    
  Future<List<Customer>> searchCustomers(String searchTerm) => 
    (select(customers)..where((c) => 
      c.firstName.contains(searchTerm) | 
      c.lastName.contains(searchTerm) | 
      c.documentNumber.contains(searchTerm))).get();
      
  Future<int> insertCustomer(CustomersCompanion customer) => 
    into(customers).insert(customer);

  // Proveedores
  Future<List<Supplier>> getAllSuppliers() => select(suppliers).get();
  
  Future<Supplier?> getSupplierById(int id) => 
    (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
    
  Future<int> insertSupplier(SuppliersCompanion supplier) => 
    into(suppliers).insert(supplier);

  // Ventas
  Future<List<Sale>> getAllSales() => select(sales).get();
  
  Future<Sale?> getSaleById(int id) => 
    (select(sales)..where((s) => s.id.equals(id))).getSingleOrNull();
    
  Future<List<Sale>> getSalesByStore(int storeId) => 
    (select(sales)..where((s) => s.storeId.equals(storeId))).get();
    
  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) => 
    (select(sales)..where((s) => 
      s.saleDate.isBetweenValues(start, end))).get();
      
  Future<int> insertSale(SalesCompanion sale) => 
    into(sales).insert(sale);

  // Items de venta
  Future<List<SaleItem>> getSaleItems(int saleId) => 
    (select(saleItems)..where((si) => si.saleId.equals(saleId))).get();
    
  Future<int> insertSaleItem(SaleItemsCompanion saleItem) => 
    into(saleItems).insert(saleItem);

  // Compras
  Future<List<Purchase>> getAllPurchases() => select(purchases).get();
  
  Future<Purchase?> getPurchaseById(int id) => 
    (select(purchases)..where((p) => p.id.equals(id))).getSingleOrNull();
    
  Future<int> insertPurchase(PurchasesCompanion purchase) => 
    into(purchases).insert(purchase);

  // Items de compra
  Future<List<PurchaseItem>> getPurchaseItems(int purchaseId) => 
    (select(purchaseItems)..where((pi) => pi.purchaseId.equals(purchaseId))).get();
    
  Future<int> insertPurchaseItem(PurchaseItemsCompanion purchaseItem) => 
    into(purchaseItems).insert(purchaseItem);

  // Transferencias
  Future<List<Transfer>> getAllTransfers() => select(transfers).get();
  
  Future<Transfer?> getTransferById(int id) => 
    (select(transfers)..where((t) => t.id.equals(id))).getSingleOrNull();
    
  Future<int> insertTransfer(TransfersCompanion transfer) => 
    into(transfers).insert(transfer);

  // Movimientos de inventario
  Future<List<InventoryMovement>> getInventoryMovementsByProduct(int productId) => 
    (select(inventoryMovements)..where((im) => im.productId.equals(productId))).get();
    
  Future<int> insertInventoryMovement(InventoryMovementsCompanion movement) => 
    into(inventoryMovements).insert(movement);

  // Alertas de stock
  Future<List<StockAlert>> getUnreadAlerts() => 
    (select(stockAlerts)..where((sa) => sa.isRead.equals(false))).get();
    
  Future<int> insertStockAlert(StockAlertsCompanion alert) => 
    into(stockAlerts).insert(alert);

  // Sesiones de usuario
  Future<UserSession?> getActiveSession(String token) => 
    (select(userSessions)..where((us) => 
      us.sessionToken.equals(token) & us.isActive.equals(true))).getSingleOrNull();
      
  Future<int> insertSession(UserSessionsCompanion session) => 
    into(userSessions).insert(session);
    
  Future<void> deactivateSession(String token) async {
    await (update(userSessions)
      ..where((us) => us.sessionToken.equals(token)))
      .write(const UserSessionsCompanion(isActive: Value(false)));
  }

  // Configuraciones del sistema
  Future<String?> getConfigValue(String key) async {
    final config = await (select(systemConfigs)
      ..where((sc) => sc.key.equals(key))).getSingleOrNull();
    return config?.value;
  }

  Future<SystemConfig?> getSystemConfiguration(String key) async {
    return await (select(systemConfigs)
      ..where((sc) => sc.key.equals(key))).getSingleOrNull();
  }
  
  Future<void> setConfigValue(String key, String value, String description) async {
    await into(systemConfigs).insertOnConflictUpdate(SystemConfigsCompanion(
      key: Value(key),
      value: Value(value),
      description: Value(description),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ============== Sync Operations ==============
  
  // Obtener elementos que necesitan sincronización (método simplificado)
  Future<List<Map<String, dynamic>>> getItemsNeedingSync(String tableName) async {
    final query = 'SELECT * FROM $tableName WHERE needs_sync = 1';
    final result = await customSelect(query).get();
    return result.map((row) => row.data).toList();
  }

  // Marcar elemento como sincronizado
  Future<void> markAsSynced<T extends Table>(
    TableInfo<T, dynamic> table,
    int id,
  ) async {
    await (update(table)..where((tbl) => (tbl as dynamic).id.equals(id)))
      .write({
        'needs_sync': false,
        'last_sync_at': DateTime.now(),
      } as Insertable<dynamic>);
  }

  // ============== MÉTODOS PARA SOLICITUDES DE EMPLEADOS ==============
  
  /// Crear solicitud de registro de empleado
  Future<int> createEmployeeRegistrationRequest(EmployeeRegistrationRequestsCompanion request) async {
    return await into(employeeRegistrationRequests).insert(request);
  }
  
  /// Obtener todas las solicitudes pendientes
  Future<List<EmployeeRegistrationRequest>> getPendingEmployeeRequests() async {
    return await (select(employeeRegistrationRequests)
      ..where((tbl) => tbl.status.equals('pending'))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.requestedAt)]))
      .get();
  }
  
  /// Obtener solicitudes por admin empleados
  Future<List<EmployeeRegistrationRequest>> getEmployeeRequestsByAdmin(int adminId) async {
    return await (select(employeeRegistrationRequests)
      ..where((tbl) => tbl.requestedBy.equals(adminId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.requestedAt)]))
      .get();
  }
  
  /// Actualizar estado de solicitud
  Future<bool> updateEmployeeRequestStatus(
    int requestId, 
    String status, 
    int approvedBy, 
    {String? rejectionReason, int? createdUserId}
  ) async {
    final result = await (update(employeeRegistrationRequests)
      ..where((tbl) => tbl.id.equals(requestId)))
      .write(EmployeeRegistrationRequestsCompanion(
        status: Value(status),
        approvedBy: Value(approvedBy),
        approvedAt: Value(DateTime.now()),
        rejectionReason: rejectionReason != null ? Value(rejectionReason) : const Value.absent(),
        createdUserId: createdUserId != null ? Value(createdUserId) : const Value.absent(),
      ));
    return result > 0;
  }
  
  // ============== MÉTODOS PARA NOTIFICACIONES ==============
  
  /// Crear notificación
  Future<int> createNotification(SystemNotificationsCompanion notification) async {
    return await into(systemNotifications).insert(notification);
  }
  
  /// Obtener notificaciones por usuario y rol
  Future<List<SystemNotification>> getNotificationsByRole(String role, {bool onlyUnread = false}) async {
    final query = select(systemNotifications)
      ..where((tbl) => tbl.targetRole.equals(role));
    
    if (onlyUnread) {
      query.where((tbl) => tbl.isRead.equals(false));
    }
    
    query.orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    
    return await query.get();
  }
  
  /// Marcar notificación como leída
  Future<bool> markNotificationAsRead(int notificationId) async {
    final result = await (update(systemNotifications)
      ..where((tbl) => tbl.id.equals(notificationId)))
      .write(const SystemNotificationsCompanion(
        isRead: Value(true),
        readAt: Value.absent(),
      ));
    return result > 0;
  }
  
  /// Obtener número de notificaciones no leídas
  Future<int> getUnreadNotificationCount(String role) async {
    final query = selectOnly(systemNotifications)
      ..addColumns([systemNotifications.id.count()])
      ..where(systemNotifications.targetRole.equals(role) & 
              systemNotifications.isRead.equals(false));
    
    final result = await query.getSingle();
    return result.read(systemNotifications.id.count()) ?? 0;
  }
  
  // ============== MÉTODOS PARA HISTORIAL DE EMPLEADOS ==============
  
  /// Crear entrada en historial de empleado
  Future<int> createEmployeeHistoryEntry(EmployeeHistoriesCompanion history) async {
    return await into(employeeHistories).insert(history);
  }
  
  /// Obtener historial de un empleado
  Future<List<EmployeeHistory>> getEmployeeHistory(int employeeId) async {
    return await (select(employeeHistories)
      ..where((tbl) => tbl.employeeId.equals(employeeId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
      .get();
  }

  // Migración de v1 a v2: Actualizar sucursales
  Future<void> _migrateTo2() async {
    try {
      // Limpiar tiendas existentes
      await delete(stores).go();
      await delete(warehouses).go();
      
      // Insertar las nuevas sucursales
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Norte',
        code: 'SN001',
        address: 'Av. Los Olivos 123, Independencia',
        city: 'Lima Norte',
        phone: const Value('+51 999 888 001'),
        isActive: const Value(true),
      ));
      
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Sur',
        code: 'SS001',
        address: 'Av. Villa El Salvador 456, Villa María del Triunfo',
        city: 'Lima Sur',
        phone: const Value('+51 999 888 002'),
        isActive: const Value(true),
      ));
      
      await into(stores).insert(StoresCompanion.insert(
        companyId: 1,
        name: 'Sucursal Centro',
        code: 'SC001',
        address: 'Jr. de la Unión 789, Cercado de Lima',
        city: 'Lima Centro',
        phone: const Value('+51 999 888 003'),
        isActive: const Value(true),
      ));
      
      // Insertar almacenes por sucursal
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Norte',
        code: 'AN001',
        address: 'Av. Los Olivos 123, Independencia',
        warehouseType: 'sucursal',
        storeId: const Value(1),
        isActive: const Value(true),
      ));
      
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Sur',
        code: 'AS001',
        address: 'Av. Villa El Salvador 456, Villa María del Triunfo',
        warehouseType: 'sucursal',
        storeId: const Value(2),
        isActive: const Value(true),
      ));
      
      await into(warehouses).insert(WarehousesCompanion.insert(
        companyId: 1,
        name: 'Almacén Centro',
        code: 'AC001',
        address: 'Jr. de la Unión 789, Cercado de Lima',
        warehouseType: 'sucursal',
        storeId: const Value(3),
        isActive: const Value(true),
      ));
      
      print(' Migración a v2 completada: Sucursales actualizadas');
    } catch (e) {
      print(' Error en migración a v2: $e');
      rethrow;
    }
  }

  // Migración de v2 a v3: Crear tablas de notificaciones
  Future<void> _migrateTo3(Migrator m) async {
    try {
      print(' Iniciando migración a v3: Creando tablas de notificaciones');
      
      // Crear las nuevas tablas de notificaciones
      await m.createTable(employeeRegistrationRequests);
      await m.createTable(systemNotifications);
      await m.createTable(employeeHistories);
      
      print(' Migración a v3 completada: Tablas de notificaciones creadas');
    } catch (e) {
      print(' Error en migración a v3: $e');
      rethrow;
    }
  }

  // Método para cerrar la conexión
  @override
  Future<void> close() async {
    await super.close();
  }
}

// Configuración de la conexión a la base de datos
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tienda_online.db'));
    
    return NativeDatabase.createInBackground(file);
  });
}