# Runbook demo julio

Este documento describe el flujo recomendado para la exposicion de julio.

La idea para el dia de la charla es simple:

- Dejar **todo Azure desplegado unas horas antes**.
- Ejecutar **Terraform desde Windows con PowerShell**.
- Evitar los scripts Bash en el flujo principal de Azure.
- Durante la exposicion, mostrar la infraestructura ya viva, las UIs, los endpoints, la carga con k6 y el escalado.

No se recomienda destruir recursos por partes ni recrear infraestructura en vivo durante la charla. Terraform puede tardar, Azure puede demorar en aprovisionar y la red siempre encuentra maneras creativas de pedir protagonismo.

## 0. Supuestos

Este runbook asume que trabajas desde Windows, en la raiz del proyecto:

```powershell
cd D:\proys\presentacion-jconf\jakartaee-nomad-arch
```

Requisitos instalados en Windows:

- JDK 21.
- Maven.
- Docker Desktop, si vas a reconstruir y publicar imagenes.
- Terraform.
- Azure CLI con sesion iniciada.
- SSH disponible desde PowerShell.
- k6.
- Bruno, si vas a usar la coleccion HTTP.

Nota: el repositorio tiene scripts Bash en `infra/scripts`, pero este runbook no los usa para Azure porque algunos invocan `terraform` internamente. Para esta demo, Terraform queda siempre del lado de PowerShell.

Verifica sesion de Azure:

```powershell
az account show
```

Si no tienes sesion:

```powershell
az login
```

## 1. Preparar imagenes Docker

Desde la raiz del proyecto:

```powershell
mvn clean install -Pprod
```

Esto compila los servicios y construye/publica las imagenes Docker que usaran los jobs de Nomad en Azure.

Si las imagenes ya estan publicadas y no hubo cambios en los servicios, este paso puede quedar hecho desde antes.

## 2. Revisar variables de Terraform

Edita:

```text
infra/terraform/terraform.tfvars
```

Para la demo completa, deja MySQL gestionado por Terraform y define el numero de workers:

```hcl
manage_mysql = true
worker_count  = 3
```

Revisa tambien:

- `location`
- `admin_username`
- `ssh_public_key_path`
- `mysql_user`
- `mysql_password`
- `my_ip`, si restringes SSH por IP

## 3. Desplegar todo en Azure

Ejecuta Terraform desde PowerShell, no desde WSL:

```powershell
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan
terraform -chdir=infra/terraform apply
```

Guarda los outputs principales en variables de PowerShell:

```powershell
$controlIp = terraform -chdir=infra/terraform output -raw control_public_ip
$gatewayIp = terraform -chdir=infra/terraform output -raw gateway_public_ip
$mysqlHost = terraform -chdir=infra/terraform output -raw mysql_host

$controlIp
$gatewayIp
$mysqlHost
```

Outputs utiles:

```powershell
terraform -chdir=infra/terraform output
```

## 4. Cargar schema y datos en Azure MySQL

Carga los datos desde PowerShell usando la VM de control como salto.

Primero define credenciales. Usa los mismos valores que tienes en `infra/terraform/terraform.tfvars`:

```powershell
$mysqlUser = "appuser"
$mysqlPassword = "AppPassword123!"
```

Limpia las tablas de demo:

```powershell
$resetSql = "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS sale_detail; DROP TABLE IF EXISTS sale; DROP TABLE IF EXISTS client; DROP TABLE IF EXISTS product; SET FOREIGN_KEY_CHECKS=1;"

ssh "azureuser@$controlIp" "docker run --rm mysql:9.7 mysql -N -B -h '$mysqlHost' -u '$mysqlUser' -p'$mysqlPassword' appdb -e `"$resetSql`""
```

Carga `infra/mysql/init/init.sql`:

```powershell
Get-Content -Raw infra/mysql/init/init.sql | ssh "azureuser@$controlIp" "docker run --rm -i mysql:9.7 mysql -h '$mysqlHost' -u '$mysqlUser' -p'$mysqlPassword' appdb"
```

Verifica conteos:

```powershell
$checkSql = "SHOW TABLES; SELECT COUNT(*) AS clients FROM client; SELECT COUNT(*) AS products FROM product; SELECT COUNT(*) AS sales FROM sale;"

