import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc_simple.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _preferOnline = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Enviar evento de login al BLoC
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: email,
        password: password,
        preferOnline: _preferOnline,
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _createTestUser() async {
    try {
      final authBloc = context.read<AuthBloc>();
      await authBloc.createTestUser(
        email: 'admin@tienda.com',
        password: '123456',
        firstName: 'Admin',
        lastName: 'Sistema',
      );
      
      _showSnackBar('Usuario de prueba creado exitosamente', Colors.green);
      
      // Auto-llenar los campos
      _emailController.text = 'admin@tienda.com';
      _passwordController.text = '123456';
    } catch (e) {
      _showSnackBar('Error al crear usuario: ${e.toString()}', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige suave
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _showSnackBar(
              'Bienvenido ${state.user.firstName}',
              Colors.green,
            );
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          } else if (state is AuthError) {
            _showSnackBar(state.message, Colors.red);
          } else if (state is AuthInvalidCredentials) {
            _showSnackBar('Credenciales incorrectas', Colors.orange);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Icono
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513), // Marrón
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Título
                    const Text(
                      'Tienda Online',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B4513),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Sistema de gestión empresarial',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5D4E37),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF8B4513),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF8B4513),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su email';
                        }
                        if (!RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$').hasMatch(value)) {
                          return 'Por favor ingrese un email válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campo Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFF8B4513),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF8B4513),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF8B4513),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Switch para modo online/offline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Intentar conexión online primero',
                          style: TextStyle(
                            color: Color(0xFF5D4E37),
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: _preferOnline,
                          onChanged: (value) {
                            setState(() {
                              _preferOnline = value;
                            });
                          },
                          activeColor: const Color(0xFF8B4513),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Botón de Login
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón para crear usuario de prueba
                    TextButton(
                      onPressed: _createTestUser,
                      child: const Text(
                        'Crear usuario de prueba',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Información de estado de conexión
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthAuthenticated) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: state.isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: state.isOnline ? Colors.green : Colors.orange,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.isOnline ? Icons.cloud_done : Icons.cloud_off,
                                  color: state.isOnline ? Colors.green : Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.isOnline ? 'Conectado' : 'Sin conexión',
                                  style: TextStyle(
                                    color: state.isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}