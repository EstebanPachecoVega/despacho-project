# Despachos y Ventas App

Aplicación para consulta de despachos y ventas.  
Monorepo que contiene el frontend, dos backends (despachos y ventas) y la infraestructura como código.

## Requisitos previos

- **Java 17**
- **Maven/Gradle**
- **Node.js**
- **Docker** y **Docker Compose**
- **Terraform**
- **AWS CLI**
- **kubectl** para despliegues en Kubernetes/EKS

## Configuración inicial

1. Clona el repositorio:
   ```bash
   cd Desktop
   git clone https://github.com/EstebanPachecoVega/despacho-project.git
   cd despacho-project

## Despliegue en AWS con Kubernetes

El directorio `k8s/` contiene los manifiestos para desplegar:

- `back-despachos`
- `back-ventas`
- `frontend`

Los repositorios ECR, la base de datos MySQL y los datos utiles para despliegue se gestionan desde `infrastructure/` con Terraform. Despues de aplicar Terraform, puedes usar el output `db_private_ip` como valor del secret de GitHub `DB_HOST`.

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

`DB_USERNAME` debe ser el usuario de aplicacion, por ejemplo `despacho_app`, no `root`.
