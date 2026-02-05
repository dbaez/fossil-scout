import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Sube una imagen desde bytes (para web)
  Future<String?> uploadImageBytes(
    Uint8List bytes,
    String userId,
    String originalFileName,
  ) async {
    try {
      final extension = originalFileName.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$extension';
      final path = 'posts/$userId/$fileName';

      print('Subiendo imagen: $path (${bytes.length} bytes)');

      // Determinar content type correcto
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        default:
          contentType = 'image/jpeg';
      }

      await _client.storage.from('post-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      print('Imagen subida exitosamente: $path');

      // Obtener URL pública
      final url = _client.storage.from('post-images').getPublicUrl(path);
      print('URL pública generada: $url');
      return url;
    } catch (e, stackTrace) {
      print('Error subiendo imagen: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-lanzar el error para que se maneje arriba
    }
  }
}
