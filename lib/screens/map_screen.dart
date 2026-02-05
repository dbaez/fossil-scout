import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/comments_section.dart';
import '../l10n/app_localizations.dart';

/// Distancia máxima (en km) para mostrar ruta interna.
/// Si el fósil está más lejos, se abre la app de mapas externa.
const double _maxInternalRouteDistance = 50.0;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final RouteService _routeService = RouteService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<PostModel> _nearbyPosts = [];
  bool _isLoading = true;
  String? _selectedMarkerId;
  List<PostModel> _postsAtLocation = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Estado de la ruta
  List<PostModel> _optimalRoute = [];
  Set<Polyline> _routePolylines = {};
  bool _isCalculatingRoute = false;
  double _routeDistance = 0.0;
  String? _routeTimeStr;
  
  // Cache de iconos numerados
  final Map<int, BitmapDescriptor> _numberedIcons = {};
  
  // Estado para modo post único
  PostModel? _singlePostView;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _getCurrentLocation();
  }

  /// Centra el mapa en una ubicación específica y opcionalmente muestra un post
  void centerOnLocation(double lat, double lng, {PostModel? post}) {
    if (post != null) {
      // Modo post único: mostrar solo este post
      setState(() {
        _singlePostView = post;
      });
    }
    
    // Centrar el mapa con offset hacia arriba para que el marcador quede visible
    // Calculamos un offset más grande en latitud (hacia el norte) para que el marcador quede en la parte superior
    // Aproximadamente 0.015 grados hacia arriba (unos 1.5 km) para que quede claramente visible sobre los detalles
    final offsetLat = lat + 0.015;
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(offsetLat, lng), // Usar latitud con offset para centrar más arriba
        16.0, // Zoom más cercano para ver mejor
      ),
    );
    
    // Si se proporciona un post, mostrar bottom sheet después de un pequeño delay
    if (post != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showPostBottomSheet(post);
        }
      });
    }
  }
  
  /// Muestra un bottom sheet con los detalles del post
  void _showPostBottomSheet(PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => PointerInterceptor(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          child: Column(
            children: [
              // Header con handle y botón cerrar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Botón cerrar
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      iconSize: 24,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imágenes del post
                        if (post.images != null && post.images!.isNotEmpty)
                          SizedBox(
                            height: 250,
                            child: PageView.builder(
                              itemCount: post.images!.length,
                              itemBuilder: (context, index) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    post.images![index].imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Header con usuario
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: post.userPhotoUrl != null
                                  ? NetworkImage(
                                      post.userPhotoUrl!,
                                      headers: const {'Accept': 'image/*'},
                                    )
                                  : null,
                              child: post.userPhotoUrl == null
                                  ? Text(
                                      (post.userName ?? 'U')[0].toUpperCase(),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.userName ?? 'Usuario',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(post.status.value),
                              backgroundColor: post.status == PostStatus.approved
                                  ? Colors.green[100]
                                  : post.status == PostStatus.pending
                                      ? Colors.orange[100]
                                      : Colors.red[100],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Descripción
                        if (post.description != null && post.description!.isNotEmpty)
                          Text(
                            post.description!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Información adicional
                        if (post.address != null)
                          ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(AppLocalizations.of(context)!.address),
                            subtitle: Text(post.address!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        if (post.rockType != null)
                          ListTile(
                            leading: const Icon(Icons.category),
                            title: Text(AppLocalizations.of(context)!.materialType),
                            subtitle: Text(post.rockType!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ListTile(
                          leading: const Icon(Icons.map),
                          title: Text(AppLocalizations.of(context)!.coordinates),
                          subtitle: Text(
                            'Lat: ${post.lat.toStringAsFixed(6)}\n'
                            'Lng: ${post.lng.toStringAsFixed(6)}',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Botón "Llévame a este fósil" (solo en modo post único)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: (_currentPosition != null && !_isCalculatingRoute)
                                ? () {
                                    // Cerrar el bottom sheet antes de calcular la ruta
                                    Navigator.pop(context);
                                    _calculateRouteToPost(post);
                                  }
                                : null,
                            icon: _isCalculatingRoute
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.directions),
                            label: Text(_isCalculatingRoute 
                                ? AppLocalizations.of(context)!.calculatingRoute 
                                : AppLocalizations.of(context)!.takeMeToThisFossil),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        // Sección de comentarios
                        CommentsSection(post: post),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ), // Cierre Container
      ), // Cierre PointerInterceptor
    ), // Cierre DraggableScrollableSheet
    ).then((_) {
      // Cuando se cierra el bottom sheet, volver a mostrar todos los posts
      if (mounted) {
        setState(() {
          _singlePostView = null;
        });
      }
    });
  }
  
  /// Calcula la distancia en línea recta entre dos puntos (Haversine)
  double _calculateDirectDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Abre Google Maps o la app de mapas del usuario para navegar al destino
  Future<void> _openExternalMaps(double destLat, double destLng, String? placeName) async {
    // URL universal que funciona en todas las plataformas
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving'
    );
    
    // URL alternativa para iOS Maps
    final appleMapsUrl = Uri.parse(
      'https://maps.apple.com/?daddr=$destLat,$destLng&dirflg=d'
    );

    try {
      // Intentar abrir Google Maps primero
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        // Fallback a Apple Maps en iOS
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Si no hay app de mapas, abrir en el navegador
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir la aplicación de mapas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calcula la ruta óptima desde la ubicación actual hasta un post específico
  Future<void> _calculateRouteToPost(PostModel post) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.currentLocationError),
        ),
      );
      return;
    }

    // Calcular distancia directa primero
    final directDistance = _calculateDirectDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      post.lat,
      post.lng,
    );

    // Si el fósil está muy lejos, preguntar si abrir app de mapas externa
    if (directDistance > _maxInternalRouteDistance) {
      final shouldOpenExternal = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Destino lejano'),
          content: Text(
            'Este fósil está a ${directDistance.toStringAsFixed(0)} km de distancia. '
            '¿Deseas abrir Google Maps para navegar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.map),
              label: const Text('Abrir Maps'),
            ),
          ],
        ),
      );

      if (shouldOpenExternal == true) {
        await _openExternalMaps(post.lat, post.lng, post.description);
      }
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      // Obtener la ruta de navegación real desde la ubicación actual hasta el post
      final routeResult = await _routeService.getNavigationRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        posts: [post], // Solo el post destino
      );

      if (routeResult.points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noRouteFound),
          ),
        );
        setState(() {
          _isCalculatingRoute = false;
        });
        return;
      }

      // Crear polyline para mostrar la ruta de navegación
      final polyline = Polyline(
        polylineId: const PolylineId('route_to_post'),
        points: routeResult.points,
        color: AppTheme.primaryColor,
        width: 5,
        patterns: [],
        geodesic: true,
      );

      // Actualizar estado con la ruta y mostrar solo este post
      setState(() {
        _singlePostView = post; // Mostrar solo este post en el mapa
        _optimalRoute = [post];
        _routePolylines = {polyline};
        _routeDistance = routeResult.totalDistance;
        _isCalculatingRoute = false;
      });

      // Calcular tiempo estimado
      final minutes = (routeResult.totalDuration / 60).round();
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      final timeStr = hours > 0 
          ? '${hours}h ${remainingMinutes}min'
          : '~${minutes}min';

      setState(() {
        _routeTimeStr = timeStr;
      });

      // Centrar el mapa para mostrar toda la ruta
      if (routeResult.points.isNotEmpty && _mapController != null) {
        final bounds = _calculateBounds(routeResult.points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            bounds,
            150.0, // Padding uniforme (dejar espacio para el bottom sheet)
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ruta calculada: ${_routeDistance.toStringAsFixed(2)} km ($timeStr)',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculando la ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = position;
      });
      
      // Forzar actualización del mapa para mostrar la ubicación
      if (_mapController != null && mounted) {
        setState(() {});
      }
      
      // En web, verificar que los permisos de ubicación estén habilitados
      if (kIsWeb) {
        print('Ubicación obtenida en web: ${position.latitude}, ${position.longitude}');
        print('Asegúrate de que el navegador tenga permisos de ubicación habilitados');
      }

      // Cargar posts cercanos
      await _loadNearbyPosts(position.latitude, position.longitude);

      // Actualizar el estado para que se reconstruyan los marcadores
      if (mounted) {
        setState(() {});
      }

      // Mover el mapa a la ubicación actual y centrar
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNearbyPosts(double lat, double lng) async {
    try {
      final posts = await _postService.getNearbyPosts(
        lat: lat,
        lng: lng,
        radiusKm: 10.0,
      );
      setState(() {
        _nearbyPosts = posts;
        _isLoading = false;
      });
      // Forzar actualización de marcadores
      if (_mapController != null && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error cargando posts cercanos: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMapContent() {
    // Usar Google Maps tanto en web como en móvil
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 14.0,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        // Forzar actualización de marcadores después de que el mapa se cree
        if (mounted) {
          setState(() {});
        }
      },
      markers: _buildMarkers(),
      polylines: _routePolylines,
      myLocationEnabled: _currentPosition != null, // Habilitar solo si tenemos ubicación
      myLocationButtonEnabled: true, // Mostrar botón para centrar en ubicación
      compassEnabled: true,
      mapToolbarEnabled: false,
      // En web, asegurar que la ubicación se muestre
      zoomControlsEnabled: true,
    );
  }

  /// Crea un icono numerado para marcadores usando Canvas
  Future<BitmapDescriptor> _createNumberedIcon(int number) async {
    // Si ya existe en cache, retornarlo
    if (_numberedIcons.containsKey(number)) {
      return _numberedIcons[number]!;
    }
    
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(50, 50);
      
      // Dibujar círculo verde de fondo
      final paint = Paint()
        ..color = AppTheme.successColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
      
      // Dibujar borde blanco
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 1.5, borderPaint);
      
      // Dibujar número
      final textPainter = TextPainter(
        text: TextSpan(
          text: number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (bytes != null) {
        final bitmapDescriptor = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
        _numberedIcons[number] = bitmapDescriptor; // Guardar en cache
        return bitmapDescriptor;
      }
    } catch (e) {
      print('Error creando icono numerado: $e');
    }
    
    // Fallback: usar marcador verde sin número
    final fallback = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _numberedIcons[number] = fallback;
    return fallback;
  }
  
  /// Crea un marcador numerado para posts en la ruta óptima
  void _createNumberedMarker({
    required Set<Marker> markers,
    required PostModel post,
    required LatLng position,
    required int number,
    required List<PostModel> posts,
  }) {
    // Usar icono del cache si está disponible, sino usar marcador verde
    final icon = _numberedIcons[number] ?? 
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    
    markers.add(
      Marker(
        markerId: MarkerId('route_${post.id}'),
        position: position,
        icon: icon,
        // No mostrar InfoWindow, solo abrir bottom sheet al hacer tap
        onTap: () {
          _showPostsBottomSheet(posts);
        },
        zIndex: (1000 + number).toDouble(), // Mayor zIndex para posts en ruta
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Si estamos en modo post único, mostrar solo ese post
    if (_singlePostView != null) {
      markers.add(
        Marker(
          markerId: MarkerId(_singlePostView!.id),
          position: LatLng(_singlePostView!.lat, _singlePostView!.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          // No mostrar InfoWindow, solo abrir bottom sheet al hacer tap
          onTap: () {
            _showPostBottomSheet(_singlePostView!);
          },
        ),
      );
      return markers;
    }

    // Nota: En web, los marcadores personalizados con BitmapDescriptor no funcionan bien.
    // Por eso usamos myLocationEnabled: true en el GoogleMap para mostrar la ubicación nativa (azul).
    // No agregamos un marcador personalizado aquí para la ubicación del usuario.

    // Agrupar posts por ubicación cercana (dentro de 50 metros)
    // Excluir posts que estén muy cerca de la ubicación del usuario para evitar confusión
    final groupedPosts = <String, List<PostModel>>{};
    
    for (final post in _nearbyPosts) {
      // Verificar que el post no esté en la misma ubicación que el usuario
      if (_currentPosition != null) {
        final distanceToUser = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          post.lat,
          post.lng,
        );
        // Si el post está a menos de 10 metros del usuario, podría ser confuso, pero lo mostramos
      }
      
      // Buscar si hay un grupo cercano
      String? groupKey;
      for (final key in groupedPosts.keys) {
        final keyParts = key.split(',');
        final keyLat = double.parse(keyParts[0]);
        final keyLng = double.parse(keyParts[1]);
        
        final distance = Geolocator.distanceBetween(
          keyLat,
          keyLng,
          post.lat,
          post.lng,
        );
        
        if (distance < 50) { // 50 metros de radio
          groupKey = key;
          break;
        }
      }
      
      if (groupKey != null) {
        groupedPosts[groupKey]!.add(post);
      } else {
        // Crear nuevo grupo
        final newKey = '${post.lat},${post.lng}';
        groupedPosts[newKey] = [post];
      }
    }

    // Crear marcadores (uno por grupo, o individual si no hay grupo)
    for (final entry in groupedPosts.entries) {
      final posts = entry.value;
      final firstPost = posts.first;
      final isMultiple = posts.length > 1;
      
      // Calcular posición promedio si hay múltiples posts
      double avgLat = firstPost.lat;
      double avgLng = firstPost.lng;
      if (isMultiple) {
        avgLat = posts.map((p) => p.lat).reduce((a, b) => a + b) / posts.length;
        avgLng = posts.map((p) => p.lng).reduce((a, b) => a + b) / posts.length;
      }

      final firstImage = firstPost.images?.isNotEmpty == true
          ? firstPost.images!.first.imageUrl
          : null;

      // Para múltiples posts, no mostrar InfoWindow y abrir directamente el bottom sheet
      if (isMultiple) {
        // Verificar si alguno de los posts está en la ruta y obtener el índice del primero
        int? routeIndex;
        for (var i = 0; i < _optimalRoute.length; i++) {
          if (posts.any((p) => p.id == _optimalRoute[i].id)) {
            routeIndex = i;
            break;
          }
        }
        final hasPostInRoute = routeIndex != null;
        
        if (hasPostInRoute) {
          // Crear marcador numerado para el primer post del grupo en la ruta
          final postInRoute = posts.firstWhere((p) => _optimalRoute.any((r) => r.id == p.id));
          _createNumberedMarker(
            markers: markers,
            post: postInRoute,
            position: LatLng(avgLat, avgLng),
            number: routeIndex! + 1,
            posts: posts,
          );
        } else {
          markers.add(
            Marker(
              markerId: MarkerId('group_${firstPost.id}'),
              position: LatLng(avgLat, avgLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              // No definir infoWindow para evitar que se muestre
              onTap: () {
                // Abrir directamente el bottom sheet sin mostrar InfoWindow
                _showPostsBottomSheet(posts);
              },
            ),
          );
        }
      } else {
        // Para un solo post, verificar si está en la ruta óptima y obtener su índice
        final routeIndex = _optimalRoute.indexWhere((p) => p.id == firstPost.id);
        final isInRoute = routeIndex != -1;
        
        // Si está en la ruta, crear marcador numerado
        if (isInRoute) {
          // Crear marcador numerado para posts en la ruta
          _createNumberedMarker(
            markers: markers,
            post: firstPost,
            position: LatLng(avgLat, avgLng),
            number: routeIndex + 1, // Numerar desde 1
            posts: posts,
          );
        } else {
          // Marcador normal para posts fuera de la ruta
          markers.add(
            Marker(
              markerId: MarkerId(firstPost.id),
              position: LatLng(avgLat, avgLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              // No mostrar InfoWindow, solo abrir bottom sheet al hacer tap
              onTap: () {
                _showPostsBottomSheet(posts);
              },
            ),
          );
        }
      }
    }

    return markers;
  }

  void _showPostsBottomSheet(List<PostModel> posts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true, // Permite cerrar al tocar fuera
      enableDrag: true, // Permite arrastrar para cerrar
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5), // Fondo semi-transparente
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: posts.length == 1 ? 0.5 : 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => PointerInterceptor(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          child: Column(
            children: [
              // Header con handle y botón cerrar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Spacer(),
                    // Título
                    Expanded(
                      child: Text(
                        posts.length == 1 
                            ? 'Hallazgo'
                            : '${posts.length} hallazgos en esta ubicación',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Botón cerrar
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Lista de posts
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final firstImage = post.images?.isNotEmpty == true
                        ? post.images!.first.imageUrl
                        : null;
                    
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context); // Cerrar bottom sheet
                            _showPostDetail(post); // Mostrar detalle del post
                          },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Miniatura de imagen
                              if (firstImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    firstImage,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              // Información del post
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.description ?? 'Sin descripción',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (post.address != null) ...[
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context); // Cerrar bottom sheet
                                          // Centrar el mapa en esta ubicación
                                          _mapController?.animateCamera(
                                            CameraUpdate.newLatLngZoom(
                                              LatLng(post.lat, post.lng),
                                              16.0,
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: AppTheme.primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                post.address!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 10,
                                              color: AppTheme.primaryColor.withOpacity(0.6),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (post.rockType != null) ...[
                                      const SizedBox(height: 4),
                                      Chip(
                                        label: Text(
                                          post.rockType!,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ), // Cierra Container
      ), // Cierra PointerInterceptor
    ), // Cierra DraggableScrollableSheet
    );
  }

  void _showPostDetail(PostModel post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imágenes del post
              if (post.images != null && post.images!.isNotEmpty)
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    itemCount: post.images!.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          post.images![index].imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      );
                    },
                  ),
                ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y usuario
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: post.userPhotoUrl != null
                              ? NetworkImage(
                                  post.userPhotoUrl!,
                                  headers: const {'Accept': 'image/*'},
                                )
                              : null,
                          child: post.userPhotoUrl == null
                              ? Text(
                                  (post.userName ?? 'U')[0].toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName ?? 'Usuario',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(post.status.value),
                          backgroundColor: post.status == PostStatus.approved
                              ? Colors.green[100]
                              : post.status == PostStatus.pending
                                  ? Colors.orange[100]
                                  : Colors.red[100],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción
                    if (post.description != null && post.description!.isNotEmpty)
                      Text(
                        post.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Información adicional
                    if (post.address != null)
                      InkWell(
                        onTap: () {
                          Navigator.pop(context); // Cerrar diálogo
                          // Centrar el mapa en esta ubicación
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(post.lat, post.lng),
                              16.0,
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: AppTheme.primaryColor,
                          ),
                          title: const Text('Dirección'),
                          subtitle: Text(post.address!),
                          contentPadding: EdgeInsets.zero,
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    if (post.rockType != null)
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: const Text('Tipo de material'),
                        subtitle: Text(post.rockType!),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ListTile(
                      leading: const Icon(Icons.map),
                      title: const Text('Coordenadas'),
                      subtitle: Text(
                        'Lat: ${post.lat.toStringAsFixed(6)}\n'
                        'Lng: ${post.lng.toStringAsFixed(6)}',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              
              // Sección de comentarios
              CommentsSection(post: post),
              
              // Botón cerrar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calcula y muestra la ruta óptima
  Future<void> _calculateOptimalRoute() async {
    if (_currentPosition == null || _nearbyPosts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay posts cercanos para calcular una ruta'),
        ),
      );
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      // Calcular ruta óptima (máximo 5 km)
      final route = await _routeService.calculateOptimalRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        posts: _nearbyPosts,
        maxDistanceKm: 5.0,
      );

      if (route.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo crear una ruta dentro del límite de 5 km'),
          ),
        );
        setState(() {
          _isCalculatingRoute = false;
        });
        return;
      }

      // Obtener ruta de navegación completa desde Google Directions API
      final routeResult = await _routeService.getNavigationRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        posts: route,
      );

      if (routeResult.points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener la ruta de navegación'),
          ),
        );
        setState(() {
          _isCalculatingRoute = false;
        });
        return;
      }

      // Crear polyline para mostrar la ruta de navegación
      final polyline = Polyline(
        polylineId: const PolylineId('optimal_route'),
        points: routeResult.points,
        color: AppTheme.primaryColor,
        width: 5,
        patterns: [],
        geodesic: true, // Seguir la curvatura de la Tierra
      );

      // Pre-cargar iconos numerados para los posts en la ruta
      for (var i = 0; i < route.length; i++) {
        await _createNumberedIcon(i + 1);
      }
      
      setState(() {
        _optimalRoute = route;
        _routePolylines = {polyline};
        _routeDistance = routeResult.totalDistance;
        _isCalculatingRoute = false;
      });

      // Ajustar la cámara para mostrar toda la ruta
      if (routeResult.points.isNotEmpty && _mapController != null) {
        final bounds = _calculateBounds(routeResult.points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }

      // Calcular tiempo estimado
      final minutes = (routeResult.totalDuration / 60).round();
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      final timeStr = hours > 0 
          ? '${hours}h ${remainingMinutes}min'
          : '~${minutes}min';

      setState(() {
        _routeTimeStr = timeStr;
      });
    } catch (e) {
      print('Error calculando ruta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al calcular la ruta: $e'),
        ),
      );
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  /// Limpia la ruta del mapa
  void _clearRoute() {
    // Cerrar cualquier SnackBar visible
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    setState(() {
      _optimalRoute = [];
      _routePolylines = {};
      _routeDistance = 0.0;
      _routeTimeStr = null;
    });
    
    // Mostrar confirmación
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta limpiada'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Calcula los límites de un conjunto de puntos
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Fósiles'),
        actions: [
          if (_optimalRoute.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearRoute,
              tooltip: 'Limpiar ruta',
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(
                  child: Text('No se pudo obtener tu ubicación'),
                )
              : Stack(
                  children: [
                    _buildMapContent(),
                    // Botón flotante para calcular ruta
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton.extended(
                        onPressed: _isCalculatingRoute ? null : _calculateOptimalRoute,
                        icon: _isCalculatingRoute
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.route),
                        label: Text(_isCalculatingRoute
                            ? 'Calculando...'
                            : _optimalRoute.isEmpty
                                ? 'Ruta Óptima'
                                : 'Recalcular'),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    // Información de la ruta
                    if (_optimalRoute.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Card(
                          elevation: 8,
                          color: Colors.grey[850],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.route,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ruta de navegación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_optimalRoute.length} posts, ${_routeDistance.toStringAsFixed(2)} km, ${_routeTimeStr ?? ""}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: _clearRoute,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue[300],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
