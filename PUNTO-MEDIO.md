# CI/CD Intermedio: GitHub Actions + Render con Docker 🐳

> **Para gente que ya tiene experiencia básica** (ej: has usado Netlify)

## 🎯 Lo que vas a hacer:

1. Pipeline en **GitHub Actions** con varios pasos (tests, security, build)
2. Deploy de **contenedor Docker** a **Render**
3. Todo automático en cada push

**Más control que Netlify, más simple que AWS**

---

## 🚀 Setup Rápido (10 minutos)

### Paso 1: Push a GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/TU_USUARIO/TU_REPO.git
git push -u origin main
```

### Paso 2: Crear Web Service en Render

1. Ve a **https://render.com** → Sign up with GitHub
2. **New +** → **Web Service**
3. Conecta tu repositorio
4. Configura:
   - **Name**: `cicd-demo`
   - **Environment**: `Docker`
   - **Region**: Frankfurt
   - **Instance Type**: `Free`
5. **Avanzado** → Desmarca "Auto-Deploy" (lo haremos con GitHub Actions)
6. **Create Web Service**

### Paso 3: Obtener Deploy Hook de Render

1. En tu servicio → **Settings**
2. Baja hasta **Deploy Hook**
3. Copia la URL (algo como `https://api.render.com/deploy/srv-xxxxx?key=yyyyy`)

### Paso 4: Añadir Secret en GitHub

1. Tu repo en GitHub → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**:
   - Name: `RENDER_DEPLOY_HOOK`
   - Value: (pega la URL del paso 3)
3. **Add secret**

### Paso 5: Activar GitHub Actions

El workflow ya está en `.github/workflows/deploy.yml`

Ahora cada push a `main`:
1. ✅ Ejecuta tests
2. ✅ Analiza seguridad del código
3. ✅ Construye imagen Docker
4. ✅ Escanea vulnerabilidades de la imagen
5. ✅ Trigger deploy en Render

---

## 🔄 Pipeline Completo

El workflow hace estos pasos:

### 1️⃣ Tests
```yaml
- Run npm test
- Verifica que el código funciona
```

### 2️⃣ Security Scan del Código
```yaml
- Escanea código con npm audit
- Detecta dependencias vulnerables
```

### 3️⃣ Build Docker
```yaml
- Construye imagen Docker
- Verifica que el build funciona
```

### 4️⃣ Docker Security Scan
```yaml
- Escanea la imagen con Trivy
- Detecta vulnerabilidades en la imagen
```

### 5️⃣ Deploy
```yaml
- Trigger deploy en Render
- Render hace pull y despliega
```

---

## 📝 Archivos Importantes

### `.github/workflows/deploy.yml`
Pipeline de CI/CD con todos los pasos.

### `Dockerfile`
Define cómo construir tu contenedor (multi-stage build optimizado).

### `render.yaml`
Configuración de Render (lee automáticamente este archivo).

---

## 🧪 Probar Localmente

### Ejecutar tests:
```bash
npm test
```

### Construir Docker:
```bash
docker build -t cicd-demo .
```

### Ejecutar contenedor:
```bash
docker run -p 3000:3000 cicd-demo
```

### Escanear seguridad:
```bash
# Instalar trivy primero
brew install aquasecurity/trivy/trivy  # macOS
# o descarga de: https://github.com/aquasecurity/trivy

# Escanear
trivy image cicd-demo
```

---

## 🎨 Personalizar el Pipeline

### Añadir más tests

Edita `.github/workflows/deploy.yml`:

```yaml
- name: Run tests
  run: |
    npm test
    npm run test:integration  # Añade esto
    npm run test:e2e         # O esto
```

### Cambiar cuando se ejecuta

```yaml
on:
  push:
    branches:
      - main
      - develop  # Añade más branches
  pull_request:
    branches:
      - main
```

### Añadir notificaciones

```yaml
- name: Notify Slack
  if: failure()
  run: |
    curl -X POST -H 'Content-type: application/json' \
      --data '{"text":"Deploy failed!"}' \
      ${{ secrets.SLACK_WEBHOOK }}
```

---

## 📊 Ver Resultados

### GitHub Actions
- Tu repo → **Actions** → verás cada ejecución
- Click en una ejecución → ves cada paso
- Logs detallados de todo

### Render
- Dashboard → tu servicio → **Events**
- Logs en vivo en **Logs**
- Métricas en **Metrics**

---

## 🔒 Seguridad

El pipeline incluye:

### 1. Dependency Scanning
```bash
npm audit --audit-level=high
```
Falla si hay vulnerabilidades críticas.

### 2. Image Scanning
```bash
trivy image --severity HIGH,CRITICAL
```
Escanea la imagen Docker por CVEs.

### 3. Secrets Detection
GitHub detecta automáticamente secrets en commits.

---

## 🐛 Troubleshooting

### Pipeline falla en tests
```bash
# Ejecuta localmente primero
npm test
```

### Build de Docker falla
```bash
# Prueba localmente
docker build -t test .
```

### Deploy hook no funciona
1. Verifica que el secret `RENDER_DEPLOY_HOOK` esté bien
2. La URL debe empezar con `https://api.render.com/deploy/`

### Render no encuentra Dockerfile
Asegúrate que `Dockerfile` está en la raíz del repo.

---

## 💰 Costos

**GRATIS** para proyectos pequeños:
- ✅ GitHub Actions: 2000 minutos/mes gratis
- ✅ Render: Plan free disponible

---

## 🎯 Comparación

| | Este Setup | Netlify | AWS ECS |
|---|-----------|---------|---------|
| **Facilidad** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| **Control** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Docker** | ✅ | ❌ | ✅ |
| **Pipeline custom** | ✅ | Limitado | ✅ |
| **Costo** | GRATIS | GRATIS | ~$8/mes |

---

## ✅ Checklist

- [ ] Código en GitHub
- [ ] Web Service creado en Render
- [ ] Deploy Hook copiado
- [ ] Secret `RENDER_DEPLOY_HOOK` añadido en GitHub
- [ ] Push a main → pipeline se ejecuta
- [ ] Todos los pasos pasan (verde)
- [ ] App funcionando en Render

---

## 🚀 Próximos Pasos (Opcional)

### Añadir Base de Datos
```yaml
# En render.yaml
databases:
  - name: mydb
    databaseName: myapp
    user: myuser
```

### Múltiples Ambientes
```yaml
# Crear servicio de staging
- type: web
  name: cicd-demo-staging
  branch: develop
```

### Monitoreo
Añadir step para enviar métricas a Datadog/New Relic.

---

**¡Listo! Ahora tienes un pipeline profesional pero manejable.** 🎉

**Es el punto medio perfecto entre simplicidad y control.**
