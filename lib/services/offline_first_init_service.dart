import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../database/local_database.dart';
import '../services/offline_first_sync_service.dart';
import '../repositories/offline_repositories.dart';

/// Servicio de inicialización para sistema offline-first
class OfflineFirstInitService {
  static OfflineFirstInitService? _instance;
  static OfflineFirstInitService get instance => _instance ??= OfflineFirstInitService._internal();
  
  OfflineFirstInitService._internal();

  // Base de datos local
  LocalDatabase? _localDatabase;
  LocalDatabase get localDatabase {
    if (_localDatabase == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _localDatabase!;
  }

  // Servicio de sincronización
  OfflineFirstSyncService? _syncService;
  OfflineFirstSyncService get syncService {
    if (_syncService == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _syncService!;
  }

  // Repositorios
  ProductRepository? _productRepository;
  ProductRepository get productRepository {
    if (_productRepository == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _productRepository!;
  }

  StockRepository? _stockRepository;
  StockRepository get stockRepository {
    if (_stockRepository == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _stockRepository!;
  }

  SaleRepository? _saleRepository;
  SaleRepository get saleRepository {
    if (_saleRepository == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _saleRepository!;
  }

  CategoryRepository? _categoryRepository;
  CategoryRepository get categoryRepository {
    if (_categoryRepository == null) {
      throw StateError('OfflineFirstInitService no ha sido inicializado. Llama a initialize() primero.');
    }
    return _categoryRepository!;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializar todo el sistema offline-first
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ Sistema offline-first ya inicializado');
      return;
    }

    print('🔄 Inicializando sistema offline-first...');

    try {
      // 1. Inicializar Supabase
      await _initializeSupabase();
      print('✅ Supabase inicializado');

      // 2. Inicializar base de datos local
      await _initializeLocalDatabase();
      print('✅ Base de datos local inicializada');

      // 3. Inicializar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences inicializado');

      // 4. Inicializar servicio de sincronización
      await _initializeSyncService(prefs);
      print('✅ Servicio de sincronización inicializado');

      // 5. Inicializar repositorios
      _initializeRepositories();
      print('✅ Repositorios inicializados');

      // 6. Realizar sincronización inicial si hay conexión
      await _performInitialSync();

      _isInitialized = true;
      print('🎉 Sistema offline-first inicializado exitosamente');

    } catch (e) {
      print('🔴 Error inicializando sistema offline-first: $e');
      rethrow;
    }
  }

  /// Inicializar Supabase
  Future<void> _initializeSupabase() async {
    // Verificar si Supabase ya está inicializado de forma segura
    try {
      // Si podemos acceder a instance.client sin error, ya está inicializado
      final _ = Supabase.instance.client;
      print('ℹ️ Supabase ya estaba inicializado');
      return;
    } catch (e) {
      // Supabase no está inicializado, proceder a inicializar
      print('🔄 Inicializando Supabase...');
    }

    // Solo intentar inicializar si está configurado
    if (!SupabaseConfig.isConfigured) {
      print('📱 Modo Offline: Supabase no configurado (esto es normal)');
      print('💡 La app funciona 100% con base de datos local');
      print('ℹ️  Para activar sincronización cloud: configurar credenciales en supabase_config.dart');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      print('✅ Supabase conectado - sincronización cloud activa');
    } catch (e) {
      print('⚠️ No se pudo conectar a Supabase (verifica internet o credenciales)');
      print('💡 Continuando en modo offline - tus datos están seguros localmente');
      // No lanzar el error, permitir que continúe en modo offline
    }
  }

  /// Inicializar base de datos local
  Future<void> _initializeLocalDatabase() async {
    _localDatabase = LocalDatabase();
    
    // Verificar que la base de datos esté funcionando
    final companies = await _localDatabase!.select(_localDatabase!.companies).get();
    print('📊 Base de datos local tiene ${companies.length} compañías');
  }

  /// Inicializar servicio de sincronización
  Future<void> _initializeSyncService(SharedPreferences prefs) async {
    _syncService = OfflineFirstSyncService(
      localDb: _localDatabase!,
      prefs: prefs,
    );

    await _syncService!.initialize();
  }

  /// Inicializar repositorios
  void _initializeRepositories() {
    _productRepository = ProductRepository(
      localDb: _localDatabase!,
      syncService: _syncService!,
    );

    _stockRepository = StockRepository(
      localDb: _localDatabase!,
      syncService: _syncService!,
    );

    _saleRepository = SaleRepository(
      localDb: _localDatabase!,
      syncService: _syncService!,
    );

    _categoryRepository = CategoryRepository(
      localDb: _localDatabase!,
      syncService: _syncService!,
    );
  }

  /// Realizar sincronización inicial
  Future<void> _performInitialSync() async {
    try {
      if (await _syncService!.hasInternetConnection()) {
        print('🌐 Conexión detectada, iniciando sincronización inicial...');
        await _syncService!.fullSync();
      } else {
        print('📱 Sin conexión, trabajando en modo offline');
      }
    } catch (e) {
      print('⚠️ Error en sincronización inicial: $e');
      // No es crítico, continuar en modo offline
    }
  }

  /// Obtener estado del sistema
  SystemStatus getSystemStatus() {
    return SystemStatus(
      isInitialized: _isInitialized,
      hasLocalDatabase: _localDatabase != null,
      hasSyncService: _syncService != null,
      hasRepositories: _productRepository != null &&
          _stockRepository != null &&
          _saleRepository != null &&
          _categoryRepository != null,
    );
  }

  /// Realizar sincronización manual
  Future<void> manualSync() async {
    if (!_isInitialized) {
      throw StateError('Sistema no inicializado');
    }

    await _syncService!.fullSync();
  }

  /// Verificar estado de conectividad
  Future<bool> checkConnectivity() async {
    if (!_isInitialized) return false;
    return await _syncService!.hasInternetConnection();
  }

  /// Stream del estado de sincronización
  Stream<bool> get syncStatus {
    if (!_isInitialized) {
      return Stream.value(false);
    }
    return _syncService!.syncStatus;
  }

  /// Stream del progreso de sincronización
  Stream<String> get syncProgress {
    if (!_isInitialized) {
      return Stream.value('Sistema no inicializado');
    }
    return _syncService!.syncProgress;
  }

  /// Limpiar y reinicializar sistema
  Future<void> reset() async {
    if (_syncService != null) {
      _syncService!.dispose();
    }

    _localDatabase = null;
    _syncService = null;
    _productRepository = null;
    _stockRepository = null;
    _saleRepository = null;
    _categoryRepository = null;
    _isInitialized = false;

    print('🔄 Sistema offline-first reiniciado');
  }

  /// Liberar recursos
  void dispose() {
    _syncService?.dispose();
    // LocalDatabase se cierra automáticamente con Drift
  }
}

/// Estado del sistema offline-first
class SystemStatus {
  final bool isInitialized;
  final bool hasLocalDatabase;
  final bool hasSyncService;
  final bool hasRepositories;

  SystemStatus({
    required this.isInitialized,
    required this.hasLocalDatabase,
    required this.hasSyncService,
    required this.hasRepositories,
  });

  bool get isHealthy => isInitialized && hasLocalDatabase && hasSyncService && hasRepositories;

  String get statusMessage {
    if (isHealthy) return 'Sistema funcionando correctamente';
    if (!isInitialized) return 'Sistema no inicializado';
    if (!hasLocalDatabase) return 'Error en base de datos local';
    if (!hasSyncService) return 'Error en servicio de sincronización';
    if (!hasRepositories) return 'Error en repositorios';
    return 'Estado desconocido';
  }
}

/// Widget helper para inicialización offline-first
/// Este widget puede usarse en main.dart para inicializar el sistema
class OfflineFirstBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget Function(BuildContext context, String status)? loadingBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const OfflineFirstBuilder({
    Key? key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  }) : super(key: key);

  @override State<OfflineFirstBuilder> createState() => _OfflineFirstBuilderState();
}

class _OfflineFirstBuilderState extends State<OfflineFirstBuilder> {
  late Future<void> _initFuture;
  final StreamController<String> _statusController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      _statusController.add('Inicializando sistema offline-first...');
      await OfflineFirstInitService.instance.initialize();
      _statusController.add('Sistema inicializado correctamente');
    } catch (e) {
      _statusController.add('Error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _statusController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return StreamBuilder<String>(
            stream: _statusController.stream,
            initialData: 'Iniciando...',
            builder: (context, statusSnapshot) {
              return widget.loadingBuilder?.call(context, statusSnapshot.data!) ??
                  _DefaultLoadingWidget(status: statusSnapshot.data!);
            },
          );
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!) ??
              _DefaultErrorWidget(error: snapshot.error!);
        }

        return widget.builder(context);
      },
    );
  }
}

/// Widget de carga por defecto
class _DefaultLoadingWidget extends StatelessWidget {
  final String status;

  const _DefaultLoadingWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de error por defecto
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                'Error inicializando sistema',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await OfflineFirstInitService.instance.reset();
                  if (context.mounted) {
                    // Reiniciar la aplicación
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}