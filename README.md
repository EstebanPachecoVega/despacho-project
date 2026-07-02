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

Despacho Project es un sistema de gestión integral que combina un **frontend React** con dos **microservicios Spring Boot** independientes para gestionar operaciones de despachos y ventas. El sistema está completamente contenerizado y desplegado en **AWS (EKS)** utilizando infraestructura como código con **Terraform** y un pipeline de CI/CD automatizado con **GitHub Actions**.

### Problema que resuelve

Permite a las empresas gestionar de forma separada y escalable las operaciones de despacho y ventas, con una interfaz de usuario moderna y despliegue automatizado en la nube.

---

## Arquitectura del Sistema

```
┌───────────────────────────────────────────────────────────────────────────┐
│                            AWS Cloud                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                       VPC (10.0.0.0/16)                             │  │
│  │                                                                     │  │
│  │  ┌───────── Subredes Públicas (10.0.1.0/24, 10.0.2.0/24) ────────┐  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │    K8s LoadBalancer (frontend, puerto 80)               │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            Internet Gateway (IGW)                       │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            NAT Gateway (EIP)                            │  │  │  │
│  │  │  │            (salida a internet desde privado)            │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │  ┌──── Subredes Privadas (10.0.3.0/24, 10.0.4.0/24) ────────────┐  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            EKS Cluster (K8s 1.30)                       │  │  │  │
│  │  │  │  ┌──────────────────────────────────────────────────┐   │  │  │  │
│  │  │  │  │  Node Group (t3.medium, 1-3 nodos)              │   │  │  │  │
│  │  │  │  │  ├── frontend Pod (80) ← LoadBalancer           │   │  │  │  │
│  │  │  │  │  ├── back-despachos Pod (8080) ← ClusterIP      │   │  │  │  │
│  │  │  │  │  └── back-ventas Pod (8081) ← ClusterIP         │   │  │  │  │
│  │  │  │  └──────────────────────────────────────────────────┘   │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            EC2 MySQL (t3.micro)                         │  │  │  │
│  │  │  │            - Docker MySQL 8.0                           │  │  │  │
│  │  │  │            - Puerto 3306                                │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │  ┌───────────────────────────────────────────────────────────────┐  │  │
│  │  │              ECR Repositories                                 │  │  │
│  │  │  - backend-despachos / backend-ventas / frontend              │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │  ┌───────────────────────────────────────────────────────────────┐  │  │
│  │  │              CloudWatch                                       │  │  │
│  │  │  - Logs: EKS control plane (/aws/eks/...)                     │  │  │
│  │  │  - Alarmas: errores EKS, CPU/status checks EC2                │  │  │
│  │  │  - Dashboard: métricas EKS + EC2 MySQL + logs                 │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Flujo de Comunicación (EKS)

1. **Usuario** → K8s LoadBalancer → Pod frontend (puerto 80)
2. **Frontend** → Backend APIs via ClusterIP (back-despachos:8080, back-ventas:8081)
3. **Backends** → MySQL EC2 en subred privada (puerto 3306, IP privada)
4. **Logs** → CloudWatch Logs grupo `/aws/eks/despacho-project-eks/cluster`

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
| **Infraestructura** | AWS (VPC, ECR, EC2, CloudWatch, EKS), Terraform |
| **CI/CD** | GitHub Actions, Docker Build, EKS Deployment |
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
- **Database per Service:** Cada microservicio gestiona sus propias tablas dentro de la base de datos `despachodb` (tablas `despacho` y `venta`)
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
| **Backend** | Health checks con `/actuator/health` | Spring Boot Actuator para readiness/liveness probes |
| **Backend** | Entrypoint con `nc -z $DB_HOST 3306` | Espera activa a MySQL antes de iniciar Spring Boot |
| **Frontend** | `HEALTHCHECK` en Nginx | K8s readiness/liveness probe monitorea el frontend |
| **Frontend** | Init container `wait-for-mysql` | Espera a que MySQL esté disponible antes de iniciar los backends |

### Manejo de fallos específicos

```
MySQL no disponible al inicio:
  → Spring Boot Hikari espera (-1 timeout)
  → Los health checks fallarán
  → K8s reiniciará el contenedor (restartPolicy: Always)
  → MySQL eventualmente arranca (EC2 tarda ~2 minutos)

