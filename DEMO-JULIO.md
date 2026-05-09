# Runbook demo julio

Este documento describe el procedimiento recomendado para la demo: preparar Azure MySQL horas antes, dejarlo poblado, bajar la infraestructura efimera y luego recrear lo faltante durante la presentacion.

La idea es separar dos cosas:

- **MySQL**: puede quedar listo antes de la demo porque tarda mas y no aporta mucho verlo crearse en vivo.
- **Nomad + Consul + Vault + Fabio + workers**: se puede recrear en vivo para demostrar la infraestructura HashiCorp funcionando.

## 0. Previo a la demo

Desde la raiz del proyecto:

```bash
mvn clean install -Pprod
```

Esto compila y publica las imagenes Docker que Nomad usara en Azure.

Revisa `infra/terraform/terraform.tfvars`:

```hcl
manage_mysql = true
worker_count  = 3
```

Inicializa Terraform:

```bash
cd infra/terraform
terraform init
terraform validate
```

## 1. Ensayo completo desde cero

Para probar absolutamente todo desde cero:

```bash
cd infra/terraform
terraform destroy
terraform apply
cd ../..
bash ./infra/scripts/seed-azure-db.sh
```

Verifica outputs:

```bash
terraform -chdir=infra/terraform output
```

Prueba el gateway:

```bash
curl http://<gateway_public_ip>:8000/clients/api/client
curl http://<gateway_public_ip>:8000/products/api/product
curl http://<gateway_public_ip>:8000/sales/resources/sale
```

Si esto funciona, la infraestructura completa esta validada.

## 2. Preparacion horas antes de la demo

Este es el flujo recomendado para julio.

Primero crea todo una vez:

```bash
cd infra/terraform
terraform apply
```

Luego carga schema y datos:

```bash
cd ../..
bash ./infra/scripts/seed-azure-db.sh --reset
```

Verifica que MySQL tenga datos:

```bash
curl http://<gateway_public_ip>:8000/clients/api/client
curl http://<gateway_public_ip>:8000/products/api/product
curl http://<gateway_public_ip>:8000/sales/resources/sale
```

Actualiza Bruno:

```bash
cd requests/bruno
javac UpdateIps.java
java UpdateIps env=AZURE ip=<gateway_public_ip>
```

## 3. Borrar lo efimero y conservar MySQL

Despues de poblar MySQL, destruye solo lo que quieres recrear durante la demo.

No uses `terraform destroy` en este punto si quieres conservar MySQL.

Desde `infra/terraform`:

```bash
terraform destroy \
  -target=azurerm_linux_virtual_machine_scale_set.workers \
  -target=azurerm_linux_virtual_machine.control \
  -target=azurerm_network_interface.control \
  -target=azurerm_lb_rule.gateway \
  -target=azurerm_lb_probe.gateway \
  -target=azurerm_lb_backend_address_pool.gateway \
  -target=azurerm_lb.gateway \
  -target=azurerm_subnet_network_security_group_association.subnet \
  -target=azurerm_network_security_group.nsg \
  -target=azurerm_subnet_nat_gateway_association.subnet \
  -target=azurerm_nat_gateway_public_ip_association.nat \
  -target=azurerm_nat_gateway.nat \
  -target=azurerm_mysql_flexible_server_firewall_rule.allow_control \
  -target=azurerm_mysql_flexible_server_firewall_rule.allow_nat \
  -target=azurerm_public_ip.control_pip \
  -target=azurerm_public_ip.gateway_pip \
  -target=azurerm_public_ip.nat_pip \
  -target=azurerm_subnet.subnet \
  -target=azurerm_virtual_network.vnet
```

Esto deja vivo:

- Resource Group.
- Azure MySQL Flexible Server.
- Base `appdb`.
- Configuracion `require_secure_transport = OFF`.
- Datos cargados por `seed-azure-db.sh`.

Terraform mostrara advertencias por usar `-target`; para este caso de demo esta bien porque estas preparando intencionalmente un estado parcial.

## 4. Minutos antes de presentar

Confirma que sigues en `infra/terraform`:

```bash
terraform plan
```

El plan deberia recrear VNet, IPs, NAT, Load Balancer, VM de control y VMSS de workers. MySQL no deberia recrearse.

Cuando empiece la demo:

```bash
terraform apply
```

Al terminar, obten los nuevos IPs:

```bash
terraform output
```

Actualiza Bruno con el nuevo gateway:

```bash
cd ../../requests/bruno
javac UpdateIps.java
java UpdateIps env=AZURE ip=<gateway_public_ip>
```

Si quieres dejar los datos limpios justo antes de probar:

```bash
cd ../..
bash ./infra/scripts/seed-azure-db.sh --reset
```

