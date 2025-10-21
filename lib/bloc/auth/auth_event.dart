import 'package:equatable/equatable.dart';

/// Eventos base para autenticación
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar si hay una sesión activa al iniciar la app
class AuthStarted extends AuthEvent {}

/// Evento para iniciar sesión
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool preferOnline; // true para intentar Supabase primero

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.preferOnline = true,
  });

  @override
  List<Object?> get props => [email, password, preferOnline];
}

/// Evento para registro de nuevo usuario
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String companyId;
  final String role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.companyId,
    required this.role,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        firstName,
        lastName,
        companyId,
        role,
      ];
}

/// Evento para cerrar sesión
class AuthLogoutRequested extends AuthEvent {}

/// Evento para actualizar el token de sesión
class AuthTokenUpdated extends AuthEvent {
  final String token;

  const AuthTokenUpdated(this.token);

  @override
  List<Object?> get props => [token];
}

/// Evento para cambiar entre modo online/offline
class AuthConnectionStatusChanged extends AuthEvent {
  final bool isOnline;

  const AuthConnectionStatusChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

/// Evento para intentar reconectar cuando se recupera la conexión
class AuthReconnectRequested extends AuthEvent {}

/// Evento para actualizar el perfil del usuario
class AuthUserProfileUpdated extends AuthEvent {
  final String firstName;
  final String lastName;
  final String? phone;

  const AuthUserProfileUpdated({
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone];
}

/// Evento para cambiar contraseña
class AuthPasswordChangeRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const AuthPasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Evento para recuperar contraseña (solo online)
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}