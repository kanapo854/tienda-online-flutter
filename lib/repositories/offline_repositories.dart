import 'dart:async';
import 'package:drift/drift.dart';
import '../database/local_database.dart';
import '../services/offline_first_sync_service.dart';

/// Repositorio de Productos con operaciones offline-first
class ProductRepository {
  final LocalDatabase localDb;
  final OfflineFirstSyncService syncService;

  ProductRepository({
    required this.localDb,
    required this.syncService,
  });

  /// Obtener todos los productos
  Future<List<Product>> getAllProducts() async {
    return await localDb.select(localDb.products).get();
  }

  /// Obtener producto por ID
  Future<Product?> getProductById(int id) async {
    return await (localDb.select(localDb.products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  /// Stream de todos los productos
  Stream<List<Product>> watchAllProducts() {
    return localDb.select(localDb.products).watch();
  }

  /// Stream de producto específico
  Stream<Product?> watchProductById(int id) {
    return (localDb.select(localDb.products)..where((p) => p.id.equals(id))).watchSingleOrNull();
  }

  /// Buscar productos por categoría
  Future<List<Product>> getProductsByCategory(int categoryId) async {
    return await (localDb.select(localDb.products)
          ..where((p) => p.categoryId.equals(categoryId)))
        .get();
  }

  /// Stream de productos por categoría
  Stream<List<Product>> watchProductsByCategory(int categoryId) {
    return (localDb.select(localDb.products)
          ..where((p) => p.categoryId.equals(categoryId)))
        .watch();
  }

  /// Crear producto (offline-first)
  Future<Product> createProduct({
    required String name,
    required String sku,
    required double salePrice,
    required double purchasePrice,
    required int categoryId,
    String? description,
    String? brand,
    String? unit = 'unidad',
  }) async {
    return await syncService.executeOfflineFirst<Product>(
      () async {
        final companion = ProductsCompanion.insert(
          name: name,
          sku: sku,
          salePrice: salePrice,
          purchasePrice: purchasePrice,
          categoryId: categoryId,
          description: Value(description),
          brand: Value(brand),
          unit: unit ?? 'unidad',
        );
        return await localDb.into(localDb.products).insertReturning(companion);
      },
      'products',
      SyncOperationType.insert,
      {
        'name': name,
        'sku': sku,
        'sale_price': salePrice,
        'purchase_price': purchasePrice,
        'category_id': categoryId,
        'description': description,
        'brand': brand,
        'unit': unit,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Actualizar producto (offline-first)
  Future<Product> updateProduct({
    required Product product,
    String? name,
    String? sku,
    double? salePrice,
    double? purchasePrice,
    int? categoryId,
    String? description,
    String? brand,
    String? unit,
  }) async {
    return await syncService.executeOfflineFirst<Product>(
      () async {
        final companion = ProductsCompanion(
          id: Value(product.id),
          name: Value(name ?? product.name),
          sku: Value(sku ?? product.sku),
          salePrice: Value(salePrice ?? product.salePrice),
          purchasePrice: Value(purchasePrice ?? product.purchasePrice),
          categoryId: Value(categoryId ?? product.categoryId),
          description: Value(description ?? product.description),
          brand: Value(brand ?? product.brand),
          unit: Value(unit ?? product.unit),
          updatedAt: Value(DateTime.now()),
        );
        await localDb.update(localDb.products).replace(companion);
        return product.copyWith(
          name: name ?? product.name,
          sku: sku ?? product.sku,
          salePrice: salePrice ?? product.salePrice,
          purchasePrice: purchasePrice ?? product.purchasePrice,
          categoryId: categoryId ?? product.categoryId,
          description: Value(description ?? product.description),
          brand: Value(brand ?? product.brand),
          unit: unit ?? product.unit,
          updatedAt: DateTime.now(),
        );
      },
      'products',
      SyncOperationType.update,
      {
        'id': product.id,
        'name': name ?? product.name,
        'sku': sku ?? product.sku,
        'sale_price': salePrice ?? product.salePrice,
        'purchase_price': purchasePrice ?? product.purchasePrice,
        'category_id': categoryId ?? product.categoryId,
        'description': description ?? product.description,
        'brand': brand ?? product.brand,
        'unit': unit ?? product.unit,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Eliminar producto (offline-first)
  Future<void> deleteProduct(int productId) async {
    return await syncService.executeOfflineFirst<void>(
      () async {
        await (localDb.delete(localDb.products)..where((p) => p.id.equals(productId))).go();
      },
      'products',
      SyncOperationType.delete,
      {'id': productId},
    );
  }
}

/// Repositorio de Stock con operaciones offline-first
class StockRepository {
  final LocalDatabase localDb;
  final OfflineFirstSyncService syncService;

  StockRepository({
    required this.localDb,
    required this.syncService,
  });

  /// Obtener todo el stock
  Future<List<Stock>> getAllStock() async {
    return await localDb.select(localDb.stocks).get();
  }

  /// Stream de todo el stock
  Stream<List<Stock>> watchAllStock() {
    return localDb.select(localDb.stocks).watch();
  }

  /// Obtener stock por producto
  Future<Stock?> getStockByProduct(int productId, int warehouseId) async {
    return await (localDb.select(localDb.stocks)
          ..where((s) => s.productId.equals(productId) & s.warehouseId.equals(warehouseId)))
        .getSingleOrNull();
  }

  /// Stream de stock por producto
  Stream<Stock?> watchStockByProduct(int productId, int warehouseId) {
    return (localDb.select(localDb.stocks)
          ..where((s) => s.productId.equals(productId) & s.warehouseId.equals(warehouseId)))
        .watchSingleOrNull();
  }

  /// Actualizar stock (offline-first)
  Future<Stock> updateStock({
    required int productId,
    required int warehouseId,
    required double newQuantity,
  }) async {
    final existingStock = await getStockByProduct(productId, warehouseId);
    
    return await syncService.executeOfflineFirst<Stock>(
      () async {
        if (existingStock != null) {
          // Actualizar stock existente
          final companion = StocksCompanion(
            productId: Value(productId),
            warehouseId: Value(warehouseId),
            quantity: Value(newQuantity),
            updatedAt: Value(DateTime.now()),
          );
          await localDb.update(localDb.stocks).replace(companion);
          return existingStock.copyWith(
            quantity: newQuantity,
            updatedAt: DateTime.now(),
          );
        } else {
          // Crear nuevo stock
          final companion = StocksCompanion.insert(
            productId: productId,
            warehouseId: warehouseId,
            quantity: Value(newQuantity),
          );
          return await localDb.into(localDb.stocks).insertReturning(companion);
        }
      },
      'stocks',
      existingStock != null ? SyncOperationType.update : SyncOperationType.insert,
      {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Reducir stock (para ventas)
  Future<bool> reduceStock(int productId, int warehouseId, double quantity) async {
    final stock = await getStockByProduct(productId, warehouseId);
    
    if (stock == null || stock.quantity < quantity) {
      return false; // Stock insuficiente
    }

    await updateStock(
      productId: productId,
      warehouseId: warehouseId,
      newQuantity: stock.quantity - quantity,
    );

    return true;
  }

  /// Aumentar stock (para compras/reposición)
  Future<Stock> addStock(int productId, int warehouseId, double quantity) async {
    final stock = await getStockByProduct(productId, warehouseId);
    final newQuantity = (stock?.quantity ?? 0.0) + quantity;

    return await updateStock(
      productId: productId,
      warehouseId: warehouseId,
      newQuantity: newQuantity,
    );
  }

  /// Obtener productos con stock disponible
  Future<List<ProductWithStock>> getProductsWithStock() async {
    final query = localDb.select(localDb.products).join([
      leftOuterJoin(localDb.stocks, localDb.stocks.productId.equalsExp(localDb.products.id))
    ]);

    final rows = await query.get();
    
    return rows.map((row) {
      final product = row.readTable(localDb.products);
      final stock = row.readTableOrNull(localDb.stocks);
      
      return ProductWithStock(
        product: product,
        totalStock: stock?.quantity ?? 0.0,
      );
    }).toList();
  }
}

/// Clase auxiliar para productos con stock
class ProductWithStock {
  final Product product;
  final double totalStock;

  ProductWithStock({
    required this.product,
    required this.totalStock,
  });

  bool get isAvailable => totalStock > 0;
}

/// Repositorio de Ventas con operaciones offline-first
class SaleRepository {
  final LocalDatabase localDb;
  final OfflineFirstSyncService syncService;

  SaleRepository({
    required this.localDb,
    required this.syncService,
  });

  /// Obtener todas las ventas
  Future<List<Sale>> getAllSales() async {
    return await localDb.select(localDb.sales).get();
  }

  /// Obtener venta por ID
  Future<Sale?> getSaleById(int id) async {
    return await (localDb.select(localDb.sales)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Stream de todas las ventas
  Stream<List<Sale>> watchAllSales() {
    return localDb.select(localDb.sales).watch();
  }

  /// Stream de venta específica
  Stream<Sale?> watchSaleById(int id) {
    return (localDb.select(localDb.sales)..where((s) => s.id.equals(id))).watchSingleOrNull();
  }

  /// Crear venta (offline-first)
  Future<Sale> createSale({
    required int customerId,
    required int employeeId,
    required int storeId,
    required String saleNumber,
    required double subtotal,
    required double totalAmount,
    String saleStatus = 'pending',
    String paymentMethod = 'cash',
    String paymentStatus = 'pending',
    double taxAmount = 0.0,
    double discountAmount = 0.0,
  }) async {
    return await syncService.executeOfflineFirst<Sale>(
      () async {
        final companion = SalesCompanion.insert(
          customerId: customerId,
          employeeId: employeeId,
          storeId: storeId,
          saleNumber: saleNumber,
          saleDate: DateTime.now(),
          subtotal: subtotal,
          taxAmount: Value(taxAmount),
          discountAmount: Value(discountAmount),
          totalAmount: totalAmount,
          saleStatus: saleStatus,
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
        );
        return await localDb.into(localDb.sales).insertReturning(companion);
      },
      'sales',
      SyncOperationType.insert,
      {
        'customer_id': customerId,
        'employee_id': employeeId,
        'store_id': storeId,
        'sale_number': saleNumber,
        'sale_date': DateTime.now().toIso8601String(),
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'sale_status': saleStatus,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Eliminar venta (offline-first)
  Future<void> deleteSale(int saleId) async {
    return await syncService.executeOfflineFirst<void>(
      () async {
        await (localDb.delete(localDb.sales)..where((s) => s.id.equals(saleId))).go();
      },
      'sales',
      SyncOperationType.delete,
      {'id': saleId},
    );
  }
}

/// Repositorio de Categorías con operaciones offline-first
class CategoryRepository {
  final LocalDatabase localDb;
  final OfflineFirstSyncService syncService;

  CategoryRepository({
    required this.localDb,
    required this.syncService,
  });

  /// Obtener todas las categorías
  Future<List<ProductCategory>> getAllCategories() async {
    return await localDb.select(localDb.productCategories).get();
  }

  /// Obtener categoría por ID
  Future<ProductCategory?> getCategoryById(int id) async {
    return await (localDb.select(localDb.productCategories)..where((c) => c.id.equals(id))).getSingleOrNull();
  }

  /// Stream de todas las categorías
  Stream<List<ProductCategory>> watchAllCategories() {
    return localDb.select(localDb.productCategories).watch();
  }

  /// Crear categoría (offline-first)
  Future<ProductCategory> createCategory({
    required String name,
    required String code,
    String? description,
    int? parentId,
  }) async {
    return await syncService.executeOfflineFirst<ProductCategory>(
      () async {
        final companion = ProductCategoriesCompanion.insert(
          name: name,
          code: code,
          description: Value(description),
          parentId: Value(parentId),
        );
        return await localDb.into(localDb.productCategories).insertReturning(companion);
      },
      'product_categories',
      SyncOperationType.insert,
      {
        'name': name,
        'code': code,
        'description': description,
        'parent_id': parentId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }
}