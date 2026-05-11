# Despachos y Ventas App

Aplicación para consulta de despachos y ventas.  
Monorepo que contiene el frontend, dos backends (despachos y ventas) y la infraestructura como código.

## Estructura del repositorio
.
├── backend/
│ ├── despachos-api/ # Backend de Despachos (Spring Boot)
│ └── ventas-api/ # Backend de Ventas (Spring Boot)
├── frontend/ # Aplicación cliente (Vite, React)
├── infrastructure/ # Infraestructura como código (Terraform)
├── .github/workflows/ # Pipelines de CI/CD
└── README.md

## Requisitos previos

- **Java 17**
- **Maven/Gradle**
- **Node.js**
- **Docker** y **Docker Compose**
- **Terraform**

## Configuración inicial

1. Clona el repositorio:
   ```bash
   cd Desktop
   git clone https://github.com/EstebanPachecoVega/despacho-project.git
   cd despacho-project