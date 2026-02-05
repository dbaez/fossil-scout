import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'config/env_config.dart';
import 'screens/main_navigation.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'widgets/fossil_compass_icon.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug: mostrar estado de configuración
  if (kDebugMode) {
    EnvConfig.printStatus();
  }

  // 1. Inicialización de Supabase 
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fossil Scout',
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''), // Español
        Locale('en', ''), // Inglés
        Locale('fr', ''), // Francés
        Locale('it', ''), // Italiano
        Locale('de', ''), // Alemán
      ],
      locale: _getLocale(),
      home: const AuthWrapper(),
    );
  }

  Locale _getLocale() {
    // Obtener el idioma del sistema
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = systemLocale.languageCode;
    
    // Si el idioma está soportado, usarlo; si no, usar inglés por defecto
    if (['es', 'en', 'fr', 'it', 'de'].contains(languageCode)) {
      return Locale(languageCode);
    }
    return const Locale('en'); // Por defecto inglés
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado de autenticación
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        
        if (session != null) {
          // Usuario autenticado - sincronizar y mostrar pantalla principal
          return const AuthenticatedWrapper();
        } else {
          // Usuario no autenticado - mostrar login
          return const LoginScreen();
        }
      },
    );
  }
}

class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({super.key});

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  final UserService _userService = UserService();
  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();
    _syncUser();
  }

  Future<void> _syncUser() async {
    await _userService.syncUserFromAuth();
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyncing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const MainNavigation();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Solo usar GoogleSignIn para móvil/desktop, no para web
  GoogleSignIn? _googleSignIn;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Solo inicializar GoogleSignIn para móvil/desktop
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: '952569557814-hdo2b9ktmg44phmdl9hofre8vjv9crus.apps.googleusercontent.com',
      );
      _googleSignIn!.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        if (account != null) {
          _loginToSupabase(account);
        }
      });
    }
  }

  Future<void> _handleSignIn() async {
    if (kIsWeb) {
      // Para web, usar OAuth redirect de Supabase directamente (sin GoogleSignIn)
      await _signInWithGoogleWeb();
    } else {
      // Para móvil/desktop, usar Google Sign-In normal
      if (_googleSignIn == null) return;
      
      try {
        setState(() => _isLoading = true);
        final account = await _googleSignIn!.signIn();
        if (account != null) {
          await _loginToSupabase(account);
        }
      } catch (e) {
        debugPrint("Error al iniciar sesión: $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogleWeb() async {
    try {
      setState(() => _isLoading = true);
      
      // Usar OAuth redirect de Supabase (más confiable en web)
      // Para desarrollo local, usar localhost
      final redirectUrl = kIsWeb 
        ? '${Uri.base.origin}'
        : 'com.example.fossil_scout://auth/callback';
      
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );
      // No cambiar isLoading aquí porque el usuario será redirigido
    } catch (e) {
      debugPrint("Error en OAuth: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginToSupabase(GoogleSignInAccount account) async {
    try {
      final googleAuth = await account.authentication;
      
      if (googleAuth.idToken == null) {
        debugPrint("Error: idToken nulo.");
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      debugPrint("¡Conectado a Supabase correctamente!");
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error en el login: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              Color(0xFF2c5f8d),
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icono
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const FossilCompassIcon(
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  Text(
                    AppLocalizations.of(context)!.appTitle,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Subtítulo
                  Text(
                    AppLocalizations.of(context)!.exploreDiscoverShare,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Botón de login
                  if (_isLoading)
                    const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 24,
                              height: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.login, size: 24);
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.continueWithGoogle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.science,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.citizenScienceForAll,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}