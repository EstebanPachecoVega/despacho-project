# Kubernetes para despacho-project

Estos manifiestos despliegan los dos backends Spring Boot y el frontend en Kubernetes/EKS.

## GitHub Secrets necesarios

El workflow CD ejecuta Terraform automáticamente, por lo que solo se requieren estas credenciales AWS y la password de MySQL:

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Access Key de AWS (temporal en AWS Academy) |
| `AWS_SECRET_ACCESS_KEY` | Secret Key de AWS (temporal en AWS Academy) |
| `AWS_SESSION_TOKEN` | Session Token de AWS (temporal en AWS Academy) |
| `DB_PASSWORD` | Password del usuario app de MySQL (`despacho_app_2026`) |

El resto de valores (`DB_HOST`, `AWS_ACCOUNT_ID`, `EKS_CLUSTER_NAME`, etc.) los obtiene el CD desde Terraform automáticamente.

## Placeholders

El workflow `.github/workflows/cd.yml` reemplaza estos placeholders antes de aplicar los manifiestos:

- `__ECR_REGISTRY__`
- `__PROJECT_NAME__`
- `__IMAGE_TAG__`
- `__DB_HOST__`
- `__DB_NAME__`
