# Local Environment Setup

This document describes how to prepare the local environment used by this project.

The current version of the demo uses **Podman** as its container runtime.

Docker Desktop is not required.

The local environment is intentionally split between **Windows** and **WSL2**:

- **Podman on Windows**
  - Builds and pushes application images through Maven and Fabric8.
  - Runs the local MySQL database using Podman Compose.

- **Podman inside WSL2**
  - Acts as the container runtime used by Nomad.
  - Runs the application workloads scheduled by Nomad.

- **WSL2**
  - Runs Nomad.
  - Runs Consul.
  - Runs Vault.
  - Runs the Nomad Podman driver.

These are two separate Podman environments. They do not share the same image store.

---

## Architecture

```text
Windows
│
├── Maven
│    │
│    └── Fabric8 docker-maven-plugin
│           │
│           ▼
│       Podman Windows
│           │
│           └── Docker-compatible API
│
├── Podman Windows
│    │
│    ├── build / push application images
│    │
│    └── MySQL
│
└── WSL2
     │
     ├── Vault
     ├── Consul
     ├── Nomad
     │    │
     │    └── nomad-driver-podman
     │            │
     │            ▼
     │       Podman Linux
     │            │
     │            ├── clients-backend
     │            ├── products-backend
     │            ├── sales-backend
     │            └── Fabio
     │
     └── HashiCorp local scripts
```

Application images are published to Docker Hub and then pulled by the Podman runtime inside WSL when Nomad schedules the workloads.

---

# 1. Requirements

The local environment requires:

- Windows 10 or Windows 11.
- WSL2.
- A recent Ubuntu distribution running inside WSL2.
- JDK 21.
- Maven, or the Maven wrappers included with the modules.
- Podman on Windows.
- Podman inside WSL2.
- Podman Compose support on Windows.
- Git.
- Internet access to download HashiCorp binaries and container images.
- A Docker Hub account if application images need to be published.

The project scripts install:

- Nomad.
- Consul.
- Vault.
- Terraform.
- CNI plugins.
- Supporting Linux packages.

---

# 2. Install WSL2

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

After installation, reboot Windows if requested.

Verify WSL:

```powershell
wsl --status
```

List the installed distributions:

```powershell
wsl --list --verbose
```

The Linux distribution should be using WSL version 2.

Example:

```text
NAME      STATE           VERSION
Ubuntu    Running         2
```

Enter WSL with:

```powershell
wsl
```

---

# 3. Install Java 21

Java 21 is required to build and run the Java applications.

Verify Java:

```bash
java -version
```

Expected major version:

```text
21
```

If Java is managed from Windows, also verify it from PowerShell:

```powershell
java -version
```

---

# 4. Install Podman on Windows

Install Podman from PowerShell.

Using `winget`:

```powershell
winget install RedHat.Podman
```

Open a new PowerShell terminal after installation.

Verify:

```powershell
podman version
```

---

# 5. Initialize Podman Machine

Podman on Windows runs Linux containers inside a Podman Machine.

Initialize the machine the first time:

```powershell
podman machine init
```

Start it:

```powershell
podman machine start
```

Verify:

```powershell
podman info
```

You can also inspect the available machines:

```powershell
podman machine list
```

A normal development session should begin by ensuring the Podman machine is running:

```powershell
podman machine start
```

If it is already running, Podman will report that state.

---

# 6. Configure the Podman Docker-compatible API

The Maven build uses the Fabric8 `docker-maven-plugin`.

Despite its name, the plugin can communicate with Podman through Podman's Docker-compatible API.

The project therefore keeps using the Fabric8 plugin while Podman provides the actual container engine.

Check the Podman connections:

```powershell
podman system connection list
```

The default Windows connection should normally be:

```text
podman-machine-default
```

Configure `DOCKER_HOST` for the current PowerShell session:

```powershell
$Env:DOCKER_HOST = "npipe:////./pipe/podman-machine-default"
```

Verify:

```powershell
$Env:DOCKER_HOST
```

Expected:

```text
npipe:////./pipe/podman-machine-default
```

To make the configuration persistent for the current Windows user:

```powershell
[Environment]::SetEnvironmentVariable(
    "DOCKER_HOST",
    "npipe:////./pipe/podman-machine-default",
    "User"
)
```

