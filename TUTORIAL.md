# 🎯 CI/CD con AWS ECS - TUTORIAL PARA PRINCIPIANTES

> **Para gente que empieza desde CERO**. Todo explicado paso a paso.

## 🚀 Inicio Rápido (3 comandos)

```bash
# 1. Ejecutar tutorial interactivo (te guía en todo)
./start-tutorial.sh

# 2. Hacer push a GitHub
git push -u origin main

# 3. Cuando termines, eliminar todo para no pagar
./cleanup.sh
```

**¡Eso es todo!** El script interactivo te explica todo.

---

## 📚 ¿Qué hace esta práctica?

Crea un **pipeline automático** que:
1. Cuando haces `git push` → se ejecuta automáticamente
2. Hace tests a tu código
3. Crea una imagen Docker
4. La sube a AWS
5. La despliega en AWS ECS (contenedores en la nube)

**Resultado**: Tu aplicación corriendo en la nube de AWS ☁️

---

## 🎓 Explicación Detallada (si quieres entender)

### ¿Qué son todos estos scripts?

```
start-tutorial.sh   → 🎯 EMPIEZA AQUÍ - Tutorial guiado paso a paso
install-aws-cli.sh  → Instala AWS CLI (lo hace el tutorial)
setup-simple.sh     → Crea recursos en AWS (lo hace el tutorial)
cleanup.sh          → ⚠️ ELIMINA TODO (úsalo al terminar)
```

### ¿Dónde van las credenciales de AWS?

**Hay 2 lugares (¡esto confunde a todos!):**

#### 1️⃣ En tu computadora (para crear la infraestructura)
```bash
aws configure
# Introduces: Access Key ID y Secret Access Key
```
Esto es para que el script `setup-simple.sh` pueda crear cosas en AWS.

#### 2️⃣ En GitHub (para que el pipeline funcione)
```
GitHub → Settings → Secrets → Actions
Crear 2 secrets:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
```
Esto es para que GitHub Actions pueda hacer deploy automáticamente.

**Son las MISMAS credenciales en ambos lugares** ✅

### ¿Cómo consigo las credenciales de AWS?

1. Ve a https://console.aws.amazon.com
2. Login con tu cuenta
3. Arriba derecha: Tu nombre → **Security credentials**
4. Baja a **"Access keys"**
5. Click **"Create access key"**
6. Elige **"Command Line Interface (CLI)"**
7. Next → Create
8. **⚠️ GUARDA AMBAS KEYS** (no las verás de nuevo)

---

## 💰 ¿Cuánto cuesta?

### Con cuenta nueva de AWS:
- **Práctica corta (2-3 horas)**: ~$0.02-0.03
- **Todo un día**: ~$0.24
- **Todo un mes**: ~$8

### ⚠️ IMPORTANTE para no pagar:
```bash
./cleanup.sh  # Ejecuta esto cuando termines
```

---

## 🐛 Solución de Problemas

### "aws: command not found"
```bash
./install-aws-cli.sh
```

### "The security token included in the request is invalid"
Tu configuración de AWS está mal:
```bash
aws configure  # Vuelve a introducir tus credenciales
```

### "Repository does not exist"
No has hecho push del código a GitHub todavía.

### El pipeline falla en GitHub Actions
Verifica que añadiste los secrets:
- GitHub → Settings → Secrets → Actions
- Debe haber: `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`

### "No puedo acceder a mi aplicación"
1. Ve a AWS Console → ECS → Clusters
2. Click en `cicd-ecs-demo-cluster`
3. Click en el servicio
4. Click en la tarea (task)
5. Busca **"Public IP"**
6. Visita: `http://LA_IP_PUBLICA:3000`

---

## 📝 Tutorial Manual (si no quieres el script)

### Paso 1: Instalar AWS CLI
```bash
./install-aws-cli.sh
```

### Paso 2: Configurar AWS CLI
```bash
aws configure
# AWS Access Key ID: TU_ACCESS_KEY
# AWS Secret Access Key: TU_SECRET_KEY
# Default region: us-east-1
# Default output format: json
```

### Paso 3: Crear infraestructura en AWS
```bash
./setup-simple.sh
```

### Paso 4: Configurar GitHub
1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. New repository secret:
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: (tu Access Key)
4. New repository secret:
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: (tu Secret Key)

### Paso 5: Push a GitHub
```bash
git add .
git commit -m "Setup CI/CD"
git push origin main
```

### Paso 6: Ver el resultado
1. GitHub → Actions (verás el pipeline ejecutándose)
2. Cuando termine: AWS Console → ECS → busca tu tarea
3. Copia la IP pública
4. Visita: `http://IP:3000`

### Paso 7: Limpiar (IMPORTANTE)
```bash
./cleanup.sh
```

---

## 🎯 Archivos del Proyecto

| Archivo | Qué hace |
|---------|----------|
| `start-tutorial.sh` | Tutorial interactivo guiado |
| `index.js` | Aplicación Node.js simple |
| `Dockerfile` | Cómo crear la imagen Docker |
| `task-definition.json` | Configuración de ECS |
| `.github/workflows/deploy.yml` | Pipeline de CI/CD |
| `setup-simple.sh` | Crea recursos en AWS |
| `cleanup.sh` | Elimina todo de AWS |

---

## ❓ Preguntas Frecuentes

**P: ¿Necesito tarjeta de crédito en AWS?**  
R: Sí, AWS la pide aunque uses el Free Tier.

**P: ¿Me van a cobrar?**  
R: Muy poco (~$0.01/hora). Ejecuta `./cleanup.sh` al terminar.

**P: ¿Qué es ECS?**  
R: Elastic Container Service. Corre tu aplicación en contenedores Docker en la nube.

**P: ¿Qué es ECR?**  
R: Elastic Container Registry. Guarda tus imágenes Docker (como Docker Hub pero de AWS).

**P: ¿Qué hace GitHub Actions?**  
R: Es el "robot" que automáticamente hace build y deploy cuando haces push.

**P: No entiendo nada de esto**  
R: ¡Normal! Solo ejecuta `./start-tutorial.sh` y sigue las instrucciones.

---

## 🆘 Ayuda

Si algo no funciona:
1. Lee los mensajes de error con calma
2. Busca en la sección "Solución de Problemas" arriba
3. Verifica que seguiste todos los pasos
4. La mayoría de problemas son por credenciales mal configuradas

---

**¡Suerte con tu práctica! 🚀**

**No olvides hacer `./cleanup.sh` al terminar** 💰
