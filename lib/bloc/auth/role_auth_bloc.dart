import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import '../../database/local_database.dart';
import '../../models/user_role.dart';
import '../../services/role_based_auth_service.dart';

// ============== EVENTS ==============
abstract class RoleAuthEvent extends Equatable {
  const RoleAuthEvent();

  @override
  List<Object?> get props => [];
}

class RoleAuthStarted extends RoleAuthEvent {}

class RoleAuthLoginRequested extends RoleAuthEvent {
  final String email;
  final String password;
  final List<UserRole>? allowedRoles;
  final bool preferOnline;

  const RoleAuthLoginRequested({
    required this.email,
    required this.password,
    this.allowedRoles,
    this.preferOnline = true,
  });

  @override
  List<Object?> get props => [email, password, allowedRoles, preferOnline];
}

class RoleAuthLogoutRequested extends RoleAuthEvent {}

class RoleAuthCreateUserRequested extends RoleAuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? phone;
  final String? documentNumber;
  final int? companyId;
  final int? storeId;
  final int? warehouseId;

  const RoleAuthCreateUserRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.documentNumber,
    this.companyId,
    this.storeId,
    this.warehouseId,
  });

  @override
  List<Object?> get props => [
    email, password, firstName, lastName, role,
    phone, documentNumber, companyId, storeId, warehouseId
  ];
}

class RoleAuthPermissionCheckRequested extends RoleAuthEvent {
  final Permission permission;

  const RoleAuthPermissionCheckRequested(this.permission);

  @override
  List<Object?> get props => [permission];
}

class RoleAuthChangeUserRoleRequested extends RoleAuthEvent {
  final int targetUserId;
  final UserRole newRole;

