# CI/CD con AWS ECS - VERSIÓN FÁCIL 🚀

> **¿Primera vez con AWS y CI/CD? Lee el [TUTORIAL.md](TUTORIAL.md)** 👈

## 🎯 Inicio Super Rápido

```bash
# Solo ejecuta esto y sigue las instrucciones:
./start-tutorial.sh
```

El script te guía paso a paso en TODO el proceso.

---

## 📋 Resumen Rápido

Esta práctica crea un pipeline CI/CD que:
- Cuando haces `git push` → automáticamente hace deploy a AWS
- Ejecuta tests, crea imagen Docker y la despliega en ECS
- Todo automatizado con GitHub Actions

**Servicios AWS usados**: Solo 2 (ECR + ECS Fargate)

## 📋 Contenido del Proyecto

```
cicd-practica4/
├── index.js                    # Aplicación Node.js/Express
├── package.json                # Dependencias Node.js
├── Dockerfile                  # Containerización de la app
├── task-definition.json        # Definición de tarea ECS
├── install-aws-cli.sh         # Script para instalar AWS CLI
├── setup-simple.sh            # Script de configuración automática
├── cleanup.sh                 # Script para eliminar todos los recursos
├── .github/
│   └── workflows/
│       └── deploy.yml         # Pipeline GitHub Actions
└── README.md                  # Este archivo
```

## 🎯 Funcionalidades

- ✅ Aplicación Node.js simple con Express
- ✅ Health check endpoint para ECS
- ✅ Containerización con Docker
- ✅ Pipeline CI/CD con GitHub Actions
- ✅ Deploy automático a AWS ECS
- ✅ Rolling update automático (sin downtime)

## 🏗️ Arquitectura (SIMPLIFICADA)

### Solo necesitas 2 servicios AWS:

1. **ECR (Elastic Container Registry)**: Para guardar imágenes Docker
2. **ECS Fargate**: Para ejecutar los contenedores

### Rolling Update

ECS hace un **rolling update automático**:
- Levanta nuevas tareas con la nueva versión
- Espera que estén healthy
- Apaga las tareas viejas
- Todo sin downtime

## 🚀 Configuración (5 minutos)

### 1. Requisitos Previos

- Cuenta de AWS (¡nueva cuenta tiene 12 meses de Free Tier!)
- Repositorio en GitHub

### 2. Instalar AWS CLI

Si no tienes AWS CLI instalado:

```bash
# Ejecutar el script de instalación
./install-aws-cli.sh

# Configurar credenciales
aws configure
```

Necesitarás crear credenciales en AWS:
1. Ve a AWS Console → IAM → Users → Tu usuario → Security credentials
2. Crea un "Access Key" para CLI
3. Guarda el Access Key ID y Secret Access Key

### 3. Configurar AWS (comando único)

```bash
# Configurar tu AWS CLI si aún no lo has hecho
aws configure

# Obtener tu Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Tu Account ID: $AWS_ACCOUNT_ID"

# 1. Crear ECR repository
aws ecr create-repository --repository-name cicd-ecs-demo --region us-east-1

# 2. Crear ECS Cluster
aws ecs create-cluster --cluster-name cicd-ecs-demo-cluster --region us-east-1

# 3. Crear IAM role para ECS (si no existe)
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }' 2>/dev/null || echo "Role ya existe"

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# 4. Actualizar task-definition.json con tu Account ID
sed -i '' "s/YOUR_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" task-definition.json

# 5. Registrar la task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# 6. Obtener VPC y Subnet por defecto
export VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
export SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[0].SubnetId" --output text)

# 7. Crear security group
export SG_ID=$(aws ec2 create-security-group \
  --group-name cicd-ecs-demo-sg \
  --description "Security group for ECS demo" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 3000 \
  --cidr 0.0.0.0/0

# 8. Crear ECS Service
aws ecs create-service \
  --cluster cicd-ecs-demo-cluster \
  --service-name cicd-ecs-demo-service \
  --task-definition cicd-ecs-demo-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}"

echo "✅ ¡Configuración completada!"
```

### 3. Configurar GitHub Secrets

Ve a tu repositorio → Settings → Secrets and variables → Actions

Añade estos secrets:

```
AWS_ACCESS_KEY_ID           # Tu Access Key ID de AWS
AWS_SECRET_ACCESS_KEY       # Tu Secret Access Key de AWS
```

**Nota**: Ya no necesitas `AWS_ACCOUNT_ID` como secret, el pipeline lo detecta automáticamente.

## 🔄 Cómo Funciona el Pipeline

### Trigger
El pipeline se ejecuta automáticamente al hacer push a `main`.