Orden de arranque en K8s:
  → init container wait-for-mysql (busybox): espera puerto 3306
  → init container create-schemas (mysql:8-oracle): CREATE SCHEMA IF NOT EXISTS
  → Contenedor principal: Hibernate crea tablas → data.sql inserta seed data
```

### Logging y monitoreo
- **Logs de EKS:** AWS CloudWatch Logs (grupo `/aws/eks/despacho-project-eks/cluster`) — api, audit, authenticator, controllerManager, scheduler
- **Alarmas:** Errores en logs de EKS, CPU y status check de MySQL
- **Dashboard:** `despacho-project-dashboard` en CloudWatch con métricas de EKS, EC2 MySQL y logs en vivo
- **Retención:** 7 días

---

## Infraestructura

### Recursos AWS creados con Terraform

| Recurso | Nombre | Propósito |
|---------|--------|-----------|
| **VPC** | `despacho-project-vpc` | Red aislada (10.0.0.0/16) |
| **Subred Pública** | `despacho-project-subnet` (x2) | 10.0.1.0/24 y 10.0.2.0/24, auto-asign IP pública |
| **Subred Privada** | `despacho-project-private` (x2) | 10.0.3.0/24 y 10.0.4.0/24, sin IP pública |
| **Internet Gateway** | `despacho-project-igw` | Salida a internet desde subredes públicas |
| **NAT Gateway** | `despacho-project-nat` | Salida a internet desde subredes privadas |
| **Elastic IP** | `despacho-project-eip` | IP fija para el NAT Gateway |
| **Route Tables** | pública + privada | Enrutan tráfico al IGW y NAT respectivamente |
| **ALB** | — | *Eliminado. K8s LoadBalancer crea su propio balanceador.* |
| **Target Group** | — | *Eliminado.* |
| **Security Groups** | `db-sg` | 1 SG para la base de datos MySQL |
| **EC2 MySQL** | `despacho-project-mysql` | t3.micro, 30GB gp3, en subred privada |
| **ECR Repositories** | 3 repos (backend, ventas, frontend) | Almacén de imágenes Docker |
| **EKS Cluster** | `despacho-project-eks` | Kubernetes 1.30, nodos en subredes privadas |
| **EKS Node Group** | `despacho-project-node-group` | t3.medium, 1-3 nodos |
| **CloudWatch Log Group** | `/aws/eks/despacho-project-eks/cluster` | Logs de control plane de EKS |
| **CloudWatch Alarmas** | 3 alarmas | Errores en logs EKS, CPU/status EC2 MySQL |
| **CloudWatch Dashboard** | `despacho-project-dashboard` | Métricas EKS, EC2 MySQL y logs |

### Rol IAM
- **LabRole** (proporcionado por AWS Academy) con permisos para ECR, EKS, CloudWatch, EC2

---

## Estructura del Proyecto

```
despacho-project/
├── .env.example                         # Variables de entorno para docker-compose
├── .env                                 # Credenciales MySQL (no se sube al repo)
├── docker-compose.yml                   # Orquestación local
├── backend/
│   ├── init.sql                         # Creación de schemas MySQL (docker-compose)
│   ├── despacho-service/
│   │   ├── .env.example                 # Variables de entorno del servicio
│   │   ├── .env                         # Credenciales (no se sube al repo)
│   │   ├── dockerfile                   # Multi-stage, netcat health check
│   │   ├── pom.xml                      # Dependencias Spring Boot
│   │   ├── mvnw / mvnw.cmd              # Maven wrapper
│   │   ├── src/
│   │   │   └── main/
│   │   │       ├── java/com/citt/
│   │   │       │   ├── controller/      # REST endpoints
│   │   │       │   ├── persistence/
│   │   │       │   │   ├── entity/      # JPA entities
│   │   │       │   │   ├── repository/  # Spring Data repos
│   │   │       │   │   └── services/    # Lógica de negocio
│   │   │       │   └── exceptions/      # Manejador global de errores
│   │   │       └── resources/
│   │   │           └── application.properties
│   │   └── ...
│   └── venta-service/
│       ├── .env.example
│       ├── .env
│       ├── dockerfile                   # Multi-stage, netcat health check
│       ├── pom.xml
│       ├── src/
│       │   └── main/
│       │       └── resources/
│       │           ├── application.properties
│       │           └── data.sql         # Seed data con 4 órdenes de compra
│       └── ...
├── frontend/
│   ├── Dockerfile                       # Node 22 + pnpm + Nginx
│   ├── default.conf.template            # Configuración Nginx con variables de entorno
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── .dockerignore
│   ├── index.html
│   ├── vite.config.js                   # Proxy a backends en desarrollo
│   ├── tailwind.config.js
│   ├── src/
│   │   ├── main.jsx                     # Entry point
│   │   ├── index.css                    # TailwindCSS
│   │   ├── Routes/
│   │   │   └── AppRoutes.jsx            # React Router
│   │   ├── componentes/
│   │   │   ├── CrudAdmin.jsx            # Dashboard principal
│   │   │   ├── Layouts/
│   │   │   │   ├── Navbar.jsx
│   │   │   │   ├── Footer.jsx
│   │   │   │   └── Carrusel.jsx
│   │   │   └── CrudAdmin/
│   │   │       ├── TableCompras.jsx      # Tabla de órdenes de compra
│   │   │       ├── TableDespachos.jsx    # Tabla de órdenes de despacho
│   │   │       ├── FormDespacho.jsx      # Crear despacho
│   │   │       ├── FormCierreDespacho.jsx # Cerrar/modificar despacho
│   │   │       ├── CardComponent.jsx     # Cards del dashboard
│   │   │       ├── SearchBar.jsx         # Búsqueda en tiempo real
│   │   │       └── Modal.jsx             # Modal genérico
│   │   └── pages/
│   │       ├── Usuarios.jsx
│   │       ├── Productos.jsx
│   │       └── Configuracion.jsx
│   └── ...
├── infrastructure/
│   ├── terraform/
│   │   ├── provider.tf               # Provider AWS
│   │   ├── variables.tf              # Variables de entrada
│   │   ├── vpc.tf                    # VPC, subredes, NAT, tablas de ruta
│   │   ├── security.tf               # Security groups (db)
│   │   ├── database.tf               # EC2 MySQL en subred privada
│   │   ├── ecr.tf                    # Repositorios ECR
│   │   ├── eks.tf                    # EKS cluster + node group
│   │   ├── cloudwatch.tf             # Alarmas, dashboard, metric filters
│   │   ├── outputs.tf                # Outputs del stack
│   │   └── terraform.tfvars          # NO SUBIR (valores reales)
│   └── k8s/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── app-configmap.yaml
│       ├── backend-despachos.yaml     # Deployment + Service + init containers
│       ├── backend-ventas.yaml        # Deployment + Service + init containers
│       └── frontend.yaml              # Deployment + LoadBalancer Service
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Integración continua (tests, lint, terraform validate)
│       ├── cd.yml                    # Despliegue continuo (push a main)
│       └── destroy.yml               # Destrucción manual de toda la infraestructura
```

---

## Configuración del Entorno

### Variables de entorno para Docker Compose (archivo `.env` raíz)

| Variable | Propósito | Ejemplo |
|----------|-----------|---------|
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MySQL | `despacho_root_2026` |
| `MYSQL_DATABASE` | Nombre de la base de datos | `despachodb` |
| `MYSQL_USER` | Usuario de la aplicación | `despacho_app` |
| `MYSQL_PASSWORD` | Contraseña del usuario | `despacho_app_2026` |

### Variables de entorno para los backends (inyectadas via K8s ConfigMap/Secrets)

| Variable | Propósito | Ejemplo |
|----------|-----------|---------|
| `SPRING_DATASOURCE_URL` | Conexión JDBC | `jdbc:mysql://10.0.3.xxx:3306/despachodb?...` |
| `SPRING_DATASOURCE_USERNAME` | Usuario MySQL | (Secreto) |
| `SPRING_DATASOURCE_PASSWORD` | Contraseña | (secreto) |
| `DB_HOST` | IP privada de EC2 MySQL | `10.0.3.xxx` |

