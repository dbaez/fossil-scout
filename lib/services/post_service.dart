import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/post_image_model.dart';
import 'like_service.dart';

class PostService {
  final SupabaseClient _client = Supabase.instance.client;
  final LikeService _likeService = LikeService();

  /// Método auxiliar para enriquecer posts con información de likes
  Future<List<PostModel>> _enrichPostsWithLikes(List<PostModel> posts) async {
    if (posts.isEmpty) return posts;
    
    final currentUserId = _client.auth.currentUser?.id;
    final postIds = posts.map((p) => p.id).toList();
    
    // Obtener conteos de likes para todos los posts
    final likesCounts = <String, int>{};
    for (final postId in postIds) {
      likesCounts[postId] = await _likeService.getLikesCount(postId);
    }
    
    // Obtener likes del usuario actual si está autenticado
    Set<String> likedPostIds = {};
    if (currentUserId != null) {
      final likedPosts = await _likeService.getLikedPosts(currentUserId);
      likedPostIds = likedPosts.toSet();
    }
    
    // Actualizar posts con información de likes
    return posts.map((post) {
      return PostModel(
        id: post.id,
        userId: post.userId,
        lat: post.lat,
        lng: post.lng,
        status: post.status,
        description: post.description,
        address: post.address,
        rockType: post.rockType,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        deletedAt: post.deletedAt,
        images: post.images,
        userName: post.userName,
        userPhotoUrl: post.userPhotoUrl,
        likesCount: likesCounts[post.id] ?? 0,
        isLiked: likedPostIds.contains(post.id),
      );
    }).toList();
  }

  /// Crea un nuevo post
  /// [initialStatus] permite especificar el estado inicial (pending o approved)
  Future<PostModel?> createPost({
    required String userId,
    required double lat,
    required double lng,
    String? description,
    String? address,
    String? rockType,
    required List<String> imageUrls,
    PostStatus initialStatus = PostStatus.pending,
  }) async {
    try {
      final now = DateTime.now();
      
      // Crear el post con el estado especificado
      final postData = {
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        'status': initialStatus.value,
        'description': description,
        'address': address,
        'rock_type': rockType,
        'created_at': now.toIso8601String(),
      };

      final postResponse = await _client
          .from('posts')
          .insert(postData)
          .select()
          .single();

      final postId = postResponse['id'] as String;

      // Crear las imágenes
      if (imageUrls.isNotEmpty) {
        final imagesData = imageUrls.asMap().entries.map((entry) {
          return {
            'post_id': postId,
            'image_url': entry.value,
            'display_order': entry.key,
            'created_at': now.toIso8601String(),
          };
        }).toList();

        await _client.from('post_images').insert(imagesData);
      }

      // Obtener el post completo con imágenes
      return await getPostById(postId);
    } catch (e) {
      print('Error creando post: $e');
      return null;
    }
  }

