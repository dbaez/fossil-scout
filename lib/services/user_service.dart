import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sincroniza el usuario de Auth con la tabla Users
  /// Si el usuario no existe, lo crea. Si existe, actualiza last_login
  Future<UserModel?> syncUserFromAuth() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) return null;

      // Buscar usuario por google_id (sub del token)
      final googleId = authUser.userMetadata?['sub'] as String? ?? authUser.id;
      
      final response = await _client
          .from('users')
          .select()
          .eq('google_id', googleId)
          .maybeSingle();

      final now = DateTime.now();
      
      if (response == null) {
        // Crear nuevo usuario
        final newUser = {
          'id': authUser.id,
          'google_id': googleId,
          'email': authUser.email ?? '',
          'display_name': authUser.userMetadata?['full_name'] as String? ?? 
                         authUser.userMetadata?['name'] as String? ?? 
                         authUser.email?.split('@')[0] ?? 'Usuario',
          'photo_url': authUser.userMetadata?['avatar_url'] as String? ?? 
                      authUser.userMetadata?['picture'] as String?,
          'role': 'user',
          'created_at': now.toIso8601String(),
          'last_login': now.toIso8601String(),
        };

        await _client.from('users').insert(newUser);
        return UserModel.fromJson(newUser);
      } else {
        // Actualizar last_login
        await _client
            .from('users')
            .update({'last_login': now.toIso8601String()})
            .eq('id', response['id'] as String);
        
        return UserModel.fromJson(response);
      }
    } catch (e) {
      print('Error sincronizando usuario: $e');
      return null;
    }
  }

  /// Obtiene el usuario actual
  Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _client.auth.currentUser;
      if (authUser == null) return null;

      final response = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }
}
