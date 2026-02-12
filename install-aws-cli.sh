#!/bin/bash
# Script para instalar AWS CLI en macOS o Linux

set -e

echo "🔧 Instalando AWS CLI..."
echo ""

# Detectar sistema operativo
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Detectado: macOS"
    
    # Verificar si ya está instalado
    if command -v aws &> /dev/null; then
        echo "✅ AWS CLI ya está instalado"
        aws --version
        exit 0
    fi
    
    # Instalar con Homebrew si está disponible
    if command -v brew &> /dev/null; then
        echo "🍺 Instalando con Homebrew..."
        brew install awscli
    else
        echo "📦 Instalando manualmente..."
        cd /tmp
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    fi
    
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Detectado: Linux"
    
    # Verificar si ya está instalado
    if command -v aws &> /dev/null; then
        echo "✅ AWS CLI ya está instalado"
        aws --version
        exit 0
    fi
    
    echo "📦 Instalando AWS CLI..."
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
    
else
    echo "❌ Sistema operativo no soportado: $OSTYPE"
    echo "Por favor, instala AWS CLI manualmente desde:"
    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo ""
echo "✅ AWS CLI instalado correctamente!"
aws --version

echo ""
echo "📝 Próximos pasos:"
echo "1. Configura AWS CLI con tus credenciales:"
echo "   aws configure"
echo ""
echo "2. Introduce:"
echo "   - AWS Access Key ID"
echo "   - AWS Secret Access Key"
echo "   - Default region (ej: us-east-1)"
echo "   - Default output format (ej: json)"
echo ""
echo "3. Verifica la configuración:"
echo "   aws sts get-caller-identity"
echo ""
echo "4. Ejecuta el script de setup:"
echo "   ./setup-simple.sh"
