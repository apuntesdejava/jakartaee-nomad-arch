# RESUMEN DE CAMBIOS: Terraform Reconstruido

## Problemas Identificados en Configuración Original

### ❌ Problemas Principales

1. **ACR Innecesario**
   - Azure Container Registry cuesta ~$10-15/mes adicionales
   - No había pipeline CI/CD para push automático
   - Los jobs usan imágenes públicas de Docker Hub

2. **MySQL Flexible Server Problemático**
   - Costo adicional (~$30-50/mes)
   - Complejidad de networking VNet/firewall innecesaria
   - Firewall rules usaban IP pública que puede cambiar
   - No alineado con setup local (donde MySQL está en contenedor)

3. **Firewall Rules Inseguras**
   - Todo abierto a `0.0.0.0/0` (cualquier IP)
   - NSG monolítico sin modularidad
   - SSH abierto a internet (riesgo de seguridad)

4. **Cloud-init Incompleto**
   - No generaba MySQL (dependía de MySQL Flexible Server)
   - No instalaba Fabio Load Balancer
   - Falta sincronización con arquitectura real

5. **Outputs No Informativos**
   - Outputs redundantes/innecesarios
   - Falta URLs directas para las UIs
   - Sin conexión clara a arquitectura

---

## Solución Implementada

### ✅ Cambios Principales

#### 1. **Arquitectura Simplificada**

```
ANTES (Complejo):
├── Resource Group
├── VNet + Subnet
├── Public IP
├── NSG + Rules
├── VM
├── ACR (ELIMINADO)
├── MySQL Flexible Server (ELIMINADO)
└── Firewall Rules para MySQL (ELIMINADO)

DESPUÉS (Simple & Funcional):
├── Resource Group
├── VNet + Subnet
├── Public IP
├── NSG + Rules (modularizadas)
├── VM
│   └── cloud-init instala:
│       ├── Docker
│       ├── MySQL (contenedor)
│       ├── Consul
│       ├── Nomad
│       ├── Vault
│       └── Fabio
└── Solo recursos NECESARIOS para dev
```

#### 2. **MySQL en Docker (dentro de VM)**

**ANTES**: MySQL Flexible Server externo
- Networking complicado
- Firewall rules frágiles
- Costos adicionales

**DESPUÉS**: MySQL en contenedor Docker
- Alineado con setup local (compose.yaml)
- Volumen persistente en `/opt/mysql-data`
- Sin costos adicionales
- Más simple y reproducible

#### 3. **Fabio Load Balancer Incluido**

**ANTES**: No estaba en cloud-init
**DESPUÉS**: Instalado y configurado automáticamente
- Puerto 9999 (HTTP) para aplicaciones
- Puerto 9998 (Admin UI)
- Configuración básica lista

#### 4. **Variables Mejoradas**

```hcl
# Nuevas variables útiles:
- vm_size               # Configurable (Default: B2s)
- enable_acr            # Toggle para ACR (Default: false)
- mysql_user/password   # Credenciales MySQL separadas
- allowed_ssh_cidr      # Restricción de SSH
- environment_tags      # Tags personalizables
```

#### 5. **NSG Modularizado**

**ANTES**: Todas las rules en un bloque:
```hcl
resource "azurerm_network_security_group" "main" {
  security_rule { ... }
  security_rule { ... }
  # ...
}
```

**DESPUÉS**: Rules separadas:
```hcl
resource "azurerm_network_security_rule" "ssh" { ... }
resource "azurerm_network_security_rule" "nomad_ui" { ... }
# Más fácil de mantener y actualizar
```

#### 6. **Cloud-init Completo**

Ahora instala todo automáticamente:
- ✅ Consul (dev mode, :8500)
- ✅ Nomad (dev mode, :4646)
- ✅ Vault (dev mode, :8200)
- ✅ Fabio (HTTP :9999, Admin :9998)
- ✅ MySQL en Docker (:3306)
- ✅ Directorio para jobs Nomad (/opt/nomad-jobs)

#### 7. **Outputs Completos**

```hcl
# Nuevo output único que resume todo:
output "deployment_info" {
  SSH command
  URLs de UIs (Nomad, Consul, Vault, Fabio)
  Conexión MySQL
  Próximos pasos
}

# Más specific outputs:
- vm_ssh_command
- nomad_ui_url
- consul_ui_url
- vault_ui_url
- fabio_ui_url
- mysql_connection_string
```

---

## Archivos Creados/Modificados

### Nuevos Archivos

1. **deploy.sh** - Script helper para Linux/Mac
   - Comandos: init, plan, apply, destroy, output, connect, copy-jobs, logs, status

2. **deploy.ps1** - Script helper para Windows PowerShell
   - Mismos comandos que deploy.sh

3. **terraform.tfvars.example** - Plantilla de configuración
   - Valores por defecto seguros
   - Fácil para copiar y personalizar

4. **README.md** (completo)
   - Arquitectura diagramada
   - Pasos paso a paso
   - Solución de problemas
   - Mejores prácticas

### Archivos Modificados

