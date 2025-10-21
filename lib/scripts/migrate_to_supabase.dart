import 'package:flutter/material.dart';
import '../database/local_database.dart';
import '../services/data_mappers.dart';
import '../config/supabase_config.dart';

/// Script para migrar datos de la base de datos local a Supabase
/// 
/// USO:
/// 1. Ejecuta la app
/// 2. En cualquier pantalla, llama: await migrateAllDataToSupabase(context);
/// 3. O agrega un botón temporal en alguna pantalla

class MigrationService {
  final LocalDatabase _localDb;
  
  MigrationService(this._localDb);

  /// Migrar TODOS los datos a Supabase
  Future<MigrationResult> migrateAllData() async {
    final result = MigrationResult();
    
    try {
      print('🚀 Iniciando migración a Supabase...');
      
      // Verificar que Supabase esté disponible
      final supabase = SupabaseConfig.client;
      
      // 1. Migrar Compañías
      print('📦 Migrando compañías...');
      await _migrateCompanies(supabase, result);
      
      // 2. Migrar Stores (crear store por defecto si no existe en local)
      print('📦 Migrando stores...');
      await _migrateStores(supabase, result);
      
      // 3. Migrar Categorías
      print('📦 Migrando categorías...');
      await _migrateCategories(supabase, result);
      
      // 4. Migrar Productos
      print('📦 Migrando productos...');
      await _migrateProducts(supabase, result);
      
      // 5. Migrar Almacenes
      print('📦 Migrando almacenes...');
      await _migrateWarehouses(supabase, result);
      
      // 5. Migrar Stock
      print('📦 Migrando stock...');
      await _migrateStocks(supabase, result);
      
      // 6. Migrar Clientes
      print('📦 Migrando clientes...');
      await _migrateCustomers(supabase, result);
      
      // 7. Migrar Empleados
      print('📦 Migrando empleados...');
      await _migrateEmployees(supabase, result);
      
      // 8. Migrar Ventas
      print('📦 Migrando ventas...');
      await _migrateSales(supabase, result);
      
      print('');
      print('✅ ¡Migración completada!');
      result.printSummary();
      
      return result;
    } catch (e) {
      print('❌ Error en migración: $e');
      result.addError('Error general', e.toString());
      return result;
    }
  }