### Pasos
1. ✅ **Tests**: Ejecuta npm test
2. ✅ **Build**: Construye la imagen Docker
3. ✅ **Push**: Sube la imagen a ECR
4. ✅ **Deploy**: Actualiza el servicio ECS
5. ✅ **Rolling Update**: ECS automáticamente:
   - Levanta nuevas tareas
   - Verifica health checks
   - Apaga tareas viejas

## 🧪 Pruebas Locales

```bash
# Instalar dependencias
npm install

# Ejecutar app
npm start

# En otra terminal, probar
curl http://localhost:3000/
curl http://localhost:3000/health

# Probar con Docker
docker build -t cicd-ecs-demo .
docker run -p 3000:3000 cicd-ecs-demo
```

## 📊 Monitorización

### Ver logs
```bash
aws logs tail /ecs/cicd-ecs-demo --follow
```

### Ver estado del servicio
```bash
aws ecs describe-services \
  --cluster cicd-ecs-demo-cluster \
  --services cicd-ecs-demo-service
```

### Obtener IP pública de la tarea
```bash
# Listar tareas
aws ecs list-tasks --cluster cicd-ecs-demo-cluster --service-name cicd-ecs-demo-service

# Obtener detalles de la tarea (reemplaza TASK_ARN)
aws ecs describe-tasks --cluster cicd-ecs-demo-cluster --tasks TASK_ARN

# Obtener IP pública
aws ec2 describe-network-interfaces \
  --network-interface-ids ENI_ID \
  --query 'NetworkInterfaces[0].Association.PublicIp' \
  --output text
```

### Probar la app en ECS
```bash
# Una vez tengas la IP pública
curl http://IP_PUBLICA:3000/
curl http://IP_PUBLICA:3000/health
```

## 🎯 Endpoints

| Endpoint | Descripción |
|----------|-------------|
| `GET /` | Mensaje de bienvenida con versión |
| `GET /health` | Health check (usado por ECS) |
| `GET /info` | Información de la aplicación |

## 🔧 Troubleshooting

### La tarea no inicia
```bash
# Ver eventos del serv

### Con Cuenta Nueva de AWS (12 meses Free Tier):

**¡GRATIS los primeros 12 meses!** 🎉

El Free Tier de AWS incluye:
- ✅ **ECS Fargate**: Nada, Fargate no está en Free Tier 😢
- ✅ **ECR**: 500 MB/mes gratis (suficiente para esta práctica)
- ✅ **CloudWatch Logs**: 5 GB gratis/mes

**Costo real con cuenta nueva:**
- **ECS Fargate**: ~$8/mes (1 tarea de 0.25 vCPU y 0.5 GB RAM)
- **ECR**: $0 (dentro de Free Tier)
- **CloudWatch**: $0 (dentro de Free Tier)

**Total: ~$8/ (IMPORTANTE para evitar costos)

### Opción 1: Script automático (Recomendado)

```bash
./cleanup.sh
```

Este script elimina **todos** los recursos:
- ✓ ECS Service y Cluster
- ✓ ECR Repository (con todas las imágenes)
- ✓ Security Group
- ✓ CloudWatch Logs
- ✓ Task Definitions

### Opción 2: Manual

```bash
# Detener servicio
aws ecs update-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --desired-count 0

# Eliminar servicio
aws ecs delete-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --force

# Eliminar cluster
aws ecs delete-cluster --cluster cicd-ecs-demo-cluster

# Eliminar repositorio ECR
aws ecr delete-repository --repository-name cicd-ecs-demo --force

