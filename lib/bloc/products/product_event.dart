import 'package:equatable/equatable.dart';

/// Eventos base para productos
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para cargar productos
class ProductsLoadRequested extends ProductEvent {
  final int? categoryId;
  final String? searchQuery;
  final int limit;
  final int offset;

  const ProductsLoadRequested({
    this.categoryId,
    this.searchQuery,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [categoryId, searchQuery, limit, offset];
}

/// Evento para refrescar productos
class ProductsRefreshRequested extends ProductEvent {
  final int? categoryId;
  final String? searchQuery;

  const ProductsRefreshRequested({
    this.categoryId,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [categoryId, searchQuery];
}

/// Evento para crear producto
class ProductCreateRequested extends ProductEvent {
  final String sku;
  final String name;
  final String description;
  final int categoryId;
  final double price;
  final double cost;
  final String unit;
  final double lowStockThreshold;
  final bool isActive;

  const ProductCreateRequested({
    required this.sku,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.price,
    required this.cost,
    required this.unit,
    this.lowStockThreshold = 10.0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        sku,
        name,
        description,
        categoryId,
        price,
        cost,
        unit,
        lowStockThreshold,
        isActive,
      ];
}

/// Evento para actualizar producto
class ProductUpdateRequested extends ProductEvent {
  final int productId;
  final String? sku;
  final String? name;
  final String? description;
  final int? categoryId;
  final double? price;
  final double? cost;
  final String? unit;
  final double? lowStockThreshold;
  final bool? isActive;

  const ProductUpdateRequested({
    required this.productId,
    this.sku,
    this.name,
    this.description,
    this.categoryId,
    this.price,
    this.cost,
    this.unit,
    this.lowStockThreshold,
    this.isActive,
  });

  @override
  List<Object?> get props => [
        productId,
        sku,
        name,
        description,
        categoryId,
        price,
        cost,
        unit,
        lowStockThreshold,
        isActive,
      ];
}

/// Evento para eliminar producto
class ProductDeleteRequested extends ProductEvent {
  final int productId;

  const ProductDeleteRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Evento para buscar productos
class ProductSearchRequested extends ProductEvent {
  final String query;

  const ProductSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// Evento para cargar más productos (paginación)
class ProductsLoadMoreRequested extends ProductEvent {}

/// Evento para filtrar productos por categoría
class ProductsFilterByCategoryRequested extends ProductEvent {
  final int? categoryId;

  const ProductsFilterByCategoryRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}