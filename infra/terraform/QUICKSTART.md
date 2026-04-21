# 🚀 QUICK START - Despliegue en 5 Comandos

Si quieres empezar **YA**, este es el camino más rápido.

## ⚡ 5 Comandos para Desplegar Todo

```bash
# 1️⃣ Preparar
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars

# 2️⃣ Editar valores (IMPORTANTE - cambiar contraseñas)
# Abre terraform.tfvars y cambia:
#   - admin_password
#   - mysql_password
#   - mysql_root_password
# nano terraform.tfvars

# 3️⃣ Inicializar
terraform init

# 4️⃣ Planificar & Ejecutar
terraform plan -out=tfplan
terraform apply tfplan

# 5️⃣ Obtener Información
terraform output deployment_info
```

## ⏱️ Tiempo Total: ~20 minutos

- Preparar: 2 min
- Terraform init: 2 min
- Terraform plan: 2 min
- **Terraform apply: 10 min** (crea infraestructura en Azure)
- Cloud-init en VM: 5 min (automático, se ejecuta después)
- **Total**: 20 minutos

## 📊 Qué Se Crea

```
✅ Resource Group (contenedor)
✅ Virtual Network + Subnet
✅ Public IP (Static)
✅ Network Security Group + Rules
✅ VM (Ubuntu 22.04, B2s)
   ├─ Docker ✅
   ├─ Consul ✅
   ├─ Nomad ✅
   ├─ Vault ✅
   ├─ Fabio ✅
   └─ MySQL (contenedor) ✅

❌ NO crea:
   • Azure Container Registry (caro, innecesario)
   • MySQL Flexible Server (caro, innecesario)
   • Storage Account (no usado)
```

## 💻 Después de Desplegar

```bash
# Obtener IP pública
AZURE_IP=$(terraform output -raw vm_public_ip)
echo "Tu VM está en: $AZURE_IP"

# Acceder a UIs
echo "Nomad:   http://$AZURE_IP:4646"
echo "Consul:  http://$AZURE_IP:8500"
echo "Vault:   http://$AZURE_IP:8200"
echo "Fabio:   http://$AZURE_IP:9998"

# SSH a la VM
ssh azureuser@$AZURE_IP

# Dentro de la VM:
# - Ver contenedores: docker ps
# - Ver servicios: systemctl status nomad-dev
# - Ver logs cloud-init: tail -100 /var/log/cloud-init-output.log
```

## 🎯 Desplegar Tus Jobs Nomad

```bash
# Desde tu máquina local:
AZURE_IP=$(terraform output -raw vm_public_ip)
scp infra/nomad/*.nomad azureuser@$AZURE_IP:/opt/nomad-jobs/

# SSH a la VM
ssh azureuser@$AZURE_IP

# Dentro de la VM:
nomad job run /opt/nomad-jobs/clients.nomad
nomad job run /opt/nomad-jobs/products.nomad
nomad job run /opt/nomad-jobs/sales.nomad

# Ver en Nomad UI: http://<IP>:4646
```

## 📝 terraform.tfvars (Editar Esto)

```hcl
# === CAMBIAR ESTOS VALORES ===

location = "swedencentral"
prefix   = "nomad-j"

# ⚠️ CAMBIAR CONTRASEÑA (mínimo 12 caracteres, números + símbolos)
admin_password      = "TuContraseñaFuerte123!"
mysql_user          = "appuser"
mysql_password      = "TuPasswordSQL123!"      # ⚠️ CAMBIAR
mysql_root_password = "TuRootPassword123!"    # ⚠️ CAMBIAR

# ✅ OPCIONAL
allowed_ssh_cidr = "0.0.0.0/0"    # O tu IP específica para mayor seguridad
enable_acr       = false           # ACR es caro, déjalo en false
```

## ✅ Checklist Pre-Despliegue

- [ ] Tengo Terraform instalado (`terraform -v`)
- [ ] Tengo Azure CLI (`az --version`)
- [ ] He hecho `az login` y estoy autenticado
- [ ] He copiado `terraform.tfvars.example` → `terraform.tfvars`
- [ ] He cambiado contraseñas en `terraform.tfvars`
- [ ] He ejecutado `terraform validate` (sin errores)
- [ ] He revisado `terraform plan` (outputs miran bien)

## 🆘 Algo Salió Mal?

```bash
# Error: "resource already exists"
# Solución: terraform destroy (elimina todo y empieza de nuevo)
terraform destroy -auto-approve
terraform apply tfplan

# Error: "VM no responde"
# Espera 5-10 minutos más (cloud-init sigue corriendo)
# O revisa logs: ssh azureuser@<IP> tail /var/log/cloud-init-output.log

# Error: "No puedo conectar MySQL"
# Espera 3 minutos (contenedor MySQL tarda en iniciar)
# O SSH y revisa: docker logs mysql-dev

# Error: "Servicios no corren"
# SSH a VM: systemctl status nomad-dev consul-dev vault-dev
# Revisar: journalctl -u nomad-dev -n 20
```

## 📞 Soporte Rápido

| Problema | Solución |
|----------|----------|
| VM tarda mucho | Espera 10-15 min, cloud-init se ejecuta |
| No puedo SSH | Revisa firewall, espera 2 min, reintenra |
| MySQL no conecta | Espera 3-5 min, intenta de nuevo |
| Nomad UI no responde | Espera, reinicia servicio: `systemctl restart nomad-dev` |
| Quiero destruir todo | `terraform destroy` |

## 📚 Documentación Completa

Para más detalles, ver:
- [README.md](README.md) - Guía completa paso a paso
- [RESUMEN.md](RESUMEN.md) - Resumen de cambios y ahorros
- [CAMBIOS.md](CAMBIOS.md) - Detalles técnicos
- [MIGRACION.md](MIGRACION.md) - Si tienes infraestructura anterior

## 🎁 Bonus: Scripts Helper

Si quieres automatizar más:

```bash
# Linux/Mac
chmod +x deploy.sh
./deploy.sh help           # Ver comandos
./deploy.sh init
./deploy.sh plan
./deploy.sh apply
./deploy.sh output
./deploy.sh connect
./deploy.sh copy-jobs

# Windows PowerShell
.\deploy.ps1 -Command help
.\deploy.ps1 -Command init
.\deploy.ps1 -Command apply
.\deploy.ps1 -Command connect
```

## 🎯 Próximos Pasos Después de Desplegar

1. ✅ Conectar: `ssh azureuser@<IP>`
2. ✅ Verificar servicios: `systemctl status nomad-dev`
3. ✅ Configurar Vault (ver README.md sección "Configurar Vault")
4. ✅ Copiar jobs Nomad
5. ✅ Ejecutar jobs: `nomad job run`
6. ✅ Monitorear en UIs

## 💰 Costo

```
VM B2s (solo): $60/mes
VNet/NSG: Gratis
Total: $60/mes

Ahorro vs anterior: -$60/mes (eliminadas ACR y MySQL Flex)
```

## 🚀 ESTÁS LISTO

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**¡Listo! Tu infraestructura estará disponible en 20 minutos.** ✅

---

Versión: 1.0 | Quick Start | 2024

