import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Configuración de compresión de imágenes
class CompressionConfig {
  /// Ancho máximo de la imagen (altura se ajusta proporcionalmente)
  final int maxWidth;
  
  /// Alto máximo de la imagen (ancho se ajusta proporcionalmente)
  final int maxHeight;
  
  /// Calidad JPEG (0-100). 85 es un buen balance calidad/tamaño
  final int quality;
  
  /// Tamaño máximo del archivo en bytes (0 = sin límite)
  final int maxFileSize;

  const CompressionConfig({
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.quality = 85,
    this.maxFileSize = 0,
  });
  
  /// Configuración para imágenes de alta calidad (posts principales)
  static const CompressionConfig highQuality = CompressionConfig(
    maxWidth: 1920,
    maxHeight: 1920,
    quality: 85,
  );
  
  /// Configuración para imágenes de calidad media
  static const CompressionConfig mediumQuality = CompressionConfig(
    maxWidth: 1280,
    maxHeight: 1280,
    quality: 75,
  );
  
  /// Configuración para miniaturas
  static const CompressionConfig thumbnail = CompressionConfig(
    maxWidth: 400,
    maxHeight: 400,
    quality: 70,
  );
  
  /// Configuración para envío a APIs de IA (Gemini, etc.)
  /// Optimizada para velocidad: imágenes pequeñas pero con suficiente detalle
  static const CompressionConfig forAI = CompressionConfig(
    maxWidth: 800,
    maxHeight: 800,
    quality: 70,
  );
}

/// Resultado de la compresión
class CompressionResult {
  /// Bytes de la imagen comprimida
  final Uint8List bytes;
  
  /// Tamaño original en bytes
  final int originalSize;
  
  /// Tamaño comprimido en bytes
  final int compressedSize;
  
  /// Ancho original
  final int originalWidth;
  
  /// Alto original
  final int originalHeight;
  
  /// Ancho final
  final int finalWidth;
  
  /// Alto final
  final int finalHeight;
  
  /// Porcentaje de reducción
  double get reductionPercent => 
      originalSize > 0 ? ((originalSize - compressedSize) / originalSize * 100) : 0;
  
  /// Ratio de compresión (ej: 0.3 = 30% del original)
  double get compressionRatio =>
      originalSize > 0 ? compressedSize / originalSize : 1;

  CompressionResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    required this.originalWidth,
    required this.originalHeight,
    required this.finalWidth,
    required this.finalHeight,
  });
  
  @override
  String toString() {
    final originalKB = (originalSize / 1024).toStringAsFixed(1);
    final compressedKB = (compressedSize / 1024).toStringAsFixed(1);
    return 'Compresión: ${originalKB}KB → ${compressedKB}KB '
           '(${reductionPercent.toStringAsFixed(1)}% reducción), '
           '${originalWidth}x$originalHeight → ${finalWidth}x$finalHeight';
  }
}

/// Servicio para comprimir imágenes antes de subirlas
class ImageCompressionService {
  
  /// Comprime una imagen según la configuración especificada
  /// 
  /// [imageBytes] - Bytes de la imagen original
  /// [config] - Configuración de compresión (opcional, usa highQuality por defecto)
  /// 
  /// Retorna CompressionResult con la imagen comprimida y estadísticas
  Future<CompressionResult> compressImage(
    Uint8List imageBytes, {
    CompressionConfig config = CompressionConfig.highQuality,
  }) async {
    final originalSize = imageBytes.length;
    
    // Decodificar la imagen
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      // Si no se puede decodificar, retornar original
      return CompressionResult(
        bytes: imageBytes,
        originalSize: originalSize,
        compressedSize: originalSize,
        originalWidth: 0,
        originalHeight: 0,
        finalWidth: 0,
        finalHeight: 0,
      );
    }
    
    final originalWidth = image.width;
    final originalHeight = image.height;
    
    // Redimensionar si es necesario
    img.Image resizedImage = image;
    if (image.width > config.maxWidth || image.height > config.maxHeight) {
      resizedImage = img.copyResize(
        image,
        width: image.width > config.maxWidth ? config.maxWidth : null,
        height: image.height > config.maxHeight ? config.maxHeight : null,
        maintainAspect: true,
        interpolation: img.Interpolation.linear,
      );
    }
    
    // Codificar como JPEG con la calidad especificada
    Uint8List compressedBytes = Uint8List.fromList(
      img.encodeJpg(resizedImage, quality: config.quality),
    );
    
    // Si hay límite de tamaño y lo excede, reducir calidad progresivamente
    if (config.maxFileSize > 0 && compressedBytes.length > config.maxFileSize) {
      int currentQuality = config.quality;
      while (compressedBytes.length > config.maxFileSize && currentQuality > 20) {
        currentQuality -= 10;
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: currentQuality),
        );
      }
    }
    
    // Si la imagen comprimida es más grande que la original (raro pero posible),
    // devolver la original si es JPEG o la comprimida si es otro formato
    if (compressedBytes.length >= originalSize && _isJpeg(imageBytes)) {
      // La original ya está optimizada
      return CompressionResult(
        bytes: imageBytes,
        originalSize: originalSize,
        compressedSize: originalSize,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        finalWidth: originalWidth,
        finalHeight: originalHeight,
      );
    }
    
    return CompressionResult(
      bytes: compressedBytes,
      originalSize: originalSize,
      compressedSize: compressedBytes.length,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      finalWidth: resizedImage.width,
      finalHeight: resizedImage.height,
    );
  }
  
  /// Comprime múltiples imágenes en paralelo
  Future<List<CompressionResult>> compressImages(
    List<Uint8List> images, {
    CompressionConfig config = CompressionConfig.highQuality,
  }) async {
    final futures = images.map((bytes) => compressImage(bytes, config: config));
    return Future.wait(futures);
  }
  
  /// Verifica si los bytes corresponden a una imagen JPEG
  bool _isJpeg(Uint8List bytes) {
    if (bytes.length < 2) return false;
    // JPEG magic number: FF D8
    return bytes[0] == 0xFF && bytes[1] == 0xD8;
  }
  
  /// Estima el tamaño comprimido sin comprimir realmente
  /// Útil para mostrar al usuario una estimación antes de subir
  int estimateCompressedSize(int originalSize, {int quality = 85}) {
    // Estimación basada en ratios típicos de compresión JPEG
    // Estos valores son aproximados y varían según el contenido de la imagen
    if (quality >= 90) return (originalSize * 0.6).round();
    if (quality >= 80) return (originalSize * 0.4).round();
    if (quality >= 70) return (originalSize * 0.3).round();
    if (quality >= 60) return (originalSize * 0.25).round();
    return (originalSize * 0.2).round();
  }
  
  /// Formatea un tamaño en bytes a una cadena legible (KB, MB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
