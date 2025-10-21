import 'package:drift/drift.dart';
import 'tables.dart'; // Importar las tablas existentes

/// Tabla para solicitudes de registro de empleados
@DataClassName('EmployeeRegistrationRequest')
class EmployeeRegistrationRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  // Referencia al empleado ya creado
  IntColumn get employeeId => integer().references(Employees, #id)();
  
  // Información laboral adicional
  TextColumn get position => text()(); // Puesto de trabajo
  RealColumn get salary => real()(); // Salario
  TextColumn get department => text()(); // Departamento
  
  // Credenciales solicitadas
  TextColumn get suggestedUsername => text()(); // Usuario sugerido
  TextColumn get suggestedRole => text()(); // Rol sugerido
  
  // Estado de la solicitud
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, approved, rejected
  TextColumn get notes => text().nullable()(); // Notas adicionales
  
  // Auditoría
  IntColumn get requestedBy => integer().references(Employees, #id)(); // Admin empleados que hizo la solicitud
  DateTimeColumn get requestedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get approvedBy => integer().nullable().references(Employees, #id)(); // Admin usuarios que aprobó
  DateTimeColumn get approvedAt => dateTime().nullable()();
  IntColumn get rejectedBy => integer().nullable().references(Employees, #id)(); // Admin usuarios que rechazó
  DateTimeColumn get rejectedAt => dateTime().nullable()();
  TextColumn get rejectionReason => text().nullable()();
  
  // Usuario creado (si fue aprobado) - Referencia al empleado actualizado
  IntColumn get createdUserId => integer().nullable().references(Employees, #id)();
}

/// Tabla para notificaciones del sistema
@DataClassName('SystemNotification')
class SystemNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  TextColumn get type => text()(); // 'employee_registration_request', 'user_account_created', etc.
  TextColumn get title => text()();
  TextColumn get message => text()();
  
  // Destinatario por rol
  TextColumn get targetRole => text()(); // 'admin_usuarios', 'admin_empleados', etc.
  
  // Datos relacionados
  IntColumn get relatedId => integer().nullable()(); // ID del objeto relacionado
  
  // Estado
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get readAt => dateTime().nullable()();
  IntColumn get readBy => integer().nullable().references(Employees, #id)();
  
  // Auditoría
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Tabla para historial de empleados
@DataClassName('EmployeeHistory')
class EmployeeHistories extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get action => text()(); // 'user_created', 'password_reset', 'role_changed', etc.
  TextColumn get description => text()();
  
  IntColumn get performedBy => integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}