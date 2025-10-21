import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config/supabase_config.dart';
import 'database/local_database.dart';
import 'bloc/auth/auth_bloc_simple.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/products/product_bloc.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos
  final database = LocalDatabase();
  
  // Inicializar Supabase (opcional si tienes credenciales)
  if (SupabaseConfig.isConfigured) {
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      print('Error inicializando Supabase: $e');
      print('La app funcionará en modo offline únicamente');
    }
  } else {
    print('Supabase no configurado - funcionando en modo offline únicamente');
  }
  
  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final LocalDatabase database;
  
  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Proveedor del AuthBloc
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            database: database,
            connectivity: Connectivity(),
          )..add(AuthStarted()), // Iniciar verificación de sesión
        ),
        
        // Proveedor del ProductBloc
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(
            database: database,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Tienda Online',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.brown[700],
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          // Personalización adicional para el tema marrón
          primaryColor: const Color(0xFF8B4513),
          scaffoldBackgroundColor: const Color(0xFFF5F5DC),
          inputDecorationTheme: InputDecorationTheme(
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
        ),
        home: const SplashScreen(),
      ),
    );
  }
}