import 'lib/database/local_database.dart';
import 'lib/services/employee_registration_service.dart';

void main() async {
  print('🔍 [DEBUG] Iniciando debug de solicitudes pendientes...');
  
  try {
    final database = LocalDatabase();
    final service = EmployeeRegistrationService();
    service.initializeDatabase(database);
    
    // 1. Verificar todos los empleados
    print('\n1️⃣ VERIFICANDO TODOS LOS EMPLEADOS:');
    final allEmployees = await database.getAllEmployees();
    print('Total empleados: ${allEmployees.length}');
    
    for (var emp in allEmployees) {
      print('- ID: ${emp.id}, Nombre: ${emp.firstName} ${emp.lastName}');
      print('  Rol: ${emp.role}, PasswordHash: ${emp.passwordHash}, Activo: ${emp.isActive}');
      print('  Email: ${emp.email}');
    }
    
    // 2. Filtrar empleados con passwordHash PENDING
    print('\n2️⃣ EMPLEADOS CON PASSWORD PENDING:');
    final pendingEmployees = allEmployees.where((emp) => 
      emp.passwordHash == 'PENDING'
    ).toList();
    print('Empleados PENDING: ${pendingEmployees.length}');
    
    for (var emp in pendingEmployees) {
      print('- ${emp.firstName} ${emp.lastName} (${emp.role}) - ID: ${emp.id}');
      print('  Email: ${emp.email}, Activo: ${emp.isActive}');
    }
    
    // 3. Verificar solicitudes de registro
    print('\n3️⃣ VERIFICANDO SOLICITUDES DE REGISTRO:');
    final allRequests = await service.getPendingRequests();
    print('Total solicitudes en BD: ${allRequests.length}');
    
    for (var req in allRequests) {
      print('- Solicitud ID: ${req.id}');
      print('  Employee ID: ${req.employeeId}');
      print('  Posición: ${req.position}');
      print('  Status: ${req.status}');
      print('  Creado por: ${req.requestedBy}');
      print('  Fecha: ${req.requestedAt}');
    }
    
    // 4. Obtener solicitudes con información del empleado
    print('\n4️⃣ SOLICITUDES CON INFO DE EMPLEADO:');
    final requestsWithInfo = await service.getRequestsWithEmployeeInfo();
    print('Solicitudes con info empleado: ${requestsWithInfo.length}');
    
    for (var item in requestsWithInfo) {
      print('- Solicitud ID: ${item.request.id}, Status: ${item.request.status}');
      if (item.employee != null) {
        print('  Empleado: ${item.employee!.firstName} ${item.employee!.lastName}');
        print('  Email: ${item.employee!.email}');
      } else {
        print('  ❌ No se encontró empleado para ID: ${item.request.employeeId}');
      }
    }
    
    // 5. Filtrar solo pendientes
    print('\n5️⃣ SOLO SOLICITUDES PENDIENTES:');
    final pendingRequests = requestsWithInfo.where((item) => 
      item.request.status == 'pending'
    ).toList();
    print('Solicitudes pendientes: ${pendingRequests.length}');
    
    for (var item in pendingRequests) {
      print('- Solicitud ID: ${item.request.id}');
      if (item.employee != null) {
        print('  Empleado: ${item.employee!.firstName} ${item.employee!.lastName}');
        print('  Email: ${item.employee!.email}, Rol: ${item.employee!.role}');
        print('  Posición solicitada: ${item.request.position}');
      }
    }
    
    await database.close();
    print('\n✅ Debug completado');
    
  } catch (e) {
    print('❌ Error en debug: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}