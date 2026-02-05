import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../config/env_config.dart';
import 'image_compression_service.dart';

/// Acción a tomar después de la validación
enum ValidationAction {
  /// Bloquear: Contenido inapropiado o completamente no relacionado
  block,
  /// Pendiente: Requiere revisión manual (baja/media confianza)
  pending,
  /// Aprobar: Alta confianza de que es un fósil legítimo
  approve,
}

/// Resultado de la validación de una imagen
class ImageValidationResult {
  /// Acción a tomar con el hallazgo
  final ValidationAction action;
  /// Nivel de confianza (0.0 a 1.0)
  final double confidenceLevel;
  /// Razón del rechazo (solo si action == block)
  final String? rejectionReason;
  /// Mensaje informativo para el usuario
  final String? message;

  ImageValidationResult({
    required this.action,
    this.confidenceLevel = 0.0,
    this.rejectionReason,
    this.message,
  });
  
  /// Alias para compatibilidad: true si no está bloqueado
  bool get isValid => action != ValidationAction.block;
}

/// Servicio para interactuar con la API de Gemini
/// Usa el modelo Gemini 3 Flash
class GeminiService {
  // API Key de Gemini - Se configura via variables de entorno
  static String get _apiKey => EnvConfig.geminiApiKey;
  
  // Endpoint de la API de Gemini
  // Usamos gemini-3-flash-preview que es el modelo más reciente
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';
  
  // Servicio de compresión para optimizar imágenes antes de enviar
  final ImageCompressionService _compressionService = ImageCompressionService();
  
  /// Comprime una imagen para envío a Gemini (800x800, calidad 70)
  Future<Uint8List> _compressForAI(Uint8List imageBytes) async {
    try {
      final result = await _compressionService.compressImage(
        imageBytes,
        config: CompressionConfig.forAI,
      );
      print('Imagen comprimida para Gemini: ${ImageCompressionService.formatFileSize(result.originalSize)} → ${ImageCompressionService.formatFileSize(result.compressedSize)} (${result.reductionPercent.toStringAsFixed(0)}% reducción)');
      return result.bytes;
    } catch (e) {
      print('Error comprimiendo imagen para Gemini, usando original: $e');
      return imageBytes;
    }
  }
  
