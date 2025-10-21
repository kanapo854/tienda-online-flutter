import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // 🔑 CONFIGURA ESTAS CREDENCIALES CON TU PROYECTO SUPABASE
  // Opción 1: Valores directos (para pruebas rápidas)
  static const String supabaseUrl = 'https://mvmwinsibyqgaoygrphn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im12bXdpbnNpYnlxZ2FveWdycGhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2MTIxMTEsImV4cCI6MjA3NjE4ODExMX0.CO5tZUJ84M3S4yyerw4AkPUI1bbdaVMRgYlrUCl9znM';
  
  // 📝 EJEMPLO DE CREDENCIALES (reemplaza con las tuyas):
  // static const String supabaseUrl = 'https://abcdefghijklmnop.supabase.co';
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3M...';
  
  // Opción 2: Desde variables de entorno (producción)
  // Para usar esta opción:
  // 1. Agrega flutter_dotenv a pubspec.yaml
  // 2. Crea archivo .env con SUPABASE_URL y SUPABASE_ANON_KEY
  // 3. Descomenta las líneas siguientes:
  /*
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL no configurada en .env');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY no configurada en .env');
    }
    return key;
  }
  */

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Solo para desarrollo
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  
  // Configuración para offline-first
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryInterval = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String pendingSyncKey = 'pending_sync_operations';
  
  // Helper para verificar si está configurado
  static bool get isConfigured => 
      supabaseUrl.isNotEmpty && 
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.startsWith('eyJ');
}