import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database/local_database.dart';
import '../../models/user_role.dart';
import '../../services/role_based_auth_service.dart';
import '../../services/employee_registration_service.dart';
import '../../bloc/auth/role_auth_bloc.dart';

class AdminEmployeesDashboard extends StatefulWidget {
  final RoleBasedAuthService authService;
  final Employee currentUser;
  final LocalDatabase database;

  const AdminEmployeesDashboard({
    Key? key,
    required this.authService,
    required this.currentUser,
    required this.database,
  }) : super(key: key);

  @override
  State<AdminEmployeesDashboard> createState() => _AdminEmployeesDashboardState();
}

class _AdminEmployeesDashboardState extends State<AdminEmployeesDashboard> {
  List<Employee> _employees = [];
  List<Company> _companies = [];
  List<Store> _stores = [];
  List<Warehouse> _warehouses = [];
  bool _isLoading = true;
  String _searchText = '';
  UserRole? _selectedRoleFilter;
  
  late final EmployeeRegistrationService _registrationService;

  // Controladores para formularios
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _passwordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.seller;
  String _selectedDocumentType = 'CI';
  int? _selectedStoreId;

  // Tipos de documento disponibles
  final List<Map<String, String>> _documentTypes = [
    {'code': 'CI', 'name': 'Cédula de Identidad'},
    {'code': 'NIT', 'name': 'NIT'},
    {'code': 'PASAPORTE', 'name': 'Pasaporte'},
  ];

