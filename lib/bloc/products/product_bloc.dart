import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import '../../database/local_database.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final LocalDatabase _database;
  
  // Variables para manejar paginación y filtros
  List<Product> _allProducts = [];
  int? _currentCategoryFilter;
  String? _currentSearchQuery;
  static const int _pageSize = 20;

  ProductBloc({
    required LocalDatabase database,
  })  : _database = database,
        super(ProductInitial()) {
    
    // Registrar manejadores de eventos
    on<ProductsLoadRequested>(_onProductsLoadRequested);
    on<ProductsRefreshRequested>(_onProductsRefreshRequested);
    on<ProductCreateRequested>(_onProductCreateRequested);
    on<ProductUpdateRequested>(_onProductUpdateRequested);
    on<ProductDeleteRequested>(_onProductDeleteRequested);
    on<ProductSearchRequested>(_onProductSearchRequested);
    on<ProductsLoadMoreRequested>(_onProductsLoadMoreRequested);
    on<ProductsFilterByCategoryRequested>(_onProductsFilterByCategoryRequested);
  }

  /// Cargar productos con filtros y paginación
  Future<void> _onProductsLoadRequested(
    ProductsLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (event.offset == 0) {
      emit(ProductLoading());
    }

    try {
      List<Product> products;
      
      if (event.categoryId != null) {
        products = await _database.getProductsByCategory(event.categoryId!);
        _currentCategoryFilter = event.categoryId;
      } else if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        products = await _searchProducts(event.searchQuery!);
        _currentSearchQuery = event.searchQuery;
      } else {
        products = await _database.getAllProducts();
        _currentCategoryFilter = null;
        _currentSearchQuery = null;
      }

      // Aplicar paginación
      final startIndex = event.offset;
      final endIndex = (startIndex + event.limit).clamp(0, products.length);
      final paginatedProducts = products.sublist(
        startIndex.clamp(0, products.length),
        endIndex,
      );

      if (event.offset == 0) {
        _allProducts = paginatedProducts;
      } else {
        _allProducts.addAll(paginatedProducts);
      }

      final hasReachedMax = endIndex >= products.length;

      emit(ProductLoaded(
        products: List.from(_allProducts),
        hasReachedMax: hasReachedMax,
      ));
    } catch (e) {
      emit(ProductError(
        message: 'Error al cargar productos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Refrescar productos
  Future<void> _onProductsRefreshRequested(
    ProductsRefreshRequested event,
    Emitter<ProductState> emit,
  ) async {
    _allProducts.clear();
    add(ProductsLoadRequested(
      categoryId: event.categoryId ?? _currentCategoryFilter,
      searchQuery: event.searchQuery ?? _currentSearchQuery,
      offset: 0,
    ));
  }

  /// Crear producto
  Future<void> _onProductCreateRequested(
    ProductCreateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductCreating());

    try {
      final newProduct = ProductsCompanion.insert(
        sku: event.sku,
        name: event.name,
        description: Value(event.description),
        categoryId: event.categoryId,
        purchasePrice: event.cost,
        salePrice: event.price,
        unit: event.unit,
        minStock: Value(event.lowStockThreshold),
        isActive: Value(event.isActive),
      );

      final productId = await _database.insertProduct(newProduct);
      final createdProduct = await _database.getProductById(productId);

      if (createdProduct != null) {
        emit(ProductCreated(createdProduct));
        
        // Refrescar la lista
        add(const ProductsRefreshRequested());
      } else {
        emit(const ProductError(message: 'Error al obtener producto creado'));
      }
    } catch (e) {
      emit(ProductError(
        message: 'Error al crear producto: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Actualizar producto
  Future<void> _onProductUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductUpdating());

    try {
      final currentProduct = await _database.getProductById(event.productId);
      if (currentProduct == null) {
        emit(const ProductError(message: 'Producto no encontrado'));
        return;
      }

      final updatedProduct = ProductsCompanion(
        id: Value(event.productId),
        sku: event.sku != null ? Value(event.sku!) : Value.absent(),
        name: event.name != null ? Value(event.name!) : Value.absent(),
        description: event.description != null ? Value(event.description!) : Value.absent(),
        categoryId: event.categoryId != null ? Value(event.categoryId!) : Value.absent(),
        purchasePrice: event.cost != null ? Value(event.cost!) : Value.absent(),
        salePrice: event.price != null ? Value(event.price!) : Value.absent(),
        unit: event.unit != null ? Value(event.unit!) : Value.absent(),
        minStock: event.lowStockThreshold != null ? Value(event.lowStockThreshold!) : Value.absent(),
        isActive: event.isActive != null ? Value(event.isActive!) : Value.absent(),
      );

      await _database.updateProduct(updatedProduct);
      final product = await _database.getProductById(event.productId);

      if (product != null) {
        emit(ProductUpdated(product));
        
        // Refrescar la lista
        add(const ProductsRefreshRequested());
      } else {
        emit(const ProductError(message: 'Error al obtener producto actualizado'));
      }
    } catch (e) {
      emit(ProductError(
        message: 'Error al actualizar producto: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Eliminar producto
  Future<void> _onProductDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductDeleting());

    try {
      await _database.deleteProduct(event.productId);
      emit(ProductDeleted(event.productId));
      
      // Refrescar la lista
      add(const ProductsRefreshRequested());
    } catch (e) {
      emit(ProductError(
        message: 'Error al eliminar producto: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Buscar productos
  Future<void> _onProductSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    _allProducts.clear();
    add(ProductsLoadRequested(
      searchQuery: event.query,
      offset: 0,
    ));
  }

  /// Cargar más productos (paginación)
  Future<void> _onProductsLoadMoreRequested(
    ProductsLoadMoreRequested event,
    Emitter<ProductState> emit,
  ) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      if (!currentState.hasReachedMax) {
        add(ProductsLoadRequested(
          categoryId: _currentCategoryFilter,
          searchQuery: _currentSearchQuery,
          offset: _allProducts.length,
        ));
      }
    }
  }

  /// Filtrar productos por categoría
  Future<void> _onProductsFilterByCategoryRequested(
    ProductsFilterByCategoryRequested event,
    Emitter<ProductState> emit,
  ) async {
    _allProducts.clear();
    add(ProductsLoadRequested(
      categoryId: event.categoryId,
      offset: 0,
    ));
  }

  /// Buscar productos por nombre o SKU
  Future<List<Product>> _searchProducts(String query) async {
    final allProducts = await _database.getAllProducts();
    return allProducts.where((product) {
      final lowercaseQuery = query.toLowerCase();
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.sku.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}