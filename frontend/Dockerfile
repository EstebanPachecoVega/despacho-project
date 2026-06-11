# Multistage
# Stage 1: Builder
FROM node:22-alpine AS builder

# Habilitar corepack y preparar pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /build

# Copiar archivos de dependencias primero para aprovechar el cache de Docker
COPY package.json pnpm-lock.yaml* ./

# Instalar dependencias con pnpm
RUN pnpm install --frozen-lockfile --ignore-scripts

# Deshabilitar scripts postinstall para evitar problemas con Husky
RUN pnpm config set ignore-scripts true

# Copiar el resto del código fuente
COPY . .

# Construir la aplicación (asume que el build genera /dist dentro de /build)
RUN pnpm run build 

# Stage 2: Servir con Nginx
FROM nginx:alpine
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
CMD wget --quiet --tries=1 --spider http://localhost || exit 1

CMD ["nginx", "-g", "daemon off;"]