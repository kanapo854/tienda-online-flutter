import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/local_database.dart';

// ============================================================================
// DIÁLOGO PARA CREAR/EDITAR PRODUCTOS
// ============================================================================

class ProductFormDialog extends StatefulWidget {
  final LocalDatabase database;
  final List<ProductCategory> categories;
  final Product? product; // null para crear, product para editar
  final VoidCallback onProductSaved;

  const ProductFormDialog({
    Key? key,
    required this.database,
    required this.categories,
    this.product,
    required this.onProductSaved,
  }) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  
  int? _selectedCategoryId;
  String _selectedUnit = 'unidad';
  bool _isLoading = false;

  final List<String> _units = [
    'unidad', 'caja', 'metro', 'metro2', 'rollo', 'kg', 'litro', 'galón'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _skuController.text = product.sku;
    _descriptionController.text = product.description ?? '';
    _brandController.text = product.brand ?? '';
    _modelController.text = product.model ?? '';
    _salePriceController.text = product.salePrice.toString();
    _purchasePriceController.text = product.purchasePrice.toString();
    _minStockController.text = product.minStock.toString();
    _maxStockController.text = product.maxStock?.toString() ?? '';
    _barcodeController.text = product.barcode ?? '';
    _selectedCategoryId = product.categoryId;
    _selectedUnit = product.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información básica
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Información Básica', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Producto *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _skuController,
                                decoration: const InputDecoration(
                                  labelText: 'SKU *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El SKU es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _barcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Código de Barras',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int?>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría *',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.categories.map((category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedCategoryId = value),
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona una categoría';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Detalles del producto
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detalles del Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _brandController,
                                decoration: const InputDecoration(
                                  labelText: 'Marca',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(
                                  labelText: 'Modelo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unidad de Medida *',
                            border: OutlineInputBorder(),
                          ),
                          items: _units.map((unit) => DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedUnit = value!),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Precios y stock
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Precios y Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _purchasePriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Precio de Compra *',
                                  prefixText: 'S/ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Precio obligatorio';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Precio inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _salePriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Precio de Venta *',
                                  prefixText: 'S/ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Precio obligatorio';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Precio inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _minStockController,
                                decoration: const InputDecoration(
                                  labelText: 'Stock Mínimo *',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Stock mínimo obligatorio';
                                  }
                                  final stock = double.tryParse(value);
                                  if (stock == null || stock < 0) {
                                    return 'Stock inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _maxStockController,
                                decoration: const InputDecoration(
                                  labelText: 'Stock Máximo',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final stock = double.tryParse(value);
                                    if (stock == null || stock < 0) {
                                      return 'Stock inválido';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.product == null ? 'Crear' : 'Actualizar'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final purchasePrice = double.parse(_purchasePriceController.text);
      final salePrice = double.parse(_salePriceController.text);
      final minStock = double.parse(_minStockController.text);
      final maxStock = _maxStockController.text.isNotEmpty ? double.parse(_maxStockController.text) : null;

      if (widget.product == null) {
        // Crear nuevo producto
        await widget.database.into(widget.database.products).insert(
          ProductsCompanion.insert(
            categoryId: _selectedCategoryId!,
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
            brand: drift.Value(_brandController.text.trim().isEmpty ? null : _brandController.text.trim()),
            model: drift.Value(_modelController.text.trim().isEmpty ? null : _modelController.text.trim()),
            purchasePrice: purchasePrice,
            salePrice: salePrice,
            unit: _selectedUnit,
            minStock: drift.Value(minStock),
            maxStock: drift.Value(maxStock),
            barcode: drift.Value(_barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim()),
          ),
        );
      } else {
        // Actualizar producto existente
        await (widget.database.update(widget.database.products)
          ..where((p) => p.id.equals(widget.product!.id))).write(
          ProductsCompanion(
            categoryId: drift.Value(_selectedCategoryId!),
            name: drift.Value(_nameController.text.trim()),
            sku: drift.Value(_skuController.text.trim()),
            description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
            brand: drift.Value(_brandController.text.trim().isEmpty ? null : _brandController.text.trim()),
            model: drift.Value(_modelController.text.trim().isEmpty ? null : _modelController.text.trim()),
            purchasePrice: drift.Value(purchasePrice),
            salePrice: drift.Value(salePrice),
            unit: drift.Value(_selectedUnit),
            minStock: drift.Value(minStock),
            maxStock: drift.Value(maxStock),
            barcode: drift.Value(_barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      widget.onProductSaved();
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error guardando producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar producto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// ============================================================================
// DIÁLOGO PARA CREAR/EDITAR CATEGORÍAS
// ============================================================================

class CategoryFormDialog extends StatefulWidget {
  final LocalDatabase database;
  final ProductCategory? category; // null para crear, category para editar
  final VoidCallback onCategorySaved;

  const CategoryFormDialog({
    Key? key,
    required this.database,
    this.category,
    required this.onCategorySaved,
  }) : super(key: key);

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final category = widget.category!;
    _nameController.text = category.name;
    _codeController.text = category.code;
    _descriptionController.text = category.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nueva Categoría' : 'Editar Categoría'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Categoría *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Código *',
                border: OutlineInputBorder(),
                helperText: 'Código único para la categoría',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El código es obligatorio';
                }
                return null;
              },
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.category == null ? 'Crear' : 'Actualizar'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.category == null) {
        // Crear nueva categoría
        await widget.database.into(widget.database.productCategories).insert(
          ProductCategoriesCompanion.insert(
            name: _nameController.text.trim(),
            code: _codeController.text.trim(),
            description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
          ),
        );
      } else {
        // Actualizar categoría existente
        await (widget.database.update(widget.database.productCategories)
          ..where((c) => c.id.equals(widget.category!.id))).write(
          ProductCategoriesCompanion(
            name: drift.Value(_nameController.text.trim()),
            code: drift.Value(_codeController.text.trim()),
            description: drift.Value(_descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim()),
            updatedAt: drift.Value(DateTime.now()),
          ),
        );
      }

      widget.onCategorySaved();
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error guardando categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar categoría: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}