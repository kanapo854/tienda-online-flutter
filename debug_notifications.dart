import 'package:tienda_online/database/local_database.dart';
import 'package:tienda_online/services/employee_registration_service.dart';
import 'package:tienda_online/services/role_based_auth_service.dart';
import 'package:tienda_online/services/simple_auth_service_fixed.dart';
import 'package:tienda_online/models/user_role.dart';

Future<void> main() async {
  print('🔍 === DEBUG NOTIFICACIONES ===');
  
  try {
    // Inicializar servicios
    final database = LocalDatabase();
    final authService = RoleBasedAuthService(SimpleAuthService(database), database);
    final registrationService = EmployeeRegistrationService();
    registrationService.initializeDatabase(database);
    
    print('✅ Servicios inicializados');
    
    // 1. Verificar estado actual de la BD
    print('\n📊 === ESTADO ACTUAL DE LA BD ===');
    final allEmployees = await database.getAllEmployees();
    final allRequests = await database.getPendingEmployeeRequests();
    final allNotifications = await (database.select(database.systemNotifications)).get();
    
    print('Total empleados: ${allEmployees.length}');
    print('Solicitudes pendientes: ${allRequests.length}');
    print('Total notificaciones: ${allNotifications.length}');
    
    // Filtrar empleados PENDING
    final pendingEmployees = allEmployees.where((emp) => 
      emp.passwordHash == 'PENDING' && emp.isActive == false
    ).toList();
    print('Empleados PENDING: ${pendingEmployees.length}');
    
    // 2. Crear un empleado nuevo si es necesario
    print('\n👤 === CREANDO EMPLEADO DE PRUEBA ===');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'test.empleado.$timestamp@example.com';
    
    final result = await authService.createEmployeeOnly(
      testEmail,
      'Juan',
      'Pérez',
      UserRole.seller,
      documentNumber: 'CI-$timestamp',
      companyId: 1,
      storeId: 1, // Sucursal Norte
    );
    
    if (result.isSuccess) {
      final createdEmployee = result.user!;
      print('✅ Empleado creado: ${createdEmployee.firstName} ${createdEmployee.lastName} (ID: ${createdEmployee.id})');
      
      // 3. Crear solicitud de registro (esto debe generar la notificación)
      print('\n📋 === CREANDO SOLICITUD DE REGISTRO ===');
      final request = await registrationService.createEmployeeRegistrationRequest(
        employeeId: createdEmployee.id,
        salary: 1500.0,
        position: 'Vendedor de Prueba',
        department: 'Ventas',
        suggestedUsername: 'jperez_$timestamp',
        suggestedRole: UserRole.seller.name,
        notes: 'Empleado de prueba para debugging de notificaciones',
        requestedBy: 1, // Simular que lo creó el admin de empleados
      );
      
      print('✅ Solicitud creada: ID ${request.id}');
      
      // 4. Verificar que se creó la notificación
      print('\n🔔 === VERIFICANDO NOTIFICACIONES ===');
      final newNotifications = await (database.select(database.systemNotifications)).get();
      print('Total notificaciones después: ${newNotifications.length}');
      
      // Buscar notificaciones para admin_usuarios
      final adminUserNotifications = newNotifications.where((n) => 
        n.targetRole == 'admin_usuarios'
      ).toList();
      print('Notificaciones para admin_usuarios: ${adminUserNotifications.length}');
      
      if (adminUserNotifications.isNotEmpty) {
        print('\n📮 === DETALLES DE NOTIFICACIONES ===');
        for (var notif in adminUserNotifications.take(3)) {
          print('• ID: ${notif.id}');
          print('  Título: ${notif.title}');
          print('  Mensaje: ${notif.message}');
          print('  Tipo: ${notif.type}');
          print('  Rol objetivo: ${notif.targetRole}');
          print('  Leída: ${notif.isRead}');
          print('  Creada: ${notif.createdAt}');
          print('  Related ID: ${notif.relatedId}');
          print('---');
        }
      }
      
      // 5. Verificar el servicio de notificaciones
      print('\n🎯 === VERIFICANDO SERVICIO ===');
      final serviceNotifications = await registrationService.getNotificationsForUserAdmins();
      print('Notificaciones desde servicio: ${serviceNotifications.length}');
      
      final requestsWithEmployee = await registrationService.getRequestsWithEmployeeInfo();
      print('Solicitudes con empleado: ${requestsWithEmployee.length}');
      
      final pendingRequestsWithEmployee = requestsWithEmployee.where((r) => 
        r.request.status == 'pending'
      ).toList();
      print('Solicitudes pendientes con empleado: ${pendingRequestsWithEmployee.length}');
      
      if (pendingRequestsWithEmployee.isNotEmpty) {
        print('\n📝 === DETALLES DE SOLICITUDES PENDIENTES ===');
        for (var req in pendingRequestsWithEmployee.take(3)) {
          print('• Solicitud ID: ${req.request.id}');
          print('  Empleado: ${req.employee?.firstName} ${req.employee?.lastName}');
          print('  Puesto: ${req.request.position}');
          print('  Estado: ${req.request.status}');
          print('  Solicitado por: ${req.request.requestedBy}');
          print('---');
        }
      }
      
    } else {
      print('❌ Error creando empleado: ${result.message}');
    }
    
    print('\n✅ === DEBUG COMPLETADO ===');
    
  } catch (e, stackTrace) {
    print('❌ Error durante debug: $e');
    print('Stack trace: $stackTrace');
  }
}