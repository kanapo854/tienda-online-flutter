import 'package:flutter/material.dart';
import '../services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SyncService? _syncService = null; // Placeholder por ahora
  bool _isOnline = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    if (_syncService != null) {
      final isConnected = await _syncService!.hasInternetConnection();
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  Future<void> _performSync() async {
    if (_syncService == null) return;
    
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await _syncService!.forceSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Sincronización completada' : 'Error en la sincronización',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Online'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          // Indicador de conectividad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),
          // Botón de sincronización
          IconButton(
            onPressed: _isSyncing ? null : _performSync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estado de conexión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: _isOnline ? Colors.green[100] : Colors.red[100],
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOnline 
                      ? 'Conectado - Datos sincronizados'
                      : 'Sin conexión - Modo offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sistema de gestión empresarial con Drift + Supabase',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Grid de opciones
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          'Productos',
                          Icons.inventory_2,
                          Colors.blue,
                          () => _navigateToProducts(),
                        ),
                        _buildMenuCard(
                          'Ventas',
                          Icons.point_of_sale,
                          Colors.green,
                          () => _navigateToSales(),
                        ),
                        _buildMenuCard(
                          'Inventario',
                          Icons.warehouse,
                          Colors.orange,
                          () => _navigateToInventory(),
                        ),
                        _buildMenuCard(
                          'Reportes',
                          Icons.analytics,
                          Colors.purple,
                          () => _navigateToReports(),
                        ),
                        _buildMenuCard(
                          'Clientes',
                          Icons.people,
                          Colors.teal,
                          () => _navigateToCustomers(),
                        ),
                        _buildMenuCard(
                          'Configuración',
                          Icons.settings,
                          Colors.grey,
                          () => _navigateToSettings(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToProducts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de Productos - Próximamente')),
    );
  }

  void _navigateToSales() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de Ventas - Próximamente')),
    );
  }

  void _navigateToInventory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de Inventario - Próximamente')),
    );
  }

  void _navigateToReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de Reportes - Próximamente')),
    );
  }

  void _navigateToCustomers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Módulo de Clientes - Próximamente')),
    );
  }

  void _navigateToSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración - Próximamente')),
    );
  }
}