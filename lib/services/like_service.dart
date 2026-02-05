import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Da like a un post (o lo quita si ya tiene like)
  /// Retorna true si se dio like, false si se quitó
  Future<bool> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Verificar si ya tiene like
      final existingLike = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Quitar like
        await _client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false;
      } else {
        // Dar like
        await _client
            .from('post_likes')
            .insert({
          'post_id': postId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      print('Error al cambiar like: $e');
      rethrow;
    }
  }

  /// Obtiene el conteo de likes de un post
  Future<int> getLikesCount(String postId) async {
    try {
      final response = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId);

      return (response as List).length;
    } catch (e) {
      print('Error obteniendo conteo de likes: $e');
      return 0;
    }
  }

  /// Verifica si el usuario actual ha dado like a un post
  Future<bool> hasUserLiked(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error verificando like: $e');
      return false;
    }
  }

  /// Obtiene los IDs de usuarios que dieron like a un post
  Future<List<String>> getLikedByUsers(String postId) async {
    try {
      final response = await _client
          .from('post_likes')
          .select('user_id')
          .eq('post_id', postId);

      return (response as List)
          .map((item) => item['user_id'] as String)
          .toList();
    } catch (e) {
      print('Error obteniendo usuarios que dieron like: $e');
      return [];
    }
  }

  /// Obtiene los posts a los que el usuario actual ha dado like
  Future<List<String>> getLikedPosts(String userId) async {
    try {
      final response = await _client
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId);

      return (response as List)
          .map((item) => item['post_id'] as String)
          .toList();
    } catch (e) {
      print('Error obteniendo posts con like: $e');
      return [];
    }
  }
}