  @override
  void initState() {
    super.initState();
    _registrationService = EmployeeRegistrationService();
    _registrationService.initializeDatabase(widget.database);
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar solo empleados (roles de employee, no admin)
      final employeeRoles = UserRole.getEmployeeRoles().map((r) => r.code).toList();
      final allEmployees = await widget.database.getAllEmployees();
      
      // Filtrar solo empleados que no tengan credenciales (passwordHash = 'PENDING') o sean empleados reales
      final employees = allEmployees.where((emp) => 
        employeeRoles.contains(emp.role)
      ).toList();
      
      final companies = await widget.database.getAllCompanies();
      final stores = await widget.database.getAllStores();
      final warehouses = await widget.database.getAllWarehouses();
      
      setState(() {
        _employees = employees;
        _companies = companies;
        _stores = stores;
        _warehouses = warehouses;
        _isLoading = false;
      });
      
      print('=== DATOS CARGADOS ===');
      print('Empleados cargados: ${_employees.length}');
      print('Compañías cargadas: ${_companies.length}');
      print('Tiendas cargadas: ${_stores.length}');
      print('Almacenes cargados: ${_warehouses.length}');
      
      if (_companies.isNotEmpty) {
        print('Primera compañía: ${_companies.first.name} (ID: ${_companies.first.id})');
      }
      if (_stores.isNotEmpty) {
        print('Primera tienda: ${_stores.first.name} (CompanyID: ${_stores.first.companyId})');
      }
      if (_employees.isNotEmpty) {
        print('Empleados encontrados:');
        for (var emp in _employees) {
          print('- ${emp.firstName} ${emp.lastName} (${emp.role}) - Activo: ${emp.isActive}');
        }
      }
    } catch (e) {
      print('Error cargando empleados: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando empleados: $e')),
        );
      }
    }
  }

  List<Employee> get _filteredEmployees {
    var filtered = _employees.where((employee) {
      final matchesSearch = _searchText.isEmpty ||
          employee.firstName.toLowerCase().contains(_searchText.toLowerCase()) ||
          employee.lastName.toLowerCase().contains(_searchText.toLowerCase()) ||
          employee.email.toLowerCase().contains(_searchText.toLowerCase()) ||
          employee.documentNumber.contains(_searchText);

      final matchesRole = _selectedRoleFilter == null ||
          employee.role == _selectedRoleFilter!.code;

      return matchesSearch && matchesRole;
    }).toList();

    // Ordenar por nombre
    filtered.sort((a, b) => a.firstName.compareTo(b.firstName));
    return filtered;
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      print('=== CREANDO EMPLEADO ===');
      print('Nombre: ${_firstNameController.text}');
      print('Apellido: ${_lastNameController.text}');
      print('Email: ${_emailController.text}');
      print('Documento: ${_documentController.text}');
      print('Rol: ${_selectedRole.code}');
      print('Tienda: $_selectedStoreId');

      // Para Administrador de Inventarios, no asignar sucursal específica (puede acceder a todas)
      final storeIdToAssign = _selectedRole == UserRole.adminInventory ? null : _selectedStoreId;
      
      // Crear número de documento con prefijo
      final fullDocumentNumber = '$_selectedDocumentType-${_documentController.text.trim()}';
      
      print('StoreId final: $storeIdToAssign');
      print('Número documento completo: $fullDocumentNumber');

      // Crear el empleado (sin credenciales de usuario)
      // Asignar compañía por defecto = 1 (Tienda Online)
      final result = await widget.authService.createEmployeeOnly(
        _emailController.text.trim(),
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _selectedRole,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        documentNumber: fullDocumentNumber,
        companyId: 1, // Siempre usar compañía por defecto
        storeId: storeIdToAssign,
        warehouseId: null, // No usar almacenes en este flujo simplificado
      );

      if (result.isSuccess) {
        // El empleado creado ya está en result.user
        final createdEmployee = result.user!;
        
        try {
          // Enviar notificación al admin de usuarios sobre el nuevo empleado
          await _registrationService.createEmployeeRegistrationRequest(
            employeeId: createdEmployee.id,
            salary: 0.0, // Salario por defecto o a definir
            position: _selectedRole.displayName,
            department: 'General',
            suggestedUsername: _emailController.text.split('@')[0],
            suggestedRole: _selectedRole.name,
            notes: 'Empleado creado por ${widget.currentUser.firstName} ${widget.currentUser.lastName}',
            requestedBy: widget.currentUser.id,
          );
          
          print('Notificación enviada al admin de usuarios exitosamente');
        } catch (notificationError) {
          print('Error enviando notificación: $notificationError');
          // No falla la creación si falla la notificación
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Empleado registrado exitosamente. Notificación enviada al admin de usuarios para crear credenciales de acceso.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop();
          _clearForm();
          await _loadData(); // Recargar la lista para mostrar el nuevo empleado
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result.message}')),
          );
        }
      }
    } catch (e) {
      print('Error creando empleado: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _documentController.clear();
    _passwordController.clear();
    _selectedRole = UserRole.seller;
    _selectedDocumentType = 'CI';
    _selectedStoreId = null;
  }

  void _showCreateEmployeeDialog() {
    _clearForm();

    showDialog(
      context: context,
      builder: (context) {
        // Variables locales para el diálogo
        int? localStoreId = _selectedStoreId;
        UserRole localRole = _selectedRole;
        String localDocumentType = _selectedDocumentType;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Debug para verificar los datos
            print('=== ESTADO DEL DIÁLOGO ===');
            print('localStoreId: $localStoreId');
            print('localRole: ${localRole.displayName}');
            
            return AlertDialog(
              title: const Text('Crear Nuevo Empleado'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    // Información personal
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellido *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Campo requerido';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de documento
                    DropdownButtonFormField<String>(
                      value: localDocumentType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Documento *',
                        border: OutlineInputBorder(),
                      ),
                      items: _documentTypes.map((type) => 
                        DropdownMenuItem(
                          value: type['code'],
                          child: Text('${type['code']} - ${type['name']}'),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          localDocumentType = value!;
                          _selectedDocumentType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Número de documento
                    TextFormField(
                      controller: _documentController,
                      decoration: InputDecoration(
                        labelText: 'Número de documento *',
                        border: const OutlineInputBorder(),
                        helperText: 'Se agregará automáticamente el prefijo $localDocumentType-',
                        helperStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Campo requerido';
                        if (value!.length < 4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Rol (solo roles de empleados)
                    DropdownButtonFormField<UserRole>(
                      value: localRole,
                      decoration: const InputDecoration(
                        labelText: 'Rol *',
                        border: OutlineInputBorder(),
                      ),
                      items: UserRole.getEmployeeRoles().map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          localRole = value!;
                          _selectedRole = value;
                          // Resetear asignaciones específicas cuando cambia el rol
                          localStoreId = null;
                          _selectedStoreId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Sucursal - Solo para roles que NO sean Administrador de Inventarios
                    if (localRole != UserRole.adminInventory) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: localStoreId,
                        decoration: const InputDecoration(
                          labelText: 'Sucursal *',
                          border: OutlineInputBorder(),
                        ),
                        items: _stores.map((store) => 
                          DropdownMenuItem<int>(
                            value: store.id,
                            child: Text(store.name),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            localStoreId = value;
                          });
                          _selectedStoreId = value;
                        },
                      ),
                    ],
                    
                    // Información para Administrador de Inventarios
                    if (localRole == UserRole.adminInventory) ...[
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
                                'El Administrador de Inventarios tiene acceso a todas las sucursales',
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
                // Validación personalizada según el rol
                bool isValid = _formKey.currentState!.validate();
                
                // Para roles que NO sean Administrador de Inventarios, verificar que tengan sucursal
                if (localRole != UserRole.adminInventory && localStoreId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar una sucursal para este rol'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Actualizar las variables globales con los valores locales
                _selectedRole = localRole;
                _selectedStoreId = localStoreId;
                
                if (isValid) {
                  _createEmployee();
                }
              },
              child: const Text('Crear Empleado'),
            ),
          ],
        );
      });
    });
  }

  Future<void> _toggleEmployeeStatus(Employee employee) async {
    try {
      // Aquí iría la lógica para activar/desactivar empleado
      // Similar a lo que tienes en admin_users_dashboard
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${employee.firstName} ${employee.isActive ? 'desactivado' : 'activado'} exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _requestUserCredentials(Employee employee) async {
    // Verificar si el empleado ya tiene credenciales
    if (employee.passwordHash.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este empleado ya tiene credenciales de acceso')),
      );
      return;
    }

    // Mostrar diálogo para solicitar credenciales
    await _showCredentialsRequestDialog(employee);
  }

  Future<void> _showCredentialsRequestDialog(Employee employee) async {
    final salaryController = TextEditingController();
    final positionController = TextEditingController();
    final departmentController = TextEditingController();
    final usernameController = TextEditingController(text: employee.email.split('@')[0]);
    final notesController = TextEditingController();
    
    String selectedRole = UserRole.seller.name;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Solicitar credenciales para ${employee.firstName} ${employee.lastName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: const InputDecoration(
                  labelText: 'Puesto de trabajo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: departmentController,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salario propuesto (S/)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario sugerido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rol sugerido',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role.name,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );

    if (result == true && 
        positionController.text.isNotEmpty && 
        departmentController.text.isNotEmpty &&
        salaryController.text.isNotEmpty &&
        usernameController.text.isNotEmpty) {
      
      try {
        final salary = double.parse(salaryController.text);
        
        await _registrationService.createEmployeeRegistrationRequest(
          employeeId: employee.id,
          salary: salary,
          position: positionController.text,
          department: departmentController.text,
          suggestedUsername: usernameController.text,
          suggestedRole: selectedRole,
          notes: notesController.text.isEmpty ? null : notesController.text,
          requestedBy: widget.currentUser.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada al administrador de usuarios'),
            backgroundColor: Colors.green,
          ),
        );
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Liberar recursos
    salaryController.dispose();
    positionController.dispose();
    departmentController.dispose();
    usernameController.dispose();
    notesController.dispose();
  }

  String _getCompanyName(int? companyId) {
    if (companyId == null) return 'Sin asignar';
    final company = _companies.where((c) => c.id == companyId).firstOrNull;
    return company?.name ?? 'Compañía no encontrada';
  }

  String _getStoreName(int? storeId) {
    if (storeId == null) return 'Sin asignar';
    final store = _stores.where((s) => s.id == storeId).firstOrNull;
    return store?.name ?? 'Tienda no encontrada';
  }

  String _getWarehouseName(int? warehouseId) {
    if (warehouseId == null) return 'Sin asignar';
    final warehouse = _warehouses.where((w) => w.id == warehouseId).firstOrNull;
    return warehouse?.name ?? 'Almacén no encontrado';
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
            const Text('Rol: Admin de Empleados'),
            const SizedBox(height: 8),
            const Text('Permisos:'),
            const SizedBox(height: 4),
            const Text('• Gestión de empleados'),
            const Text('• Asignación de roles y permisos'),
            const Text('• Control de solicitudes'),
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
        title: const Text('Gestión de Empleados'),
        backgroundColor: UserRole.adminEmployees.color,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Controles de búsqueda y filtros
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Buscar empleados...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole?>(
                        value: _selectedRoleFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por rol',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<UserRole?>(
                            value: null,
                            child: Text('Todos los roles'),
                          ),
                          ...UserRole.getEmployeeRoles().map((role) {
                            return DropdownMenuItem<UserRole?>(
                              value: role,
                              child: Text(role.displayName),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRoleFilter = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total empleados: ${_filteredEmployees.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          ElevatedButton.icon(
                            onPressed: _showCreateEmployeeDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Nuevo Empleado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: UserRole.adminEmployees.color,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Lista de empleados
                Expanded(
                  child: _filteredEmployees.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron empleados',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            final role = UserRole.fromCode(employee.role);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: role.color,
                                  child: Text(
                                    '${employee.firstName[0]}${employee.lastName[0]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '${employee.firstName} ${employee.lastName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(employee.email),
                                    Text(
                                      '${role.displayName} • ${_getCompanyName(employee.companyId)}',
                                      style: TextStyle(color: role.color),
                                    ),
                                    if (employee.storeId != null)
                                      Text('Tienda: ${_getStoreName(employee.storeId)}'),
                                    if (employee.warehouseId != null)
                                      Text('Almacén: ${_getWarehouseName(employee.warehouseId)}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: employee.isActive ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        employee.isActive ? 'Activo' : 'Inactivo',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        switch (value) {
                                          case 'toggle_status':
                                            await _toggleEmployeeStatus(employee);
                                            break;
                                          case 'request_credentials':
                                            await _requestUserCredentials(employee);
                                            break;
                                          case 'edit':
                                            // Implementar edición
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'toggle_status',
                                          child: Text(
                                            employee.isActive ? 'Desactivar' : 'Activar',
                                          ),
                                        ),
                                        if (employee.passwordHash.isEmpty)
                                          const PopupMenuItem(
                                            value: 'request_credentials',
                                            child: Row(
                                              children: [
                                                Icon(Icons.key, size: 16),
                                                SizedBox(width: 8),
                                                Text('Solicitar credenciales'),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Editar'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEmployeeDialog,
        backgroundColor: UserRole.adminEmployees.color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}