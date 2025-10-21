import 'package:flutter/material.dart';

/// Sistema de roles y permisos para la aplicación
enum UserRole {
  // Roles de Administración
  adminUsers('admin_users', 'Administrador de Usuarios', UserType.admin),
  adminEmployees('admin_employees', 'Administrador de Empleados', UserType.admin),
  
  // Roles de Empleados
  seller('seller', 'Vendedor', UserType.employee),
  adminInventory('admin_inventory', 'Administrador de Inventarios', UserType.employee),
  adminBranches('admin_branches', 'Administrador de Sucursales', UserType.employee),
  manager('manager', 'Gerente', UserType.employee),
  
  // Rol de Cliente
  customer('customer', 'Cliente', UserType.customer);

  const UserRole(this.code, this.displayName, this.type);
  
  final String code;
  final String displayName;
  final UserType type;

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.customer,
    );
  }

  /// Obtener todos los roles de un tipo específico
  static List<UserRole> getRolesByType(UserType type) {
    return UserRole.values.where((role) => role.type == type).toList();
  }

  /// Obtener solo los roles de empleados (sin incluir administradores)
  static List<UserRole> getEmployeeRoles() {
    return [
      UserRole.manager,          // Gerente
      UserRole.seller,           // Vendedor
      UserRole.adminInventory,   // Administrador de Inventarios
    ];
  }

  /// Verificar si un rol tiene permisos de administración
  bool get isAdmin => type == UserType.admin;

  /// Verificar si un rol es de empleado
  bool get isEmployee => type == UserType.employee;

  /// Verificar si un rol es de cliente
  bool get isCustomer => type == UserType.customer;
}

/// Tipos de usuario en el sistema
enum UserType {
  admin('Administrador'),
  employee('Empleado'),
  customer('Cliente');

  const UserType(this.displayName);
  final String displayName;
}

/// Permisos específicos por rol
class RolePermissions {
  static const Map<UserRole, List<Permission>> _permissions = {
    // Administrador de Usuarios
    UserRole.adminUsers: [
      Permission.manageUsers,
      Permission.manageCustomers,
      Permission.viewReports,
      Permission.manageSystem,
      Permission.viewAllStores,
      Permission.viewAllWarehouses,
    ],

    // Administrador de Empleados
    UserRole.adminEmployees: [
      Permission.manageEmployees,
      Permission.viewEmployeeReports,
      Permission.manageShifts,
      Permission.viewAllStores,
    ],

    // Vendedor
    UserRole.seller: [
      Permission.processSales,
      Permission.viewProducts,
      Permission.manageCustomers,
      Permission.viewOwnSales,
    ],

    // Administrador de Inventarios
    UserRole.adminInventory: [
      Permission.manageInventory,
      Permission.manageProducts,
      Permission.managePurchases,
      Permission.manageTransfers,
      Permission.viewInventoryReports,
      Permission.viewAllWarehouses,
    ],

    // Administrador de Sucursales
    UserRole.adminBranches: [
      Permission.manageStores,
      Permission.manageEmployees,
      Permission.viewStoreReports,
      Permission.manageInventory,
      Permission.viewAllStores,
    ],

    // Gerente
    UserRole.manager: [
      Permission.viewReports,
      Permission.manageEmployees,
      Permission.manageInventory,
      Permission.manageSales,
      Permission.viewFinancialReports,
      Permission.viewAllStores,
      Permission.viewAllWarehouses,
    ],

    // Cliente
    UserRole.customer: [
      Permission.viewProducts,
      Permission.placeOrders,
      Permission.viewOwnOrders,
    ],
  };

  /// Obtener permisos de un rol específico
  static List<Permission> getPermissions(UserRole role) {
    return _permissions[role] ?? [];
  }

  /// Verificar si un rol tiene un permiso específico
  static bool hasPermission(UserRole role, Permission permission) {
    return getPermissions(role).contains(permission);
  }

  /// Verificar si un usuario puede acceder a una funcionalidad
  static bool canAccess(UserRole role, List<Permission> requiredPermissions) {
    final userPermissions = getPermissions(role);
    return requiredPermissions.any((permission) => userPermissions.contains(permission));
  }
}

/// Permisos específicos del sistema
enum Permission {
  // Gestión de usuarios
  manageUsers,
  manageCustomers,
  manageEmployees,
  
  // Gestión de productos e inventario
  manageProducts,
  manageInventory,
  managePurchases,
  manageTransfers,
  viewProducts,
  
  // Gestión de ventas
  processSales,
  manageSales,
  viewOwnSales,
  viewAllSales,
  
  // Gestión de sucursales y almacenes
  manageStores,
  manageWarehouses,
  viewAllStores,
  viewAllWarehouses,
  
  // Reportes
  viewReports,
  viewEmployeeReports,
  viewInventoryReports,
  viewStoreReports,
  viewFinancialReports,
  
  // Sistema
  manageSystem,
  manageShifts,
  
  // Cliente
  viewOwnOrders,
  placeOrders,
}

/// Extensión para facilitar el trabajo con roles
extension UserRoleExtension on UserRole {
  /// Verificar si tiene un permiso específico
  bool hasPermission(Permission permission) {
    return RolePermissions.hasPermission(this, permission);
  }

  /// Verificar si puede acceder a una lista de permisos
  bool canAccess(List<Permission> requiredPermissions) {
    return RolePermissions.canAccess(this, requiredPermissions);
  }

  /// Obtener todos los permisos del rol
  List<Permission> get permissions => RolePermissions.getPermissions(this);

  /// Verificar si es un rol de gestión (admin o gerente)
  bool get isManagementRole => this == UserRole.manager || isAdmin;

  /// Obtener el color asociado al rol para la UI
  String get colorCode {
    switch (this) {
      case UserRole.adminUsers:
      case UserRole.adminEmployees:
        return '#FF5722'; // Rojo admin
      case UserRole.manager:
        return '#9C27B0'; // Púrpura gerente
      case UserRole.adminInventory:
        return '#2196F3'; // Azul inventario
      case UserRole.adminBranches:
        return '#4CAF50'; // Verde sucursales
      case UserRole.seller:
        return '#FF9800'; // Naranja vendedor
      case UserRole.customer:
        return '#607D8B'; // Gris cliente
    }
  }

  /// Obtener el color como Color de Material
  Color get color {
    final colorCode = this.colorCode;
    final hexCode = colorCode.replaceFirst('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// Obtener icono asociado al rol
  String get iconName {
    switch (this) {
      case UserRole.adminUsers:
        return 'admin_panel_settings';
      case UserRole.adminEmployees:
        return 'people';
      case UserRole.manager:
        return 'business';
      case UserRole.adminInventory:
        return 'inventory';
      case UserRole.adminBranches:
        return 'store';
      case UserRole.seller:
        return 'point_of_sale';
      case UserRole.customer:
        return 'person';
    }
  }
}