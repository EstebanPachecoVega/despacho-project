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

Despacho Project es un sistema de gestión integral que combina un **frontend React** con dos **microservicios Spring Boot** independientes para gestionar operaciones de despachos y ventas. El sistema está completamente contenerizado y desplegado en **AWS (ECS Fargate + EKS)** utilizando infraestructura como código con **Terraform** y un pipeline de CI/CD automatizado con **GitHub Actions**.

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
│  │  ┌───────────── Subredes Públicas (10.0.1.0/24, 10.0.2.0/24) ────┐  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            Application Load Balancer                    │  │  │  │
│  │  │  │            (puerto 80 -> target group)                  │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │              Internet Gateway (IGW)                     │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │              NAT Gateway (EIP)                          │  │  │  │
│  │  │  │              (salida a internet desde privado)          │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  │  ┌──────── Subredes Privadas (10.0.3.0/24, 10.0.4.0/24) ─────────┐  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            ECS Fargate (app)                            │  │  │  │
│  │  │  │  ┌──────────────────────────────────────────────────┐   │  │  │  │
│  │  │  │  │  Task: frontend (80) ← ALB target group          │   │  │  │  │
│  │  │  │  │  ├── backend-despachos (8080, via localhost)     │   │  │  │  │
│  │  │  │  │  └── backend-ventas (8081, via localhost)        │   │  │  │  │
│  │  │  │  └──────────────────────────────────────────────────┘   │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            EC2 MySQL (t3.micro)                         │  │  │  │
│  │  │  │            - Docker MySQL 8.0                           │  │  │  │
│  │  │  │            - Puerto 3306 (solo ECS + EKS)               │  │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘  │  │  │
│  │  │                                                               │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐  │  │  │
│  │  │  │            EKS Cluster                                  │  │  │  │
│  │  │  │  - Node group (t3.medium, 1-3 nodos)                    │  │  │  │
│  │  │  │  - frontend: LoadBalancer (port 80)                     │  │  │  │
│  │  │  │  - back-despachos: ClusterIP (8080)                     │  │  │  │
│  │  │  │  - back-ventas: ClusterIP (8081)                        │  │  │  │
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
│  │  │  - Logs: ECS (/ecs/...), EKS control plane (/aws/eks/...)     │  │  │
│  │  │  - Alarmas: CPU, memoria, errores, status checks              │  │  │
│  │  │  - Dashboard: métricas + logs de error                        │  │  │
│  │  └───────────────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Flujo de Comunicación (ECS)

1. **Usuario** → ALB (puerto 80) → ECS Task (frontend Nginx, puerto 80)
2. **Frontend** → Backend APIs via `localhost` (misma tarea ECS, puertos 8080/8081)
3. **Backends** → MySQL EC2 en subred privada (puerto 3306, IP privada)
4. **Logs** → CloudWatch Logs grupo `/ecs/despacho-project`
5. **Alarmas** → CloudWatch monitorea CPU, memoria, errores, status checks

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
- **Logs de ECS:** AWS CloudWatch Logs (grupo `/ecs/despacho-project`) — streams: backend-despachos, backend-ventas, frontend
- **Logs de EKS:** AWS CloudWatch Logs (grupo `/aws/eks/despacho-project-eks/cluster`) — api, audit, authenticator, controllerManager, scheduler
- **Alarmas:** CPU y memoria de ECS, errores en logs, CPU y status check de MySQL
- **Dashboard:** `despacho-project-dashboard` en CloudWatch con métricas y logs en vivo
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
| **ALB** | `despacho-project-alb` | Application Load Balancer público (puerto 80) |
| **Target Group** | `despacho-project-frontend-tg` | Target group para frontend ECS (tipo IP) |
| **Security Groups** | `alb-sg`, `ecs-tasks-sg`, `db-sg` | 3 SGs separados: ALB público, ECS privado, DB privado |
| **EC2 MySQL** | `despacho-project-mysql` | t3.micro, 30GB gp3, en subred privada |
| **ECR Repositories** | 3 repos (backend, ventas, frontend) | Almacén de imágenes Docker |
| **ECS Cluster** | `despacho-project-cluster` | Fargate, modo awsvpc |
| **ECS Task Definition** | `despacho-project-app` | CPU 1024, RAM 4096, 3 contenedores |
| **ECS Service** | `app` | Desired count 1, con ALB |
| **EKS Cluster** | `despacho-project-eks` | Kubernetes 1.30, nodos en subredes privadas |
| **EKS Node Group** | `despacho-project-node-group` | t3.medium, 1-3 nodos |
| **CloudWatch Log Group** | `/ecs/despacho-project` | Logs de ECS, retención 7 días |
| **CloudWatch Log Group** | `/aws/eks/despacho-project-eks/cluster` | Logs de control plane de EKS |
| **CloudWatch Alarmas** | 5 alarmas | CPU/memoria ECS, CPU/status EC2, errores en logs |
| **CloudWatch Dashboard** | `despacho-project-dashboard` | Métricas y logs recientes |

### Rol IAM
- **LabRole** (proporcionado por AWS Academy) con permisos para ECS, ECR, EKS, CloudWatch, EC2

---

## Estructura del Proyecto

