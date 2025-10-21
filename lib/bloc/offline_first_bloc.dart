import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/offline_first_init_service.dart';
import '../repositories/offline_repositories.dart';
import '../database/local_database.dart';

// Events
abstract class OfflineFirstEvent extends Equatable {
  const OfflineFirstEvent();

  @override
  List<Object?> get props => [];
}

class InitializeOfflineFirst extends OfflineFirstEvent {
  const InitializeOfflineFirst();
}

class SyncData extends OfflineFirstEvent {
  const SyncData();
}

class CheckConnectivity extends OfflineFirstEvent {
  const CheckConnectivity();
}

class LoadProducts extends OfflineFirstEvent {
  const LoadProducts();
}

class LoadProductsByCategory extends OfflineFirstEvent {
  final int categoryId;

  const LoadProductsByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class CreateProduct extends OfflineFirstEvent {
  final String name;
  final String sku;
  final double salePrice;
  final double purchasePrice;
  final int categoryId;
  final String? description;
  final String? brand;
  final String? unit;

  const CreateProduct({
    required this.name,
    required this.sku,
    required this.salePrice,
    required this.purchasePrice,
    required this.categoryId,
    this.description,
    this.brand,
    this.unit,
  });

  @override
  List<Object?> get props => [
        name,
        sku,
        salePrice,
        purchasePrice,
        categoryId,
        description,
        brand,
        unit,
      ];
}

class UpdateProduct extends OfflineFirstEvent {
  final Product product;
  final String? name;
  final String? sku;
  final double? salePrice;
  final double? purchasePrice;
  final int? categoryId;
  final String? description;
  final String? brand;
  final String? unit;

  const UpdateProduct({
    required this.product,
    this.name,
    this.sku,
    this.salePrice,
    this.purchasePrice,
    this.categoryId,
    this.description,
    this.brand,
    this.unit,
  });

  @override
  List<Object?> get props => [
        product,
        name,
        sku,
        salePrice,
        purchasePrice,
        categoryId,
        description,
        brand,
        unit,
      ];
}

class UpdateStock extends OfflineFirstEvent {
  final int productId;
  final int warehouseId;
  final double newQuantity;

  const UpdateStock({
    required this.productId,
    required this.warehouseId,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [productId, warehouseId, newQuantity];
}

class CreateSale extends OfflineFirstEvent {
  final int customerId;
  final int employeeId;
  final int storeId;
  final String saleNumber;
  final double subtotal;
  final double totalAmount;
  final String saleStatus;
  final String paymentMethod;
  final String paymentStatus;
  final double taxAmount;
  final double discountAmount;

  const CreateSale({
    required this.customerId,
    required this.employeeId,
    required this.storeId,
    required this.saleNumber,
    required this.subtotal,
    required this.totalAmount,
    this.saleStatus = 'pending',
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
  });

  @override
  List<Object?> get props => [
        customerId,
        employeeId,
        storeId,
        saleNumber,
        subtotal,
        totalAmount,
        saleStatus,
        paymentMethod,
        paymentStatus,
        taxAmount,
        discountAmount,
      ];
}

// States
abstract class OfflineFirstState extends Equatable {
  const OfflineFirstState();

  @override
  List<Object?> get props => [];
}

class OfflineFirstInitial extends OfflineFirstState {
  const OfflineFirstInitial();
}

class OfflineFirstLoading extends OfflineFirstState {
  const OfflineFirstLoading();
}

class OfflineFirstReady extends OfflineFirstState {
  final bool hasConnection;
  final bool isSyncing;
  final String syncStatus;

  const OfflineFirstReady({
    required this.hasConnection,
    required this.isSyncing,
    required this.syncStatus,
  });

  @override
  List<Object?> get props => [hasConnection, isSyncing, syncStatus];
}

class ProductsLoaded extends OfflineFirstState {
  final List<Product> products;
  final bool hasConnection;

  const ProductsLoaded({
    required this.products,
    required this.hasConnection,
  });

  @override
  List<Object?> get props => [products, hasConnection];
}

class ProductCreated extends OfflineFirstState {
  final Product product;
  final bool hasConnection;

  const ProductCreated({
    required this.product,
    required this.hasConnection,
  });

  @override
  List<Object?> get props => [product, hasConnection];
}

class ProductUpdated extends OfflineFirstState {
  final Product product;
  final bool hasConnection;

  const ProductUpdated({
    required this.product,
    required this.hasConnection,
  });

  @override
  List<Object?> get props => [product, hasConnection];
}

class StockUpdated extends OfflineFirstState {
  final Stock stock;
  final bool hasConnection;

  const StockUpdated({
    required this.stock,
    required this.hasConnection,
  });

  @override
  List<Object?> get props => [stock, hasConnection];
}

class SaleCreated extends OfflineFirstState {
  final Sale sale;
  final bool hasConnection;

  const SaleCreated({
    required this.sale,
    required this.hasConnection,
  });

  @override
  List<Object?> get props => [sale, hasConnection];
}

class OfflineFirstError extends OfflineFirstState {
  final String message;
  final Object? error;

  const OfflineFirstError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

class SyncInProgress extends OfflineFirstState {
  final String progress;

  const SyncInProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class SyncCompleted extends OfflineFirstState {
  final bool hasConnection;

  const SyncCompleted(this.hasConnection);

  @override
  List<Object?> get props => [hasConnection];
}

// BLoC
class OfflineFirstBloc extends Bloc<OfflineFirstEvent, OfflineFirstState> {
  late final ProductRepository _productRepository;
  late final StockRepository _stockRepository;
  late final SaleRepository _saleRepository;
  late final CategoryRepository _categoryRepository;

  StreamSubscription? _syncStatusSubscription;
  StreamSubscription? _syncProgressSubscription;

  OfflineFirstBloc() : super(const OfflineFirstInitial()) {
    on<InitializeOfflineFirst>(_onInitialize);
    on<SyncData>(_onSyncData);
    on<CheckConnectivity>(_onCheckConnectivity);
    on<LoadProducts>(_onLoadProducts);
    on<LoadProductsByCategory>(_onLoadProductsByCategory);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<UpdateStock>(_onUpdateStock);
    on<CreateSale>(_onCreateSale);
  }

  Future<void> _onInitialize(
    InitializeOfflineFirst event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      emit(const OfflineFirstLoading());

      // Inicializar el sistema offline-first
      await OfflineFirstInitService.instance.initialize();

      // Obtener repositorios
      _productRepository = OfflineFirstInitService.instance.productRepository;
      _stockRepository = OfflineFirstInitService.instance.stockRepository;
      _saleRepository = OfflineFirstInitService.instance.saleRepository;
      _categoryRepository = OfflineFirstInitService.instance.categoryRepository;

      // Escuchar cambios de sincronización
      _syncStatusSubscription = OfflineFirstInitService.instance.syncStatus.listen((isSyncing) {
        if (isSyncing) {
          // No emitir estado aquí para evitar conflictos
        }
      });

      _syncProgressSubscription = OfflineFirstInitService.instance.syncProgress.listen((progress) {
        if (progress.contains('Sincronizando') || progress.contains('Descargando') || progress.contains('Subiendo')) {
          add(const SyncData()); // Trigger sync state update
        }
      });

      // Verificar conectividad inicial
      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(OfflineFirstReady(
        hasConnection: hasConnection,
        isSyncing: false,
        syncStatus: hasConnection ? 'Conectado' : 'Modo offline',
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error inicializando sistema offline-first',
        error: e,
      ));
    }
  }

  Future<void> _onSyncData(
    SyncData event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      emit(const SyncInProgress('Sincronizando datos...'));
      
      await OfflineFirstInitService.instance.manualSync();
      
      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      emit(SyncCompleted(hasConnection));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error en sincronización',
        error: e,
      ));
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(OfflineFirstReady(
        hasConnection: hasConnection,
        isSyncing: false,
        syncStatus: hasConnection ? 'Conectado' : 'Modo offline',
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error verificando conectividad',
        error: e,
      ));
    }
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final products = await _productRepository.getAllProducts();
      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(ProductsLoaded(
        products: products,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error cargando productos',
        error: e,
      ));
    }
  }