  /// Obtiene un post por ID con sus imágenes y datos del usuario
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            post_images(*),
            users!posts_user_id_fkey(display_name, photo_url)
          ''')
          .eq('id', postId)
          .single();

      final post = PostModel.fromJson(response);
      
      // Procesar imágenes
      final images = (response['post_images'] as List?)
          ?.map((img) => PostImageModel.fromJson(img as Map<String, dynamic>))
          .toList() ?? [];
      
      // Procesar datos del usuario
      final userData = response['users'] as Map<String, dynamic>?;
      
      // Obtener información de likes
      final likesCount = await _likeService.getLikesCount(postId);
      final isLiked = await _likeService.hasUserLiked(postId);
      
      return PostModel(
        id: post.id,
        userId: post.userId,
        lat: post.lat,
        lng: post.lng,
        status: post.status,
        description: post.description,
        address: post.address,
        rockType: post.rockType,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        deletedAt: post.deletedAt,
        images: images,
        userName: userData?['display_name'] as String?,
        userPhotoUrl: userData?['photo_url'] as String?,
        likesCount: likesCount,
        isLiked: isLiked,
      );
    } catch (e) {
      print('Error obteniendo post: $e');
      return null;
    }
  }

  /// Obtiene posts cercanos a una ubicación (en radio de km)
  Future<List<PostModel>> getNearbyPosts({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
    int limit = 50,
  }) async {
    try {
      // Usar PostGIS si está disponible, o filtrar por rango aproximado
      // Por ahora, usaremos un rango aproximado de lat/lng
      final latRange = radiusKm / 111.0; // ~111 km por grado de latitud
      final lngRange = radiusKm / (111.0 * (lat / 90.0).abs());

      final response = await _client
          .from('posts')
          .select('''
            *,
            post_images(*),
            users!posts_user_id_fkey(display_name, photo_url)
          ''')
          .gte('lat', lat - latRange)
          .lte('lat', lat + latRange)
          .gte('lng', lng - lngRange)
          .lte('lng', lng + lngRange)
          .eq('status', PostStatus.approved.value)
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = (response as List)
          .where((item) => item['deleted_at'] == null) // Filtrar eliminados
          .map((item) {
        final post = PostModel.fromJson(item);
        final images = (item['post_images'] as List?)
            ?.map((img) => PostImageModel.fromJson(img as Map<String, dynamic>))
            .toList() ?? [];
        final userData = item['users'] as Map<String, dynamic>?;
        
        return PostModel(
          id: post.id,
          userId: post.userId,
          lat: post.lat,
          lng: post.lng,
          status: post.status,
          description: post.description,
          address: post.address,
          rockType: post.rockType,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          deletedAt: post.deletedAt,
          images: images,
          userName: userData?['display_name'] as String?,
          userPhotoUrl: userData?['photo_url'] as String?,
        );
      }).toList();
      
      return await _enrichPostsWithLikes(posts);
    } catch (e) {
      print('Error obteniendo posts cercanos: $e');
      return [];
    }
  }

  /// Actualiza el estado de un post
  Future<bool> updatePostStatus({
    required String postId,
    required PostStatus newStatus,
  }) async {
    try {
      await _client
          .from('posts')
          .update({
            'status': newStatus.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId);
      return true;
    } catch (e) {
      print('Error actualizando estado del post: $e');
      return false;
    }
  }

  /// Obtiene posts pendientes de aprobación
  Future<List<PostModel>> getPendingPosts({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            post_images(*),
            users!posts_user_id_fkey(display_name, photo_url)
          ''')
          .eq('status', PostStatus.pending.value)
          .order('created_at', ascending: false)
          .limit(limit);

      final posts = (response as List)
          .where((item) => item['deleted_at'] == null)
          .map((item) {
        final post = PostModel.fromJson(item);
        final images = (item['post_images'] as List?)
            ?.map((img) => PostImageModel.fromJson(img as Map<String, dynamic>))
            .toList() ?? [];
        final userData = item['users'] as Map<String, dynamic>?;
        
        return PostModel(
          id: post.id,
          userId: post.userId,
          lat: post.lat,
          lng: post.lng,
          status: post.status,
          description: post.description,
          address: post.address,
          rockType: post.rockType,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          deletedAt: post.deletedAt,
          images: images,
          userName: userData?['display_name'] as String?,
          userPhotoUrl: userData?['photo_url'] as String?,
        );
      }).toList();
      
      return await _enrichPostsWithLikes(posts);
    } catch (e) {
      print('Error obteniendo posts pendientes: $e');
      return [];
    }
  }

  /// Obtiene el timeline de posts (últimos hallazgos)
  /// Muestra posts aprobados y posts pendientes del usuario actual
  /// Si se proporciona ubicación y sortByDate es false, ordena por cercanía
  /// Si sortByDate es true, ordena por fecha de creación (nuevo a viejo)
  Future<List<PostModel>> getTimeline({
    int limit = 20,
    int offset = 0,
    double? userLat,
    double? userLng,
    bool sortByDate = false,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      
      // Si ordenamos por fecha, podemos paginar en el servidor
      // Si ordenamos por distancia, necesitamos todos los posts para calcular distancias
      final response = sortByDate
          ? await _client
              .from('posts')
              .select('''
                *,
                post_images(*),
                users!posts_user_id_fkey(display_name, photo_url)
              ''')
              .or('status.eq.approved,status.eq.pending')
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1)
          : await _client
              .from('posts')
              .select('''
                *,
                post_images(*),
                users!posts_user_id_fkey(display_name, photo_url)
              ''')
              .or('status.eq.approved,status.eq.pending')
              .order('created_at', ascending: false);

      var posts = (response as List)
          .where((item) => item['deleted_at'] == null) // Filtrar eliminados
          .map((item) {
        final post = PostModel.fromJson(item);
        final images = (item['post_images'] as List?)
            ?.map((img) => PostImageModel.fromJson(img as Map<String, dynamic>))
            .toList() ?? [];
        final userData = item['users'] as Map<String, dynamic>?;
        
        return PostModel(
          id: post.id,
          userId: post.userId,
          lat: post.lat,
          lng: post.lng,
          status: post.status,
          description: post.description,
          address: post.address,
          rockType: post.rockType,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          deletedAt: post.deletedAt,
          images: images,
          userName: userData?['display_name'] as String?,
          userPhotoUrl: userData?['photo_url'] as String?,
        );
      }).toList();
      
      // Si se proporciona ubicación y no ordenamos por fecha, ordenar por distancia
      if (!sortByDate && userLat != null && userLng != null) {
        posts.sort((a, b) {
          final distA = _calculateDistance(userLat, userLng, a.lat, a.lng);
          final distB = _calculateDistance(userLat, userLng, b.lat, b.lng);
          return distA.compareTo(distB);
        });
      }
      
      // Aplicar paginación después de ordenar (solo si ordenamos por distancia)
      final paginatedPosts = sortByDate
          ? posts // Ya paginado en el servidor
          : posts.skip(offset).take(limit).toList();
      
      return await _enrichPostsWithLikes(paginatedPosts);
    } catch (e) {
      print('Error obteniendo timeline: $e');
      return [];
    }
  }
  
  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