```
despacho-project/
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Integración continua (tests, lint, terraform validate)
│       ├── cd.yml                    # Despliegue continuo (push a main)
│       └── destroy.yml              # Destrucción manual de toda la infraestructura
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
├── infrastructure/
│   ├── terraform/
│   │   ├── provider.tf               # Provider AWS
│   │   ├── variables.tf              # Variables de entrada
│   │   ├── vpc.tf                    # VPC, subredes, NAT, tablas de ruta
│   │   ├── security.tf               # Security groups (alb, ecs-tasks, db)
│   │   ├── database.tf               # EC2 MySQL en subred privada
│   │   ├── ecr.tf                    # Repositorios ECR
│   │   ├── ecs.tf                    # ECS + ALB + CloudWatch logs
│   │   ├── eks.tf                    # EKS cluster + node group
│   │   ├── cloudwatch.tf             # Alarmas, dashboard, metric filters
│   │   ├── outputs.tf                # Outputs del stack
│   │   └── terraform.tfvars          # NO SUBIR (valores reales)
│   └── k8s/
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       ├── app-configmap.yaml
│       ├── backend-despachos.yaml
│       ├── backend-ventas.yaml
│       └── frontend.yaml
```

---

## Configuración del Entorno

### Variables de entorno para los backends (inyectadas en ECS)

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
| `backend-despachos.yaml` | Deployment + ClusterIP Service | 8080 |
| `backend-ventas.yaml` | Deployment + ClusterIP Service | 8081 |
| `frontend.yaml` | Deployment + LoadBalancer Service | 80 |

Los nodos EKS están en **subredes privadas** con salida a internet vía NAT Gateway.
El Service `frontend` de tipo `LoadBalancer` crea automáticamente un Classic Load Balancer en las subredes públicas.

### Requisitos para EKS

- Las subredes públicas tienen el tag `kubernetes.io/role/elb: 1`
- Las subredes privadas tienen el tag `kubernetes.io/role/internal-elb: 1`
- Ambas tienen el tag `kubernetes.io/cluster/<cluster-name>: shared`

### Despliegue manual

```bash
kubectl apply -k infrastructure/k8s/
kubectl -n despacho-project rollout status deployment/frontend --timeout=180s
```

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
docker run -p 8080:80 despacho-frontend-test
```

---

## CI/CD y Observabilidad

### Pipeline de GitHub Actions (`.github/workflows/cd.yml`)

**Trigger:** Push a rama `main`

**Jobs:**
1. **Terraform Apply** — Crea/actualiza toda la infraestructura (VPC, subredes, ALB, ECS, EKS, etc.)
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

**⚠️ Irreversible:** Borra VPC, subredes, ALB, ECS, EKS, EC2 MySQL, ECR, CloudWatch, etc.

### Observabilidad con CloudWatch

#### Logs

| Grupo de logs | Origen | Acceso |
|---------------|--------|--------|
| `/ecs/despacho-project` | Contenedores ECS (frontend, back-despachos, back-ventas) | CloudWatch → Log groups |
| `/aws/eks/despacho-project-eks/cluster` | Plano de control de EKS (api, audit, authenticator, controllerManager, scheduler) | CloudWatch → Log groups |

#### Alarmas configuradas

| Alarma | Métrica | Umbral | Periodo |
|--------|---------|--------|---------|
| `ecs-cpu-high` | CPU de ECS | > 80% | 10 min |
| `ecs-memory-high` | Memoria de ECS | > 80% | 10 min |
| `ecs-errors-high` | Errores en logs (`ERROR`, `Exception`) | > 10 | 5 min |
| `ec2-cpu-high` | CPU de MySQL EC2 | > 80% | 10 min |
| `ec2-status-failed` | Status check de EC2 | ≥ 1 | 10 min |

#### Dashboard

Disponible en CloudWatch → Dashboards → `despacho-project-dashboard`
Incluye: métricas de CPU/memoria de ECS, CPU/status de EC2 MySQL, conteo de errores en logs, y tabla con los últimos errores.

#### Comandos útiles (AWS CLI)

```bash
# Ver logs de backend-despachos
aws logs get-log-events --log-group-name /ecs/despacho-project \
  --log-stream-name backend-despachos/xxxx

# Obtener DNS del ALB
aws elbv2 describe-load-balancers --names "despacho-project-alb" \
  --query "LoadBalancers[0].DNSName" --output text

# Forzar despliegue manual ECS
aws ecs update-service --cluster despacho-project-cluster \
  --service app --force-new-deployment

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
# Obtener el DNS del ALB
ALB_DNS=$(aws elbv2 describe-load-balancers --names "despacho-project-alb" \
  --query "LoadBalancers[0].DNSName" --output text)

# Probar health checks via ALB
curl http://$ALB_DNS

# Obtener URL del K8s LoadBalancer
LB_HOST=$(kubectl get svc -n despacho-project frontend \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LB_HOST

# Probar endpoints via ECS (necesita acceso a subred privada o usar AWS Systems Manager)
# curl http://<IP_PRIVADA_ECS>:8080/api/despachos
# curl http://<IP_PRIVADA_ECS>:8081/api/ventas
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
VITE_API_DESPACHOS_URL=http://<ALB_DNS>:8080
VITE_API_VENTAS_URL=http://<ALB_DNS>:8081
```

---

## Roadmap

### ✅ Implementado
- [x] Microservicios Spring Boot con JPA
- [x] Frontend React con Vite y Tailwind
- [x] Contenerización completa (Docker multi-stage)
- [x] Infraestructura AWS con Terraform (VPC, ECS Fargate, ECR, EC2 MySQL, EKS)
- [x] CI/CD con GitHub Actions (build + push + deploy)
- [x] Health checks y logs centralizados (CloudWatch)
- [x] Espera activa a MySQL en entrypoint
- [x] Configuración externalizada (variables de entorno)
- [x] Subredes privadas con NAT Gateway para mayor seguridad
- [x] Application Load Balancer (ALB) como endpoint fijo para ECS
- [x] Security groups segregados por capa (ALB, ECS, DB)
- [x] EKS con nodos en subredes privadas
- [x] Logs del plano de control de EKS en CloudWatch
- [x] Alarmas de CloudWatch (CPU, memoria, errores, status checks)
- [x] Dashboard de CloudWatch con métricas y logs

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
