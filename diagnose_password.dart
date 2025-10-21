import 'lib/database/local_database.dart';
import 'lib/services/simple_auth_service_fixed.dart';
import 'lib/services/role_based_auth_service.dart';

void main() async {
  print('🧪 DIAGNÓSTICO DE CAMBIO DE CONTRASEÑA');
  print('=' * 60);

  // Usar base de datos real del proyecto
  final database = LocalDatabase();
  final authService = SimpleAuthService(database);
  final roleService = RoleBasedAuthService(authService, database);

  try {
    // 1. Mostrar usuarios existentes
    print('\n1️⃣ Usuarios en la base de datos:');
    final users = await database.getAllEmployees();
    
    if (users.isEmpty) {
      print('❌ No hay usuarios en la base de datos');
      return;
    }
    
    for (var user in users) {
      print('   ID: ${user.id} | ${user.firstName} ${user.lastName} | ${user.email}');
    }

    // 2. Seleccionar usuario para prueba
    final testUser = users.firstWhere(
      (user) => user.email.contains('admin') || user.email.contains('test'),
      orElse: () => users.first,
    );
    
    print('\n2️⃣ Usuario seleccionado para prueba:');
    print('   ID: ${testUser.id}');
    print('   Nombre: ${testUser.firstName} ${testUser.lastName}');
    print('   Email: ${testUser.email}');
    print('   Salt actual: ${testUser.salt}');
    print('   Hash actual: ${testUser.passwordHash.substring(0, 20)}...');

    // 3. Probar contraseñas conocidas ANTES del cambio
    print('\n3️⃣ Probando contraseñas conocidas ANTES del cambio:');
    final commonPasswords = ['admin123', '123456', 'admin', 'password', 'test'];
    
    String? workingPassword;
    for (var password in commonPasswords) {
      try {
        final verification = authService.verifyPassword(password, testUser.salt, testUser.passwordHash);
        print('   $password: ${verification ? "✅ FUNCIONA" : "❌ No funciona"}');
        if (verification && workingPassword == null) {
          workingPassword = password;
        }
      } catch (e) {
        print('   $password: ❌ Error al verificar: $e');
      }
    }

    if (workingPassword == null) {
      print('\n❌ No se encontró una contraseña que funcione. Usando admin123 como predeterminada...');
      workingPassword = 'admin123';
    } else {
      print('\n✅ Contraseña actual encontrada: $workingPassword');
    }

    // 4. Cambiar la contraseña
    print('\n4️⃣ Cambiando contraseña a: "nuevaPassword456"');
    final changeResult = await roleService.updateUserPassword(testUser.id, 'nuevaPassword456');
    
    if (changeResult.isSuccess) {
      print('✅ Cambio de contraseña reportado como exitoso');
    } else {
      print('❌ Error al cambiar contraseña: ${changeResult.errorMessage}');
      return;
    }

    // 5. Obtener datos actualizados del usuario
    print('\n5️⃣ Verificando datos actualizados en BD:');
    final updatedUser = await database.getEmployeeById(testUser.id);
    if (updatedUser != null) {
      print('   Salt nuevo: ${updatedUser.salt}');
      print('   Hash nuevo: ${updatedUser.passwordHash.substring(0, 20)}...');
      print('   ¿Salt cambió?: ${testUser.salt != updatedUser.salt ? "SÍ" : "NO"}');
      print('   ¿Hash cambió?: ${testUser.passwordHash != updatedUser.passwordHash ? "SÍ" : "NO"}');
    }

    // 6. Probar contraseña anterior
    print('\n6️⃣ Probando contraseña anterior ($workingPassword):');
    try {
      final oldLogin = await authService.signInLocally(testUser.email, workingPassword);
      print('❌ ERROR: La contraseña anterior todavía funciona! (ID: ${oldLogin.id})');
    } catch (e) {
      print('✅ Correcto: La contraseña anterior ya no funciona');
    }

    // 7. Probar nueva contraseña
    print('\n7️⃣ Probando nueva contraseña (nuevaPassword456):');
    try {
      final newLogin = await authService.signInLocally(testUser.email, 'nuevaPassword456');
      print('✅ ÉXITO: Login con nueva contraseña funciona! (ID: ${newLogin.id})');
    } catch (e) {
      print('❌ ERROR: No puede hacer login con nueva contraseña');
      print('   Error: $e');
      
      // Verificación manual adicional
      if (updatedUser != null) {
        final manualVerification = authService.verifyPassword('nuevaPassword456', updatedUser.salt, updatedUser.passwordHash);
        print('   Verificación manual: ${manualVerification ? "✅ VÁLIDA" : "❌ INVÁLIDA"}');
        
        // Generar hash manualmente para comparar
        final manualHash = authService.hashPasswordWithSalt('nuevaPassword456', updatedUser.salt);
        print('   Hash esperado: ${manualHash.substring(0, 20)}...');
        print('   Hash en BD:    ${updatedUser.passwordHash.substring(0, 20)}...');
        print('   ¿Coinciden?: ${manualHash == updatedUser.passwordHash ? "SÍ" : "NO"}');
      }
    }

    print('\n🎯 RESUMEN:');
    print('   Usuario: ${testUser.email}');
    print('   Contraseña original: $workingPassword');
    print('   Nueva contraseña: nuevaPassword456');
    print('   Cambio exitoso: ${changeResult.isSuccess ? "SÍ" : "NO"}');
    
  } catch (e, stackTrace) {
    print('❌ Error durante el diagnóstico: $e');
    print('Stack trace: $stackTrace');
  } finally {
    await database.close();
    print('\n🏁 Diagnóstico completado');
  }
}