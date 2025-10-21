# 📤 Migrar Datos Locales a Supabase

## 🎯 Opciones para Migrar tus Datos

### **Opción 1: Botón Temporal en la App** (Recomendado - Más Fácil)

Agrega un botón temporal en cualquier pantalla para migrar los datos:

```dart
// Ejemplo: Agregar en RoleSelectionScreen o AdminDashboard

import '../scripts/migrate_to_supabase.dart';

// Dentro del build(), agregar este botón flotante:
floatingActionButton: FloatingActionButton.extended(
  onPressed: () => showMigrationDialog(context, database),
  icon: const Icon(Icons.cloud_upload),
  label: const Text('Migrar a Supabase'),
  backgroundColor: Colors.orange,
),
```

**Pasos**:
1. Abre `lib/main.dart`
2. En la clase `RoleSelectionScreen`, agregar el import:
   ```dart
   import 'scripts/migrate_to_supabase.dart';
   ```
3. En el `Scaffold` del `build()`, agregar el `floatingActionButton` (antes del body)
4. Hot Reload (`r`)
5. Presiona el botón naranja "Migrar a Supabase"
6. ¡Listo! Verás el progreso y resultado

---

### **Opción 2: Desde Código (Programáticamente)**

Si prefieres ejecutar la migración desde código:

```dart
import '../scripts/migrate_to_supabase.dart';
import '../database/local_database.dart';

Future<void> migrateData() async {
  final database = LocalDatabase();
  final service = MigrationService(database);
  
  print('Iniciando migración...');
  final result = await service.migrateAllData();
  
  if (result.hasErrors) {
    print('Migración completada con errores');
  } else {
    print('¡Migración exitosa!');
  }
}
```

---

### **Opción 3: Script Standalone (Línea de Comandos)**

Crea un archivo `migrate_standalone.dart` en la raíz:

```dart
import 'package:flutter/widgets.dart';
import 'lib/database/local_database.dart';
import 'lib/scripts/migrate_to_supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = LocalDatabase();
  final service = MigrationService(database);
  
  print('🚀 Iniciando migración de datos...');
  final result = await service.migrateAllData();
  
  print('\n✅ Proceso completado');
  print('Registros migrados: ${result.totalSuccess}');
  print('Errores: ${result.totalErrors}');
}
```

Ejecutar:
```bash
dart run migrate_standalone.dart
```

---

## 📋 Antes de Migrar

### **Checklist Pre-Migración:**

- [ ] ✅ Supabase configurado en `supabase_config.dart`
- [ ] ✅ Tablas creadas en Supabase (ejecutar `supabase_schema.sql`)
- [ ] ✅ RLS configurado (políticas de acceso)
- [ ] ✅ Internet activo
- [ ] ✅ Datos locales existen (verifica tu base de datos local)

---

## 🔄 Qué Hace la Migración

El script migra **automáticamente**:

1. 🏢 **Compañías** (companies)
2. 📁 **Categorías** (categories) 
3. 📦 **Productos** (products)
4. 🏪 **Almacenes** (warehouses)
5. 📊 **Stock** (stocks)
6. 👥 **Clientes** (customers)
7. 👨‍💼 **Empleados** (employees) *sin contraseñas*
8. 💰 **Ventas** (sales)

### **Características:**

- ✅ **Upsert**: Actualiza si existe, crea si no existe
- ✅ **No duplica**: Usa el ID para identificar registros
- ✅ **Manejo de errores**: Continúa aunque falle un registro
- ✅ **Reporte detallado**: Muestra éxitos y errores
- ✅ **Seguro**: No borra datos locales

---

## 🎨 Ejemplo Visual - Agregar Botón en Main.dart

```dart
// En lib/main.dart, clase RoleSelectionScreen

import 'scripts/migrate_to_supabase.dart'; // <-- AGREGAR ESTO

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        backgroundColor: Colors.brown[600],
        elevation: 0,
        title: const Text('Tienda Online'),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: ConnectivityIndicator(),
          ),
        ],
      ),
      // 🔥 AGREGAR ESTE BOTÓN FLOTANTE:
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Obtener la base de datos del contexto o crear una
          final database = LocalDatabase(); // O usa context si tienes Provider
          showMigrationDialog(context, database);
        },
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Migrar Datos'),
        backgroundColor: Colors.orange,
      ),
      // Botón flotante para sincronización manual (ya existente)
      // floatingActionButton: const ManualSyncButton(...), // <-- Comentar este
      
      body: SyncStatusWidget(
        // ... resto del código
```

---

## 📊 Resultado Esperado

Al presionar el botón verás:

```
🚀 Iniciando migración a Supabase...
📦 Migrando compañías...
   Encontradas 2 compañías
📦 Migrando categorías...
   Encontradas 5 categorías
📦 Migrando productos...
   Encontrados 24 productos
📦 Migrando almacenes...
   Encontrados 3 almacenes
📦 Migrando stock...
   Encontrados 18 registros de stock
📦 Migrando clientes...
   Encontrados 10 clientes
📦 Migrando empleados...
   Encontrados 8 empleados
📦 Migrando ventas...
   Encontradas 15 ventas

✅ ¡Migración completada!

═══════════════════════════════════════
📊 RESUMEN DE MIGRACIÓN
═══════════════════════════════════════

✅ Registros migrados exitosamente:
   • companies: 2 registros
   • categories: 5 registros
   • products: 24 registros
   • warehouses: 3 registros
   • stocks: 18 registros
   • customers: 10 registros
   • employees: 8 registros
   • sales: 15 registros

═══════════════════════════════════════
Total: 85 exitosos, 0 errores
═══════════════════════════════════════
```

---

## ⚠️ Problemas Comunes

### **"relation does not exist"**
**Causa**: No has creado las tablas en Supabase
**Solución**: Ejecuta `supabase_schema.sql` en el SQL Editor de Supabase

### **"permission denied for table"**
**Causa**: No configuraste RLS o políticas
**Solución**: Ver `CONFIGURAR_SUPABASE.md` - Paso 2

### **"Supabase no está inicializado"**
**Causa**: No configuraste credenciales o no hay internet
**Solución**: 
1. Verifica `supabase_config.dart`
2. Verifica conexión a internet
3. Haz Hot Restart

---

## 🔄 Re-migrar Datos

Puedes ejecutar la migración múltiples veces de forma segura:

- ✅ **Actualiza** registros existentes (por ID)
- ✅ **No duplica** datos
- ✅ **Solo crea** lo que no existe

---

## 💡 Tips

1. **Primera vez**: Migra todo usando el botón
2. **Actualizaciones**: Usa sincronización automática (ya integrada)
3. **Pruebas**: Verifica en Supabase Table Editor que los datos llegaron
4. **Backup**: Supabase hace backups automáticos

---

## 🎯 Después de Migrar

Una vez migrados los datos:

1. **Quita el botón** de migración (comentarlo o eliminarlo)
2. **Verifica** en Supabase Table Editor que todo esté bien
3. **Activa** la sincronización automática (ya está activa)
4. **Usa** la app normalmente - sincroniza cada 5 minutos

---

## 📞 Soporte

Si algo falla:
- Revisa los logs en consola
- Verifica que las tablas existan en Supabase
- Asegúrate de que RLS esté configurado
- Verifica internet

**¡Tu sistema de migración está listo!** 🎉
