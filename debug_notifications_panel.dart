/*import 'lib/database/local_database.dart';
import 'lib/services/employee_registration_service.dart';
import 'lib/services/role_based_auth_service.dart';
import 'lib/services/simple_auth_service_fixed.dart';
import 'lib/models/user_role.dart';

void main() async {
  print('🔧 DEBUG: Iniciando debugging del panel de notificaciones...');
  
  try {
    final database = LocalDatabase();
    final authService = RoleBasedAuthService(SimpleAuthService(database), database);
    final registrationService = EmployeeRegistrationService();
    registrationService.initializeDatabase(database);
    
    print('✅ Servicios inicializados correctamente');
    
    // 1. Verificar si hay empleados pending
    print('\n📊 1. Verificando empleados PENDING...');
    final allEmployees = await database.getAllEmployees();
    final pendingEmployees = allEmployees.where((emp) => 
      emp.passwordHash == 'PENDING' && 
      UserRole.getEmployeeRoles().map((r) => r.code).contains(emp.role)
    ).toList();
    
    print('👥 Total empleados: ${allEmployees.length}');
    print('⏳ Empleados PENDING: ${pendingEmployees.length}');
    
    for (var emp in pendingEmployees) {
      print('   - ${emp.firstName} ${emp.lastName} (${emp.role}) - ID: ${emp.id}');
    }
    
    // 2. Verificar si hay solicitudes de registro
    /*print('\n📋 2. Verificando solicitudes de registro...');
    final allRequests = await registrationService.getAllRegistrationRequests();
    final pendingRequests = allRequests.where((req) => req.status == 'pending').toList();
    
    print('📜 Total solicitudes: ${allRequests.length}');
    print('⏳ Solicitudes PENDING: ${pendingRequests.length}');
    
    for (var req in pendingRequests) {
      print('   - Solicitud ID: ${req.id} para empleado ID: ${req.employeeId}');
      print('     Estado: ${req.status}, Usuario sugerido: ${req.suggestedUsername}');
    }
    
    // 3. Verificar notificaciones
    print('\n🔔 3. Verificando notificaciones...');
    final notifications = await registrationService.getNotificationsForUserAdmins();
    print('🔔 Notificaciones para admin_usuarios: ${notifications.length}');
    
    for (var notif in notifications.take(5)) {
      print('   - ${notif.title}: ${notif.message}');
      print('     Tipo: ${notif.type}, Leída: ${notif.isRead}');
    }
    
    // 4. Si hay solicitudes pending, probar aprobación
    if (pendingRequests.isNotEmpty) {
      print('\n✅ 4. Probando aprobación de solicitud...');
      final testRequest = pendingRequests.first;
      
      try {
        await registrationService.approveRequest(
          requestId: testRequest.id,
          username: testRequest.suggestedUsername,
          password: 'test123',
          role: testRequest.suggestedRole,
          approvedBy: 1, // Usar ID de usuario de prueba
        );
        print('✅ Aprobación exitosa para solicitud ID: ${testRequest.id}');
      } catch (e) {
        print('❌ Error en aprobación: $e');
      }
    } else if (pendingEmployees.isNotEmpty) {
      print('\n🆕 4. Creando solicitud de registro para empleado pending...');
      final testEmployee = pendingEmployees.first;
      
      try {
        await registrationService.createEmployeeRegistrationRequest(
          employeeId: testEmployee.id,
          salary: 1500.0,
          position: 'Vendedor de Prueba',
          department: 'Ventas',
          suggestedUsername: 'test_${testEmployee.firstName.toLowerCase()}',
          suggestedRole: testEmployee.role,
          notes: 'Solicitud creada para debugging',
          requestedBy: 1,
        );
        print('✅ Solicitud creada para empleado ID: ${testEmployee.id}');
      } catch (e) {
        print('❌ Error creando solicitud: $e');
      }
    } else {
      print('\n🆕 4. Creando empleado de prueba para debugging...');
      
      try {
        final result = await authService.createEmployeeOnly(
          'debug.test.${DateTime.now().millisecondsSinceEpoch}@example.com',
          'Debug',
          'Test Employee',
          UserRole.seller,
          documentNumber: 'DEBUG${DateTime.now().millisecondsSinceEpoch}',
          companyId: 1,
          storeId: 1,
        );
        
        if (result.isSuccess) {
          print('✅ Empleado de prueba creado: ${result.user!.firstName} ${result.user!.lastName} - ID: ${result.user!.id}');
          
          // Crear solicitud para este empleado
          await registrationService.createEmployeeRegistrationRequest(
            employeeId: result.user!.id,
            salary: 1500.0,
            position: 'Vendedor de Prueba',
            department: 'Ventas',
            suggestedUsername: 'debug_seller',
            suggestedRole: UserRole.seller.code,
            notes: 'Empleado de debug creado automáticamente',
            requestedBy: 1,
          );
          print('✅ Solicitud creada para empleado de debug');
        } else {
          print('❌ Error creando empleado de prueba: ${result.message}');
        }
      } catch (e) {
        print('❌ Error inesperado: $e');
      }
    }
    
    print('\n🎯 DEBUG completado. Revisa los resultados arriba.');
    
  } catch (e) {
    print('❌ ERROR CRÍTICO: $e');
  }
}*/*/