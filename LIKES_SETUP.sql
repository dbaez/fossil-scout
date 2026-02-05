-- Script SQL para crear la tabla post_likes y configurar políticas RLS
-- Ejecuta este script en el SQL Editor de Supabase

-- Crear la tabla post_likes (relación muchos-a-muchos entre usuarios y posts)
CREATE TABLE IF NOT EXISTS post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id) -- Un usuario solo puede dar like una vez por post
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_created_at ON post_likes(created_at);

-- Habilitar Row Level Security (RLS)
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

-- Política: Todos pueden leer los likes
CREATE POLICY "Anyone can read likes"
  ON post_likes
  FOR SELECT
  USING (true);

-- Política: Usuarios autenticados pueden crear likes (dar like)
CREATE POLICY "Authenticated users can create likes"
  ON post_likes
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden eliminar sus propios likes (quitar like)
CREATE POLICY "Users can delete their own likes"
  ON post_likes
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Función para obtener el conteo de likes de un post
CREATE OR REPLACE FUNCTION get_post_likes_count(post_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM post_likes
    WHERE post_id = post_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si un usuario ha dado like a un post
CREATE OR REPLACE FUNCTION has_user_liked_post(post_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM post_likes
    WHERE post_id = post_uuid AND user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
