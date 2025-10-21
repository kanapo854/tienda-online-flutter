import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/role_auth_bloc.dart';
import '../../models/user_role.dart';
import '../../database/local_database.dart';
import '../../services/role_based_auth_service.dart';
import '../../services/simple_auth_service_fixed.dart';
import '../../services/employee_registration_service.dart';
import '../../widgets/notifications_panel.dart';

class AdminUsersDashboard extends StatefulWidget {
  const AdminUsersDashboard({super.key});

  @override
  State<AdminUsersDashboard> createState() => _AdminUsersDashboardState();
}

class _AdminUsersDashboardState extends State<AdminUsersDashboard> {
  late final LocalDatabase _database;
  late final RoleBasedAuthService _authService;
  List<Employee> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _database = LocalDatabase();
    _authService = RoleBasedAuthService(SimpleAuthService(_database), _database);
    _loadUsers();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final allEmployees = await _database.getAllEmployees();
      
      // Filtrar solo usuarios administrativos y usuarios con credenciales completas
      final adminRoles = [UserRole.adminUsers.code, UserRole.adminEmployees.code];
      final users = allEmployees.where((emp) => 
        adminRoles.contains(emp.role) || 
        (emp.passwordHash.isNotEmpty && emp.passwordHash != 'PENDING')
      ).toList();
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
      
