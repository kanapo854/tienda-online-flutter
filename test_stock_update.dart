import 'lib/database/local_database.dart';
import 'package:drift/drift.dart' as drift;

void main() async {
  print('🧪 PRUEBA DE ACTUALIZACIÓN DE STOCK');
  print('=' * 50);

  final database = LocalDatabase();

  try {
    // 1. Verificar productos y almacenes existentes
    print('\n1️⃣ Verificando productos y almacenes...');
    final products = await database.getAllProducts();
    final warehouses = await database.getAllWarehouses();
    final stores = await database.getAllStores();
    final stocks = await database.getAllStocks();

    print('   Productos: ${products.length}');
    print('   Almacenes: ${warehouses.length}');
    print('   Sucursales: ${stores.length}');
    print('   Registros de stock: ${stocks.length}');

    if (products.isEmpty || warehouses.isEmpty || stores.isEmpty) {
      print('❌ No hay suficientes datos para la prueba');
      return;
    }

    // 2. Seleccionar producto y almacén para prueba
    final testProduct = products.first;
    final testStore = stores.first;
    final testWarehouse = warehouses.where((w) => w.storeId == testStore.id).firstOrNull;

    if (testWarehouse == null) {
      print('❌ No se encontró almacén para la sucursal ${testStore.name}');
      return;
    }

    print('\n2️⃣ Datos de prueba seleccionados:');
    print('   Producto: ${testProduct.name} (ID: ${testProduct.id})');
    print('   Sucursal: ${testStore.name} (ID: ${testStore.id})');
    print('   Almacén: ${testWarehouse.name} (ID: ${testWarehouse.id})');

    // 3. Verificar stock actual
    print('\n3️⃣ Stock actual:');
    final currentStock = await (database.select(database.stocks)
      ..where((s) => s.productId.equals(testProduct.id) & s.warehouseId.equals(testWarehouse.id))).getSingleOrNull();

    if (currentStock != null) {
      print('   Stock existente: ${currentStock.quantity}');
    } else {
      print('   No existe registro de stock');
    }

    // 4. Actualizar stock usando insertOnConflictUpdate
    print('\n4️⃣ Actualizando stock a 100 unidades...');
    const newStock = 100.0;

    await database.into(database.stocks).insertOnConflictUpdate(
      StocksCompanion(
        productId: drift.Value(testProduct.id),
        warehouseId: drift.Value(testWarehouse.id),
        quantity: const drift.Value(newStock),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    print('✅ Stock actualizado');

    // 5. Verificar que el cambio se aplicó
    print('\n5️⃣ Verificando cambios...');
    final updatedStock = await (database.select(database.stocks)
      ..where((s) => s.productId.equals(testProduct.id) & s.warehouseId.equals(testWarehouse.id))).getSingle();

    print('   Nuevo stock: ${updatedStock.quantity}');
    print('   Última actualización: ${updatedStock.updatedAt}');

    if (updatedStock.quantity == newStock) {
      print('✅ ÉXITO: El stock se actualizó correctamente');
    } else {
      print('❌ ERROR: El stock no se actualizó (esperado: $newStock, actual: ${updatedStock.quantity})');
    }

    // 6. Probar actualización a valor diferente
    print('\n6️⃣ Probando segunda actualización a 75 unidades...');
    const secondStock = 75.0;

    await database.into(database.stocks).insertOnConflictUpdate(
      StocksCompanion(
        productId: drift.Value(testProduct.id),
        warehouseId: drift.Value(testWarehouse.id),
        quantity: const drift.Value(secondStock),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final finalStock = await (database.select(database.stocks)
      ..where((s) => s.productId.equals(testProduct.id) & s.warehouseId.equals(testWarehouse.id))).getSingle();

    print('   Stock final: ${finalStock.quantity}');

    if (finalStock.quantity == secondStock) {
      print('✅ ÉXITO: Segunda actualización exitosa');
    } else {
      print('❌ ERROR: Segunda actualización falló');
    }

    print('\n🎉 PRUEBA COMPLETADA');

  } catch (e, stackTrace) {
    print('❌ Error durante la prueba: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await database.close();
  }
}