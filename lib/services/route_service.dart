import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../models/post_model.dart';

// Para web, usar JavaScript interop
import 'dart:js' as js;
import 'dart:js_util' as js_util;

class RouteService {
  static const String _directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  // API key configurada via variables de entorno
  static String get _apiKey => EnvConfig.googleMapsApiKey;

  /// Calcula una ruta óptima que visite los posts más cercanos sin superar 5 km
  /// Usa un algoritmo greedy: siempre va al post más cercano que no supere el límite
  Future<List<PostModel>> calculateOptimalRoute({
    required double startLat,
    required double startLng,
    required List<PostModel> posts,
    required double maxDistanceKm,
  }) async {
    if (posts.isEmpty) return [];

    final visited = <String>{};
    final route = <PostModel>[];
    double currentLat = startLat;
    double currentLng = startLng;
    double totalDistance = 0.0;

    // Mientras haya posts sin visitar y no hayamos superado el límite
    while (visited.length < posts.length) {
      PostModel? nearestPost;
      double nearestDistance = double.infinity;

      // Encontrar el post más cercano que no hayamos visitado
      for (final post in posts) {
        final postKey = '${post.lat},${post.lng}';
        if (visited.contains(postKey)) continue;

        final distance = Geolocator.distanceBetween(
          currentLat,
          currentLng,
          post.lat,
          post.lng,
        ) / 1000; // Convertir a km

        // Verificar que agregar este post no supere el límite
        // (incluyendo la distancia de regreso al inicio)
        final distanceBack = Geolocator.distanceBetween(
          post.lat,
          post.lng,
          startLat,
          startLng,
        ) / 1000;

        final newTotalDistance = totalDistance + distance + distanceBack;

        if (distance < nearestDistance && newTotalDistance <= maxDistanceKm) {
          nearestDistance = distance;
          nearestPost = post;
        }
      }

      // Si no encontramos ningún post que quepa en la ruta, terminamos
      if (nearestPost == null) break;

      // Agregar el post a la ruta
      route.add(nearestPost);
      visited.add('${nearestPost.lat},${nearestPost.lng}');
      totalDistance += nearestDistance;
      currentLat = nearestPost.lat;
      currentLng = nearestPost.lng;
    }

    return route;
  }

  /// Obtiene las coordenadas de la ruta de navegación completa desde Google Directions API
  /// Retorna la ruta real siguiendo calles y caminos, no líneas rectas
  Future<RouteResult> getNavigationRoute({
    required double startLat,
    required double startLng,
    required List<PostModel> posts,
  }) async {
    if (posts.isEmpty) {
      return RouteResult(
        points: [],
        totalDistance: 0.0,
        totalDuration: 0,
      );
    }

    // Para web, usar JavaScript interop para evitar CORS
    if (kIsWeb) {
      return await _getNavigationRouteWeb(
        startLat: startLat,
        startLng: startLng,
        posts: posts,
      );
    }

    // Para móvil, usar HTTP normal
    final waypointsStr = posts.map((p) => '${p.lat},${p.lng}').join('|');
    
    final url = Uri.parse(
      '$_directionsApiUrl?origin=$startLat,$startLng'
      '&destination=$startLat,$startLng' // Regresar al inicio
      '&waypoints=optimize:true|$waypointsStr'
      '&mode=walking' // Modo caminando para rutas peatonales
      '&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['status'] == 'OK' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = (data['routes'] as List)[0] as Map<String, dynamic>;
          final allPoints = <LatLng>[];
          double totalDistance = 0.0;
          int totalDuration = 0;

          // Obtener todos los puntos de todos los legs (segmentos) de la ruta
          if (route['legs'] != null) {
            final legs = route['legs'] as List;
            for (final leg in legs) {
              final legMap = leg as Map<String, dynamic>;
              
              // Sumar distancia y duración con manejo seguro de tipos
              if (legMap['distance'] != null) {
                final distance = legMap['distance'] as Map<String, dynamic>;
                if (distance['value'] != null) {
                  final value = distance['value'];
                  if (value is num) {
                    totalDistance += value / 1000.0; // Convertir a km
                  }
                }
              }
              
              if (legMap['duration'] != null) {
                final duration = legMap['duration'] as Map<String, dynamic>;
                if (duration['value'] != null) {
                  final value = duration['value'];
                  if (value is num) {
                    totalDuration += value.toInt(); // En segundos
                  }
                }
              }

              // Obtener todos los steps (pasos) de cada leg para la ruta detallada
              if (legMap['steps'] != null) {
                final steps = legMap['steps'] as List;
                for (final step in steps) {
                  final stepMap = step as Map<String, dynamic>;
                  if (stepMap['polyline'] != null) {
                    final polyline = stepMap['polyline'] as Map<String, dynamic>;
                      if (polyline['points'] != null) {
                        final stepPoints = _decodePolyline(
                          polyline['points'] as String,
                          startLat,
                          startLng,
                          10.0, // Radio máximo de 10 km
                        );
                        allPoints.addAll(stepPoints);
                      }
                  }
                }
              }
            }
          }

          // Si no hay steps, usar el overview_polyline como fallback
          if (allPoints.isEmpty && route['overview_polyline'] != null) {
            final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;
            if (overviewPolyline['points'] != null) {
              final polyline = overviewPolyline['points'] as String;
              allPoints.addAll(_decodePolyline(
                polyline,
                startLat,
                startLng,
                10.0, // Radio máximo de 10 km
              ));
            }
          }

          return RouteResult(
            points: allPoints,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
          );
        } else {
          // Si hay un error en la API, mostrar el mensaje
          final status = data['status'] as String? ?? 'UNKNOWN';
          final errorMessage = data['error_message'] as String? ?? 'Error desconocido';
          print('Error en Directions API: $status - $errorMessage');
        }
      } else {
        print('Error HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error obteniendo ruta de navegación: $e');
      print('Stack trace: $stackTrace');
    }

