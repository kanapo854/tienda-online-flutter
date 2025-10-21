import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/local_database.dart';
import '../../models/user_role.dart';
import '../../services/role_based_auth_service.dart';
import '../../widgets/inventory_dialogs.dart';
import '../../bloc/auth/role_auth_bloc.dart';

class AdminInventoryDashboard extends StatefulWidget {
  final RoleBasedAuthService authService;
  final Employee currentUser;
  final LocalDatabase database;

  const AdminInventoryDashboard({
    Key? key,
    required this.authService,
    required this.currentUser,
    required this.database,
  }) : super(key: key);

  @override
  State<AdminInventoryDashboard> createState() => _AdminInventoryDashboardState();
}

class _AdminInventoryDashboardState extends State<AdminInventoryDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Data
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Store> _stores = [];
  List<Warehouse> _warehouses = [];
  List<Stock> _stocks = [];
  
  // UI State
  bool _isLoading = true;
  String _searchText = '';
  int? _selectedStoreId;
  int? _selectedCategoryId;
  
  // Controllers
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final products = await widget.database.getAllProducts();
      final categories = await widget.database.getAllCategories();
      final stores = await widget.database.getAllStores();
      final warehouses = await widget.database.getAllWarehouses();
      final stocks = await widget.database.getAllStocks();
      
      setState(() {
        _products = products;
        _categories = categories;
        _stores = stores;
        _warehouses = warehouses;
        _stocks = stocks;
        _isLoading = false;
      });
      
      print('📦 Datos de inventario cargados: ${_products.length} productos, ${_stores.length} sucursales');
      
    } catch (e) {
      print('❌ Error cargando inventario: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error cargando datos: $e');
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
            Text('Nombre: ${widget.currentUser.firstName} ${widget.currentUser.lastName}'),
            Text('Email: ${widget.currentUser.email}'),
            const SizedBox(height: 8),
            const Text('Rol: Admin de Inventarios'),
            const SizedBox(height: 8),
            const Text('Permisos:'),
            const SizedBox(height: 4),
            const Text('• Gestión de productos y categorías'),
            const Text('• Control de stock y movimientos'),
            const Text('• Reportes de inventario'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Inventario'),
        backgroundColor: UserRole.adminInventory.color,
        foregroundColor: Colors.white,
        actions: [
          // Menú de usuario
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'refresh':
                  _loadData();
                  break;
                case 'logout':
                  context.read<RoleAuthBloc>().add(RoleAuthLogoutRequested());
                  Navigator.of(context).pushReplacementNamed('/');
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
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Actualizar'),
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
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Productos'),
            Tab(icon: Icon(Icons.category), text: 'Categorías'),
            Tab(icon: Icon(Icons.store), text: 'Por Sucursal'),
            Tab(icon: Icon(Icons.analytics), text: 'Reportes'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildCategoriesTab(),
                _buildByStoreTab(),
                _buildReportsTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Productos
        return FloatingActionButton.extended(
          onPressed: _showCreateProductDialog,
          backgroundColor: UserRole.adminInventory.color,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Producto'),
        );
      case 1: // Categorías
        return FloatingActionButton.extended(
          onPressed: _showCreateCategoryDialog,
          backgroundColor: UserRole.adminInventory.color,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Categoría'),
        );
      default:
        return null;
    }
  }

  // ============================================================================
  // TAB 1: PRODUCTOS
  // ============================================================================
  
  Widget _buildProductsTab() {
    return Column(
      children: [
        _buildProductsFilters(),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildProductsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, SKU o descripción...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _searchText = value),
          ),
          const SizedBox(height: 8),
          // Filtro por categoría
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: UserRole.adminInventory.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_getFilteredProducts().length} productos',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _getFilteredProducts();
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchText.isNotEmpty || _selectedCategoryId != null
                  ? 'No se encontraron productos con los filtros aplicados'
                  : 'No hay productos registrados',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchText.isEmpty && _selectedCategoryId == null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showCreateProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('Agregar primer producto'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  List<Product> _getFilteredProducts() {
    return _products.where((product) {
      // Filtro de búsqueda
      final matchesSearch = _searchText.isEmpty ||
          product.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchText.toLowerCase()) ||
          (product.description?.toLowerCase().contains(_searchText.toLowerCase()) ?? false);

      // Filtro de categoría
      final matchesCategory = _selectedCategoryId == null || product.categoryId == _selectedCategoryId;

      return matchesSearch && matchesCategory && product.isActive;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Widget _buildProductCard(Product product) {
    final category = _categories.where((c) => c.id == product.categoryId).firstOrNull;
    final totalStock = _getTotalProductStock(product.id);
    final lowStock = totalStock <= product.minStock;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: category?.isActive == true ? Colors.blue : Colors.grey,
          child: Text(
            product.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${product.sku}'),
            Text('Categoría: ${category?.name ?? 'Sin categoría'}'),
            Text('Precio: BS/ ${product.salePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: lowStock ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Stock Total: ${totalStock.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleProductAction(value, product),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: ListTile(
              leading: Icon(Icons.edit), title: Text('Editar Producto'))),
            const PopupMenuItem(value: 'price', child: ListTile(
              leading: Icon(Icons.attach_money), title: Text('Cambiar Precio'))),
            const PopupMenuItem(value: 'stock', child: ListTile(
              leading: Icon(Icons.inventory), title: Text('Gestionar Stock'))),
            const PopupMenuItem(value: 'delete', child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red), 
              title: Text('Eliminar', style: TextStyle(color: Colors.red)))),
          ],
        ),
        children: [
          _buildProductStockDetails(product),
        ],
      ),
    );
  }

  Widget _buildProductStockDetails(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stock por Sucursal:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._stores.map((store) {
            final stock = _getProductStockByStore(product.id, store.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('Stock: ${stock.toStringAsFixed(0)} ${product.unit}'),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showEditStockDialog(product, store),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 2: CATEGORÍAS
  // ============================================================================

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            children: [
              const Icon(Icons.category, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '${_categories.length} categorías registradas',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay categorías registradas',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateCategoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primera categoría'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final productCount = _products.where((p) => p.categoryId == category.id).length;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.isActive ? Colors.green : Colors.grey,
                          child: Text(
                            category.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${category.code}'),
                            if (category.description != null) Text(category.description!),
                            Text('$productCount productos'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleCategoryAction(value, category),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: ListTile(
                              leading: Icon(Icons.edit), title: Text('Editar'))),
                            PopupMenuItem(
                              value: category.isActive ? 'deactivate' : 'activate',
                              child: ListTile(
                                leading: Icon(category.isActive ? Icons.visibility_off : Icons.visibility),
                                title: Text(category.isActive ? 'Desactivar' : 'Activar'),
                              ),
                            ),
                            if (productCount == 0) 
                              const PopupMenuItem(value: 'delete', child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                              )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 3: POR SUCURSAL
  // ============================================================================

  Widget _buildByStoreTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: DropdownButtonFormField<int?>(
            value: _selectedStoreId,
            decoration: InputDecoration(
              labelText: 'Seleccionar Sucursal',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _stores.map((store) => DropdownMenuItem<int?>(
              value: store.id,
              child: Text('${store.name} - ${store.city}'),
            )).toList(),
            onChanged: (value) => setState(() => _selectedStoreId = value),
          ),
        ),
        Expanded(
          child: _selectedStoreId == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Selecciona una sucursal para ver su inventario',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _buildStoreInventory(_selectedStoreId!),
        ),
      ],
    );
  }

  Widget _buildStoreInventory(int storeId) {
    final store = _stores.firstWhere((s) => s.id == storeId);
    final storeProducts = _getProductsByStore(storeId);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.store, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${store.city} - ${storeProducts.length} productos en stock'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: storeProducts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay productos con stock en esta sucursal',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: storeProducts.length,
                  itemBuilder: (context, index) {
                    final productStock = storeProducts[index];
                    final product = productStock['product'] as Product;
                    final stock = productStock['stock'] as double;
                    final lowStock = stock <= product.minStock;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: lowStock ? Colors.red : Colors.green,
                          child: Icon(
                            lowStock ? Icons.warning : Icons.check,
                            color: Colors.white,
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
                            Text('Precio: BS/ ${product.salePrice.toStringAsFixed(2)}'),
                            Text(
                              'Stock: ${stock.toStringAsFixed(0)} ${product.unit}',
                              style: TextStyle(
                                color: lowStock ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showEditStockDialog(product, store),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar Stock',
                            ),
                            IconButton(
                              onPressed: () => _showEditPriceDialog(product),
                              icon: const Icon(Icons.attach_money),
                              tooltip: 'Editar Precio',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // TAB 4: REPORTES
  // ============================================================================

  Widget _buildReportsTab() {
    final totalProducts = _products.length;
    final activeProducts = _products.where((p) => p.isActive).length;
    final totalValue = _calculateTotalInventoryValue();
    final lowStockProducts = _getLowStockProducts();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          const Text(
            'Resumen General',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Productos', totalProducts.toString(), Icons.inventory_2, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Productos Activos', activeProducts.toString(), Icons.check_circle, Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatCard('Valor Total', 'BS/ ${totalValue.toStringAsFixed(2)}', Icons.attach_money, Colors.orange)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Stock Bajo', lowStockProducts.length.toString(), Icons.warning, Colors.red)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Productos con stock bajo
          const Text(
            'Productos con Stock Bajo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (lowStockProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('✅ Todos los productos tienen stock suficiente'),
                ],
              ),
            )
          else
            ...lowStockProducts.map((product) {
              final totalStock = _getTotalProductStock(product.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning, color: Colors.white),
                  ),
                  title: Text(product.name),
                  subtitle: Text('Stock actual: ${totalStock.toStringAsFixed(0)} / Mínimo: ${product.minStock.toStringAsFixed(0)}'),
                  trailing: ElevatedButton(
                    onPressed: () => _showQuickRestockDialog(product),
                    child: const Text('Reabastecer'),
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 24),
          
          // Stock por sucursal
          const Text(
            'Stock por Sucursal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._stores.map((store) {
            final storeProducts = _getProductsByStore(store.id);
            final storeValue = _calculateStoreInventoryValue(store.id);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: const Icon(Icons.store, color: Colors.blue),
                title: Text(store.name),
                subtitle: Text('${storeProducts.length} productos - Valor: BS/ ${storeValue.toStringAsFixed(2)}'),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: storeProducts.take(5).map((productStock) {
                        final product = productStock['product'] as Product;
                        final stock = productStock['stock'] as double;
                        return ListTile(
                          dense: true,
                          title: Text(product.name),
                          trailing: Text('${stock.toStringAsFixed(0)} ${product.unit}'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  double _getTotalProductStock(int productId) {
    return _stocks
        .where((stock) => stock.productId == productId)
        .fold(0.0, (sum, stock) => sum + stock.quantity);
  }

  double _getProductStockByStore(int productId, int storeId) {
    final warehouse = _warehouses.where((w) => w.storeId == storeId).firstOrNull;
    if (warehouse == null) return 0.0;
    
    final stock = _stocks.where((s) => 
      s.productId == productId && s.warehouseId == warehouse.id
    ).firstOrNull;
    return stock?.quantity ?? 0.0;
  }

  List<Map<String, dynamic>> _getProductsByStore(int storeId) {
    final warehouse = _warehouses.where((w) => w.storeId == storeId).firstOrNull;
    if (warehouse == null) return [];

    final storeStocks = _stocks.where((s) => s.warehouseId == warehouse.id && s.quantity > 0).toList();
    
    return storeStocks.map((stock) {
      final product = _products.firstWhere((p) => p.id == stock.productId);
      return {
        'product': product,
        'stock': stock.quantity,
      };
    }).toList()..sort((a, b) => (a['product'] as Product).name.compareTo((b['product'] as Product).name));
  }

  List<Product> _getLowStockProducts() {
    return _products.where((product) {
      final totalStock = _getTotalProductStock(product.id);
      return totalStock <= product.minStock && product.isActive;
    }).toList();
  }

  double _calculateTotalInventoryValue() {
    return _products
        .where((product) => product.isActive)
        .fold(0.0, (sum, product) {
          final totalStock = _getTotalProductStock(product.id);
          return sum + (totalStock * product.salePrice);
        });
  }

  double _calculateStoreInventoryValue(int storeId) {
    final storeProducts = _getProductsByStore(storeId);
    return storeProducts.fold(0.0, (sum, productStock) {
      final product = productStock['product'] as Product;
      final stock = productStock['stock'] as double;
      return sum + (stock * product.salePrice);
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================================
  // ACTION HANDLERS
  // ============================================================================

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showEditProductDialog(product);
        break;
      case 'price':
        _showEditPriceDialog(product);
        break;
      case 'stock':
        _showManageStockDialog(product);
        break;
      case 'delete':
        _showDeleteProductDialog(product);
        break;
    }
  }

  void _handleCategoryAction(String action, ProductCategory category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'activate':
      case 'deactivate':
        _toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
  }

  // ============================================================================
  // DIALOGS - PLACEHOLDERS (implementar según necesidades)
  // ============================================================================

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        database: widget.database,
        categories: _categories,
        onProductSaved: _loadData,
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        database: widget.database,
        onCategorySaved: _loadData,
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        database: widget.database,
        categories: _categories,
        product: product,
        onProductSaved: _loadData,
      ),
    );
  }

  void _showEditCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        database: widget.database,
        category: category,
        onCategorySaved: _loadData,
      ),
    );
  }

  void _showEditPriceDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Precio - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Precio actual: BS/ ${product.salePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('IMPORTANTE: El precio se aplicará a TODAS las sucursales'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nuevo Precio',
                prefixText: 'BS/ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                final newPrice = double.tryParse(value);
                if (newPrice != null && newPrice > 0) {
                  _updateProductPrice(product, newPrice);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showEditStockDialog(Product product, Store store) {
    final currentStock = _getProductStockByStore(product.id, store.id);
    final controller = TextEditingController(text: currentStock.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sucursal: ${store.name}'),
            Text('Stock actual: ${currentStock.toStringAsFixed(0)} ${product.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nuevo Stock',
                suffixText: product.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = double.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                _updateProductStock(product, store, newStock);
                Navigator.pop(context);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showManageStockDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Gestionar Stock - ${product.name}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text('Gestión de stock por sucursal para: ${product.name}'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _stores.length,
                  itemBuilder: (context, index) {
                    final store = _stores[index];
                    final currentStock = _getProductStockByStore(product.id, store.id);
                    
                    return Card(
                      child: ListTile(
                        title: Text(store.name),
                        subtitle: Text('Stock actual: ${currentStock.toStringAsFixed(0)} ${product.unit}'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditStockDialog(product, store);
                          },
                          child: const Text('Editar'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(Product product) {
    final quantityController = TextEditingController();
    int? selectedStoreId;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reabastecer - ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock mínimo: ${product.minStock.toStringAsFixed(0)}'),
              Text('Stock actual total: ${_getTotalProductStock(product.id).toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: selectedStoreId,
                decoration: const InputDecoration(
                  labelText: 'Sucursal',
                  border: OutlineInputBorder(),
                ),
                items: _stores.map((store) => DropdownMenuItem<int?>(
                  value: store.id,
                  child: Text(store.name),
                )).toList(),
                onChanged: (value) => setDialogState(() => selectedStoreId = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Cantidad a agregar',
                  suffixText: product.unit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStoreId != null) {
                  final quantity = double.tryParse(quantityController.text);
                  if (quantity != null && quantity > 0) {
                    final store = _stores.firstWhere((s) => s.id == selectedStoreId);
                    final currentStock = _getProductStockByStore(product.id, store.id);
                    _updateProductStock(product, store, currentStock + quantity);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Agregar Stock'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que deseas eliminar el producto "${product.name}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _deleteProduct(product),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que deseas eliminar la categoría "${category.name}"?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _deleteCategory(category),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  Future<void> _updateProductPrice(Product product, double newPrice) async {
    try {
      await (widget.database.update(widget.database.products)
        ..where((p) => p.id.equals(product.id))).write(
        ProductsCompanion(
          salePrice: drift.Value(newPrice),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      _showSuccessSnackBar('Precio actualizado en todas las sucursales: BS/ ${newPrice.toStringAsFixed(2)}');
      await _loadData();
    } catch (e) {
      print('❌ Error actualizando precio: $e');
      _showErrorSnackBar('Error al actualizar precio: $e');
    }
  }

  Future<void> _updateProductStock(Product product, Store store, double newStock) async {
    try {
      final warehouse = _warehouses.where((w) => w.storeId == store.id).firstOrNull;
      if (warehouse == null) {
        _showErrorSnackBar('No se encontró almacén para la sucursal');
        return;
      }

      print('🔄 Actualizando stock: Producto ${product.id}, Almacén ${warehouse.id}, Nuevo stock: $newStock');

      // Usar insertOnConflictUpdate para crear o actualizar el registro
      await widget.database.into(widget.database.stocks).insertOnConflictUpdate(
        StocksCompanion(
          productId: drift.Value(product.id),
          warehouseId: drift.Value(warehouse.id),
          quantity: drift.Value(newStock),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      print('✅ Stock actualizado exitosamente');
      _showSuccessSnackBar('Stock actualizado: ${newStock.toStringAsFixed(0)} ${product.unit}');
      await _loadData();
    } catch (e) {
      print('❌ Error actualizando stock: $e');
      _showErrorSnackBar('Error al actualizar stock: $e');
    }
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      Navigator.pop(context); // Cerrar diálogo
      
      // Eliminar stocks del producto
      await (widget.database.delete(widget.database.stocks)
        ..where((s) => s.productId.equals(product.id))).go();
      
      // Eliminar producto
      await (widget.database.delete(widget.database.products)
        ..where((p) => p.id.equals(product.id))).go();
      
      _showSuccessSnackBar('Producto eliminado exitosamente');
      await _loadData();
    } catch (e) {
      print('❌ Error eliminando producto: $e');
      _showErrorSnackBar('Error al eliminar producto: $e');
    }
  }

  Future<void> _deleteCategory(ProductCategory category) async {
    try {
      Navigator.pop(context); // Cerrar diálogo
      
      // Eliminar categoría
      await (widget.database.delete(widget.database.productCategories)
        ..where((c) => c.id.equals(category.id))).go();
      
      _showSuccessSnackBar('Categoría eliminada exitosamente');
      await _loadData();
    } catch (e) {
      print('❌ Error eliminando categoría: $e');
      _showErrorSnackBar('Error al eliminar categoría: $e');
    }
  }

  Future<void> _toggleCategoryStatus(ProductCategory category) async {
    try {
      await (widget.database.update(widget.database.productCategories)
        ..where((c) => c.id.equals(category.id))).write(
        ProductCategoriesCompanion(
          isActive: drift.Value(!category.isActive),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      _showSuccessSnackBar('Estado de categoría actualizado');
      await _loadData();
    } catch (e) {
      print('❌ Error actualizando categoría: $e');
      _showErrorSnackBar('Error al actualizar categoría: $e');
    }
  }
}