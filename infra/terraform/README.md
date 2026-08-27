# Infraestructura Azure con Terraform

Este directorio crea la infraestructura Azure del demo Jakarta EE/Quarkus con Nomad, Consul, Vault, Fabio, Podman y Azure Database for MySQL.

Terraform, Azure CLI y el estado de Terraform se administran exclusivamente desde Windows/PowerShell. Después de crear la infraestructura, WSL se usa únicamente para configurar Consul y desplegar los jobs compartidos mediante `infra/scripts/deploy-cloud.sh`.

## Arquitectura

- La VM de control ejecuta Nomad server, Consul server y Vault. Tiene el cliente de Nomad deshabilitado y no instala ningún runtime de contenedores.
- El Virtual Machine Scale Set contiene los workers. Cada worker ejecuta Nomad client, Consul client, Podman rootful y `nomad-driver-podman`.
- El Azure Load Balancer publica el gateway Fabio en el puerto 8000 y la UI de Fabio en el puerto 9998 para todos los workers.
- Azure Database for MySQL Flexible Server proporciona la base de datos externa a los workers.
- El NAT Gateway proporciona la salida a Internet de la subred.
- Los mismos jobs de `infra/nomad/` se usan localmente y en Azure. Las imágenes `docker.io/...` identifican el registro Docker Hub; no implican el uso del runtime Docker.

Terraform expone dos IP públicas con responsabilidades diferentes:

- `control_public_ip`: SSH, APIs y UIs de Nomad y Consul en la VM de control.
- `gateway_public_ip`: Fabio y el tráfico público de las aplicaciones a través del Load Balancer.

## Requisitos en Windows

Instala en Windows:

- Terraform.
- Azure CLI.
- El cliente Windows OpenSSH.

Comprueba las herramientas desde PowerShell:

```powershell
terraform version
az version
ssh -V
```

Inicia sesión en Azure también desde PowerShell:

```powershell
az login
az account show
```

Si necesitas seleccionar otra suscripción:

```powershell
az account set --subscription "<SUBSCRIPTION_ID_OR_NAME>"
```

## Clave SSH

La variable `admin_ssh_public_key` es obligatoria. El flujo recomendado usa Windows OpenSSH y una clave almacenada en el perfil de Windows. Antes de crearla, revisa las claves existentes:

```powershell
Get-ChildItem "$env:USERPROFILE\.ssh"
```

Si todavía no tienes una clave, puedes crearla desde PowerShell:

```powershell
ssh-keygen -t ed25519 `
  -C "jakartaee-nomad-azure" `
  -f "$env:USERPROFILE\.ssh\jakartaee-nomad-azure"
```

El comando genera una clave privada y un archivo público con extensión `.pub`. Conserva la clave privada únicamente en tu equipo y configura Terraform con el contenido completo del archivo público, por ejemplo:

```powershell
Get-Content "$env:USERPROFILE\.ssh\jakartaee-nomad-azure.pub"
```

PuTTY puede utilizarse como alternativa opcional, pero Windows OpenSSH es el flujo principal de este proyecto. No incluyas una clave privada en `terraform.tfvars` ni en el repositorio.

## Configurar variables

Desde PowerShell, en la raíz del repositorio:

```powershell
Set-Location .\infra\terraform
Copy-Item .\terraform.tfvars.example .\terraform.tfvars
```

Edita `terraform.tfvars` y sustituye como mínimo:

- `admin_ssh_public_key` por el contenido completo de tu archivo `.pub`.
- `mysql_server_name` por un nombre globalmente único.
- Las credenciales de MySQL de ejemplo por valores adecuados para el entorno.
- `my_ip` por tu IP pública con máscara `/32` para restringir el acceso cuando sea posible.

El valor `ssh-ed25519 AAAA... jakartaee-nomad-azure` del archivo de ejemplo es solamente un marcador y no es una clave válida.

## Crear la infraestructura desde PowerShell

Todos estos comandos se ejecutan en `infra/terraform` desde Windows/PowerShell:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Revisa el plan antes de confirmar `terraform apply`. Cloud-init instala y configura la pila HashiCorp en la VM de control y Podman rootful con el driver externo de Nomad en los workers. Los jobs de aplicación no se despliegan desde Terraform.

## Obtener las IP públicas

Cuando Terraform termine, mantente en PowerShell y consulta ambos outputs:

```powershell
$CONTROL_PUBLIC_IP = terraform output -raw control_public_ip
$GATEWAY_PUBLIC_IP = terraform output -raw gateway_public_ip

$CONTROL_PUBLIC_IP
$GATEWAY_PUBLIC_IP
```

También puedes comprobar el acceso a la VM de control con Windows OpenSSH:

```powershell
ssh -i "$env:USERPROFILE\.ssh\jakartaee-nomad-azure" azureuser@$CONTROL_PUBLIC_IP
```

Para revisar cloud-init sin cambiar de terminal:

```powershell
ssh -i "$env:USERPROFILE\.ssh\jakartaee-nomad-azure" azureuser@$CONTROL_PUBLIC_IP "sudo cloud-init status --wait"
ssh -i "$env:USERPROFILE\.ssh\jakartaee-nomad-azure" azureuser@$CONTROL_PUBLIC_IP "sudo tail -n 200 /var/log/cloud-init-output.log"
```

## Desplegar los workloads desde WSL

Una vez creada y preparada la infraestructura, abre WSL, sitúate en la raíz del repositorio y pasa explícitamente las dos IP obtenidas en PowerShell:

```bash
./infra/scripts/deploy-cloud.sh <CONTROL_PUBLIC_IP> <GATEWAY_PUBLIC_IP>
```

El script espera a Nomad, configura Consul KV y envía, en orden, los jobs de Fabio, clients, products y sales. Usa la IP de control para Nomad y Consul, y muestra las URLs públicas con la IP del gateway.

No ejecutes Terraform, Azure CLI ni `terraform output` desde WSL. WSL no administra el estado de Terraform; la transferencia entre ambos entornos son los dos valores de IP copiados explícitamente.

## Acceso después del despliegue

- Nomad UI: `http://<CONTROL_PUBLIC_IP>:4646`
- Consul UI: `http://<CONTROL_PUBLIC_IP>:8500`
- Fabio UI: `http://<GATEWAY_PUBLIC_IP>:9998`
- Gateway y aplicaciones: `http://<GATEWAY_PUBLIC_IP>:8000`

Consulta [`../../README.md`](../../README.md) para la arquitectura completa del repositorio y [`../../docs/local-environment.md`](../../docs/local-environment.md) para el entorno local Podman en Windows/WSL.

## Destruir la infraestructura

Cuando sea necesario eliminar el entorno, vuelve a `infra/terraform` en Windows/PowerShell, revisa el objetivo y ejecuta:

```powershell
terraform plan -destroy
terraform destroy
```

Esta operación elimina los recursos administrados por este estado de Terraform, incluidos los datos que no se hayan respaldado.
