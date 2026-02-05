#!/bin/bash
# ===========================================
# Script de build para DESARROLLO LOCAL
# ===========================================
# Uso: ./scripts/build_dev.sh
# ===========================================

set -e

# Directorio del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Cargar variables de entorno desde .env
if [ -f ".env" ]; then
    echo "📦 Cargando variables desde .env..."
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ Error: No se encontró el archivo .env"
    echo "   Copia .env.example a .env y configura tus API keys"
    exit 1
fi

# Verificar que las variables existan
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$GOOGLE_MAPS_API_KEY" ] || [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ Error: Faltan variables de entorno en .env"
    echo "   Revisa que todas las variables estén configuradas"
    exit 1
fi

echo "🔨 Compilando Flutter Web para desarrollo..."

# Build con variables de entorno
flutter build web \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
    --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"

# Reemplazar placeholder en index.html
echo "🔄 Configurando Google Maps API key en index.html..."
sed -i.bak "s/GOOGLE_MAPS_API_KEY_PLACEHOLDER/$GOOGLE_MAPS_API_KEY/g" build/web/index.html
rm -f build/web/index.html.bak

echo "✅ Build completado en build/web/"
echo ""
echo "Para servir localmente:"
echo "  cd build/web && python3 -m http.server 8080"