ssh "azureuser@$controlIp" "docker run --rm mysql:9.7 mysql -N -B -h '$mysqlHost' -u '$mysqlUser' -p'$mysqlPassword' appdb -e `"$checkSql`""
```

## 5. Verificar infraestructura antes de la charla

Desde PowerShell:

```powershell
ssh "azureuser@$controlIp"
```

Dentro de la VM de control:

```bash
nomad node status
nomad job status
consul members
consul catalog services
```

Sal de la VM:

```bash
exit
```

Prueba endpoints desde PowerShell:

```powershell
curl.exe "http://${gatewayIp}:8000/clients/api/client"
curl.exe "http://${gatewayIp}:8000/products/api/product"
curl.exe "http://${gatewayIp}:8000/sales/resources/sale"
```

Abre estas URLs y dejalas listas:

```text
Nomad UI:  http://<control_public_ip>:4646
Consul UI: http://<control_public_ip>:8500
Fabio UI:  http://<gateway_public_ip>:9998
Gateway:   http://<gateway_public_ip>:8000
```

## 6. Actualizar Bruno

Desde PowerShell:

```powershell
cd requests/bruno 
java UpdateIps.java env=AZURE "ip=$gatewayIp"
cd ../..
```

Luego abre Bruno y usa el ambiente `AZURE`.

## 7. Minutos antes de presentar

No vuelvas a aplicar Terraform salvo que hayas cambiado algo.

Haz una verificacion rapida:

```powershell
$controlIp = terraform -chdir=infra/terraform output -raw control_public_ip
$gatewayIp = terraform -chdir=infra/terraform output -raw gateway_public_ip
$mysqlHost = terraform -chdir=infra/terraform output -raw mysql_host

terraform -chdir=infra/terraform plan

curl.exe "http://${gatewayIp}:8000/clients/api/client"
curl.exe "http://${gatewayIp}:8000/products/api/product"
curl.exe "http://${gatewayIp}:8000/sales/resources/sale"
```

El `plan` idealmente no deberia mostrar cambios. Si muestra cambios inesperados justo antes de la charla, no apliques a menos que sea necesario.

Si quieres resetear datos justo antes de iniciar, confirma que `$mysqlUser` y `$mysqlPassword` siguen definidos en esa terminal y repite la carga desde PowerShell:

```powershell
$resetSql = "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS sale_detail; DROP TABLE IF EXISTS sale; DROP TABLE IF EXISTS client; DROP TABLE IF EXISTS product; SET FOREIGN_KEY_CHECKS=1;"
ssh "azureuser@$controlIp" "docker run --rm mysql:9.7 mysql -N -B -h '$mysqlHost' -u '$mysqlUser' -p'$mysqlPassword' appdb -e `"$resetSql`""
Get-Content -Raw infra/mysql/init/init.sql | ssh "azureuser@$controlIp" "docker run --rm -i mysql:9.7 mysql -h '$mysqlHost' -u '$mysqlUser' -p'$mysqlPassword' appdb"
```

## 8. Validaciones para mostrar en vivo

Nomad:

```powershell
ssh "azureuser@$controlIp" "nomad node status"
ssh "azureuser@$controlIp" "nomad job status"
```

Consul:

```powershell
ssh "azureuser@$controlIp" "consul members"
ssh "azureuser@$controlIp" "consul catalog services"
```

APIs:

```powershell
curl.exe "http://${gatewayIp}:8000/clients/api/client"
curl.exe "http://${gatewayIp}:8000/products/api/product"
curl.exe "http://${gatewayIp}:8000/sales/resources/sale"
```

Escalado manual:

```powershell
ssh "azureuser@$controlIp" "nomad job scale products-backend api 3"
ssh "azureuser@$controlIp" "nomad job scale clients-backend api 3"
ssh "azureuser@$controlIp" "nomad job status products-backend"
ssh "azureuser@$controlIp" "nomad job status clients-backend"
```

Fabio seguira resolviendo por Consul sin cambiar las URLs publicas.

## 9. Carga y observabilidad en vivo

Abre estas ventanas antes de iniciar la prueba:

- Nomad UI: `http://<control_public_ip>:4646`
- Consul UI: `http://<control_public_ip>:8500`
- Fabio UI: `http://<gateway_public_ip>:9998`
- k6 dashboard: `http://127.0.0.1:5665`

