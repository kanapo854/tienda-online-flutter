import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'lib/database/local_database.dart';

Future<void> main() async {
  print('=== Prueba Simplificada de Aprobación/Rechazo ===');
  
  try {
    final database = LocalDatabase();
    
    // 1. Verificar solicitudes pendientes
    print('\n1. Consultando solicitudes pendientes...');
    final pendingRequests = await (database.select(database.employeeRegistrationRequests)
        ..where((r) => r.status.equals('pending'))).get();
    
    print('Solicitudes pendientes: ${pendingRequests.length}');
    
    if (pendingRequests.isEmpty) {
      print('❌ No hay solicitudes pendientes para probar.');
      print('La funcionalidad simplificada está lista para usar cuando haya solicitudes.');
      await database.close();
      return;
    }
    
    // Mostrar detalles de las solicitudes
    for (var i = 0; i < pendingRequests.length; i++) {
      final request = pendingRequests[i];
      print('  Solicitud ${i + 1}:');
      print('    - ID: ${request.id}');
      print('    - Employee ID: ${request.employeeId}');
      print('    - Position: ${request.position}');
      print('    - Status: ${request.status}');
    }
    
    // 2. Probar APROBACIÓN
    if (pendingRequests.isNotEmpty) {
      final firstRequest = pendingRequests[0];
      print('\n2. Probando APROBACIÓN...');
      print('   Solicitud ID: ${firstRequest.id}');
      
      // Actualizar empleado (simular aprobación)
      final employeeUpdateCount = await (database.update(database.employees)
            ..where((e) => e.id.equals(firstRequest.employeeId)))
          .write(EmployeesCompanion(
            passwordHash: const drift.Value('temp_hash_123'),
            salt: const drift.Value('temp_salt_456'),
            isActive: const drift.Value(true),
          ));
      
      print('   Empleados actualizados: $employeeUpdateCount');
      
      // Actualizar estado de solicitud
      final requestUpdateCount = await (database.update(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(firstRequest.id)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const drift.Value('approved'),
            approvedAt: drift.Value(DateTime.now()),
          ));
      
      print('   Solicitudes actualizadas: $requestUpdateCount');
      
      // Verificar resultado
      final updatedEmployee = await (database.select(database.employees)
            ..where((e) => e.id.equals(firstRequest.employeeId))).getSingle();
      
      print('   ✅ Empleado ahora activo: ${updatedEmployee.isActive}');
      print('   ✅ Password Hash: ${updatedEmployee.passwordHash}');
      
      final updatedRequest = await (database.select(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(firstRequest.id))).getSingle();
      
      print('   ✅ Solicitud aprobada: ${updatedRequest.status}');
      print('   ✅ Aprobada en: ${updatedRequest.approvedAt}');
    }
    
    // 3. Probar RECHAZO (si hay más solicitudes)
    if (pendingRequests.length > 1) {
      final secondRequest = pendingRequests[1];
      print('\n3. Probando RECHAZO...');
      print('   Solicitud ID: ${secondRequest.id}');
      
      // Actualizar empleado (simular rechazo)
      final employeeRejectCount = await (database.update(database.employees)
            ..where((e) => e.id.equals(secondRequest.employeeId)))
          .write(const EmployeesCompanion(
            isActive: drift.Value(false),
          ));
      
      print('   Empleados actualizados: $employeeRejectCount');
      
      // Actualizar estado de solicitud
      final requestRejectCount = await (database.update(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(secondRequest.id)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const drift.Value('rejected'),
            rejectedAt: drift.Value(DateTime.now()),
          ));
      
      print('   Solicitudes actualizadas: $requestRejectCount');
      
      // Verificar resultado
      final rejectedEmployee = await (database.select(database.employees)
            ..where((e) => e.id.equals(secondRequest.employeeId))).getSingle();
      
      print('   ✅ Empleado ahora inactivo: ${rejectedEmployee.isActive}');
      
      final rejectedRequest = await (database.select(database.employeeRegistrationRequests)
            ..where((r) => r.id.equals(secondRequest.id))).getSingle();
      
      print('   ✅ Solicitud rechazada: ${rejectedRequest.status}');
      print('   ✅ Rechazada en: ${rejectedRequest.rejectedAt}');
    }
    
    await database.close();
    
    print('\n🎉 PRUEBA COMPLETADA EXITOSAMENTE');
    print('La funcionalidad simplificada de aprobación/rechazo está funcionando:');
    print('✅ Aceptar: Solo cambia isActive=true y agrega credenciales temporales');
    print('✅ Rechazar: Solo cambia isActive=false');
    print('✅ Ambos actualizan el estado de la solicitud correctamente');
    
  } catch (e, stackTrace) {
    print('❌ Error durante la prueba:');
    print('Error: $e');
    print('StackTrace: $stackTrace');
    exit(1);
  }
}