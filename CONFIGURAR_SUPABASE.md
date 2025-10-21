# 🚀 GUÍA RÁPIDA: Configurar Tu Supabase

## ✅ Ya tienes:
- Proyecto Supabase creado: `mvmwinsibyqgaoygrphn.supabase.co`
- Credenciales configuradas en `supabase_config.dart`

## 📋 PASOS PARA ACTIVAR SINCRONIZACIÓN

### **Paso 1: Crear las tablas en Supabase** (5 minutos)

1. Ve a tu proyecto en Supabase: https://supabase.com/dashboard/project/mvmwinsibyqgaoygrphn

2. Click en **SQL Editor** (icono de base de datos en la barra lateral)

3. Click en **New Query**

4. Copia TODO el contenido del archivo `supabase_schema.sql` (está en la raíz del proyecto)

5. Pega en el editor y click en **Run**

6. Verifica que se crearon las tablas:
   - Ve a **Table Editor**
   - Deberías ver: companies, stores, warehouses, categories, products, stocks, customers, employees, sales, etc.

---

### **Paso 2: Configurar Row Level Security (RLS)** (2 minutos)

Para que tu app pueda leer/escribir datos:

1. En Supabase, ve a **Authentication** > **Policies**

2. Para cada tabla, crea una política:

```sql
-- Ejecuta esto en SQL Editor para permitir acceso anónimo (solo desarrollo)
-- ⚠️ IMPORTANTE: En producción debes configurar autenticación adecuada

-- Permitir todo para desarrollo (tabla companies como ejemplo)
CREATE POLICY "Allow all for development" ON companies
  FOR ALL USING (true)
  WITH CHECK (true);

-- Repite para cada tabla o usa este script automático:
DO $$ 
DECLARE 
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT LIKE 'pg_%'
  LOOP
    EXECUTE format('
      ALTER TABLE %I ENABLE ROW LEVEL SECURITY;
      CREATE POLICY "Allow all for development" ON %I
        FOR ALL USING (true) WITH CHECK (true);
    ', table_name, table_name);
  END LOOP;
END $$;
```

---

### **Paso 3: Activar Realtime (Opcional)** (1 minuto)

Para recibir cambios en tiempo real:

1. Ve a **Database** > **Replication**

2. Habilita Realtime para las tablas importantes:
   - products
   - stocks
   - sales
   - categories

---

### **Paso 4: Probar la conexión**

Ahora haz **Hot Restart** (R) en tu app y deberías ver:

```
✅ Supabase conectado - sincronización cloud activa
✅ Conectado a Supabase
```

En lugar de:
```
📱 Modo Offline: Supabase no configurado
```

---

## 🔧 Solución de Problemas

### **"Failed host lookup" o "No address associated with hostname"**

**Causa**: No hay internet o problema de DNS

**Solución**:
1. Verifica tu conexión a internet
2. Intenta abrir https://mvmwinsibyqgaoygrphn.supabase.co en tu navegador
3. Si no carga, espera unos minutos (el proyecto puede estar pausado)

---

### **"permission denied for table" o similar**

**Causa**: No configuraste RLS correctamente

**Solución**:
1. Ejecuta el script de políticas del Paso 2
2. Verifica en Supabase > Authentication > Policies que las políticas existen

---

### **"relation does not exist"**

**Causa**: No ejecutaste el script SQL del Paso 1

**Solución**:
1. Ve a SQL Editor
2. Ejecuta `supabase_schema.sql` completo
3. Verifica que las tablas aparecen en Table Editor

---

## 🎯 Comandos Rápidos

### Ver tablas existentes:
```sql
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

### Ver políticas RLS:
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

### Borrar todo y empezar de nuevo:
```sql
-- ⚠️ CUIDADO: Esto borra TODAS las tablas
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Luego ejecuta supabase_schema.sql nuevamente
```

---

## 📊 Verificar Estado Actual

En la consola de tu app Flutter deberías ver:

### ✅ **Si está funcionando:**
```
🚀 Iniciando Tienda Online...
✅ Supabase conectado - sincronización cloud activa
✅ Conectado a Supabase
📊 Base de datos local tiene X compañías
🎉 Sistema offline-first inicializado exitosamente
```

### ⚠️ **Si falta configurar (actual):**
```
📱 Modo Offline: Supabase no configurado
💡 La app funciona 100% con base de datos local
```

---

## 🚀 Después de Configurar

Una vez que veas "✅ Supabase conectado":

1. **Sincronización automática** cada 5 minutos
2. **Indicador verde** (🟢) en el AppBar
3. **Botón de sync** funcionará para sincronizar manualmente
4. **Cambios en tiempo real** si activaste Realtime

---

## 💡 Tips

- **Desarrollo**: Usa políticas permisivas (como en Paso 2)
- **Producción**: Implementa autenticación y políticas específicas
- **Testing**: Puedes insertar datos de prueba directamente en Supabase Table Editor
- **Backup**: Supabase hace backups automáticos

---

## 📞 ¿Necesitas ayuda?

1. Revisa los logs en la consola de Flutter
2. Verifica en Supabase > Logs si hay errores
3. Asegúrate de que el proyecto Supabase esté activo (no pausado)

**¡Tu Supabase está configurado! Solo falta crear las tablas.** 🎉
