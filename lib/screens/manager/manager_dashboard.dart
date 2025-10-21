import 'package:flutter/material.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gerencia'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.purple),
            SizedBox(height: 16),
            Text(
              'Panel de Gerencia',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Funcionalidad próximamente disponible'),
          ],
        ),
      ),
    );
  }
}