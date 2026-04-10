# JakartaEE / MicroProfile + Quarkus & Nomad Architecture

Este proyecto es una arquitectura moderna orientada a la nube construida sobre un modelo puro de orquestación local en **WSL** (Windows Subsystem for Linux), utilizando el stack de HashiCorp y Docker. 

Comprende un ecosistema mixto de aplicaciones hechas en el clásico **Payara Micro (JakartaEE)** e implementaciones rápidas en **Quarkus (MicroProfile)**.

## 🏗 Arquitectura de Microservicios

Toda la infraestructura está desacoplada e interconectada en malla vía Service Discovery. Las tecnologías que le dan vida son:

### 1. HashiCorp Stack
- **Nomad**: Actúa como el orquestador principal de cargas de trabajo ejecutando los *Nomad Jobs* que empaquetan a nuestras aplicaciones en el motor de Docker usando el driver integrado.
- **Consul**: Brinda las herramientas de Service Discovery, observabilidad perimetral y Health Checks para conocer al instante la situación de la topología de red.
- **Vault**: Proporciona el sistema inyectado de secretos utilizando Workload Identities (JWT) para que los contenedores obtengan sus credenciales de base de datos (`user`, `password`, `url`) desde `kv/data/mysql` sin almacenarlo en texto plano.

### 2. Backends (Aplicaciones)
- 🛒 `products` **(Quarkus - JVM)**
- 👥 `clients` **(Quarkus - JVM)**
- 💳 `sales` **(Payara Micro)**: Se conecta como cliente distribuido hacia `/products/api` y `/clients/api` para compilar ventas.

*(Todos corren bajo `network_mode = "host"` acoplando su puerto dinámico `NOMAD_PORT_http` a la red WSL).*

### 3. API Gateway Edge: FabioLB
Para simplificar la configuración en modo de desarrollo y evitar los complejos proxies con CNI (Container Networking Interface), este stack ejecuta el robusto **Fabio Load Balancer** (`fabiolb/fabio`). 
- Escucha pasivamente a Consul, detecta los `tags = ["urlprefix-/..."]` de los HCL jobs y enruta **automáticamente** el tráfico de API de entrada al contenedor correcto. ¡Zero Configuración!

## 🚀 Guía de Operaciones

### Requisitos previos
- Windows + WSL2 habilitado.
- Docker Desktop Integration corriendo en segundo plano activamente para WSL.

### 1. Construir las imágenes y empaquetables
Desde la raíz del proyecto, asegúrate de compilar y abastecer las cargas binarias de tus módulos de Java y construir tus contenedores si dispones tu script de *image build* ejecutando:
```shell
mvn clean package -P prod
```

### 2. Iniciar el Clúster e Infraestructura Local
Si es la **primera vez**, asegúrate de tener todo instalado y los credenciales montados (utilizando los scripts adyacentes de ser necesario como `install-hashicorp.sh` y `setup-vault.sh`).

Para arrancar todo de golpe simplemente ejecuta la utilidad principal (que configurará puertos, limpiará remanentes antiguos, inyectará red/variables en Nomad y levantará cada contenedor):

```bash
./infra/scripts/start-local.sh
```

El script se encargará de configurar MySQL y levantar las orquestaciones. El proceso dura unos segundos (y un par extra mientrás Payara Micro calienta y Fabio registra los microservicios saludables en Consul).

## ☁️ Despliegue en la Nube (Azure)

Esta arquitectura está preparada para ser desplegada en **Microsoft Azure** utilizando **Terraform** para la Infraestructura como Código (IaC).

### Componentes en Azure:
- **Máquina Virtual (Ubuntu 22.04)**: Hospeda el stack de HashiCorp (Nomad, Consul, Vault) y Fabio.
- **Azure Container Registry (ACR)**: Almacenamiento privado para las imágenes de Docker.
- **Azure Database for MySQL (Flexible Server)**: Base de datos administrada para los microservicios.
- **Network Security Group (NSG)**: Configuración de firewall para permitir tráfico en los puertos de gestión y el gateway (8000).

### Pasos para el despliegue:

#### 1. Preparar la infraestructura con Terraform
Asegúrate de tener instalada la CLI de Azure (`az`) y haber iniciado sesión (`az login`). Luego, desde la carpeta `infra/terraform`:

```bash
cd infra/terraform
terraform init
terraform apply
```
*Nota: Se te solicitará una contraseña para el administrador de la VM y la base de datos.*

#### 2. Subir imágenes al registro (ACR)
Una vez finalizado el `apply`, Terraform mostrará los comandos necesarios en el output `push_commands`. Básicamente:
1. Haz login en el ACR: `az acr login --name <tu_acr_name>`
2. Etiqueta tus imágenes locales (construidas con `mvn clean package`).
3. Súbelas con `docker push`.

#### 3. Configurar Vault y Desplegar Jobs
Usa el script de despliegue automatizado que se encargará de configurar las intenciones en Consul y lanzar los jobs en Nomad apuntando al ACR y a la base de datos de Azure:

```bash
# Configura las variables de entorno con los datos de Terraform (IP y Host DB)
export DB_URL="jdbc:mysql://<mysql_host>:3306/appdb?useSSL=true"
export DB_USER="appadmin"
export DB_PASS="<tu_password>"

# Ejecuta el despliegue
./infra/scripts/deploy-azure.sh
```

---

## 🌐 Endpoints y Dashboards

Una vez ejecutado tu clúster por completo, podrás acceder desde tu navegador de Windows a:

### Puntos de acceso para el usuario / API
Todo el tráfico debe pasar por Fabio, quien funciona en el puerto unificado `8000`:
- **Sales API**: [http://localhost:8000/sales](http://localhost:8000/sales)
- **Products API**: [http://localhost:8000/products](http://localhost:8000/products)
- **Clients API**: [http://localhost:8000/clients](http://localhost:8000/clients)

### Interfaces Administrativas (UIs)
- **Consul (Service Discovery & Health)**: [http://localhost:8500](http://localhost:8500)
- **Nomad (Workload Orchestration)**: [http://localhost:4646](http://localhost:4646)
- **Fabio (Routing Table Activa)**: [http://localhost:9998](http://localhost:9998)