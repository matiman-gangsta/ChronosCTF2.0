# ChronosCTF 2.0 - Guía de Arquitectura e Infraestructura para Agentes

Este documento describe la arquitectura técnica, decisiones de diseño y pautas operativas para cualquier agente que trabaje en este repositorio.

---

## 1. Contexto y Restricciones de Presupuesto

- **Plataforma:** ChronosCTF 2.0 (GZCTF + Caddy HTTPS + PostgreSQL + Stack de Monitoreo Grafana/Prometheus).
- **Entorno Cloud:** Microsoft Azure (Región: `eastus2`).
- **Suscripción:** **Azure for Students (Crédito limitado de $100 USD)**.
- **Regla Fundamental:** Maximizar el rendimiento por dólar. Evitar cualquier recurso con costo fijo mensual innecesario. Cuando la plataforma no esté en uso, la VM y componentes de red se destruyen para dejar el consumo en $0, manteniendo únicamente el Blob Storage con los respaldos intactos.

---

## 2. Decisiones Arquitectónicas Clave

### A. Sin Azure Container Registry (ACR)
- **Motivo:** ACR (SKU Basic) cuesta **~$5 USD/mes fijo**, consumiendo crédito incluso con la máquina apagada o destruida.
- **Implementación:** `acr.tf` y el rol `AcrPull` en `vm.tf` están **deshabilitados**. NO re-habilitar ACR salvo petición explícita del usuario.
- **Alternativa:** Todos los contenedores de retos se compilan y gestionan **localmente en el Docker Engine de la VM** a costo **$0 adicional**.

### B. Persistencia Liviana con Azure Blob Storage
- **Motivo:** Blob Storage con redundancia LRS cuesta únicamente por datos almacenados (~$0.018 USD/GB/mes). Almacenar configuraciones y base de datos cuesta **menos de $0.05 USD/mes**.
- **Infraestructura (`storage.tf` y `main.tf`):**
  - Resource Group: `rg-ctf2026-prod` (con `prevent_destroy = true`)
  - Storage Account: `stchronosctfprod` (con `prevent_destroy = true`)
  - Contenedor privado: `backups` (con `prevent_destroy = true`)
  - Archivo maestro: `gzctf_full_backup.tar.gz` (contiene BD Postgres, appsettings, credenciales, uploads y dashboards de Grafana).
- **Seguridad:** La VM se autentica contra Blob Storage mediante **Identidad Administrada del Sistema (MSI)** y el rol `Storage Blob Data Contributor`. Nunca colocar connection strings ni claves maestras en el código.

### C. Ciclo de Vida y Bootstrap de la VM (`scripts/cloud-init.sh`)
La máquina virtual (`Standard_B2s` con 2 vCPUs y 4GB RAM) es efímera y completamente auto-recuperable al arrancar:
1. **Swapfile de 4GB:** Configurado en el paso `[0/9]` para evitar OOM (Out Of Memory) durante picos de compilación o tráfico.
2. **Restauración Automática:** Antes de iniciar GZCTF, consulta si existe `gzctf_full_backup.tar.gz` en Blob Storage. Si existe, lo descarga y restaura la base de datos PostgreSQL, usuarios, configuraciones y dashboards de Grafana.
3. **Compilación de Retos:** En el paso `[10/10]`, clona el repositorio y compila automáticamente las imágenes Docker de todos los retos en el daemon local.
4. **Respaldos Periódicos:** El cronjob en `/etc/cron.hourly/gzctf-backup` realiza un dump de PostgreSQL y comprime `/opt/gzctf` subiéndolo de forma desatendida a Blob Storage.

---

## 3. Guía Operativa de Terraform

### A. Para Desplegar / Levantar la Plataforma (`terraform apply`)
Cuando el usuario pida *"hazme un terraform apply de lo que tengo acá"* o levantar el entorno:
1. Navegar a la carpeta `terraform/`.
2. Ejecutar:
   ```powershell
   terraform apply -auto-approve
   ```
3. Terraform aprovisionará la VNet, subredes, NSG, IP Pública, VM y rol de acceso a almacenamiento.
4. Exportar la clave SSH generada automáticamente:
   ```powershell
   python -c "import subprocess, json; data = json.loads(subprocess.check_output(['terraform', 'output', '-json'])); open('chronos_rsa', 'w', newline='\n').write(data['tls_private_key']['value'])"
   Copy-Item -Path "chronos_rsa" -Destination "..\chronos_rsa"
   icacls chronos_rsa /inheritance:r /grant:r "$($env:USERNAME):(R)"
   icacls ..\chronos_rsa /inheritance:r /grant:r "$($env:USERNAME):(R)"
   ```
5. La VM arrancará, descargará el backup desde Blob Storage y compilará todos los retos de forma autónoma en ~3 minutos.

### B. Para Pausar / Bajar la Plataforma (`terraform destroy` selectivo)
Para detener la facturación de cómputo y red preservando **únicamente** el Blob Storage con las configuraciones:
1. Ejecutar en `terraform/`:
   ```powershell
   terraform destroy -target="azurerm_linux_virtual_machine.vm" -target="azurerm_network_interface.vm_nic" -target="azurerm_public_ip.vm_pip" -target="azurerm_subnet_network_security_group_association.platform" -target="azurerm_subnet_network_security_group_association.challenges" -target="azurerm_subnet.platform" -target="azurerm_subnet.challenges" -target="azurerm_virtual_network.main" -target="azurerm_network_security_group.main" -target="azurerm_role_assignment.vm_storage_blob" -target="tls_private_key.ssh[0]" -auto-approve
   ```
2. **Resultado:** Se eliminan la VM, IPs, NSG y VNet ($0 costo de cómputo). `stchronosctfprod` y `rg-ctf2026-prod` permanecen intactos guardando el respaldo.

---

## 4. Accesos y Verificación

- **Plataforma Web (HTTPS):** `https://chronosctf-2026.eastus2.cloudapp.azure.com`
- **Monitoreo Grafana:** `https://chronosctf-2026.eastus2.cloudapp.azure.com/grafana`
- **Credenciales iniciales:** En caso de no existir respaldo previo, se guardan en `/opt/gzctf/admin_credentials.txt` en el servidor tras la instalación.
