# Terraform: Despliegue de Consul + Nomad + Fabio en Azure

Este directorio contiene la configuración de Terraform para desplegar un entorno completo de **Consul + Nomad + Fabio + MySQL** en Azure.

## Arquitectura

```
┌─────────────────────────────────────────────┐
│        Azure Resource Group                 │
│  ┌───────────────────────────────────────┐  │
│  │      Virtual Network (10.0.0.0/16)    │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │   Subnet (10.0.2.0/24)          │  │  │
│  │  │                                 │  │  │
│  │  │  ┌──────────────────────────┐   │  │  │
│  │  │  │   Linux VM (B2s)         │   │  │  │
│  │  │  │ ┌────────────────────┐   │   │  │  │
│  │  │  │ │ Consul (8500)      │   │   │  │  │
│  │  │  │ │ Nomad (4646)       │   │   │  │  │
│  │  │  │ │ Vault (8200)       │   │   │  │  │
│  │  │  │ │ Fabio (9998/9999)  │   │   │  │  │
│  │  │  │ │ Docker             │   │   │  │  │
│  │  │  │ │  └─ MySQL (3306)   │   │   │  │  │
│  │  │  │ └────────────────────┘   │   │  │  │
│  │  │  └──────────────────────────┘   │  │  │
│  │  └─────────────────────────────────┘  │  │
│  │           ▲                            │  │
│  │           │                            │  │
│  │      Public IP (Static)               │  │
│  │                                       │  │
│  │  NSG (Network Security Group)         │  │
│  │  ├─ SSH (22)                          │  │
│  │  ├─ Consul UI (8500)                  │  │
│  │  ├─ Nomad UI (4646)                   │  │
│  │  ├─ Vault UI (8200)                   │  │
│  │  ├─ Fabio HTTP (9999)                 │  │
│  │  └─ Fabio Admin (9998)                │  │
│  │                                       │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Componentes

### ✅ Incluidos (Simplificado)

- **Virtual Network** (VNet) + Subnet
- **Linux VM** (Ubuntu 22.04 LTS, Standard_B2s)
- **Static Public IP** para acceso remoto
- **Network Security Group** con reglas de firewall
- **Docker** con MySQL en contenedor (volumen persistente)
- **Consul** (dev mode)
- **Nomad** (dev mode)
- **Vault** (dev mode)
- **Fabio** Load Balancer (últimas versiones)

## Requisitos

1. **Terraform** >= 1.0
2. **Azure CLI** (`az` command)
3. Cuenta de **Azure** activa
4. SSH key o password configurado

## Pasos para Desplegar

### 1. Preparar Archivo de Variables

```bash
# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars y cambiar valores sensibles
nano terraform.tfvars
```

**Variables críticas a cambiar:**

```hcl
admin_password      = "ChangeMe!StrongPassword123!"  # Contraseña para SSH
mysql_password      = "ChangeMe!dbpass123!"          # Contraseña para MySQL
mysql_root_password = "ChangeMe!rootpass123!"        # Root de MySQL
allowed_ssh_cidr    = "0.0.0.0/0"                    # Cambiar a tu IP para producción
```

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Planificar Despliegue

```bash
terraform plan -out=tfplan
```

Revisa los recursos que se crearán.

### 4. Aplicar Configuración

```bash
terraform apply tfplan
```

Esto tardará ~5-10 minutos en completar.

### 5. Obtener Información de Despliegue

Una vez finalizado, Terraform mostrará los outputs:

```bash
terraform output
```

O específicamente:

```bash
terraform output vm_public_ip          # IP pública de la VM
terraform output vm_ssh_command        # Comando SSH
terraform output deployment_info       # Resumen completo
```

## Acceso después del Despliegue

### SSH a la VM

```bash
ssh azureuser@<PUBLIC_IP>
```

### Acceder a las UIs

Reemplaza `<PUBLIC_IP>` con el output de `terraform output vm_public_ip`:

| Servicio       | URL                                  | Usuario | Contraseña |
|---|---|---|---|
| **Nomad**      | `http://<PUBLIC_IP>:4646`          | -       | -          |
| **Consul**     | `http://<PUBLIC_IP>:8500`          | -       | -          |
| **Vault**      | `http://<PUBLIC_IP>:8200`          | root    | root       |
| **Fabio Admin**| `http://<PUBLIC_IP>:9998`          | -       | -          |

### Conectar a MySQL

Desde tu máquina local:

```bash
mysql -h <PUBLIC_IP> -u appuser -p appdb
# Ingresa contraseña: (valor de mysql_password en tfvars)
```

O desde dentro de la VM:

```bash
ssh azureuser@<PUBLIC_IP>
docker exec -it mysql-dev mysql -uappuser -p appdb
```

