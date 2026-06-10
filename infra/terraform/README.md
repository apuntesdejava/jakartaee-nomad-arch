# Terraform: Despliegue Automático de Jakarta EE + Nomad + Consul + Vault en Azure

Este directorio contiene la configuración de Terraform para desplegar un entorno completo de **Jakarta EE + Nomad + Consul + Vault + Fabio + MySQL** en Azure de forma **100% automática**.

## Arquitectura Final

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                Virtual Network (10.0.0.0/16)               │  │
│  │  ┌───────────────────────────────────────────────────────┐  │  │
│  │  │            Subnet (10.0.1.0/24)                       │  │  │
│  │  │                                                         │  │  │
│  │  │  ┌──────────────────────────────────────────────────┐   │  │  │
│  │  │  │         Ubuntu VM (B2s)                          │   │  │  │
│  │  │  │ ┌─────────────────────────────────────────────┐  │   │  │  │
│  │  │  │ │ Docker + MySQL                              │  │   │  │  │
│  │  │  │ │ Consul (8500) + Nomad (4646) + Vault (8200) │  │   │  │  │
│  │  │  │ │ Fabio Load Balancer (9998/9999)             │  │   │  │  │
│  │  │  │ │ ┌─────────────────────────────────────────┐ │  │   │  │  │
│  │  │  │ │ │ Clients API (8081)                      │ │  │   │  │  │
│  │  │  │ │ │ Products API (8082)                     │ │  │   │  │  │
│  │  │  │ │ │ Sales Web (8083)                        │ │  │   │  │  │
│  │  │  │ │ └─────────────────────────────────────────┘ │  │   │  │  │
│  │  │  │ └─────────────────────────────────────────────┘  │   │  │  │
│  │  │  └──────────────────────────────────────────────────┘   │  │  │
│  │  │                        ▲                                 │  │  │
│  │  │                        │                                 │  │  │
│  │  │              Public IP (Static)                         │  │  │
│  │  │                                                         │  │  │
│  │  │  NSG: SSH(22), Nomad(4646), Consul(8500), Fabio(9999)   │  │  │
│  │  └───────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Despliegue 100% Automático

### Paso 1: Preparar Variables

```bash
cd infra/terraform

# Copiar template
cp terraform.tfvars.example terraform.tfvars

# Editar contraseñas (opcional, tiene defaults seguros)
nano terraform.tfvars
```

### Paso 2: Desplegar Todo

```bash
# Inicializar
terraform init

# Planificar
terraform plan

# DESPLEGAR TODO AUTOMÁTICAMENTE (15-20 minutos)
terraform apply -auto-approve
```

### Paso 3: ¡Listo! Acceder a las Aplicaciones

Después de 15-20 minutos, Terraform mostrará las URLs:

```bash
# Nomad UI (Jobs corriendo)
http://<IP>:4646

# Consul UI (Service Discovery)
http://<IP>:8500

# Vault UI (Secrets Management)
http://<IP>:8200

# Fabio Load Balancer (API Gateway)
http://<IP>:9999

# Aplicaciones Directas:
# Clients API:  http://<IP>:8081/clients/api
# Products API: http://<IP>:8082/products/api
# Sales Web:    http://<IP>:8083/sales
```

## ✨ Lo Que Hace Automáticamente

| Componente     | Estado | Descripción                                |
|----------------|--------|--------------------------------------------|
| **Terraform**  | ✅      | Crea VM, redes, NSG, IP pública            |
| **Cloud-init** | ✅      | Instala Docker, HashiCorp stack, Fabio     |
| **MySQL**      | ✅      | Docker container con base de datos         |
| **Consul**     | ✅      | Service discovery + KV store               |
| **Nomad**      | ✅      | Job scheduler con integración Vault        |
| **Vault**      | ✅      | Secrets management + JWT auth              |
| **Fabio**      | ✅      | Load balancer automático                   |
| **Jobs**       | ✅      | 3 aplicaciones desplegadas automáticamente |
| **Config**     | ✅      | Consul KV poblado, Vault configurado       |

## 🎯 Beneficios vs AKS

| Aspecto            | Este Setup           | AKS                 |
|--------------------|----------------------|---------------------|
| **Complejidad**    | ⚠️ Media (Terraform) | ❌ Alta (Kubernetes) |
| **Costo**          | ✅ $65/mes            | ❌ $150-300/mes      |
| **Tiempo Deploy**  | ✅ 20 min             | ❌ 1-2 horas         |
| **Mantenimiento**  | ✅ Bajo               | ❌ Alto              |
| **Dev Experience** | ✅ Excelente          | ⚠️ Complejo         |
| **Escalabilidad**  | ✅ Nomad clusters     | ✅ Kubernetes        |

## 📋 Requisitos

- **Terraform** >= 1.0
- **Azure CLI** configurado (`az login`)
- **SSH Key** configurada en `terraform.tfvars` (viene con default)
- **Cuenta Azure** con créditos

## 🔧 Configuración Avanzada

### Cambiar Región
```hcl
location = "westeurope"  # Europa
location = "eastus"      # Este US (default)
location = "brazilsouth" # Brasil
```

### Cambiar Tamaño VM
```hcl
vm_size = "Standard_B4ms"  # 4 vCPU, 16GB RAM
```

### Restringir IP SSH
```hcl
my_ip = "203.0.113.42/32"  # Tu IP específica
```

## 🔍 Monitoreo y Logs

Si acabas de ejecutar `terraform apply`, la VM tardará unos **5-10 minutos** en terminar de configurar todo. Puedes monitorear el progreso con estos comandos:

### 1. Ver progreso de instalación en tiempo real
Este log muestra la instalación de Docker, Nomad, Consul y la descarga de imágenes.
```bash
ssh azureuser@<IP> "sudo tail -f /var/log/cloud-init-output.log"
```

### 2. Ver el despliegue automático de los Jobs
Este servicio se encarga de ejecutar `nomad job run` para cada aplicación una vez que Nomad está listo.
```bash
ssh azureuser@<IP> "sudo journalctl -u nomad-jobs-setup -f"
```

### 3. Verificar estado de los contenedores Docker
```bash
ssh azureuser@<IP> "sudo docker ps"
```

### 4. Logs de los Orquestadores (Systemd)
```bash
# Nomad
ssh azureuser@<IP> "sudo journalctl -u nomad -f"
# Consul
ssh azureuser@<IP> "sudo journalctl -u consul -f"
# Vault
ssh azureuser@<IP> "sudo journalctl -u vault -f"
```

## 🛠️ Solución de Problemas


## 🧹 Limpieza

```bash
terraform destroy -auto-approve
```

**⚠️ Elimina TODO: VM, datos, IPs**

## 📚 Arquitectura Técnica

### Servicios Instalados Automáticamente
- **Consul 1.17.3**: Service discovery, health checks, KV store
- **Nomad 1.7.5**: Job scheduler con integración Vault
- **Vault 1.15.6**: Secrets management con JWT authentication
- **Fabio 1.6.3**: Load balancer automático via Consul
- **MySQL 8.0**: Base de datos en Docker
- **Docker**: Container runtime

### Jobs Desplegados
1. **clients-backend**: Quarkus API (puerto 8081)
2. **products-backend**: Quarkus API (puerto 8082)  
3. **sales-backend**: Payara web app (puerto 8083)

### Seguridad
- **Vault**: Gestiona credenciales MySQL
- **JWT**: Autenticación Nomad ↔ Vault
- **NSG**: Firewall restrictivo
- **SSH**: Solo desde IP configurada

---

**🎉 ¡Listo para revolucionar tu desarrollo Jakarta EE en la nube!**
