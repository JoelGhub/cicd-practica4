#!/bin/bash
# 🎯 TUTORIAL INTERACTIVO - CI/CD con AWS ECS
# Para gente que empieza desde CERO

set -e

echo "════════════════════════════════════════════════════════════"
echo "  🚀 TUTORIAL: CI/CD con AWS ECS - Para Principiantes"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Este script te guiará paso a paso. ¡No te preocupes!"
echo ""

# ============================================
# PASO 1: Verificar AWS CLI
# ============================================
echo "📍 PASO 1/5: Verificar AWS CLI"
echo "────────────────────────────────────────────────────────────"

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado"
    echo ""
    read -p "¿Quieres instalarlo ahora? (s/n): " install_cli
    if [ "$install_cli" = "s" ]; then
        ./install-aws-cli.sh
    else
        echo "Por favor instala AWS CLI y vuelve a ejecutar este script"
        exit 1
    fi
fi

echo "✅ AWS CLI instalado"
aws --version
echo ""

# ============================================
# PASO 2: Obtener credenciales de AWS
# ============================================
echo "📍 PASO 2/5: Configurar credenciales de AWS"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "🔑 Necesitas obtener tus credenciales de AWS:"
echo ""
echo "   1. Ve a: https://console.aws.amazon.com"
echo "   2. Haz login con tu cuenta de AWS"
echo "   3. Arriba a la derecha, click en tu nombre → Security credentials"
echo "   4. Baja hasta 'Access keys' → Click 'Create access key'"
echo "   5. Selecciona 'Command Line Interface (CLI)'"
echo "   6. ⚠️  GUARDA el Access Key ID y Secret Access Key"
echo ""
read -p "¿Ya tienes tus credenciales? (s/n): " has_credentials

if [ "$has_credentials" != "s" ]; then
    echo ""
    echo "Ve a obtenerlas y luego ejecuta este script de nuevo"
    exit 0
fi

# Verificar si ya está configurado
if aws sts get-caller-identity &> /dev/null; then
    echo ""
    echo "✅ AWS CLI ya está configurado"
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    echo "   Tu Account ID: $AWS_ACCOUNT_ID"
    echo ""
    read -p "¿Quieres mantener esta configuración? (s/n): " keep_config
    if [ "$keep_config" != "s" ]; then
        echo ""
        echo "Introduce tus nuevas credenciales:"
        aws configure
    fi
else
    echo ""
    echo "Vamos a configurar AWS CLI:"
    echo "(Necesitarás: Access Key ID, Secret Access Key)"
    echo ""
    aws configure
fi

# Verificar que funcionó
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error configurando AWS CLI"
    exit 1
fi

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo ""
echo "✅ AWS CLI configurado correctamente"
echo "   Tu Account ID: $AWS_ACCOUNT_ID"
echo ""

# ============================================
# PASO 3: Crear infraestructura en AWS
# ============================================
echo "📍 PASO 3/5: Crear infraestructura en AWS"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "Voy a crear en tu cuenta de AWS:"
echo "  • ECR Repository (para guardar imágenes Docker)"
echo "  • ECS Cluster (para ejecutar contenedores)"
echo "  • Security Group (firewall)"
echo "  • IAM Role (permisos)"
echo ""
echo "⚠️  Esto empezará a generar costos (~$0.01/hora)"
echo ""
read -p "¿Continuar? (s/n): " create_infra

if [ "$create_infra" != "s" ]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "🔨 Creando recursos..."
./setup-simple.sh

echo ""
echo "✅ Infraestructura creada en AWS"
echo ""

# ============================================
# PASO 4: Configurar GitHub
# ============================================
echo "📍 PASO 4/5: Configurar GitHub Repository"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "🔑 Ahora necesitas configurar los SECRETS en GitHub:"
echo ""
echo "   1. Ve a tu repositorio en GitHub"
echo "   2. Click en: Settings → Secrets and variables → Actions"
echo "   3. Click en: 'New repository secret'"
echo ""
echo "   Añade estos 2 secrets:"
echo ""
echo "   Secret 1:"
echo "   ┌─────────────────────────────────────┐"
echo "   │ Name:  AWS_ACCESS_KEY_ID            │"
echo "   │ Value: (tu Access Key ID de AWS)    │"
echo "   └─────────────────────────────────────┘"
echo ""
echo "   Secret 2:"
echo "   ┌─────────────────────────────────────┐"
echo "   │ Name:  AWS_SECRET_ACCESS_KEY        │"
echo "   │ Value: (tu Secret Access Key)       │"
echo "   └─────────────────────────────────────┘"
echo ""
echo "⚠️  IMPORTANTE: Son las MISMAS credenciales que usaste"
echo "   en el paso 2 (aws configure)"
echo ""
read -p "¿Ya configuraste los secrets en GitHub? (s/n): " github_done

if [ "$github_done" != "s" ]; then
    echo ""
    echo "Configúralos y luego continúa con el PASO 5"
    echo ""
    echo "Para continuar luego, ve directamente al PASO 5:"
    echo "Haz push de este código a la rama 'main' de tu repo"
    exit 0
fi

# ============================================
# PASO 5: Hacer push y deploy
# ============================================
echo ""
echo "📍 PASO 5/5: Deploy a AWS"
echo "────────────────────────────────────────────────────────────"
echo ""
echo "🎉 ¡Casi listo!"
echo ""
echo "Último paso: hacer push a GitHub"
echo ""

# Verificar si es un repo git
if [ ! -d ".git" ]; then
    echo "Inicializando repositorio Git..."
    git init
    git add .
    git commit -m "Initial commit: CI/CD AWS ECS setup"
    echo ""
    echo "Ahora necesitas conectar con tu repositorio en GitHub:"
    echo ""
    read -p "URL de tu repositorio GitHub: " repo_url
    git remote add origin "$repo_url"
fi

echo "Haciendo push a GitHub..."
echo ""
git branch -M main
git add .
git commit -m "CI/CD setup ready" 2>/dev/null || echo "No hay cambios nuevos"

echo ""
echo "Ejecuta este comando para hacer push:"
echo ""
echo "  git push -u origin main"
echo ""
echo "El pipeline de GitHub Actions se ejecutará automáticamente"
echo ""

# ============================================
# RESUMEN FINAL
# ============================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ ¡CONFIGURACIÓN COMPLETADA!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Resumen:"
echo "  ✓ AWS CLI configurado"
echo "  ✓ Infraestructura creada en AWS"
echo "  ✓ GitHub secrets configurados"
echo "  ✓ Código listo para push"
echo ""
echo "🚀 Próximos pasos:"
echo ""
echo "  1. Ejecuta: git push -u origin main"
echo "  2. Ve a GitHub → Actions para ver el pipeline"
echo "  3. Cuando termine, tu app estará en AWS ECS"
echo ""
echo "🔍 Para ver tu aplicación:"
echo "  1. Ve a AWS Console → ECS → Clusters → cicd-ecs-demo-cluster"
echo "  2. Click en el servicio → Tasks → Click en la tarea"
echo "  3. En 'Network', copia la 'Public IP'"
echo "  4. Visita: http://LA_IP:3000"
echo ""
echo "⚠️  IMPORTANTE - Evitar costos:"
echo "  Cuando termines la práctica, ejecuta:"
echo "  ./cleanup.sh"
echo ""
echo "💰 Costo actual: ~\$0.01/hora (si dejas todo corriendo)"
echo "════════════════════════════════════════════════════════════"
echo ""