Close and reopen PowerShell.

Verify again:

```powershell
$Env:DOCKER_HOST
```

---

# 7. Configure Docker Hub credentials for Maven

The Fabric8 Maven plugin needs registry credentials when pushing images.

Using `podman login` is not necessarily sufficient because Maven/Fabric8 uses its own registry authentication configuration.

Create or edit:

```text
~/.m2/settings.xml
```

On Windows this is normally:

```text
C:\Users\<your-user>\.m2\settings.xml
```

Add:

```xml
<settings>
    <servers>
        <server>
            <id>docker.io</id>
            <username>YOUR_DOCKER_HUB_USERNAME</username>
            <password>YOUR_DOCKER_HUB_ACCESS_TOKEN</password>
        </server>
    </servers>
</settings>
```

Use a Docker Hub Personal Access Token instead of storing the account password.

For this demo, a token with:

- Read
- Write

permissions is sufficient.

Do not commit `settings.xml` or registry credentials to the repository.

---

# 8. Build and publish the application images

From PowerShell, at the root of the repository:

```powershell
mvn clean install -Pprod
```

The current images are:

```text
docker.io/apuntesdejava/clients-hc-example-jvm:0.0.1
docker.io/apuntesdejava/products-hc-example-jvm:0.0.1
docker.io/apuntesdejava/sales-hc-example:0.0.1
```

The build uses Podman through the Docker-compatible API exposed by Podman Machine.

Verify the images in Windows:

```powershell
podman images
```

The Maven build may also push the images to Docker Hub depending on the configured Maven lifecycle.

---

# 9. Install Podman inside WSL

The Podman installation inside WSL is independent from Podman running on Windows.

Inside WSL:

```bash
sudo apt update
sudo apt install -y podman
```

Verify:

```bash
podman version
```

Then:

```bash
podman info
```

The local demo uses rootless Podman inside WSL.

You can verify the current user ID with:

```bash
id -u
```

A typical first Linux user has UID:

```text
1000
```

---

# 10. Windows Podman and WSL Podman are separate

This distinction is important.

Running:

```powershell
podman images
```

in Windows shows the images stored by Podman Machine.

Running:

```bash
podman images
```

inside WSL shows the images stored by the native Linux Podman installation.

They are not the same image store.

Therefore, even if an application image already exists in Podman Windows, Nomad inside WSL may still show:

```text
Pulling image docker.io/...
```

This is expected.

The Nomad-managed Podman runtime will pull the image from the registry when it is not available in its own WSL image store.

---

# 11. Enable the Podman API socket inside WSL

The Nomad Podman driver communicates with Podman through its API socket.

Enable the rootless Podman socket:

```bash
systemctl --user enable --now podman.socket
```

Check its status:

```bash
systemctl --user status podman.socket
```

Verify the socket:

```bash
ls -l /run/user/$(id -u)/podman/podman.sock
```

The expected socket path is:

```text
/run/user/<UID>/podman/podman.sock
```

For UID `1000`, for example:

```text
/run/user/1000/podman/podman.sock
```

---

# 12. Install HashiCorp tools

The repository contains an installation script:

```bash
./infra/scripts/install-hashicorp.sh
```

Run it from WSL:

```bash
chmod +x ./infra/scripts/install-hashicorp.sh
./infra/scripts/install-hashicorp.sh
```

The script installs the versions currently defined in the repository for:

- Consul
- Nomad
- Vault
- Terraform

It also installs:

- CNI plugins
- `curl`
- `unzip`
- `jq`
- `iptables`

and prepares Linux networking settings required by Nomad.

Verify:

```bash
consul version
nomad version
vault version
terraform version
```

---

# 13. Install the Nomad Podman driver

Nomad does not include the Podman task driver by default.

The driver must be installed separately.

The local setup currently uses:

```text
nomad-driver-podman 0.6.5
```

Download it:

```bash
cd /tmp
wget https://releases.hashicorp.com/nomad-driver-podman/0.6.5/nomad-driver-podman_0.6.5_linux_amd64.zip
```

Extract:

```bash
unzip nomad-driver-podman_0.6.5_linux_amd64.zip
```

Create the Nomad plugin directory:

