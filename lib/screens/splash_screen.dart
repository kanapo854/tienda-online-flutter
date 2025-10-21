import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // Simular tiempo de carga
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D4037),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o ícono de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                size: 80,
                color: Color(0xFF5D4037),
              ),
            ),
            const SizedBox(height: 30),
            
            // Título de la aplicación
            const Text(
              'Tienda Online',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtítulo
            const Text(
              'Decoración y Construcción',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),
            
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}