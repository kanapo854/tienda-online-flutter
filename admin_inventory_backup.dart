/*import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/local_database.dart';
import '../../models/user_role.dart';
import '../../services/role_based_auth_service.dart';

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
      final categories = await widget.database.getAllProductCategories();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Inventario'),
        backgroundColor: UserRole.adminInventory.color,
        foregroundColor: Colors.white,
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
            Row(
              children: [
                Text('Precio: S/ ${product.salePrice.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
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
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar productos, tiendas, almacenes y stocks
      final products = await widget.database.getAllProducts();
      final stores = await widget.database.getAllStores();
      final warehouses = await widget.database.getAllWarehouses();
      final stocks = await widget.database.getAllStocks();
      
      setState(() {
        _products = products;
        _stores = stores;
        _warehouses = warehouses;
        _stocks = stocks;
        _isLoading = false;
      });
      
      print('=== DATOS DE INVENTARIO CARGADOS ===');
      print('Productos: ${_products.length}');
      print('Tiendas: ${_stores.length}');
      print('Almacenes: ${_warehouses.length}');
      print('Stocks: ${_stocks.length}');
      
    } catch (e) {
      print('Error cargando datos de inventario: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesSearch = _searchText.isEmpty ||
          product.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchText.toLowerCase()) ||
          (product.description?.toLowerCase().contains(_searchText.toLowerCase()) ?? false);

      return matchesSearch;
    }).toList();

    // Ordenar por nombre
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  double _getProductStock(int productId, int storeId) {
    // Buscar almacén de la tienda
    final warehouse = _warehouses.where((w) => w.storeId == storeId).firstOrNull;
    if (warehouse == null) return 0.0;
    
    final stock = _stocks.where((s) => 
      s.productId == productId && s.warehouseId == warehouse.id
    ).firstOrNull;
    return stock?.quantity ?? 0.0;
  }

  String _getStoreName(int storeId) {
    final store = _stores.where((s) => s.id == storeId).firstOrNull;
    return store?.name ?? 'Tienda no encontrada';
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      print('=== CREANDO PRODUCTO ===');
      print('Nombre: ${_nameController.text}');
      print('Precio: ${_priceController.text}');
      print('SKU: ${_skuController.text}');

      // Crear el producto
      final productId = await widget.database.into(widget.database.products).insert(
        ProductsCompanion.insert(
          categoryId: 1, // Categoría por defecto
          name: _nameController.text.trim(),
          sku: _skuController.text.trim(),
          description: drift.Value(_descriptionController.text.trim()),
          salePrice: double.parse(_priceController.text),
          purchasePrice: double.parse(_priceController.text) * 0.7, // 30% de margen por defecto
          unit: 'unidad',
        ),
      );

      // Crear stock inicial en todos los almacenes (cantidad 0)
      for (final warehouse in _warehouses) {
        await widget.database.into(widget.database.stocks).insert(
          StocksCompanion.insert(
            productId: productId,
            warehouseId: warehouse.id,
            quantity: drift.Value(0.0),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto creado exitosamente en todas las sucursales'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        _clearForm();
        await _loadData();
      }
      
    } catch (e) {
      print('Error creando producto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _skuController.clear();
  }

  void _showCreateProductDialog() {
    _clearForm();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Producto'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta (S/) *',
                      border: OutlineInputBorder(),
                      prefixText: 'S/ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Campo requerido';
                      if (double.tryParse(value!) == null) return 'Precio inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (Código) *',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: PROD001',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'IMPORTANTE: El precio será el mismo en todas las sucursales. El inventario inicial será 0.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _createProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: UserRole.adminInventory.color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crear Producto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Inventarios'),
        backgroundColor: UserRole.adminInventory.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Productos'),
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
                _buildByStoreTab(),
                _buildReportsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateProductDialog,
              backgroundColor: UserRole.adminInventory.color,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Producto'),
            )
          : null,
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar productos...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total productos: ${_filteredProducts.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Precios únicos en todas las sucursales',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de productos
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron productos',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: UserRole.adminInventory.color,
          child: Text(
            product.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'S/ ${product.salePrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.lock, size: 14, color: Colors.orange[600]),
                Text(
                  ' Precio único',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.description?.isNotEmpty == true) ...[
                  const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.description!),
                  const SizedBox(height: 16),
                ],
                const Text('Stock por sucursal:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._stores.map((store) {
                  final stock = _getProductStock(product.id, store.id);
                  final isLowStock = stock < 10;
                  
                  return ListTile(
                    leading: Icon(
                      Icons.store,
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                    title: Text(store.name),
                    subtitle: Text('Stock: ${stock.toStringAsFixed(1)} unidades'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLowStock ? Colors.red : Colors.green,
                        ),
                      ),
                      child: Text(
                        isLowStock ? 'Stock Bajo' : 'Stock OK',
                        style: TextStyle(
                          color: isLowStock ? Colors.red[700] : Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByStoreTab() {
    return ListView.builder(
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        final warehouse = _warehouses.where((w) => w.storeId == store.id).firstOrNull;
        final storeStocks = warehouse != null 
            ? _stocks.where((s) => s.warehouseId == warehouse.id).toList()
            : <Stock>[];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: UserRole.adminInventory.color,
              child: Text(
                store.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              store.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${storeStocks.length} productos'),
            children: storeStocks.map((stock) {
              final product = _products.firstWhere((p) => p.id == stock.productId);
              final isLowStock = stock.quantity < 10;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLowStock ? Colors.red : Colors.green,
                  child: Text(
                    product.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SKU: ${product.sku}'),
                    Text('Precio: S/ ${product.salePrice.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    '${stock.quantity.toStringAsFixed(1)} unidades',
                    style: TextStyle(
                      color: isLowStock ? Colors.red[700] : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    // Calcular estadísticas
    final totalProducts = _products.length;
    final totalStock = _stocks.fold<double>(0, (sum, s) => sum + s.quantity);
    final lowStockItems = _stocks.where((s) => s.quantity < 10).length;
    final outOfStockItems = _stocks.where((s) => s.quantity == 0).length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Mensaje importante sobre precios
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.orange[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Política de Precios Unificados',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Todos los productos mantienen el mismo precio en todas las sucursales. Solo el inventario puede variar por ubicación.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Productos',
                  totalProducts.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Stock Total',
                  totalStock.toStringAsFixed(0),
                  Icons.storage,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Stock Bajo',
                  lowStockItems.toString(),
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Sin Stock',
                  outOfStockItems.toString(),
                  Icons.error,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                    final product = _products.firstWhere((p) => p.id == productStock['product'].id);
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
                            Text('Precio: S/ ${product.salePrice.toStringAsFixed(2)}'),
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
              Expanded(child: _buildStatCard('Valor Total', 'S/ ${totalValue.toStringAsFixed(2)}', Icons.attach_money, Colors.orange)),
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
                subtitle: Text('${storeProducts.length} productos - Valor: S/ ${storeValue.toStringAsFixed(2)}'),
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
  // DIALOGS
  // ============================================================================

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        database: widget.database,
        categories: _categories,
        onProductCreated: _loadData,
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        database: widget.database,
        onCategoryCreated: _loadData,
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(
        database: widget.database,
        categories: _categories,
        product: product,
        onProductCreated: _loadData,
      ),
    );
  }

  void _showEditCategoryDialog(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        database: widget.database,
        category: category,
        onCategoryCreated: _loadData,
      ),
    );
  }

  void _showEditPriceDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _PriceEditDialog(
        database: widget.database,
        product: product,
        onPriceUpdated: _loadData,
      ),
    );
  }

  void _showEditStockDialog(Product product, Store store) {
    final warehouse = _warehouses.where((w) => w.storeId == store.id).firstOrNull;
    if (warehouse == null) {
      _showErrorSnackBar('No se encontró almacén para la sucursal ${store.name}');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _StockEditDialog(
        database: widget.database,
        product: product,
        warehouse: warehouse,
        store: store,
        onStockUpdated: _loadData,
      ),
    );
  }

  void _showManageStockDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _StockManagementDialog(
        database: widget.database,
        product: product,
        stores: _stores,
        warehouses: _warehouses,
        stocks: _stocks,
        onStockUpdated: _loadData,
      ),
    );
  }

  void _showQuickRestockDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => _QuickRestockDialog(
        database: widget.database,
        product: product,
        stores: _stores,
        warehouses: _warehouses,
        onStockUpdated: _loadData,
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
}*/