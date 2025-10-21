import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/local_database.dart';
import '../../services/role_based_auth_service.dart';
import '../../models/user_role.dart';
import '../../bloc/auth/role_auth_bloc.dart';
import '../../widgets/customer_widgets.dart';

/// Dashboard principal para clientes - Pantalla de compras de productos
class CustomerDashboard extends StatefulWidget {
  final LocalDatabase? database;
  
  const CustomerDashboard({super.key, this.database});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LocalDatabase _database;
  late RoleBasedAuthService _authService;
  Employee? _currentUser;

  // Estados de la aplicación
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Store> _stores = [];
  Map<int, List<Stock>> _stocksByStore = {};
  
  // Carrito de compras
  final Map<String, CartItem> _cartItems = {}; // key: "productId_storeId"
  Store? _selectedStore;
  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() async {
    final authBloc = context.read<RoleAuthBloc>();
    _authService = authBloc.authService;
    _database = widget.database ?? context.read<LocalDatabase>();
    
    final authState = authBloc.state;
    if (authState is RoleAuthAuthenticated) {
      _currentUser = authState.user;
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar datos principales
      final products = await _database.select(_database.products).get();
      final categories = await _database.select(_database.productCategories).get();
      final stores = await _database.select(_database.stores).get();
      
      // Cargar stock por almacén (asociado a tiendas)
      final stocks = await _database.select(_database.stocks).get();
      final warehouses = await _database.select(_database.warehouses).get();
      final Map<int, List<Stock>> stocksByStore = {};
      
      // Crear un mapa de warehouse_id a store_id
      final Map<int, int> warehouseToStore = {};
      for (var warehouse in warehouses) {
        if (warehouse.storeId != null) {
          warehouseToStore[warehouse.id] = warehouse.storeId!;
        }
      }
      
      // Agrupar stocks por tienda
      for (var stock in stocks) {
        final storeId = warehouseToStore[stock.warehouseId];
        if (storeId != null) {
          if (!stocksByStore.containsKey(storeId)) {
            stocksByStore[storeId] = [];
          }
          stocksByStore[storeId]!.add(stock);
        }
      }

      setState(() {
        _products = products.where((p) => p.isActive).toList();
        _categories = categories.where((c) => c.isActive).toList();
        _stores = stores.where((s) => s.isActive).toList();
        _stocksByStore = stocksByStore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: UserRole.customer.color,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tienda Online',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            if (_currentUser != null)
              Text(
                '¡Hola, ${_currentUser!.firstName}!',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // Badge del carrito
          Stack(
            children: [
              IconButton(
                onPressed: () => _showCartDialog(),
                icon: const Icon(Icons.shopping_cart),
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_getTotalItemsInCart()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // Menú de usuario
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'orders':
                  _showOrdersDialog();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Mis Pedidos'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: 'Productos'),
            Tab(icon: Icon(Icons.location_on), text: 'Tiendas'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Ofertas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildStoresTab(),
                _buildCategoriesTab(),
                _buildOffersTab(),
              ],
            ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Filtros y búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Barra de búsqueda
              TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 12),
              
              // Filtros
              Column(
                children: [
                  // Primera fila: Filtro por tienda
                  DropdownButtonFormField<Store>(
                    value: _selectedStore,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Tienda',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<Store>(
                        value: null,
                        child: Text(
                          'Todas las tiendas',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._stores.map((store) => DropdownMenuItem(
                        value: store,
                        child: Text(
                          store.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (store) {
                      setState(() => _selectedStore = store);
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Segunda fila: Filtro por categoría
                  DropdownButtonFormField<ProductCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Categoría',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<ProductCategory>(
                        value: null,
                        child: Text(
                          'Todas las categorías',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de productos
        Expanded(
          child: _buildProductsList(),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _getFilteredProducts();
    
    if (filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Intenta cambiar los filtros de búsqueda',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 
                       MediaQuery.of(context).size.width > 600 ? 2 : 1,
        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.75 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(
          product: product,
          stores: _stores,
          stocksByStore: _stocksByStore,
          selectedStore: _selectedStore,
          onAddToCart: (productId, storeId, quantity) {
            _addToCart(productId, storeId, quantity);
          },
        );
      },
    );
  }

  Widget _buildStoresTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        final storeStock = _stocksByStore[store.id] ?? [];
        final availableProducts = storeStock.where((s) => s.quantity > 0).length;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado de la tienda
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: UserRole.customer.color,
                      child: const Icon(Icons.store, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            store.city,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Información de la tienda
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.address,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    if (store.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            store.phone!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.inventory, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$availableProducts productos disponibles',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Botón en la parte inferior
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStore = store;
                        _tabController.animateTo(0); // Ir a la pestaña de productos
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UserRole.customer.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Ver Productos'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 
                       MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: MediaQuery.of(context).size.width < 600 ? 1.0 : 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final productsInCategory = _products
            .where((p) => p.categoryId == category.id)
            .length;

        return Card(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _tabController.animateTo(0); // Ir a la pestaña de productos
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 2,
                    child: Icon(
                      Icons.category,
                      size: MediaQuery.of(context).size.width < 600 ? 32 : 48,
                      color: UserRole.customer.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$productsInCategory productos',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOffersTab() {
    // Productos con descuento o precios especiales
    final offeredProducts = _products.where((p) {
      // Aquí podrías implementar lógica de ofertas
      // Por ahora mostraremos productos con precios menores a un umbral
      return p.salePrice < 50000; // Productos menores a 50,000
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: const Column(
            children: [
              Icon(Icons.local_offer, size: 48, color: Colors.orange),
              SizedBox(height: 8),
              Text(
                '¡Ofertas Especiales!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'Los mejores precios para ti',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 
                             MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.7 : 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: offeredProducts.length,
            itemBuilder: (context, index) {
              final product = offeredProducts[index];
              return ProductCard(
                product: product,
                stores: _stores,
                stocksByStore: _stocksByStore,
                selectedStore: _selectedStore,
                isOffer: true,
                onAddToCart: (productId, storeId, quantity) {
                  _addToCart(productId, storeId, quantity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<Product> _getFilteredProducts() {
    return _products.where((product) {
      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final matchesSearch = product.name.toLowerCase().contains(_searchQuery) ||
                            (product.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                            (product.brand?.toLowerCase().contains(_searchQuery) ?? false);
        if (!matchesSearch) return false;
      }
      
      // Filtrar por categoría
      if (_selectedCategory != null && product.categoryId != _selectedCategory!.id) {
        return false;
      }
      
      // Filtrar por tienda (debe tener stock)
      if (_selectedStore != null) {
        final storeStock = _stocksByStore[_selectedStore!.id];
        final hasStock = storeStock?.any((s) => s.productId == product.id && s.quantity > 0) ?? false;
        if (!hasStock) return false;
      }
      
      return true;
    }).toList();
  }

  void _addToCart(int productId, int storeId, double quantity) {
    final key = '${productId}_$storeId';
    final product = _products.firstWhere((p) => p.id == productId);
    final store = _stores.firstWhere((s) => s.id == storeId);
    
    setState(() {
      if (_cartItems.containsKey(key)) {
        _cartItems[key] = _cartItems[key]!.copyWith(
          quantity: _cartItems[key]!.quantity + quantity,
        );
      } else {
        _cartItems[key] = CartItem(
          product: product,
          store: store,
          quantity: quantity,
          unitPrice: product.salePrice,
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al carrito'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  int _getTotalItemsInCart() {
    return _cartItems.values.fold(0, (total, item) => total + item.quantity.round());
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => CartDialog(
        cartItems: _cartItems,
        onUpdateQuantity: (key, quantity) {
          setState(() {
            if (quantity <= 0) {
              _cartItems.remove(key);
            } else {
              _cartItems[key] = _cartItems[key]!.copyWith(quantity: quantity);
            }
          });
        },
        onCheckout: _processCheckout,
        onClearCart: () {
          setState(() => _cartItems.clear());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _processCheckout() async {
    if (_cartItems.isEmpty) return;
    
    try {
      // Verificar stock disponible antes de procesar
      final stockErrors = <String>[];
      for (final item in _cartItems.values) {
        final stock = await _database.getStockByProductAndWarehouse(
          item.product.id, 
          1 // Usar warehouse por defecto
        );
        
        if (stock == null) {
          stockErrors.add('${item.product.name}: Sin stock disponible');
        } else if (stock.quantity < item.quantity) {
          stockErrors.add('${item.product.name}: Stock insuficiente (Disponible: ${stock.quantity.toInt()}, Solicitado: ${item.quantity})');
        }
      }
      
      if (stockErrors.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.warning, color: Colors.orange, size: 64),
              title: const Text('Stock Insuficiente'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Los siguientes productos no tienen stock suficiente:'),
                  const SizedBox(height: 8),
                  ...stockErrors.map((error) => Text('• $error')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Agrupar por tienda
      final ordersByStore = <int, List<CartItem>>{};
      for (final item in _cartItems.values) {
        if (!ordersByStore.containsKey(item.store.id)) {
          ordersByStore[item.store.id] = [];
        }
        ordersByStore[item.store.id]!.add(item);
      }
      
      // Crear una venta por cada tienda
      for (final storeId in ordersByStore.keys) {
        final items = ordersByStore[storeId]!;
        final subtotal = items.fold(0.0, (sum, item) => sum + (item.quantity * item.unitPrice));
        
        // Crear la venta
        final taxAmount = subtotal * 0.19; // IVA 19%
        final totalAmount = subtotal + taxAmount;
        
        final saleId = await _database.into(_database.sales).insert(
          SalesCompanion.insert(
            storeId: storeId,
            customerId: _currentUser!.id,
            employeeId: _currentUser!.id, // Por ahora usar el mismo usuario
            saleNumber: 'WEB-${DateTime.now().millisecondsSinceEpoch}',
            saleDate: DateTime.now(),
            subtotal: subtotal,
            totalAmount: totalAmount,
            saleStatus: 'PENDING',
            paymentMethod: 'ONLINE',
            paymentStatus: 'PENDING',
          ),
        );
        
        // Crear los items de la venta y actualizar stock
        for (final item in items) {
          await _database.into(_database.saleItems).insert(
            SaleItemsCompanion.insert(
              saleId: saleId,
              productId: item.product.id,
              warehouseId: 1, // Usar warehouse por defecto
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.quantity * item.unitPrice,
            ),
          );
          
          // Decrementar el stock
          await _database.decrementStock(
            item.product.id,
            1, // Warehouse por defecto
            item.quantity.toDouble(),
          );
        }
      }
      
      setState(() => _cartItems.clear());
      
      // Recargar datos para actualizar el stock después de la compra
      await _loadData();
      
      if (mounted) {
        Navigator.of(context).pop(); // Cerrar el diálogo del carrito
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
            title: const Text('¡Pedido Realizado!'),
            content: const Text(
              'Tu pedido ha sido procesado exitosamente y el stock ha sido actualizado. '
              'Recibirás una confirmación por email.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al procesar el pedido: $e';
        
        // Mensaje más específico para errores de stock
        if (e.toString().contains('Stock insuficiente')) {
          errorMessage = 'No hay suficiente stock disponible para completar el pedido.';
        } else if (e.toString().contains('Stock no encontrado')) {
          errorMessage = 'Algunos productos no están disponibles en inventario.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentUser != null) ...[
              Text('Nombre: ${_currentUser!.firstName} ${_currentUser!.lastName}'),
              Text('Email: ${_currentUser!.email}'),
              if (_currentUser!.phone != null)
                Text('Teléfono: ${_currentUser!.phone}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showOrdersDialog() {
    // Implementar lista de pedidos del cliente
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mis Pedidos'),
        content: const Text('Funcionalidad próximamente disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    context.read<RoleAuthBloc>().add(RoleAuthLogoutRequested());
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Clase para representar items en el carrito
class CartItem {
  final Product product;
  final Store store;
  final double quantity;
  final double unitPrice;

  CartItem({
    required this.product,
    required this.store,
    required this.quantity,
    required this.unitPrice,
  });

  CartItem copyWith({
    Product? product,
    Store? store,
    double? quantity,
    double? unitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      store: store ?? this.store,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  double get totalPrice => quantity * unitPrice;
}