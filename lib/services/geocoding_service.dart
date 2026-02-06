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
  static const String _placesAutocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';

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

  /// Obtiene sugerencias de autocompletado para una dirección
  Future<List<PlaceSuggestion>> getAddressSuggestions(String input) async {
    if (input.trim().length < 3) return [];
    
    if (kIsWeb) {
      return await _getAddressSuggestionsWeb(input);
    }

    try {
      final encodedInput = Uri.encodeComponent(input);
      final url = Uri.parse(
        '$_placesAutocompleteUrl?input=$encodedInput&types=address&language=es&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          return predictions.map((p) => PlaceSuggestion(
            placeId: p['place_id'] as String,
            description: p['description'] as String,
            mainText: p['structured_formatting']?['main_text'] as String? ?? '',
            secondaryText: p['structured_formatting']?['secondary_text'] as String? ?? '',
          )).toList();
        }
      }
    } catch (e) {
      print('Error en places autocomplete: $e');
    }

    return [];
  }
  
  /// Versión web de autocompletado usando JavaScript
  Future<List<PlaceSuggestion>> _getAddressSuggestionsWeb(String input) async {
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
        return [];
      }

      final completer = Completer<List<PlaceSuggestion>>();

      // Crear el callback para la respuesta
      final callback = js.allowInterop((predictions, status) {
        if (status == 'OK' && predictions != null) {
          try {
            final dartPredictions = js_util.dartify(predictions);
            if (dartPredictions is List) {
              final suggestions = dartPredictions.map((p) {
                final prediction = p as Map;
                final structured = prediction['structured_formatting'] as Map?;
                return PlaceSuggestion(
                  placeId: prediction['place_id'] as String? ?? '',
                  description: prediction['description'] as String? ?? '',
                  mainText: structured?['main_text'] as String? ?? '',
                  secondaryText: structured?['secondary_text'] as String? ?? '',
                );
              }).toList();
              completer.complete(suggestions);
              return;
            }
          } catch (e) {
            print('Error procesando sugerencias: $e');
          }
        }
        completer.complete([]);
      });

      final escapedInput = input.replaceAll("'", "\\'").replaceAll('"', '\\"');
      
      final window = js.context['window'];
      js_util.setProperty(window, '_autocompleteCallback', callback);

      js.context.callMethod('eval', [
        '''
        (function() {
          var service = new google.maps.places.AutocompleteService();
          service.getPlacePredictions({
            input: "$escapedInput",
            types: ["address"],
            language: "es"
          }, window._autocompleteCallback);
        })()
        '''
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
    } catch (e) {
      print('Error en autocomplete web: $e');
      return [];
    }
  }
  
  /// Obtiene los detalles de un lugar (coordenadas) desde su place_id
  Future<GeocodingResult?> getPlaceDetails(String placeId) async {
    if (kIsWeb) {
      return await _getPlaceDetailsWeb(placeId);
    }

    try {
      final url = Uri.parse(
        '$_placeDetailsUrl?place_id=$placeId&fields=geometry,formatted_address&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          final geometry = result['geometry'] as Map<String, dynamic>;
          final location = geometry['location'] as Map<String, dynamic>;

          return GeocodingResult(
            lat: (location['lat'] as num).toDouble(),
            lng: (location['lng'] as num).toDouble(),
            formattedAddress: result['formatted_address'] as String?,
          );
        }
      }
    } catch (e) {
      print('Error obteniendo detalles del lugar: $e');
    }

    return null;
  }
  
  /// Versión web de place details
  Future<GeocodingResult?> _getPlaceDetailsWeb(String placeId) async {
    try {
      int attempts = 0;
      while (attempts < 20) {
        if (js.context.hasProperty('google')) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!js.context.hasProperty('google')) {
        return null;
      }

      final completer = Completer<GeocodingResult?>();

      final callback = js.allowInterop((place, status) {
        if (status == 'OK' && place != null) {
          try {
            final dartPlace = js_util.dartify(place) as Map;
            final geometry = dartPlace['geometry'] as Map;
            final location = geometry['location'] as Map;

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
                formattedAddress: dartPlace['formatted_address'] as String?,
              ));
              return;
            }
          } catch (e) {
            print('Error procesando place details: $e');
          }
        }
        completer.complete(null);
      });

      final window = js.context['window'];
      js_util.setProperty(window, '_placeDetailsCallback', callback);

      js.context.callMethod('eval', [
        '''
        (function() {
          var service = new google.maps.places.PlacesService(document.createElement('div'));
          service.getDetails({
            placeId: "$placeId",
            fields: ["geometry", "formatted_address"]
          }, window._placeDetailsCallback);
        })()
        '''
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      print('Error en place details web: $e');
      return null;
    }
  }
}

/// Sugerencia de lugar para autocompletado
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
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
