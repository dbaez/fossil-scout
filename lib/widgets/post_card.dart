import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../services/like_service.dart';
import 'comments_section.dart';
import 'fossil_heart_icon.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final bool isAdmin;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onAddressTap;

  const PostCard({
    super.key,
    required this.post,
    this.isAdmin = false,
    this.onApprove,
    this.onReject,
    this.onAddressTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late PostModel _post;
  final LikeService _likeService = LikeService();
  bool _isLiking = false;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  late Animation<double> _likeOpacityAnimation;
  late Animation<double> _likeRotationAnimation;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    
    // Configurar animación de like
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_likeAnimationController);
    
    _likeOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_likeAnimationController);
    
    _likeRotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    
    setState(() {
      _isLiking = true;
      // Iniciar animación solo si se está dando like (no quitando)
      if (!_post.isLiked) {
        _likeAnimationController.reset();
        _likeAnimationController.forward();
      }
    });

    try {
      final wasLiked = _post.isLiked;
      final newLiked = await _likeService.toggleLike(_post.id);
      
      setState(() {
        _post = PostModel(
          id: _post.id,
          userId: _post.userId,
          lat: _post.lat,
          lng: _post.lng,
          status: _post.status,
          description: _post.description,
          address: _post.address,
          rockType: _post.rockType,
          createdAt: _post.createdAt,
          updatedAt: _post.updatedAt,
          deletedAt: _post.deletedAt,
          images: _post.images,
          userName: _post.userName,
          userPhotoUrl: _post.userPhotoUrl,
          likesCount: _post.likesCount + (newLiked ? 1 : -1),
          isLiked: newLiked,
        );
        _isLiking = false;
      });
    } catch (e) {
      setState(() {
        _isLiking = false;
      });
      _likeAnimationController.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final firstImage = _post.images?.isNotEmpty == true
        ? _post.images!.first.imageUrl
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con usuario y fecha (estilo Instagram - arriba de la imagen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _post.userPhotoUrl != null
                        ? NetworkImage(
                            _post.userPhotoUrl!,
                            headers: const {'Accept': 'image/*'},
                          )
                        : null,
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error cargando foto de perfil: $exception');
                    },
                    child: _post.userPhotoUrl == null
                        ? Text(
                            (_post.userName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post.userName ?? 'Explorador',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getTimeAgo(_post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de estado (más discreto)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                    color: _post.status == PostStatus.approved
                        ? AppTheme.successColor.withOpacity(0.2)
                        : _post.status == PostStatus.pending
                            ? AppTheme.warningColor.withOpacity(0.2)
                            : AppTheme.errorColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _post.status.value.toUpperCase(),
                    style: TextStyle(
                      color: _post.status == PostStatus.approved
                          ? AppTheme.successColor
                          : _post.status == PostStatus.pending
                              ? AppTheme.warningColor
                              : AppTheme.errorColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Imagen (estilo Instagram - cuadrada o casi cuadrada)
            if (firstImage != null)
              GestureDetector(
                onDoubleTap: _toggleLike,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0, // Cuadrada como Instagram
                      child: Image.network(
                        firstImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    // Animación de like al hacer doble toque (corazón fósil)
                    AnimatedBuilder(
                      animation: _likeAnimationController,
                      builder: (context, child) {
                        if (_likeAnimationController.value == 0.0) {
                          return const SizedBox.shrink();
                        }
                        return IgnorePointer(
                          child: Opacity(
                            opacity: _likeOpacityAnimation.value,
                            child: Transform.scale(
                              scale: _likeScaleAnimation.value,
                              child: Transform.rotate(
                                angle: _likeRotationAnimation.value,
                                child: FossilHeartIcon(
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Iconos de interacción (estilo Instagram)
                  Row(
                    children: [
                      IconButton(
                        icon: _isLiking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _post.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 24,
                                color: _post.isLiked ? Colors.red : Colors.black,
                              ),
                        onPressed: _toggleLike,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (_post.likesCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${_post.likesCount}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.comment_outlined, size: 24),
                        onPressed: () {
                          // TODO: Navegar a pantalla de comentarios
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                
                  // Descripción (estilo Instagram - texto simple)
                  if (_post.description != null && _post.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: _post.userName ?? 'Explorador',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: _post.description!),
                          ],
                        ),
                      ),
                    ),
                  
                  // Información adicional (más compacta)
                  if (_post.address != null || _post.rockType != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (_post.address != null)
                            InkWell(
                              onTap: widget.onAddressTap,
                              child: Text(
                                '📍 ${_post.address!}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          if (_post.rockType != null)
                            Text(
                              '🪨 ${_post.rockType!}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                
                  // Botones de aprobación para administradores
                  if (widget.isAdmin && _post.status == PostStatus.pending) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.warningColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onReject,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Rechazar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: BorderSide(color: AppTheme.errorColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: widget.onApprove,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Aprobar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Sección de comentarios (más compacta)
                  CommentsSection(post: _post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
