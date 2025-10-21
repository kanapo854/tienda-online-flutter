import 'package:flutter/material.dart';
import '../services/offline_first_init_service.dart';

/// Widget que muestra el estado de sincronización en tiempo real
class SyncStatusWidget extends StatelessWidget {
  final Widget child;
  final bool showWhenOffline;
  final bool showProgress;

  const SyncStatusWidget({
    Key? key,
    required this.child,
    this.showWhenOffline = true,
    this.showProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showProgress) _buildSyncIndicator(),
      ],
    );
  }

  Widget _buildSyncIndicator() {
    return StreamBuilder<bool>(
      stream: OfflineFirstInitService.instance.syncStatus,
      initialData: false,
      builder: (context, syncSnapshot) {
        final isSyncing = syncSnapshot.data ?? false;

        return StreamBuilder<String>(
          stream: OfflineFirstInitService.instance.syncProgress,
          initialData: '',
          builder: (context, progressSnapshot) {
            final progress = progressSnapshot.data ?? '';

            // No mostrar nada si no está sincronizando y no hay mensaje especial
            if (!isSyncing && !progress.contains('offline') && !showWhenOffline) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isSyncing || progress.isNotEmpty ? 48 : 0,
                child: Material(
                  color: _getStatusColor(isSyncing, progress),
                  elevation: 4,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildStatusIcon(isSyncing, progress),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getStatusMessage(isSyncing, progress),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSyncing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIcon(bool isSyncing, String progress) {
    if (isSyncing) {
      return const Icon(Icons.sync, color: Colors.white, size: 20);
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 20);
    }
    
    if (progress.contains('completada') || progress.contains('exitosa')) {
      return const Icon(Icons.check_circle, color: Colors.white, size: 20);
    }
    
    if (progress.contains('Error')) {
      return const Icon(Icons.error, color: Colors.white, size: 20);
    }
    
    return const Icon(Icons.info, color: Colors.white, size: 20);
  }

  Color _getStatusColor(bool isSyncing, String progress) {
    if (isSyncing) {
      return Colors.blue;
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return Colors.orange;
    }
    
    if (progress.contains('completada') || progress.contains('exitosa')) {
      return Colors.green;
    }
    
    if (progress.contains('Error')) {
      return Colors.red;
    }
    
    return Colors.grey;
  }

  String _getStatusMessage(bool isSyncing, String progress) {
    if (isSyncing) {
      return progress.isNotEmpty ? progress : 'Sincronizando...';
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return 'Trabajando sin conexión';
    }
    
    return progress.isNotEmpty ? progress : 'Listo';
  }
}

/// Widget flotante para mostrar el estado de sincronización
class FloatingSyncStatus extends StatelessWidget {
  const FloatingSyncStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineFirstInitService.instance.syncStatus,
      initialData: false,
      builder: (context, syncSnapshot) {
        final isSyncing = syncSnapshot.data ?? false;

        return StreamBuilder<String>(
          stream: OfflineFirstInitService.instance.syncProgress,
          initialData: '',
          builder: (context, progressSnapshot) {
            final progress = progressSnapshot.data ?? '';

            // Solo mostrar cuando hay actividad relevante
            if (!isSyncing && !progress.contains('offline') && progress.isEmpty) {
              return const SizedBox.shrink();
            }

            return Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1.0,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _getStatusColor(isSyncing, progress).withOpacity(0.9),
                    ),
                    child: Row(
                      children: [
                        _buildStatusIcon(isSyncing, progress),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getStatusMessage(isSyncing, progress),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSyncing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusIcon(bool isSyncing, String progress) {
    if (isSyncing) {
      return const Icon(Icons.sync, color: Colors.white, size: 24);
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 24);
    }
    
    if (progress.contains('completada') || progress.contains('exitosa')) {
      return const Icon(Icons.check_circle, color: Colors.white, size: 24);
    }
    
    if (progress.contains('Error')) {
      return const Icon(Icons.error, color: Colors.white, size: 24);
    }
    
    return const Icon(Icons.info, color: Colors.white, size: 24);
  }

  Color _getStatusColor(bool isSyncing, String progress) {
    if (isSyncing) {
      return Colors.blue;
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return Colors.orange;
    }
    
    if (progress.contains('completada') || progress.contains('exitosa')) {
      return Colors.green;
    }
    
    if (progress.contains('Error')) {
      return Colors.red;
    }
    
    return Colors.grey;
  }

  String _getStatusMessage(bool isSyncing, String progress) {
    if (isSyncing) {
      return progress.isNotEmpty ? progress : 'Sincronizando datos...';
    }
    
    if (progress.contains('offline') || progress.contains('Sin conexión')) {
      return 'Modo offline activo';
    }
    
    return progress;
  }
}

/// Widget de botón para sincronización manual
class ManualSyncButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? tooltip;

  const ManualSyncButton({
    Key? key,
    this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  State<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends State<ManualSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performSync() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    _animationController.repeat();

    try {
      await OfflineFirstInitService.instance.manualSync();
      
      if (widget.onPressed != null) {
        widget.onPressed!();
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineFirstInitService.instance.syncStatus,
      initialData: false,
      builder: (context, snapshot) {
        final isSyncingAlready = snapshot.data ?? false;
        final isDisabled = _isLoading || isSyncingAlready;

        return Tooltip(
          message: widget.tooltip ?? 'Sincronizar datos',
          child: FloatingActionButton(
            onPressed: isDisabled ? null : _performSync,
            backgroundColor: isDisabled ? Colors.grey : null,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2.0 * 3.14159,
                  child: Icon(
                    Icons.sync,
                    color: isDisabled ? Colors.grey[300] : Colors.white,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Widget de indicador de conectividad
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: OfflineFirstInitService.instance.checkConnectivity(),
      builder: (context, snapshot) {
        final hasConnection = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasConnection ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasConnection ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                hasConnection ? 'En línea' : 'Sin conexión',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}