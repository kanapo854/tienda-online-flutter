import 'dart:io';

void main() async {
  print('🧪 === TEST SIMPLE DE VERIFICACIÓN ===');
  
  // Verificar que los archivos existen
  final projectDir = Directory('g:\\Maestria\\ESP2\\Proyecto_Final\\ProyectoFlutter\\tienda_online');
  print('📁 Directorio del proyecto existe: ${projectDir.existsSync()}');
  
  final libDir = Directory('${projectDir.path}/lib');
  print('📁 Directorio lib existe: ${libDir.existsSync()}');
  
  // Verificar archivos clave
  final files = [
    'lib/widgets/notifications_panel.dart',
    'lib/services/employee_registration_service.dart',
    'lib/screens/admin/admin_employees_dashboard.dart',
    'lib/screens/admin/admin_users_dashboard.dart',
    'lib/database/local_database.dart',
  ];
  
  for (final filePath in files) {
    final file = File('${projectDir.path}/$filePath');
    print('📄 $filePath existe: ${file.existsSync()}');
  }
  
  print('\n🔍 === REVISANDO CONTENIDO CLAVE ===');
  
  // Verificar que el panel de notificaciones tiene el método debug
  final notificationsPanelFile = File('${projectDir.path}/lib/widgets/notifications_panel.dart');
  if (notificationsPanelFile.existsSync()) {
    final content = await notificationsPanelFile.readAsString();
    final hasDebugMethod = content.contains('_showDebugInfo');
    final hasDebugButton = content.contains('bug_report');
    print('🐛 Panel tiene método debug: $hasDebugMethod');
    print('🐛 Panel tiene botón debug: $hasDebugButton');
  }
  
  // Verificar que el dashboard de empleados usa createEmployeeOnly
  final employeesDashboardFile = File('${projectDir.path}/lib/screens/admin/admin_employees_dashboard.dart');
  if (employeesDashboardFile.existsSync()) {
    final content = await employeesDashboardFile.readAsString();
    final usesCreateEmployeeOnly = content.contains('createEmployeeOnly');
    final sendsNotification = content.contains('createEmployeeRegistrationRequest');
    print('👥 Dashboard usa createEmployeeOnly: $usesCreateEmployeeOnly');
    print('📬 Dashboard envía notificaciones: $sendsNotification');
  }
  
  print('\n✅ === VERIFICACIÓN COMPLETADA ===');
}