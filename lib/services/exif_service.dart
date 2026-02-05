import 'dart:typed_data';
import 'package:exif/exif.dart';

class ExifService {
  /// Extrae las coordenadas GPS de los metadatos EXIF de una imagen
  /// Retorna null si la imagen no tiene metadatos GPS
  Future<ExifCoordinates?> getCoordinatesFromImage(Uint8List imageBytes) async {
    try {
      final tags = await readExifFromBytes(imageBytes);

      if (tags.isEmpty) {
        print('La imagen no tiene metadatos EXIF');
        return null;
      }

      // Verificar si existen las etiquetas GPS
      final gpsLatitude = tags['GPS GPSLatitude'];
      final gpsLatitudeRef = tags['GPS GPSLatitudeRef'];
      final gpsLongitude = tags['GPS GPSLongitude'];
      final gpsLongitudeRef = tags['GPS GPSLongitudeRef'];

      if (gpsLatitude == null || gpsLongitude == null) {
        print('La imagen no tiene coordenadas GPS en los metadatos EXIF');
        return null;
      }

      // Convertir la latitud
      final lat = _convertToDecimalDegrees(
        gpsLatitude.values,
        gpsLatitudeRef?.printable ?? 'N',
      );

      // Convertir la longitud
      final lng = _convertToDecimalDegrees(
        gpsLongitude.values,
        gpsLongitudeRef?.printable ?? 'E',
      );

      if (lat == null || lng == null) {
        print('Error convirtiendo coordenadas GPS');
        return null;
      }

      print('Coordenadas GPS extraídas: lat=$lat, lng=$lng');

      return ExifCoordinates(lat: lat, lng: lng);
    } catch (e) {
      print('Error leyendo metadatos EXIF: $e');
      return null;
    }
  }

  /// Convierte coordenadas en formato de grados/minutos/segundos a grados decimales
  double? _convertToDecimalDegrees(IfdValues? values, String ref) {
    if (values == null) return null;

    try {
      final valuesList = values.toList();
      if (valuesList.length < 3) return null;

      // Los valores están en formato [grados, minutos, segundos]
      // Cada valor es un Ratio (numerador/denominador)
      final degrees = _ratioToDouble(valuesList[0]);
      final minutes = _ratioToDouble(valuesList[1]);
      final seconds = _ratioToDouble(valuesList[2]);

      if (degrees == null || minutes == null || seconds == null) {
        return null;
      }

      // Convertir a grados decimales
      double decimal = degrees + (minutes / 60) + (seconds / 3600);

      // Si es Sur o Oeste, hacer negativo
      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      print('Error convirtiendo a grados decimales: $e');
      return null;
    }
  }

  /// Convierte un Ratio de EXIF a double
  double? _ratioToDouble(dynamic value) {
    if (value == null) return null;

    try {
      if (value is Ratio) {
        return value.numerator / value.denominator;
      } else if (value is int) {
        return value.toDouble();
      } else if (value is double) {
        return value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Coordenadas extraídas de los metadatos EXIF
class ExifCoordinates {
  final double lat;
  final double lng;

  ExifCoordinates({
    required this.lat,
    required this.lng,
  });
}
