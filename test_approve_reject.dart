import 'package:drift/drift.dart' as drift;
import 'lib/database/local_database.dart';

void main() async {
  print('=== Probando funcionalidad simplificada de aprobación/rechazo ===');
  
  final database = LocalDatabase();
  
  try {
    print('\n1. Consultando solicitudes pendientes...');
    final pendingRequests = await (database.select(database.employeeRegistrationRequests)
        ..where((r) => r.status.equals('pending')))
        .get();
    
    print('Solicitudes pendientes encontradas: ${pendingRequests.length}');
    for (var request in pendingRequests) {
      print('  - ID: ${request.id}, Employee ID: ${request.employeeId}, Status: ${request.status}');
    }
    
    if (pendingRequests.isNotEmpty) {
      final firstRequest = pendingRequests.first;
      print('\n2. Probando APROBACIÓN de la primera solicitud...');
      print('   Request ID: ${firstRequest.id}');
      print('   Employee ID: ${firstRequest.employeeId}');
      
      // Simular aprobación (como lo hace el método simplificado)
      print('   Actualizando empleado a activo...');
      final updateCount = await (database.update(database.employees)
            ..where((e) => e.id.equals(firstRequest.employeeId)))
          .write(EmployeesCompanion(
            passwordHash: const drift.Value('temp_password_hash'),
            salt: const drift.Value('temp_salt'),
            isActive: const drift.Value(true),
          ));
      
      print('   Empleados actualizados: $updateCount');
      
      print('   Actualizando estado de la solicitud...');
      final requestUpdateCount = await (database.update(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(firstRequest.id)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const drift.Value('approved'),
            approvedAt: drift.Value(DateTime.now()),
          ));
      
      print('   Solicitudes actualizadas: $requestUpdateCount');
      
      print('\n3. Verificando el resultado...');
      final updatedEmployee = await (database.select(database.employees)
            ..where((e) => e.id.equals(firstRequest.employeeId)))
          .getSingle();
      
      print('   Empleado actualizado:');
      print('     - ID: ${updatedEmployee.id}');
      print('     - Email: ${updatedEmployee.email}');
      print('     - Is Active: ${updatedEmployee.isActive}');
      print('     - Password Hash: ${updatedEmployee.passwordHash}');
      
      final updatedRequest = await (database.select(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(firstRequest.id)))
          .getSingle();
      
      print('   Solicitud actualizada:');
      print('     - Status: ${updatedRequest.status}');
      print('     - Approved At: ${updatedRequest.approvedAt}');
      
      print('\n✅ Prueba de APROBACIÓN completada exitosamente!');
      
      // Ahora probar rechazo con otra solicitud si existe
      if (pendingRequests.length > 1) {
        final secondRequest = pendingRequests[1];
        print('\n4. Probando RECHAZO de la segunda solicitud...');
        print('   Request ID: ${secondRequest.id}');
        print('   Employee ID: ${secondRequest.employeeId}');
        
        // Simular rechazo (como lo hace el método simplificado)
        print('   Actualizando empleado a inactivo...');
        final rejectUpdateCount = await (database.update(database.employees)
              ..where((e) => e.id.equals(secondRequest.employeeId)))
            .write(const EmployeesCompanion(
              isActive: drift.Value(false),
            ));
        
        print('   Empleados actualizados: $rejectUpdateCount');
        
        print('   Actualizando estado de la solicitud...');
        final rejectRequestUpdateCount = await (database.update(database.employeeRegistrationRequests)
              ..where((r) => r.id.equals(secondRequest.id)))
            .write(EmployeeRegistrationRequestsCompanion(
              status: const drift.Value('rejected'),
              rejectedAt: drift.Value(DateTime.now()),
            ));
        
        print('   Solicitudes actualizadas: $rejectRequestUpdateCount');
        
        print('\n5. Verificando el resultado del rechazo...');
        final rejectedEmployee = await (database.select(database.employees)
              ..where((e) => e.id.equals(secondRequest.employeeId)))
            .getSingle();
        
        print('   Empleado rechazado:');
        print('     - ID: ${rejectedEmployee.id}');
        print('     - Email: ${rejectedEmployee.email}');
        print('     - Is Active: ${rejectedEmployee.isActive}');
        
        final rejectedRequest = await (database.select(database.employeeRegistrationRequests)
              ..where((r) => r.id.equals(secondRequest.id)))
            .getSingle();
        
        print('   Solicitud rechazada:');
        print('     - Status: ${rejectedRequest.status}');
        print('     - Rejected At: ${rejectedRequest.rejectedAt}');
        
        print('\n✅ Prueba de RECHAZO completada exitosamente!');
      }
    } else {
      print('❌ No hay solicitudes pendientes para probar');
    }
    
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  } finally {
    await database.close();
    print('\n=== Prueba completada ===');
  }
}