  /// Genera una descripción de una imagen usando Gemini 3 Flash
  /// 
  /// [imageBytes] - Los bytes de la imagen a analizar
  /// [imageMimeType] - El tipo MIME de la imagen (ej: 'image/jpeg', 'image/png')
  /// 
  /// Retorna la descripción generada o null si hay un error
  Future<String?> generateImageDescription(
    Uint8List imageBytes,
    String imageMimeType,
  ) async {
    try {
      // Comprimir imagen antes de enviar para mejorar velocidad
      final compressedBytes = await _compressForAI(imageBytes);
      
      // Convertir la imagen a base64
      final base64Image = base64Encode(compressedBytes);
      
      // Construir la URL con la API key
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      // Construir el request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': 'Actúa como un experto en paleontología urbana. Analiza el fósil en este material de construcción y genera una ficha técnica de máximo 250 caracteres. Usa este formato: [Taxón/Tipo] | [Periodo Geológico] | [Litología/Sustrato] | [Breve observación técnica]. Sé directo, preciso y usa terminología científica rigurosa.'
              },
              {
                'inline_data': {
                  'mime_type': imageMimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 512,
        }
      };
      
      // Hacer la petición HTTP
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al generar descripción');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Extraer el texto de la respuesta
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = responseData['candidates'][0]['content']['parts'][0]['text'] as String;
          return text.trim();
        } else {
          print('Error: Respuesta de Gemini sin contenido válido');
          print('Response: ${response.body}');
          return null;
        }
      } else {
        print('Error en la API de Gemini: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Si es un error de API key, dar un mensaje más claro
        if (response.statusCode == 400 || response.statusCode == 403) {
          throw Exception('Error de autenticación. Verifica que la API key de Gemini esté configurada correctamente.');
        }
        
        // Detectar errores de sobrecarga
        if (response.statusCode == 429 || response.statusCode == 503) {
          throw http.ClientException(
            'API sobrecargada',
            Uri.parse(_baseUrl),
          );
        }
        
        return null;
      }
    } catch (e) {
      developer.log(
        'Error generando descripción con Gemini',
        name: 'GeminiService',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }
  
  /// Determina el tipo MIME de una imagen basándose en sus bytes
  String _getImageMimeType(Uint8List imageBytes) {
    // Verificar el header de la imagen para determinar el tipo
    if (imageBytes.length >= 2) {
      // JPEG: FF D8
      if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      // PNG: 89 50 4E 47
      if (imageBytes.length >= 4 &&
          imageBytes[0] == 0x89 &&
          imageBytes[1] == 0x50 &&
          imageBytes[2] == 0x4E &&
          imageBytes[3] == 0x47) {
        return 'image/png';
      }
      // WebP: RIFF...WEBP
      if (imageBytes.length >= 12 &&
          imageBytes[0] == 0x52 &&
          imageBytes[1] == 0x49 &&
          imageBytes[2] == 0x46 &&
          imageBytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    // Por defecto, asumir JPEG
    return 'image/jpeg';
  }
  
  /// Genera una descripción de una imagen (versión simplificada que detecta el MIME type automáticamente)
  Future<String?> generateImageDescriptionAuto(Uint8List imageBytes) async {
    final mimeType = _getImageMimeType(imageBytes);
    return await generateImageDescription(imageBytes, mimeType);
  }

  /// Valida si una imagen es apropiada y está relacionada con fósiles
  /// 
  /// [imageBytes] - Los bytes de la imagen a validar
  /// 
  /// Retorna un ImageValidationResult con:
  /// - action: block (rechazar), pending (revisión), approve (publicar)
  /// - confidenceLevel: nivel de confianza (0.0 a 1.0)
  Future<ImageValidationResult> validateImage(
    Uint8List imageBytes,
  ) async {
    try {
      // Comprimir imagen antes de enviar para mejorar velocidad
      final compressedBytes = await _compressForAI(imageBytes);
      
      final mimeType = _getImageMimeType(compressedBytes);
      final base64Image = base64Encode(compressedBytes);
      
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      // Prompt para validar la imagen con sistema de confianza
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''Analiza esta imagen y clasifícala según los siguientes criterios. Responde SOLO con JSON:

{
  "action": "block" | "pending" | "approve",
  "confidence": 0.0 a 1.0,
  "reason": "explicación breve"
}

CRITERIOS:

1. action = "block" (BLOQUEAR - la imagen NO se sube):
   - Contenido sexual, pornográfico o sugerente
   - Contenido violento, sangriento o perturbador
   - Contenido discriminatorio, ofensivo o de odio
   - Imagen completamente NO relacionada con geología/fósiles/paleontología (ej: selfies, comida, animales vivos, memes, capturas de pantalla)

2. action = "pending" (PENDIENTE - requiere revisión humana):
   - La imagen muestra rocas, minerales o materiales que PODRÍAN contener fósiles pero no es claro
   - La imagen está relacionada con geología pero el fósil no es evidente
   - Baja calidad de imagen que dificulta la identificación
   - Confianza < 0.7 de que sea un fósil real

3. action = "approve" (APROBAR - se publica directamente):
   - Claramente muestra un fósil identificable (amonite, trilobite, huella, hueso, etc.)
   - Materiales de construcción con fósiles visibles
   - Rocas sedimentarias con restos fósiles evidentes
   - Confianza >= 0.7 de que es un hallazgo paleontológico legítimo

IMPORTANTE:
- Sé PERMISIVO con imágenes de rocas/materiales geológicos aunque no veas un fósil claro
- Solo usa "block" para contenido claramente inapropiado o completamente irrelevante
- Ante la duda entre pending y approve, elige pending
- confidence debe reflejar tu certeza de que la imagen muestra un fósil real

Responde SOLO con el JSON, sin texto adicional.'''
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'topK': 1,
          'topP': 0.8,
          'maxOutputTokens': 300,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_LOW_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout al validar imagen');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Verificar si Gemini bloqueó la imagen por contenido inapropiado
        if (responseData['promptFeedback'] != null &&
            responseData['promptFeedback']['blockReason'] != null) {
          return ImageValidationResult(
            action: ValidationAction.block,
            confidenceLevel: 1.0,
            rejectionReason: 'La imagen contiene contenido inapropiado que no está permitido.',
          );
        }
        
        // Verificar si la respuesta fue bloqueada por seguridad
        if (responseData['candidates'] == null || 
            responseData['candidates'].isEmpty ||
            responseData['candidates'][0]['finishReason'] == 'SAFETY') {
          return ImageValidationResult(
            action: ValidationAction.block,
            confidenceLevel: 1.0,
            rejectionReason: 'La imagen contiene contenido inapropiado que no está permitido.',
          );
        }
        
        // Extraer el texto de la respuesta
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = responseData['candidates'][0]['content']['parts'][0]['text'] as String;
          final cleanedText = text.trim();
          
          // Intentar parsear el JSON de la respuesta
          try {
            // Limpiar el texto para extraer solo el JSON
            String jsonText = cleanedText;
            final jsonStart = jsonText.indexOf('{');
            final jsonEnd = jsonText.lastIndexOf('}');
            if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
              jsonText = jsonText.substring(jsonStart, jsonEnd + 1);
            }
            
            final validationData = jsonDecode(jsonText) as Map<String, dynamic>;
            final actionStr = validationData['action'] as String? ?? 'pending';
            final confidence = (validationData['confidence'] as num?)?.toDouble() ?? 0.5;
            final reason = validationData['reason'] as String?;
            
            // Convertir string a enum
            ValidationAction action;
            String? message;
            
            switch (actionStr.toLowerCase()) {
              case 'block':
                action = ValidationAction.block;
                break;
              case 'approve':
                action = ValidationAction.approve;
                message = 'Hallazgo validado automáticamente';
                break;
              case 'pending':
              default:
                action = ValidationAction.pending;
                message = 'Hallazgo pendiente de revisión';
                break;
            }
            
            return ImageValidationResult(
              action: action,
              confidenceLevel: confidence,
              rejectionReason: action == ValidationAction.block ? reason : null,
              message: message ?? reason,
            );
          } catch (e) {
            // Si no se puede parsear el JSON, analizar el texto directamente
            print('Error parseando respuesta de validación: $e');
            print('Respuesta recibida: $cleanedText');
            
            final lowerText = cleanedText.toLowerCase();
            
            // Detectar bloqueo explícito
            if (lowerText.contains('"action"') && lowerText.contains('"block"')) {
              return ImageValidationResult(
                action: ValidationAction.block,
                confidenceLevel: 0.8,
                rejectionReason: 'La imagen no cumple con los criterios de la plataforma.',
              );
            }
            
            // Detectar aprobación explícita
            if (lowerText.contains('"action"') && lowerText.contains('"approve"')) {
              return ImageValidationResult(
                action: ValidationAction.approve,
                confidenceLevel: 0.7,
                message: 'Hallazgo validado automáticamente',
              );
            }
            
            // Por defecto, dejar como pendiente (no bloquear)
            return ImageValidationResult(
              action: ValidationAction.pending,
              confidenceLevel: 0.5,
              message: 'Hallazgo pendiente de revisión',
            );
          }
        } else {
          // Si no hay respuesta válida, dejar como pendiente
          return ImageValidationResult(
            action: ValidationAction.pending,
            confidenceLevel: 0.5,
            message: 'No se pudo analizar la imagen. Pendiente de revisión manual.',
          );
        }
      } else {
        print('Error en la API de Gemini: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Si es un error de API key, lanzar excepción
        if (response.statusCode == 400 || response.statusCode == 403) {
          throw Exception('Error de autenticación. Verifica que la API key de Gemini esté configurada correctamente.');
        }
        
        // En caso de error de API, dejar como pendiente (no bloquear al usuario)
        return ImageValidationResult(
          action: ValidationAction.pending,
          confidenceLevel: 0.5,
          message: 'Error temporal en validación. Pendiente de revisión.',
        );
      }
    } catch (e) {
      print('Error validando imagen con Gemini: $e');
      // En caso de error, dejar como pendiente (no bloquear al usuario)
      return ImageValidationResult(
        action: ValidationAction.pending,
        confidenceLevel: 0.5,
        message: 'Error en validación. Pendiente de revisión.',
      );
    }
  }
}