### Archivo `terraform.tfvars` (requerido localmente)

```hcl
key_pair_name = "vockey"              # Key pair de AWS Academy
db_password   = "TuClaveSegura123"
db_name       = "despachodb"
```

### Secrets en GitHub (para CI/CD)

GitHub Actions espera estos Secrets:

- `AWS_ACCOUNT_ID`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `EKS_CLUSTER_NAME`
- `DB_HOST`
- `DB_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`

## Despliegue en AWS con Kubernetes

El directorio `k8s/` contiene los manifiestos para desplegar en EKS:

| Manifiesto | Tipo | Puerto |
|------------|------|--------|
| `namespace.yaml` | Namespace | `despacho-project` |
| `app-configmap.yaml` | ConfigMap | Configuración de base de datos |
| `backend-despachos.yaml` | Deployment + ClusterIP Service | 8080 | `wait-for-mysql` (busybox) + `create-schemas` (mysql:8-oracle) |
| `backend-ventas.yaml` | Deployment + ClusterIP Service | 8081 | `wait-for-mysql` (busybox) + `create-schemas` (mysql:8-oracle) |
| `frontend.yaml` | Deployment + LoadBalancer Service | 80 |

Los nodos EKS están en **subredes privadas** con salida a internet vía NAT Gateway.
El Service `frontend` de tipo `LoadBalancer` crea automáticamente un Classic Load Balancer en las subredes públicas.

