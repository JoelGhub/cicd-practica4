# Etapa 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar package files
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Etapa 2: Production
FROM node:18-alpine

WORKDIR /app

# Copiar dependencias desde builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código de la aplicación
COPY . .

# Exponer puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Usuario no root por seguridad
USER node

# Comando de inicio
CMD ["npm", "start"]
