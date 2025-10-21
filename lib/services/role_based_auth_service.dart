import 'package:drift/drift.dart';
import '../database/local_database.dart';
import '../models/user_role.dart';
import 'simple_auth_service_fixed.dart';

/// Servicio de autenticación extendido con manejo de roles
class RoleBasedAuthService {
  final SimpleAuthService _authService;
  final LocalDatabase _database;

  RoleBasedAuthService(this._authService, this._database);

  /// Login con validación de rol
  Future<AuthResult> loginWithRole(
    String email,
    String password, {
    List<UserRole>? allowedRoles,
    bool preferOnline = true,
  }) async {
    try {
      // Realizar login normal
      Employee user;
      if (preferOnline) {
        try {
          user = await _authService.signInWithSupabase(email, password);
        } catch (e) {
          user = await _authService.signInLocally(email, password);
        }
      } else {
        user = await _authService.signInLocally(email, password);
      }

      // Obtener rol del usuario
      final userRole = UserRole.fromCode(user.role);

      // Validar si el rol está permitido
      if (allowedRoles != null && !allowedRoles.contains(userRole)) {
        await _authService.signOut();
        return AuthResult.failure(
          'No tienes permisos para acceder a esta aplicación. Rol requerido: ${allowedRoles.map((r) => r.displayName).join(", ")}',
        );
      }

      // Verificar si el usuario está activo
      if (!user.isActive) {
        await _authService.signOut();
        return AuthResult.failure('Tu cuenta está desactivada. Contacta al administrador.');
      }

      return AuthResult.success(user, userRole);
    } catch (e) {
      return AuthResult.failure('Error de autenticación: ${e.toString()}');
    }
  }

  /// Crear empleado (sin crear usuario en el sistema)
  Future<AuthResult> createEmployeeOnly(
    String email,
    String firstName,
    String lastName,
    UserRole role, {
    String? phone,
    String? documentNumber,
    int? companyId,
    int? storeId,
    int? warehouseId,
  }) async {
    try {
      // Validar que se proporcionen los datos necesarios según el rol
      if (role.isEmployee && companyId == null) {
        return AuthResult.failure('Los empleados deben tener una empresa asignada');
      }

      if (role == UserRole.seller && storeId == null) {
        return AuthResult.failure('Los vendedores deben tener una sucursal asignada');
      }

      if (role == UserRole.manager && storeId == null) {
        return AuthResult.failure('Los gerentes deben tener una sucursal asignada');
      }
      
      // Administradores de inventario NO necesitan sucursal específica (acceden a todas)

      // Crear empleado SIN credenciales de acceso
      final employeeId = await _database.insertEmployee(EmployeesCompanion.insert(
        companyId: companyId ?? 1,
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role.code,
        passwordHash: 'PENDING', // Indica que no tiene credenciales aún
        salt: 'PENDING',
        documentType: 'dni', // Valor por defecto
        isActive: const Value(false), // Inactivo hasta que admin usuarios lo active
        phone: phone != null ? Value(phone) : const Value.absent(),
        documentNumber: documentNumber ?? '',
        storeId: storeId != null ? Value(storeId) : const Value.absent(),
        warehouseId: warehouseId != null ? Value(warehouseId) : const Value.absent(),
      ));

      // Buscar el empleado creado para devolverlo
      final createdEmployee = await _database.getEmployeeById(employeeId);
      if (createdEmployee == null) {
        return AuthResult.failure('Error al crear empleado');
      }

      return AuthResult.success(createdEmployee, role);
    } catch (e) {
      return AuthResult.failure('Error al crear empleado: ${e.toString()}');
    }
  }

