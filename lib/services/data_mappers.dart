import '../database/local_database.dart';

/// Mappers para convertir entre modelos de Drift y JSON de Supabase
/// Esto permite sincronizar datos entre la base de datos local y Supabase

class DataMappers {
  // ==================== PRODUCT MAPPERS ====================
  
  /// Convertir Product de Drift a JSON para Supabase
  static Map<String, dynamic> productToJson(Product product) {
    return {
      'id': product.id,
      'category_id': product.categoryId,
      'name': product.name,
      'sku': product.sku,
      'barcode': product.barcode,
      'description': product.description,
      'brand': product.brand,
      'model': product.model,
      'purchase_price': product.purchasePrice,
      'sale_price': product.salePrice,
      'unit': product.unit,
      'min_stock': product.minStock,
      'max_stock': product.maxStock,
      'image_urls': product.imageUrls,
      'specifications': product.specifications,
      'supplier': product.supplier,
      'is_active': product.isActive,
      'created_at': product.createdAt.toIso8601String(),
      'updated_at': product.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a Product de Drift
  static Product productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      salePrice: (json['sale_price'] as num).toDouble(),
      unit: json['unit'] as String,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0.0,
      maxStock: (json['max_stock'] as num?)?.toDouble(),
      imageUrls: json['image_urls'] as String?,
      specifications: json['specifications'] as String?,
      supplier: json['supplier'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== STOCK MAPPERS ====================
  
  /// Convertir Stock de Drift a JSON para Supabase
  static Map<String, dynamic> stockToJson(Stock stock) {
    return {
      'product_id': stock.productId,
      'warehouse_id': stock.warehouseId,
      'quantity': stock.quantity,
      'reserved_quantity': stock.reservedQuantity,
      'last_movement_at': stock.lastMovementAt?.toIso8601String(),
      'updated_at': stock.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a Stock de Drift
  static Stock stockFromJson(Map<String, dynamic> json) {
    return Stock(
      productId: json['product_id'] as int,
      warehouseId: json['warehouse_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      reservedQuantity: (json['reserved_quantity'] as num?)?.toDouble() ?? 0.0,
      lastMovementAt: json['last_movement_at'] != null
          ? DateTime.parse(json['last_movement_at'] as String)
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== SALE MAPPERS ====================
  
  /// Convertir Sale de Drift a JSON para Supabase
  static Map<String, dynamic> saleToJson(Sale sale) {
    return {
      'id': sale.id,
      'store_id': sale.storeId,
      'customer_id': sale.customerId,
      'employee_id': sale.employeeId,
      'sale_number': sale.saleNumber,
      'sale_date': sale.saleDate.toIso8601String(),
      'subtotal': sale.subtotal,
      'tax_amount': sale.taxAmount,
      'discount_amount': sale.discountAmount,
      'total_amount': sale.totalAmount,
      'sale_status': sale.saleStatus,
      'payment_method': sale.paymentMethod,
      'payment_status': sale.paymentStatus,
      'notes': sale.notes,
      'invoice_number': sale.invoiceNumber,
      'created_at': sale.createdAt.toIso8601String(),
      'updated_at': sale.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a Sale de Drift
  static Sale saleFromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as int,
      storeId: json['store_id'] as int,
      customerId: json['customer_id'] as int,
      employeeId: json['employee_id'] as int,
      saleNumber: json['sale_number'] as String,
      saleDate: DateTime.parse(json['sale_date'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      saleStatus: json['sale_status'] as String,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      notes: json['notes'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== CATEGORY MAPPERS ====================
  
  /// Convertir ProductCategory de Drift a JSON para Supabase
  static Map<String, dynamic> categoryToJson(ProductCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'code': category.code,
      'description': category.description,
      'parent_id': category.parentId,
      'is_active': category.isActive,
      'created_at': category.createdAt.toIso8601String(),
      'updated_at': category.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a ProductCategory de Drift
  static ProductCategory categoryFromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== CUSTOMER MAPPERS ====================
  
  /// Convertir Customer de Drift a JSON para Supabase
  static Map<String, dynamic> customerToJson(Customer customer) {
    return {
      'id': customer.id,
      'first_name': customer.firstName,
      'last_name': customer.lastName,
      'email': customer.email,
      'phone': customer.phone,
      'document_type': customer.documentType,
      'document_number': customer.documentNumber,
      'address': customer.address,
      'city': customer.city,
      'customer_type': customer.customerType,
      'company_name': customer.companyName,
      'credit_limit': customer.creditLimit,
      'is_active': customer.isActive,
      'created_at': customer.createdAt.toIso8601String(),
      'updated_at': customer.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a Customer de Drift
  static Customer customerFromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      customerType: json['customer_type'] as String,
      companyName: json['company_name'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== EMPLOYEE MAPPERS ====================
  
  /// Convertir Employee de Drift a JSON para Supabase (sin password)
  static Map<String, dynamic> employeeToJson(Employee employee, {bool includePassword = false}) {
    final json = {
      'id': employee.id,
      'company_id': employee.companyId,
      'store_id': employee.storeId,
      'warehouse_id': employee.warehouseId,
      'first_name': employee.firstName,
      'last_name': employee.lastName,
      'email': employee.email,
      'phone': employee.phone,
      'document_type': employee.documentType,
      'document_number': employee.documentNumber,
      'role': employee.role,
      'last_login': employee.lastLogin?.toIso8601String(),
      'is_active': employee.isActive,
      'created_at': employee.createdAt.toIso8601String(),
      'updated_at': employee.updatedAt.toIso8601String(),
    };

    // Solo incluir password si es necesario (generalmente NO)
    if (includePassword) {
      json['password_hash'] = employee.passwordHash;
      json['salt'] = employee.salt;
    }

    return json;
  }

  /// Convertir JSON de Supabase a Employee de Drift
  static Employee employeeFromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      storeId: json['store_id'] as int?,
      warehouseId: json['warehouse_id'] as int?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String,
      role: json['role'] as String,
      passwordHash: json['password_hash'] as String? ?? '',
      salt: json['salt'] as String? ?? '',
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }

  // ==================== WAREHOUSE MAPPERS ====================
  
  /// Convertir Warehouse de Drift a JSON para Supabase
  static Map<String, dynamic> warehouseToJson(Warehouse warehouse) {
    return {
      'id': warehouse.id,
      'company_id': warehouse.companyId,
      'store_id': warehouse.storeId,
      'name': warehouse.name,
      'code': warehouse.code,
      'address': warehouse.address,
      'warehouse_type': warehouse.warehouseType,
      'is_active': warehouse.isActive,
      'created_at': warehouse.createdAt.toIso8601String(),
      'updated_at': warehouse.updatedAt.toIso8601String(),
    };
  }

  /// Convertir JSON de Supabase a Warehouse de Drift
  static Warehouse warehouseFromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      storeId: json['store_id'] as int?,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      warehouseType: json['warehouse_type'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      needsSync: false,
      lastSyncAt: DateTime.now(),
    );
  }
}
