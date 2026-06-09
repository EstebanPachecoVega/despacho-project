# Kubernetes para despacho-project

Estos manifiestos despliegan los dos backends Spring Boot y el frontend en Kubernetes/EKS.

## GitHub Secrets esperados

El Secret real de Kubernetes no se versiona. El workflow de CD lo crea desde GitHub Secrets:

- `AWS_ACCOUNT_ID`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `EKS_CLUSTER_NAME`
- `DB_HOST`
- `DB_NAME`
- `DB_USERNAME`
- `DB_PASSWORD`

`DB_HOST` puede salir del output Terraform `db_private_ip`. `DB_USERNAME` debe ser el usuario de aplicacion, por ejemplo `despacho_app`, no `root`.

## Placeholders

El workflow `.github/workflows/cd.yml` reemplaza estos placeholders antes de aplicar los manifiestos:

- `__ECR_REGISTRY__`
- `__PROJECT_NAME__`
- `__IMAGE_TAG__`
- `__DB_HOST__`
- `__DB_NAME__`
