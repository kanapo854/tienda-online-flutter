import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../database/local_database.dart';

class EmployeeRegistrationService {
  static final EmployeeRegistrationService _instance = EmployeeRegistrationService._internal();
  factory EmployeeRegistrationService() => _instance;
  EmployeeRegistrationService._internal();

  late LocalDatabase _database;

  void initializeDatabase(LocalDatabase database) {
    _database = database;
  }

  /// Crear una solicitud de registro de empleado (agregar credenciales de acceso)
  Future<EmployeeRegistrationRequest> createEmployeeRegistrationRequest({
    required int employeeId,
    required double salary,
    required String position,
    required String department,
    required String suggestedUsername,
    required String suggestedRole,
    String? notes,
    int? requestedBy,
  }) async {
    final companion = EmployeeRegistrationRequestsCompanion(
      employeeId: Value(employeeId),
      salary: Value(salary),
      position: Value(position),
      department: Value(department),
      suggestedUsername: Value(suggestedUsername),
      suggestedRole: Value(suggestedRole),
      notes: Value(notes),
      status: const Value('pending'),
      requestedBy: Value(requestedBy ?? 1), // Por defecto empleado ID 1
      requestedAt: Value(DateTime.now()),
    );

    final requestId = await _database.into(_database.employeeRegistrationRequests)
        .insert(companion);

    // Crear notificación para admin_usuarios
    await _createNotificationForAdminUsers(
      title: 'Nueva solicitud de registro de empleado',
      message: 'Se ha solicitado crear credenciales de acceso para el empleado en el puesto: $position',
      type: 'employee_registration_request',
      relatedId: requestId,
    );

    // Obtener la solicitud creada
    return await (_database.select(_database.employeeRegistrationRequests)
        ..where((tbl) => tbl.id.equals(requestId)))
        .getSingle();
  }

  /// Obtener todas las solicitudes pendientes
  Future<List<EmployeeRegistrationRequest>> getPendingRequests() async {
    return await (_database.select(_database.employeeRegistrationRequests)
          ..where((tbl) => tbl.status.equals('pending')))
        .get();
  }

  /// Obtener solicitudes con información del empleado
  Future<List<EmployeeRegistrationRequestWithEmployee>> getRequestsWithEmployeeInfo() async {
    final query = _database.select(_database.employeeRegistrationRequests).join([
      leftOuterJoin(
        _database.employees,
        _database.employees.id.equalsExp(_database.employeeRegistrationRequests.employeeId),
      ),
    ]);

    final results = await query.get();
    
    return results.map((row) {
      final request = row.readTable(_database.employeeRegistrationRequests);
      final employee = row.readTableOrNull(_database.employees);
      
      return EmployeeRegistrationRequestWithEmployee(
        request: request,
        employee: employee,
      );
    }).toList();
  }

