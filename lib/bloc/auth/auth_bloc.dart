import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../../services/simple_auth_service_fixed.dart';
import '../../database/local_database.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SimpleAuthService _authService;
  final LocalDatabase _database;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  AuthBloc({
    required SimpleAuthService authService,
    required LocalDatabase database,
    Connectivity? connectivity,
  })  : _authService = authService,
        _database = database,
        _connectivity = connectivity ?? Connectivity(),
        super(AuthInitial()) {
    
    // Registrar manejadores de eventos
    on<AuthStarted>(_onAuthStarted);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenUpdated>(_onAuthTokenUpdated);
    on<AuthConnectionStatusChanged>(_onAuthConnectionStatusChanged);
    on<AuthReconnectRequested>(_onAuthReconnectRequested);
    on<AuthUserProfileUpdated>(_onAuthUserProfileUpdated);
    on<AuthPasswordChangeRequested>(_onAuthPasswordChangeRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);

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

  /// Manejar inicio de la aplicación - verificar sesión existente
  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Verificar si hay una sesión local activa
      final currentUser = await _authService.getCurrentUser();
      
      if (currentUser != null) {
        // Verificar conectividad para determinar modo online/offline
        final connectivityResult = await _connectivity.checkConnectivity();
        final isOnline = connectivityResult != ConnectivityResult.none;

        if (isOnline) {
          // Intentar validar sesión con Supabase
          try {
            final isValidSession = await _authService.validateSession();
            if (isValidSession) {
              final token = await _authService.getSessionToken();
              emit(AuthAuthenticated(
                user: currentUser,
                token: token,
                isOnline: true,
              ));
              return;
            }
          } catch (e) {
            // Si falla la validación online, continuar en modo offline
          }
        }

        // Modo offline o fallo de validación online
        emit(AuthAuthenticated(
          user: currentUser,
          isOnline: false,
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
      Employee? user;
      String? token;
      bool isOnline = false;

      if (event.preferOnline) {
        // Verificar conectividad
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          try {
            // Intentar login online primero
            user = await _authService.signInWithSupabase(
              event.email,
              event.password,
            );
            token = await _authService.getSessionToken();
            isOnline = true;
          } catch (e) {
            // Si falla online, intentar offline
            user = await _authService.signInLocally(
              event.email,
              event.password,
            );
          }
        } else {
          // Sin conexión, usar modo offline
          user = await _authService.signInLocally(
            event.email,
            event.password,
          );
        }
      } else {
        // Login offline directo
        user = await _authService.signInLocally(
          event.email,
          event.password,
        );
      }

      emit(AuthAuthenticated(
        user: user,
        token: token,
        isOnline: isOnline,
      ));
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        emit(const AuthInvalidCredentials());
      } else if (e.toString().contains('connection') || 
                 e.toString().contains('network')) {
        emit(AuthConnectionError(
          message: 'Error de conexión: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      } else {
        emit(AuthError(
          message: 'Error de autenticación: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    }
  }

  /// Manejar solicitud de registro
  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthRegistering());

    try {
      // Verificar conectividad para Supabase
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;

      Employee? newUser;

      if (hasConnection) {
        try {
          // Intentar registro en Supabase primero
          newUser = await _authService.signUpWithSupabase(
            event.email,
            event.password,
            event.firstName,
            event.lastName,
            event.companyId,
            event.role,
          );
        } catch (e) {
          // Si falla Supabase, registrar localmente
          newUser = await _authService.signUpLocally(
            event.email,
            event.password,
            event.firstName,
            event.lastName,
            event.companyId,
            event.role,
          );
        }
      } else {
        // Sin conexión, registro local
        newUser = await _authService.signUpLocally(
          event.email,
          event.password,
          event.firstName,
          event.lastName,
          event.companyId,
          event.role,
        );
      }

      emit(AuthRegistrationSuccess(newUser));
      
      // Automáticamente autenticar al usuario después del registro
      add(AuthLoginRequested(
        email: event.email,
        password: event.password,
        preferOnline: hasConnection,
      ));
    } catch (e) {
      emit(AuthRegistrationError(
        message: 'Error en registro: ${e.toString()}',
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
      await _authService.signOut();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(
        message: 'Error al cerrar sesión: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar actualización de token
  Future<void> _onAuthTokenUpdated(
    AuthTokenUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(currentState.copyWith(token: event.token));
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
      
      // Si se recupera la conexión, intentar sincronizar
      if (event.isOnline && !currentState.isOnline) {
        add(AuthReconnectRequested());
      }
    }
  }

  /// Manejar solicitud de reconexión
  Future<void> _onAuthReconnectRequested(
    AuthReconnectRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      
      try {
        // Intentar validar sesión con Supabase
        final isValidSession = await _authService.validateSession();
        if (isValidSession) {
          final token = await _authService.getSessionToken();
          emit(currentState.copyWith(
            token: token,
            isOnline: true,
          ));
        }
      } catch (e) {
        // Mantener modo offline si falla la reconexión
        emit(currentState.copyWith(isOnline: false));
      }
    }
  }

  /// Manejar actualización de perfil
  Future<void> _onAuthUserProfileUpdated(
    AuthUserProfileUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      
      try {
        // Actualizar en base de datos local
        await _database.updateEmployee(EmployeesCompanion(
          id: Value(currentState.user.id),
          firstName: Value(event.firstName),
          lastName: Value(event.lastName),
          phone: Value(event.phone),
        ));
        
        // Obtener el usuario actualizado
        final updatedUser = await _database.getEmployeeById(currentState.user.id);
        
        // Si está online, sincronizar con Supabase
        if (currentState.isOnline) {
          // TODO: Implementar actualización en Supabase
        }
        
        emit(currentState.copyWith(user: updatedUser!));
      } catch (e) {
        emit(AuthError(
          message: 'Error al actualizar perfil: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    }
  }

  /// Manejar cambio de contraseña
  Future<void> _onAuthPasswordChangeRequested(
    AuthPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      
      try {
        if (currentState.isOnline) {
          // Cambiar contraseña en Supabase
          await _authService.changePassword(
            event.currentPassword,
            event.newPassword,
          );
        } else {
          // Cambiar contraseña localmente
          await _authService.changePasswordLocally(
            currentState.user.email,
            event.currentPassword,
            event.newPassword,
          );
        }
        
        // Estado permanece igual, solo mostrar éxito via listener
        
      } catch (e) {
        emit(AuthError(
          message: 'Error al cambiar contraseña: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    }
  }

  /// Manejar recuperación de contraseña
  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authService.resetPassword(event.email);
      // Estado permanece igual, solo mostrar éxito via listener
    } catch (e) {
      emit(AuthError(
        message: 'Error al enviar correo de recuperación: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}