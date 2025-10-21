import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import 'dart:math';
import '../../database/local_database.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LocalDatabase _database;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Employee? _currentUser;

  AuthBloc({
    required LocalDatabase database,
    Connectivity? connectivity,
  })  : _database = database,
        _connectivity = connectivity ?? Connectivity(),
        super(AuthInitial()) {
    
    // Registrar manejadores de eventos básicos
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthConnectionStatusChanged>(_onAuthConnectionStatusChanged);

    // Monitorear cambios de conectividad
    _startConnectivityMonitoring();
  }

  /// Iniciar monitoreo de conectividad
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final isOnline = result != ConnectivityResult.none;
        add(AuthConnectionStatusChanged(isOnline));
      },
    );
  }

  /// Manejar inicio de la aplicación
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Por ahora, simplemente verificar si hay empleados en la base
      final employees = await _database.getAllEmployees();
      
      if (employees.isNotEmpty) {
        // Si hay empleados, usar el primero como usuario temporal
        // En una implementación real, manejarías sesiones guardadas
        _currentUser = employees.first;
        
        final connectivityResult = await _connectivity.checkConnectivity();
        final isOnline = connectivityResult != ConnectivityResult.none;
        
        emit(AuthAuthenticated(
          user: _currentUser!,
          isOnline: isOnline,
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(
        message: 'Error al verificar sesión: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar solicitud de login
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Buscar empleado por email
      final employee = await _database.getEmployeeByEmail(event.email);
      
      if (employee != null) {
        // Verificar contraseña
        if (_verifyPassword(event.password, employee.salt, employee.passwordHash)) {
          _currentUser = employee;
          
          final connectivityResult = await _connectivity.checkConnectivity();
          final isOnline = connectivityResult != ConnectivityResult.none;
          
          emit(AuthAuthenticated(
            user: employee,
            isOnline: isOnline,
          ));
        } else {
          emit(const AuthInvalidCredentials());
        }
      } else {
        emit(const AuthInvalidCredentials());
      }
    } catch (e) {
      emit(AuthError(
        message: 'Error de autenticación: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar solicitud de logout
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoggingOut());

    try {
      _currentUser = null;
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(
        message: 'Error al cerrar sesión: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar cambio de estado de conexión
  Future<void> _onAuthConnectionStatusChanged(
    AuthConnectionStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(isOnline: event.isOnline));
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES PARA AUTENTICACIÓN
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

  /// Crear usuario para testing/demo
  Future<Employee> createTestUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final salt = _generateSalt();
    final hashedPassword = _hashPassword(password, salt);
    
    final newEmployee = EmployeesCompanion.insert(
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: 'admin',
      companyId: 1,
      documentType: 'dni',
      documentNumber: '12345678',
      passwordHash: hashedPassword,
      salt: salt,
      isActive: const Value(true),
    );
    
    final employeeId = await _database.insertEmployee(newEmployee);
    final createdEmployee = await _database.getEmployeeById(employeeId);
    return createdEmployee!;
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}