  /// Aprobar una solicitud y actualizar credenciales del empleado
  Future<void> approveRequest({
    required int requestId,
    required String username,
    required String password,
    required String role,
    int? approvedBy,
  }) async {
    await _database.transaction(() async {
      // Obtener la solicitud
      final request = await (_database.select(_database.employeeRegistrationRequests)
            ..where((tbl) => tbl.id.equals(requestId)))
          .getSingle();

      // Obtener el empleado
      final employee = await (_database.select(_database.employees)
            ..where((tbl) => tbl.id.equals(request.employeeId)))
          .getSingle();

      // Generar hash de la contraseña
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);

      // Actualizar el empleado con credenciales de acceso
      await (_database.update(_database.employees)
            ..where((tbl) => tbl.id.equals(employee.id)))
          .write(EmployeesCompanion(
            role: Value(role),
            passwordHash: Value(passwordHash),
            salt: Value(salt),
          ));

      // Actualizar el estado de la solicitud
      await (_database.update(_database.employeeRegistrationRequests)
            ..where((tbl) => tbl.id.equals(requestId)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const Value('approved'),
            approvedAt: Value(DateTime.now()),
            approvedBy: Value(approvedBy),
            createdUserId: Value(employee.id),
          ));

      // Crear historial
      await _createEmployeeHistory(
        employeeId: employee.id,
        action: 'credentials_created',
        description: 'Credenciales de acceso creadas con rol: $role',
        performedBy: approvedBy,
      );

      // Crear notificación de confirmación
      await _createNotificationForEmployeeAdmin(
        title: 'Solicitud aprobada',
        message: 'Se han creado exitosamente las credenciales de acceso para ${employee.firstName} ${employee.lastName}',
        type: 'registration_approved',
        relatedId: requestId,
      );
    });
  }

  /// Rechazar una solicitud
  Future<void> rejectRequest({
    required int requestId,
    required String reason,
    int? rejectedBy,
  }) async {
    await _database.transaction(() async {
      // Actualizar el estado de la solicitud
      await (_database.update(_database.employeeRegistrationRequests)
            ..where((tbl) => tbl.id.equals(requestId)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const Value('rejected'),
            rejectedAt: Value(DateTime.now()),
            rejectedBy: Value(rejectedBy),
            rejectionReason: Value(reason),
          ));

      // Obtener información para la notificación
      final request = await (_database.select(_database.employeeRegistrationRequests)
            ..where((tbl) => tbl.id.equals(requestId)))
          .getSingle();

      final employee = await (_database.select(_database.employees)
            ..where((tbl) => tbl.id.equals(request.employeeId)))
          .getSingle();

      // Crear notificación de rechazo
      await _createNotificationForEmployeeAdmin(
        title: 'Solicitud rechazada',
        message: 'La solicitud de credenciales para ${employee.firstName} ${employee.lastName} ha sido rechazada. Motivo: $reason',
        type: 'registration_rejected',
        relatedId: requestId,
      );

      // Crear historial
      await _createEmployeeHistory(
        employeeId: employee.id,
        action: 'credentials_request_rejected',
        description: 'Solicitud de credenciales rechazada. Motivo: $reason',
        performedBy: rejectedBy,
      );
    });
  }

  /// Obtener notificaciones para administradores de usuarios
  Future<List<SystemNotification>> getNotificationsForUserAdmins() async {
    return await (_database.select(_database.systemNotifications)
          ..where((tbl) => tbl.targetRole.equals('admin_usuarios'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Obtener notificaciones para administradores de empleados
  Future<List<SystemNotification>> getNotificationsForEmployeeAdmins() async {
    return await (_database.select(_database.systemNotifications)
          ..where((tbl) => tbl.targetRole.equals('admin_empleados'))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Marcar notificación como leída
  Future<void> markNotificationAsRead(int notificationId, int? readBy) async {
    await (_database.update(_database.systemNotifications)
          ..where((tbl) => tbl.id.equals(notificationId)))
        .write(SystemNotificationsCompanion(
          isRead: const Value(true),
          readAt: Value(DateTime.now()),
          readBy: Value(readBy),
        ));
  }

  /// Obtener historial de un empleado
  Future<List<EmployeeHistory>> getEmployeeHistory(int employeeId) async {
    return await (_database.select(_database.employeeHistories)
          ..where((tbl) => tbl.employeeId.equals(employeeId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  // Métodos privados auxiliares

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _createNotificationForAdminUsers({
    required String title,
    required String message,
    required String type,
    int? relatedId,
  }) async {
    final companion = SystemNotificationsCompanion(
      title: Value(title),
      message: Value(message),
      type: Value(type),
      targetRole: const Value('admin_usuarios'),
      relatedId: Value(relatedId),
      isRead: const Value(false),
      createdAt: Value(DateTime.now()),
    );

    await _database.into(_database.systemNotifications).insert(companion);
  }

  Future<void> _createNotificationForEmployeeAdmin({
    required String title,
    required String message,
    required String type,
    int? relatedId,
  }) async {
    final companion = SystemNotificationsCompanion(
      title: Value(title),
      message: Value(message),
      type: Value(type),
      targetRole: const Value('admin_empleados'),
      relatedId: Value(relatedId),
      isRead: const Value(false),
      createdAt: Value(DateTime.now()),
    );

    await _database.into(_database.systemNotifications).insert(companion);
  }

  Future<void> _createEmployeeHistory({
    required int employeeId,
    required String action,
    required String description,
    int? performedBy,
  }) async {
    final companion = EmployeeHistoriesCompanion(
      employeeId: Value(employeeId),
      action: Value(action),
      description: Value(description),
      performedBy: Value(performedBy),
      createdAt: Value(DateTime.now()),
    );

    await _database.into(_database.employeeHistories).insert(companion);
  }
}

// Clase auxiliar para devolver solicitudes con información del empleado
class EmployeeRegistrationRequestWithEmployee {
  final EmployeeRegistrationRequest request;
  final Employee? employee;

  EmployeeRegistrationRequestWithEmployee({
    required this.request,
    this.employee,
  });
}