```bash
sudo mkdir -p /opt/nomad/plugins
```

Install the binary:

```bash
sudo install -m 755 \
  nomad-driver-podman \
  /opt/nomad/plugins/nomad-driver-podman
```

Verify:

```bash
ls -l /opt/nomad/plugins
```

Expected:

```text
nomad-driver-podman
```

The binary is a Nomad plugin and is not intended to be executed directly.

---

# 14. Configure Nomad to use the Podman driver

Nomad must know where the external plugin is installed.

The local Nomad configuration is:

```text
infra/nomad/agent-dev.hcl
```

It must define:

```hcl
plugin_dir = "/opt/nomad/plugins"
```

The Podman driver must also point to the rootless Podman socket.

Example:

```hcl
plugin "nomad-driver-podman" {
  config {
    socket_path = "unix:///run/user/1000/podman/podman.sock"
  }
}
```

Replace `1000` with the result of:

```bash
id -u
```

if your user has another UID.

---

# 15. Verify the Nomad Podman driver

After Nomad starts, run:

```bash
nomad node status -verbose
```

The `Drivers` section should include:

```text
Driver    Detected  Healthy  Message
podman    true      true     All Podman sockets are responding.
```

For example:

```text
Drivers
Driver    Detected  Healthy  Message
docker    false     false    Failed to connect to docker daemon
exec      true      true     Healthy
podman    true      true     All Podman sockets are responding.
raw_exec  true      true     Healthy
```

The Docker driver may appear as unavailable.

That is expected.

This project uses the Podman driver for the application workloads.

---

# 16. Start MySQL from Windows

The MySQL container is managed from Windows Podman.

This is intentional.

When `podman.exe compose` is invoked from WSL, the external Compose provider running on Windows may incorrectly translate WSL paths such as:

```text
/mnt/c/...
```

into invalid Windows paths.

For that reason, start MySQL directly from PowerShell.

From the repository root:

```powershell
podman compose -f .\infra\compose.yaml up -d
```

Verify:

```powershell
podman ps
```

The container should include:

```text
mysql-dev
```

and should eventually report a healthy status.

---

# 17. Verify MySQL

From PowerShell:

```powershell
podman exec mysql-dev mysqladmin ping -h localhost -uappuser -papppass
```

Expected:

```text
mysqld is alive
```

The local connection information used by the demo is:

```text
Host: localhost
Port: 3306
User: appuser
Password: apppass
```

These credentials are for the local demo environment only.

---

# 18. Start the local HashiCorp environment

With MySQL already running on Windows, enter WSL and go to the repository directory.

For example:

```bash
cd /mnt/c/proys/apuntesdejava/jakartaee-nomad-arch
```

Then run:

```bash
./infra/scripts/start-local.sh
```

The script:

1. Verifies the required tools.
2. Verifies that `mysql-dev` is running in Podman Windows.
3. Starts Vault in development mode.
4. Starts Consul.
5. Starts Nomad.
6. Configures Vault.
7. Loads application configuration into Consul KV.
8. Submits the Nomad jobs.

The applications deployed are:

```text
clients-backend
products-backend
sales-backend
api-gateway
```

---

# 19. Local runtime architecture

After startup, the architecture is:

```text
                 Windows
                   │
                   │
           Podman Windows
                   │
                 MySQL
                   ▲
                   │
───────────────────┼──────────────────
                   │
                  WSL
                   │
       ┌───────────┼───────────┐
       │           │           │
     Vault       Consul      Nomad
                               │
                               ▼
                     nomad-driver-podman
                               │
                               ▼
                         Podman Linux
                               │
             ┌─────────────────┼────────────────┐
             │                 │                │
          clients           products          sales
             │                 │                │
             └─────────────────┼────────────────┘
                               │
                             Fabio
```

---

# 20. Verify Nomad jobs

Run:

```bash
nomad status
```

A healthy environment should show:

```text
ID                Type     Priority  Status
api-gateway       system   50        running
clients-backend   service  50        running
products-backend  service  50        running
sales-backend     service  50        running
```

---

# 21. Verify Consul services

Run:

```bash
consul catalog services
```

A healthy local environment should include:

```text
clients-backend
consul
fabio
nomad
nomad-client
products-backend
sales-backend
```