Terminal 1: monitor de infraestructura en PowerShell.

```powershell
while ($true) {
    Clear-Host
    Get-Date
    ""
    "== Nomad nodes =="
    ssh "azureuser@$controlIp" "nomad node status"
    ""
    "== Nomad jobs =="
    ssh "azureuser@$controlIp" "nomad job status"
    ""
    "== Consul services =="
    ssh "azureuser@$controlIp" "consul catalog services"
    ""
    "== Gateway probes =="
    curl.exe -sS -o NUL -w "clients  %{http_code}`n" "http://${gatewayIp}:8000/clients/api/q/health/ready"
    curl.exe -sS -o NUL -w "products %{http_code}`n" "http://${gatewayIp}:8000/products/api/q/health/ready"
    curl.exe -sS -o NUL -w "sales    %{http_code}`n" "http://${gatewayIp}:8000/sales/resources/sale"
    Start-Sleep -Seconds 5
}
```

Terminal 2: prueba de carga con dashboard web y reporte HTML.

```powershell
$env:BASE_URL = "http://${gatewayIp}:8000"
$env:PEAK_VUS = "120"
$env:SALE_RATIO = "0.05"
$env:K6_WEB_DASHBOARD = "true"
$env:K6_WEB_DASHBOARD_EXPORT = "load-tests/k6/report-azure.html"

k6 run load-tests/k6/live-demo.js
```

Que mostrar durante la carga:

- En k6: latencia `p95`, errores, requests por segundo y duracion.
- En Nomad: jobs saludables, allocs corriendo y escalado manual.
- En Consul: servicios registrados y checks pasando.
- En Fabio: rutas `/clients`, `/products`, `/sales` y backends disponibles.

Puedes escalar mientras k6 corre:

```powershell
ssh "azureuser@$controlIp" "nomad job scale products-backend api 3"
ssh "azureuser@$controlIp" "nomad job scale clients-backend api 3"
```

Despues de unos segundos, Consul y Fabio deben mostrar mas instancias disponibles sin cambiar la URL publica.

## 10. Limpieza al terminar

Cuando ya no necesites conservar la demo en Azure, borra todo:

```powershell
terraform -chdir=infra/terraform destroy
```

Esto elimina VMs, redes, Load Balancer, NAT, Nomad, Consul, Vault, Fabio y MySQL.

Importante: mientras no ejecutes `terraform destroy`, Azure seguira cobrando por los recursos vivos, especialmente MySQL, almacenamiento, backups, VM, VMSS, NAT Gateway y Load Balancer.

## 11. Checklist corto

Horas antes de la demo:

- Imagenes Docker publicadas.
- `terraform -chdir=infra/terraform apply` ejecutado desde PowerShell.
- Schema y datos cargados desde PowerShell.
- Endpoints `/clients`, `/products`, `/sales` responden.
- Bruno actualizado con el `gateway_public_ip`.
- UIs de Nomad, Consul y Fabio abiertas o verificadas.

Minutos antes:

- Variables `$controlIp` y `$gatewayIp` cargadas.
- `terraform -chdir=infra/terraform plan` sin cambios inesperados.
- Endpoints probados con `curl.exe`.
- k6 instalado y listo.
- Ventanas de UI y terminales preparadas.

Durante la demo:

- Mostrar outputs principales.
- Mostrar Nomad UI.
- Mostrar Consul UI.
- Mostrar Fabio UI.
- Probar endpoints.
- Ejecutar k6.
- Escalar `products` y `clients`.
- Mostrar que Fabio mantiene la misma URL publica.

Despues de la demo:

- Ejecutar `terraform -chdir=infra/terraform destroy` si ya no necesitas conservar Azure.
