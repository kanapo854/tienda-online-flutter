import 'package:equatable/equatable.dart';
import '../../database/local_database.dart';

/// Estados base para productos
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductInitial extends ProductState {}

/// Estado de carga
class ProductLoading extends ProductState {}

/// Estado cuando se cargan productos exitosamente
class ProductLoaded extends ProductState {
  final List<Product> products;
  final bool hasReachedMax;

  const ProductLoaded({
    required this.products,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [products, hasReachedMax];

  ProductLoaded copyWith({
    List<Product>? products,
    bool? hasReachedMax,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

/// Estado de error
class ProductError extends ProductState {
  final String message;
  final Exception? exception;

  const ProductError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

/// Estado cuando se está creando un producto
class ProductCreating extends ProductState {}

/// Estado cuando se crea un producto exitosamente
class ProductCreated extends ProductState {
  final Product product;

  const ProductCreated(this.product);

  @override
  List<Object?> get props => [product];
}

/// Estado cuando se está actualizando un producto
class ProductUpdating extends ProductState {}

/// Estado cuando se actualiza un producto exitosamente
class ProductUpdated extends ProductState {
  final Product product;

  const ProductUpdated(this.product);

  @override
  List<Object?> get props => [product];
}

/// Estado cuando se está eliminando un producto
class ProductDeleting extends ProductState {}

/// Estado cuando se elimina un producto exitosamente
class ProductDeleted extends ProductState {
  final int productId;

  const ProductDeleted(this.productId);

  @override
  List<Object?> get props => [productId];
}