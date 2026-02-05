import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/post_card.dart';
import '../widgets/fossil_compass_icon.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class TimelineScreen extends StatefulWidget {
  final Function(double lat, double lng, PostModel post)? onNavigateToMap;

  const TimelineScreen({
    super.key,
    this.onNavigateToMap,
  });

  @override
  State<TimelineScreen> createState() => TimelineScreenState();
}

enum SortMode { distance, date }

class TimelineScreenState extends State<TimelineScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _offset = 0;
  bool _isAdmin = false;
  Position? _currentPosition;
  SortMode _sortMode = SortMode.distance; // Por defecto: distancia

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Sin permisos, cargar sin ordenar por ubicación
          _loadPosts();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Sin permisos, cargar sin ordenar por ubicación
        _loadPosts();
        return;
      }

      // Obtener ubicación
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _loadPosts();
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      // Cargar posts sin ordenar por ubicación
      _loadPosts();
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = await _userService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.role.value == 'admin';
      });
    }
  }

  /// Cambia el modo de ordenamiento y recarga los posts
  void _changeSortMode(SortMode mode) {
    setState(() {
      _sortMode = mode;
    });
    _loadPosts(refresh: true);
  }

  /// Método público para cambiar a ordenamiento por fecha y recargar
  void switchToDateSortAndRefresh() {
    _changeSortMode(SortMode.date);
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _offset = 0;
        _posts = [];
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    try {
      final posts = await _postService.getTimeline(
        limit: 20,
        offset: _offset,
        userLat: _sortMode == SortMode.distance ? _currentPosition?.latitude : null,
        userLng: _sortMode == SortMode.distance ? _currentPosition?.longitude : null,
        sortByDate: _sortMode == SortMode.date,
      );

      setState(() {
        if (refresh) {
          _posts = posts;
        } else {
          _posts.addAll(posts);
        }
        _offset += posts.length;
        _hasMore = posts.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingPosts}: $e')),
        );
      }
    }
  }

  Future<void> _approvePost(String postId) async {
    try {
      final success = await _postService.updatePostStatus(
        postId: postId,
        newStatus: PostStatus.approved,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.postApproved),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar posts
        _loadPosts(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorApprovingPost),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _rejectPost(String postId) async {
    try {
      final success = await _postService.updatePostStatus(
        postId: postId,
        newStatus: PostStatus.rejected,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.postRejected),
            backgroundColor: Colors.orange,
          ),
        );
        // Recargar posts
        _loadPosts(refresh: true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorRejectingPost),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FossilCompassIcon(
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.appTitle,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          PopupMenuButton<SortMode>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sortMode == SortMode.distance ? Icons.near_me : Icons.access_time,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _sortMode == SortMode.distance 
                      ? AppLocalizations.of(context)!.distance 
                      : AppLocalizations.of(context)!.antiquity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
              onSelected: (SortMode mode) {
                _changeSortMode(mode);
              },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<SortMode>(
                value: SortMode.distance,
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me,
                      size: 18,
                      color: _sortMode == SortMode.distance
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.distance,
                      style: TextStyle(
                        color: _sortMode == SortMode.distance
                            ? AppTheme.primaryColor
                            : Colors.grey[700],
                        fontWeight: _sortMode == SortMode.distance
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<SortMode>(
                value: SortMode.date,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: _sortMode == SortMode.date
                          ? AppTheme.primaryColor
                          : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.antiquity,
                      style: TextStyle(
                        color: _sortMode == SortMode.date
                            ? AppTheme.primaryColor
                            : Colors.grey[700],
                        fontWeight: _sortMode == SortMode.date
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.exploringFindings,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            )
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noFindingsYet,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.beFirstToDiscover,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadPosts(refresh: true),
                  child: ListView.builder(
                    itemCount: _posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _posts.length) {
                        // Cargar más
                        _loadPosts();
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final post = _posts[index];
                      return PostCard(
                        post: post,
                        isAdmin: _isAdmin,
                        onApprove: () => _approvePost(post.id),
                        onReject: () => _rejectPost(post.id),
                        onAddressTap: widget.onNavigateToMap != null
                            ? () => widget.onNavigateToMap!(post.lat, post.lng, post)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