  /// Crear usuario con rol específico
  Future<AuthResult> createUserWithRole(
    String email,
    String password,
    String firstName,
    String lastName,
    UserRole role, {
    String? phone,
    String? documentNumber,
    int? companyId,
    int? storeId,
    int? warehouseId,
  }) async {
    try {
      // Validar que se proporcionen los datos necesarios según el rol
      if (role.isEmployee && companyId == null) {
        return AuthResult.failure('Los empleados deben tener una empresa asignada');
      }

      if (role == UserRole.seller && storeId == null) {
        return AuthResult.failure('Los vendedores deben tener una tienda asignada');
      }

      if (role == UserRole.adminInventory && warehouseId == null) {
        return AuthResult.failure('Los administradores de inventario deben tener un almacén asignado');
      }

      // Crear usuario
      final newUser = await _authService.signUpLocally(
        email,
        password,
        firstName,
        lastName,
        companyId?.toString() ?? '1',
        role.code,
        documentNumber: documentNumber,
      );

      // Actualizar datos adicionales si es necesario
      if (phone != null || documentNumber != null || storeId != null || warehouseId != null) {
        await _database.updateEmployee(EmployeesCompanion(
          id: Value(newUser.id),
          phone: phone != null ? Value(phone) : const Value.absent(),
          documentNumber: documentNumber != null ? Value(documentNumber) : const Value.absent(),
          storeId: storeId != null ? Value(storeId) : const Value.absent(),
          warehouseId: warehouseId != null ? Value(warehouseId) : const Value.absent(),
        ));
      }

      return AuthResult.success(newUser, role);
    } catch (e) {
      return AuthResult.failure('Error al crear usuario: ${e.toString()}');
    }
  }

  /// Verificar permisos de un usuario
  Future<bool> hasPermission(Employee user, Permission permission) async {
    final role = UserRole.fromCode(user.role);
    return role.hasPermission(permission);
  }

  /// Verificar si un usuario puede acceder a una funcionalidad
  Future<bool> canAccess(Employee user, List<Permission> requiredPermissions) async {
    final role = UserRole.fromCode(user.role);
    return role.canAccess(requiredPermissions);
  }

  /// Obtener usuarios por rol
  Future<List<Employee>> getUsersByRole(UserRole role) async {
    return await _database.getEmployeesByRole(role.code);
  }

  /// Obtener usuarios por tipo (admin, employee, customer)
  Future<List<Employee>> getUsersByType(UserType type) async {
    final roles = UserRole.getRolesByType(type);
    final roleCodes = roles.map((r) => r.code).toList();
    
    List<Employee> allUsers = [];
    for (String roleCode in roleCodes) {
      final users = await _database.getEmployeesByRole(roleCode);
      allUsers.addAll(users);
    }
    
    return allUsers;
  }