### Requisitos para EKS

- Las subredes públicas tienen el tag `kubernetes.io/role/elb: 1`
- Las subredes privadas tienen el tag `kubernetes.io/role/internal-elb: 1`
- Ambas tienen el tag `kubernetes.io/cluster/<cluster-name>: shared`

### Despliegue manual

```bash
# Renderizar manifiestos reemplazando placeholders
mkdir -p .k8s-rendered
cp infrastructure/k8s/*.yaml .k8s-rendered/
for f in .k8s-rendered/*.yaml; do
  sed -i \
    -e "s|__ECR_REGISTRY__|${ECR_REGISTRY}|g" \
    -e "s|__PROJECT_NAME__|${PROJECT_NAME}|g" \
    -e "s|__IMAGE_TAG__|${IMAGE_TAG}|g" \
    -e "s|__DB_HOST__|${DB_HOST}|g" \
    -e "s|__DB_NAME__|${DB_NAME}|g" \
    "$f"
done

kubectl apply -k .k8s-rendered/
kubectl -n despacho-project rollout status deployment/frontend --timeout=180s
```

---

## Ejecución Local

### Requisitos previos
- Docker Desktop
- Node.js 22 + pnpm (para frontend standalone)
- Java 21 + Maven (para backends standalone, opcional)

### Con Docker Compose (recomendado)

```bash
# 1. Clonar y configurar variables de entorno
cp .env.example .env
cp backend/despacho-service/.env.example backend/despacho-service/.env
cp backend/venta-service/.env.example backend/venta-service/.env

# 2. Primer arranque (limpia volumen MySQL para cargar schemas y seed data)
docker compose down -v
docker compose up -d --build

# 3. Abrir frontend
# http://localhost:3000
```

### Backends (locales con Docker)

```bash
# Construir imagen
docker build -t despacho-backend-test ./backend/despacho-service

# Ejecutar (requiere MySQL local o variable DB_HOST)
docker run -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/testdb \
  -e SPRING_DATASOURCE_USERNAME=username \
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
docker run -p 3000:80 despacho-frontend-test
```

---

## CI/CD y Observabilidad

### Pipeline de GitHub Actions (`.github/workflows/cd.yml`)

**Trigger:** Push a rama `main`

**Jobs:**
1. **Terraform Apply** — Crea/actualiza toda la infraestructura (VPC, subredes, EKS, EC2 MySQL, etc.)
2. **Build y push** de 3 imágenes Docker a ECR (backend-despachos, backend-ventas, frontend)
3. **kubectl apply** — Renderiza y aplica los manifiestos de Kubernetes en EKS
4. **Rollout status** — Verifica que los deployments de K8s estén saludables

**Duración típica:** 5-8 minutos

### Workflow de Destroy (`.github/workflows/destroy.yml`)

**Trigger:** Manual via `workflow_dispatch` en GitHub Actions

**Requisito:** Escribir `destroy` en el campo de confirmación para ejecutar

