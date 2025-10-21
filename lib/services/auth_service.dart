import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL'; // Reemplazar con tu URL
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // Reemplazar con tu clave
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Generar salt para password
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }
  
  // Hash password con salt
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verificar password
  bool _verifyPassword(String password, String salt, String hashedPassword) {
    final hash = _hashPassword(password, salt);
    return hash == hashedPassword;
  }
  
  // Registro de usuario en Supabase
  Future<AuthResponse> registerUser({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // Login con email y password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
  
  // Obtener usuario actual
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  // Verificar si está autenticado
  bool get isAuthenticated => _supabase.auth.currentUser != null;
  
  // Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Recuperar password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
  
  // Actualizar password
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
  
  // Actualizar perfil de usuario
  Future<UserResponse> updateProfile(Map<String, dynamic> data) async {
    return await _supabase.auth.updateUser(
      UserAttributes(data: data),
    );
  }
}

class LocalAuthService {
  // Para autenticación offline cuando no hay conexión a Supabase
  
  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }
  
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }
  
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  bool _verifyPassword(String password, String salt, String hashedPassword) {
    final hash = _hashPassword(password, salt);
    return hash == hashedPassword;
  }
  
  // Preparar datos de empleado para crear hash de password
  Map<String, String> prepareEmployeeAuth(String password) {
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    
    return {
      'salt': salt,
      'passwordHash': hash,
    };
  }
  
  // Verificar login local
  bool verifyLocalLogin(String password, String salt, String storedHash) {
    return _verifyPassword(password, salt, storedHash);
  }
  
  // Generar token de sesión
  String generateSessionToken() {
    return _generateSessionToken();
  }
  
  // Verificar si la sesión es válida
  bool isSessionValid(DateTime expiresAt) {
    return DateTime.now().isBefore(expiresAt);
  }
  
  // Generar fecha de expiración de sesión (8 horas)
  DateTime getSessionExpiration() {
    return DateTime.now().add(const Duration(hours: 8));
  }
}