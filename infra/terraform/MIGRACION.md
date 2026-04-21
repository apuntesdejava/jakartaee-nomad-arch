# 🔄 Plan de Migración: De Configuración Anterior a Nueva

Si ya has ejecutado la **configuración anterior** con ACR y MySQL Flexible Server, este documento te guía a **migrar a la nueva configuración simplificada**.

## Opción 1: Destruir y Empezar de Nuevo (Recomendado)

**Tiempo**: ~15 minutos
**Costo**: -$60 (eliminan recursos caros)
**Riesgo**: Bajo (es dev, datos pueden perderse)

### Pasos

```bash
# 1. Hacer backup del estado actual (por si acaso)
cp terraform.tfstate terraform.tfstate.backup.old

# 2. Destruir recursos anteriores
terraform destroy

# Confirmar cuando se le pida
# Esto eliminará: ACR, MySQL Flexible Server, VM anterior, NSG, etc.

# 3. Limpiar
rm -rf .terraform
rm terraform.tfstate*

# 4. Reemplazar archivos
# Tu nuevo main.tf, variables.tf, outputs.tf, cloud-init.yaml
# ya están listos

# 5. Inicializar nuevamente
terraform init

# 6. Planificar con nueva configuración
terraform plan -out=tfplan

# 7. Aplicar
terraform apply tfplan
```

**Ventajas**:
- ✅ Limpio, sin recursos huérfanos
- ✅ Nuevo estado es pequeño y mantenible
- ✅ Sin conflictos

**Desventajas**:
- ❌ Tiempo de inactividad (~10 min)
- ❌ Pierdes datos en MySQL (haz backup si lo necesitas)

---

## Opción 2: Migración Gradual (Avanzado)

Si tienes datos que necesitas preservar, aquí está el proceso:

### Fase 1: Backup de Datos MySQL

```bash
# SSH a la VM anterior
ssh azureuser@<OLD_IP>

# Hacer dump de MySQL
mysqldump -uappuser -p appdb > appdb.sql
# Ingresa contraseña

# Descargar a tu máquina local
exit

# En tu máquina local
scp azureuser@<OLD_IP>:appdb.sql ./appdb-backup.sql
```

### Fase 2: Crear Nueva Infraestructura

```bash
# 1. Renombrar state anterior (para no perderlo)
mv terraform.tfstate terraform.tfstate.old

# 2. Inicializar con nueva configuración
terraform init

# 3. Aplicar
terraform plan -out=tfplan
terraform apply tfplan
```

### Fase 3: Restaurar Datos

```bash
# SSH a la NUEVA VM
ssh azureuser@<NEW_IP>

# Esperar 2 minutos a que MySQL esté listo
sleep 120

# Restaurar datos
mysql -uappuser -p appdb < /tmp/appdb-backup.sql
# Ingresa contraseña

# Verificar
mysql -uappuser -p appdb -e "SHOW TABLES;"
```

### Fase 4: Reconfigurar Vault y Jobs

```bash
# Seguir pasos de "Configurar Vault con Credenciales MySQL" en README.md

# Copiar y ejecutar nuevos jobs
scp infra/nomad/*.nomad azureuser@<NEW_IP>:/opt/nomad-jobs/
ssh azureuser@<NEW_IP>

cd /opt/nomad-jobs
nomad job run clients.nomad
nomad job run products.nomad
nomad job run sales.nomad
```

### Fase 5: Destruir Infraestructura Antigua

```bash
# Una vez verificado que TODO funciona en el nuevo:

# Restaurar state anterior temporalmente
mv terraform.tfstate terraform.tfstate.new
mv terraform.tfstate.old terraform.tfstate

# Cambiar variable enable_acr a false y comentar MySQL Flexible
# O simplemente ejecutar destroy (si state anterior está corrupto)
terraform destroy

# Restaurar nuevo state
rm terraform.tfstate terraform.tfstate.backup
mv terraform.tfstate.new terraform.tfstate
```

---

## Opción 3: Importar Recursos Existentes (Expert)

Si quieres **mantener la VM actual** pero cambiar la BD:

```bash
# ⚠️ Muy avanzado, no recomendado para dev

# 1. Hacer import del NIC, NSG, etc.
terraform import azurerm_network_interface.main \
  /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Network/networkInterfaces/<NIC_NAME>

# 2. Luego manualmente alinear resource blocks en main.tf

# ⚠️ Requiere mucho trabajo manual, fácil de romper
```

**No recomendado para dev**. Usa Opción 1 o 2.

---

## Checklist de Migración

### Pre-Migración
- [ ] He hecho backup: `cp terraform.tfstate terraform.tfstate.backup.old`
- [ ] He anotado IP pública de VM anterior
- [ ] He hecho backup de datos MySQL (si es importante)
- [ ] He exportado configuración de Vault (si es importante)

