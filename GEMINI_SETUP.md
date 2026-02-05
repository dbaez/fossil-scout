# Configuración de Gemini API

Para que la funcionalidad de descripción automática funcione, necesitas configurar tu API key de Gemini.

## Pasos para obtener la API key:

1. Ve a [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Inicia sesión con tu cuenta de Google
3. Haz clic en "Create API Key" o "Get API Key"
4. Copia la API key generada

## Configurar la API key en el código:

1. Abre el archivo `lib/services/gemini_service.dart`
2. Busca la línea que dice:
   ```dart
   static const String _apiKey = 'TU_API_KEY_AQUI'; // TODO: Configurar API key
   ```
3. Reemplaza `'TU_API_KEY_AQUI'` con tu API key real:
   ```dart
   static const String _apiKey = 'tu-api-key-real-aqui';
   ```

## Modelo utilizado:

- **Modelo**: Gemini 1.5 Flash (el más barato disponible)
- **Precio**: Muy económico, optimizado para velocidad y eficiencia
- **Región**: Funciona en Europa sin restricciones

## Funcionalidad:

- Cuando seleccionas o tomas una foto, se genera automáticamente una descripción
- También puedes hacer clic en el icono ✨ en el campo de descripción para regenerar
- La descripción se genera en español y es específica para hallazgos fósiles/geológicos

## Notas de seguridad:

⚠️ **IMPORTANTE**: No subas este archivo con tu API key a repositorios públicos. Considera usar variables de entorno o un archivo de configuración que esté en `.gitignore`.
