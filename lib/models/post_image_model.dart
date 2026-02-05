class PostImageModel {
  final String id;
  final String postId;
  final String imageUrl;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  PostImageModel({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.displayOrder,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory PostImageModel.fromJson(Map<String, dynamic> json) {
    return PostImageModel(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      imageUrl: json['image_url'] as String,
      displayOrder: json['display_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