  Future<void> _migrateCompanies(dynamic supabase, MigrationResult result) async {
    try {
      final companies = await _localDb.select(_localDb.companies).get();
      print('   Encontradas ${companies.length} compañías en BD local');
      
      // FIX: Si no hay companies en local, crear una por defecto en Supabase
      if (companies.isEmpty) {
        print('   ⚠️  No hay companies en BD local, creando company por defecto en Supabase...');
        try {
          final defaultCompany = {
            'id': 1,
            'name': 'Empresa Principal',
            'ruc': '20000000001',
            'address': 'Dirección por defecto',
            'phone': '999999999',
            'email': 'contacto@empresa.com',
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          await supabase.from('companies').upsert(defaultCompany, onConflict: 'id');
          result.addSuccess('companies');
          print('      ✓ Company por defecto creada con ID=1');
        } catch (e) {
          result.addError('companies', 'No se pudo crear company por defecto: $e');
          print('      ✗ Error creando company por defecto: $e');
        }
        return;
      }
      
      for (final company in companies) {
        try {
          final json = {
            'id': company.id,
            'name': company.name,
            'ruc': company.ruc,
            'address': company.address,
            'phone': company.phone,
            'email': company.email,
            'is_active': company.isActive,
            'created_at': company.createdAt.toIso8601String(),
            'updated_at': company.updatedAt.toIso8601String(),
          };
          
          // Usar upsert con onConflict para asegurar que se actualiza si existe
          await supabase.from('companies').upsert(json, onConflict: 'id');
          result.addSuccess('companies');
          print('      ✓ Company ${company.id} migrada');
        } catch (e) {
          result.addError('companies', 'Company ${company.id}: $e');
          print('      ✗ Company ${company.id} falló: $e');
        }
      }
    } catch (e) {
      result.addError('companies', 'Error general: $e');
    }
  }

  Future<void> _migrateStores(dynamic supabase, MigrationResult result) async {
    try {
      // La BD local no tiene tabla stores, crear store por defecto en Supabase
      print('   ⚠️  BD local no tiene stores, creando store por defecto en Supabase...');
      try {
        final defaultStore = {
          'id': 1,
          'company_id': 1,
          'name': 'Tienda Principal',
          'code': 'STORE001',
          'address': 'Dirección principal',
          'city': 'Lima',
          'phone': '999999999',
          'latitude': null,
          'longitude': null,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await supabase.from('stores').upsert(defaultStore, onConflict: 'id');
        result.addSuccess('stores');
        print('      ✓ Store por defecto creada con ID=1');
      } catch (e) {
        result.addError('stores', 'No se pudo crear store por defecto: $e');
        print('      ✗ Error creando store por defecto: $e');
      }
    } catch (e) {
      result.addError('stores', 'Error general: $e');
    }
  }

  Future<void> _migrateCategories(dynamic supabase, MigrationResult result) async {
    try {
      final categories = await _localDb.select(_localDb.productCategories).get();
      print('   Encontradas ${categories.length} categorías');
      
      for (final category in categories) {
        try {
          final json = DataMappers.categoryToJson(category);
          // FIX: La tabla se llama 'product_categories' no 'categories'
          await supabase.from('product_categories').upsert(json);
          result.addSuccess('categories');
        } catch (e) {
          result.addError('categories', 'Category ${category.id}: $e');
        }
      }
    } catch (e) {
      result.addError('categories', 'Error general: $e');
    }
  }

  Future<void> _migrateProducts(dynamic supabase, MigrationResult result) async {
    try {
      final products = await _localDb.select(_localDb.products).get();
      print('   Encontrados ${products.length} productos');
      
      for (final product in products) {
        try {
          final json = DataMappers.productToJson(product);
          await supabase.from('products').upsert(json);
          result.addSuccess('products');
        } catch (e) {
          result.addError('products', 'Product ${product.id}: $e');
        }
      }
    } catch (e) {
      result.addError('products', 'Error general: $e');
    }
  }

  Future<void> _migrateWarehouses(dynamic supabase, MigrationResult result) async {
    try {
      final warehouses = await _localDb.select(_localDb.warehouses).get();
      print('   Encontrados ${warehouses.length} almacenes');
      
      for (final warehouse in warehouses) {
        try {
          final json = DataMappers.warehouseToJson(warehouse);
          
          // FIX: Si company_id es null o 0, usar 1 (company por defecto)
          if (json['company_id'] == null || json['company_id'] == 0) {
            json['company_id'] = 1;
            print('      ⚠️ Warehouse ${warehouse.id}: company_id null/0, usando company_id=1');
          }
          
          // FIX: store_id debe ser null si no existe la store
          // En Supabase, store_id es opcional (ON DELETE SET NULL)
          json['store_id'] = null;
          
          // FIX: Convertir warehouse_type a valores válidos de Supabase
          // Supabase acepta: 'central', 'store', 'external'
          // Base de datos local puede tener: 'sucursal', 'almacen', etc
          String warehouseType = json['warehouse_type'] as String? ?? 'store';
          if (warehouseType == 'sucursal' || warehouseType == 'tienda') {
            warehouseType = 'store';
          } else if (warehouseType == 'almacen' || warehouseType == 'almacén') {
            warehouseType = 'central';
          } else if (!['central', 'store', 'external'].contains(warehouseType)) {
            warehouseType = 'store'; // Default
          }
          json['warehouse_type'] = warehouseType;
          
          await supabase.from('warehouses').upsert(json);
          result.addSuccess('warehouses');
        } catch (e) {
          result.addError('warehouses', 'Warehouse ${warehouse.id}: $e');
        }
      }
    } catch (e) {
      result.addError('warehouses', 'Error general: $e');
    }
  }

  Future<void> _migrateStocks(dynamic supabase, MigrationResult result) async {
    try {
      final stocks = await _localDb.select(_localDb.stocks).get();
      print('   Encontrados ${stocks.length} registros de stock');
      
      for (final stock in stocks) {
        try {
          final json = DataMappers.stockToJson(stock);
          await supabase.from('stocks').upsert(json);
          result.addSuccess('stocks');
        } catch (e) {
          result.addError('stocks', 'Stock ${stock.productId}-${stock.warehouseId}: $e');
        }
      }
    } catch (e) {
      result.addError('stocks', 'Error general: $e');
    }
  }

  Future<void> _migrateCustomers(dynamic supabase, MigrationResult result) async {
    try {
      final customers = await _localDb.select(_localDb.customers).get();
      print('   Encontrados ${customers.length} clientes');
      
      for (final customer in customers) {
        try {
          final json = DataMappers.customerToJson(customer);
          await supabase.from('customers').upsert(json);
          result.addSuccess('customers');
        } catch (e) {
          result.addError('customers', 'Customer ${customer.id}: $e');
        }
      }
    } catch (e) {
      result.addError('customers', 'Error general: $e');
    }
  }

  Future<void> _migrateEmployees(dynamic supabase, MigrationResult result) async {
    try {
      final employees = await _localDb.select(_localDb.employees).get();
      print('   Encontrados ${employees.length} empleados');
      
      for (final employee in employees) {
        try {
          // FIX: Incluir password_hash (requerido por Supabase)
          final json = DataMappers.employeeToJson(employee, includePassword: true);
          
          // Si aún no tiene password_hash, crear uno por defecto
          if (json['password_hash'] == null || json['password_hash'] == '') {
            json['password_hash'] = r'$2a$10$defaulthashformigratedemployees'; // Hash por defecto
            print('      ⚠️ Employee ${employee.id} sin password, usando hash por defecto');
          }
          
          // FIX: Si company_id es null o 0, usar 1 (company por defecto)
          if (json['company_id'] == null || json['company_id'] == 0) {
            json['company_id'] = 1;
          }
          
          // FIX: store_id y warehouse_id deben ser null si no existen
          json['store_id'] = null;
          json['warehouse_id'] = null;
          
          // FIX: Convertir role a valores válidos de Supabase
          // Valores permitidos: 'admin', 'store_manager', 'warehouse_manager', 'cashier', 'employee'
          if (json['role'] != null) {
            final role = json['role'].toString().toLowerCase();
            
            // Mapear roles locales a roles de Supabase
            if (role == 'administrador' || role == 'gerente general') {
              json['role'] = 'admin';
            } else if (role == 'gerente tienda' || role == 'jefe tienda') {
              json['role'] = 'store_manager';
            } else if (role == 'gerente almacen' || role == 'jefe almacen') {
              json['role'] = 'warehouse_manager';
            } else if (role == 'cajero' || role == 'vendedor') {
              json['role'] = 'cashier';
            } else if (role == 'empleado') {
              json['role'] = 'employee';
            } else if (['admin', 'store_manager', 'warehouse_manager', 'cashier', 'employee'].contains(role)) {
              // Ya es válido, mantener
              json['role'] = role;
            } else {
              // Por defecto, employee
              json['role'] = 'employee';
              print('      ⚠️ Employee ${employee.id}: rol "$role" mapeado a "employee"');
            }
          }
          
          await supabase.from('employees').upsert(json);
          result.addSuccess('employees');
        } catch (e) {
          result.addError('employees', 'Employee ${employee.id}: $e');
        }
      }
    } catch (e) {
      result.addError('employees', 'Error general: $e');
    }
  }

  Future<void> _migrateSales(dynamic supabase, MigrationResult result) async {
    try {
      final sales = await _localDb.select(_localDb.sales).get();
      print('   Encontradas ${sales.length} ventas');
      
      for (final sale in sales) {
        try {
          final json = DataMappers.saleToJson(sale);
          
          // FIX: customer_id debe ser null si el customer no existe en Supabase
          // En el schema, customer_id tiene ON DELETE SET NULL
          if (json['customer_id'] != null) {
            // Verificar si el customer existe, si no, poner null
            try {
              final customerExists = await supabase
                  .from('customers')
                  .select('id')
                  .eq('id', json['customer_id'])
                  .maybeSingle();
              
              if (customerExists == null) {
                json['customer_id'] = null;
                print('      ⚠️ Sale ${sale.id}: customer_id=${json['customer_id']} no existe, usando null');
              }
            } catch (e) {
              // Si hay error al verificar, mejor poner null
              json['customer_id'] = null;
            }
          }
          
          // FIX: Convertir payment_method a valores válidos de Supabase
          // Valores permitidos: 'cash', 'card', 'transfer', 'credit'
          if (json['payment_method'] != null) {
            final method = json['payment_method'].toString().toLowerCase();
            
            // Mapear valores locales a valores de Supabase
            if (method.contains('efectivo') || method == 'cash') {
              json['payment_method'] = 'cash';
            } else if (method.contains('tarjeta') || method.contains('card') || method == 'online') {
              json['payment_method'] = 'card';
            } else if (method.contains('transferencia') || method == 'transfer') {
              json['payment_method'] = 'transfer';
            } else if (method.contains('credito') || method.contains('credit')) {
              json['payment_method'] = 'credit';
            } else {
              // Default: card para pagos online/electrónicos
              json['payment_method'] = 'card';
              print('      ⚠️ Sale ${sale.id}: método de pago "$method" mapeado a "card"');
            }
          }
          
          // FIX: Convertir payment_status a valores válidos de Supabase
          // Valores permitidos: 'pending', 'paid', 'partial', 'overdue'
          if (json['payment_status'] != null) {
            final status = json['payment_status'].toString().toLowerCase();
            
            // Mapear valores locales a valores de Supabase
            if (status == 'pagado' || status == 'paid' || status == 'completado') {
              json['payment_status'] = 'paid';
            } else if (status == 'pendiente' || status == 'pending') {
              json['payment_status'] = 'pending';
            } else if (status == 'parcial' || status == 'partial') {
              json['payment_status'] = 'partial';
            } else if (status == 'vencido' || status == 'overdue' || status == 'atrasado') {
              json['payment_status'] = 'overdue';
            } else if (['pending', 'paid', 'partial', 'overdue'].contains(status)) {
              // Ya es válido
              json['payment_status'] = status;
            } else {
              // Default: pending para estados desconocidos
              json['payment_status'] = 'pending';
              print('      ⚠️ Sale ${sale.id}: payment_status "$status" mapeado a "pending"');
            }
          }
          
          // FIX: Convertir sale_status a valores válidos de Supabase
          // Valores permitidos: 'pending', 'completed', 'cancelled', 'returned'
          if (json['sale_status'] != null) {
            final saleStatus = json['sale_status'].toString().toLowerCase();
            
            // Mapear valores locales a valores de Supabase
            if (saleStatus == 'completado' || saleStatus == 'completada' || saleStatus == 'completed' || saleStatus == 'finalizado') {
              json['sale_status'] = 'completed';
            } else if (saleStatus == 'pendiente' || saleStatus == 'pending') {
              json['sale_status'] = 'pending';
            } else if (saleStatus == 'cancelado' || saleStatus == 'cancelada' || saleStatus == 'cancelled') {
              json['sale_status'] = 'cancelled';
            } else if (saleStatus == 'devuelto' || saleStatus == 'devuelta' || saleStatus == 'returned') {
              json['sale_status'] = 'returned';
            } else if (['pending', 'completed', 'cancelled', 'returned'].contains(saleStatus)) {
              // Ya es válido
              json['sale_status'] = saleStatus;
            } else {
              // Default: completed para ventas sin estado conocido
              json['sale_status'] = 'completed';
              print('      ⚠️ Sale ${sale.id}: sale_status "$saleStatus" mapeado a "completed"');
            }
          }
          
          await supabase.from('sales').upsert(json);
          result.addSuccess('sales');
        } catch (e) {
          result.addError('sales', 'Sale ${sale.id}: $e');
        }
      }
    } catch (e) {
      result.addError('sales', 'Error general: $e');
    }
  }
}

/// Resultado de la migración
class MigrationResult {
  final Map<String, int> _successCount = {};
  final Map<String, List<String>> _errors = {};
  
  void addSuccess(String table) {
    _successCount[table] = (_successCount[table] ?? 0) + 1;
  }
  
  void addError(String table, String error) {
    _errors.putIfAbsent(table, () => []);
    _errors[table]!.add(error);
  }
  
  void printSummary() {
    print('');
    print('═══════════════════════════════════════');
    print('📊 RESUMEN DE MIGRACIÓN');
    print('═══════════════════════════════════════');
    
    if (_successCount.isNotEmpty) {
      print('\n✅ Registros migrados exitosamente:');
      _successCount.forEach((table, count) {
        print('   • $table: $count registros');
      });
    }
    
    if (_errors.isNotEmpty) {
      print('\n❌ Errores encontrados:');
      _errors.forEach((table, errors) {
        print('   • $table: ${errors.length} errores');
        for (final error in errors.take(3)) {
          print('     - $error');
        }
        if (errors.length > 3) {
          print('     - ...y ${errors.length - 3} más');
        }
      });
    }
    
    final totalSuccess = _successCount.values.fold(0, (a, b) => a + b);
    final totalErrors = _errors.values.fold(0, (a, b) => a + b.length);
    
    print('\n═══════════════════════════════════════');
    print('Total: $totalSuccess exitosos, $totalErrors errores');
    print('═══════════════════════════════════════');
  }
  
  bool get hasErrors => _errors.isNotEmpty;
  int get totalSuccess => _successCount.values.fold(0, (a, b) => a + b);
  int get totalErrors => _errors.values.fold(0, (a, b) => a + b.length);
}

/// Widget para mostrar progreso de migración
class MigrationDialog extends StatefulWidget {
  final LocalDatabase database;
  
  const MigrationDialog({
    Key? key,
    required this.database,
  }) : super(key: key);

  @override
  State<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends State<MigrationDialog> {
  bool _isMigrating = false;
  MigrationResult? _result;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue),
          SizedBox(width: 8),
          Text('Migrar a Supabase'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _isMigrating
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Migrando datos a Supabase...'),
                  SizedBox(height: 8),
                  Text(
                    'Por favor espera, esto puede tomar unos minutos',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : _result == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Esta acción copiará todos los datos de tu base de datos local a Supabase.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Importante:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('• Asegúrate de tener internet', style: TextStyle(fontSize: 12)),
                            Text('• Verifica que las tablas estén creadas en Supabase', style: TextStyle(fontSize: 12)),
                            Text('• Los datos existentes se actualizarán (upsert)', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _result!.hasErrors ? Icons.warning : Icons.check_circle,
                              color: _result!.hasErrors ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _result!.hasErrors ? 'Completado con errores' : '¡Migración exitosa!',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('✅ ${_result!.totalSuccess} registros migrados'),
                        if (_result!.hasErrors)
                          Text('❌ ${_result!.totalErrors} errores', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
      ),
      actions: [
        if (!_isMigrating && _result == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        if (!_isMigrating && _result == null)
          ElevatedButton(
            onPressed: _startMigration,
            child: const Text('Iniciar Migración'),
          ),
        if (_result != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
      ],
    );
  }
  
  Future<void> _startMigration() async {
    setState(() {
      _isMigrating = true;
    });
    
    try {
      final service = MigrationService(widget.database);
      final result = await service.migrateAllData();
      
      setState(() {
        _result = result;
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });
      
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
}

/// Función helper para mostrar el diálogo desde cualquier pantalla
Future<void> showMigrationDialog(BuildContext context, LocalDatabase database) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => MigrationDialog(database: database),
  );
}
