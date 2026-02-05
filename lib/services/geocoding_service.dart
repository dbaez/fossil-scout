import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:async';
import '../config/env_config.dart';

class GeocodingService {
  // API key configurada via variables de entorno
  static String get _apiKey => EnvConfig.googleMapsApiKey;
  static const String _geocodingApiUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Convierte coordenadas a una dirección legible (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    if (kIsWeb) {
      return await _getAddressFromCoordinatesWeb(lat, lng);
    }

    try {
      final url = Uri.parse(
        '$_geocodingApiUrl?latlng=$lat,$lng&key=$_apiKey&language=es',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            // Obtener la dirección formateada del primer resultado
            final firstResult = results[0] as Map<String, dynamic>;
            return firstResult['formatted_address'] as String?;
          }
        }
      }
    } catch (e) {
      print('Error en reverse geocoding: $e');
    }

    return null;
  }

  /// Versión web usando JavaScript interop para evitar CORS
  Future<String?> _getAddressFromCoordinatesWeb(double lat, double lng) async {
    try {
      // Esperar a que Google Maps esté disponible
      int attempts = 0;
      while (attempts < 20) {
        if (js.context.hasProperty('google')) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!js.context.hasProperty('google')) {
        print('Google Maps JavaScript API no está disponible');
        return null;
      }

      final completer = Completer<String?>();

      // Crear el callback para la respuesta
      final callback = js.allowInterop((results, status) {
        print('Callback de Geocoder recibido. Status: $status');
        if (status == 'OK' && results != null) {
          try {
            final dartResults = js_util.dartify(results);
            if (dartResults is List && dartResults.isNotEmpty) {
              final firstResult = dartResults[0] as Map;
              final formattedAddress = firstResult['formatted_address'] as String?;
              completer.complete(formattedAddress);
              return;
            }
          } catch (e) {
            print('Error procesando respuesta de Geocoder: $e');
          }
        }
        completer.complete(null);
      });

      // Guardar callback en window
      final window = js.context['window'];
      js_util.setProperty(window, '_geocoderCallback', callback);

      // Ejecutar reverse geocoding usando la API de JavaScript
      js.context.callMethod('eval', [
        '''
        (function() {
          var geocoder = new google.maps.Geocoder();
          var latlng = { lat: $lat, lng: $lng };
          geocoder.geocode({ location: latlng, language: 'es' }, window._geocoderCallback);
        })()
        '''
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      print('Error en reverse geocoding web: $e');
      return null;
    }
  }

  /// Convierte una dirección a coordenadas (forward geocoding)
  Future<GeocodingResult?> getCoordinatesFromAddress(String address) async {
    if (kIsWeb) {
      return await _getCoordinatesFromAddressWeb(address);
    }

    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        '$_geocodingApiUrl?address=$encodedAddress&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' && data['results'] != null) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final firstResult = results[0] as Map<String, dynamic>;
            final geometry = firstResult['geometry'] as Map<String, dynamic>;
            final location = geometry['location'] as Map<String, dynamic>;

            return GeocodingResult(
              lat: (location['lat'] as num).toDouble(),
              lng: (location['lng'] as num).toDouble(),
              formattedAddress: firstResult['formatted_address'] as String?,
            );
          }
        }
      }
    } catch (e) {
      print('Error en forward geocoding: $e');
    }

    return null;
  }

  /// Versión web usando JavaScript interop para evitar CORS
  Future<GeocodingResult?> _getCoordinatesFromAddressWeb(String address) async {
    try {
      // Esperar a que Google Maps esté disponible
      int attempts = 0;
      while (attempts < 20) {
        if (js.context.hasProperty('google')) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!js.context.hasProperty('google')) {
        print('Google Maps JavaScript API no está disponible');
        return null;
      }

      final completer = Completer<GeocodingResult?>();

      // Crear el callback para la respuesta
      final callback = js.allowInterop((results, status) {
        print('Callback de Geocoder (forward) recibido. Status: $status');
        if (status == 'OK' && results != null) {
          try {
            final dartResults = js_util.dartify(results);
            if (dartResults is List && dartResults.isNotEmpty) {
              final firstResult = dartResults[0] as Map;
              final geometry = firstResult['geometry'] as Map;
              final location = geometry['location'] as Map;

              // Google Maps JS API devuelve funciones lat() y lng()
              // pero al hacer dartify se convierten en valores directos
              double? lat;
              double? lng;

              if (location['lat'] is num) {
                lat = (location['lat'] as num).toDouble();
              }
              if (location['lng'] is num) {
                lng = (location['lng'] as num).toDouble();
              }

              if (lat != null && lng != null) {
                completer.complete(GeocodingResult(
                  lat: lat,
                  lng: lng,
                  formattedAddress: firstResult['formatted_address'] as String?,
                ));
                return;
              }
            }
          } catch (e) {
            print('Error procesando respuesta de Geocoder (forward): $e');
          }
        }
        completer.complete(null);
      });

      // Escapar comillas en la dirección
      final escapedAddress = address.replaceAll("'", "\\'").replaceAll('"', '\\"');

      // Guardar callback en window
      final window = js.context['window'];
      js_util.setProperty(window, '_geocoderForwardCallback', callback);

      // Ejecutar forward geocoding usando la API de JavaScript
      js.context.callMethod('eval', [
        '''
        (function() {
          var geocoder = new google.maps.Geocoder();
          geocoder.geocode({ address: "$escapedAddress" }, window._geocoderForwardCallback);
        })()
        '''
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (e) {
      print('Error en forward geocoding web: $e');
      return null;
    }
  }
}

/// Resultado de forward geocoding
class GeocodingResult {
  final double lat;
  final double lng;
  final String? formattedAddress;

  GeocodingResult({
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });
}
