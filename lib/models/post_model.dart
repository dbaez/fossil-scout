import 'post_image_model.dart';

enum PostStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const PostStatus(this.value);

  static PostStatus fromString(String value) {
    return PostStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PostStatus.pending,
    );
  }
}

class PostModel {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final PostStatus status;
  final String? description;
  final String? address;
  final String? rockType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // Relaciones (opcionales, se cargan por separado)
  final List<PostImageModel>? images;
  final String? userName;
  final String? userPhotoUrl;
  
  // Información de likes
  final int likesCount;
  final bool isLiked;

  PostModel({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.status,
    this.description,
    this.address,
    this.rockType,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.images,
    this.userName,
    this.userPhotoUrl,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      status: PostStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      address: json['address'] as String?,
      rockType: json['rock_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((img) => PostImageModel.fromJson(img as Map<String, dynamic>))
              .toList()
          : null,
      userName: json['user_name'] as String?,
      userPhotoUrl: json['user_photo_url'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'status': status.value,
      'description': description,
      'address': address,
      'rock_type': rockType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
