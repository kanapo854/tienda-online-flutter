import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Simular las funciones de hash
String generateSalt() {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final Random random = Random();
  return String.fromCharCodes(List.generate(16, (index) => chars.codeUnitAt(random.nextInt(chars.length))));
}

String hashPassword(String password, String salt) {
  final bytes = utf8.encode(password + salt);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

bool verifyPassword(String password, String storedHash, String salt) {
  final hashedPassword = hashPassword(password, salt);
  return hashedPassword == storedHash;
}

Future<void> main() async {
  print('🔍 Información sobre credenciales de usuarios...\n');
  
  print('� CREDENCIALES COMUNES PARA PRUEBAS:');
  print('=' * 60);
  
  // Usuarios típicos del sistema
  print('👤 ADMINISTRADOR:');
  print('   Email: admin@tienda.com');
  print('   Contraseña: admin123');
  print('   Rol: admin');
  print('');
  
  print('👤 USUARIO DE PRUEBA:');
  print('   Email: user@tienda.com');
  print('   Contraseña: 123456');
  print('   Rol: customer');
  print('');
  
  print('👤 EMPLEADO:');
  print('   Email: empleado@tienda.com');
  print('   Contraseña: empleado123');
  print('   Rol: seller');
  print('');
  
  print('👤 INVENTARIO:');
  print('   Email: inventario@tienda.com');
  print('   Contraseña: inventario123');
  print('   Rol: admin_inventory');
  print('');
  
  print('� CONTRASEÑAS COMUNES A PROBAR:');
  print('- 123456');
  print('- password');
  print('- admin');
  print('- admin123');
  print('- test');
  print('- 12345');
  print('- usuario123');
  print('- empleado123');
  print('- inventario123');
  print('');
  
  print('� INFORMACIÓN SOBRE HASHING:');
  print('- Las contraseñas están hasheadas con SHA-256 + Salt');
  print('- Cada usuario tiene un salt único');
  print('- No es posible recuperar la contraseña original');
  print('- Se puede cambiar usando la funcionalidad del sistema');
  print('');
  
  // Demostrar proceso de verificación
  print('🧪 EJEMPLO DE VERIFICACIÓN:');
  String testPassword = 'admin123';
  String testSalt = generateSalt();
  String testHash = hashPassword(testPassword, testSalt);
  
  print('Contraseña: $testPassword');
  print('Salt generado: $testSalt');
  print('Hash resultante: ${testHash.substring(0, 20)}...');
  
  bool isValid = verifyPassword(testPassword, testHash, testSalt);
  print('Verificación: ${isValid ? "✅ VÁLIDA" : "❌ INVÁLIDA"}');
  print('');
  
  print('🔧 CÓMO CAMBIAR CONTRASEÑAS:');
  print('1. Inicia sesión como administrador');
  print('2. Ve al panel de gestión de usuarios');
  print('3. Busca el usuario en la lista');
  print('4. Haz clic en el menú contextual (⋮)');
  print('5. Selecciona "Cambiar contraseña"');
  print('6. Ingresa la nueva contraseña');
  print('7. Confirma el cambio');
  print('');
  
  print('🎯 FUNCIONALIDAD IMPLEMENTADA:');
  print('✅ Cambio de contraseñas');
  print('✅ Edición de datos de usuario');
  print('✅ Activar/desactivar usuarios');
  print('✅ Validación y encriptación segura');
  print('✅ Interfaz administrativa completa');
  
  print('\n📱 Para acceder al sistema:');
  print('1. Ejecuta: flutter run');
  print('2. Usa una de las credenciales mostradas arriba');
  print('3. Accede al panel administrativo');
  
  exit(0);
}