#!/bin/bash
# Script para eliminar TODOS los recursos de AWS y evitar costos
# ⚠️  CUIDADO: Este script eliminará todos los recursos de la práctica

set -e

export AWS_REGION="us-east-1"

echo "🧹 Limpieza de recursos AWS para CI/CD ECS Demo"
echo ""
echo "⚠️  ADVERTENCIA: Esto eliminará TODOS los recursos de la práctica"
echo "   - ECS Service y Cluster"
echo "   - ECR Repository (y todas las imágenes)"
echo "   - Security Group"
echo "   - CloudWatch Logs"
echo ""
read -p "¿Estás seguro? (escribe 'SI' para continuar): " confirmation

if [ "$confirmation" != "SI" ]; then
    echo "❌ Operación cancelada"
    exit 0
fi

echo ""
echo "🗑️  Iniciando limpieza..."
echo ""

# 1. Detener y eliminar ECS Service
echo "🛑 Deteniendo ECS service..."
aws ecs update-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --desired-count 0 \
  --region $AWS_REGION \
  2>/dev/null || echo "⚠️  Service no encontrado o ya detenido"

sleep 5

echo "🗑️  Eliminando ECS service..."
aws ecs delete-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --force \
  --region $AWS_REGION \
  2>/dev/null || echo "⚠️  Service no encontrado"

sleep 5

# 2. Eliminar ECS Cluster
echo "🗑️  Eliminando ECS cluster..."
aws ecs delete-cluster \
  --cluster cicd-ecs-demo-cluster \
  --region $AWS_REGION \
  2>/dev/null || echo "⚠️  Cluster no encontrado"

# 3. Eliminar ECR Repository (y todas las imágenes)
echo "🗑️  Eliminando ECR repository y todas las imágenes..."
aws ecr delete-repository \
  --repository-name cicd-ecs-demo \
  --force \
  --region $AWS_REGION \
  2>/dev/null || echo "⚠️  Repository no encontrado"

# 4. Eliminar Security Group
echo "🗑️  Eliminando security group..."
export SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=cicd-ecs-demo-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text \
  --region $AWS_REGION 2>/dev/null)

if [ "$SG_ID" != "None" ] && [ -n "$SG_ID" ]; then
    aws ec2 delete-security-group \
      --group-id $SG_ID \
      --region $AWS_REGION \
      2>/dev/null || echo "⚠️  No se pudo eliminar el security group (puede tener dependencias)"
else
    echo "⚠️  Security group no encontrado"
fi

# 5. Eliminar CloudWatch Log Group
echo "🗑️  Eliminando CloudWatch logs..."
aws logs delete-log-group \
  --log-group-name /ecs/cicd-ecs-demo \
  --region $AWS_REGION \
  2>/dev/null || echo "⚠️  Log group no encontrado"

# 6. Deregistrar todas las task definitions
echo "🗑️  Desregistrando task definitions..."
TASK_DEFINITIONS=$(aws ecs list-task-definitions \
  --family-prefix cicd-ecs-demo-task \
  --query 'taskDefinitionArns[]' \
  --output text \
  --region $AWS_REGION 2>/dev/null)

if [ -n "$TASK_DEFINITIONS" ]; then
    for task_def in $TASK_DEFINITIONS; do
        aws ecs deregister-task-definition \
          --task-definition $task_def \
          --region $AWS_REGION \
          2>/dev/null || true
    done
    echo "✓ Task definitions desregistradas"
else
    echo "⚠️  No hay task definitions para eliminar"
fi

echo ""
echo "✅ Limpieza completada!"
echo ""
echo "📋 Recursos eliminados:"
echo "  ✓ ECS Service (cicd-ecs-demo-service)"
echo "  ✓ ECS Cluster (cicd-ecs-demo-cluster)"
echo "  ✓ ECR Repository (cicd-ecs-demo)"
echo "  ✓ Security Group (cicd-ecs-demo-sg)"
echo "  ✓ CloudWatch Logs (/ecs/cicd-ecs-demo)"
echo "  ✓ Task Definitions"
echo ""
echo "💡 Nota: Los IAM roles (ecsTaskExecutionRole) NO se eliminan"
echo "   porque pueden estar siendo usados por otros servicios."
echo "   Si quieres eliminarlos manualmente:"
echo "   aws iam detach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
echo "   aws iam delete-role --role-name ecsTaskExecutionRole"
echo ""
echo "💰 Ya no deberías incurrir en costos por estos recursos."
