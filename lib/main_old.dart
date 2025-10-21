import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tienda_online/screens/admin/admin_inventory_dashboard.dart';

import 'database/local_database.dart';
import 'services/simple_auth_service_fixed.dart';
import 'services/role_based_auth_service.dart';
import 'bloc/auth/role_auth_bloc.dart';
import 'screens/role_login_screen.dart';
import 'screens/admin/admin_users_dashboard.dart';
import 'screens/admin/admin_employees_dashboard.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/sales/sales_dashboard.dart';
import 'screens/branches/branches_dashboard.dart';
import 'models/user_role.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos
  final database = LocalDatabase();
  
  runApp(TiendaOnlineApp(database: database));
}

class TiendaOnlineApp extends StatelessWidget {
  final LocalDatabase database;

  const TiendaOnlineApp({
    super.key,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoleAuthBloc>(
          create: (context) {
            final authService = SimpleAuthService(database);
            final roleAuthService = RoleBasedAuthService(authService, database);
            
            return RoleAuthBloc(
              authService: roleAuthService,
              connectivity: Connectivity(),
            )..add(RoleAuthStarted());
          },
        ),
      ],
      child: MaterialApp(
        title: 'Tienda Online - Sistema de Roles',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const RoleSelectionScreen(),
        routes: {
          '/admin-login': (context) => const RoleLoginScreen(
            allowedRoles: [UserRole.adminUsers, UserRole.adminEmployees],
            title: 'Acceso Administrativo',
          ),
          '/employee-login': (context) => const RoleLoginScreen(
            allowedRoles: [
              UserRole.seller,
              UserRole.adminInventory,
              UserRole.adminBranches,
              UserRole.manager,
            ],
            title: 'Acceso Empleados',
          ),
          '/customer-login': (context) => const RoleLoginScreen(
            allowedRoles: [UserRole.customer],
            title: 'Acceso Clientes',
          ),
          '/general-login': (context) => const RoleLoginScreen(
            title: 'Acceso General',
          ),
          // Aquí agregarías las rutas de los dashboards
          '/admin-dashboard': (context) => const AdminUsersDashboard(),
          '/employees-dashboard': (context) => BlocBuilder<RoleAuthBloc, RoleAuthState>(
            builder: (context, state) {
              if (state is RoleAuthAuthenticated) {
                final authService = context.read<RoleAuthBloc>().authService;
                return AdminEmployeesDashboard(
                  authService: authService,
                  currentUser: state.user,
                  database: database,
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          '/manager-dashboard': (context) => const ManagerDashboard(),
          '/sales-dashboard': (context) => const SalesDashboard(),
          '/inventory-dashboard': (context) => BlocBuilder<RoleAuthBloc, RoleAuthState>(
            builder: (context, state) {
              if (state is RoleAuthAuthenticated) {
                final authService = context.read<RoleAuthBloc>().authService;
                return AdminInventoryDashboard(
                  authService: authService,
                  currentUser: state.user,
                  database: database,
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
          '/branches-dashboard': (context) => const BranchesDashboard(),
          '/customer-dashboard': (context) => BlocBuilder<RoleAuthBloc, RoleAuthState>(
            builder: (context, state) {
              if (state is RoleAuthAuthenticated) {
                return CustomerDashboard(database: database);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        },
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      body: BlocListener<RoleAuthBloc, RoleAuthState>(
        listener: (context, state) {
          if (state is RoleAuthOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is RoleAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo principal
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.brown[600],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título principal
                Text(
                  'Tienda Online',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.brown[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistema de Gestión Comercial',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.brown[600],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Opciones de acceso
                Text(
                  'Acceso al Sistema:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.brown[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botón de acceso general único
                SizedBox(
                  width: 300,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pushNamed('/general-login'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.brown[600],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.login,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Iniciar Sesión',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Acceso para todos los roles',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Usuarios de prueba
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.brown[600]),
                            const SizedBox(width: 8),
                            Text(
                              'Usuarios de Prueba',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        _buildUserCredential(
                          context,
                          email: 'admin.usuarios@tienda.com',
                          password: '123456',
                          role: 'Admin Usuarios',
                          icon: Icons.admin_panel_settings,
                          color: Colors.red[600]!,
                        ),
                        
                        _buildUserCredential(
                          context,
                          email: 'admin.empleados@tienda.com',
                          password: '123456',
                          role: 'Admin Empleados',
                          icon: Icons.group,
                          color: Colors.orange[600]!,
                        ),
                        
                        _buildUserCredential(
                          context,
                          email: 'ichacon@tienda.com',
                          password: '123456',
                          role: 'Admin Inventarios',
                          icon: Icons.inventory,
                          color: Colors.blue[600]!,
                        ),
                        
                        _buildUserCredential(
                          context,
                          email: 'juan@email.com',
                          password: '123456',
                          role: 'Cliente',
                          icon: Icons.shopping_cart,
                          color: Colors.green[600]!,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCredential(
    BuildContext context, {
    required String email,
    required String password,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 16,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Contraseña: $password',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}