1. **main.tf** - Reconstruido completamente
   - ✅ Eliminado ACR
   - ✅ Eliminado MySQL Flexible Server
   - ✅ Modularizado NSG
   - ✅ Cloud-init con templatefile()
   - ✅ Mejor organización con comentarios

2. **variables.tf** - Variables expandidas
   - ✅ Nuevas variables
   - ✅ Tags ambiente
   - ✅ Mejor documentación

3. **outputs.tf** - Outputs redesigned
   - ✅ Información más útil
   - ✅ Output deployment_info centralizado
   - ✅ URLs directas de UIs

4. **cloud-init.yaml** - Completamente mejorado
   - ✅ MySQL en Docker
   - ✅ Fabio instalado
   - ✅ Variables interpoladas (mysql_user, mysql_password, etc)
   - ✅ Directorio /opt/nomad-jobs

---

## Mejoras de Costo

### ANTES (Original)
```
- VM B2s:              ~$60/mes
- MySQL Flexible:      ~$50/mes
- ACR Basic:           ~$10/mes
- VNet/NSG:            Gratis
─────────────────────
TOTAL:                 ~$120/mes
```

### DESPUÉS (Optimizado)
```
- VM B2s:              ~$60/mes
- MySQL en Docker:     Incluido (gratis)
- ACR:                 Deshabilitado (gratis)
- VNet/NSG:            Gratis
─────────────────────
TOTAL:                 ~$60/mes

💰 AHORRO: 50% (eliminadas $60/mes de costos innecesarios)
```

---

## Mejoras de Seguridad

| Aspecto | ANTES | DESPUÉS |
|---------|-------|---------|
| SSH | Abierto a 0.0.0.0/0 | Configurable en variable |
| Firewall | Monolítico | Modularizado (fácil de auditar) |
| Secretos | Mezclados en admin_password | Separados (mysql_user, mysql_password, mysql_root_password) |
| Tags | Ninguno | Completos para auditoría |

---

## Cambios de Funcionalidad

### Ahora Funciona

✅ **MySQL**: Accesible en `:3306` de la VM (como en local)
✅ **Fabio**: Instalado y configurado (puertos 9998/9999)
✅ **Cloud-init**: Completo, tarda ~5-10 min en ejecutarse
✅ **Jobs Nomad**: Directorio listo en `/opt/nomad-jobs`
✅ **Variables MySQL**: Inyectadas desde Terraform

### Ya No Funciona (Removido)

❌ **ACR**: Removido (pero puedo habilitarse con `enable_acr = true`)
❌ **MySQL Flexible Server**: Removido (pero puede readoptarse si es necesario)

---

## Cómo Usar la Nueva Configuración

### Quick Start

```bash
cd infra/terraform

# 1. Preparar variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar contraseñas

# 2. Desplegar (3 comandos)
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# 3. Obtener información
terraform output deployment_info

# 4. Conectar
ssh azureuser@<PUBLIC_IP>
```

O con los scripts helper:

```bash
# Linux/Mac
chmod +x deploy.sh
./deploy.sh init
./deploy.sh plan
./deploy.sh apply
./deploy.sh output
./deploy.sh connect

# Windows PowerShell
.\deploy.ps1 -Command init
.\deploy.ps1 -Command plan
.\deploy.ps1 -Command apply
.\deploy.ps1 -Command output
.\deploy.ps1 -Command connect
```

---

## Próximos Pasos Opcionales

Si necesitas en el futuro:

1. **Habilitar ACR**
   ```hcl
   enable_acr = true  # en terraform.tfvars
   ```

2. **Cambiar a MySQL Flexible Server**
   - Crear nuevo archivo `database.tf` con resource `azurerm_mysql_flexible_server`
   - Actualizar cloud-init para NO lanzar Docker MySQL
   - Ajustar firewall rules

3. **Escalar a múltiples VMs**
   - Modularizar actual a `modules/`
   - Crear variable de count para múltiples instancias
   - Configurar Load Balancer Externo

4. **Producción**
   - Usar `terraform` state en Azure Storage Account
   - Secrets en Azure Key Vault
   - Agregara SSH Keys en lugar de passwords
   - Configurar más restrictivo (`allowed_ssh_cidr`)

---

## Validación

Antes de ejecutar `terraform apply`, verifica:

- [ ] `terraform.tfvars` está creado y personalizado
- [ ] Contraseñas son fuertes (>12 caracteres, números, símbolos)
- [ ] Tiene credenciales de Azure configuradas (`az login`)
- [ ] Ha revisado `terraform plan` output

---

## Soporte

Si algo no funciona:

1. **Ver logs cloud-init**: `ssh <IP> tail -100 /var/log/cloud-init-output.log`
2. **Revisar estado servicios**: `ssh <IP> systemctl status nomad-dev`
3. **Revisar estado Terraform**: `terraform show`
4. **Destruir y reintentar**: `terraform destroy && terraform apply`

---

**Versión**: 1.0 (Reconstrucción)
**Fecha**: 2024
**Estado**: ✅ Listo para producción Dev

