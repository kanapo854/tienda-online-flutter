/*import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  print('🔍 [DEBUG] Verificando solicitudes pendientes...');
  
  try {
    // Abrir la base de datos directamente
    final dbPath = p.join(Directory.current.path, 'tienda_online.db');
    final database = NativeDatabase(File(dbPath));
    
    print('📍 Ruta BD: $dbPath');
    print('📍 Archivo existe: ${File(dbPath).existsSync()}');
    
    // Verificar empleados con passwordHash PENDING
    print('\n1️⃣ EMPLEADOS CON PASSWORD PENDING:');
    final employeesResult = await database.customSelect(
      'SELECT id, first_name, last_name, role, password_hash, is_active, email FROM employees WHERE password_hash = ?',
      variables: [Variable.withString('PENDING')]
    ).get();
    
    print('Empleados PENDING encontrados: ${employeesResult.length}');
    for (var row in employeesResult) {
      print('- ID: ${row.data['id']}, Nombre: ${row.data['first_name']} ${row.data['last_name']}');
      print('  Rol: ${row.data['role']}, Activo: ${row.data['is_active']}');
      print('  Email: ${row.data['email']}');
    }
    
    // Verificar si existe la tabla de solicitudes
    print('\n2️⃣ VERIFICANDO TABLA DE SOLICITUDES:');
    try {
      final requestsResult = await database.customSelect(
        'SELECT * FROM employee_registration_requests'
      ).get();
      
      print('Solicitudes encontradas: ${requestsResult.length}');
      for (var row in requestsResult) {
        print('- ID: ${row.data['id']}, Employee ID: ${row.data['employee_id']}');
        print('  Posición: ${row.data['position']}, Status: ${row.data['status']}');
        print('  Solicitado por: ${row.data['requested_by']}');
        print('  Fecha: ${row.data['requested_at']}');
      }
    } catch (e) {
      print('❌ Error accediendo a employee_registration_requests: $e');
    }
    
    // Verificar notificaciones
    print('\n3️⃣ VERIFICANDO NOTIFICACIONES:');
    try {
      final notificationsResult = await database.customSelect(
        'SELECT * FROM system_notifications WHERE target_role = ?',
        variables: [Variable.withString('admin_usuarios')]
      ).get();
      
      print('Notificaciones para admin_usuarios: ${notificationsResult.length}');
      for (var row in notificationsResult) {
        print('- ID: ${row.data['id']}, Tipo: ${row.data['type']}');
        print('  Título: ${row.data['title']}');
        print('  Leído: ${row.data['is_read']}');
      }
    } catch (e) {
      print('❌ Error accediendo a system_notifications: $e');
    }
    
    await database.close();
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error general: $e');
  }
}*/