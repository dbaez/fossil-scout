/// Configuración de variables de entorno para Fossil Scout
/// 
/// Las variables se inyectan durante el build usando --dart-define:
/// flutter build web \
///   --dart-define=SUPABASE_URL=xxx \
///   --dart-define=SUPABASE_ANON_KEY=xxx \
///   --dart-define=GOOGLE_MAPS_API_KEY=xxx \
///   --dart-define=GEMINI_API_KEY=xxx
/// 
/// Para desarrollo local, usa el script: ./scripts/build_dev.sh
class EnvConfig {
  // Singleton
  EnvConfig._();
  
  /// Supabase URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  /// Supabase Anonymous Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  
  /// Google Maps API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  /// Google Gemini API Key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  /// Verifica si las variables de entorno están configuradas
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           googleMapsApiKey.isNotEmpty &&
           geminiApiKey.isNotEmpty;
  }
  
  /// Lista las variables faltantes (útil para debug)
  static List<String> get missingVariables {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY');
    if (geminiApiKey.isEmpty) missing.add('GEMINI_API_KEY');
    return missing;
  }
  
  /// Imprime el estado de configuración (para debug)
  static void printStatus() {
    print('=== EnvConfig Status ===');
    print('SUPABASE_URL: ${supabaseUrl.isNotEmpty ? "✓ configurado" : "✗ falta"}');
    print('SUPABASE_ANON_KEY: ${supabaseAnonKey.isNotEmpty ? "✓ configurado" : "✗ falta"}');
    print('GOOGLE_MAPS_API_KEY: ${googleMapsApiKey.isNotEmpty ? "✓ configurado" : "✗ falta"}');
    print('GEMINI_API_KEY: ${geminiApiKey.isNotEmpty ? "✓ configurado" : "✗ falta"}');
    print('========================');
  }
}