**Jobs:**
1. **Restaurar cache** del state de Terraform
2. **Limpiar Kubernetes** (elimina namespace `despacho-project` para evitar que EKS se trabe)
3. **Terraform destroy** — Elimina todos los recursos de AWS gestionados por Terraform

**⚠️ Irreversible:** Borra VPC, subredes, EKS, EC2 MySQL, ECR, CloudWatch, etc.

### Observabilidad con CloudWatch

#### Logs

| Grupo de logs | Origen | Acceso |
|---------------|--------|--------|
| `/aws/eks/despacho-project-eks/cluster` | Plano de control de EKS (api, audit, authenticator, controllerManager, scheduler) | CloudWatch → Log groups |

#### Alarmas configuradas

| Alarma | Métrica | Umbral | Periodo |
|--------|---------|--------|---------|
| `eks-errors-high` | Errores en logs de EKS (`ERROR`, `Exception`) | > 10 | 5 min |
| `ec2-cpu-high` | CPU de MySQL EC2 | > 80% | 10 min |
| `ec2-status-failed` | Status check de EC2 | ≥ 1 | 10 min |

#### Dashboard

Disponible en CloudWatch → Dashboards → `despacho-project-dashboard`
Incluye: métricas de nodos EKS (`node_ready_count`), CPU/status de EC2 MySQL, conteo de errores en logs de EKS, y tabla con los últimos errores.

#### Comandos útiles (AWS CLI)

```bash
# Ver logs del plano de control de EKS
aws logs get-log-events --log-group-name /aws/eks/despacho-project-eks/cluster

# Obtener estado del cluster EKS
aws eks describe-cluster --name despacho-project-eks

# Ver alarmas activas
aws cloudwatch describe-alarms --state-value ALARM

# Ver dashboard
aws cloudwatch get-dashboard --dashboard-name despacho-project-dashboard
```

---

## Pruebas

### Backend (Spring Boot)
```bash
cd backend/despacho-service
./mvnw test
```

### Frontend (React - pruebas básicas)
```bash
cd frontend
pnpm lint      # ESLint
pnpm build     # Verifica que build funciona
```

### Pruebas de integración (post-despliegue)

```bash
# Obtener URL del K8s LoadBalancer
LB_HOST=$(kubectl get svc -n despacho-project frontend \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LB_HOST

# Probar health checks via LoadBalancer
curl http://$LB_HOST
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
VITE_API_DESPACHOS_URL=http://<LB_DNS>:8080
VITE_API_VENTAS_URL=http://<LB_DNS>:8081
```

---

## Roadmap

### ✅ Implementado
- [x] Microservicios Spring Boot con JPA
- [x] Frontend React con Vite y Tailwind
- [x] Contenerización completa (Docker multi-stage)
- [x] Infraestructura AWS con Terraform (VPC, ECR, EC2 MySQL, EKS)
- [x] CI/CD con GitHub Actions (build + push + deploy a EKS)
- [x] Health checks y logs centralizados (CloudWatch)
- [x] Espera activa a MySQL en entrypoint
- [x] Configuración externalizada (variables de entorno)
- [x] Subredes privadas con NAT Gateway para mayor seguridad
- [x] K8s LoadBalancer como endpoint público para el frontend
- [x] Security group para la base de datos MySQL
- [x] EKS con nodos en subredes privadas
- [x] Logs del plano de control de EKS en CloudWatch
- [x] Alarmas de CloudWatch (errores EKS, CPU/status EC2)
- [x] Dashboard de CloudWatch con métricas EKS, EC2 MySQL y logs
- [x] Seed data automático con `data.sql` (INSERT IGNORE en cada arranque)
- [x] Validación de fecha de despacho (sin fecha, sin fechas pasadas)
- [x] IDs secuenciales con `GenerationType.IDENTITY` (sin saltos)
- [x] Init containers en K8s (`wait-for-mysql` + `create-schemas`)
- [x] Manejo de errores en frontend con SweetAlert2 (loading, error, empty)
- [x] Mensajes de error intuitivos en backend (español)
- [x] Orquestación local con Docker Compose (MySQL + 2 backends + frontend)

### En progreso / Planificado
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
- [ ] Blue/Green deployments con EKS
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
- Verifica el estado de los pods en EKS (`kubectl get pods -n despacho-project`)
- Comprueba que MySQL esté corriendo (`docker ps` en EC2)