## Desplegar Jobs de Nomad

SSH a la VM y luego:

```bash
# Descargar tus archivos .nomad desde el repo local
scp -r /path/to/infra/nomad/* azureuser@<PUBLIC_IP>:/opt/nomad-jobs/

# Conectar por SSH
ssh azureuser@<PUBLIC_IP>

# Desplegar jobs
nomad job run /opt/nomad-jobs/clients.nomad
nomad job run /opt/nomad-jobs/products.nomad
nomad job run /opt/nomad-jobs/sales.nomad
```

## Configuración de Vault con Credenciales MySQL

Dentro de la VM, necesitas inyectar las credenciales de MySQL en Vault:

```bash
ssh azureuser@<PUBLIC_IP>

# Configurar secretos en Vault
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=root

# Crear política (si no existe)
vault policy write nomad-cluster - <<EOF
path "kv/data/mysql" {
  capabilities = ["read"]
}
path "auth/jwt/role/nomad" {
  capabilities = ["read"]
}
EOF

# Guardar credenciales MySQL
vault kv put kv/mysql \
  user="appuser" \
  password="apppass123!" \
  url="jdbc:mysql://127.0.0.1:3306/appdb"
```

## Destruir Recursos

Para eliminar todos los recursos de Azure:

```bash
terraform destroy
```

**⚠️ ADVERTENCIA**: Esto eliminará TODOS los recursos, incluida la VM y datos.

## Solución de Problemas

### VM no inicia correctamente

```bash
# Revisar logs de cloud-init
ssh azureuser@<PUBLIC_IP>
tail -50 /var/log/cloud-init-output.log
```

### MySQL no se conecta

```bash
# Verificar que contenedor está corriendo
ssh azureuser@<PUBLIC_IP>
docker ps | grep mysql

# Revisar logs del contenedor
docker logs mysql-dev
```

### Nomad/Consul no están corriendo

```bash
# Verificar servicios
systemctl status consul-dev
systemctl status nomad-dev
systemctl status vault-dev
systemctl status fabio

# Revisar logs
journalctl -u nomad-dev -n 100
```

### Puertos no accesibles

```bash
# Revisar firewall desde la VM
sudo iptables -L -n

# Revisar NSG desde Azure CLI
az network nsg rule list -g <resource_group> --nsg-name <nsg_name>
```

## Estructura de Archivos

```
infra/terraform/
├── main.tf                      # Recursos principales (VNet, VM, NSG)
├── variables.tf                 # Definición de variables
├── outputs.tf                   # Outputs de Terraform
├── terraform.tfvars.example     # Ejemplo de valores
├── cloud-init.yaml              # Script de inicialización de VM
├── terraform.tfstate            # Estado (no comitear)
└── README.md                    # Este archivo
```

## Configuración Avanzada

### Habilitar ACR (si lo necesitas)

En `terraform.tfvars`:

```hcl
enable_acr = true
```

Luego:

```bash
terraform apply
```

### Cambiar tamaño de VM

En `terraform.tfvars`:

```hcl
vm_size = "Standard_B4ms"  # 4 vCPU, 16 GB RAM
```

### Usar ubicación diferente

En `terraform.tfvars`:

```hcl
location = "eastus"  # u otra región de Azure
```

## Mejores Prácticas

1. **Seguridad**:
   - No comitear `terraform.tfvars` con contraseñas reales
   - Usar Azure Key Vault para secretos en producción
   - Restringir `allowed_ssh_cidr` a tu IP

2. **Mantenimiento**:
   - Usar `terraform plan` antes de cambios
   - Mantener backups de `terraform.tfstate`
   - Versionar cambios en Git

3. **Costos**:
   - Usar `terraform destroy` cuando no necesites la infraestructura
   - VM B2s es ~$60/mes; ajustar según necesidad
   - MySQL en Docker (incluido) no tiene costes adicionales

## Referencias

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Nomad Documentation](https://www.nomadproject.io/docs)
- [Consul Documentation](https://www.consul.io/docs)
- [Fabio Load Balancer](https://fabiolb.net/)

## Preguntas Frecuentes

**¿Dónde están mis datos de MySQL?**
- En `/opt/mysql-data` dentro de la VM, persistentes en disco.

**¿Puedo escalar a múltiples VMs?**
- Esta configuración es para dev single-node. Para producción, refactorizar a módulos Terraform.

**¿Cómo actualizo Consul/Nomad/Vault?**
- SSH a la VM y ejecutar: `sudo apt-get upgrade`

**¿Qué sucede si reinicio la VM?**
- Todos los servicios se reinician automáticamente (systemd configured)
- Los datos de MySQL persisten

---

**Creado**: 2024 | **Mantenedor**: DevTeam | **Versión**: 1.0