---

# 22. Verify Vault

Vault runs in development mode.

The local address is:

```text
http://127.0.0.1:8200
```

The development token is:

```text
root
```

Verify:

```bash
VAULT_ADDR=http://127.0.0.1:8200 vault status
```

---

# 23. Local URLs

When accessing the services from WSL:

| Service | URL |
|---|---|
| Nomad UI | `http://localhost:4646` |
| Consul UI | `http://localhost:8500` |
| Vault UI | `http://localhost:8200` |
| Fabio Gateway | `http://localhost:8000` |
| Fabio UI | `http://localhost:9998` |

When accessing the environment from Windows, `localhost` may work depending on the current WSL networking configuration.

If it does not, obtain the WSL IP:

```bash
hostname -I | awk '{print $1}'
```

Example:

```text
172.26.124.97
```

Then open:

```text
http://172.26.124.97:4646
http://172.26.124.97:8500
http://172.26.124.97:8200
http://172.26.124.97:8000
http://172.26.124.97:9998
```

The WSL IP may change when WSL restarts.

---

# 24. Why container image names are fully qualified

Podman does not necessarily assume Docker Hub for unqualified image names.

For example, this may fail:

```hcl
image = "apuntesdejava/products-hc-example-jvm:0.0.1"
```

with an error similar to:

```text
short-name "apuntesdejava/products-hc-example-jvm:0.0.1"
did not resolve to an alias and no unqualified-search registries are defined
```

The Nomad jobs therefore use fully-qualified names:

```hcl
image = "docker.io/apuntesdejava/products-hc-example-jvm:0.0.1"
```

The same applies to third-party images.

For example:

```hcl
image = "docker.io/fabiolb/fabio:1.7.0"
```

---

# 25. Fabio and host networking

Fabio reads service information from Consul.

Consul runs directly inside WSL, while Fabio runs inside Podman.

Because the local Podman installation is rootless, Fabio explicitly uses host networking:

```hcl
config {
  image        = "docker.io/fabiolb/fabio:1.7.0"
  network_mode = "host"
}
```

Without:

```hcl
network_mode = "host"
```

Fabio may fail to connect to Consul.

The typical error is:

```text
Error initializing backend.
dial tcp <wsl-ip>:8500: connect: connection refused

FATAL Timeout registering backend.
```

When host networking is enabled, Fabio can reach the Consul agent running inside WSL.

---

# 26. Viewing Nomad application logs

First list the allocations:

```bash
nomad job allocs clients-backend
```

Then:

```bash
nomad alloc logs <ALLOC_ID> clients
```

Follow the log:

```bash
nomad alloc logs -f <ALLOC_ID> clients
```

A convenient one-line command for the currently running allocation is:

```bash
nomad alloc logs -f $(
  nomad job allocs -json clients-backend |
  jq -r '.[] | select(.ClientStatus == "running") | .ID' |
  head -1
) clients
```

For Fabio:

```bash
nomad alloc logs -f $(
  nomad job allocs -json api-gateway |
  jq -r '.[] | select(.ClientStatus == "running") | .ID' |
  head -1
) fabio
```

---

# 27. Useful status commands

Nomad:

```bash
nomad status
```

Nomad node:

```bash
nomad node status -verbose
```

Consul:

```bash
consul members
```

Consul services:

```bash
consul catalog services
```

Vault:

```bash
VAULT_ADDR=http://127.0.0.1:8200 vault status
```

Podman inside WSL:

```bash
podman ps
```

Podman Windows:

```powershell
podman ps
```

---

# 28. HashiCorp process logs

The local startup script writes HashiCorp logs to:

```text
/tmp/vault.log
/tmp/consul.log
/tmp/nomad.log
```

For example:

```bash
tail -f /tmp/nomad.log
```

```bash
tail -f /tmp/consul.log
```

```bash
tail -f /tmp/vault.log
```

---

# 29. Restarting the local environment

MySQL can remain running in Windows Podman.

To restart the HashiCorp environment:

```bash
./infra/scripts/start-local.sh
```

If an old Nomad process remains active, check:

```bash
ps -ef | grep '[n]omad agent'
```

Because Nomad is started with `sudo`, it may require elevated permissions to terminate:

