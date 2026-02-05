import 'package:flutter/material.dart';
import 'dart:ui';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // App
      'appTitle': 'Fossil Scout',
      'exploreDiscoverShare': 'Explora, descubre y comparte hallazgos fósiles',
      'continueWithGoogle': 'Continuar con Google',
      'citizenScienceForAll': 'Ciencia ciudadana para todos',
      
      // Timeline
      'exploringFindings': 'Explorando hallazgos...',
      'noFindingsYet': 'No hay hallazgos aún',
      'beFirstToDiscover': '¡Sé el primero en descubrir un fósil!',
      'distance': 'Distancia',
      'antiquity': 'Antigüedad',
      
      // Posts
      'postApproved': 'Post aprobado exitosamente',
      'errorApprovingPost': 'Error al aprobar el post',
      'postRejected': 'Post rechazado',
      'errorRejectingPost': 'Error al rechazar el post',
      'errorLoadingPosts': 'Error cargando posts',
      
      // Comments
      'viewAllComments': 'Ver todos los comentarios',
      'noCommentsYet': 'Aún no hay comentarios',
      'writeComment': 'Escribe un comentario...',
      'publish': 'Publicar',
      'comments': 'Comentarios',
      
      // Map
      'takeMeToThisFossil': 'Llévame a este fósil',
      'calculatingRoute': 'Calculando ruta...',
      'routeCalculated': 'Ruta calculada',
      'errorCalculatingRoute': 'Error calculando la ruta',
      'noRouteFound': 'No se pudo calcular la ruta hasta este fósil',
      'currentLocationError': 'No se pudo obtener tu ubicación actual',
      'address': 'Dirección',
      'materialType': 'Tipo de material',
      'coordinates': 'Coordenadas',
      'close': 'Cerrar',
      
      // Profile
      'profile': 'Perfil',
      'myPosts': 'Mis posts',
      'pendingPosts': 'Posts pendientes',
      'approvedPosts': 'Posts aprobados',
      'rejectedPosts': 'Posts rechazados',
      'logout': 'Cerrar sesión',
      
      // Add Post
      'addPost': 'Agregar post',
      'description': 'Descripción',
      'selectImages': 'Seleccionar imágenes',
      'submit': 'Enviar',
      'cancel': 'Cancelar',
      'validatingImage': 'Validando imagen',
      'validatingImages': 'Validando imágenes...',
      'uploading': 'Subiendo...',
      'imageRejected': 'La imagen no cumple con los criterios de validación',
      'imageInappropriate': 'La imagen contiene contenido inapropiado que no está permitido',
      'imageNotRelated': 'La imagen no está relacionada con fósiles o paleontología',
      'validationError': 'Error al validar la imagen',
      'imageRequired': 'Se necesita al menos una imagen',
      'addressRequired': 'Se necesita una dirección',
      'selectImageForLocation': 'Selecciona una imagen',
      'locationFromPhotoHint': 'La ubicación se obtendrá de los metadatos de la foto',
      'gettingAddress': 'Obteniendo dirección...',
      'locationFromPhoto': 'Ubicación de la foto',
      'locationExtractedFromPhoto': 'Ubicación extraída de la foto',
      'noGpsInPhoto': 'La foto no tiene información de ubicación',
      'enterAddressManually': 'Introduce la dirección',
      'noGpsInPhotoHint': 'La foto no contiene coordenadas GPS. Por favor, indica dónde encontraste el fósil.',
      'useCurrentLocation': 'Usar mi ubicación actual',
      'addressPlaceholder': 'Ej: Parque Nacional, Ciudad',
      'addressNotFound': 'No se pudo encontrar la dirección',
      'postPublishedDirectly': '¡Hallazgo publicado! La IA ha validado tu fósil',
      'postPendingReview': 'Hallazgo enviado. Pendiente de revisión',
      // New finding flow
      'newFinding': 'Nuevo Hallazgo',
      'step1Photo': '1. Foto del hallazgo',
      'step1Hint': 'Toma o selecciona una foto de tu descubrimiento',
      'takePhoto': 'Cámara',
      'selectFromGallery': 'Galería',
      'step2Details': '2. Detalles',
      'step2Hint': 'Generados automáticamente por IA',
      'descriptionLabel': 'Descripción',
      'descriptionGenerating': 'Generando descripción con IA...',
      'descriptionHint': 'Se generará automáticamente al añadir una foto',
      'regenerateDescription': 'Regenerar con IA',
      'locationLabel': 'Ubicación',
      'locationDetected': 'Detectada de la foto',
      'locationManual': 'Introduce la ubicación',
      'locationWaiting': 'Esperando foto...',
      'materialTypeLabel': 'Tipo de material',
      'materialTypeHint': 'Ej: Caliza, Arenisca, Mármol...',
      'optional': 'opcional',
      'step3Publish': '3. Publicar',
      'publishButton': 'Publicar Hallazgo',
      'missingPhoto': 'Añade una foto para continuar',
      'missingLocation': 'Se necesita la ubicación',
      'readyToPublish': '¡Listo para publicar!',
      'aiWillValidate': 'La IA validará tu hallazgo',
      'compressingImage': 'Comprimiendo imagen',
    },
    'en': {
      // App
      'appTitle': 'Fossil Scout',
      'exploreDiscoverShare': 'Explore, discover and share fossil findings',
      'continueWithGoogle': 'Continue with Google',
      'citizenScienceForAll': 'Citizen science for everyone',
      
      // Timeline
      'exploringFindings': 'Exploring findings...',
      'noFindingsYet': 'No findings yet',
      'beFirstToDiscover': 'Be the first to discover a fossil!',
      'distance': 'Distance',
      'antiquity': 'Antiquity',
      
      // Posts
      'postApproved': 'Post approved successfully',
      'errorApprovingPost': 'Error approving post',
      'postRejected': 'Post rejected',
      'errorRejectingPost': 'Error rejecting post',
      'errorLoadingPosts': 'Error loading posts',
      
      // Comments
      'viewAllComments': 'View all comments',
      'noCommentsYet': 'No comments yet',
      'writeComment': 'Write a comment...',
      'publish': 'Publish',
      'comments': 'Comments',
      
      // Map
      'takeMeToThisFossil': 'Take me to this fossil',
      'calculatingRoute': 'Calculating route...',
      'routeCalculated': 'Route calculated',
      'errorCalculatingRoute': 'Error calculating route',
      'noRouteFound': 'Could not calculate route to this fossil',
      'currentLocationError': 'Could not get your current location',
      'address': 'Address',
      'materialType': 'Material type',
      'coordinates': 'Coordinates',
      'close': 'Close',
      
      // Profile
      'profile': 'Profile',
      'myPosts': 'My posts',
      'pendingPosts': 'Pending posts',
      'approvedPosts': 'Approved posts',
      'rejectedPosts': 'Rejected posts',
      'logout': 'Logout',
      
      // Add Post
      'addPost': 'Add post',
      'description': 'Description',
      'selectImages': 'Select images',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'validatingImage': 'Validating image',
      'validatingImages': 'Validating images...',
      'uploading': 'Uploading...',
      'imageRejected': 'The image does not meet validation criteria',
      'imageInappropriate': 'The image contains inappropriate content that is not allowed',
      'imageNotRelated': 'The image is not related to fossils or paleontology',
      'validationError': 'Error validating image',
      'imageRequired': 'At least one image is required',
      'addressRequired': 'Address is required',
      'selectImageForLocation': 'Select an image',
      'locationFromPhotoHint': 'Location will be obtained from the photo metadata',
      'gettingAddress': 'Getting address...',
      'locationFromPhoto': 'Location from photo',
      'locationExtractedFromPhoto': 'Location extracted from photo',
      'noGpsInPhoto': 'The photo has no location information',
      'enterAddressManually': 'Enter address',
      'noGpsInPhotoHint': 'The photo does not contain GPS coordinates. Please indicate where you found the fossil.',
      'useCurrentLocation': 'Use my current location',
      'addressPlaceholder': 'E.g.: National Park, City',
      'addressNotFound': 'Could not find the address',
      'postPublishedDirectly': 'Finding published! AI has validated your fossil',
      'postPendingReview': 'Finding submitted. Pending review',
      // New finding flow
      'newFinding': 'New Finding',
      'step1Photo': '1. Photo of the finding',
      'step1Hint': 'Take or select a photo of your discovery',
      'takePhoto': 'Camera',
      'selectFromGallery': 'Gallery',
      'step2Details': '2. Details',
      'step2Hint': 'Auto-generated by AI',
      'descriptionLabel': 'Description',
      'descriptionGenerating': 'Generating description with AI...',
      'descriptionHint': 'Will be generated automatically when you add a photo',
      'regenerateDescription': 'Regenerate with AI',
      'locationLabel': 'Location',
      'locationDetected': 'Detected from photo',
      'locationManual': 'Enter location',
      'locationWaiting': 'Waiting for photo...',
      'materialTypeLabel': 'Material type',
      'materialTypeHint': 'E.g.: Limestone, Sandstone, Marble...',
      'optional': 'optional',
      'step3Publish': '3. Publish',
      'publishButton': 'Publish Finding',
      'missingPhoto': 'Add a photo to continue',
      'missingLocation': 'Location is required',
      'readyToPublish': 'Ready to publish!',
      'aiWillValidate': 'AI will validate your finding',
      'compressingImage': 'Compressing image',
    },
    'fr': {
      // App
      'appTitle': 'Fossil Scout',
      'exploreDiscoverShare': 'Explorez, découvrez et partagez des découvertes fossiles',
      'continueWithGoogle': 'Continuer avec Google',
      'citizenScienceForAll': 'Science citoyenne pour tous',
      
      // Timeline
      'exploringFindings': 'Exploration des découvertes...',
      'noFindingsYet': 'Aucune découverte pour le moment',
      'beFirstToDiscover': 'Soyez le premier à découvrir un fossile !',
      'distance': 'Distance',
      'antiquity': 'Antiquité',
      
      // Posts
      'postApproved': 'Publication approuvée avec succès',
      'errorApprovingPost': 'Erreur lors de l\'approbation de la publication',
      'postRejected': 'Publication rejetée',
      'errorRejectingPost': 'Erreur lors du rejet de la publication',
      'errorLoadingPosts': 'Erreur lors du chargement des publications',
      
      // Comments
      'viewAllComments': 'Voir tous les commentaires',
      'noCommentsYet': 'Pas encore de commentaires',
      'writeComment': 'Écrivez un commentaire...',
      'publish': 'Publier',
      'comments': 'Commentaires',
      
      // Map
      'takeMeToThisFossil': 'Emmenez-moi à ce fossile',
      'calculatingRoute': 'Calcul de l\'itinéraire...',
      'routeCalculated': 'Itinéraire calculé',
      'errorCalculatingRoute': 'Erreur lors du calcul de l\'itinéraire',
      'noRouteFound': 'Impossible de calculer l\'itinéraire vers ce fossile',
      'currentLocationError': 'Impossible d\'obtenir votre position actuelle',
      'address': 'Adresse',
      'materialType': 'Type de matériau',
      'coordinates': 'Coordonnées',
      'close': 'Fermer',
      
      // Profile
      'profile': 'Profil',
      'myPosts': 'Mes publications',
      'pendingPosts': 'Publications en attente',
      'approvedPosts': 'Publications approuvées',
      'rejectedPosts': 'Publications rejetées',
      'logout': 'Déconnexion',
      
      // Add Post
      'addPost': 'Ajouter une publication',
      'description': 'Description',
      'selectImages': 'Sélectionner des images',
      'submit': 'Soumettre',
      'cancel': 'Annuler',
      'validatingImage': 'Validation de l\'image',
      'validatingImages': 'Validation des images...',
      'uploading': 'Téléchargement...',
      'imageRejected': 'L\'image ne répond pas aux critères de validation',
      'imageInappropriate': 'L\'image contient du contenu inapproprié qui n\'est pas autorisé',
      'imageNotRelated': 'L\'image n\'est pas liée aux fossiles ou à la paléontologie',
      'validationError': 'Erreur lors de la validation de l\'image',
      'imageRequired': 'Au moins une image est requise',
      'addressRequired': 'L\'adresse est requise',
      'selectImageForLocation': 'Sélectionnez une image',
      'locationFromPhotoHint': 'La localisation sera obtenue à partir des métadonnées de la photo',
      'gettingAddress': 'Obtention de l\'adresse...',
      'locationFromPhoto': 'Localisation de la photo',
      'locationExtractedFromPhoto': 'Localisation extraite de la photo',
      'noGpsInPhoto': 'La photo n\'a pas d\'informations de localisation',
      'enterAddressManually': 'Entrez l\'adresse',
      'noGpsInPhotoHint': 'La photo ne contient pas de coordonnées GPS. Veuillez indiquer où vous avez trouvé le fossile.',
      'useCurrentLocation': 'Utiliser ma position actuelle',
      'addressPlaceholder': 'Ex: Parc National, Ville',
      'addressNotFound': 'Impossible de trouver l\'adresse',
      'postPublishedDirectly': 'Découverte publiée ! L\'IA a validé votre fossile',
      'postPendingReview': 'Découverte soumise. En attente de révision',
      // New finding flow
      'newFinding': 'Nouvelle Découverte',
      'step1Photo': '1. Photo de la découverte',
      'step1Hint': 'Prenez ou sélectionnez une photo de votre découverte',
      'takePhoto': 'Appareil photo',
      'selectFromGallery': 'Galerie',
      'step2Details': '2. Détails',
      'step2Hint': 'Générés automatiquement par l\'IA',
      'descriptionLabel': 'Description',
      'descriptionGenerating': 'Génération de la description par l\'IA...',
      'descriptionHint': 'Sera générée automatiquement lors de l\'ajout d\'une photo',
      'regenerateDescription': 'Régénérer avec l\'IA',
      'locationLabel': 'Emplacement',
      'locationDetected': 'Détecté depuis la photo',
      'locationManual': 'Entrer l\'emplacement',
      'locationWaiting': 'En attente de la photo...',
      'materialTypeLabel': 'Type de matériau',
      'materialTypeHint': 'Ex: Calcaire, Grès, Marbre...',
      'optional': 'optionnel',
      'step3Publish': '3. Publier',
      'publishButton': 'Publier la Découverte',
      'missingPhoto': 'Ajoutez une photo pour continuer',
      'missingLocation': 'L\'emplacement est requis',
      'readyToPublish': 'Prêt à publier !',
      'aiWillValidate': 'L\'IA validera votre découverte',
      'compressingImage': 'Compression de l\'image',
    },
    'it': {
      // App
      'appTitle': 'Fossil Scout',
      'exploreDiscoverShare': 'Esplora, scopri e condividi ritrovamenti fossili',
      'continueWithGoogle': 'Continua con Google',
      'citizenScienceForAll': 'Scienza cittadina per tutti',
      
      // Timeline
      'exploringFindings': 'Esplorazione dei ritrovamenti...',
      'noFindingsYet': 'Nessun ritrovamento ancora',
      'beFirstToDiscover': 'Sii il primo a scoprire un fossile!',
      'distance': 'Distanza',
      'antiquity': 'Antichità',
      
      // Posts
      'postApproved': 'Post approvato con successo',
      'errorApprovingPost': 'Errore nell\'approvazione del post',
      'postRejected': 'Post rifiutato',
      'errorRejectingPost': 'Errore nel rifiuto del post',
      'errorLoadingPosts': 'Errore nel caricamento dei post',
      
      // Comments
      'viewAllComments': 'Vedi tutti i commenti',
      'noCommentsYet': 'Nessun commento ancora',
      'writeComment': 'Scrivi un commento...',
      'publish': 'Pubblica',
      'comments': 'Commenti',
      
      // Map
      'takeMeToThisFossil': 'Portami a questo fossile',
      'calculatingRoute': 'Calcolo del percorso...',
      'routeCalculated': 'Percorso calcolato',
      'errorCalculatingRoute': 'Errore nel calcolo del percorso',
      'noRouteFound': 'Impossibile calcolare il percorso verso questo fossile',
      'currentLocationError': 'Impossibile ottenere la tua posizione attuale',
      'address': 'Indirizzo',
      'materialType': 'Tipo di materiale',
      'coordinates': 'Coordinate',
      'close': 'Chiudi',
      
      // Profile
      'profile': 'Profilo',
      'myPosts': 'I miei post',
      'pendingPosts': 'Post in attesa',
      'approvedPosts': 'Post approvati',
      'rejectedPosts': 'Post rifiutati',
      'logout': 'Esci',
      
      // Add Post
      'addPost': 'Aggiungi post',
      'description': 'Descrizione',
      'selectImages': 'Seleziona immagini',
      'submit': 'Invia',
      'cancel': 'Annulla',
      'validatingImage': 'Validazione immagine',
      'validatingImages': 'Validazione immagini...',
      'uploading': 'Caricamento...',
      'imageRejected': 'L\'immagine non soddisfa i criteri di validazione',
      'imageInappropriate': 'L\'immagine contiene contenuti inappropriati non consentiti',
      'imageNotRelated': 'L\'immagine non è correlata a fossili o paleontologia',
      'validationError': 'Errore nella validazione dell\'immagine',
      'imageRequired': 'È richiesta almeno un\'immagine',
      'addressRequired': 'L\'indirizzo è richiesto',
      'selectImageForLocation': 'Seleziona un\'immagine',
      'locationFromPhotoHint': 'La posizione sarà ottenuta dai metadati della foto',
      'gettingAddress': 'Ottenimento indirizzo...',
      'locationFromPhoto': 'Posizione dalla foto',
      'locationExtractedFromPhoto': 'Posizione estratta dalla foto',
      'noGpsInPhoto': 'La foto non ha informazioni sulla posizione',
      'enterAddressManually': 'Inserisci l\'indirizzo',
      'noGpsInPhotoHint': 'La foto non contiene coordinate GPS. Indica dove hai trovato il fossile.',
      'useCurrentLocation': 'Usa la mia posizione attuale',
      'addressPlaceholder': 'Es: Parco Nazionale, Città',
      'addressNotFound': 'Impossibile trovare l\'indirizzo',
      'postPublishedDirectly': 'Ritrovamento pubblicato! L\'IA ha validato il tuo fossile',
      'postPendingReview': 'Ritrovamento inviato. In attesa di revisione',
      // New finding flow
      'newFinding': 'Nuovo Ritrovamento',
      'step1Photo': '1. Foto del ritrovamento',
      'step1Hint': 'Scatta o seleziona una foto della tua scoperta',
      'takePhoto': 'Fotocamera',
      'selectFromGallery': 'Galleria',
      'step2Details': '2. Dettagli',
      'step2Hint': 'Generati automaticamente dall\'IA',
      'descriptionLabel': 'Descrizione',
      'descriptionGenerating': 'Generazione descrizione con IA...',
      'descriptionHint': 'Verrà generata automaticamente quando aggiungi una foto',
      'regenerateDescription': 'Rigenera con IA',
      'locationLabel': 'Posizione',
      'locationDetected': 'Rilevata dalla foto',
      'locationManual': 'Inserisci posizione',
      'locationWaiting': 'In attesa della foto...',
      'materialTypeLabel': 'Tipo di materiale',
      'materialTypeHint': 'Es: Calcare, Arenaria, Marmo...',
      'optional': 'opzionale',
      'step3Publish': '3. Pubblica',
      'publishButton': 'Pubblica Ritrovamento',
      'missingPhoto': 'Aggiungi una foto per continuare',
      'missingLocation': 'La posizione è richiesta',
      'readyToPublish': 'Pronto per pubblicare!',
      'aiWillValidate': 'L\'IA validerà il tuo ritrovamento',
      'compressingImage': 'Compressione immagine',
    },
    'de': {
      // App
      'appTitle': 'Fossil Scout',
      'exploreDiscoverShare': 'Erkunden, entdecken und teilen Sie fossile Funde',
      'continueWithGoogle': 'Mit Google fortfahren',
      'citizenScienceForAll': 'Bürgerwissenschaft für alle',
      
      // Timeline
      'exploringFindings': 'Funde erkunden...',
      'noFindingsYet': 'Noch keine Funde',
      'beFirstToDiscover': 'Seien Sie der Erste, der ein Fossil entdeckt!',
      'distance': 'Entfernung',
      'antiquity': 'Altertum',
      
      // Posts
      'postApproved': 'Beitrag erfolgreich genehmigt',
      'errorApprovingPost': 'Fehler beim Genehmigen des Beitrags',
      'postRejected': 'Beitrag abgelehnt',
      'errorRejectingPost': 'Fehler beim Ablehnen des Beitrags',
      'errorLoadingPosts': 'Fehler beim Laden der Beiträge',
      
      // Comments
      'viewAllComments': 'Alle Kommentare anzeigen',
      'noCommentsYet': 'Noch keine Kommentare',
      'writeComment': 'Schreiben Sie einen Kommentar...',
      'publish': 'Veröffentlichen',
      'comments': 'Kommentare',
      
      // Map
      'takeMeToThisFossil': 'Bringen Sie mich zu diesem Fossil',
      'calculatingRoute': 'Route wird berechnet...',
      'routeCalculated': 'Route berechnet',
      'errorCalculatingRoute': 'Fehler beim Berechnen der Route',
      'noRouteFound': 'Route zu diesem Fossil konnte nicht berechnet werden',
      'currentLocationError': 'Aktueller Standort konnte nicht ermittelt werden',
      'address': 'Adresse',
      'materialType': 'Materialtyp',
      'coordinates': 'Koordinaten',
      'close': 'Schließen',
      
      // Profile
      'profile': 'Profil',
      'myPosts': 'Meine Beiträge',
      'pendingPosts': 'Ausstehende Beiträge',
      'approvedPosts': 'Genehmigte Beiträge',
      'rejectedPosts': 'Abgelehnte Beiträge',
      'logout': 'Abmelden',
      
      // Add Post
      'addPost': 'Beitrag hinzufügen',
      'description': 'Beschreibung',
      'selectImages': 'Bilder auswählen',
      'submit': 'Senden',
      'cancel': 'Abbrechen',
      'validatingImage': 'Bild validieren',
      'validatingImages': 'Bilder werden validiert...',
      'uploading': 'Hochladen...',
      'imageRejected': 'Das Bild erfüllt die Validierungskriterien nicht',
      'imageInappropriate': 'Das Bild enthält unangemessene Inhalte, die nicht erlaubt sind',
      'imageNotRelated': 'Das Bild steht nicht im Zusammenhang mit Fossilien oder Paläontologie',
      'validationError': 'Fehler bei der Bildvalidierung',
      'imageRequired': 'Mindestens ein Bild ist erforderlich',
      'addressRequired': 'Adresse ist erforderlich',
      'selectImageForLocation': 'Bild auswählen',
      'locationFromPhotoHint': 'Der Standort wird aus den Foto-Metadaten ermittelt',
      'gettingAddress': 'Adresse wird ermittelt...',
      'locationFromPhoto': 'Standort aus Foto',
      'locationExtractedFromPhoto': 'Standort aus Foto extrahiert',
      'noGpsInPhoto': 'Das Foto enthält keine Standortinformationen',
      'enterAddressManually': 'Adresse eingeben',
      'noGpsInPhotoHint': 'Das Foto enthält keine GPS-Koordinaten. Bitte geben Sie an, wo Sie das Fossil gefunden haben.',
      'useCurrentLocation': 'Meinen aktuellen Standort verwenden',
      'addressPlaceholder': 'Z.B.: Nationalpark, Stadt',
      'addressNotFound': 'Adresse konnte nicht gefunden werden',
      'postPublishedDirectly': 'Fund veröffentlicht! KI hat Ihr Fossil validiert',
      'postPendingReview': 'Fund eingereicht. Ausstehende Überprüfung',
      // New finding flow
      'newFinding': 'Neuer Fund',
      'step1Photo': '1. Foto des Fundes',
      'step1Hint': 'Nehmen oder wählen Sie ein Foto Ihrer Entdeckung',
      'takePhoto': 'Kamera',
      'selectFromGallery': 'Galerie',
      'step2Details': '2. Details',
      'step2Hint': 'Automatisch von KI generiert',
      'descriptionLabel': 'Beschreibung',
      'descriptionGenerating': 'Beschreibung wird mit KI generiert...',
      'descriptionHint': 'Wird automatisch generiert, wenn Sie ein Foto hinzufügen',
      'regenerateDescription': 'Mit KI regenerieren',
      'locationLabel': 'Standort',
      'locationDetected': 'Aus Foto erkannt',
      'locationManual': 'Standort eingeben',
      'locationWaiting': 'Warte auf Foto...',
      'materialTypeLabel': 'Materialtyp',
      'materialTypeHint': 'Z.B.: Kalkstein, Sandstein, Marmor...',
      'optional': 'optional',
      'step3Publish': '3. Veröffentlichen',
      'publishButton': 'Fund Veröffentlichen',
      'missingPhoto': 'Fügen Sie ein Foto hinzu, um fortzufahren',
      'missingLocation': 'Standort ist erforderlich',
      'readyToPublish': 'Bereit zur Veröffentlichung!',
      'aiWillValidate': 'KI wird Ihren Fund validieren',
      'compressingImage': 'Bild komprimieren',
    },
  };

  String get appTitle => _localizedValues[_getLanguageCode()]?['appTitle'] ?? _localizedValues['en']!['appTitle']!;
  String get exploreDiscoverShare => _localizedValues[_getLanguageCode()]?['exploreDiscoverShare'] ?? _localizedValues['en']!['exploreDiscoverShare']!;
  String get continueWithGoogle => _localizedValues[_getLanguageCode()]?['continueWithGoogle'] ?? _localizedValues['en']!['continueWithGoogle']!;
  String get citizenScienceForAll => _localizedValues[_getLanguageCode()]?['citizenScienceForAll'] ?? _localizedValues['en']!['citizenScienceForAll']!;
  String get exploringFindings => _localizedValues[_getLanguageCode()]?['exploringFindings'] ?? _localizedValues['en']!['exploringFindings']!;
  String get noFindingsYet => _localizedValues[_getLanguageCode()]?['noFindingsYet'] ?? _localizedValues['en']!['noFindingsYet']!;
  String get beFirstToDiscover => _localizedValues[_getLanguageCode()]?['beFirstToDiscover'] ?? _localizedValues['en']!['beFirstToDiscover']!;
  String get distance => _localizedValues[_getLanguageCode()]?['distance'] ?? _localizedValues['en']!['distance']!;
  String get antiquity => _localizedValues[_getLanguageCode()]?['antiquity'] ?? _localizedValues['en']!['antiquity']!;
  String get postApproved => _localizedValues[_getLanguageCode()]?['postApproved'] ?? _localizedValues['en']!['postApproved']!;
  String get errorApprovingPost => _localizedValues[_getLanguageCode()]?['errorApprovingPost'] ?? _localizedValues['en']!['errorApprovingPost']!;
  String get postRejected => _localizedValues[_getLanguageCode()]?['postRejected'] ?? _localizedValues['en']!['postRejected']!;
  String get errorRejectingPost => _localizedValues[_getLanguageCode()]?['errorRejectingPost'] ?? _localizedValues['en']!['errorRejectingPost']!;
  String get errorLoadingPosts => _localizedValues[_getLanguageCode()]?['errorLoadingPosts'] ?? _localizedValues['en']!['errorLoadingPosts']!;
  String get viewAllComments => _localizedValues[_getLanguageCode()]?['viewAllComments'] ?? _localizedValues['en']!['viewAllComments']!;
  String get noCommentsYet => _localizedValues[_getLanguageCode()]?['noCommentsYet'] ?? _localizedValues['en']!['noCommentsYet']!;
  String get writeComment => _localizedValues[_getLanguageCode()]?['writeComment'] ?? _localizedValues['en']!['writeComment']!;
  String get publish => _localizedValues[_getLanguageCode()]?['publish'] ?? _localizedValues['en']!['publish']!;
  String get comments => _localizedValues[_getLanguageCode()]?['comments'] ?? _localizedValues['en']!['comments']!;
  String get takeMeToThisFossil => _localizedValues[_getLanguageCode()]?['takeMeToThisFossil'] ?? _localizedValues['en']!['takeMeToThisFossil']!;
  String get calculatingRoute => _localizedValues[_getLanguageCode()]?['calculatingRoute'] ?? _localizedValues['en']!['calculatingRoute']!;
  String get routeCalculated => _localizedValues[_getLanguageCode()]?['routeCalculated'] ?? _localizedValues['en']!['routeCalculated']!;
  String get errorCalculatingRoute => _localizedValues[_getLanguageCode()]?['errorCalculatingRoute'] ?? _localizedValues['en']!['errorCalculatingRoute']!;
  String get noRouteFound => _localizedValues[_getLanguageCode()]?['noRouteFound'] ?? _localizedValues['en']!['noRouteFound']!;
  String get currentLocationError => _localizedValues[_getLanguageCode()]?['currentLocationError'] ?? _localizedValues['en']!['currentLocationError']!;
  String get address => _localizedValues[_getLanguageCode()]?['address'] ?? _localizedValues['en']!['address']!;
  String get materialType => _localizedValues[_getLanguageCode()]?['materialType'] ?? _localizedValues['en']!['materialType']!;
  String get coordinates => _localizedValues[_getLanguageCode()]?['coordinates'] ?? _localizedValues['en']!['coordinates']!;
  String get close => _localizedValues[_getLanguageCode()]?['close'] ?? _localizedValues['en']!['close']!;
  String get profile => _localizedValues[_getLanguageCode()]?['profile'] ?? _localizedValues['en']!['profile']!;
  String get myPosts => _localizedValues[_getLanguageCode()]?['myPosts'] ?? _localizedValues['en']!['myPosts']!;
  String get pendingPosts => _localizedValues[_getLanguageCode()]?['pendingPosts'] ?? _localizedValues['en']!['pendingPosts']!;
  String get approvedPosts => _localizedValues[_getLanguageCode()]?['approvedPosts'] ?? _localizedValues['en']!['approvedPosts']!;
  String get rejectedPosts => _localizedValues[_getLanguageCode()]?['rejectedPosts'] ?? _localizedValues['en']!['rejectedPosts']!;
  String get logout => _localizedValues[_getLanguageCode()]?['logout'] ?? _localizedValues['en']!['logout']!;
  String get addPost => _localizedValues[_getLanguageCode()]?['addPost'] ?? _localizedValues['en']!['addPost']!;
  String get description => _localizedValues[_getLanguageCode()]?['description'] ?? _localizedValues['en']!['description']!;
  String get selectImages => _localizedValues[_getLanguageCode()]?['selectImages'] ?? _localizedValues['en']!['selectImages']!;
  String get submit => _localizedValues[_getLanguageCode()]?['submit'] ?? _localizedValues['en']!['submit']!;
  String get cancel => _localizedValues[_getLanguageCode()]?['cancel'] ?? _localizedValues['en']!['cancel']!;
  String get validatingImage => _localizedValues[_getLanguageCode()]?['validatingImage'] ?? _localizedValues['en']!['validatingImage']!;
  String get validatingImages => _localizedValues[_getLanguageCode()]?['validatingImages'] ?? _localizedValues['en']!['validatingImages']!;
  String get uploading => _localizedValues[_getLanguageCode()]?['uploading'] ?? _localizedValues['en']!['uploading']!;
  String get imageRejected => _localizedValues[_getLanguageCode()]?['imageRejected'] ?? _localizedValues['en']!['imageRejected']!;
  String get imageInappropriate => _localizedValues[_getLanguageCode()]?['imageInappropriate'] ?? _localizedValues['en']!['imageInappropriate']!;
  String get imageNotRelated => _localizedValues[_getLanguageCode()]?['imageNotRelated'] ?? _localizedValues['en']!['imageNotRelated']!;
  String get validationError => _localizedValues[_getLanguageCode()]?['validationError'] ?? _localizedValues['en']!['validationError']!;
  String get imageRequired => _localizedValues[_getLanguageCode()]?['imageRequired'] ?? _localizedValues['en']!['imageRequired']!;
  String get addressRequired => _localizedValues[_getLanguageCode()]?['addressRequired'] ?? _localizedValues['en']!['addressRequired']!;
  String get selectImageForLocation => _localizedValues[_getLanguageCode()]?['selectImageForLocation'] ?? _localizedValues['en']!['selectImageForLocation']!;
  String get locationFromPhotoHint => _localizedValues[_getLanguageCode()]?['locationFromPhotoHint'] ?? _localizedValues['en']!['locationFromPhotoHint']!;
  String get gettingAddress => _localizedValues[_getLanguageCode()]?['gettingAddress'] ?? _localizedValues['en']!['gettingAddress']!;
  String get locationFromPhoto => _localizedValues[_getLanguageCode()]?['locationFromPhoto'] ?? _localizedValues['en']!['locationFromPhoto']!;
  String get locationExtractedFromPhoto => _localizedValues[_getLanguageCode()]?['locationExtractedFromPhoto'] ?? _localizedValues['en']!['locationExtractedFromPhoto']!;
  String get noGpsInPhoto => _localizedValues[_getLanguageCode()]?['noGpsInPhoto'] ?? _localizedValues['en']!['noGpsInPhoto']!;
  String get enterAddressManually => _localizedValues[_getLanguageCode()]?['enterAddressManually'] ?? _localizedValues['en']!['enterAddressManually']!;
  String get noGpsInPhotoHint => _localizedValues[_getLanguageCode()]?['noGpsInPhotoHint'] ?? _localizedValues['en']!['noGpsInPhotoHint']!;
  String get useCurrentLocation => _localizedValues[_getLanguageCode()]?['useCurrentLocation'] ?? _localizedValues['en']!['useCurrentLocation']!;
  String get addressPlaceholder => _localizedValues[_getLanguageCode()]?['addressPlaceholder'] ?? _localizedValues['en']!['addressPlaceholder']!;
  String get addressNotFound => _localizedValues[_getLanguageCode()]?['addressNotFound'] ?? _localizedValues['en']!['addressNotFound']!;
  String get postPublishedDirectly => _localizedValues[_getLanguageCode()]?['postPublishedDirectly'] ?? _localizedValues['en']!['postPublishedDirectly']!;
  String get postPendingReview => _localizedValues[_getLanguageCode()]?['postPendingReview'] ?? _localizedValues['en']!['postPendingReview']!;
  // New finding flow
  String get newFinding => _localizedValues[_getLanguageCode()]?['newFinding'] ?? _localizedValues['en']!['newFinding']!;
  String get step1Photo => _localizedValues[_getLanguageCode()]?['step1Photo'] ?? _localizedValues['en']!['step1Photo']!;
  String get step1Hint => _localizedValues[_getLanguageCode()]?['step1Hint'] ?? _localizedValues['en']!['step1Hint']!;
  String get takePhoto => _localizedValues[_getLanguageCode()]?['takePhoto'] ?? _localizedValues['en']!['takePhoto']!;
  String get selectFromGallery => _localizedValues[_getLanguageCode()]?['selectFromGallery'] ?? _localizedValues['en']!['selectFromGallery']!;
  String get step2Details => _localizedValues[_getLanguageCode()]?['step2Details'] ?? _localizedValues['en']!['step2Details']!;
  String get step2Hint => _localizedValues[_getLanguageCode()]?['step2Hint'] ?? _localizedValues['en']!['step2Hint']!;
  String get descriptionLabel => _localizedValues[_getLanguageCode()]?['descriptionLabel'] ?? _localizedValues['en']!['descriptionLabel']!;
  String get descriptionGenerating => _localizedValues[_getLanguageCode()]?['descriptionGenerating'] ?? _localizedValues['en']!['descriptionGenerating']!;
  String get descriptionHint => _localizedValues[_getLanguageCode()]?['descriptionHint'] ?? _localizedValues['en']!['descriptionHint']!;
  String get regenerateDescription => _localizedValues[_getLanguageCode()]?['regenerateDescription'] ?? _localizedValues['en']!['regenerateDescription']!;
  String get locationLabel => _localizedValues[_getLanguageCode()]?['locationLabel'] ?? _localizedValues['en']!['locationLabel']!;
  String get locationDetected => _localizedValues[_getLanguageCode()]?['locationDetected'] ?? _localizedValues['en']!['locationDetected']!;
  String get locationManual => _localizedValues[_getLanguageCode()]?['locationManual'] ?? _localizedValues['en']!['locationManual']!;
  String get locationWaiting => _localizedValues[_getLanguageCode()]?['locationWaiting'] ?? _localizedValues['en']!['locationWaiting']!;
  String get materialTypeLabel => _localizedValues[_getLanguageCode()]?['materialTypeLabel'] ?? _localizedValues['en']!['materialTypeLabel']!;
  String get materialTypeHint => _localizedValues[_getLanguageCode()]?['materialTypeHint'] ?? _localizedValues['en']!['materialTypeHint']!;
  String get optional => _localizedValues[_getLanguageCode()]?['optional'] ?? _localizedValues['en']!['optional']!;
  String get step3Publish => _localizedValues[_getLanguageCode()]?['step3Publish'] ?? _localizedValues['en']!['step3Publish']!;
  String get publishButton => _localizedValues[_getLanguageCode()]?['publishButton'] ?? _localizedValues['en']!['publishButton']!;
  String get missingPhoto => _localizedValues[_getLanguageCode()]?['missingPhoto'] ?? _localizedValues['en']!['missingPhoto']!;
  String get missingLocation => _localizedValues[_getLanguageCode()]?['missingLocation'] ?? _localizedValues['en']!['missingLocation']!;
  String get readyToPublish => _localizedValues[_getLanguageCode()]?['readyToPublish'] ?? _localizedValues['en']!['readyToPublish']!;
  String get aiWillValidate => _localizedValues[_getLanguageCode()]?['aiWillValidate'] ?? _localizedValues['en']!['aiWillValidate']!;
  String get compressingImage => _localizedValues[_getLanguageCode()]?['compressingImage'] ?? _localizedValues['en']!['compressingImage']!;

  String _getLanguageCode() {
    final code = locale.languageCode;
    // Si el idioma no está soportado, usar inglés
    if (!_localizedValues.containsKey(code)) {
      return 'en';
    }
    return code;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'fr', 'it', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
