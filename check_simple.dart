import 'dart:io';

void main() async {
  print('🔍 Verificando el archivo de base de datos SQLite...');
  
  // Comprobar si existe el archivo de base de datos
  final dbFile = File('database.db');
  if (dbFile.existsSync()) {
    print('✅ Archivo database.db encontrado');
    final size = dbFile.lengthSync();
    print('📊 Tamaño del archivo: ${size} bytes');
  } else {
    print('❌ Archivo database.db NO encontrado');
  }
  
  print('');
  print('💡 Para crear empleados de prueba y solicitudes:');
  print('1. Ejecuta la app Flutter');
  print('2. Ve a Admin Usuarios → Crear Usuario Nuevo');
  print('3. O usa el botón debug en el dashboard de empleados');
  print('');
  print('📋 Los archivos principales del panel de notificaciones:');
  print('- lib/widgets/notifications_panel.dart');
  print('- lib/services/employee_registration_service.dart');
  print('- lib/services/role_based_auth_service.dart');
}