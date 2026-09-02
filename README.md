# 🛡️ ChronosCTF 2026 - Plataforma de Infraestructura & Retos

[![Terraform CI/CD](https://img.shields.io/badge/IaC-Terraform_1.7+-7B42BC?logo=terraform&logoColor=white)](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/terraform)
[![Azure for Students](https://img.shields.io/badge/Cloud-Azure_($100_Budget)-0089D6?logo=microsoftazure&logoColor=white)](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/.antigravity/rules.md)
[![Docker Hardened](https://img.shields.io/badge/Security-Non--Root_Docker-2496ED?logo=docker&logoColor=white)](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/challenges)
[![CI/CD Pipelines](https://img.shields.io/badge/GitHub_Actions-OIDC_Auth-2088FF?logo=githubactions&logoColor=white)](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/.github/workflows)

Repositorio centralizado para el aprovisionamiento automatizado, despliegue continuo y desarrollo de desafíos del torneo universitario de ciberseguridad **ChronosCTF 2026**.

---

## 🏗️ 1. Arquitectura del Sistema

La arquitectura está concebida bajo principios rigurosos de **FinOps** para operar dentro del crédito estricto de **$100 USD (Azure for Students)** durante el ciclo de vida del torneo:

```
                                  [ Internet / Jugadores ]
                                             │
                                             ▼
                          ┌─────────────────────────────────────┐
                          │     Azure Public IP (Estática)      │
                          └──────────────────┬──────────────────┘
                                             │
                          ┌──────────────────▼──────────────────┐
                          │     Network Security Group (NSG)     │
                          │   • 80 / 443 (HTTP/HTTPS)           │
                          │   • 22 (SSH Administrador)          │
                          │   • 8000-8100 (Retos de red)        │
                          └──────────────────┬──────────────────┘
                                             │
                    ┌────────────────────────┴────────────────────────┐
                    │ Azure Virtual Network (10.0.0.0/16)             │
                    │                                                 │
                    │  ┌───────────────────────────────────────────┐  │
                    │  │ Subred Plataforma (snet-platform)         │  │
                    │  │                                           │  │
                    │  │   ┌─────────────────────────────────────┐ │  │
                    │  │   │ VM Ubuntu 24.04 (Standard_B2s)      │ │  │
                    │  │   │  - CTFd (Plataforma web)            │ │  │
                    │  │   │  - MariaDB 10.11 (Base de datos)    │ │  │
                    │  │   │  - Redis 7 (Caché en memoria)       │ │  │
                    │  │   │  - Contenedores de Retos Web/Pwn    │ │  │
                    │  │   └─────────────────────────────────────┘ │  │
                    │  └───────────────────────────────────────────┘  │
                    │  ┌───────────────────────────────────────────┐  │
                    │  │ Subred Retos (snet-challenges)            │  │
                    │  │  (Segmentación lógica para aislamiento)   │  │
                    │  └───────────────────────────────────────────┘  │
                    └────────────────────────┬────────────────────────┘
                                             │ AcrPull
                                             ▼
                          ┌─────────────────────────────────────┐
                          │   Azure Container Registry (ACR)    │
                          │         SKU Basic ($5/mes)          │
                          └─────────────────────────────────────┘
```

### 💰 Estimación de Costos Mensuales (Presupuesto $100 USD)

| Componente Azure | SKU / Especificación | Costo Aprox. / Mes |
| :--- | :--- | :--- |
| **Máquina Virtual** | `Standard_B2s` (2 vCPU, 4 GiB RAM, Burstable) | ~$30.36 USD |
| **Disco SO** | `StandardSSD_LRS` 30 GB | ~$2.40 USD |
| **IP Pública** | Standard IPv4 (Estática) | ~$3.65 USD |
| **Registro Contenedores** | ACR SKU `Basic` | ~$5.00 USD |
| **Transferencia Saliente** | Egress (~15-20 GB) | ~$1.80 USD |
| **Total Estimado** | Operación Continua | **~$43.21 USD / mes** |

> *Nota: Al operar durante un mes de pruebas y el fin de semana del evento, el costo total permanece holgadamente por debajo del límite de $100 USD.*

---

## 📁 2. Estructura del Repositorio

```text
.
├── .antigravity/
│   └── rules.md                  # Reglas del proyecto, políticas FinOps y estándares Docker
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml    # CI: Valida y simula cambios en Terraform vía OIDC
│       ├── terraform-apply.yml   # CD: Aplica infraestructura en main vía OIDC
│       └── build-challenges.yml  # CI: Compila y valida Dockerfiles y metadatos de retos
├── challenges/
│   ├── README.md                 # Guía y convenciones para creadores de retos
│   └── web/
│       └── _template/            # Plantilla estandarizada de reto Web
│           ├── Dockerfile        # Multi-stage, usuario sin privilegios (no-root)
│           ├── challenge.yml     # Metadatos para sincronización con CTFd
│           ├── solution.md       # Writeup oficial y guía de solución
│           ├── solution/
│           │   └── solve.py      # Exploit automatizado de prueba
│           └── src/
│               ├── app.py        # Código fuente del reto
│               └── requirements.txt
├── scripts/
│   └── cloud-init.sh             # Bootstrap de la VM: Docker, Compose y CTFd
├── terraform/
│   ├── backend.tf                # Backend remoto Azure Blob Storage
│   ├── providers.tf              # Configuración de azurerm y versión
│   ├── variables.tf              # Variables parametrizadas (SKU, región, etc.)
│   ├── main.tf                   # Resource Group, VNet, Subnets y NSG
│   ├── acr.tf                    # Azure Container Registry (Basic)
│   ├── vm.tf                     # VM Ubuntu 24.04, Disco 30GB y NIC
│   └── outputs.tf                # IP pública, login server ACR y comandos
├── .gitignore                    # Reglas de exclusión para IaC, Docker, Python y secretos
└── README.md                     # Documentación principal
```

---

## 🔄 3. Flujo de Trabajo Git & CI/CD (GitFlow / Trunk-Based)

Para mantener la integridad y seguridad del entorno, seguimos el siguiente ciclo de contribución:

```
[ Feature / Challenge Branch ] ─────► [ Pull Request a 'main' ]
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼                                                             ▼
       [ build-challenges.yml ]                                      [ terraform-plan.yml ]
  - Detecta carpetas modificadas                                - Azure OIDC Login
  - Verifica challenge.yml & solution.md                        - terraform fmt & validate
  - Compila con docker build                                    - terraform plan
  - Valida usuario no-root en contenedor                        - Resumen en comentario del PR
                 │                                                             │
                 └──────────────────────────────┬──────────────────────────────┘
                                                ▼
                                    [ Code Review & Merge ]
                                                │
                                                ▼
                                     [ Push a rama 'main' ]
                                                │
                                                ▼
                                    [ terraform-apply.yml ]
                                - Aplica cambios automáticamente
```

### Configuración de Secretos en GitHub Actions (OIDC)
Para habilitar el despliegue sin contraseñas mediante **OpenID Connect (OIDC)** en Azure:

1. Crear una aplicación en Azure Entra ID con credencial federada vinculada a este repositorio.
2. Definir los siguientes secretos en el repositorio de GitHub (`Settings > Secrets and variables > Actions`):
   - `AZURE_CLIENT_ID`: ID de la aplicación / Service Principal.
   - `AZURE_TENANT_ID`: ID del directorio (tenant).
   - `AZURE_SUBSCRIPTION_ID`: ID de la suscripción de Azure.
   - `TF_STATE_RG`: Resource Group donde reside el estado de Terraform.
   - `TF_STATE_STORAGE_ACCOUNT`: Nombre de la cuenta de almacenamiento de Terraform.
   - `TF_STATE_CONTAINER`: Contenedor blob (ej. `tfstate`).

---

## 🚀 4. Guía de Despliegue

### 4.1. Despliegue Local para Desarrollo (Retos y CTFd)

#### Probar un reto individual localmente:
```bash
cd challenges/web/_template
docker build -t reto-template .
docker run --rm -p 8000:8000 -e FLAG="CHRONOS{test_flag_local}" reto-template
```
Verifica la solución ejecutando:
```bash
python solution/solve.py http://localhost:8000
```

#### Probar la plataforma CTFd completa en local:
```bash
mkdir -p /tmp/ctfd-local
# Utiliza la definición provista en scripts/cloud-init.sh
docker compose -f scripts/cloud-init.sh up -d  # o adapta docker-compose.yml
```

---

### 4.2. Despliegue en la Nube con Terraform

#### Paso 1: Autenticación inicial en Azure CLI
```bash
az login
az account set --subscription "<TU_SUBSCRIPTION_ID>"
```

#### Paso 2: Crear el contenedor de estado remoto de Terraform (única vez)
```bash
az group create --name rg-ctf-tfstate --location eastus2
az storage account create --name stctf2026tfstate --resource-group rg-ctf-tfstate --sku Standard_LRS
az storage container create --name tfstate --account-name stctf2026tfstate
```

#### Paso 3: Inicializar y desplegar infraestructura
```bash
cd terraform

# Inicializar con backend remoto configurado
terraform init \
  -backend-config="resource_group_name=rg-ctf-tfstate" \
  -backend-config="storage_account_name=stctf2026tfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.terraform.tfstate"

# Verificar plan de ejecución
terraform plan -out=tfplan

# Aplicar cambios
terraform apply tfplan
```

#### Paso 4: Obtener accesos y conectarse
Al finalizar, Terraform mostrará las salidas con la IP pública asignada:
```bash
terraform output ssh_connection_command
# Ejemplo: ssh azureuser@20.x.x.x
```
El script `scripts/cloud-init.sh` habrá configurado automáticamente Docker, Nginx y CTFd en `/opt/ctfd`. Accede a la plataforma ingresando a `http://<VM_PUBLIC_IP>` en tu navegador.

---

## 🔒 5. Políticas y Reglas de Seguridad
Consulta [.antigravity/rules.md](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/.antigravity/rules.md) para conocer las políticas obligatorias sobre no-root, multi-stage y límites de recursos cgroups.
