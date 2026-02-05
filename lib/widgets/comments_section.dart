import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/comment_service.dart';
import '../theme/app_theme.dart';
import '../screens/comments_screen.dart';
import '../l10n/app_localizations.dart';

class CommentsSection extends StatefulWidget {
  final PostModel post;

  const CommentsSection({
    super.key,
    required this.post,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _commentController.addListener(() {
      setState(() {}); // Actualizar UI cuando cambia el texto
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.getCommentsByPostId(widget.post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando comentarios: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para comentar')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final comment = await _commentService.createComment(
        postId: widget.post.id,
        userId: user.id,
        content: content,
      );

      if (comment != null) {
        _commentController.clear();
        setState(() {
          _comments.add(comment);
          _isSubmitting = false;
        });
        
        // Scroll al final para ver el nuevo comentario
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.publish),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorLoadingPosts),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final maxPreviewComments = 2;
    final hasMoreComments = _comments.length > maxPreviewComments;
    final previewComments = _comments.take(maxPreviewComments).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista de comentarios (máximo 2 para preview)
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_comments.isNotEmpty) ...[
          // Mostrar solo los primeros comentarios
          ...previewComments.map((comment) => _buildCommentItem(comment, compact: true)),
          
          // Botón para ver todos los comentarios
          if (hasMoreComments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(post: widget.post),
                    ),
                  ).then((_) {
                    // Recargar comentarios cuando se regrese
                    _loadComments();
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '${AppLocalizations.of(context)!.viewAllComments} (${_comments.length})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
        
        // Campo para agregar comentario (estilo Instagram - compacto)
        if (currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Avatar del usuario actual
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: currentUser.userMetadata?['photo_url'] != null
                      ? NetworkImage(
                          currentUser.userMetadata!['photo_url'] as String,
                          headers: const {'Accept': 'image/*'},
                        )
                      : null,
                  child: currentUser.userMetadata?['photo_url'] == null
                      ? Text(
                          (currentUser.userMetadata?['display_name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Campo de texto compacto
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.writeComment,
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                // Botón enviar
                TextButton(
                  onPressed: _isSubmitting || _commentController.text.trim().isEmpty
                      ? null
                      : _submitComment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          AppLocalizations.of(context)!.publish,
                          style: TextStyle(
                            color: _commentController.text.trim().isEmpty
                                ? Colors.grey[400]
                                : AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Text(
                  'Inicia sesión para comentar',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment, {bool compact = false}) {
    final timeAgo = _getTimeAgo(comment.createdAt);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 4 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar del usuario (más pequeño en modo compacto)
          CircleAvatar(
            radius: compact ? 16 : 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: comment.userPhotoUrl != null
                ? NetworkImage(
                    comment.userPhotoUrl!,
                    headers: const {'Accept': 'image/*'},
                  )
                : null,
            child: comment.userPhotoUrl == null
                ? Text(
                    (comment.userName ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: compact ? 12 : 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Contenido del comentario (estilo Instagram)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: comment.userName ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                if (compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
}
