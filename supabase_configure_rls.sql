-- 🔐 SCRIPT PARA CONFIGURAR ROW LEVEL SECURITY (RLS) EN SUPABASE
-- Ejecuta este script en el SQL Editor de Supabase para permitir acceso a tus tablas

-- ⚠️ IMPORTANTE: Este script es para DESARROLLO
-- En PRODUCCIÓN debes configurar políticas más restrictivas con autenticación

-- ==============================================================================
-- OPCIÓN 1: DESARROLLO - PERMITIR TODO (Más Fácil)
-- ==============================================================================
-- Esta opción permite acceso completo a todas las tablas
-- Ideal para desarrollo y pruebas

DO $$ 
DECLARE 
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT LIKE 'pg_%'
    AND tablename NOT LIKE 'sql_%'
  LOOP
    -- Habilitar RLS en la tabla
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', table_name);
    
    -- Eliminar políticas existentes (si las hay)
    EXECUTE format('DROP POLICY IF EXISTS "Allow all for development" ON %I;', table_name);
    
    -- Crear política que permite todo
    EXECUTE format('
      CREATE POLICY "Allow all for development" ON %I
        FOR ALL 
        USING (true) 
        WITH CHECK (true);
    ', table_name);
    
    RAISE NOTICE 'RLS configurado para tabla: %', table_name;
  END LOOP;
END $$;

-- ==============================================================================
-- Verificar que se aplicó correctamente
-- ==============================================================================

SELECT 
  schemaname, 
  tablename, 
  policyname,
  permissive,
  roles
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ==============================================================================
-- OPCIÓN 2: PRODUCCIÓN - SOLO PARA USUARIOS AUTENTICADOS (Más Seguro)
-- ==============================================================================
-- Descomenta este bloque si quieres seguridad básica con autenticación

/*
DO $$ 
DECLARE 
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT LIKE 'pg_%'
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', table_name);
    
    -- Eliminar políticas de desarrollo
    EXECUTE format('DROP POLICY IF EXISTS "Allow all for development" ON %I;', table_name);
    
    -- Permitir solo a usuarios autenticados
    EXECUTE format('
      CREATE POLICY "Allow authenticated users" ON %I
        FOR ALL 
        TO authenticated
        USING (true) 
        WITH CHECK (true);
    ', table_name);
    
    RAISE NOTICE 'RLS de producción configurado para: %', table_name;
  END LOOP;
END $$;
*/

-- ==============================================================================
-- OPCIÓN 3: POLÍTICAS PERSONALIZADAS (Máxima Seguridad)
-- ==============================================================================
-- Ejemplo: Diferentes permisos por tabla

/*
-- Employees: Solo administradores pueden modificar
CREATE POLICY "Employees admin only" ON employees
  FOR ALL
  TO authenticated
  USING (auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role = 'admin'
  ))
  WITH CHECK (auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role = 'admin'
  ));

-- Sales: Vendedores pueden crear, todos pueden leer
CREATE POLICY "Sales read all" ON sales
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Sales insert sellers" ON sales
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role IN ('seller', 'admin')
  ));

-- Products: Todos pueden leer, admin puede modificar
CREATE POLICY "Products read all" ON products
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Products modify admin" ON products
  FOR ALL
  TO authenticated
  USING (auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role = 'admin'
  ))
  WITH CHECK (auth.uid() IN (
    SELECT user_id FROM user_roles WHERE role = 'admin'
  ));
*/

-- ==============================================================================
-- DESHABILITAR RLS (SI LO NECESITAS)
-- ==============================================================================
-- ⚠️ PELIGRO: Solo usa esto si sabes lo que haces

/*
DO $$ 
DECLARE 
  table_name text;
BEGIN
  FOR table_name IN 
    SELECT tablename FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename NOT LIKE 'pg_%'
  LOOP
    EXECUTE format('ALTER TABLE %I DISABLE ROW LEVEL SECURITY;', table_name);
    RAISE NOTICE 'RLS deshabilitado para: %', table_name;
  END LOOP;
END $$;
*/

-- ==============================================================================
-- COMANDOS ÚTILES
-- ==============================================================================

-- Ver estado de RLS en todas las tablas
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Ver todas las políticas
SELECT 
  schemaname, 
  tablename, 
  policyname,
  cmd as operation,
  qual as using_expression
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ==============================================================================
-- FIN DEL SCRIPT
-- ==============================================================================

-- ✅ DESPUÉS DE EJECUTAR:
-- 1. Verifica que aparezcan las políticas creadas
-- 2. Intenta migrar datos desde tu app nuevamente
-- 3. Si hay problemas, revisa los logs en Supabase > Logs
