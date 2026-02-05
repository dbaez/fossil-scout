#!/bin/bash
# ===========================================
# Script para ejecutar en modo desarrollo
# ===========================================
# Uso: ./scripts/run_dev.sh
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
    exit 1
fi

echo "🚀 Iniciando Flutter Web en modo desarrollo..."
echo ""

# Crear un index.html temporal con la API key
TEMP_INDEX="web/index.html"
sed -i.bak "s/GOOGLE_MAPS_API_KEY_PLACEHOLDER/$GOOGLE_MAPS_API_KEY/g" "$TEMP_INDEX"

# Run con variables de entorno
flutter run -d chrome \
    --dart-define=SUPABASE_URL="$SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
    --dart-define=GOOGLE_MAPS_API_KEY="$GOOGLE_MAPS_API_KEY" \
    --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY"

# Restaurar index.html original
mv "$TEMP_INDEX.bak" "$TEMP_INDEX"
