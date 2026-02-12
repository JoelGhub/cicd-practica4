#!/bin/bash
# Script simplificado de configuración AWS para CI/CD ECS Demo
# Requisito: AWS CLI instalado y configurado (ejecuta ./install-aws-cli.sh si no lo tienes)

set -e

echo "🚀 Configurando infraestructura AWS para CI/CD ECS Demo (Versión Simple)..."
echo ""

# Verificar que AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado"
    echo "Ejecuta: ./install-aws-cli.sh"
    exit 1
fi

# Verificar que AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI no está configurado"
    echo "Ejecuta: aws configure"
    exit 1
fi

# Obtener Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-east-1"

echo "✅ Account ID: $AWS_ACCOUNT_ID"
echo "✅ Region: $AWS_REGION"
echo ""

# 1. Crear ECR repository
echo "📦 Creando ECR repository..."
aws ecr create-repository \
  --repository-name cicd-ecs-demo \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true \
  2>/dev/null || echo "✓ Repository ya existe"

# 2. Crear ECS Cluster
echo "🏗️  Creando ECS cluster..."
aws ecs create-cluster \
  --cluster-name cicd-ecs-demo-cluster \
  --region $AWS_REGION \
  2>/dev/null || echo "✓ Cluster ya existe"

# 3. Crear IAM role para ECS
echo "🔐 Configurando IAM role..."
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || echo "✓ Role ya existe"

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
  2>/dev/null || echo "✓ Policy ya attached"

# 4. Actualizar task-definition.json
echo "📝 Actualizando task-definition.json..."
sed -i.bak "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" task-definition.json
rm task-definition.json.bak 2>/dev/null || true

# 5. Registrar task definition
echo "📋 Registrando task definition..."
aws ecs register-task-definition --cli-input-json file://task-definition.json > /dev/null

# 6. Obtener VPC y Subnet por defecto
echo "🌐 Obteniendo VPC y subnet..."
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text --region $AWS_REGION)
export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text --region $AWS_REGION)

echo "  VPC: $VPC_ID"
echo "  Subnet: $SUBNET_ID"

# 7. Crear security group
echo "🔒 Creando security group..."
export SG_ID=$(aws ec2 create-security-group \
  --group-name cicd-ecs-demo-sg \
  --description "Security group for ECS demo" \
  --vpc-id $VPC_ID \
  --region $AWS_REGION \
  --query 'GroupId' --output text 2>/dev/null || \
  aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=cicd-ecs-demo-sg" \
    --query 'SecurityGroups[0].GroupId' \
    --output text --region $AWS_REGION)

echo "  Security Group: $SG_ID"

# Añadir regla de ingreso si no existe
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0 \
  --region $AWS_REGION \
  2>/dev/null || echo "✓ Regla de ingreso ya existe"

# 8. Crear ECS Service
echo "🚀 Creando ECS service..."
aws ecs create-service \
  --cluster cicd-ecs-demo-cluster \
  --service-name cicd-ecs-demo-service \
  --task-definition cicd-ecs-demo-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --region $AWS_REGION \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  2>/dev/null || echo "✓ Service ya existe"

echo ""
echo "✅ ¡Configuración completada!"
echo ""
echo "📝 Próximos pasos:"
echo "1. Ve a GitHub → Settings → Secrets and add:"
echo "   - AWS_ACCESS_KEY_ID"
echo "   - AWS_SECRET_ACCESS_KEY"
echo ""
echo "2. Haz push a main para activar el pipeline"
echo ""
echo "3. Para obtener la IP pública de tu app:"
echo "   aws ecs list-tasks --cluster cicd-ecs-demo-cluster --service-name cicd-ecs-demo-service"
echo "   aws ecs describe-tasks --cluster cicd-ecs-demo-cluster --tasks <TASK_ARN>"
echo ""
echo "🎉 ¡Listo para deployar!"
