# 📦 Despachos y Ventas App - Sistema de Gestión de Despachos y Ventas

Aplicación para consulta de despachos y ventas.  
Monorepo que contiene el frontend, dos backends (despachos y ventas) y la infraestructura como código.

## Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Microservicios](#microservicios)
- [Stack Tecnológico](#stack-tecnológico)
- [Patrones y Estándares](#patrones-y-estándares)
- [Transacciones Distribuidas](#transacciones-distribuidas)
- [Manejo de Errores](#manejo-de-errores)
- [Infraestructura](#infraestructura)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración del Entorno](#configuración-del-entorno)
- [Ejecución Local](#ejecución-local)
- [CI/CD y Observabilidad](#cicd-y-observabilidad)
- [Pruebas](#pruebas)
- [Frontend](#frontend)
- [Roadmap](#roadmap)
- [Contribución](#contribución)

---

## Descripción General

Despacho Project es un sistema de gestión integral que combina un **frontend React** con dos **microservicios Spring Boot** independientes para gestionar operaciones de despachos y ventas. El sistema está completamente contenerizado y desplegado en **AWS Fargate** utilizando infraestructura como código con **Terraform** y un pipeline de CI/CD automatizado con **GitHub Actions**.

### Problema que resuelve

Permite a las empresas gestionar de forma separada y escalable las operaciones de despacho y ventas, con una interfaz de usuario moderna y despliegue automatizado en la nube.

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    VPC (10.0.0.0/16)                      │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │              Public Subnet (10.0.1.0/24)           │  │   │
│  │  │  ┌──────────────────────────────────────────────┐  │  │   │
│  │  │  │            ECS Fargate Cluster               │  │  │   │
│  │  │  │  ┌────────────────────────────────────────┐  │  │  │   │
│  │  │  │  │  Task: despacho-project-app            │  │  │  │   │
│  │  │  │  │  ├── frontend (Nginx, puerto 80)       │  │  │  │   │
│  │  │  │  │  ├── backend-despachos (puerto 8080)   │  │  │  │   │
│  │  │  │  │  └── backend-ventas (puerto 8081)      │  │  │  │   │
│  │  │  │  └────────────────────────────────────────┘  │  │  │   │
│  │  │  └──────────────────────────────────────────────┘  │  │   │
│  │  │                                                     │  │   │
│  │  │  ┌──────────────────────────────────────────────┐  │  │   │
│  │  │  │    EC2 Instance (MySQL 8.0)                  │  │  │   │
│  │  │  │    - Docker container con MySQL              │  │  │   │
│  │  │  │    - Puerto 3306 expuesto internamente       │  │  │   │
│  │  │  └──────────────────────────────────────────────┘  │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                                                           │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │              ECR Repositories                       │  │   │
│  │  │  - despacho-project-backend-despachos               │  │   │
│  │  │  - despacho-project-backend-ventas                  │  │   │
│  │  │  - despacho-project-frontend                        │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Comunicación

1. **Usuario** → Frontend (React) alojado en Nginx
2. **Frontend** → Backend APIs mediante HTTP (puertos 8080 y 8081)
3. **Backends** → MySQL en EC2 (puerto 3306) para persistencia
4. **Logs** → Envío a CloudWatch Logs para monitoreo centralizado

---

## Microservicios

### Backend Despachos (`despacho-service`)
- **Puerto:** 8080
- **Responsabilidad:** Gestión de despachos, seguimiento de envíos, logística
- **Endpoints documentados:** Swagger UI disponible en `/swagger-ui.html`

### Backend Ventas (`venta-service`)
- **Puerto:** 8081
- **Responsabilidad:** Gestión de ventas, facturación, clientes
- **Endpoints documentados:** Swagger UI disponible en `/swagger-ui.html`

### Frontend (`frontend`)
- **Tecnología:** React 18 + Vite + TailwindCSS
- **Servidor:** Nginx (servidor web ligero y rápido)
- **Routing:** React Router DOM v6
- **Estado:** React Hooks

---

## Stack Tecnológico

| Capa | Tecnologías |
|------|-------------|
| **Frontend** | React 18, Vite 5, TailwindCSS 3, pnpm, Nginx |
| **Backend** | Java 21, Spring Boot 3.x, Spring Data JPA, Maven |
| **Base de Datos** | MySQL 8.0 (Oracle) en contenedor Docker |
| **Infraestructura** | AWS (VPC, ECS Fargate, ECR, EC2, CloudWatch), Terraform |
| **CI/CD** | GitHub Actions, Docker Build, ECS Deployment |
| **Health Checks** | Spring Boot Actuator, Swagger UI, netcat (nc) |
| **Documentación APIs** | SpringDoc OpenAPI (Swagger) |

### Dependencias Frontend
```json
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "react-router-dom": "^6.24.1",
  "react-hook-form": "^7.52.1",
  "react-icons": "^5.1.0",
  "axios": "^1.6.8",
  "sweetalert2": "^11.11.0"
}
```

### Dependencias Backend (Spring Boot Starter)
- `spring-boot-starter-web`
- `spring-boot-starter-data-jpa`
- `spring-boot-starter-actuator` (health checks)
- `mysql-connector-java`
- `springdoc-openapi-starter-webmvc-ui` (Swagger)

---

## Patrones y Estándares

### Patrones de Diseño
- **API Gateway implícito:** El frontend consume directamente los dos microservicios
- **Database per Service:** Cada microservicio tiene su propia base de datos (actualmente comparten MySQL pero aislado por esquema)
- **Service Discovery:** No implementado (comunicación directa por IP)
- **Configuración externalizada:** Variables de entorno para credenciales y conexiones

### Estándares de Código
- **Frontend:** ESLint + Prettier
- **Backend:** Estándar Java 21, convenciones Spring Boot

---

## Transacciones Distribuidas

**Estado actual:** No se implementan transacciones distribuidas entre microservicios. Cada servicio gestiona sus propias transacciones locales.

### Propuesta de implementación futura (SAGA Pattern)
Para operaciones que cruzan ambos servicios (ej. crear venta y agendar despacho), se sugiere implementar:
- **Coreografía de eventos** con RabbitMQ (ya desplegado en infraestructura pero no integrado)
- **Orquestación con temporal.io** o **AWS Step Functions**

### Estrategia actual para consistencia
- **Eventual consistency:** Si falla una operación secundaria, se registra en logs y se alerta
- **Circuit Breaker:** Usando Resilience4j en futuras iteraciones

---

## Manejo de Errores

### Estrategias implementadas

| Componente | Mecanismo | Descripción |
|------------|-----------|-------------|
| **Backend** | `spring.sql.init.continue-on-error=true` | No falla si hay errores en scripts SQL iniciales |
| **Backend** | `spring.datasource.hikari.initializationFailTimeout=-1` | Espera indefinidamente a que MySQL esté disponible |
| **Backend** | Health checks con `/swagger-ui.html` | ECS monitorea la salud del servicio |
| **Backend** | Entrypoint con `nc -z $DB_HOST 3306` | Espera activa a MySQL antes de iniciar Spring Boot |
| **Frontend** | `HEALTHCHECK` en Nginx | ECS sabe si el frontend está vivo |
| **Frontend** | `dependsOn` (ECS) | El frontend espera a que los backends inicien |

### Manejo de fallos específicos

```
MySQL no disponible al inicio:
  → Spring Boot Hikari espera (-1 timeout)
  → Los health checks fallarán
  → ECS reiniciará el contenedor (hasta 5 reintentos, startPeriod 120s)
  → MySQL eventualmente arranca (EC2 tarda ~2 minutos)
```

### Logging y monitoreo
- **Logs centralizados:** AWS CloudWatch Logs (grupo `/ecs/despacho-project`)
- **Streams individuales:** backend-despachos, backend-ventas, frontend
- **Retención:** 7 días

---

## Infraestructura

### Recursos AWS creados con Terraform

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| **VPC** | `despacho-project-vpc` | Red aislada (10.0.0.0/16) |
| **Subred Pública** | `despacho-project-subnet` | 10.0.1.0/24, auto-asign IP pública |
| **Internet Gateway** | `despacho-project-igw` | Salida a internet |
| **Route Table** | `despacho-project-rt` | Enruta tráfico 0.0.0.0/0 al IGW |
| **Security Group** | `despacho-project-sg` | Puertos 22, 80, 8080, 8081, 3306 abiertos |
| **EC2 MySQL** | `despacho-project-mysql` | t3.micro, 30GB gp3, user_data con Docker |
| **ECR Repositories** | 3 repos (backend, ventas, frontend) | Almacén de imágenes Docker |
| **ECS Cluster** | `despacho-project-cluster` | Fargate, modo awsvpc |
| **ECS Task Definition** | `despacho-project-app` | CPU 1024, RAM 2048, 3 contenedores |
| **ECS Service** | `app` | Desired count 1, auto-reemplazo |
| **CloudWatch Log Group** | `/ecs/despacho-project` | Retención 7 días |

### Rol IAM
- **LabRole** (proporcionado por AWS Academy) con permisos para ECS, ECR, CloudWatch

---

## Estructura del Proyecto

```
despacho-project/
├── .github/
│   └── workflows/
│       └── cd.yml                    # Pipeline CI/CD de GitHub Actions
├── backend/
│   ├── despacho-service/
│   │   ├── Dockerfile                # Multi-stage, netcat health check
│   │   ├── pom.xml                   # Dependencias Spring Boot
│   │   ├── src/
│   │   │   └── main/
│   │   │       └── resources/
│   │   │           └── application.properties
│   │   └── ...
│   └── venta-service/
│       ├── Dockerfile                # Multi-stage, netcat health check
│       ├── pom.xml
│       ├── src/
│       └── ...
├── frontend/
│   ├── Dockerfile                    # Node 22 + pnpm + Nginx
│   ├── nginx.conf                    # Configuración SPA + caching
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── .dockerignore
│   ├── index.html
│   ├── vite.config.js
│   ├── tailwind.config.js
│   ├── src/
│   │   ├── App.jsx
│   │   ├── main.jsx
│   │   ├── components/
│   │   ├── pages/
│   │   └── ...
│   └── ...
└── infrastructure/
    ├── main.tf                       # Recursos AWS completos
    ├── variables.tf
    ├── terraform.tfvars.example      # Plantilla de variables
    ├── terraform.tfvars              # NO SUBIR (valores reales)
    └── outputs.tf                    # (opcional)
```

---

## Configuración del Entorno

### Variables de entorno para los backends (inyectadas en ECS)

| Variable | Propósito | Ejemplo |
|----------|-----------|---------|
| `SPRING_DATASOURCE_URL` | Conexión JDBC | `jdbc:mysql://10.0.1.xxx:3306/despachodb?...` |
| `SPRING_DATASOURCE_USERNAME` | Usuario MySQL | `root` |
| `SPRING_DATASOURCE_PASSWORD` | Contraseña | (secreto) |
| `DB_HOST` | IP privada de EC2 MySQL | `10.0.1.xxx` |

### Archivo `terraform.tfvars` (requerido localmente)

```hcl
key_pair_name = "vockey"              # Key pair de AWS Academy
db_password   = "TuClaveSegura123"
db_name       = "despachodb"
```

### Secrets en GitHub (para CI/CD)

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Del laboratorio Academy |
| `AWS_SECRET_ACCESS_KEY` | Del laboratorio Academy |
| `AWS_SESSION_TOKEN` | Del laboratorio Academy |
| `AWS_ACCOUNT_ID` | Tu Account ID (12 dígitos) |

---

## Ejecución Local

### Requisitos previos
- Docker Desktop
- Node.js 22 + pnpm (para frontend)
- Java 17 + Maven (para backends)
- MySQL 8.0 local (opcional)

### Backends (locales con Docker)

```bash
# Construir imagen
docker build -t despacho-backend-test ./backend/despacho-service

# Ejecutar (requiere MySQL local o variable DB_HOST)
docker run -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/testdb \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=password \
  despacho-backend-test
```

### Frontend (local)

```bash
cd frontend
pnpm install
pnpm dev   # Abre http://localhost:5173
pnpm build # Genera carpeta dist/
```

### Frontend con Docker (prueba local)

```bash
docker build -t despacho-frontend-test ./frontend
docker run -p 8080:80 despacho-frontend-test
```

---

## CI/CD y Observabilidad

### Pipeline de GitHub Actions (`.github/workflows/cd.yml`)

**Trigger:** Push a rama `main`

**Jobs:**
1. **Checkout** del código
2. **Configurar credenciales AWS** (usando secrets)
3. **Login en ECR** (autenticación Docker)
4. **Build y push** de 3 imágenes (backend-despachos, backend-ventas, frontend)
5. **Forzar nuevo despliegue** en ECS (`update-service --force-new-deployment`)

**Duración típica:** 3-5 minutos

### Observabilidad con CloudWatch

| Recurso | Cómo acceder |
|---------|---------------|
| **Logs de contenedores** | CloudWatch → Log groups → `/ecs/despacho-project` |
| **Métricas de ECS** | CloudWatch → Metrics → ECS |
| **Health checks** | ECS → Tasks → Ver "Health status" |
| **Estado de servicios** | ECS → Clusters → Servicio app |

### Comandos útiles (AWS CLI)

```bash
# Ver logs de backend-despachos
aws logs get-log-events --log-group-name /ecs/despacho-project \
  --log-stream-name backend-despachos/xxxx

# Forzar despliegue manual
aws ecs update-service --cluster despacho-project-cluster \
  --service app --force-new-deployment

# Obtener IP pública de la tarea
TASK_ARN=$(aws ecs list-tasks --cluster despacho-project-cluster \
  --query "taskArns[0]" --output text)
aws ecs describe-tasks --cluster despacho-project-cluster \
  --tasks $TASK_ARN --query "tasks[0].attachments[0].details[?name=='publicIPv4'].value"
```

---

## Pruebas

### Backend (Spring Boot)
```bash
cd backend/despacho-service
mvn test
```

### Frontend (React - pruebas básicas)
```bash
cd frontend
pnpm lint      # ESLint
pnpm build     # Verifica que build funciona
```

### Pruebas de integración (post-despliegue)

```bash
# Probar health checks
curl http://<IP_PUBLICA>:8080/swagger-ui.html
curl http://<IP_PUBLICA>:8081/swagger-ui.html
curl http://<IP_PUBLICA>

# Probar endpoints concretos (ejemplo)
curl http://<IP_PUBLICA>:8080/api/despachos
```

---

## Frontend

### Características
- **React 18** con componentes funcionales y hooks
- **React Router DOM v6** para navegación SPA
- **TailwindCSS 3** para estilos utilitarios
- **React Hook Form** para manejo de formularios
- **React Icons** para iconografía
- **Axios** para peticiones HTTP
- **SweetAlert2** para alertas y modales

### Build con pnpm
```bash
pnpm install
pnpm run build   # Genera dist/ optimizado
```

### Servidor Nginx (producción)
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;  # Soporte React Router
    # Cache de assets estáticos por 1 año
    location ~* \.(js|css|png|jpg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Variables de entorno (Vite)
Crear `.env.production`:
```env
VITE_API_DESPACHOS_URL=http://<IP_PUBLICA>:8080
VITE_API_VENTAS_URL=http://<IP_PUBLICA>:8081
```

---

## Roadmap

### ✅ Implementado
- [x] Microservicios Spring Boot con JPA
- [x] Frontend React con Vite y Tailwind
- [x] Contenerización completa (Docker multi-stage)
- [x] Infraestructura AWS con Terraform (VPC, ECS Fargate, ECR, EC2 MySQL)
- [x] CI/CD con GitHub Actions (build + push + deploy)
- [x] Health checks y logs centralizados (CloudWatch)
- [x] Espera activa a MySQL en entrypoint
- [x] Configuración externalizada (variables de entorno)

### En progreso / Planificado
- [ ] Application Load Balancer (ALB) para endpoint fijo
- [ ] Dominio personalizado + SSL/TLS (AWS Certificate Manager)
- [ ] Migración a AWS RDS (MySQL gestionado)
- [ ] Integración con RabbitMQ para eventos asíncronos
- [ ] Circuit Breaker con Resilience4j
- [ ] Pruebas de carga con k6 o JMeter
- [ ] Dashboard de monitoreo con Grafana + Prometheus
- [ ] Terraform remoto backend (S3 + DynamoDB)

### Ideas futuras
- [ ] Patrón SAGA para transacciones distribuidas
- [ ] Infraestructura multi-región (DR)
- [ ] Blue/Green deployments con ECS
- [ ] Frontend con autenticación (Auth0 / AWS Cognito)

---

## Contribución

### Flujo de trabajo

1. **Crea una rama desde `develop`:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/nueva-funcionalidad
   ```

2. **Realiza cambios y commits:**
   ```bash
   git add .
   git commit -m "feat: descripción del cambio"
   ```

3. **Push y Pull Request a `develop`:**
   ```bash
   git push origin feature/nueva-funcionalidad
   ```
   (Crear PR en GitHub)

4. **Después de revisión, merge a `main`:**
   - GitHub Actions automáticamente desplegará a AWS

### Convenciones de commits
- `feat:` Nueva funcionalidad
- `fix:` Corrección de error
- `docs:` Documentación
- `infra:` Cambios en Terraform/Docker
- `ci:` Cambios en GitHub Actions

---

## Notas adicionales para AWS Academy

- Las credenciales del Learner Lab expiran al detener el laboratorio.
- Usa `End Lab` para pausar recursos y no consumir crédito.
- **No uses `Reset`** a menos que quieras perder toda la configuración.
- El rol `LabRole` debe existir en tu cuenta (viene por defecto).

---

## Contribuidores

<a href="https://github.com/Rorrop24">
  <img src="https://github.com/Rorrop24.png" width="60px;" alt="Rodrigo Catalan"/>
</a>

<a href="https://github.com/XxXCamilongoXxX">
  <img src="https://github.com/XxXCamilongoXxX.png" width="60px;" alt="Camilo "/>
</a>

---

## Contacto y Soporte

Para problemas técnicos:
- Revisa los logs en CloudWatch Logs
- Verifica el estado de las tareas en ECS Console
- Comprueba que MySQL esté corriendo (`docker ps` en EC2)