```bash
sudo pkill -f "nomad agent"
```

Similarly:

```bash
pkill -f "consul agent" || true
pkill -f "vault server" || true
```

Then run:

```bash
./infra/scripts/start-local.sh
```

---

# 30. Stop MySQL

From PowerShell:

```powershell
podman compose -f .\infra\compose.yaml down
```

To only stop it:

```powershell
podman stop mysql-dev
```

---

# 31. Troubleshooting

## Podman Machine is not running

Symptom:

```text
Cannot connect to Podman
```

Check:

```powershell
podman machine list
```

Start it:

```powershell
podman machine start
```

---

## Maven/Fabric8 cannot connect to Podman

Verify:

```powershell
$Env:DOCKER_HOST
```

Expected:

```text
npipe:////./pipe/podman-machine-default
```

Also verify:

```powershell
podman info
```

---

## Maven can build but cannot push

Verify the Maven server configuration:

```text
~/.m2/settings.xml
```

The server ID must match:

```xml
<id>docker.io</id>
```

Verify that the Docker Hub access token has Write permission.

---

## Nomad does not detect Podman

Check the socket:

```bash
systemctl --user status podman.socket
```

Verify:

```bash
ls -l /run/user/$(id -u)/podman/podman.sock
```

Verify the plugin:

```bash
ls -l /opt/nomad/plugins/nomad-driver-podman
```

Then:

```bash
nomad node status -verbose
```

Expected:

```text
podman    true    true    All Podman sockets are responding.
```

---

## Nomad reports `missing drivers`

Check:

```bash
nomad node status -verbose
```

If Podman does not appear as healthy, verify:

- `podman.socket`
- `plugin_dir`
- `socket_path`
- the installed `nomad-driver-podman` binary

---

## Podman cannot resolve an image name

Symptom:

```text
short-name ... did not resolve to an alias
```

Use fully-qualified image names:

```text
docker.io/<namespace>/<image>:<tag>
```

---

## Fabio continuously restarts

Inspect:

```bash
nomad job allocs api-gateway
```

Then:

```bash
nomad alloc status <ALLOC_ID>
```

And:

```bash
nomad alloc logs <ALLOC_ID> fabio
```

If the error contains:

```text
connect: connection refused
```

against Consul port `8500`, verify that the Fabio job contains:

```hcl
network_mode = "host"
```

---

## Verify Consul directly

From WSL:

```bash
curl http://127.0.0.1:8500/v1/status/leader
```

Also test the WSL IP:

```bash
WSL_IP=$(hostname -I | awk '{print $1}')
curl http://$WSL_IP:8500/v1/status/leader
```

Check the listener:

```bash
ss -ltnp | grep 8500
```

Expected:

```text
*:8500
```

---

## `podman.exe compose` fails when invoked from WSL

Do not start the Windows Compose environment through a WSL path.

Instead of:

```bash
podman.exe compose -f /mnt/c/.../infra/compose.yaml up -d
```

open PowerShell and run:

```powershell
podman compose -f .\infra\compose.yaml up -d
```

This avoids path conversion problems between WSL and the Windows Compose provider.

---

# 32. Quick startup checklist

For subsequent demo sessions, the complete startup sequence is much shorter.

From PowerShell:

```powershell
podman machine start
```

Then, from the project root:

```powershell
podman compose -f .\infra\compose.yaml up -d
```

Verify:

```powershell
podman ps
```

Enter WSL:

```powershell
wsl
```

Go to the project:

```bash
cd /mnt/c/proys/apuntesdejava/jakartaee-nomad-arch
```

Verify the Podman socket:

```bash
systemctl --user is-active podman.socket
```

Then:

```bash
./infra/scripts/start-local.sh
```

Finally:

```bash
nomad status
```

and:

```bash
consul catalog services
```

A healthy environment should show all application jobs running and all application services registered in Consul.

---

# 33. Expected final state

Nomad:

```text
api-gateway       running
clients-backend   running
products-backend  running
sales-backend     running
```

Consul:

```text
clients-backend
consul
fabio
nomad
nomad-client
products-backend
sales-backend
```

Nomad Podman driver:

```text
podman    true    true    All Podman sockets are responding.
```

At this point the complete local demo environment is ready.