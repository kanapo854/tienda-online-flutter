import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/local_database.dart';
import '../../services/employee_registration_service.dart';
import '../../models/user_role.dart';

class NotificationsPanel extends StatefulWidget {
  final String targetRole;
  final int? currentUserId;

  const NotificationsPanel({
    Key? key,
    required this.targetRole,
    this.currentUserId,
  }) : super(key: key);

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final EmployeeRegistrationService _service = EmployeeRegistrationService();
  LocalDatabase? _database;
  List<SystemNotification> _notifications = [];
  List<EmployeeRegistrationRequestWithEmployee> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      _database = LocalDatabase();
      _service.initializeDatabase(_database!);
      await _loadNotifications();
      await _loadPendingRequests();
    } catch (e) {
      print('Error initializing database: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      List<SystemNotification> notifications;
      if (widget.targetRole == 'admin_usuarios') {
        notifications = await _service.getNotificationsForUserAdmins();
      } else {
        notifications = await _service.getNotificationsForEmployeeAdmins();
      }
      
      if (mounted) {
        setState(() => _notifications = notifications);
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      if (widget.targetRole == 'admin_usuarios') {
        print('📋 [DEBUG] Cargando empleados pendientes para admin_usuarios...');
        print('📋 [DEBUG] Database inicializada: ${_database != null}');
        
        // Obtener empleados que tienen passwordHash = 'PENDING'
        final allEmployees = await _database!.getAllEmployees();
        print('📋 [DEBUG] Total empleados en BD: ${allEmployees.length}');
        
        // Filtrar empleados pendientes (sin credenciales de acceso)
        final pendingEmployees = allEmployees.where((emp) => 
          emp.passwordHash == 'PENDING'
        ).toList();
        print('📋 [DEBUG] Empleados con PENDING: ${pendingEmployees.length}');
        
        for (var emp in pendingEmployees) {
          print('📋 [DEBUG] - Empleado PENDING: ${emp.firstName} ${emp.lastName} (ID: ${emp.id}, Rol: ${emp.role}, Activo: ${emp.isActive})');
        }
        
        // Crear solicitudes mock basadas en los empleados pendientes
        final pendingRequests = <EmployeeRegistrationRequestWithEmployee>[];
        for (var employee in pendingEmployees) {
          // Crear una solicitud mock para cada empleado pendiente
          final mockRequest = EmployeeRegistrationRequest(
            id: employee.id, // Usar ID del empleado como ID de solicitud
            employeeId: employee.id,
            position: employee.role, // Usar el rol como posición
            salary: 0.0, // Valor por defecto
            department: 'Pendiente', // Valor por defecto
            suggestedUsername: employee.email.split('@')[0], // Usar parte del email como username
            suggestedRole: UserRole.fromCode(employee.role).name,
            status: 'pending',
            notes: 'Empleado creado, pendiente de credenciales de acceso',
            requestedBy: 1, // Admin por defecto
            requestedAt: employee.createdAt,
            approvedBy: null,
            approvedAt: null,
            rejectedBy: null,
            rejectedAt: null,
            rejectionReason: null,
            createdUserId: null,
          );
          
          pendingRequests.add(EmployeeRegistrationRequestWithEmployee(
            request: mockRequest,
            employee: employee,
          ));
        }
        
        print('📋 [DEBUG] Solicitudes mock creadas: ${pendingRequests.length}');
        
        if (mounted) {
          setState(() => _pendingRequests = pendingRequests);
        }
      }
    } catch (e) {
      print('❌ [ERROR] Error loading pending requests: $e');
      print('❌ [ERROR] Stack trace: ${StackTrace.current}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: widget.targetRole == 'admin_usuarios' ? 2 : 1,
      child: Column(
        children: [
          if (widget.targetRole == 'admin_usuarios')
            const TabBar(
              tabs: [
                Tab(text: 'Solicitudes Pendientes'),
                Tab(text: 'Notificaciones'),
              ],
            ),
          Expanded(
            child: widget.targetRole == 'admin_usuarios'
                ? TabBarView(
                    children: [
                      _buildPendingRequestsTab(),
                      _buildNotificationsTab(),
                    ],
                  )
                : _buildNotificationsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    return Column(
      children: [
        // Botones de control y debug
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solicitudes pendientes (${_pendingRequests.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  // Botón de debug
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.orange),
                    onPressed: _showDebugInfo,
                    tooltip: 'Ver información de debug',
                  ),
                  // Botón de refresh
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _loadPendingRequests();
                      await _loadNotifications();
                      setState(() => _isLoading = false);
                    },
                    tooltip: 'Actualizar solicitudes',
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _pendingRequests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes pendientes',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las solicitudes aparecerán aquí cuando el admin de empleados registre nuevos empleados',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final requestWithEmployee = _pendingRequests[index];
        final request = requestWithEmployee.request;
        final employee = requestWithEmployee.employee;

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Text(
              employee != null 
                  ? '${employee.firstName} ${employee.lastName}'
                  : 'Empleado ID: ${request.employeeId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Puesto: ${request.position} - Departamento: ${request.department}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Email:', employee?.email ?? 'N/A'),
                    _buildInfoRow('Teléfono:', employee?.phone ?? 'N/A'),
                    _buildInfoRow('Salario propuesto:', 'S/ ${request.salary.toStringAsFixed(2)}'),
                    _buildInfoRow('Usuario sugerido:', request.suggestedUsername),
                    _buildInfoRow('Rol sugerido:', request.suggestedRole),
                    if (request.notes != null && request.notes!.isNotEmpty)
                      _buildInfoRow('Notas:', request.notes!),
                    _buildInfoRow('Fecha de solicitud:', 
                        request.requestedAt.toString().substring(0, 19)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _approveRequest(request),
                          icon: const Icon(Icons.check),
                          label: const Text('Aceptar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _rejectRequest(request),
                          icon: const Icon(Icons.close),
                          label: const Text('Rechazar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
            ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return const Center(
        child: Text('No hay notificaciones'),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          color: notification.isRead ? null : Colors.blue.shade50,
          child: ListTile(
            leading: Icon(
              _getNotificationIcon(notification.type),
              color: notification.isRead ? Colors.grey : Colors.blue,
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  notification.createdAt.toString().substring(0, 19),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: notification.isRead 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    onPressed: () => _markAsRead(notification),
                  ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'employee_registration_request':
        return Icons.person_add;
      case 'registration_approved':
        return Icons.check_circle;
      case 'registration_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(SystemNotification notification) async {
    try {
      await _service.markNotificationAsRead(notification.id, widget.currentUserId);
      await _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al marcar como leída: $e')),
      );
    }
  }

  Future<void> _approveRequest(EmployeeRegistrationRequest request) async {
    try {
      // Obtener el empleado
      final employee = await (_database!.select(_database!.employees)
            ..where((emp) => emp.id.equals(request.employeeId)))
          .getSingle();

      // Generar credenciales simples
      final password = 'temp${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = 'hash_$password'; // Simplificado para testing
      final salt = 'salt_${DateTime.now().millisecondsSinceEpoch}';

      // Activar el empleado - solo cambiar estado
      await (_database!.update(_database!.employees)
            ..where((emp) => emp.id.equals(employee.id)))
          .write(EmployeesCompanion(
            passwordHash: drift.Value(passwordHash),
            salt: drift.Value(salt),
            isActive: const drift.Value(true),
          ));

      // Marcar la solicitud como aprobada
      await (_database!.update(_database!.employeeRegistrationRequests)
            ..where((req) => req.id.equals(request.id)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const drift.Value('approved'),
            approvedAt: drift.Value(DateTime.now()),
            approvedBy: drift.Value(widget.currentUserId),
          ));

      if (mounted) {
        // Mostrar la contraseña temporal al administrador
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Empleado Activado'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('El empleado ${employee.firstName} ${employee.lastName} ha sido activado exitosamente.'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Credenciales de acceso:', 
                             style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        SelectableText('Email: ${employee.email}'),
                        SelectableText('Contraseña temporal: $password'),
                        SizedBox(height: 8),
                        Text('⚠️ Comunique estas credenciales al empleado',
                             style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Entendido'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Copiar contraseña al portapapeles
                    Clipboard.setData(ClipboardData(text: password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contraseña copiada al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Copiar Contraseña'),
                ),
              ],
            );
          },
        );
      }

      await _loadPendingRequests();
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(EmployeeRegistrationRequest request) async {
    try {
      // Obtener el empleado
      final employee = await (_database!.select(_database!.employees)
            ..where((emp) => emp.id.equals(request.employeeId)))
          .getSingle();

      // Bloquear el empleado - solo cambiar estado a inactivo
      await (_database!.update(_database!.employees)
            ..where((emp) => emp.id.equals(employee.id)))
          .write(EmployeesCompanion(
            isActive: const drift.Value(false),
          ));

      // Marcar la solicitud como rechazada
      await (_database!.update(_database!.employeeRegistrationRequests)
            ..where((req) => req.id.equals(request.id)))
          .write(EmployeeRegistrationRequestsCompanion(
            status: const drift.Value('rejected'),
            rejectedAt: drift.Value(DateTime.now()),
            rejectedBy: drift.Value(widget.currentUserId),
            rejectionReason: const drift.Value('Solicitud rechazada por el administrador'),
          ));

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.block, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Solicitud Rechazada'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('La solicitud del empleado ${employee.firstName} ${employee.lastName} ha sido rechazada.'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estado del empleado:', 
                             style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Acceso al sistema: Bloqueado'),
                        Text('• Estado: Inactivo'),
                        SizedBox(height: 8),
                        Text('ℹ️ El empleado no podrá acceder al sistema',
                             style: TextStyle(color: Colors.orange[700], fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Entendido'),
                ),
              ],
            );
          },
        );
      }

      await _loadPendingRequests();
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _showDebugInfo() async {
    try {
      // Obtener todos los datos de la base de datos
      final allEmployees = await _database!.getAllEmployees();
      final pendingEmployees = allEmployees.where((emp) => 
        emp.passwordHash == 'PENDING' && emp.isActive == false
      ).toList();
      
      final allRequests = await _service.getPendingRequests();
      final allNotifications = await (_database!.select(_database!.systemNotifications)).get();
      
      // Mostrar información en un diálogo
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🐛 Debug Info'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Estadísticas de BD:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• Total empleados: ${allEmployees.length}'),
                    Text('• Empleados PENDING: ${pendingEmployees.length}'),
                    Text('• Solicitudes de registro: ${allRequests.length}'),
                    Text('• Notificaciones en BD: ${allNotifications.length}'),
                    Text('• Solicitudes en panel: ${_pendingRequests.length}'),
                    const SizedBox(height: 16),
                    
                    Text('👥 Empleados PENDING:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...pendingEmployees.map((emp) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('• ${emp.firstName} ${emp.lastName} (ID: ${emp.id}, Role: ${emp.role})'),
                    )),
                    const SizedBox(height: 16),
                    
                    Text('📋 Solicitudes de registro:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...allRequests.map((req) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('• ID: ${req.id}, Employee: ${req.employeeId}, Status: ${req.status}'),
                    )),
                    const SizedBox(height: 16),
                    
                    Text('🔔 Notificaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...allNotifications.take(5).map((notif) => Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text('• ${notif.title} (${notif.targetRole})'),
                    )),
                    if (allNotifications.length > 5) 
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text('... y ${allNotifications.length - 5} más'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Forzar recarga completa
                  setState(() => _isLoading = true);
                  await _initializeDatabase();
                },
                child: const Text('Recargar Todo'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error en debug info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo debug info: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}