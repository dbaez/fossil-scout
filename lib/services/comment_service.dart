import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crea un nuevo comentario en un post
  Future<CommentModel?> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      
      final commentData = {
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'created_at': now.toIso8601String(),
      };

      final response = await _client
          .from('comments')
          .insert(commentData)
          .select('''
            *,
            users(display_name, photo_url)
          ''')
          .single();

      final userData = response['users'] as Map<String, dynamic>?;
      
      return CommentModel(
        id: response['id'] as String,
        postId: response['post_id'] as String,
        userId: response['user_id'] as String,
        content: response['content'] as String,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
        deletedAt: response['deleted_at'] != null
            ? DateTime.parse(response['deleted_at'] as String)
            : null,
        userName: userData?['display_name'] as String?,
        userPhotoUrl: userData?['photo_url'] as String?,
      );
    } catch (e) {
      print('Error creando comentario: $e');
      return null;
    }
  }

  /// Obtiene todos los comentarios de un post
  Future<List<CommentModel>> getCommentsByPostId(String postId) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            users(display_name, photo_url)
          ''')
          .eq('post_id', postId)
          .isFilter('deleted_at', null) // Solo comentarios no eliminados
          .order('created_at', ascending: true);

      return (response as List).map((item) {
        final userData = item['users'] as Map<String, dynamic>?;
        
        return CommentModel(
          id: item['id'] as String,
          postId: item['post_id'] as String,
          userId: item['user_id'] as String,
          content: item['content'] as String,
          createdAt: DateTime.parse(item['created_at'] as String),
          updatedAt: item['updated_at'] != null
              ? DateTime.parse(item['updated_at'] as String)
              : null,
          deletedAt: item['deleted_at'] != null
              ? DateTime.parse(item['deleted_at'] as String)
              : null,
          userName: userData?['display_name'] as String?,
          userPhotoUrl: userData?['photo_url'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error obteniendo comentarios: $e');
      return [];
    }
  }

  /// Elimina un comentario (soft delete)
  Future<bool> deleteComment(String commentId, String userId) async {
    try {
      // Verificar que el comentario pertenece al usuario
      final comment = await _client
          .from('comments')
          .select('user_id')
          .eq('id', commentId)
          .single();

      if (comment['user_id'] != userId) {
        print('El usuario no tiene permiso para eliminar este comentario');
        return false;
      }

      await _client
          .from('comments')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', commentId);

      return true;
    } catch (e) {
      print('Error eliminando comentario: $e');
      return false;
    }
  }

  /// Actualiza un comentario
  Future<bool> updateComment(String commentId, String userId, String newContent) async {
    try {
      // Verificar que el comentario pertenece al usuario
      final comment = await _client
          .from('comments')
          .select('user_id')
          .eq('id', commentId)
          .single();

      if (comment['user_id'] != userId) {
        print('El usuario no tiene permiso para actualizar este comentario');
        return false;
      }

      await _client
          .from('comments')
          .update({
            'content': newContent,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId);

      return true;
    } catch (e) {
      print('Error actualizando comentario: $e');
      return false;
    }
  }
}