  Future<void> _onLoadProductsByCategory(
    LoadProductsByCategory event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final products = await _productRepository.getProductsByCategory(event.categoryId);
      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(ProductsLoaded(
        products: products,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error cargando productos por categoría',
        error: e,
      ));
    }
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final product = await _productRepository.createProduct(
        name: event.name,
        sku: event.sku,
        salePrice: event.salePrice,
        purchasePrice: event.purchasePrice,
        categoryId: event.categoryId,
        description: event.description,
        brand: event.brand,
        unit: event.unit,
      );

      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(ProductCreated(
        product: product,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error creando producto',
        error: e,
      ));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final product = await _productRepository.updateProduct(
        product: event.product,
        name: event.name,
        sku: event.sku,
        salePrice: event.salePrice,
        purchasePrice: event.purchasePrice,
        categoryId: event.categoryId,
        description: event.description,
        brand: event.brand,
        unit: event.unit,
      );

      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(ProductUpdated(
        product: product,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error actualizando producto',
        error: e,
      ));
    }
  }

  Future<void> _onUpdateStock(
    UpdateStock event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final stock = await _stockRepository.updateStock(
        productId: event.productId,
        warehouseId: event.warehouseId,
        newQuantity: event.newQuantity,
      );

      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(StockUpdated(
        stock: stock,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error actualizando stock',
        error: e,
      ));
    }
  }

  Future<void> _onCreateSale(
    CreateSale event,
    Emitter<OfflineFirstState> emit,
  ) async {
    try {
      final sale = await _saleRepository.createSale(
        customerId: event.customerId,
        employeeId: event.employeeId,
        storeId: event.storeId,
        saleNumber: event.saleNumber,
        subtotal: event.subtotal,
        totalAmount: event.totalAmount,
        saleStatus: event.saleStatus,
        paymentMethod: event.paymentMethod,
        paymentStatus: event.paymentStatus,
        taxAmount: event.taxAmount,
        discountAmount: event.discountAmount,
      );

      final hasConnection = await OfflineFirstInitService.instance.checkConnectivity();
      
      emit(SaleCreated(
        sale: sale,
        hasConnection: hasConnection,
      ));
    } catch (e) {
      emit(OfflineFirstError(
        message: 'Error creando venta',
        error: e,
      ));
    }
  }

  @override
  Future<void> close() {
    _syncStatusSubscription?.cancel();
    _syncProgressSubscription?.cancel();
    return super.close();
  }
}