import 'package:equatable/equatable.dart';
import '../../database/local_database.dart';

/// Estados base para autenticación
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - no sabemos si el usuario está autenticado
class AuthInitial extends AuthState {}

/// Estado de carga durante autenticación
class AuthLoading extends AuthState {}

/// Estado cuando el usuario está autenticado exitosamente
class AuthAuthenticated extends AuthState {
  final Employee user;
  final String? token;
  final bool isOnline;

  const AuthAuthenticated({
    required this.user,
    this.token,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [user, token, isOnline];

  /// Crear copia del estado con valores actualizados
  AuthAuthenticated copyWith({
    Employee? user,
    String? token,
    bool? isOnline,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      token: token ?? this.token,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Estado cuando el usuario no está autenticado
class AuthUnauthenticated extends AuthState {}

/// Estado de error durante autenticación
class AuthError extends AuthState {
  final String message;
  final Exception? exception;

  const AuthError({
    required this.message,
    this.exception,
  });

  @override
  List<Object?> get props => [message, exception];
}

/// Estado específico para errores de conexión
class AuthConnectionError extends AuthError {
  const AuthConnectionError({
    required String message,
    Exception? exception,
  }) : super(message: message, exception: exception);
}

/// Estado específico para credenciales incorrectas
class AuthInvalidCredentials extends AuthError {
  const AuthInvalidCredentials()
      : super(message: 'Credenciales incorrectas');
}

/// Estado cuando se está registrando un nuevo usuario
class AuthRegistering extends AuthState {}

/// Estado cuando el registro fue exitoso
class AuthRegistrationSuccess extends AuthState {
  final Employee newUser;

  const AuthRegistrationSuccess(this.newUser);

  @override
  List<Object?> get props => [newUser];
}

/// Estado cuando hay un error en el registro
class AuthRegistrationError extends AuthError {
  const AuthRegistrationError({
    required String message,
    Exception? exception,
  }) : super(message: message, exception: exception);
}

/// Estado durante el proceso de logout
class AuthLoggingOut extends AuthState {}

/// Estado cuando el logout fue exitoso
class AuthLoggedOut extends AuthState {}