## 5. Validaciones en vivo

Nomad:

```bash
ssh azureuser@<control_public_ip>
nomad node status
nomad job status
```

Consul:

```bash
consul members
consul catalog services
```

APIs:

```bash
curl http://<gateway_public_ip>:8000/clients/api/client
curl http://<gateway_public_ip>:8000/products/api/product
curl http://<gateway_public_ip>:8000/sales/resources/sale
```

Escalado manual:

```bash
nomad job scale products-backend api 3
nomad job scale clients-backend api 3
nomad job status products-backend
nomad job status clients-backend
```

Fabio seguira resolviendo por Consul sin cambiar URLs.

## 6. Carga y observabilidad en vivo

Abre estas ventanas antes de iniciar la prueba:

- Nomad UI: `http://<control_public_ip>:4646`
- Consul UI: `http://<control_public_ip>:8500`
- Fabio UI: `http://<gateway_public_ip>:9998`
- k6 dashboard: `http://127.0.0.1:5665`

Terminal 1: monitor de infraestructura.

```bash
cd /mnt/c/proys/nomad/jakartaee-nomad-arch
bash ./infra/scripts/watch-azure-live.sh
```

Terminal 2: prueba de carga con dashboard web y reporte HTML.

```bash
cd /mnt/c/proys/nomad/jakartaee-nomad-arch
BASE_URL=http://<gateway_public_ip>:8000 \
PEAK_VUS=120 \
SALE_RATIO=0.05 \
K6_WEB_DASHBOARD=true \
K6_WEB_DASHBOARD_EXPORT=load-tests/k6/report-azure.html \
k6 run load-tests/k6/live-demo.js
```

Que mostrar durante la carga:

- En k6: latencia `p95`, errores, requests por segundo y duracion.
- En Nomad: jobs saludables, allocs corriendo y escalado manual.
- En Consul: servicios registrados y checks pasando.
- En Fabio: rutas `/clients`, `/products`, `/sales` y backends disponibles.

Puedes escalar en otra terminal mientras k6 corre:

```bash
ssh azureuser@<control_public_ip>
nomad job scale products-backend api 3
nomad job scale clients-backend api 3
```

Despues de unos segundos, Consul y Fabio deben mostrar mas instancias disponibles sin cambiar la URL publica.

## 7. Limpieza al terminar

### Opcion A: borrar absolutamente todo

Usa esta opcion al terminar el ensayo o cuando ya no necesites conservar MySQL:

```bash
cd infra/terraform
terraform destroy
```

Esto elimina VMs, redes, Load Balancer, NAT, Nomad, Consul, Vault, Fabio y MySQL.

### Opcion B: conservar MySQL para otra demo

Si quieres dejar MySQL vivo y borrar solo lo efimero, repite el destroy parcial:

```bash
cd infra/terraform
terraform destroy \
  -target=azurerm_linux_virtual_machine_scale_set.workers \
  -target=azurerm_linux_virtual_machine.control \
  -target=azurerm_network_interface.control \
  -target=azurerm_lb_rule.gateway \
  -target=azurerm_lb_probe.gateway \
  -target=azurerm_lb_backend_address_pool.gateway \
  -target=azurerm_lb.gateway \
  -target=azurerm_subnet_network_security_group_association.subnet \
  -target=azurerm_network_security_group.nsg \
  -target=azurerm_subnet_nat_gateway_association.subnet \
  -target=azurerm_nat_gateway_public_ip_association.nat \
  -target=azurerm_nat_gateway.nat \
  -target=azurerm_mysql_flexible_server_firewall_rule.allow_control \
  -target=azurerm_mysql_flexible_server_firewall_rule.allow_nat \
  -target=azurerm_public_ip.control_pip \
  -target=azurerm_public_ip.gateway_pip \
  -target=azurerm_public_ip.nat_pip \
  -target=azurerm_subnet.subnet \
  -target=azurerm_virtual_network.vnet
```

Recuerda: si conservas MySQL, Azure seguira cobrando por el servidor MySQL, almacenamiento y backups.

## 8. Checklist corto

Antes de la demo:

- Imagenes Docker publicadas.
- `terraform apply` ejecutado al menos una vez.
- `bash ./infra/scripts/seed-azure-db.sh --reset` ejecutado.
- Endpoints `/clients`, `/products`, `/sales` responden.
- Bruno actualizado con el `gateway_public_ip`.
- Infra efimera destruida si quieres recrearla en vivo.

Durante la demo:

- `terraform apply`.
- Mostrar outputs.
- Abrir Nomad UI.
- Probar endpoints.
- Escalar un job con `nomad job scale`.

Despues de la demo:

- `terraform destroy` si quieres borrar todo.
- Destroy parcial si quieres conservar MySQL.