      print('Usuarios administrativos cargados: ${users.length}');
      for (var user in users) {
        print('- ${user.firstName} ${user.lastName} (${user.role}) - Hash: ${user.passwordHash.substring(0, 10)}...');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtener empleados pendientes de aprobación
  Future<List<Employee>> _getPendingEmployees() async {
    try {
      final database = LocalDatabase();
      final allEmployees = await database.getAllEmployees();
      
      // Filtrar empleados con credenciales pendientes
      final pendingEmployees = allEmployees.where((emp) => 
        emp.passwordHash == 'PENDING' && 
        UserRole.getEmployeeRoles().map((r) => r.code).contains(emp.role)
      ).toList();
      
      return pendingEmployees;
    } catch (e) {
      print('Error obteniendo empleados pendientes: $e');
      return [];
    }
  }

  /// Mostrar lista de empleados pendientes de aprobación
  // NOTA: Esta funcionalidad ahora se maneja desde el panel de notificaciones
  /*void _showPendingEmployees() async {
    final pendingEmployees = await _getPendingEmployees();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_add, color: Colors.green),
            const SizedBox(width: 8),
            Text('Empleados Pendientes (${pendingEmployees.length})'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: pendingEmployees.isEmpty ? 100 : 400,
          child: pendingEmployees.isEmpty
              ? const Center(
                  child: Text('No hay empleados pendientes de aprobación'),
                )
              : ListView.builder(
                  itemCount: pendingEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = pendingEmployees[index];
                    final role = UserRole.fromCode(employee.role);
                    
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Text(
                            '${employee.firstName[0]}${employee.lastName[0]}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${employee.firstName} ${employee.lastName}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${employee.email}'),
                            Text('Rol: ${role.displayName}'),
                            Text('Documento: ${employee.documentNumber}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveEmployee(employee),
                              tooltip: 'Aprobar empleado',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectEmployee(employee),
                              tooltip: 'Rechazar empleado',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
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

  /// Aprobar empleado y darle credenciales de acceso
  Future<void> _approveEmployee(Employee employee) async {
    // Mostrar diálogo para configurar credenciales
    final TextEditingController passwordController = TextEditingController();
    passwordController.text = 'temp123'; // Contraseña temporal por defecto
    
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aprobar empleado: ${employee.firstName} ${employee.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Esto creará credenciales de acceso para el empleado.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña temporal',
                border: OutlineInputBorder(),
                hintText: 'Contraseña que el empleado deberá cambiar',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    
    if (approved == true && mounted) {
      try {
        // Crear credenciales usando el servicio de autenticación
        final result = await _authService.createUserWithRole(
          employee.email,
          passwordController.text,
          employee.firstName,
          employee.lastName,
          UserRole.fromCode(employee.role),
          phone: employee.phone,
          documentNumber: employee.documentNumber,
          companyId: employee.companyId,
          storeId: employee.storeId,
          warehouseId: employee.warehouseId,
        );
        
        if (result.isSuccess) {
          // Eliminar el registro pendiente
          await LocalDatabase().deleteEmployee(employee.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empleado ${employee.firstName} ${employee.lastName} aprobado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recargar datos
          await _loadUsers();
          Navigator.of(context).pop(); // Cerrar diálogo de pendientes
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al aprobar empleado: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error inesperado: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    passwordController.dispose();
  }

  /// Rechazar empleado pendiente
  Future<void> _rejectEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar empleado'),
        content: Text('¿Estás seguro de que quieres rechazar a ${employee.firstName} ${employee.lastName}?\n\nEsto eliminará permanentemente su registro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      try {
        await LocalDatabase().deleteEmployee(employee.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empleado ${employee.firstName} ${employee.lastName} rechazado'),
            backgroundColor: Colors.orange,
          ),
        );
        
        Navigator.of(context).pop(); // Cerrar diálogo de pendientes
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al rechazar empleado: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }*/

  void _showDebugOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛠️ Opciones de Debug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Ver todos los registros'),
              subtitle: const Text('Incluye registros ocultos o corruptos'),
              onTap: () {
                Navigator.of(context).pop();
                _showAllDatabaseRecords();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.purple),
              title: const Text('Mostrar documentos únicos'),
              subtitle: const Text('Ver todos los document_number en BD'),
              onTap: () {
                Navigator.of(context).pop();
                _showAllDocumentNumbers();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.orange),
              title: const Text('Limpiar registros duplicados'),
              subtitle: const Text('Elimina registros con problemas'),
              onTap: () {
                Navigator.of(context).pop();
                _cleanDuplicateRecords();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.green),
              title: const Text('Crear empleado de prueba'),
              subtitle: const Text('Crear empleado PENDING para test'),
              onTap: () {
                Navigator.of(context).pop();
                _createTestEmployee();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.green),
              title: const Text('Ver notificaciones'),
              subtitle: const Text('Ir a la pestaña de notificaciones'),
              onTap: () {
                Navigator.of(context).pop();
                DefaultTabController.of(context).animateTo(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Limpiar toda la tabla'),
              subtitle: const Text('⚠️ Elimina TODOS los usuarios'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmClearAllUsers();
              },
            ),
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

  void _showAllDatabaseRecords() async {
    try {
      final database = LocalDatabase();
      
      // Consulta directa para ver TODOS los registros, incluso los problemáticos
      final results = await database.customSelect(
        'SELECT id, email, first_name, last_name, document_number, role, company_id, store_id, warehouse_id FROM employees ORDER BY id'
      ).get();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔍 Todos los registros en BD'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: results.isEmpty 
              ? const Center(child: Text('No hay registros en la base de datos'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final record = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: record.data['document_number'] == null 
                          ? Colors.red[50] 
                          : Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: record.data['document_number'] == null 
                              ? Colors.red 
                              : Colors.blue,
                          child: Text('${record.data['id']}'),
                        ),
                        title: Text(
                          '${record.data['email'] ?? 'SIN EMAIL'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nombre: ${record.data['first_name']} ${record.data['last_name']}'),
                            Text('Documento: ${record.data['document_number'] ?? 'NULL'}'),
                            Text('Rol: ${record.data['role'] ?? 'NULL'}'),
                            Text('IDs: C:${record.data['company_id']} S:${record.data['store_id']} W:${record.data['warehouse_id']}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecordById(record.data['id']),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al consultar BD: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAllDocumentNumbers() async {
    try {
      final database = LocalDatabase();
      final employees = await database.getAllEmployees();
      
      // Crear un mapa para contar documentos
      final documentCounts = <String?, int>{};
      for (final emp in employees) {
        documentCounts[emp.documentNumber] = (documentCounts[emp.documentNumber] ?? 0) + 1;
      }
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('📄 Documentos en BD (${employees.length} total)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: documentCounts.isEmpty 
              ? const Center(child: Text('No hay documentos'))
              : ListView.builder(
                  itemCount: documentCounts.length,
                  itemBuilder: (context, index) {
                    final entry = documentCounts.entries.elementAt(index);
                    final docNumber = entry.key ?? 'NULL';
                    final count = entry.value;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: count > 1 ? Colors.red : Colors.green,
                        child: Text('$count'),
                      ),
                      title: Text(
                        docNumber,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: count > 1 ? Colors.red : Colors.black,
                          fontWeight: count > 1 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        count > 1 ? '⚠️ DUPLICADO' : '✅ Único',
                        style: TextStyle(
                          color: count > 1 ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
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

  void _deleteRecordById(int id) async {
    try {
      final database = LocalDatabase();
      await (database.delete(database.employees)..where((emp) => emp.id.equals(id))).go();
      _loadUsers();
      Navigator.of(context).pop(); // Cerrar el diálogo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registro $id eliminado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar registro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cleanDuplicateRecords() async {
    try {
      final database = LocalDatabase();
      
      // Obtener todos los empleados y filtrar los problemáticos
      final allEmployees = await database.getAllEmployees();
      final problematicEmployees = allEmployees.where((emp) => 
        emp.documentNumber.isEmpty || emp.documentNumber == ''
      );
      
      // Eliminar uno por uno
      for (final emp in problematicEmployees) {
        await database.deleteEmployee(emp.id);
      }
      
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${problematicEmployees.length} registros problemáticos eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmClearAllUsers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar eliminación total'),
        content: const Text('Esto eliminará TODOS los usuarios de la base de datos, incluyendo el usuario actual. Tendrás que volver a crear usuarios de prueba.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final database = LocalDatabase();
                await database.delete(database.employees).go();
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos los usuarios eliminados. Puedes crear nuevos usuarios.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Sí, eliminar todo'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestEmployee() async {
    try {
      // Crear un empleado de prueba usando createEmployeeOnly
      final result = await _authService.createEmployeeOnly(
        'test.empleado.${DateTime.now().millisecondsSinceEpoch}@example.com',
        'Juan',
        'Pérez Test',
        UserRole.seller,
        documentNumber: '${DateTime.now().millisecondsSinceEpoch}',
        companyId: 1,
        storeId: 1,
      );

      if (result.isSuccess) {
        // Crear la solicitud de registro usando el servicio
        final registrationService = EmployeeRegistrationService();
        registrationService.initializeDatabase(LocalDatabase());
        
        await registrationService.createEmployeeRegistrationRequest(
          employeeId: result.user!.id,
          salary: 1500.0,
          position: 'Vendedor de Prueba',
          department: 'Ventas',
          suggestedUsername: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
          suggestedRole: UserRole.seller.name,
          notes: 'Empleado de prueba creado para debugging',
          requestedBy: _users.isNotEmpty ? _users.first.id : 1,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empleado de prueba creado: ${result.user!.firstName} ${result.user!.lastName}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Ver Notificaciones',
                onPressed: () {
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
            ),
          );
        }

        _loadUsers(); // Recargar la lista
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creando empleado de prueba: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
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
            const Text('Rol: Admin de Usuarios'),
            const SizedBox(height: 8),
            const Text('Permisos:'),
            const SizedBox(height: 4),
            const Text('• Gestión de usuarios del sistema'),
            const Text('• Configuración de accesos'),
            const Text('• Administración de roles'),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración de Usuarios'),
          backgroundColor: Colors.brown[600],
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
                    _loadUsers();
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Usuarios'),
              Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(),
            NotificationsPanel(
              targetRole: 'admin_usuarios',
              currentUserId: _users.isNotEmpty ? _users.first.id : 1, // Usar usuario actual si está disponible
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateUserDialog(),
          backgroundColor: Colors.brown[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text('Nuevo Usuario'),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Header con estadísticas
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.brown[50],
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Usuarios',
                        _users.length.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Administradores',
                        _users.where((u) => u.role.startsWith('admin')).length.toString(),
                        Icons.admin_panel_settings,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Empleados',
                        _users.where((u) => !u.role.startsWith('admin') && u.role != 'customer').length.toString(),
                        Icons.badge,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista de usuarios
              Expanded(
                child: _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay usuarios registrados',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
              ),
            ],
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

  Widget _buildUserCard(Employee user) {
    final userRole = UserRole.fromCode(user.role);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse('0xFF${userRole.colorCode.substring(1)}')),
          child: Text(
            user.firstName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          '${user.firstName} ${user.lastName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${userRole.colorCode.substring(1)}')).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(int.parse('0xFF${userRole.colorCode.substring(1)}')),
                  width: 1,
                ),
              ),
              child: Text(
                userRole.displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(int.parse('0xFF${userRole.colorCode.substring(1)}')),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estado del usuario
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.isActive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Text(
                user.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 11,
                  color: user.isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botón rápido de cambiar contraseña
            IconButton(
              icon: const Icon(Icons.lock_reset, size: 20),
              onPressed: () => _showResetPasswordDialog(user),
              tooltip: 'Cambiar contraseña',
              color: Colors.orange[700],
            ),
            // Menú contextual
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditUserDialog(user);
                    break;
                  case 'toggle_status':
                    _toggleUserStatus(user);
                    break;
                  case 'reset_password':
                    _showResetPasswordDialog(user);
                    break;
                  case 'delete':
                    _showDeleteUserDialog(user);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar datos'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        user.isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                        color: user.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Desactivar' : 'Activar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_password',
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Cambiar contraseña'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar permanentemente', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        title: 'Crear Nuevo Usuario',
        onSave: (userData) async {
          try {
            print('🔍 DEBUG: Iniciando creación de usuario...');
            print('📧 Email: ${userData['email']}');
            print('👤 Nombre: ${userData['firstName']} ${userData['lastName']}');
            print('🎭 Rol: ${userData['role']}');
            print('📄 Documento original: "${userData['documentNumber']}"');
            print('📋 Tipo de documento: ${userData['documentType']}');
            
            // Generar número de documento único si no se proporciona
            String? documentNumber = userData['documentNumber']?.isEmpty == true 
                ? null 
                : userData['documentNumber'];
            String documentType = userData['documentType'] ?? 'CC';
            
            print('📄 Documento procesado inicial: "$documentNumber"');
            print('📋 Tipo de documento final: "$documentType"');
            
            if (documentNumber == null || documentNumber.isEmpty) {
              print('🔄 Generando documento automático...');
              
              // Generar un número único más robusto
              final database = LocalDatabase();
              bool isUnique = false;
              int attempts = 0;
              
              while (!isUnique && attempts < 10) {
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final random = (timestamp % 1000000).toString().padLeft(6, '0');
                documentNumber = '$documentType$random'; // Usar el tipo de documento como prefijo
                
                print('🎲 Intento ${attempts + 1}: Probando documento "$documentNumber"');
                
                // Verificar si ya existe usando el método correcto de la base de datos
                final existingEmployees = await database.getAllEmployees();
                final existing = existingEmployees.where((emp) => emp.documentNumber == documentNumber).isNotEmpty;
                
                print('🔍 Documento "$documentNumber" existe: $existing');
                print('👥 Total empleados en BD: ${existingEmployees.length}');
                
                if (!existing) {
                  isUnique = true;
                  print('✅ Documento único encontrado: "$documentNumber"');
                } else {
                  attempts++;
                  print('❌ Documento duplicado, reintentando...');
                  // Esperar un poco para cambiar el timestamp
                  await Future.delayed(const Duration(milliseconds: 1));
                }
              }
              
              if (!isUnique) {
                throw Exception('No se pudo generar un número de documento único después de $attempts intentos');
              }
            } else {
              print('📝 Usando documento proporcionado: "$documentNumber"');
              
              // Verificar si el documento proporcionado ya existe
              final database = LocalDatabase();
              final existingEmployees = await database.getAllEmployees();
              final existing = existingEmployees.where((emp) => emp.documentNumber == documentNumber).isNotEmpty;
              
              print('🔍 Verificando documento proporcionado "$documentNumber" - existe: $existing');
              
              if (existing) {
                throw Exception('El documento "$documentNumber" ya está en uso');
              }
            }

            print('🚀 Creando usuario con documento: "$documentNumber"');

            final result = await _authService.createUserWithRole(
              userData['email']!,
              userData['password']!,
              userData['firstName']!,
              userData['lastName']!,
              userData['role']!,
              phone: userData['phone']?.isEmpty == true ? null : userData['phone'],
              documentNumber: documentNumber,
              companyId: userData['companyId'],
              storeId: userData['storeId'],
              warehouseId: userData['warehouseId'],
            );

            print('📊 Resultado de creación: ${result.isSuccess ? "ÉXITO" : "FALLO"}');
            if (!result.isSuccess) {
              print('❌ Error: ${result.errorMessage}');
            }

            if (result.isSuccess) {
              _loadUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usuario creado: ${userData['firstName']} ${userData['lastName']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                String errorMessage = result.errorMessage ?? 'Error desconocido';
                
                // Personalizar mensajes de error comunes
                if (errorMessage.contains('UNIQUE constraint failed: employees.email')) {
                  errorMessage = 'Ya existe un usuario con ese email';
                } else if (errorMessage.contains('UNIQUE constraint failed: employees.document_number')) {
                  errorMessage = 'Ya existe un usuario with ese número de documento';
                } else if (errorMessage.contains('document_number')) {
                  errorMessage = 'Error con el número de documento. Intenta con otro.';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $errorMessage'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              String errorMessage = e.toString();
              
              // Personalizar mensajes de error de excepción
              if (errorMessage.contains('UNIQUE constraint failed: employees.email')) {
                errorMessage = 'Ya existe un usuario con ese email';
              } else if (errorMessage.contains('UNIQUE constraint failed: employees.document_number')) {
                errorMessage = 'Ya existe un usuario con ese número de documento';
              } else if (errorMessage.contains('document_number')) {
                errorMessage = 'Error con el número de documento';
              } else {
                errorMessage = 'Error al crear usuario: $errorMessage';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditUserDialog(Employee user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        title: 'Editar Usuario',
        user: user,
        onSave: (userData) async {
          try {
            print('📝 Actualizando usuario ${user.id}...');
            print('📧 Email actual: ${user.email} -> nuevo: ${userData['email']}');
            print('👤 Nombre actual: ${user.firstName} ${user.lastName} -> nuevo: ${userData['firstName']} ${userData['lastName']}');
            print('🎭 Rol actual: ${user.role} -> nuevo: ${userData['role']?.code}');

            // Actualizar datos del usuario (sin contraseña)
            final result = await _authService.updateUserData(
              user.id,
              firstName: userData['firstName'],
              lastName: userData['lastName'],
              email: userData['email'],
              phone: userData['phone']?.isEmpty == true ? null : userData['phone'],
              documentNumber: userData['documentNumber']?.isEmpty == true ? null : userData['documentNumber'],
              role: userData['role'],
              companyId: userData['companyId'],
              storeId: userData['storeId'],
              warehouseId: userData['warehouseId'],
            );

            print('📊 Resultado de actualización: ${result.isSuccess ? "ÉXITO" : "FALLO"}');
            if (!result.isSuccess) {
              print('❌ Error: ${result.errorMessage}');
            }

            if (result.isSuccess) {
              _loadUsers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usuario ${userData['firstName']} ${userData['lastName']} actualizado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                String errorMessage = result.errorMessage ?? 'Error desconocido';
                
                // Personalizar mensajes de error comunes
                if (errorMessage.contains('email ya está en uso')) {
                  errorMessage = 'Ya existe otro usuario con ese email';
                } else if (errorMessage.contains('documento ya está en uso')) {
                  errorMessage = 'Ya existe otro usuario con ese número de documento';
                }
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $errorMessage'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            print('💥 Excepción al actualizar usuario: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error inesperado al actualizar usuario: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showResetPasswordDialog(Employee user) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();
    bool isUpdatingPassword = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Cambiar contraseña de ${user.firstName} ${user.lastName}'),
              ),
            ],
          ),
          content: Form(
            key: passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información del usuario
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: UserRole.fromCode(user.role).color,
                        child: Text(
                          '${user.firstName[0]}${user.lastName[0]}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(user.email, style: const TextStyle(fontSize: 12)),
                            Text(
                              UserRole.fromCode(user.role).displayName,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Nueva contraseña
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Mínimo 6 caracteres',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Contraseña requerida';
                    if (value!.length < 6) return 'Mínimo 6 caracteres';
                    if (value.length > 50) return 'Máximo 50 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirmar contraseña
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Confirmación requerida';
                    if (value != passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Advertencia de seguridad
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El usuario deberá usar esta nueva contraseña para iniciar sesión',
                          style: TextStyle(
                            color: Colors.amber[800],
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
          actions: [
            TextButton(
              onPressed: isUpdatingPassword ? null : () {
                // No dispose aquí - dejar que se haga automáticamente
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isUpdatingPassword ? null : () async {
                if (passwordFormKey.currentState!.validate()) {
                  setDialogState(() => isUpdatingPassword = true);
                  
                  try {
                    // Actualizar contraseña usando el servicio de autenticación
                    final result = await _authService.updateUserPassword(
                      user.id,
                      passwordController.text,
                    );
                    
                    if (result.isSuccess) {
                      // Solo cerrar el diálogo - no dispose manual
                      Navigator.of(context).pop();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contraseña actualizada para ${user.firstName} ${user.lastName}'),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                    } else {
                      setDialogState(() => isUpdatingPassword = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${result.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    setDialogState(() => isUpdatingPassword = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error inesperado: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: isUpdatingPassword
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Cambiar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(Employee user) async {
    final newStatus = !user.isActive;
    final action = newStatus ? 'activar' : 'desactivar';
    
    // Confirmar la acción
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.check_circle : Icons.block,
              color: newStatus ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text('${newStatus ? 'Activar' : 'Desactivar'} usuario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Estás seguro de que deseas $action a ${user.firstName} ${user.lastName}?'),
            const SizedBox(height: 12),
            if (!newStatus) 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al desactivar el usuario no podrá iniciar sesión',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(newStatus ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final result = await _authService.updateUserData(
          user.id,
          isActive: newStatus,
        );
        
        if (result.isSuccess) {
          _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Usuario ${user.firstName} ${user.lastName} ${newStatus ? 'activado' : 'desactivado'} exitosamente'),
                backgroundColor: newStatus ? Colors.green : Colors.orange,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cambiar estado del usuario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showDeleteUserDialog(Employee user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar al usuario ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final database = LocalDatabase();
                await database.deleteEmployee(user.id);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar usuario: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final String title;
  final Function(Map<String, dynamic>) onSave;
  final Employee? user;

  const UserFormDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.user,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  
  UserRole _selectedRole = UserRole.customer; // Por defecto cliente
  int? _selectedCompanyId = 1;
  int? _selectedStoreId;
  int? _selectedWarehouseId;
  String _selectedDocumentType = 'CI'; // Cédula de Identidad por defecto
  
  // Tipos de documento disponibles
  final List<Map<String, String>> _documentTypes = [
    {'code': 'CI', 'name': 'Cédula de Identidad'},
    {'code': 'NIT', 'name': 'NIT'},
    {'code': 'PASAPORTE', 'name': 'Pasaporte'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Cargar datos del usuario existente
      _emailController.text = widget.user!.email;
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _phoneController.text = widget.user!.phone ?? '';
      _selectedRole = UserRole.fromCode(widget.user!.role);
      _selectedCompanyId = widget.user!.companyId;
      _selectedStoreId = widget.user!.storeId;
      _selectedWarehouseId = widget.user!.warehouseId;
      
      // Extraer tipo y número de documento del número de documento existente
      String docNumber = widget.user!.documentNumber;
      if (docNumber.isNotEmpty) {
        // Buscar coincidencia con los tipos de documento disponibles
        bool foundType = false;
        for (var type in _documentTypes) {
          if (docNumber.startsWith('${type['code']!}-')) {
            _selectedDocumentType = type['code']!;
            _documentController.text = docNumber.substring(type['code']!.length + 1); // +1 por el guión
            foundType = true;
            break;
          } else if (docNumber.startsWith(type['code']!)) {
            _selectedDocumentType = type['code']!;
            _documentController.text = docNumber.substring(type['code']!.length);
            foundType = true;
            break;
          }
        }
        // Si no se encuentra coincidencia con prefijos conocidos, usar el documento completo
        if (!foundType) {
          // Verificar si tiene un formato CI1234567, NIT123456, etc.
          final match = RegExp(r'^([A-Z]+)(.*)$').firstMatch(docNumber);
          if (match != null) {
            final prefix = match.group(1)!;
            final number = match.group(2)!;
            // Verificar si el prefijo es uno de nuestros tipos conocidos
            if (_documentTypes.any((type) => type['code'] == prefix)) {
              _selectedDocumentType = prefix;
              _documentController.text = number;
            } else {
              // Usar documento completo y tipo por defecto
              _documentController.text = docNumber;
            }
          } else {
            _documentController.text = docNumber;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.person_add,
            color: isEditing ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información contextual para edición
                if (isEditing) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: UserRole.fromCode(widget.user!.role).color,
                          child: Text(
                            '${widget.user!.firstName[0]}${widget.user!.lastName[0]}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editando: ${widget.user!.firstName} ${widget.user!.lastName}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'ID: ${widget.user!.id} • Creado: ${widget.user!.createdAt.day}/${widget.user!.createdAt.month}/${widget.user!.createdAt.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña (solo para crear)
                if (widget.user == null) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Contraseña requerida';
                      if (value!.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Nombre
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Nombre requerido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Apellido
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Apellido requerido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tipo de documento
                DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Documento',
                    border: OutlineInputBorder(),
                  ),
                  items: _documentTypes.map((type) => 
                    DropdownMenuItem(
                      value: type['code'],
                      child: Text('${type['code']} - ${type['name']}'),
                    ),
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Número de documento
                TextFormField(
                  controller: _documentController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Documento (opcional)',
                    hintText: 'Se generará automáticamente si se deja vacío',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Rol - Solo roles administrativos y clientes (NO empleados)
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    // Roles administrativos
                    DropdownMenuItem(value: UserRole.adminUsers, child: Text(UserRole.adminUsers.displayName)),
                    DropdownMenuItem(value: UserRole.adminEmployees, child: Text(UserRole.adminEmployees.displayName)),
                    DropdownMenuItem(value: UserRole.adminInventory, child: Text(UserRole.adminInventory.displayName)),
                    // Clientes
                    DropdownMenuItem(value: UserRole.customer, child: Text(UserRole.customer.displayName)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                      // Los usuarios administrativos y clientes no necesitan sucursal
                      _selectedStoreId = null;
                      _selectedWarehouseId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Información sobre roles sin sucursal
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
                          _selectedRole == UserRole.customer 
                            ? 'Los clientes no requieren asignación de sucursal'
                            : 'Los administradores tienen acceso global a todas las sucursales',
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Combinar tipo de documento con número si se proporciona un número
              String? fullDocumentNumber;
              if (_documentController.text.trim().isNotEmpty) {
                fullDocumentNumber = '$_selectedDocumentType-${_documentController.text.trim()}';
              }
              
              final userData = {
                'email': _emailController.text.trim(),
                'password': _passwordController.text, // Solo para creación
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'documentNumber': fullDocumentNumber ?? '', // Documento completo o vacío
                'documentType': _selectedDocumentType,
                'role': _selectedRole,
                'companyId': _selectedCompanyId,
                'storeId': _selectedStoreId,
                'warehouseId': _selectedWarehouseId,
              };
              widget.onSave(userData);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isEditing ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}