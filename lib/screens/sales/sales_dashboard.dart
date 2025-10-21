import 'package:flutter/material.dart';

class SalesDashboard extends StatelessWidget {
  const SalesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Ventas'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Panel de Ventas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Funcionalidad próximamente disponible'),
          ],
        ),
      ),
    );
  }
}