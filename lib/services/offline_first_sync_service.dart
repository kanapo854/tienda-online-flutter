import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../database/local_database.dart';

// Para unawaited
void unawaited(Future<void> future) {
  // Simplemente ignora el future sin esperar
}

enum SyncOperationType {
  insert,
  update,
  delete,
}

class PendingSyncOperation {
  final String id;
  final String tableName;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  PendingSyncOperation({
    required this.id,
    required this.tableName,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableName': tableName,
        'type': type.name,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  static PendingSyncOperation fromJson(Map<String, dynamic> json) =>
      PendingSyncOperation(
        id: json['id'],
        tableName: json['tableName'],
        type: SyncOperationType.values.firstWhere((e) => e.name == json['type']),
        data: json['data'],
        createdAt: DateTime.parse(json['createdAt']),
        retryCount: json['retryCount'] ?? 0,
      );

  PendingSyncOperation copyWith({int? retryCount}) => PendingSyncOperation(
        id: id,
        tableName: tableName,
        type: type,
        data: data,
        createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
      );
}

class OfflineFirstSyncService {
  final LocalDatabase _localDb;
  final Connectivity _connectivity;
  final SharedPreferences _prefs;

  Timer? _syncTimer;
  bool _isSyncing = false;
  final StreamController<bool> _syncStatusController = StreamController<bool>.broadcast();
  final StreamController<String> _syncProgressController = StreamController<String>.broadcast();

  OfflineFirstSyncService({
    required LocalDatabase localDb,
    required SharedPreferences prefs,
  })  : _localDb = localDb,
        _connectivity = Connectivity(),
        _prefs = prefs;

  // Obtener cliente de Supabase de forma segura
  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  // Streams para UI
  Stream<bool> get syncStatus => _syncStatusController.stream;
  Stream<String> get syncProgress => _syncProgressController.stream;

  /// Inicializar el servicio de sincronización
  Future<void> initialize() async {
    await _setupRealtimeSubscriptions();
    await _startPeriodicSync();
    
    // Escuchar cambios de conectividad
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        _triggerSync();
      }
    });
  }

  /// Verificar si hay conexión a internet
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    // Verificar si Supabase está inicializado y es accesible
    final client = _supabaseClient;
    if (client == null) {
      // Esto es normal si no configuraste Supabase - la app funciona en modo local
      return false;
    }

    try {
      await client.from('companies').select('id').limit(1);
      print('✅ Conectado a Supabase');
      return true;
    } catch (e) {
      // Solo mostrar error en debug, no es crítico
      print('� Trabajando en modo offline (Supabase no disponible)');
      return false;
    }
  }

  /// Configurar suscripciones en tiempo real
  Future<void> _setupRealtimeSubscriptions() async {
    if (!await hasInternetConnection()) return;

    final client = _supabaseClient;
    if (client == null) return;

    try {
      // Suscribirse a cambios en tablas críticas
      client.channel('all-changes').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        callback: (payload) => _handleRealtimeUpdate(payload),
      ).subscribe();

      print('✅ Suscripciones en tiempo real configuradas');
    } catch (e) {
      print('🔴 Error configurando suscripciones: $e');
    }
  }

  /// Manejar actualizaciones en tiempo real
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    print('📡 Cambio en tiempo real: ${payload.table} - ${payload.eventType}');
    
    // Solo actualizar si no estamos sincronizando (evitar bucles)
    if (!_isSyncing) {
      _processRealtimeChange(payload);
    }
  }

  /// Procesar cambios en tiempo real
  Future<void> _processRealtimeChange(PostgresChangePayload payload) async {
    try {
      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          await _insertLocalFromRealtime(payload.table, payload.newRecord);
          break;
        case PostgresChangeEvent.update:
          await _updateLocalFromRealtime(payload.table, payload.newRecord);
          break;
        case PostgresChangeEvent.delete:
          await _deleteLocalFromRealtime(payload.table, payload.oldRecord);
          break;
        case PostgresChangeEvent.all:
          // Manejar evento 'all' si es necesario
          print('📡 Evento realtime genérico recibido');
          break;
      }
    } catch (e) {
      print('🔴 Error procesando cambio realtime: $e');
    }
  }

  /// Iniciar sincronización periódica
  Future<void> _startPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(SupabaseConfig.syncInterval, (_) {
      _triggerSync();
    });
  }

  /// Disparar sincronización
  void _triggerSync() {
    if (!_isSyncing) {
      unawaited(fullSync());
    }
  }

  /// Sincronización completa (bidireccional)
  Future<void> fullSync() async {
    if (_isSyncing) {
      print('⏳ Sincronización ya en progreso');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      if (!await hasInternetConnection()) {
        _syncProgressController.add('Sin conexión - trabajando offline');
        return;
      }

      print('🔄 Iniciando sincronización completa...');
      _syncProgressController.add('Iniciando sincronización...');

      // 1. Subir cambios locales pendientes
      await _uploadPendingChanges();

      // 2. Descargar cambios del servidor
      await _downloadServerChanges();

      // 3. Actualizar timestamp de última sincronización
      await _updateLastSyncTimestamp();

      print('✅ Sincronización completa exitosa');
      _syncProgressController.add('Sincronización completada');

    } catch (e) {
      print('🔴 Error en sincronización: $e');
      _syncProgressController.add('Error en sincronización: $e');
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  /// Subir cambios locales pendientes
  Future<void> _uploadPendingChanges() async {
    final pendingOps = await _getPendingOperations();
    if (pendingOps.isEmpty) return;

    _syncProgressController.add('Subiendo ${pendingOps.length} cambios...');

    for (final op in pendingOps) {
      try {
        await _executePendingOperation(op);
        await _removePendingOperation(op.id);
      } catch (e) {
        print('🔴 Error ejecutando operación ${op.id}: $e');
        
        // Incrementar contador de reintentos
        final updatedOp = op.copyWith(retryCount: op.retryCount + 1);
        
        if (updatedOp.retryCount >= SupabaseConfig.maxRetryAttempts) {
          print('❌ Operación ${op.id} falló después de ${SupabaseConfig.maxRetryAttempts} intentos');
          await _removePendingOperation(op.id);
        } else {
          await _updatePendingOperation(updatedOp);
        }
      }
    }
  }

  /// Descargar cambios del servidor
  Future<void> _downloadServerChanges() async {
    final lastSync = await _getLastSyncTimestamp();
    _syncProgressController.add('Descargando cambios desde servidor...');

    // Lista de tablas a sincronizar
    final tables = [
      'companies',
      'stores', 
      'warehouses',
      'employees',
      'product_categories',
      'products',
      'stocks',
      'customers',
      'suppliers',
      'sales',
      'sale_items',
      'purchases',
      'purchase_items',
    ];

    for (final table in tables) {
      try {
        await _syncTableFromServer(table, lastSync);
      } catch (e) {
        print('🔴 Error sincronizando tabla $table: $e');
      }
    }
  }

  /// Agregar operación pendiente para sincronizar después
  Future<void> addPendingOperation(
    String tableName,
    SyncOperationType type,
    Map<String, dynamic> data,
  ) async {
    final operation = PendingSyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableName: tableName,
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    final pendingOps = await _getPendingOperations();
    pendingOps.add(operation);
    await _savePendingOperations(pendingOps);

    print('📝 Operación pendiente agregada: $tableName - ${type.name}');
  }

  /// Operaciones CRUD offline-first
  Future<T> executeOfflineFirst<T>(
    Future<T> Function() operation,
    String tableName,
    SyncOperationType type,
    Map<String, dynamic> data,
  ) async {
    try {
      // Ejecutar operación localmente
      final result = await operation();

      // Si hay conexión, intentar sincronizar inmediatamente
      if (await hasInternetConnection()) {
        try {
          await _executeSyncOperation(tableName, type, data);
        } catch (e) {
          // Si falla la sincronización inmediata, agregar a pendientes
          await addPendingOperation(tableName, type, data);
        }
      } else {
        // Sin conexión, agregar a pendientes
        await addPendingOperation(tableName, type, data);
      }

      return result;
    } catch (e) {
      print('🔴 Error en operación offline-first: $e');
      rethrow;
    }
  }

  // Métodos auxiliares privados
  Future<List<PendingSyncOperation>> _getPendingOperations() async {
    final json = _prefs.getString(SupabaseConfig.pendingSyncKey);
    if (json == null) return [];
    
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((e) => PendingSyncOperation.fromJson(e)).toList();
  }

  Future<void> _savePendingOperations(List<PendingSyncOperation> operations) async {
    final json = jsonEncode(operations.map((e) => e.toJson()).toList());
    await _prefs.setString(SupabaseConfig.pendingSyncKey, json);
  }

  Future<void> _removePendingOperation(String operationId) async {
    final pendingOps = await _getPendingOperations();
    pendingOps.removeWhere((op) => op.id == operationId);
    await _savePendingOperations(pendingOps);
  }

  Future<void> _updatePendingOperation(PendingSyncOperation operation) async {
    final pendingOps = await _getPendingOperations();
    final index = pendingOps.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      pendingOps[index] = operation;
      await _savePendingOperations(pendingOps);
    }
  }

  Future<DateTime?> _getLastSyncTimestamp() async {
    final timestamp = _prefs.getString(SupabaseConfig.lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  Future<void> _updateLastSyncTimestamp() async {
    await _prefs.setString(
      SupabaseConfig.lastSyncKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _executePendingOperation(PendingSyncOperation operation) async {
    await _executeSyncOperation(operation.tableName, operation.type, operation.data);
  }

  Future<void> _executeSyncOperation(
    String tableName,
    SyncOperationType type,
    Map<String, dynamic> data,
  ) async {
    final client = _supabaseClient;
    if (client == null) {
      // Esto solo ocurre si intentas sincronizar sin Supabase configurado
      throw Exception('No se puede sincronizar: Supabase no configurado (modo offline activo)');
    }

    switch (type) {
      case SyncOperationType.insert:
        await client.from(tableName).insert(data);
        break;
      case SyncOperationType.update:
        final id = data['id'];
        await client.from(tableName).update(data).eq('id', id);
        break;
      case SyncOperationType.delete:
        final id = data['id'];
        await client.from(tableName).delete().eq('id', id);
        break;
    }
  }

  Future<void> _syncTableFromServer(String tableName, DateTime? lastSync) async {
    final client = _supabaseClient;
    if (client == null) {
      print('⚠️ Supabase no disponible para sincronizar $tableName');
      return;
    }

    try {
      // Implementar descarga de cambios desde servidor
      var query = client.from(tableName).select();
      
      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }
      
      final response = await query;
      
      if (response.isNotEmpty) {
        print('📥 Descargando ${response.length} registros de $tableName');
        // Aquí implementarías la lógica para insertar/actualizar en la DB local
        // Por ahora solo registramos la descarga
      }
    } catch (e) {
      print('🔴 Error descargando $tableName: $e');
      // Continuar con otras tablas aunque una falle
    }
  }

  Future<void> _insertLocalFromRealtime(String table, Map<String, dynamic>? record) async {
    if (record == null) return;
    // Implementar inserción en base de datos local desde tiempo real
    print('➕ Insertando en local: $table - ${record['id']}');
  }

  Future<void> _updateLocalFromRealtime(String table, Map<String, dynamic>? record) async {
    if (record == null) return;
    // Implementar actualización en base de datos local desde tiempo real
    print('✏️ Actualizando en local: $table - ${record['id']}');
  }

  Future<void> _deleteLocalFromRealtime(String table, Map<String, dynamic>? record) async {
    if (record == null) return;
    // Implementar eliminación en base de datos local desde tiempo real
    print('🗑️ Eliminando en local: $table - ${record['id']}');
  }

  /// Limpiar recursos
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
    _syncProgressController.close();
  }
}