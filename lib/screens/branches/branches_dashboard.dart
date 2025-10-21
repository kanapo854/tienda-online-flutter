import 'package:flutter/material.dart';

class BranchesDashboard extends StatelessWidget {
  const BranchesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Sucursales'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Panel de Sucursales',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Funcionalidad próximamente disponible'),
          ],
        ),
      ),
    );
  }
}