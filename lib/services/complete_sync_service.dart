import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/local_database.dart';
import '../config/supabase_config.dart';

class CompleteSyncService {
  final LocalDatabase _localDb = LocalDatabase();
  final Connectivity _connectivity = Connectivity();
  SupabaseClient? get _supabase => SupabaseConfig.isConfigured ? SupabaseConfig.client : null;

  // ============================================
  // VERIFICACIÓN DE CONECTIVIDAD
  // ============================================

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ============================================
  // SINCRONIZACIÓN PRINCIPAL
  // ============================================

  /// Sincronización completa del sistema
  Future<Map<String, dynamic>> syncAll() async {
    if (_supabase == null) {
      return {
        'success': false,
        'error': 'Supabase no configurado',
        'offline_mode': true,
      };
    }

    if (!await hasInternetConnection()) {
      return {
        'success': false,
        'error': 'Sin conexión a internet',
        'offline_mode': true,
      };
    }

    try {
      final results = <String, dynamic>{
        'success': true,
        'synced_tables': <String>[],
        'errors': <String, String>{},
        'total_uploaded': 0,
        'total_downloaded': 0,
      };

      // 1. SINCRONIZAR DATOS MAESTROS (Descarga primero)
      print('📥 Descargando datos maestros...');
      await _downloadMasterData(results);

      // 2. SUBIR CAMBIOS LOCALES
      print('📤 Subiendo cambios locales...');
      await _uploadLocalChanges(results);

      // 3. DESCARGAR NUEVAS TRANSACCIONES
      print('📥 Descargando nuevas transacciones...');
      await _downloadTransactions(results);

      print('✅ Sincronización completada');
      return results;

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'partial_sync': true,
      };
    }
  }

  // ============================================
  // DESCARGA DE DATOS MAESTROS
  // ============================================

  Future<void> _downloadMasterData(Map<String, dynamic> results) async {
    // Sincronizar en orden de dependencias
    await _syncTableFromSupabase('companies', results);
    await _syncTableFromSupabase('stores', results);
    await _syncTableFromSupabase('warehouses', results);
    await _syncTableFromSupabase('product_categories', results);
    await _syncTableFromSupabase('products', results);
    await _syncTableFromSupabase('employees', results);
    await _syncTableFromSupabase('customers', results);
    await _syncTableFromSupabase('suppliers', results);
  }

  // ============================================
  // SUBIDA DE CAMBIOS LOCALES
  // ============================================

  Future<void> _uploadLocalChanges(Map<String, dynamic> results) async {
    // Subir datos maestros primero
    await _uploadTableToSupabase('companies', results);
    await _uploadTableToSupabase('stores', results);
    await _uploadTableToSupabase('warehouses', results);
    await _uploadTableToSupabase('employees', results);
    await _uploadTableToSupabase('products', results);
    await _uploadTableToSupabase('customers', results);
    await _uploadTableToSupabase('suppliers', results);

    // Luego transacciones
    await _uploadTableToSupabase('sales', results);
    await _uploadTableToSupabase('purchases', results);
    await _uploadTableToSupabase('transfers', results);
    await _uploadTableToSupabase('inventory_movements', results);
  }

  // ============================================
  // DESCARGA DE TRANSACCIONES
  // ============================================

  Future<void> _downloadTransactions(Map<String, dynamic> results) async {
    await _syncTableFromSupabase('sales', results);
    await _syncTableFromSupabase('sale_items', results);
    await _syncTableFromSupabase('purchases', results);
    await _syncTableFromSupabase('purchase_items', results);
    await _syncTableFromSupabase('transfers', results);
    await _syncTableFromSupabase('transfer_items', results);
    await _syncTableFromSupabase('inventory_movements', results);
    await _syncTableFromSupabase('stock_alerts', results);
  }

  // ============================================
  // MÉTODOS AUXILIARES DE SINCRONIZACIÓN
  // ============================================

  /// Descargar tabla desde Supabase a local
  Future<void> _syncTableFromSupabase(String tableName, Map<String, dynamic> results) async {
    try {
      // Obtener timestamp de última sincronización
      final lastSync = await _localDb.getConfigValue('last_sync_$tableName');
      final DateTime? lastSyncTime = lastSync != null ? DateTime.tryParse(lastSync) : null;

      // Construir query con filtro de fecha si existe
      var query = _supabase!.from(tableName).select('*');
      
      if (lastSyncTime != null) {
        query = query.gte('updated_at', lastSyncTime.toIso8601String());
      }

      final data = await query;
      
      if (data.isNotEmpty) {
        // Aquí implementarías la inserción específica para cada tabla
        // Por simplicidad, lo mantenemos genérico
        await _insertDataToLocal(tableName, data);
        
        results['synced_tables'].add(tableName);
        results['total_downloaded'] += data.length;
        
        // Actualizar timestamp de sincronización
        await _localDb.setConfigValue(
          'last_sync_$tableName',
          DateTime.now().toIso8601String(),
          'Última sincronización de $tableName',
        );
      }

      print('✅ $tableName sincronizada: ${data.length} registros');

    } catch (e) {
      results['errors'][tableName] = e.toString();
      print('❌ Error sincronizando $tableName: $e');
    }
  }

  /// Subir cambios locales a Supabase
  Future<void> _uploadTableToSupabase(String tableName, Map<String, dynamic> results) async {
    try {
      // Obtener datos que necesitan sincronización
      final localChanges = await _localDb.getItemsNeedingSync(tableName);
      
      if (localChanges.isEmpty) return;

      for (final item in localChanges) {
        try {
          // Limpiar campos que no deben ir a Supabase
          final cleanItem = Map<String, dynamic>.from(item);
          cleanItem.remove('needs_sync');
          cleanItem.remove('last_sync_at');

          // Upsert en Supabase
          await _supabase!.from(tableName).upsert(cleanItem);
          
          // Marcar como sincronizado localmente
          await _markAsSynced(tableName, item['id']);
          
          results['total_uploaded'] += 1;

        } catch (e) {
          print('❌ Error subiendo item ${item['id']} de $tableName: $e');
        }
      }

      print('✅ $tableName subida: ${localChanges.length} registros');

    } catch (e) {
      results['errors']['upload_$tableName'] = e.toString();
      print('❌ Error subiendo $tableName: $e');
    }
  }

  // ============================================
  // UTILIDADES DE BASE DE DATOS
  // ============================================

  /// Insertar datos descargados en base local
  Future<void> _insertDataToLocal(String tableName, List<dynamic> data) async {
    // Implementación específica por tabla
    switch (tableName) {
      case 'companies':
        for (final item in data) {
          await _insertOrUpdateCompany(item);
        }
        break;
      case 'stores':
        for (final item in data) {
          await _insertOrUpdateStore(item);
        }
        break;
      case 'products':
        for (final item in data) {
          await _insertOrUpdateProduct(item);
        }
        break;
      // Agregar más casos según necesidad
      default:
        print('⚠️ Tabla $tableName no tiene implementación específica');
    }
  }

  /// Marcar registro como sincronizado
  Future<void> _markAsSynced(String tableName, int id) async {
    final updateQuery = '''
      UPDATE $tableName 
      SET needs_sync = 0, last_sync_at = ? 
      WHERE id = ?
    ''';
    
    await _localDb.customStatement(updateQuery, [
      DateTime.now().toIso8601String(),
      id,
    ]);
  }

  // ============================================
  // MÉTODOS ESPECÍFICOS POR TABLA
  // ============================================

  Future<void> _insertOrUpdateCompany(Map<String, dynamic> data) async {
    // Implementar lógica específica para companies
    // Por simplicidad, se omite la implementación completa
  }

  Future<void> _insertOrUpdateStore(Map<String, dynamic> data) async {
    // Implementar lógica específica para stores
  }

  Future<void> _insertOrUpdateProduct(Map<String, dynamic> data) async {
    // Implementar lógica específica para products
  }

  // ============================================
  // SINCRONIZACIÓN DE STOCK EN TIEMPO REAL
  // ============================================

  /// Sincronizar stock después de una venta
  Future<void> syncStockAfterSale(int productId, int warehouseId, double quantity) async {
    if (_supabase == null) return;

    try {
      // Actualizar stock en Supabase
      await _supabase!.from('stocks').upsert({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        'last_movement_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Stock sincronizado para producto $productId');
    } catch (e) {
      print('❌ Error sincronizando stock: $e');
    }
  }

  // ============================================
  // SUBSCRIPCIONES EN TIEMPO REAL
  // ============================================

  /// Escuchar cambios en tiempo real (requiere Supabase)
  void listenToRealTimeChanges() {
    if (_supabase == null) return;

    // Escuchar cambios en productos
    _supabase!
        .channel('products_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            print('📡 Cambio en productos: ${payload.eventType}');
            // Aquí podrías actualizar la UI o la base local
          },
        )
        .subscribe();

    // Escuchar cambios en stock
    _supabase!
        .channel('stock_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stocks',
          callback: (payload) {
            print('📡 Cambio en stock: ${payload.eventType}');
            // Actualizar stock local automáticamente
          },
        )
        .subscribe();
  }

  // ============================================
  // UTILIDADES PÚBLICAS
  // ============================================

  /// Forzar sincronización completa
  Future<Map<String, dynamic>> forceFullSync() async {
    print('🔄 Iniciando sincronización forzada...');
    return await syncAll();
  }

  /// Verificar estado de sincronización
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingChanges = <String, int>{};
    
    // Verificar tablas principales
    final tables = [
      'companies', 'stores', 'warehouses', 'employees',
      'products', 'customers', 'suppliers', 'sales',
      'purchases', 'transfers', 'inventory_movements'
    ];

    for (final table in tables) {
      final changes = await _localDb.getItemsNeedingSync(table);
      if (changes.isNotEmpty) {
        pendingChanges[table] = changes.length;
      }
    }

    return {
      'has_internet': await hasInternetConnection(),
      'supabase_configured': SupabaseConfig.isConfigured,
      'pending_changes': pendingChanges,
      'total_pending': pendingChanges.values.fold(0, (a, b) => a + b),
    };
  }
}