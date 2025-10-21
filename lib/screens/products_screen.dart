import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/products/product_bloc.dart';
import '../bloc/products/product_event.dart';
import '../bloc/products/product_state.dart';
import '../database/local_database.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Cargar productos al iniciar
    context.read<ProductBloc>().add(const ProductsLoadRequested());
    
    // Listener para scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ProductBloc>().add(ProductsLoadMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _showCreateProductDialog() {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Producto'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Precio de Venta',
                          border: OutlineInputBorder(),
                          prefixText: 'S/ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(
                          labelText: 'Costo',
                          border: OutlineInputBorder(),
                          prefixText: 'S/ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                context.read<ProductBloc>().add(
                  ProductCreateRequested(
                    sku: skuController.text,
                    name: nameController.text,
                    description: descriptionController.text,
                    categoryId: 1, // Por ahora usar categoría por defecto
                    price: double.tryParse(priceController.text) ?? 0.0,
                    cost: double.tryParse(costController.text) ?? 0.0,
                    unit: 'unidad',
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              context.read<ProductBloc>().add(const ProductsRefreshRequested());
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductBloc>().add(const ProductsRefreshRequested());
                        },
                      )
                    : null,
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  context.read<ProductBloc>().add(ProductSearchRequested(query));
                } else {
                  context.read<ProductBloc>().add(const ProductsRefreshRequested());
                }
              },
            ),
          ),
          
          // Lista de productos
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ProductBloc>().add(const ProductsRefreshRequested());
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay productos',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Crea tu primer producto usando el botón +',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.hasReachedMax 
                        ? state.products.length 
                        : state.products.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= state.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final product = state.products[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF8B4513),
                            child: Text(
                              product.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SKU: ${product.sku}'),
                              if (product.description != null)
                                Text(
                                  product.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              Row(
                                children: [
                                  Text(
                                    'Precio: S/ ${product.salePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B4513),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Costo: S/ ${product.purchasePrice.toStringAsFixed(2)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteConfirmation(product);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                
                return const Center(child: Text('Estado no reconocido'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProductDialog,
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(ProductDeleteRequested(product.id));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}