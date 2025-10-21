# 🚀 Guía de Configuración de Supabase para Sistema Offline-First

## 📋 Prerequisitos

1. Cuenta en Supabase (https://supabase.com)
2. Proyecto creado en Supabase
3. Flutter SDK instalado

## 🔧 Paso 1: Configurar Proyecto en Supabase

### 1.1 Crear Proyecto
1. Ve a https://app.supabase.com
2. Click en "New Project"
3. Completa los detalles:
   - **Name**: Tienda Online
   - **Database Password**: (guarda esto de forma segura)
   - **Region**: Elige la más cercana
4. Click en "Create new project"

### 1.2 Obtener Credenciales
1. Ve a **Settings** > **API**
2. Copia:
   - **Project URL** (ejemplo: https://xxxxx.supabase.co)
   - **anon public** key

## 📊 Paso 2: Crear Esquema de Base de Datos

### 2.1 Abrir SQL Editor
1. En tu proyecto de Supabase, ve a **SQL Editor**
2. Click en "New query"

### 2.2 Ejecutar Script SQL
Copia y pega el siguiente script (disponible en `supabase_schema.sql`):

```sql
-- Ver archivo supabase_schema.sql en la raíz del proyecto
```

O usa el archivo `supabase_schema.sql` que ya tienes en tu proyecto.

### 2.3 Habilitar Row Level Security (RLS)

**IMPORTANTE**: Por seguridad, debes configurar políticas RLS:

```sql
-- Habilitar RLS en todas las tablas
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE sale_items ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (personaliza según tus necesidades)
-- Ejemplo: Permitir lectura a usuarios autenticados
CREATE POLICY "Enable read access for authenticated users" ON products
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Ejemplo: Permitir escritura a usuarios autenticados
CREATE POLICY "Enable insert for authenticated users" ON products
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');
```

## 🔑 Paso 3: Configurar Credenciales en la App

### Opción A: Configuración Directa (Para pruebas)

Edita `lib/config/supabase_config.dart`:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### Opción B: Variables de Entorno (Recomendado para producción)

1. **Agregar dependencia en `pubspec.yaml`**:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. **Crear archivo `.env`** en la raíz del proyecto:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

3. **Agregar `.env` a `.gitignore`**:
```
.env
```

4. **Agregar `.env` a `pubspec.yaml`**:
```yaml
flutter:
  assets:
    - .env
```

5. **Cargar en `main.dart`**:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  runApp(MyApp());
}
```

## 🔄 Paso 4: Configurar Realtime (Opcional pero Recomendado)

### 4.1 Habilitar Realtime
1. Ve a **Database** > **Replication**
2. Habilita las tablas que quieres sincronizar en tiempo real:
   - ✅ products
   - ✅ stocks
   - ✅ sales
   - ✅ customers
   - ✅ product_categories

### 4.2 Configurar Publicaciones
```sql
-- Crear publicación para replicación
CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
```

## 🧪 Paso 5: Probar la Conexión

### 5.1 Verificar en la App

Ejecuta este código para probar:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

Future<void> testConnection() async {
  try {
    await SupabaseConfig.initialize();
    
    // Probar query simple
    final response = await SupabaseConfig.client
        .from('product_categories')
        .select()
        .limit(1);
    
    print('✅ Conexión exitosa: ${response}');
  } catch (e) {
    print('❌ Error de conexión: $e');
  }
}
```

### 5.2 Verificar desde Supabase Dashboard
1. Ve a **Table Editor**
2. Selecciona una tabla (ej: `products`)
3. Agrega un registro de prueba manualmente
4. Verifica que aparezca en tu app

## 🔐 Paso 6: Seguridad (IMPORTANTE)

### 6.1 Nunca Commitear Credenciales
- ✅ Usa `.env` y agrégalo a `.gitignore`
- ❌ Nunca subas el Service Role Key a Git
- ✅ Usa diferentes keys para desarrollo y producción

### 6.2 Configurar Políticas RLS Apropiadas
```sql
-- Ejemplo: Solo lectura de productos activos
CREATE POLICY "Public products read policy" ON products
    FOR SELECT
    USING (is_active = true);

-- Ejemplo: Solo empleados pueden modificar
CREATE POLICY "Employees update policy" ON products
    FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT id FROM employees WHERE is_active = true
        )
    );
```

## 📱 Paso 7: Integrar en la App

### 7.1 Actualizar main.dart

```dart
import 'package:flutter/material.dart';
import 'services/offline_first_init_service.dart';
import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseConfig.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OfflineFirstBuilder(
        builder: (context) => YourHomeScreen(),
        loadingBuilder: (context, status) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

## 🧩 Paso 8: Migración de Datos (Opcional)

Si ya tienes datos en Drift, puedes migrarlos a Supabase:

```dart
Future<void> migrateToSupabase() async {
  final localDb = LocalDatabase();
  final supabase = SupabaseConfig.client;
  
  // Migrar productos
  final products = await localDb.select(localDb.products).get();
  for (final product in products) {
    await supabase.from('products').upsert(
      DataMappers.productToJson(product)
    );
  }
  
  print('✅ Migración completada');
}
```

## 🐛 Solución de Problemas

### Error: "Invalid API key"
- Verifica que copiaste la key completa
- Asegúrate de usar la **anon public** key, no la service role key

### Error: "Table does not exist"
- Verifica que ejecutaste el script SQL
- Revisa en **Table Editor** que las tablas existen

### Error: "Row Level Security"
- Desactiva temporalmente RLS para probar: `ALTER TABLE products DISABLE ROW LEVEL SECURITY;`
- O configura políticas apropiadas

### Sin sincronización en tiempo real
- Verifica que Realtime esté habilitado en las tablas
- Revisa la consola del navegador para errores WebSocket

## 📚 Recursos Adicionales

- [Documentación oficial de Supabase](https://supabase.com/docs)
- [Supabase Flutter Client](https://supabase.com/docs/reference/dart/introduction)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)

## ✅ Checklist de Configuración

- [ ] Proyecto creado en Supabase
- [ ] Credenciales obtenidas (URL + Anon Key)
- [ ] Esquema de base de datos creado (SQL ejecutado)
- [ ] RLS configurado
- [ ] Credenciales configuradas en la app (.env o directo)
- [ ] Realtime habilitado (opcional)
- [ ] Conexión probada exitosamente
- [ ] Políticas de seguridad revisadas
- [ ] `.env` agregado a `.gitignore`
- [ ] Sistema offline-first integrado en main.dart

¡Listo! Tu sistema offline-first con Supabase está configurado. 🎉