# Eliminar security group
awsAWS Free Tier](https://aws.amazon.com/free/)
- [GitHub Actions](https://docs.github.com/actions)

## ❓ FAQ

### ¿Cuánto cuesta hacer esta práctica?

Si tienes cuenta nueva de AWS y la terminas en 2-3 horas: **~$0.02-0.03** (casi nada).

Si la dejas corriendo todo un mes: **~$8**.

**Solución**: Ejecuta `./cleanup.sh` cuando termines.

### ¿El Free Tier cubre todo?

No, ECS Fargate no está incluido en Free Tier, pero es muy económico:
- ~$0.01/hora
- ~$0.24/día
- ~$8/mes

ECR y CloudWatch sí están en Free Tier (primeros 12 meses).

### ¿Cómo verifico que no estoy incurriendo en costos?

```bash
# Ver servicios activos
aws ecs describe-services --cluster cicd-ecs-demo-cluster --services cicd-ecs-demo-service --query 'services[0].runningCount'

# Si es 0, no hay tareas corriendo (no hay costos)
# Ve también a: AWS Console → Billing → Bills
```

### ¿Puedo usar esto en producción?

Esta configuración es para aprendizaje. Para producción necesitarías:
- Application Load Balancer (alta disponibilidad)
- Auto Scaling
- Múltiples AZs
- Monitorización avanzada
- Secrets Manager para credenciales

---

**¡Happy deploying! 🚀**

**No olvides ejecutar `./cleanup.sh` cuando termines para evitar costos** 💰

⚠️ **Verifica que todo se eliminó**:
```bash
# Verificar que no hay servicios corriendo
aws ecs list-services --cluster cicd-ecs-demo-cluster

# Verificar billing
# Ve a AWS Console → Billing → Bills para confirmar
```

⚠️ **IMPORTANTE**: Si solo quieres hacer la práctica por unas horas:
- Costo por hora: ~$0.01/hora
- Práctica de 2-3 horas: ~$0.03
- **¡Elimina los recursos después con `./cleanup.sh`!**ifica que el security group permita tráfico en el puerto 3000.

## 💰 Costos Estimados (MUY REDUCIDOS)

- **ECS Fargate**: ~$8/mes (1 tarea pequeña)
- **ECR**: Gratis (primeros 500MB)
- **CloudWatch Logs**: ~$1/mes

**Total: ~$9/mes** (vs $37-43 de la versión compleja)

💡 **Tip**: Para la práctica, puedes detener el servicio cuando no lo uses con:
```bash
aws ecs update-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --desired-count 0
```

## 🧹 Cleanup

```bash
# Detener servicio
aws ecs update-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --desired-count 0

# Eliminar servicio
aws ecs delete-service \
  --cluster cicd-ecs-demo-cluster \
  --service cicd-ecs-demo-service \
  --force

# Eliminar cluster
aws ecs delete-cluster --cluster cicd-ecs-demo-cluster

# Eliminar repositorio ECR
aws ecr delete-repository --repository-name cicd-ecs-demo --force

# Eliminar security group (reemplaza SG_ID)
aws ec2 delete-security-group --group-id sg-xxxxx
```

## 📝 Diferencias con la Versión Compleja

| Característica | Versión Simple | Versión Compleja |
|----------------|----------------|------------------|
| Servicios AWS | 2 (ECR, ECS) | 5+ (ECR, ECS, ALB, CodeDeploy, etc) |
| Deployment | Rolling Update | Blue/Green |
| Configuración | 5 minutos | 30+ minutos |
| Costo mensual | ~$9 | ~$37 |
| Load Balancer | No (IP pública) | Sí (ALB) |
| Downtime | Ninguno | Ninguno |

## 📚 Recursos

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions](https://docs.github.com/actions)

---

**¡Happy deploying! 🚀**

## 📋 Contenido del Proyecto

```
cicd-practica4/
├── index.js                    # Aplicación Node.js/Express
├── package.json                # Dependencias Node.js
├── Dockerfile                  # Containerización de la app
├── .dockerignore              # Archivos a ignorar en Docker
├── task-definition.json        # Definición de tarea ECS
├── appspec.json               # Configuración Blue/Green deploy
├── .github/
│   └── workflows/
│       └── deploy.yml         # Pipeline GitHub Actions
└── README.md                  # Este archivo
```

## 🎯 Funcionalidades

- ✅ Aplicación Node.js simple con Express
- ✅ Health check endpoint para ECS
- ✅ Containerización con Docker (multi-stage build)
- ✅ Pipeline CI/CD con GitHub Actions
- ✅ Deploy automático a AWS ECS
- ✅ Estrategia Blue/Green deployment
- ✅ Tests automáticos antes del deploy
- ✅ Logging con CloudWatch

## 🏗️ Arquitectura

### Componentes AWS necesarios:

1. **ECR (Elastic Container Registry)**: Registro de imágenes Docker
2. **ECS (Elastic Container Service)**: Orquestación de contenedores
3. **Application Load Balancer**: Distribuidor de tráfico
4. **CodeDeploy**: Gestión del deployment Blue/Green
5. **CloudWatch Logs**: Monitorización y logs

### Blue/Green Deployment

El deployment Blue/Green crea dos ambientes:
- **Blue**: Versión actual en producción
- **Green**: Nueva versión a desplegar

El tráfico se cambia gradualmente de Blue a Green, permitiendo rollback rápido si hay problemas.

## 🚀 Configuración Inicial

### 1. Requisitos Previos

- Cuenta de AWS
- CLI de AWS configurado
- Repositorio en GitHub
- Node.js 18+ (para desarrollo local)
- Docker (para pruebas locales)

### 2. Configurar Infraestructura AWS

#### 2.1 Crear VPC y Subnets (si no existen)

```bash
# Usar la VPC por defecto o crear una nueva
aws ec2 describe-vpcs
aws ec2 describe-subnets
```

#### 2.2 Crear ECR Repository

```bash
aws ecr create-repository \
  --repository-name cicd-ecs-demo \
  --region us-east-1
```

#### 2.3 Crear ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name cicd-ecs-demo-cluster \
  --region us-east-1
```

#### 2.4 Crear IAM Roles

**ecsTaskExecutionRole** (para ECS ejecutar tareas):
```bash
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy-ecs.json

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

**ecsTaskRole** (para la aplicación):
```bash
aws iam create-role \
  --role-name ecsTaskRole \
  --assume-role-policy-document file://trust-policy-ecs.json
```

#### 2.5 Crear Application Load Balancer

```bash
# Crear ALB
aws elbv2 create-load-balancer \
  --name cicd-ecs-demo-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx

# Crear Target Groups (Blue y Green)
aws elbv2 create-target-group \
  --name cicd-ecs-demo-tg-blue \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --health-check-path /health

aws elbv2 create-target-group \
  --name cicd-ecs-demo-tg-green \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --health-check-path /health

# Crear Listeners
aws elbv2 create-listener \
  --load-balancer-arn <ALB-ARN> \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=<TG-BLUE-ARN>
```

#### 2.6 Crear CloudWatch Log Group

```bash
aws logs create-log-group \
  --log-group-name /ecs/cicd-ecs-demo \
  --region us-east-1
```

#### 2.7 Registrar Task Definition

Actualiza `task-definition.json` con tus valores y:

```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json
```

#### 2.8 Crear ECS Service con CodeDeploy

```bash
aws ecs create-service \
  --cluster cicd-ecs-demo-cluster \
  --service-name cicd-ecs-demo-service \
  --task-definition cicd-ecs-demo-task \
  --desired-count 2 \
  --launch-type FARGATE \
  --deployment-controller type=CODE_DEPLOY \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=<TG-BLUE-ARN>,containerName=app,containerPort=3000
```

#### 2.9 Configurar CodeDeploy

```bash
# Crear aplicación CodeDeploy
aws deploy create-application \
  --application-name AppECS-cicd-ecs-demo-cluster-cicd-ecs-demo-service \
  --compute-platform ECS

# Crear deployment group
aws deploy create-deployment-group \
  --application-name AppECS-cicd-ecs-demo-cluster-cicd-ecs-demo-service \
  --deployment-group-name DgpECS-cicd-ecs-demo-cluster-cicd-ecs-demo-service \
  --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
  --service-role-arn arn:aws:iam::ACCOUNT_ID:role/CodeDeployServiceRole \
  --ecs-services clusterName=cicd-ecs-demo-cluster,serviceName=cicd-ecs-demo-service \
  --load-balancer-info targetGroupPairInfoList=[{targetGroups=[{name=cicd-ecs-demo-tg-blue},{name=cicd-ecs-demo-tg-green}],prodTrafficRoute={listenerArns=[<LISTENER-ARN>]}}] \
  --blue-green-deployment-configuration "terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=5},deploymentReadyOption={actionOnTimeout=CONTINUE_DEPLOYMENT}"
```

### 3. Configurar GitHub Secrets

Ve a tu repositorio → Settings → Secrets and variables → Actions

Añade estos secrets:

```
AWS_ACCESS_KEY_ID           # Tu Access Key ID de AWS
AWS_SECRET_ACCESS_KEY       # Tu Secret Access Key de AWS
AWS_ACCOUNT_ID              # Tu Account ID de AWS
```

### 4. Actualizar Configuración

Actualiza estos archivos con tus valores:

**task-definition.json**:
- `ACCOUNT_ID`: Tu AWS Account ID
- `REGION`: Tu región AWS
- Subnets y security groups

**appspec.json**:
- Subnets
- Security groups

**.github/workflows/deploy.yml**:
- Verifica los nombres de recursos si los cambiaste

## 🧪 Pruebas Locales

### Ejecutar la aplicación localmente

```bash
# Instalar dependencias
npm install

# Ejecutar app
npm start

# Probar endpoints
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/info
```

### Probar con Docker

```bash
# Build
docker build -t cicd-ecs-demo .

# Run
docker run -p 3000:3000 -e APP_VERSION=1.0.0 cicd-ecs-demo

# Test
curl http://localhost:3000/health
```

## 🔄 Workflow CI/CD

### Trigger del Pipeline

El pipeline se ejecuta automáticamente en:
- Push a la rama `main`
- Pull requests hacia `main`

### Fases del Pipeline

#### 1. **Build and Test**
- ✅ Checkout del código
- ✅ Setup de Node.js
- ✅ Instalación de dependencias
- ✅ Ejecución de tests
- ✅ Build de imagen Docker
- ✅ Test de la imagen

#### 2. **Deploy** (solo en main)
- ✅ Configuración de credenciales AWS
- ✅ Login a ECR
- ✅ Build y push de imagen
- ✅ Actualización de task definition
- ✅ Deploy con CodeDeploy (Blue/Green)
- ✅ Verificación de estabilidad del servicio

### Blue/Green Deployment Flow

1. **Traffic on Blue**: Todo el tráfico va a la versión Blue (actual)
2. **Deploy Green**: Se despliega la nueva versión en Green
3. **Health Checks**: ECS verifica que Green esté saludable
4. **Traffic Shift**: El tráfico se cambia gradualmente a Green
5. **Monitor**: Se monitorea la nueva versión
6. **Terminate Blue**: Si todo va bien, se termina Blue
7. **Rollback**: Si hay problemas, se vuelve a Blue instantáneamente

## 📊 Monitorización

### Ver logs en CloudWatch

```bash
aws logs tail /ecs/cicd-ecs-demo --follow
```

### Ver estado del servicio

```bash
aws ecs describe-services \
  --cluster cicd-ecs-demo-cluster \
  --services cicd-ecs-demo-service
```

### Ver deployments

```bash
aws deploy list-deployments \
  --application-name AppECS-cicd-ecs-demo-cluster-cicd-ecs-demo-service
```

## 🎯 Endpoints de la Aplicación

| Endpoint | Descripción |
|----------|-------------|
| `GET /` | Mensaje de bienvenida con versión |
| `GET /health` | Health check (usado por ECS) |
| `GET /info` | Información de la aplicación |

## 🔧 Troubleshooting

### El deployment falla

1. Verifica los logs de CloudWatch
2. Revisa el health check endpoint
3. Verifica que los security groups permitan el tráfico
4. Comprueba los IAM roles y permisos

### La imagen no se construye

1. Verifica el Dockerfile
2. Comprueba las dependencias en package.json
3. Revisa los logs de GitHub Actions

### CodeDeploy falla

1. Verifica que appspec.json tenga la configuración correcta
2. Comprueba que los target groups existan
3. Revisa que el listener esté configurado correctamente

## 🛡️ Seguridad

- ✅ Usar IAM roles con permisos mínimos necesarios
- ✅ No hardcodear credenciales (usar GitHub Secrets)
- ✅ Usar security groups restrictivos
- ✅ Ejecutar contenedor como usuario no-root
- ✅ Escanear imágenes Docker por vulnerabilidades
- ✅ Usar HTTPS en producción

## 📚 Recursos Adicionales

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS CodeDeploy Blue/Green](https://docs.aws.amazon.com/codedeploy/latest/userguide/deployments-create-ecs-cfn.html)
- [GitHub Actions AWS](https://github.com/aws-actions)

## 💰 Costos Estimados

Para esta práctica (uso ligero):
- ECS Fargate: ~$15-20/mes (2 tareas)
- ALB: ~$20/mes
- ECR: ~$1/mes (primeros 500MB gratis)
- CloudWatch Logs: ~$1-2/mes

**Total estimado: $37-43/mes**

💡 **Tip**: Recuerda eliminar los recursos cuando termines la práctica para evitar costos.

## 🧹 Cleanup

Para eliminar todos los recursos:

```bash
# Eliminar servicio ECS
aws ecs update-service --cluster cicd-ecs-demo-cluster --service cicd-ecs-demo-service --desired-count 0
aws ecs delete-service --cluster cicd-ecs-demo-cluster --service cicd-ecs-demo-service --force

# Eliminar cluster
aws ecs delete-cluster --cluster cicd-ecs-demo-cluster

# Eliminar ALB y target groups
aws elbv2 delete-load-balancer --load-balancer-arn <ALB-ARN>
aws elbv2 delete-target-group --target-group-arn <TG-ARN>

# Eliminar repositorio ECR
aws ecr delete-repository --repository-name cicd-ecs-demo --force

# Eliminar log group
aws logs delete-log-group --log-group-name /ecs/cicd-ecs-demo

# Eliminar aplicación CodeDeploy
aws deploy delete-application --application-name AppECS-cicd-ecs-demo-cluster-cicd-ecs-demo-service
```

## 📝 Licencia

MIT

---

**¡Happy deploying! 🚀**
