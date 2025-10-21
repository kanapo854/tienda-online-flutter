import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/role_auth_bloc.dart';
import '../models/user_role.dart';
import '../database/local_database.dart';

class RoleLoginScreen extends StatefulWidget {
  final List<UserRole>? allowedRoles;
  final String title;

  const RoleLoginScreen({
    super.key,
    this.allowedRoles,
    this.title = 'Iniciar Sesión',
  });

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: BlocListener<RoleAuthBloc, RoleAuthState>(
        listener: (context, state) {
          if (state is RoleAuthAuthenticated) {
            _showSuccessAndNavigate(context, state.user, state.role);
          } else if (state is RoleAuthError) {
            _showErrorDialog(context, state.message);
          } else if (state is RoleAuthInsufficientPermissions) {
            _showPermissionError(context, state.message, state.requiredRoles);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Icono
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.brown[600],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Título
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.brown[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtítulo con roles permitidos
                      if (widget.allowedRoles != null) ...[
                        Text(
                          'Roles permitidos: ${widget.allowedRoles!.map((r) => r.displayName).join(", ")}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.brown[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 32),
                      
                      // Formulario
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!value.contains('@')) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Opción de modo online/offline
                            /*SwitchListTile(
                              title: const Text('Preferir modo online'),
                              subtitle: Text(
                                _preferOnline 
                                  ? 'Intentará conectar con el servidor primero'
                                  : 'Usará solo la base de datos local',
                              ),
                              value: _preferOnline,
                              onChanged: (value) {
                                setState(() {
                                  _preferOnline = value;
                                });
                              },
                              activeColor: Colors.brown[600],
                            ),*/
                            const SizedBox(height: 24),
                            
                            // Botón de login
                            BlocBuilder<RoleAuthBloc, RoleAuthState>(
                              builder: (context, state) {
                                final isLoading = state is RoleAuthLoading;
                                
                                return SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown[600],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Enlaces adicionales
                      /*Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _createTestUsers,
                            child: Text(
                              'Crear usuarios',
                              style: TextStyle(color: Colors.brown[600], fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _debugDatabase,
                            child: Text(
                              'Debug BD',
                              style: TextStyle(color: Colors.red[600], fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _resetDatabase,
                            child: Text(
                              'Reset BD',
                              style: TextStyle(color: Colors.purple[600], fontSize: 12),
                            ),
                          ),
                        ],
                      ),*/
                      
                      // Información de usuarios de prueba
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Usuarios de prueba disponibles:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._buildTestUsersList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTestUsersList() {
    final testUsers = [
      {'email': 'admin.usuarios@tienda.com', 'password': '123456', 'role': 'Administrador de Usuarios'},
      {'email': 'admin.empleados@tienda.com', 'password': '123456', 'role': 'Administrador de Empleados'},
      {'email': 'ichacon@tienda.com', 'password': '123456', 'role': 'Administrador de Inventarios'},
      {'email': 'juan@email.com', 'password': '123456', 'role': 'Cliente'},
    ];

    return testUsers.map((user) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user['email']!,
                    style: const TextStyle(
                      fontSize: 11, 
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.lock, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Contraseña: ${user['password']!}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    user['role']!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )).toList();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<RoleAuthBloc>().add(
        RoleAuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          allowedRoles: widget.allowedRoles,
          preferOnline: _preferOnline,
        ),
      );
    }
  }

  void _createTestUsers() {
    context.read<RoleAuthBloc>().add(RoleAuthCreateTestUsersRequested());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creando usuarios de prueba...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _debugDatabase() async {
    try {
      final database = LocalDatabase();
      final employees = await database.getAllEmployees();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Debug - Base de Datos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: employees.isEmpty 
              ? const Center(child: Text('No hay usuarios en la base de datos'))
              : ListView.builder(
                  itemCount: employees.length,
                  itemBuilder: (context, index) {
                    final emp = employees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          emp.email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nombre: ${emp.firstName} ${emp.lastName}'),
                            Text('Documento: ${emp.documentNumber}'),
                            Text('Rol: ${emp.role}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al leer BD: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetDatabase() async {
    try {
      final database = LocalDatabase();
      
      // Confirmar la acción
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Confirmar Reset'),
          content: const Text('Esto borrará TODOS los datos de la base de datos. ¿Estás seguro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, borrar todo'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // Borrar todos los empleados
      await database.delete(database.employees).go();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Base de datos reiniciada. Ahora puedes crear usuarios de prueba.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reiniciar BD: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessAndNavigate(BuildContext context, Employee user, UserRole role) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Bienvenido, ${user.firstName}! (${role.displayName})'),
        backgroundColor: Colors.green,
      ),
    );

    // Navegar según el rol
    _navigateByRole(context, role);
  }

  void _navigateByRole(BuildContext context, UserRole role) {
    // Aquí defines a dónde navegar según el rol
    switch (role) {
      case UserRole.adminUsers:
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
        break;
      case UserRole.adminEmployees:
        Navigator.of(context).pushReplacementNamed('/employees-dashboard');
        break;
      case UserRole.manager:
        Navigator.of(context).pushReplacementNamed('/manager-dashboard');
        break;
      case UserRole.seller:
        Navigator.of(context).pushReplacementNamed('/sales-dashboard');
        break;
      case UserRole.adminInventory:
        Navigator.of(context).pushReplacementNamed('/inventory-dashboard');
        break;
      case UserRole.adminBranches:
        Navigator.of(context).pushReplacementNamed('/branches-dashboard');
        break;
      case UserRole.customer:
        Navigator.of(context).pushReplacementNamed('/customer-dashboard');
        break;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Autenticación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionError(BuildContext context, String message, List<UserRole> requiredRoles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso Denegado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Roles permitidos:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...requiredRoles.map((role) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(int.parse('0xFF${role.colorCode.substring(1)}')),
                  ),
                  const SizedBox(width: 8),
                  Text(role.displayName),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}