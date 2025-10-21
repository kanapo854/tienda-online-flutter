import 'package:tienda_online/database/local_database.dart';
import 'package:tienda_online/services/employee_registration_service.dart';
import 'package:tienda_online/services/role_based_auth_service.dart';
import 'package:tienda_online/services/simple_auth_service_fixed.dart';
import 'package:tienda_online/models/user_role.dart';

Future<void> main() async {
  print('🧪 === INICIO DEL TEST DE NOTIFICACIONES ===');
  
  try {
    // Inicializar servicios
    final database = LocalDatabase();
    final authService = RoleBasedAuthService(SimpleAuthService(database), database);
    final registrationService = EmployeeRegistrationService();
    registrationService.initializeDatabase(database);
    
    print('✅ Servicios inicializados');
    
    // 1. Verificar estado inicial de la base de datos
    print('\n📊 === ESTADO INICIAL DE LA BD ===');
    final allEmployees = await database.getAllEmployees();
    print('Total empleados: ${allEmployees.length}');
    
    final pendingEmployees = allEmployees.where((emp) => 
      emp.passwordHash == 'PENDING' && emp.isActive == false
    ).toList();
    print('Empleados PENDING: ${pendingEmployees.length}');
    
    final allRequests = await registrationService.getPendingRequests();
    print('Solicitudes pendientes: ${allRequests.length}');
    
    final allNotifications = await (database.select(database.systemNotifications)).get();
    print('Notificaciones totales: ${allNotifications.length}');
    
    // 2. Crear un empleado de prueba si no hay empleados PENDING
    if (pendingEmployees.isEmpty) {
      print('\n🏗️ === CREANDO EMPLEADO DE PRUEBA ===');
      
      final result = await authService.createEmployeeOnly(
        'test.empleado@example.com',
        'Juan',
        'Pérez',
        UserRole.seller,
        documentNumber: '12345678',
        companyId: 1,
      );
      
      if (result.isSuccess) {
        print('✅ Empleado creado: ${result.user!.firstName} ${result.user!.lastName}');
        
        // Crear solicitud de registro
        final request = await registrationService.createEmployeeRegistrationRequest(
          employeeId: result.user!.id,
          salary: 1500.0,
          position: 'Vendedor',
          department: 'Ventas',
          suggestedUsername: 'jperez',
          suggestedRole: UserRole.seller.name,
          notes: 'Empleado de prueba para testing',
          requestedBy: 1,
        );
        
        print('✅ Solicitud de registro creada: ID ${request.id}');
      } else {
        print('❌ Error creando empleado: ${result.message}');
      }
    }
    
    // 3. Verificar estado final
    print('\n📊 === ESTADO FINAL DE LA BD ===');
    final finalEmployees = await database.getAllEmployees();
    print('Total empleados: ${finalEmployees.length}');
    
    final finalPendingEmployees = finalEmployees.where((emp) => 
      emp.passwordHash == 'PENDING' && emp.isActive == false
    ).toList();
    print('Empleados PENDING: ${finalPendingEmployees.length}');
    
    final finalRequests = await registrationService.getPendingRequests();
    print('Solicitudes pendientes: ${finalRequests.length}');
    
    final finalNotifications = await (database.select(database.systemNotifications)).get();
    print('Notificaciones totales: ${finalNotifications.length}');
    
    // 4. Mostrar detalles de las solicitudes
    if (finalRequests.isNotEmpty) {
      print('\n📋 === DETALLES DE SOLICITUDES ===');
      for (var request in finalRequests) {
        print('• ID: ${request.id}');
        print('  Employee ID: ${request.employeeId}');
        print('  Position: ${request.position}');
        print('  Status: ${request.status}');
        print('  Requested by: ${request.requestedBy}');
        print('  Created at: ${request.requestedAt}');
      }
    }
    
    // 5. Mostrar detalles de las notificaciones
    if (finalNotifications.isNotEmpty) {
      print('\n🔔 === DETALLES DE NOTIFICACIONES ===');
      for (var notification in finalNotifications.take(10)) {
        print('• ID: ${notification.id}');
        print('  Title: ${notification.title}');
        print('  Target Role: ${notification.targetRole}');
        print('  Type: ${notification.type}');
        print('  Created at: ${notification.createdAt}');
      }
    }
    
    // 6. Probar el servicio de notificaciones para admin_usuarios
    print('\n🎯 === PROBANDO SERVICIO PARA ADMIN_USUARIOS ===');
    final adminNotifications = await registrationService.getNotificationsForUserAdmins();
    print('Notificaciones para admin_usuarios: ${adminNotifications.length}');
    
    final requestsWithEmployeeInfo = await registrationService.getRequestsWithEmployeeInfo();
    print('Solicitudes con info de empleado: ${requestsWithEmployeeInfo.length}');
    
    final pendingRequestsWithInfo = requestsWithEmployeeInfo.where((r) => r.request.status == 'pending').toList();
    print('Solicitudes pendientes con info: ${pendingRequestsWithInfo.length}');
    
    print('\n✅ === TEST COMPLETADO ===');
    
    // Cerrar base de datos
    await database.close();
    
  } catch (e, stackTrace) {
    print('❌ Error en el test: $e');
    print('Stack trace: $stackTrace');
  }
}