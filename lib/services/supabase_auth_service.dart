import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import '../config/supabase_config.dart';
import '../database/local_database.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SupabaseAuthService {
  final LocalDatabase _localDb = LocalDatabase();
  SupabaseClient? get _supabase => SupabaseConfig.isConfigured ? SupabaseConfig.client : null;

  // ============================================
  // AUTENTICACIÓN ONLINE (SUPABASE)
  // ============================================

  /// Registro de usuario en Supabase + Local
  Future<Map<String, dynamic>> registerWithSupabase({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required int companyId,
    int? storeId,
    int? warehouseId,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      // 1. Registrar en Supabase Auth
      final authResponse = await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'company_id': companyId,
          'store_id': storeId,
          'warehouse_id': warehouseId,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Error creando usuario en Supabase');
      }

      // 2. Crear registro en tabla employees
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      final employeeData = {
        'company_id': companyId,
        'store_id': storeId,
        'warehouse_id': warehouseId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'role': role,
        'password_hash': hashedPassword,
        'salt': salt,
        'is_active': true,
      };

      // Insertar en Supabase
      final employeeResponse = await _supabase!
          .from('employees')
          .insert(employeeData)
          .select()
          .single();

      // 3. También guardar localmente
      await _localDb.insertEmployee(EmployeesCompanion.insert(
        companyId: companyId,
        storeId: Value(storeId),
        warehouseId: Value(warehouseId),
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
        documentType: 'dni', // Valor por defecto
        documentNumber: '00000000', // Valor por defecto
        passwordHash: hashedPassword,
        salt: salt,
        needsSync: const Value(false), // Ya está sincronizado
      ));

      return {
        'success': true,
        'user': authResponse.user,
        'employee': employeeResponse,
        'message': 'Usuario registrado exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Login con Supabase
  Future<Map<String, dynamic>> loginWithSupabase({
    required String email,
    required String password,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase no configurado');
    }

    try {
      // 1. Autenticar con Supabase
      final authResponse = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Credenciales incorrectas');
      }

      // 2. Obtener datos del empleado
      final employeeResponse = await _supabase!
          .from('employees')
          .select('*')
          .eq('email', email)
          .single();

      // 3. Actualizar último login
      await _supabase!
          .from('employees')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('email', email);

      // 4. Crear sesión local
      final sessionToken = _generateSessionToken();
      final expiresAt = DateTime.now().add(const Duration(hours: 8));

      await _localDb.insertSession(UserSessionsCompanion.insert(
        employeeId: employeeResponse['id'],
        sessionToken: sessionToken,
        expiresAt: expiresAt,
      ));

      return {
        'success': true,
        'user': authResponse.user,
        'employee': employeeResponse,
        'session_token': sessionToken,
        'message': 'Login exitoso',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Logout de Supabase
  Future<void> logoutFromSupabase() async {
    if (_supabase != null) {
      await _supabase!.auth.signOut();
    }
  }

  /// Verificar si hay sesión activa en Supabase
  bool get isLoggedInSupabase {
    return _supabase?.auth.currentUser != null;
  }

  /// Obtener usuario actual de Supabase
  User? get currentSupabaseUser {
    return _supabase?.auth.currentUser;
  }

  // ============================================
  // AUTENTICACIÓN LOCAL (OFFLINE)
  // ============================================

  /// Login offline con base de datos local
  Future<Map<String, dynamic>> loginLocal({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Buscar empleado por email
      final employee = await _localDb.getEmployeeByEmail(email);
      
      if (employee == null) {
        return {
          'success': false,
          'error': 'Usuario no encontrado',
        };
      }

      // 2. Verificar contraseña
      final isValidPassword = _verifyPassword(password, employee.salt, employee.passwordHash);
      
      if (!isValidPassword) {
        return {
          'success': false,
          'error': 'Contraseña incorrecta',
        };
      }

      // 3. Verificar que esté activo
      if (!employee.isActive) {
        return {
          'success': false,
          'error': 'Usuario desactivado',
        };
      }

      // 4. Crear sesión local
      final sessionToken = _generateSessionToken();
      final expiresAt = DateTime.now().add(const Duration(hours: 8));

      await _localDb.insertSession(UserSessionsCompanion.insert(
        employeeId: employee.id,
        sessionToken: sessionToken,
        expiresAt: expiresAt,
      ));

      // 5. Actualizar último login (marcar para sync)
      await _localDb.updateEmployee(EmployeesCompanion(
        id: Value(employee.id),
        lastLogin: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ));

      return {
        'success': true,
        'employee': employee,
        'session_token': sessionToken,
        'message': 'Login offline exitoso',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ============================================
  // GESTIÓN DE SESIONES
  // ============================================

  /// Verificar si hay una sesión válida
  Future<bool> hasValidSession(String sessionToken) async {
    final session = await _localDb.getActiveSession(sessionToken);
    
    if (session == null) return false;
    if (!session.isActive) return false;
    if (session.expiresAt.isBefore(DateTime.now())) {
      // Sesión expirada, desactivar
      await _localDb.deactivateSession(sessionToken);
      return false;
    }
    
    return true;
  }

  /// Cerrar sesión local
  Future<void> logoutLocal(String sessionToken) async {
    await _localDb.deactivateSession(sessionToken);
  }

  // ============================================
  // UTILIDADES PRIVADAS
  // ============================================

  String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String salt, String hashedPassword) {
    final computedHash = _hashPassword(password, salt);
    return computedHash == hashedPassword;
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // ============================================
  // SYNC DE AUTENTICACIÓN
  // ============================================

  /// Sincronizar cambios de empleados con Supabase
  Future<void> syncEmployeeChanges() async {
    if (_supabase == null) return;

    try {
      // Obtener empleados que necesitan sincronización
      final localChanges = await _localDb.getItemsNeedingSync('employees');

      for (final employeeData in localChanges) {
        try {
          // Subir cambios a Supabase
          await _supabase!.from('employees').upsert(employeeData);
          
          // Marcar como sincronizado
          await _localDb.markAsSynced(
            _localDb.employees, 
            employeeData['id'],
          );
        } catch (e) {
          print('Error sincronizando empleado ${employeeData['id']}: $e');
        }
      }
    } catch (e) {
      print('Error sincronizando empleados: $e');
    }
  }
} 