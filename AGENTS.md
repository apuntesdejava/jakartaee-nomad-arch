# AGENTS.md

## Project purpose

This repository demonstrates a Jakarta EE and Quarkus architecture using:

- HashiCorp Nomad
- Consul
- Vault
- Fabio
- Podman
- MySQL
- Terraform
- Azure

The current local container runtime is Podman.

Docker is no longer a supported runtime for the local environment.

## Important architectural context

The local environment intentionally uses two separate Podman installations:

- Podman on Windows:
    - Maven/Fabric8 image build and push
    - MySQL through Podman Compose

- Podman inside WSL2:
    - Nomad task runtime
    - application workloads
    - Fabio

Nomad, Consul and Vault run inside WSL2.

The two Podman installations do not share the same image store.

See:

- `README.md`
- `docs/local-environment.md`

These documents are the source of truth for the current local architecture.

## Docker-related terminology

Do not blindly remove every occurrence of the word `docker`.

The following are legitimate and may remain:

- `docker.io`
    - This is the Docker Hub registry hostname.

- `io.fabric8:docker-maven-plugin`
    - This is the actual Maven plugin name.
    - The plugin is intentionally used against Podman's Docker-compatible API.

- `DOCKER_HOST`
    - This is intentionally used to point Fabric8 to Podman's Docker-compatible Windows named pipe.

- `Dockerfile`
    - Podman consumes standard Dockerfile/Containerfile syntax.
    - Do not rename existing Dockerfiles unless explicitly requested.

- `.dockerignore`
    - Keep unless there is a concrete technical reason to replace it.

- Quarkus-generated `src/main/docker/` directories
    - Keep unless explicitly requested.

When cleaning Docker references, distinguish between:

1. Docker as a runtime or required tool — remove or replace.
2. Docker-compatible API terminology — may remain.
3. Docker Hub registry terminology — must remain where technically correct.
4. File/plugin names imposed by external tools — do not rename unnecessarily.

## Local runtime policy

The supported local environment is Podman-only.

Do not add Docker fallback logic to scripts.

Do not document Docker Desktop as a requirement.

Do not add `docker` CLI commands to the local setup unless explicitly required for historical documentation.

Prefer:

```bash
podman
```
or, when intentionally invoking Windows Podman from WSL:
```bash
podman.exe
```

### Script expectations

Scripts under `infra/scripts` should:

* fail clearly when required tools are missing;
* print actionable error messages;
* avoid silently falling back to Docker;
* preserve current working Podman behavior;
* remain usable from WSL;
* avoid hardcoded machine-specific paths where possible.

Do not change unrelated behavior while performing cleanup tasks.

### Nomad

Local Nomad workloads use:

```hcl
driver = "podman"
```

Container image names should be fully qualified, for example:

```
docker.io/apuntesdejava/products-hc-example-jvm:0.0.1
```

Fabio requires:

```
network_mode = "host"
```

in the local Podman setup so it can reach Consul running in WSL.

Do not revert these settings.

### Validation

After modifying shell scripts:

```
bash -n <script>
```

For changes involving the local environment, inspect at minimum:
```
nomad status
consul catalog services
```
when the environment is available.

Do not claim runtime validation was performed if the environment is unavailable.

Change discipline

For each requested task:

1. Inspect the relevant files first.
2. Make only changes required for the task.
3. Preserve unrelated working behavior.
4. Show a concise summary of changed files.
5. Explain any Docker-related occurrence intentionally left unchanged.
6. Report validation performed and validation not performed.

Do not perform broad repository-wide cleanup unless explicitly requested.