  const RoleAuthChangeUserRoleRequested({
    required this.targetUserId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [targetUserId, newRole];
}

class RoleAuthToggleUserActiveRequested extends RoleAuthEvent {
  final int targetUserId;
  final bool isActive;

  const RoleAuthToggleUserActiveRequested({
    required this.targetUserId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [targetUserId, isActive];
}

class RoleAuthCreateTestUsersRequested extends RoleAuthEvent {}

class RoleAuthConnectionStatusChanged extends RoleAuthEvent {
  final bool isOnline;

  const RoleAuthConnectionStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

// ============== STATES ==============
abstract class RoleAuthState extends Equatable {
  const RoleAuthState();

  @override
  List<Object?> get props => [];
}

class RoleAuthInitial extends RoleAuthState {}

class RoleAuthLoading extends RoleAuthState {}

class RoleAuthAuthenticated extends RoleAuthState {
  final Employee user;
  final UserRole role;
  final bool isOnline;
  final String? token;

  const RoleAuthAuthenticated({
    required this.user,
    required this.role,
    this.isOnline = false,
    this.token,
  });

  @override
  List<Object?> get props => [user, role, isOnline, token];

  RoleAuthAuthenticated copyWith({
    Employee? user,
    UserRole? role,
    bool? isOnline,
    String? token,
  }) {
    return RoleAuthAuthenticated(
      user: user ?? this.user,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      token: token ?? this.token,
    );
  }
}

class RoleAuthUnauthenticated extends RoleAuthState {}

class RoleAuthError extends RoleAuthState {
  final String message;
  final Exception? exception;

  const RoleAuthError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

class RoleAuthInsufficientPermissions extends RoleAuthState {
  final String message;
  final List<UserRole> requiredRoles;

  const RoleAuthInsufficientPermissions({
    required this.message,
    required this.requiredRoles,
  });

  @override
  List<Object?> get props => [message, requiredRoles];
}

class RoleAuthUserCreated extends RoleAuthState {
  final Employee user;
  final UserRole role;

  const RoleAuthUserCreated({
    required this.user,
    required this.role,
  });

  @override
  List<Object?> get props => [user, role];
}

class RoleAuthPermissionResult extends RoleAuthState {
  final Permission permission;
  final bool hasPermission;

  const RoleAuthPermissionResult({
    required this.permission,
    required this.hasPermission,
  });

  @override
  List<Object?> get props => [permission, hasPermission];
}

class RoleAuthOperationSuccess extends RoleAuthState {
  final String message;

  const RoleAuthOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============
class RoleAuthBloc extends Bloc<RoleAuthEvent, RoleAuthState> {
  final RoleBasedAuthService _authService;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Getter público para acceder al authService
  RoleBasedAuthService get authService => _authService;

  RoleAuthBloc({
    required RoleBasedAuthService authService,
    Connectivity? connectivity,
  })  : _authService = authService,
        _connectivity = connectivity ?? Connectivity(),
        super(RoleAuthInitial()) {
    
    // Registrar manejadores de eventos
    on<RoleAuthStarted>(_onAuthStarted);
    on<RoleAuthLoginRequested>(_onLoginRequested);
    on<RoleAuthLogoutRequested>(_onLogoutRequested);
    on<RoleAuthCreateUserRequested>(_onCreateUserRequested);
    on<RoleAuthPermissionCheckRequested>(_onPermissionCheckRequested);
    on<RoleAuthChangeUserRoleRequested>(_onChangeUserRoleRequested);
    on<RoleAuthToggleUserActiveRequested>(_onToggleUserActiveRequested);
    on<RoleAuthCreateTestUsersRequested>(_onCreateTestUsersRequested);
    on<RoleAuthConnectionStatusChanged>(_onConnectionStatusChanged);

    // Monitorear cambios de conectividad
    _startConnectivityMonitoring();
  }

  /// Iniciar monitoreo de conectividad
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        // Solo emitir cambios de conectividad si está autenticado
        if (state is RoleAuthAuthenticated) {
          add(RoleAuthConnectionStatusChanged(result != ConnectivityResult.none));
        }
      },
    );
  }

  /// Manejar inicio de la aplicación
  Future<void> _onAuthStarted(
    RoleAuthStarted event,
    Emitter<RoleAuthState> emit,
  ) async {
    emit(RoleAuthLoading());

    try {
      // Aquí podrías verificar si hay una sesión activa guardada
      // Por ahora, simplemente emitir estado no autenticado
      emit(RoleAuthUnauthenticated());
    } catch (e) {
      emit(RoleAuthError(
        message: 'Error al verificar sesión: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar solicitud de login con roles
  Future<void> _onLoginRequested(
    RoleAuthLoginRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    emit(RoleAuthLoading());

    try {
      final result = await _authService.loginWithRole(
        event.email,
        event.password,
        allowedRoles: event.allowedRoles,
        preferOnline: event.preferOnline,
      );

      if (result.isSuccess) {
        // Verificar conectividad
        final connectivityResult = await _connectivity.checkConnectivity();
        final isOnline = connectivityResult != ConnectivityResult.none;

        emit(RoleAuthAuthenticated(
          user: result.user!,
          role: result.role!,
          isOnline: isOnline,
        ));
      } else {
        if (event.allowedRoles != null && 
            result.errorMessage!.contains('No tienes permisos')) {
          emit(RoleAuthInsufficientPermissions(
            message: result.errorMessage!,
            requiredRoles: event.allowedRoles!,
          ));
        } else {
          emit(RoleAuthError(message: result.errorMessage!));
        }
      }
    } catch (e) {
      emit(RoleAuthError(
        message: 'Error de autenticación: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar solicitud de logout
  Future<void> _onLogoutRequested(
    RoleAuthLogoutRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    emit(RoleAuthLoading());

    try {
      // Aquí llamarías al método de logout del servicio
      // await _authService.signOut();
      emit(RoleAuthUnauthenticated());
    } catch (e) {
      emit(RoleAuthError(
        message: 'Error al cerrar sesión: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar creación de usuario
  Future<void> _onCreateUserRequested(
    RoleAuthCreateUserRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    emit(RoleAuthLoading());

    try {
      final result = await _authService.createUserWithRole(
        event.email,
        event.password,
        event.firstName,
        event.lastName,
        event.role,
        phone: event.phone,
        documentNumber: event.documentNumber,
        companyId: event.companyId,
        storeId: event.storeId,
        warehouseId: event.warehouseId,
      );

      if (result.isSuccess) {
        emit(RoleAuthUserCreated(
          user: result.user!,
          role: result.role!,
        ));
      } else {
        emit(RoleAuthError(message: result.errorMessage!));
      }
    } catch (e) {
      emit(RoleAuthError(
        message: 'Error al crear usuario: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Verificar permisos
  Future<void> _onPermissionCheckRequested(
    RoleAuthPermissionCheckRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    if (state is RoleAuthAuthenticated) {
      final currentState = state as RoleAuthAuthenticated;
      
      try {
        final hasPermission = await _authService.hasPermission(
          currentState.user,
          event.permission,
        );

        emit(RoleAuthPermissionResult(
          permission: event.permission,
          hasPermission: hasPermission,
        ));

        // Volver al estado autenticado
        emit(currentState);
      } catch (e) {
        emit(RoleAuthError(
          message: 'Error al verificar permisos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    } else {
      emit(const RoleAuthError(message: 'Usuario no autenticado'));
    }
  }

  /// Cambiar rol de usuario
  Future<void> _onChangeUserRoleRequested(
    RoleAuthChangeUserRoleRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    if (state is RoleAuthAuthenticated) {
      final currentState = state as RoleAuthAuthenticated;
      
      try {
        final success = await _authService.changeUserRole(
          currentState.user,
          event.targetUserId,
          event.newRole,
        );

        if (success) {
          emit(const RoleAuthOperationSuccess('Rol actualizado exitosamente'));
        } else {
          emit(const RoleAuthError(message: 'No tienes permisos para cambiar roles'));
        }

        // Volver al estado autenticado
        emit(currentState);
      } catch (e) {
        emit(RoleAuthError(
          message: 'Error al cambiar rol: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    } else {
      emit(const RoleAuthError(message: 'Usuario no autenticado'));
    }
  }

  /// Activar/desactivar usuario
  Future<void> _onToggleUserActiveRequested(
    RoleAuthToggleUserActiveRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    if (state is RoleAuthAuthenticated) {
      final currentState = state as RoleAuthAuthenticated;
      
      try {
        final success = await _authService.toggleUserActive(
          currentState.user,
          event.targetUserId,
          event.isActive,
        );

        if (success) {
          final action = event.isActive ? 'activado' : 'desactivado';
          emit(RoleAuthOperationSuccess('Usuario $action exitosamente'));
        } else {
          emit(const RoleAuthError(message: 'No tienes permisos para esta acción'));
        }

        // Volver al estado autenticado
        emit(currentState);
      } catch (e) {
        emit(RoleAuthError(
          message: 'Error al modificar usuario: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ));
      }
    } else {
      emit(const RoleAuthError(message: 'Usuario no autenticado'));
    }
  }

  /// Crear usuarios de prueba
  Future<void> _onCreateTestUsersRequested(
    RoleAuthCreateTestUsersRequested event,
    Emitter<RoleAuthState> emit,
  ) async {
    emit(RoleAuthLoading());

    try {
      await _authService.createTestUsers();
      emit(const RoleAuthOperationSuccess('Usuarios de prueba creados exitosamente'));
    } catch (e) {
      emit(RoleAuthError(
        message: 'Error al crear usuarios de prueba: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Manejar cambio de estado de conectividad
  Future<void> _onConnectionStatusChanged(
    RoleAuthConnectionStatusChanged event,
    Emitter<RoleAuthState> emit,
  ) async {
    if (state is RoleAuthAuthenticated) {
      final currentState = state as RoleAuthAuthenticated;
      emit(currentState.copyWith(isOnline: event.isOnline));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}