    // Si falla, retornar ruta vacía
    return RouteResult(
      points: [],
      totalDistance: 0.0,
      totalDuration: 0,
    );
  }

  /// Obtiene la ruta usando JavaScript interop (para web, evita CORS)
  Future<RouteResult> _getNavigationRouteWeb({
    required double startLat,
    required double startLng,
    required List<PostModel> posts,
  }) async {
    // Radio máximo para filtrar puntos (10 km para cubrir ruta de 5 km + regreso)
    const double maxRadiusKm = 10.0;
    try {
      // Esperar a que Google Maps y la función helper estén disponibles
      int attempts = 0;
      while (attempts < 20) { // Esperar hasta 10 segundos (20 * 500ms)
        if (js.context.hasProperty('getDirectionsRoute')) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      // Verificar que la función helper esté disponible
      if (!js.context.hasProperty('getDirectionsRoute')) {
        print('Función helper getDirectionsRoute no está disponible después de esperar');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }
      
      // Verificar también que Google Maps esté cargado
      if (!js.context.hasProperty('google')) {
        print('Google Maps JavaScript API no está disponible');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }

      // Verificar que la función helper esté disponible
      if (!js.context.hasProperty('getDirectionsRoute')) {
        print('Función helper getDirectionsRoute no está disponible');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }

      // Preparar waypoints
      final waypointsList = posts.map((p) {
        return js_util.jsify({
          'location': js_util.jsify({'lat': p.lat, 'lng': p.lng}),
          'stopover': true,
        });
      }).toList();
      final waypoints = js_util.jsify(waypointsList);

      // Configurar request
      final request = js_util.jsify({
        'origin': js_util.jsify({'lat': startLat, 'lng': startLng}),
        'destination': js_util.jsify({'lat': startLat, 'lng': startLng}),
        'waypoints': waypoints,
        'optimizeWaypoints': true,
        'travelMode': 'WALKING',
      });

      // Hacer la petición de forma asíncrona usando un Completer
      final completer = Completer<RouteResult>();

      // Usar la función helper definida en index.html
      // Acceder a window.getDirectionsRoute usando js_util
      final window = js.context['window'];
      if (window == null) {
        print('window no está disponible');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }
      
      if (!js_util.hasProperty(window, 'getDirectionsRoute')) {
        print('getDirectionsRoute no está disponible en window');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }
      
      final getDirectionsRoute = js_util.getProperty(window, 'getDirectionsRoute');
      if (getDirectionsRoute == null) {
        print('getDirectionsRoute es null');
        return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
      }
      
      // Llamar a la función directamente usando Function.apply
      final callback = js.allowInterop((result, status) {
        print('Callback de Directions recibido. Status: $status');
        if (status == 'OK' && result != null) {
          print('Procesando respuesta OK de Directions...');
          try {
            var allPoints = <LatLng>[];
            double totalDistance = 0.0;
            int totalDuration = 0;

            // Procesar la respuesta - convertir a Dart primero
            print('Convirtiendo resultado a Dart...');
            final dartResult = js_util.dartify(result);
            print('dartResult tipo: ${dartResult.runtimeType}');
            if (dartResult == null || dartResult is! Map) {
              print('Resultado no es un Map válido. Tipo: ${dartResult?.runtimeType}');
              completer.complete(RouteResult(points: [], totalDistance: 0.0, totalDuration: 0));
              return;
            }

            final resultMap = dartResult as Map;
            print('resultMap keys: ${resultMap.keys}');
            final routes = resultMap['routes'];
            print('routes tipo: ${routes.runtimeType}');
            if (routes != null && routes is List && routes.isNotEmpty) {
              print('Procesando ${routes.length} ruta(s)...');
              final route = routes[0] as Map;
              print('route keys: ${route.keys}');
              final legs = route['legs'];
              print('legs tipo: ${legs.runtimeType}, es List: ${legs is List}');
              if (legs is List) {

                print('Procesando ${legs.length} leg(s)...');
                for (var i = 0; i < legs.length; i++) {
                  final leg = legs[i];
                  if (leg is! Map) {
                    print('Leg $i no es un Map, saltando...');
                    continue;
                  }
                  final legMap = leg as Map;
                  print('Procesando leg $i...');
                  
                  // Sumar distancia y duración
                  if (legMap['distance'] != null && legMap['distance'] is Map) {
                    final distance = legMap['distance'] as Map;
                    if (distance['value'] != null && distance['value'] is num) {
                      totalDistance += (distance['value'] as num) / 1000.0;
                    }
                  }
                  
                  if (legMap['duration'] != null && legMap['duration'] is Map) {
                    final duration = legMap['duration'] as Map;
                    if (duration['value'] != null && duration['value'] is num) {
                      totalDuration += (duration['value'] as num).toInt();
                    }
                  }

                  // Obtener puntos de cada step
                  final steps = legMap['steps'];
                  print('steps tipo: ${steps.runtimeType}, es List: ${steps is List}');
                  if (steps != null && steps is List) {
                    print('Procesando ${steps.length} step(s) en leg $i...');
                    for (var j = 0; j < steps.length; j++) {
                      final step = steps[j];
                      if (step is! Map) {
                        print('Step $j en leg $i no es un Map, saltando...');
                        continue;
                      }
                      final stepMap = step as Map;
                      final polylineObj = stepMap['polyline'];
                      
                      if (polylineObj == null) {
                        print('Step $j en leg $i no tiene polyline');
                        continue;
                      }
                      
                      String? polylineString;
                      
                      // polyline puede ser un Map o directamente un String
                      if (polylineObj is Map) {
                        final polyline = polylineObj as Map;
                        final pointsObj = polyline['points'];
                        if (pointsObj != null && pointsObj is String) {
                          polylineString = pointsObj as String;
                        }
                      } else if (polylineObj is String) {
                        polylineString = polylineObj as String;
                      }
                      
                      if (polylineString != null && polylineString.isNotEmpty) {
                        print('Decodificando polyline del step $j (${polylineString.length} caracteres): ${polylineString.substring(0, polylineString.length > 50 ? 50 : polylineString.length)}...');
                        final stepPoints = _decodePolyline(polylineString, startLat, startLng, maxRadiusKm);
                        print('Decodificados ${stepPoints.length} puntos válidos del step $j (dentro de ${maxRadiusKm}km)');
                        if (stepPoints.isNotEmpty) {
                          print('Primer punto step $j: ${stepPoints.first.latitude}, ${stepPoints.first.longitude}');
                        }
                        // Filtrar puntos inválidos y agregar solo los válidos
                        for (final point in stepPoints) {
                          // Evitar duplicados consecutivos
                          if (allPoints.isEmpty || 
                              allPoints.last.latitude != point.latitude || 
                              allPoints.last.longitude != point.longitude) {
                            allPoints.add(point);
                          }
                        }
                      } else {
                        print('Step $j en leg $i no tiene polylineString válido');
                      }
                    }
                  } else {
                    print('Leg $i no tiene steps o steps no es una List');
                  }
                }
              } else {
                print('No hay legs o legs no es una List');
              }

              // Si no hay puntos, usar overview_polyline
              if (allPoints.isEmpty) {
                final overviewPolylineObj = route['overview_polyline'];
                if (overviewPolylineObj != null) {
                  String? polylineString;
                  
                  // overview_polyline puede ser un Map o directamente un String
                  if (overviewPolylineObj is Map) {
                    final overviewPolyline = overviewPolylineObj as Map;
                    final pointsObj = overviewPolyline['points'];
                    if (pointsObj != null && pointsObj is String) {
                      polylineString = pointsObj as String;
                    }
                  } else if (overviewPolylineObj is String) {
                    polylineString = overviewPolylineObj as String;
                  }
                  
                  if (polylineString != null && polylineString.isNotEmpty) {
                    final overviewPoints = _decodePolyline(polylineString, startLat, startLng, maxRadiusKm);
                    // Filtrar y agregar solo puntos válidos
                    for (final point in overviewPoints) {
                      if (allPoints.isEmpty || 
                          allPoints.last.latitude != point.latitude || 
                          allPoints.last.longitude != point.longitude) {
                        allPoints.add(point);
                      }
                    }
                  }
                }
              }
              
              // Limpiar puntos duplicados y puntos fuera de rango
              allPoints = _cleanRoutePoints(allPoints);
              
              // Debug: verificar que tenemos puntos válidos
              if (allPoints.isNotEmpty) {
                print('Ruta decodificada: ${allPoints.length} puntos');
                print('Primer punto: ${allPoints.first.latitude}, ${allPoints.first.longitude}');
                print('Último punto: ${allPoints.last.latitude}, ${allPoints.last.longitude}');
              }

              completer.complete(RouteResult(
                points: allPoints,
                totalDistance: totalDistance,
                totalDuration: totalDuration,
              ));
              } else {
                completer.complete(RouteResult(points: [], totalDistance: 0.0, totalDuration: 0));
              }
            } catch (e, stackTrace) {
              print('Error procesando respuesta de Directions: $e');
              print('Stack trace: $stackTrace');
              completer.complete(RouteResult(points: [], totalDistance: 0.0, totalDuration: 0));
            }
        } else {
          print('Error en Directions API: $status');
          if (result != null) {
            print('Result no es null pero status no es OK');
          }
          completer.complete(RouteResult(points: [], totalDistance: 0.0, totalDuration: 0));
        }
      });
        
      // Llamar a la función helper directamente
      // Guardar callback temporalmente en window para acceder desde eval
      js_util.setProperty(window, '_directionsCallback', callback);
      js_util.setProperty(window, '_directionsRequest', request);
      
      print('Llamando a getDirectionsRoute...');
      print('getDirectionsRoute disponible: ${js_util.hasProperty(window, 'getDirectionsRoute')}');
      
      // Llamar usando eval para evitar problemas con callMethod
      try {
        js.context.callMethod('eval', [
          '(function() { '
          '  console.log("Ejecutando getDirectionsRoute..."); '
          '  if (typeof window.getDirectionsRoute === "function") { '
          '    console.log("getDirectionsRoute es una función, llamando..."); '
          '    window.getDirectionsRoute(window._directionsRequest, window._directionsCallback); '
          '  } else { '
          '    console.error("getDirectionsRoute no es una función:", typeof window.getDirectionsRoute); '
          '    window._directionsCallback(null, "NOT_LOADED"); '
          '  } '
          '})()'
        ]);
      } catch (e) {
        print('Error al ejecutar eval: $e');
        completer.complete(RouteResult(points: [], totalDistance: 0.0, totalDuration: 0));
        return await completer.future;
      }

      return await completer.future;
    } catch (e, stackTrace) {
      print('Error en _getNavigationRouteWeb: $e');
      print('Stack trace: $stackTrace');
      return RouteResult(points: [], totalDistance: 0.0, totalDuration: 0);
    }
  }

  /// Método legacy mantenido para compatibilidad
  @Deprecated('Usar getNavigationRoute en su lugar')
  Future<List<LatLng>> getRoutePoints({
    required double startLat,
    required double startLng,
    required List<PostModel> posts,
  }) async {
    final result = await getNavigationRoute(
      startLat: startLat,
      startLng: startLng,
      posts: posts,
    );
    return result.points;
  }

  /// Decodifica un polyline de Google Maps usando el paquete google_polyline_algorithm
  /// Filtra puntos que estén fuera del radio especificado desde la ubicación del usuario
  List<LatLng> _decodePolyline(String encoded, double userLat, double userLng, double maxRadiusKm) {
    final points = <LatLng>[];
    if (encoded.isEmpty) {
      print('Polyline vacío');
      return points;
    }
    
    try {
      // Usar el paquete google_polyline_algorithm para decodificar correctamente
      final decodedPoints = decodePolyline(encoded);
      
      if (decodedPoints.isEmpty) {
        print('No se decodificaron puntos del polyline');
        return points;
      }
      
      int puntosFiltrados = 0;
      
      // Convertir los puntos decodificados a LatLng y filtrar por distancia
      for (final point in decodedPoints) {
        if (point.length < 2) continue;
        
        final decodedLat = point[0] as double;
        final decodedLng = point[1] as double;
        
        // Validar coordenadas básicas
        if (decodedLat >= -90 && decodedLat <= 90 && 
            decodedLng >= -180 && decodedLng <= 180 &&
            !decodedLat.isNaN && !decodedLng.isNaN &&
            !decodedLat.isInfinite && !decodedLng.isInfinite) {
          
          // Filtrar por distancia desde el usuario (máximo maxRadiusKm)
          final distance = Geolocator.distanceBetween(
            userLat,
            userLng,
            decodedLat,
            decodedLng,
          ) / 1000; // Convertir a km
          
          if (distance <= maxRadiusKm) {
            points.add(LatLng(decodedLat, decodedLng));
          } else {
            puntosFiltrados++;
            if (puntosFiltrados <= 3) {
              print('Punto filtrado (fuera de ${maxRadiusKm}km): lat=$decodedLat, lng=$decodedLng, distancia=${distance.toStringAsFixed(2)}km');
            }
          }
        } else {
          puntosFiltrados++;
          if (puntosFiltrados <= 3) {
            print('Punto inválido (coordenadas fuera de rango): lat=$decodedLat, lng=$decodedLng');
          }
        }
      }
      
      if (points.isEmpty && decodedPoints.isNotEmpty) {
        print('Advertencia: se decodificaron ${decodedPoints.length} puntos pero todos fueron filtrados ($puntosFiltrados fuera de rango)');
      } else if (puntosFiltrados > 0) {
        print('Filtrados $puntosFiltrados puntos fuera del rango de ${maxRadiusKm}km. Puntos válidos: ${points.length}');
      } else {
        print('Decodificados ${points.length} puntos válidos del polyline');
      }
    } catch (e, stackTrace) {
      print('Error decodificando polyline: $e');
      print('Stack trace: $stackTrace');
      print('Polyline: ${encoded.substring(0, encoded.length > 100 ? 100 : encoded.length)}...');
    }

    return points;
  }

  /// Valida que un LatLng sea válido
  bool _isValidLatLng(LatLng point) {
    return point.latitude >= -90 && point.latitude <= 90 &&
           point.longitude >= -180 && point.longitude <= 180 &&
           !point.latitude.isNaN && !point.longitude.isNaN &&
           !point.latitude.isInfinite && !point.longitude.isInfinite;
  }

  /// Limpia puntos de ruta: elimina duplicados y puntos inválidos
  List<LatLng> _cleanRoutePoints(List<LatLng> points) {
    if (points.isEmpty) return points;
    
    final cleaned = <LatLng>[];
    LatLng? lastPoint;
    
    for (final point in points) {
      if (!_isValidLatLng(point)) continue;
      
      // Eliminar duplicados consecutivos (con tolerancia de 0.0001 grados)
      if (lastPoint != null) {
        final latDiff = (point.latitude - lastPoint.latitude).abs();
        final lngDiff = (point.longitude - lastPoint.longitude).abs();
        if (latDiff < 0.0001 && lngDiff < 0.0001) {
          continue; // Punto duplicado, saltar
        }
      }
      
      cleaned.add(point);
      lastPoint = point;
    }
    
    return cleaned;
  }

  /// Calcula la distancia total de una ruta (en línea recta)
  /// Nota: Para distancia real de navegación, usar getNavigationRoute
  double calculateRouteDistance(List<PostModel> route, double startLat, double startLng) {
    if (route.isEmpty) return 0.0;

    double totalDistance = 0.0;
    double currentLat = startLat;
    double currentLng = startLng;

    for (final post in route) {
      totalDistance += Geolocator.distanceBetween(
        currentLat,
        currentLng,
        post.lat,
        post.lng,
      ) / 1000; // Convertir a km
      currentLat = post.lat;
      currentLng = post.lng;
    }

    // Agregar distancia de regreso al inicio
    totalDistance += Geolocator.distanceBetween(
      currentLat,
      currentLng,
      startLat,
      startLng,
    ) / 1000;

    return totalDistance;
  }
}

/// Resultado de una ruta de navegación
class RouteResult {
  final List<LatLng> points;
  final double totalDistance; // En kilómetros
  final int totalDuration; // En segundos

  RouteResult({
    required this.points,
    required this.totalDistance,
    required this.totalDuration,
  });
}