  /// Cambiar rol de un usuario (solo para administradores)
  Future<bool> changeUserRole(
    Employee currentUser,
    int targetUserId,
    UserRole newRole,
  ) async {
    final currentRole = UserRole.fromCode(currentUser.role);
    
    // Solo administradores de usuarios pueden cambiar roles
    if (!currentRole.hasPermission(Permission.manageUsers) && 
        !currentRole.hasPermission(Permission.manageEmployees)) {
      return false;
    }

    try {
      await _database.updateEmployee(EmployeesCompanion(
        id: Value(targetUserId),
        role: Value(newRole.code),
        updatedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Activar/desactivar usuario
  Future<bool> toggleUserActive(
    Employee currentUser,
    int targetUserId,
    bool isActive,
  ) async {
    final currentRole = UserRole.fromCode(currentUser.role);
    
    // Solo administradores pueden activar/desactivar usuarios
    if (!currentRole.hasPermission(Permission.manageUsers) && 
        !currentRole.hasPermission(Permission.manageEmployees)) {
      return false;
    }

    try {
      await _database.updateEmployee(EmployeesCompanion(
        id: Value(targetUserId),
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Crear usuarios de prueba para cada rol
  Future<void> createTestUsers() async {
    final testUsers = [
      // Administradores
      {
        'email': 'admin.usuarios@tienda.com',
        'password': '123456',
        'firstName': 'Juan',
        'lastName': 'Pérez',
        'role': UserRole.adminUsers,
        'companyId': 1,
      },
      {
        'email': 'admin.empleados@tienda.com',
        'password': '123456',
        'firstName': 'María',
        'lastName': 'González',
        'role': UserRole.adminEmployees,
        'companyId': 1,
      },
      
      // Empleados
      {
        'email': 'vendedor@tienda.com',
        'password': '123456',
        'firstName': 'Carlos',
        'lastName': 'Rodríguez',
        'role': UserRole.seller,
        'companyId': 1,
        'storeId': 1,
      },
      {
        'email': 'admin.inventario@tienda.com',
        'password': '123456',
        'firstName': 'Ana',
        'lastName': 'Martínez',
        'role': UserRole.adminInventory,
        'companyId': 1,
        'warehouseId': 1,
      },
      {
        'email': 'admin.sucursales@tienda.com',
        'password': '123456',
        'firstName': 'Luis',
        'lastName': 'Fernández',
        'role': UserRole.adminBranches,
        'companyId': 1,
      },
      {
        'email': 'gerente@tienda.com',
        'password': '123456',
        'firstName': 'Sofia',
        'lastName': 'López',
        'role': UserRole.manager,
        'companyId': 1,
      },
      
      // Cliente
      {
        'email': 'cliente@email.com',
        'password': '123456',
        'firstName': 'Pedro',
        'lastName': 'García',
        'role': UserRole.customer,
      },
    ];

    for (var userData in testUsers) {
      try {
        print('🔍 Verificando usuario: ${userData['email']}');
        final existing = await _database.getEmployeeByEmail(userData['email'] as String);
        if (existing == null) {
          print('📝 Creando usuario: ${userData['email']} con rol ${(userData['role'] as UserRole).displayName}');
          print('   - CompanyId: ${userData['companyId']}');
          print('   - StoreId: ${userData['storeId']}');
          print('   - WarehouseId: ${userData['warehouseId']}');
          
          final result = await createUserWithRole(
            userData['email'] as String,
            userData['password'] as String,
            userData['firstName'] as String,
            userData['lastName'] as String,
            userData['role'] as UserRole,
            companyId: userData['companyId'] as int?,
            storeId: userData['storeId'] as int?,
            warehouseId: userData['warehouseId'] as int?,
            documentNumber: '12345${userData.hashCode % 1000}'.padLeft(8, '0'), // Número único
          );
          
          if (result.isSuccess) {
            print('✅ Usuario creado: ${userData['email']} - Rol: ${(userData['role'] as UserRole).displayName}');
          } else {
            print('❌ Error creando usuario ${userData['email']}: ${result.errorMessage}');
          }
        } else {
          print('⚠️ Usuario ya existe: ${userData['email']}');
        }
      } catch (e) {
        print('💥 Error procesando usuario ${userData['email']}: $e');
        print('💥 Stack trace: ${e.toString()}');
      }
    }
  }

  /// Actualizar contraseña de usuario
  Future<AuthResult> updateUserPassword(int userId, String newPassword) async {
    try {
      print('🔐 Actualizando contraseña para usuario ID: $userId');
      
      // Validar nueva contraseña
      if (newPassword.length < 6) {
        return AuthResult.failure('La contraseña debe tener al menos 6 caracteres');
      }
      
      if (newPassword.length > 50) {
        return AuthResult.failure('La contraseña no puede tener más de 50 caracteres');
      }
      
      // Generar salt y hash para la nueva contraseña
      final salt = _authService.generateSalt();
      final hashedPassword = _authService.hashPasswordWithSalt(newPassword, salt);
      
      print('🔧 Hash generado para nueva contraseña');
      
      // Actualizar en la base de datos local
      await (_database.update(_database.employees)
        ..where((emp) => emp.id.equals(userId))
      ).write(EmployeesCompanion(
        passwordHash: Value(hashedPassword),
        salt: Value(salt),
        updatedAt: Value(DateTime.now()),
      ));
      
      print('✅ Contraseña actualizada en base de datos local');
      
      // TODO: Si tienes sincronización con Supabase, agregar aquí la actualización remota
      
      // Obtener el usuario actualizado
      final updatedUser = await _database.getEmployeeById(userId);
      if (updatedUser == null) {
        return AuthResult.failure('Usuario no encontrado después de la actualización');
      }
      
      final userRole = UserRole.fromCode(updatedUser.role);
      
      return AuthResult.success(updatedUser, userRole);
    } catch (e) {
      print('❌ Error actualizando contraseña: $e');
      return AuthResult.failure('Error al actualizar la contraseña: ${e.toString()}');
    }
  }

  /// Actualizar datos de usuario (sin contraseña)
  Future<AuthResult> updateUserData(
    int userId, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? documentNumber,
    UserRole? role,
    int? companyId,
    int? storeId,
    int? warehouseId,
    bool? isActive,
  }) async {
    try {
      print('👤 Actualizando datos de usuario ID: $userId');
      
      // Validar email si se proporciona
      if (email != null && email.isNotEmpty) {
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          return AuthResult.failure('Email inválido');
        }
        
        // Verificar que el email no esté en uso por otro usuario
        final existingUsers = await _database.getAllEmployees();
        final emailExists = existingUsers.any((emp) => emp.email == email && emp.id != userId);
        if (emailExists) {
          return AuthResult.failure('El email ya está en uso por otro usuario');
        }
      }
      
      // Validar número de documento si se proporciona
      if (documentNumber != null && documentNumber.isNotEmpty) {
        final existingUsers = await _database.getAllEmployees();
        final documentExists = existingUsers.any((emp) => emp.documentNumber == documentNumber && emp.id != userId);
        if (documentExists) {
          return AuthResult.failure('El número de documento ya está en uso');
        }
      }
      
      // Crear el companion con los campos a actualizar
      final companion = EmployeesCompanion(
        firstName: firstName != null ? Value(firstName) : const Value.absent(),
        lastName: lastName != null ? Value(lastName) : const Value.absent(),
        email: email != null ? Value(email) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        documentNumber: documentNumber != null ? Value(documentNumber) : const Value.absent(),
        role: role != null ? Value(role.code) : const Value.absent(),
        companyId: companyId != null ? Value(companyId) : const Value.absent(),
        storeId: storeId != null ? Value(storeId) : const Value.absent(),
        warehouseId: warehouseId != null ? Value(warehouseId) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );
      
      // Actualizar en la base de datos
      final updatedCount = await (_database.update(_database.employees)
        ..where((emp) => emp.id.equals(userId))
      ).write(companion);
      
      if (updatedCount == 0) {
        return AuthResult.failure('Usuario no encontrado');
      }
      
      print('✅ Usuario actualizado exitosamente');
      
      // TODO: Si tienes sincronización con Supabase, agregar aquí la actualización remota
      
      // Obtener el usuario actualizado
      final updatedUser = await _database.getEmployeeById(userId);
      if (updatedUser == null) {
        return AuthResult.failure('Usuario no encontrado después de la actualización');
      }
      
      final userRole = UserRole.fromCode(updatedUser.role);
      
      return AuthResult.success(updatedUser, userRole);
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      return AuthResult.failure('Error al actualizar el usuario: ${e.toString()}');
    }
  }
}

/// Resultado de operaciones de autenticación
class AuthResult {
  final bool isSuccess;
  final Employee? user;
  final UserRole? role;
  final String? errorMessage;

  AuthResult._(this.isSuccess, this.user, this.role, this.errorMessage);

  String? get message => errorMessage;

  factory AuthResult.success(Employee user, UserRole role) {
    return AuthResult._(true, user, role, null);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(false, null, null, message);
  }
}