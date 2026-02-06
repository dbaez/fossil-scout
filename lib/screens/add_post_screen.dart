import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/gemini_service.dart';
import '../services/geocoding_service.dart';
import '../services/exif_service.dart';
import '../services/image_compression_service.dart';
import '../models/post_model.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Origen de las coordenadas del post
enum CoordinateSource {
  none,       // Sin coordenadas
  exif,       // Desde metadatos EXIF de la imagen
  manual,     // Desde dirección manual del usuario
  device,     // Desde ubicación del dispositivo (fallback)
}

class AddPostScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const AddPostScreen({
    super.key,
    this.onPostCreated,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _rockTypeController = TextEditingController();
  
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final GeocodingService _geocodingService = GeocodingService();
  final ExifService _exifService = ExifService();
  final ImageCompressionService _compressionService = ImageCompressionService();

  List<XFile> _selectedImages = [];
  
  // Coordenadas (transparentes para el usuario)
  double? _latitude;
  double? _longitude;
  
  // Origen de las coordenadas
  CoordinateSource _coordinateSource = CoordinateSource.none;
  
  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isGeneratingDescription = false;
  bool _isValidatingImages = false;
  bool _isGettingAddress = false;
  
  // Si se necesita dirección manual (la foto no tiene GPS)
  bool _needsManualAddress = false;

  @override
  void initState() {
    super.initState();
    // Ya no obtenemos ubicación automáticamente al iniciar
    // Las coordenadas se obtienen de las imágenes o de la dirección manual
  }

  /// Obtiene la ubicación del dispositivo (fallback si la imagen no tiene GPS)
  Future<void> _getDeviceLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _coordinateSource = CoordinateSource.device;
          _isGettingLocation = false;
        });
        
        // Auto-completar dirección desde la ubicación del dispositivo
        await _getAddressFromCoordinates();
      } else {
        setState(() => _isGettingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se necesita permiso de ubicación'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e')),
        );
      }
    }
  }
  
  /// Extrae coordenadas GPS de los metadatos EXIF de la primera imagen
  Future<void> _extractCoordinatesFromImage(XFile image) async {
    try {
      final imageBytes = await image.readAsBytes();
      final exifCoords = await _exifService.getCoordinatesFromImage(imageBytes);
      
      if (exifCoords != null) {
        setState(() {
          _latitude = exifCoords.lat;
          _longitude = exifCoords.lng;
          _coordinateSource = CoordinateSource.exif;
          _needsManualAddress = false;
        });
        
        // Auto-completar dirección desde las coordenadas EXIF
        await _getAddressFromCoordinates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.locationExtractedFromPhoto),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // La imagen no tiene GPS, el usuario debe ingresar dirección manualmente
        setState(() {
          _needsManualAddress = true;
          _coordinateSource = CoordinateSource.none;
          _latitude = null;
          _longitude = null;
          _addressController.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noGpsInPhoto),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error extrayendo coordenadas de imagen: $e');
      setState(() {
        _needsManualAddress = true;
      });
    }
  }
  
  /// Obtiene la dirección desde las coordenadas actuales (reverse geocoding)
  Future<void> _getAddressFromCoordinates() async {
    if (_latitude == null || _longitude == null) return;
    
    setState(() => _isGettingAddress = true);
    
    try {
      final address = await _geocodingService.getAddressFromCoordinates(
        _latitude!,
        _longitude!,
      );
      
      if (address != null && mounted) {
        setState(() {
          _addressController.text = address;
          _isGettingAddress = false;
        });
      } else {
        setState(() => _isGettingAddress = false);
      }
    } catch (e) {
      print('Error obteniendo dirección: $e');
      setState(() => _isGettingAddress = false);
    }
  }
  
  /// Obtiene coordenadas desde una dirección (forward geocoding)
  Future<bool> _getCoordinatesFromAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return false;
    
    setState(() => _isGettingAddress = true);
    
    try {
      final result = await _geocodingService.getCoordinatesFromAddress(address);
      
      if (result != null && mounted) {
        setState(() {
          _latitude = result.lat;
          _longitude = result.lng;
          _coordinateSource = CoordinateSource.manual;
          _isGettingAddress = false;
          // Actualizar con la dirección formateada de Google
          if (result.formattedAddress != null) {
            _addressController.text = result.formattedAddress!;
          }
        });
        return true;
      } else {
        setState(() => _isGettingAddress = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.addressNotFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      print('Error obteniendo coordenadas de dirección: $e');
      setState(() => _isGettingAddress = false);
      return false;
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        
        // Extraer coordenadas de la primera imagen
        await _extractCoordinatesFromImage(images.first);
        
        // Generar descripción automáticamente con la primera imagen
        await _generateDescriptionFromFirstImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seleccionando imágenes: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final isFirstImage = _selectedImages.isEmpty;
        setState(() {
          _selectedImages.add(image);
        });
        
        // Si es la primera imagen, extraer coordenadas
        if (isFirstImage) {
          await _extractCoordinatesFromImage(image);
        }
        
        // Generar descripción automáticamente con la nueva imagen
        await _generateDescriptionFromFirstImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error tomando foto: $e')),
        );
      }
    }
  }

  /// Genera una descripción automática usando Gemini de la primera imagen seleccionada
  Future<void> _generateDescriptionFromFirstImage() async {
    if (_selectedImages.isEmpty) return;
    
    // Solo generar si el campo de descripción está vacío
    if (_descriptionController.text.trim().isNotEmpty) {
      // Preguntar al usuario si quiere reemplazar la descripción existente
      final shouldReplace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generar nueva descripción'),
          content: const Text(
            'Ya existe una descripción. ¿Deseas reemplazarla con una descripción '
            'generada automáticamente por IA?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reemplazar'),
            ),
          ],
        ),
      );
      
      if (shouldReplace != true) return;
    }
    
    setState(() {
      _isGeneratingDescription = true;
    });
    
    try {
      // Leer la primera imagen
      final firstImage = _selectedImages.first;
      final imageBytes = await firstImage.readAsBytes();
      
      // Generar descripción y material con Gemini
      final result = await _geminiService.generateDescriptionWithMaterial(imageBytes);
      
      if (result != null && mounted) {
        setState(() {
          _descriptionController.text = result.description;
          // También completar el tipo de material si viene
          if (result.material != null && result.material!.isNotEmpty) {
            _rockTypeController.text = result.material!;
          }
          _isGeneratingDescription = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Descripción y material generados automáticamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isGeneratingDescription = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo generar la descripción automáticamente'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isGeneratingDescription = false;
      });
      
      // Log del error
      developer.log(
        'Error generando descripción con IA',
        name: 'AddPostScreen',
        error: e,
        stackTrace: StackTrace.current,
      );
      
      if (mounted) {
        String errorMessage;
        Color backgroundColor;
        
        // Detectar errores de sobrecarga de la API
        if (e is http.ClientException || 
            (e.toString().contains('429') || 
             e.toString().contains('503') || 
             e.toString().contains('overload') ||
             e.toString().contains('quota') ||
             e.toString().contains('rate limit'))) {
          errorMessage = 'El servicio de IA está sobrecargado en este momento. Por favor, intenta de nuevo en unos instantes.';
          backgroundColor = Colors.orange;
        } else if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
          errorMessage = 'La solicitud tardó demasiado. Por favor, verifica tu conexión e intenta de nuevo.';
          backgroundColor = Colors.orange;
        } else {
          errorMessage = 'No se pudo generar la descripción automáticamente. Puedes escribirla manualmente.';
          backgroundColor = Colors.orange;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.imageRequired)),
      );
      return;
    }
    
    // Si no tenemos coordenadas, intentar obtenerlas de la dirección manual
    if (_latitude == null || _longitude == null) {
      if (_addressController.text.trim().isNotEmpty) {
        setState(() => _isLoading = true);
        final success = await _getCoordinatesFromAddress();
        if (!success) {
          setState(() => _isLoading = false);
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addressRequired)),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Validar la primera imagen (representativa del hallazgo)
      setState(() {
        _isValidatingImages = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.validatingImage),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final firstImageBytes = await _selectedImages.first.readAsBytes();
      final validationResult = await _geminiService.validateImage(firstImageBytes);
      
      // Solo bloquear si el contenido es inapropiado o completamente irrelevante
      if (validationResult.action == ValidationAction.block) {
        setState(() {
          _isLoading = false;
          _isValidatingImages = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                validationResult.rejectionReason ?? 
                l10n.imageRejected,
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return; // Solo bloquear si es contenido inapropiado
      }
      
      // Determinar el estado inicial según el resultado de validación
      final PostStatus initialStatus = validationResult.action == ValidationAction.approve
          ? PostStatus.approved
          : PostStatus.pending;

      setState(() {
        _isValidatingImages = false;
      });

      // Comprimir y subir imágenes
      List<String> imageUrls = [];
      int totalOriginalSize = 0;
      int totalCompressedSize = 0;
      
      for (int i = 0; i < _selectedImages.length; i++) {
        final xFile = _selectedImages[i];
        try {
          print('Procesando imagen ${i + 1}/${_selectedImages.length}: ${xFile.name}');
          final originalBytes = await xFile.readAsBytes();
          totalOriginalSize += originalBytes.length;
          
          // Comprimir la imagen
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.compressingImage} ${i + 1}/${_selectedImages.length}...'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          
          final compressionResult = await _compressionService.compressImage(
            originalBytes,
            config: CompressionConfig.highQuality,
          );
          totalCompressedSize += compressionResult.compressedSize;
          
          print('Compresión: ${compressionResult.toString()}');
          
          // Subir imagen comprimida
          final url = await _storageService.uploadImageBytes(
            compressionResult.bytes,
            user.id,
            // Cambiar extensión a .jpg ya que siempre comprimimos a JPEG
            '${xFile.name.split('.').first}.jpg',
          );
          
          if (url != null) {
            print('URL obtenida: $url');
            imageUrls.add(url);
          } else {
            print('Error: URL es null para ${xFile.name}');
          }
        } catch (e) {
          print('Error procesando imagen ${xFile.name}: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error subiendo imagen ${xFile.name}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      
      // Log de estadísticas de compresión
      if (totalOriginalSize > 0) {
        final savedBytes = totalOriginalSize - totalCompressedSize;
        final savedPercent = (savedBytes / totalOriginalSize * 100).toStringAsFixed(1);
        print('Compresión total: ${ImageCompressionService.formatFileSize(totalOriginalSize)} → '
              '${ImageCompressionService.formatFileSize(totalCompressedSize)} '
              '($savedPercent% ahorrado)');
      }

      if (imageUrls.isEmpty) {
        throw Exception('No se pudieron subir las imágenes. Verifica la consola para más detalles.');
      }
      
      print('Total de URLs subidas: ${imageUrls.length}');

      // Crear post con el estado determinado por la validación
      final post = await _postService.createPost(
        userId: user.id,
        lat: _latitude!,
        lng: _longitude!,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        rockType: _rockTypeController.text.isEmpty
            ? null
            : _rockTypeController.text,
        imageUrls: imageUrls,
        initialStatus: initialStatus,
      );

      if (post != null && mounted) {
        // Mensaje diferente según el estado
        final String successMessage;
        final Color messageColor;
        
        if (initialStatus == PostStatus.approved) {
          successMessage = l10n.postPublishedDirectly;
          messageColor = Colors.green;
        } else {
          successMessage = l10n.postPendingReview;
          messageColor = Colors.orange;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: messageColor,
          ),
        );
        // Limpiar formulario
        _descriptionController.clear();
        _addressController.clear();
        _rockTypeController.clear();
        setState(() {
          _selectedImages = [];
          _latitude = null;
          _longitude = null;
          _coordinateSource = CoordinateSource.none;
          _needsManualAddress = false;
        });
        
        // Ejecutar callback para navegar al feed
        if (widget.onPostCreated != null) {
          widget.onPostCreated!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando post: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isValidatingImages = false;
      });
    }
  }

  /// Construye la sección de dirección según el estado actual
  Widget _buildAddressSection() {
    final l10n = AppLocalizations.of(context)!;
    
    // Si no hay imágenes seleccionadas, mostrar indicación
    if (_selectedImages.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
            ),
          ),
          title: Text(
            l10n.selectImageForLocation,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            l10n.locationFromPhotoHint,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    // Si estamos obteniendo la dirección, mostrar spinner
    if (_isGettingAddress || _isGettingLocation) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          title: Text(
            l10n.gettingAddress,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Si tenemos coordenadas de la imagen, mostrar dirección obtenida
    if (_coordinateSource == CoordinateSource.exif && _addressController.text.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          ),
          title: Text(
            l10n.locationFromPhoto,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          subtitle: Text(
            _addressController.text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
    }
    
    // Si necesita dirección manual (la imagen no tiene GPS)
    if (_needsManualAddress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_location_alt,
                  color: Colors.orange,
                ),
              ),
              title: Text(
                l10n.enterAddressManually,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              subtitle: Text(
                l10n.noGpsInPhotoHint,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                tooltip: l10n.useCurrentLocation,
                onPressed: _getDeviceLocation,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: l10n.address,
              hintText: l10n.addressPlaceholder,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
            ),
            validator: (value) {
              if (_needsManualAddress && (value == null || value.trim().isEmpty)) {
                return l10n.addressRequired;
              }
              return null;
            },
          ),
        ],
      );
    }
    
    // Estado por defecto (sin imágenes procesadas aún)
    return const SizedBox.shrink();
  }

  /// Verifica si el formulario está listo para enviar
  bool get _isReadyToSubmit {
    final hasImages = _selectedImages.isNotEmpty;
    final hasLocation = (_latitude != null && _longitude != null) || 
                        (_needsManualAddress && _addressController.text.trim().isNotEmpty);
    return hasImages && hasLocation;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline),
            const SizedBox(width: 8),
            Text(l10n.newFinding),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ========== PASO 1: FOTO ==========
            _buildStepCard(
              stepNumber: '1',
              title: l10n.step1Photo,
              subtitle: l10n.step1Hint,
              isCompleted: _selectedImages.isNotEmpty,
              icon: Icons.camera_alt,
              child: Column(
                children: [
                  // Botones de acción
                  if (_selectedImages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.camera_alt,
                              label: l10n.takePhoto,
                              onPressed: _takePhoto,
                              isPrimary: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.photo_library,
                              label: l10n.selectFromGallery,
                              onPressed: _pickImages,
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Vista previa de imágenes
                  if (_selectedImages.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1, // +1 para botón de añadir
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            // Botón para añadir más
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[400]!,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: Colors.grey, size: 32),
                                    SizedBox(height: 4),
                                    Text('+', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FutureBuilder<Uint8List>(
                                    future: _selectedImages[index].readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 120,
                                        );
                                      }
                                      return Container(
                                        width: 100,
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Badge de primera imagen (principal)
                              if (index == 0)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '★',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ),
                              // Botón de eliminar
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      if (_selectedImages.isEmpty) {
                                        _latitude = null;
                                        _longitude = null;
                                        _coordinateSource = CoordinateSource.none;
                                        _needsManualAddress = false;
                                        _addressController.clear();
                                        _descriptionController.clear();
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== PASO 2: DETALLES ==========
            _buildStepCard(
              stepNumber: '2',
              title: l10n.step2Details,
              subtitle: l10n.step2Hint,
              isCompleted: _selectedImages.isNotEmpty && !_isGeneratingDescription && !_isGettingAddress,
              isEnabled: _selectedImages.isNotEmpty,
              icon: Icons.auto_awesome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  const SizedBox(height: 12),
                  _buildDetailField(
                    label: l10n.descriptionLabel,
                    icon: Icons.description,
                    isLoading: _isGeneratingDescription,
                    loadingText: l10n.descriptionGenerating,
                    child: _selectedImages.isEmpty
                        ? Text(
                            l10n.descriptionHint,
                            style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  hintText: l10n.descriptionHint,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                maxLines: 3,
                                enabled: !_isGeneratingDescription,
                              ),
                              if (!_isGeneratingDescription && _descriptionController.text.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _generateDescriptionFromFirstImage,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(l10n.regenerateDescription),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const Divider(height: 24),
                  // Tipo de material (generado por IA junto con descripción)
                  _buildDetailField(
                    label: '${l10n.materialTypeLabel} (${l10n.optional})',
                    icon: Icons.category,
                    child: TextFormField(
                      controller: _rockTypeController,
                      decoration: InputDecoration(
                        hintText: l10n.materialTypeHint,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  // Ubicación
                  _buildDetailField(
                    label: l10n.locationLabel,
                    icon: Icons.location_on,
                    isLoading: _isGettingAddress || _isGettingLocation,
                    loadingText: l10n.gettingAddress,
                    statusIcon: _buildLocationStatusIcon(),
                    child: _buildLocationContent(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ========== PASO 3: PUBLICAR ==========
            _buildStepCard(
              stepNumber: '3',
              title: l10n.step3Publish,
              subtitle: _isReadyToSubmit ? l10n.readyToPublish : l10n.missingPhoto,
              isCompleted: false,
              isEnabled: _isReadyToSubmit,
              icon: Icons.publish,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Mensaje informativo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.aiWillValidate,
                            style: const TextStyle(color: Colors.blue, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón publicar
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_isReadyToSubmit) ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isReadyToSubmit ? 4 : 0,
                      ),
                      child: (_isLoading || _isValidatingImages)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isValidatingImages 
                                      ? l10n.validatingImages
                                      : l10n.uploading,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.publish),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.publishButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una tarjeta de paso
  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required IconData icon,
    required Widget child,
    bool isEnabled = true,
  }) {
    final Color stepColor = isCompleted 
        ? Colors.green 
        : (isEnabled ? AppTheme.primaryColor : Colors.grey);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: stepColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: stepColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Icon(icon, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: stepColor,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un botón de acción (cámara/galería)
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isPrimary ? Colors.white : AppTheme.primaryColor,
        elevation: isPrimary ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isPrimary ? BorderSide.none : BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  /// Construye un campo de detalle
  Widget _buildDetailField({
    required String label,
    required IconData icon,
    required Widget child,
    bool isLoading = false,
    String? loadingText,
    Widget? statusIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const Spacer(),
            if (statusIcon != null) statusIcon,
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                loadingText ?? '',
                style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
              ),
            ],
          )
        else
          child,
      ],
    );
  }

  /// Construye el icono de estado de ubicación
  Widget? _buildLocationStatusIcon() {
    if (_coordinateSource == CoordinateSource.exif) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.locationDetected,
              style: const TextStyle(color: Colors.green, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return null;
  }

  /// Construye el contenido del campo de ubicación
  Widget _buildLocationContent() {
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedImages.isEmpty) {
      return Text(
        l10n.locationWaiting,
        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
      );
    }
    
    if (_coordinateSource == CoordinateSource.exif && _addressController.text.isNotEmpty) {
      return Text(
        _addressController.text,
        style: const TextStyle(fontSize: 14),
      );
    }
    
    if (_needsManualAddress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.noGpsInPhotoHint,
            style: TextStyle(color: Colors.orange[700], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: l10n.addressPlaceholder,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _getDeviceLocation,
                icon: const Icon(Icons.my_location),
                tooltip: l10n.useCurrentLocation,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      );
    }
    
    return Text(
      l10n.locationWaiting,
      style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _rockTypeController.dispose();
    super.dispose();
  }
}
