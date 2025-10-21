import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:math';
import '../database/local_database.dart';
import '../config/supabase_config.dart';

/// Servicio de autenticación simplificado y corregido
class SimpleAuthService {
  final LocalDatabase _database;
  SupabaseClient? get _supabase => SupabaseConfig.isConfigured ? SupabaseConfig.client : null;

  SimpleAuthService(this._database);

  // ============================================
  // MÉTODOS PRINCIPALES PARA EL BLOC
  // ============================================

  /// Obtener usuario actual de la sesión
  Future<Employee?> getCurrentUser() async {
    try {
      // Verificar primero si hay usuario en Supabase
      if (_supabase != null) {
        final user = _supabase!.auth.currentUser;
        if (user != null) {
          // Buscar employee en la base local
          final employee = await _database.getEmployeeByEmail(user.email!);
          return employee;
        }
      }
      
      // Si no hay sesión de Supabase, verificar sesión local
      // TODO: Implementar gestión de sesión local
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verificar si la sesión es válida
  Future<bool> validateSession() async {
    try {
      if (_supabase == null) return false;
      final user = _supabase!.auth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Obtener token de sesión
  Future<String?> getSessionToken() async {
    try {
      if (_supabase == null) return null;
      final session = _supabase!.auth.currentSession;
      return session?.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Login con Supabase
  Future<Employee> signInWithSupabase(String email, String password) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      final response = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Buscar employee en base local
        final employee = await _database.getEmployeeByEmail(email);
        if (employee != null) {
          return employee;
        } else {
          // Crear employee básico si no existe
          final newEmployee = EmployeesCompanion.insert(
            email: email,
            firstName: response.user!.userMetadata?['first_name'] ?? 'Usuario',
            lastName: response.user!.userMetadata?['last_name'] ?? 'Supabase',
            role: 'user',
            companyId: 1,
            documentType: 'dni',
            documentNumber: '00000000',
            passwordHash: '',
            salt: '',
            isActive: const Value(true),
          );
          
          final employeeId = await _database.insertEmployee(newEmployee);
          final createdEmployee = await _database.getEmployeeById(employeeId);
          return createdEmployee!;
        }
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      throw Exception('Error de autenticación: ${e.toString()}');
    }
  }

  /// Login local
  Future<Employee> signInLocally(String email, String password) async {
    try {
      final employee = await _database.getEmployeeByEmail(email);
      
      if (employee == null) {
        throw Exception('Usuario no encontrado');
      }

      // Verificar password
      if (_verifyPassword(password, employee.salt, employee.passwordHash)) {
        return employee;
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      throw Exception('Error de autenticación local: ${e.toString()}');
    }
  }

  /// Registro con Supabase
  Future<Employee> signUpWithSupabase(
    String email,
    String password,
    String firstName,
    String lastName,
    String companyId,
    String role,
  ) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'company_id': companyId,
          'role': role,
        },
      );

      if (response.user != null) {
        // Crear employee en base local
        final salt = _generateSalt();
        final hashedPassword = _hashPassword(password, salt);
        
        final newEmployee = EmployeesCompanion.insert(
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          companyId: int.parse(companyId),
          documentType: 'dni',
          documentNumber: '00000000',
          passwordHash: hashedPassword,
          salt: salt,
          isActive: const Value(true),
        );
        
        final employeeId = await _database.insertEmployee(newEmployee);
        final createdEmployee = await _database.getEmployeeById(employeeId);
        return createdEmployee!;
      } else {
        throw Exception('Error al crear usuario en Supabase');
      }
    } catch (e) {
      throw Exception('Error de registro: ${e.toString()}');
    }
  }

  /// Registro local
  Future<Employee> signUpLocally(
    String email,
    String password,
    String firstName,
    String lastName,
    String companyId,
    String role, {
    String? documentNumber,
    String documentType = 'dni',
  }) async {
    try {
      // Verificar si el usuario ya existe
      final existingEmployee = await _database.getEmployeeByEmail(email);
      if (existingEmployee != null) {
        throw Exception('El usuario ya existe');
      }

      // Crear nuevo usuario
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);
      
      final newEmployee = EmployeesCompanion.insert(
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        companyId: int.parse(companyId),
        documentType: documentType,
        documentNumber: documentNumber ?? '00000000',
        passwordHash: hashedPassword,
        salt: salt,
        isActive: const Value(true),
      );
      
      final employeeId = await _database.insertEmployee(newEmployee);
      final createdEmployee = await _database.getEmployeeById(employeeId);
      return createdEmployee!;
    } catch (e) {
      throw Exception('Error de registro local: ${e.toString()}');
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      if (_supabase != null) {
        await _supabase!.auth.signOut();
      }
      // TODO: Limpiar sesión local
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  /// Cambiar contraseña en Supabase
  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      await _supabase!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Error al cambiar contraseña: ${e.toString()}');
    }
  }

  /// Cambiar contraseña localmente
  Future<void> changePasswordLocally(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final employee = await _database.getEmployeeByEmail(email);
      if (employee == null) {
        throw Exception('Usuario no encontrado');
      }
      
      // Verificar contraseña actual
      if (!_verifyPassword(currentPassword, employee.salt, employee.passwordHash)) {
        throw Exception('Contraseña actual incorrecta');
      }

      // Actualizar con nueva contraseña
      final newSalt = _generateSalt();
      final newHashedPassword = _hashPassword(newPassword, newSalt);
      
      await _database.updateEmployee(EmployeesCompanion(
        id: Value(employee.id),
        passwordHash: Value(newHashedPassword),
        salt: Value(newSalt),
      ));
    } catch (e) {
      throw Exception('Error al cambiar contraseña local: ${e.toString()}');
    }
  }

  /// Recuperar contraseña (solo Supabase)
  Future<void> resetPassword(String email) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      await _supabase!.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: ${e.toString()}');
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Generar salt para password
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hash password con salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verificar password
  bool _verifyPassword(String password, String salt, String hashedPassword) {
    final hash = _hashPassword(password, salt);
    return hash == hashedPassword;
  }

  // ============================================
  // MÉTODOS PÚBLICOS PARA GESTIÓN DE CONTRASEÑAS
  // ============================================

  /// Generar salt público
  String generateSalt() {
    return _generateSalt();
  }

  /// Hash password público (con salt generado automáticamente)
  String hashPassword(String password) {
    final salt = _generateSalt();
    return _hashPassword(password, salt);
  }

  /// Hash password con salt específico
  String hashPasswordWithSalt(String password, String salt) {
    return _hashPassword(password, salt);
  }

  /// Verificar password público
  bool verifyPassword(String password, String salt, String hashedPassword) {
    return _verifyPassword(password, salt, hashedPassword);
  }
}