### Durante Migración (Opción 1)
- [ ] `terraform destroy` - Esperé confirmación
- [ ] `terraform init`
- [ ] `terraform plan` - Revisé recursos nuevos
- [ ] `terraform apply`

### Post-Migración
- [ ] `terraform output` - Verifiqué información
- [ ] SSH a nueva VM: `ssh azureuser@<NEW_IP>`
- [ ] Verificar servicios: `systemctl status nomad-dev`
- [ ] Ver Nomad UI: `http://<NEW_IP>:4646`
- [ ] Ver Consul UI: `http://<NEW_IP>:8500`
- [ ] Conectar MySQL: `mysql -h<NEW_IP> -uappuser -p appdb`
- [ ] Configurar Vault con credenciales
- [ ] Ejecutar jobs Nomad

---

## Recuperación de Problemas

### "Accidentalmente ejecuté destroy, ¿cómo recupero?"

```bash
# Si tienes backup del state:
cp terraform.tfstate.backup.old terraform.tfstate
terraform import ...  # Reimportar recursos

# Si no:
# Ir a Azure Portal y manualmente anotar IDs de recursos
# Luego usar terraform import para cada uno
# ⚠️ Proceso largo y propenso a errores
```

### "El estado de Terraform está corrupto"

```bash
# Opción A: Empezar del cero (recomendado)
rm -rf terraform.tfstate* .terraform
terraform init
# Luego destroy manual en Azure Portal
# Luego apply

# Opción B: Intentar refresh
terraform refresh
# Si sigue fallando, ir a Opción A
```

### "Quiero volver a la configuración anterior"

```bash
# Si conservaste terraform.tfstate.old:
cp terraform.tfstate terraform.tfstate.new
cp terraform.tfstate.old terraform.tfstate

terraform destroy  # Destruye la NUEVA

# Revertir cambios en archivos .tf
# O si no están versionados, recrearlos manualmente

terraform init
terraform apply
```

---

## Costos durante Migración

```
Fase 1: Backup MySQL              - (conectarse a VM)
Fase 2: Nueva VM levantando       ~$60/mes + $50/mes de MySQL Flex + $10 ACR (si estaba)
                                   = Ambas infraestructuras activas por 30 min
                                   ≈ $0.30-0.50

Fase 3: Restaurar datos           - (conectarse a VM nueva)
Fase 4: Configurar Vault/Jobs     - (ejecutar comandos)
Fase 5: Destruir antigua          -$60/mes (cuando destruyes)

TOTAL COSTO EXTRA: ~$1 (máximo 1 hora de doble infraestructura)
AHORRO A LARGO PLAZO: $60/mes * 12 = $720/año
```

---

## Después de la Migración

### Verificación Final

```bash
# Ver que todo está funcionando
terraform show

# Obtener outputs
terraform output deployment_info

# Conectar a VM
ssh azureuser@<NEW_IP>

# Dentro de VM:
docker ps -a          # Ver contenedores (MySQL debe estar corriendo)
systemctl status nomad-dev consul-dev vault-dev  # Ver servicios
curl http://127.0.0.1:4646/ui  # Nomad health check
curl http://127.0.0.1:8500/ui  # Consul health check
mysql -uappuser -p appdb -e "SELECT 1;"  # MySQL test
```

### Limpieza

```bash
# En local
rm -f terraform.tfstate.old  # Si ya no lo necesitas
rm -f appdb-backup.sql       # Si ya no lo necesitas

# En Azure Portal (manual)
# Verificar que no hay recursos "dangling" o innecesarios
# Todos los viejos ACR, MySQL Flexible deben estar gone
```

### Documentación

```bash
# Actualizar README.md de tu proyecto con nueva IP
# Actualizar cualquier script que tenga IP hardcoded
# Actualizar DNS records (si tienes)
```

---

## Guía Rápida por Opción

| Criterio | Opción 1 | Opción 2 | Opción 3 |
|----------|----------|----------|----------|
| **Complejidad** | Fácil | Intermedia | Experto |
| **Tiempo** | 15 min | 45 min | 2+ horas |
| **Riesgo** | Bajo | Medio | Alto |
| **Datos Preservados** | ❌ No | ✅ Sí | ✅ Sí |
| **Recomendado** | ✅ SÍ | 🟡 Si tienes datos | ❌ No |

---

## Si Tienes Preguntas

- **¿Cuál opción elijoRecomendado: Opción 1 (destruir y empezar)**
- **¿Perderé datos?**: Sí, en dev, no importa. Haz backup si lo necesitas (Opción 2)
- **¿Cuánto tiempo?**: 15 min (Opción 1), 45 min (Opción 2)
- **¿Cuánto cuesta?**: ~$1 durante la migración
- **¿Cómo vuelvo atrás?**: Tienes backup de .tfstate

---

**Versión**: 1.0 | **Fecha**: 2024 | **Estado**: ✅ Listo

