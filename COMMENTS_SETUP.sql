-- Script SQL para configurar políticas RLS en la tabla comments
-- Ejecuta este script en el SQL Editor de Supabase
-- NOTA: La tabla comments ya existe, solo se configuran las políticas

-- Habilitar Row Level Security (RLS) si no está habilitado
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay (opcional, comenta si quieres mantener las existentes)
-- DROP POLICY IF EXISTS "Anyone can read non-deleted comments" ON comments;
-- DROP POLICY IF EXISTS "Authenticated users can create comments" ON comments;
-- DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
-- DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

-- Política: Todos pueden leer comentarios (excepto eliminados)
CREATE POLICY "Anyone can read non-deleted comments"
  ON comments
  FOR SELECT
  USING (deleted_at IS NULL);

-- Política: Usuarios autenticados pueden crear comentarios
CREATE POLICY "Authenticated users can create comments"
  ON comments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden actualizar sus propios comentarios
CREATE POLICY "Users can update their own comments"
  ON comments
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden eliminar (soft delete) sus propios comentarios
-- Nota: La eliminación se hace mediante UPDATE estableciendo deleted_at
CREATE POLICY "Users can delete their own comments"
  ON comments
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
