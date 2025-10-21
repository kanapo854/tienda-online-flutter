import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/local_database.dart';
import '../screens/customer/customer_dashboard.dart';

/// Widget de tarjeta de producto para mostrar en la tienda
class ProductCard extends StatelessWidget {
  final Product product;
  final List<Store> stores;
  final Map<int, List<Stock>> stocksByStore;
  final Store? selectedStore;
  final bool isOffer;
  final Function(int productId, int storeId, double quantity) onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.stores,
    required this.stocksByStore,
    this.selectedStore,
    this.isOffer = false,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtener tiendas que tienen stock de este producto
    final storesWithStock = _getStoresWithStock();
    final hasStock = storesWithStock.isNotEmpty;
    final totalStock = _getTotalStock();

    return Card(
      elevation: isOffer ? 8 : 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                      if (isOffer)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OFERTA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (!hasStock)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black54,
                          child: const Center(
                            child: Text(
                              'SIN STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Información del producto
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Marca si está disponible
                      if (product.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.brand!,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const Spacer(),
                      
                      // Precio
                      Text(
                        '\$${_formatPrice(product.salePrice)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOffer ? Colors.orange : Colors.green[700],
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      // Información de stock
                      if (hasStock) 
                        Text(
                          storesWithStock.length == 1 
                            ? '${totalStock.toInt()} disponibles' 
                            : '${totalStock.toInt()} en ${storesWithStock.length} tienda(s)',
                          style: TextStyle(
                            fontSize: 8,
                            color: totalStock > 10 ? Colors.green[600] : 
                                   totalStock > 3 ? Colors.orange[600] : Colors.red[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Sin stock',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 6),
                      
                      // Botón de agregar al carrito
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: hasStock ? () => _showAddToCartDialog(context) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasStock ? 
                              (isOffer ? Colors.orange : Colors.blue) : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            textStyle: const TextStyle(fontSize: 9),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              hasStock ? 'Agregar' : 'Sin Stock',
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Store> _getStoresWithStock() {
    final storesWithStock = <Store>[];
    
    for (final store in stores) {
      final storeStock = stocksByStore[store.id];
      final hasProductStock = storeStock?.any(
        (stock) => stock.productId == product.id && stock.quantity > 0,
      ) ?? false;
      
      if (hasProductStock) {
        storesWithStock.add(store);
      }
    }
    
    return storesWithStock;
  }

  double _getTotalStock() {
    double total = 0.0;
    
    for (final store in stores) {
      final storeStock = stocksByStore[store.id];
      if (storeStock != null) {
        try {
          final productStock = storeStock.firstWhere(
            (stock) => stock.productId == product.id,
          );
          
          if (productStock.quantity > 0) {
            total += productStock.quantity;
          }
        } catch (e) {
          // No stock found for this product in this store
          continue;
        }
      }
    }
    
    return total;
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showAddToCartDialog(BuildContext context) {
    final storesWithStock = _getStoresWithStock();
    
    showDialog(
      context: context,
      builder: (context) => AddToCartDialog(
        product: product,
        storesWithStock: storesWithStock,
        stocksByStore: stocksByStore,
        selectedStore: selectedStore,
        onAddToCart: onAddToCart,
      ),
    );
  }
}

/// Diálogo para agregar productos al carrito
class AddToCartDialog extends StatefulWidget {
  final Product product;
  final List<Store> storesWithStock;
  final Map<int, List<Stock>> stocksByStore;
  final Store? selectedStore;
  final Function(int productId, int storeId, double quantity) onAddToCart;

  const AddToCartDialog({
    Key? key,
    required this.product,
    required this.storesWithStock,
    required this.stocksByStore,
    this.selectedStore,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  late Store _selectedStore;
  double _quantity = 1;
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    // Seleccionar la primera tienda disponible o la preseleccionada
    _selectedStore = widget.selectedStore ?? widget.storesWithStock.first;
  }

  @override
  Widget build(BuildContext context) {
    final maxStock = _getMaxStockForStore(_selectedStore);
    
    return AlertDialog(
      title: Text('Agregar ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del producto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (widget.product.brand != null)
                        Text(
                          widget.product.brand!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        '\$${_formatPrice(widget.product.salePrice)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selección de tienda
          if (widget.storesWithStock.length > 1) ...[
            const Text('Tienda:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Store>(
              value: _selectedStore,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: widget.storesWithStock.map((store) {
                final stock = _getMaxStockForStore(store);
                return DropdownMenuItem(
                  value: store,
                  child: Text(
                    '${store.name} ($stock disponibles)',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (store) {
                if (store != null) {
                  setState(() {
                    _selectedStore = store;
                    // Ajustar cantidad si excede el stock de la nueva tienda
                    final newMaxStock = _getMaxStockForStore(store);
                    if (_quantity > newMaxStock) {
                      _quantity = newMaxStock;
                      _quantityController.text = _quantity.toString();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          
          // Cantidad
          const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Botón decrementar
              IconButton(
                onPressed: _quantity > 1 ? () {
                  setState(() {
                    _quantity--;
                    _quantityController.text = _quantity.toString();
                  });
                } : null,
                icon: const Icon(Icons.remove),
              ),
              
              // Campo de cantidad
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final newQuantity = double.tryParse(value) ?? 1;
                    if (newQuantity >= 1 && newQuantity <= maxStock) {
                      setState(() => _quantity = newQuantity);
                    }
                  },
                ),
              ),
              
              // Botón incrementar
              IconButton(
                onPressed: _quantity < maxStock ? () {
                  setState(() {
                    _quantity++;
                    _quantityController.text = _quantity.toString();
                  });
                } : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          
          Text(
            'Disponible: ${maxStock.toInt()} unidades',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: \$${_formatPrice(_quantity * widget.product.salePrice)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAddToCart(widget.product.id, _selectedStore.id, _quantity);
            Navigator.of(context).pop();
          },
          child: const Text('Agregar al Carrito'),
        ),
      ],
    );
  }

  double _getMaxStockForStore(Store store) {
    final storeStock = widget.stocksByStore[store.id];
    final productStock = storeStock?.firstWhere(
      (stock) => stock.productId == widget.product.id,
      orElse: () => Stock(
        productId: widget.product.id,
        warehouseId: 1,
        quantity: 0,
        reservedQuantity: 0,
        lastMovementAt: null,
        updatedAt: DateTime.now(),
        needsSync: false,
        lastSyncAt: null,
      ),
    );
    
    return productStock?.quantity ?? 0;
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Diálogo del carrito de compras
class CartDialog extends StatelessWidget {
  final Map<String, CartItem> cartItems;
  final Function(String key, double quantity) onUpdateQuantity;
  final VoidCallback onCheckout;
  final VoidCallback onClearCart;

  const CartDialog({
    Key? key,
    required this.cartItems,
    required this.onUpdateQuantity,
    required this.onCheckout,
    required this.onClearCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalValue = cartItems.values.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    
    return Dialog(
      child: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Título
              Row(
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Mi Carrito',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const Divider(),
              
              // Lista de items
              if (cartItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tu carrito está vacío',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Agrega productos para comenzar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final key = cartItems.keys.elementAt(index);
                      final item = cartItems.values.elementAt(index);
                      
                      return CartItemCard(
                        item: item,
                        onUpdateQuantity: (quantity) => onUpdateQuantity(key, quantity),
                        onRemove: () => onUpdateQuantity(key, 0),
                      );
                    },
                  ),
                ),
                
                const Divider(),
                
                // Total y botones
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_formatPrice(totalValue)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showClearCartConfirmation(context),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Vaciar Carrito'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: onCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Realizar Pedido'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Vaciar Carrito'),
        content: const Text(
          '¿Estás seguro de que quieres vaciar todo el carrito?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar confirmación
              onClearCart(); // Ejecutar acción
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, vaciar'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Tarjeta individual de item en el carrito
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(double) onUpdateQuantity;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen del producto
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            
            const SizedBox(width: 12),
            
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.product.brand != null)
                    Text(
                      item.product.brand!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    'Tienda: ${item.store.name}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_formatPrice(item.unitPrice)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            // Controles de cantidad
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1 
                        ? () => onUpdateQuantity(item.quantity - 1)
                        : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity.toInt()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onUpdateQuantity(item.quantity + 1),
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Subtotal
                Text(
                  '\$${_formatPrice(item.totalPrice)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Botón eliminar
                TextButton(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}