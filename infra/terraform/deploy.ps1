# Helper script para gestionar la infraestructura Terraform en Azure (Windows PowerShell)
# Uso: .\deploy.ps1 -Command init|plan|apply|destroy|output|connect|copy-jobs

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("init", "plan", "apply", "destroy", "output", "connect", "copy-jobs", "logs", "status", "refresh", "help")]
    [string]$Command = "help"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StateFile = Join-Path $ScriptDir "terraform.tfstate"

# Funciones
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Check-Terraform {
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error "Terraform no está instalado"
        exit 1
    }
    $version = terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version
    Write-Success "Terraform encontrado: $version"
}

function Check-TFVars {
    $tfvarsPath = Join-Path $ScriptDir "terraform.tfvars"
    if (-not (Test-Path $tfvarsPath)) {
        Write-Error "terraform.tfvars no encontrado"
        Write-Host "Crear desde ejemplo:"
        Write-Host "  Copy-Item $tfvarsPath.example $tfvarsPath"
        Write-Host "  notepad $tfvarsPath"
        exit 1
    }
    Write-Success "terraform.tfvars encontrado"
}

function Cmd-Init {
    Write-Header "Inicializando Terraform"
    Check-Terraform
    Push-Location $ScriptDir
    terraform init
    Pop-Location
    Write-Success "Terraform inicializado"
}

function Cmd-Plan {
    Write-Header "Planificando cambios"
    Check-Terraform
    Check-TFVars
    Push-Location $ScriptDir
    terraform plan -out=tfplan
    Pop-Location
    Write-Success "Plan generado: tfplan"
}

function Cmd-Apply {
    Write-Header "Aplicando cambios"
    Check-Terraform
    Check-TFVars

    $tfplanPath = Join-Path $ScriptDir "tfplan"
    if (-not (Test-Path $tfplanPath)) {
        Write-Error "tfplan no encontrado. Ejecuta primero: .\deploy.ps1 -Command plan"
        exit 1
    }

    Push-Location $ScriptDir
    Write-Warning "Esto creará recursos en Azure e incurrirá en costos"
    $response = Read-Host "¿Continuar? (s/n)"
    if ($response -eq "s") {
        terraform apply tfplan
        Remove-Item tfplan -ErrorAction SilentlyContinue
        Write-Success "Infraestructura desplegada"
        Start-Sleep -Seconds 2
        Cmd-Output
    } else {
        Write-Warning "Operación cancelada"
    }
    Pop-Location
}

function Cmd-Destroy {
    Write-Header "Destruyendo recursos"
    Check-Terraform
    Check-TFVars

    Push-Location $ScriptDir
    Write-Error "ADVERTENCIA: Esto eliminará TODOS los recursos en Azure"
    $response = Read-Host "¿Estás seguro? (escribir 'sí' para confirmar)"
    if ($response -eq "sí") {
        terraform destroy
        Write-Success "Recursos destruidos"
    } else {
        Write-Warning "Operación cancelada"
    }
    Pop-Location
}

function Cmd-Output {
    Write-Header "Información de Despliegue"
    Check-Terraform
    Push-Location $ScriptDir

    if (-not (Test-Path $StateFile)) {
        Write-Error "No hay estado de Terraform. Ejecuta primero: .\deploy.ps1 -Command apply"
        Pop-Location
        exit 1
    }

    terraform output deployment_info
    Pop-Location
}

function Cmd-Connect {
    Write-Header "Conectando a la VM"
    Check-Terraform
    Push-Location $ScriptDir

    if (-not (Test-Path $StateFile)) {
        Write-Error "No hay estado de Terraform"
        Pop-Location
        exit 1
    }

    $vmIp = terraform output -raw vm_public_ip 2>$null
    if (-not $vmIp) {
        Write-Error "No se pudo obtener la IP de la VM"
        Pop-Location
        exit 1
    }

    Write-Success "Conectando a azureuser@$vmIp"
    ssh "azureuser@$vmIp"
    Pop-Location
}

function Cmd-CopyJobs {
    Write-Header "Copiando jobs de Nomad a la VM"
    Check-Terraform

    $jobsSrc = Join-Path $ScriptDir "../nomad"
    if (-not (Test-Path $jobsSrc)) {
        Write-Error "Directorio de jobs no encontrado: $jobsSrc"
        exit 1
    }

    Push-Location $ScriptDir

    $vmIp = terraform output -raw vm_public_ip 2>$null
    if (-not $vmIp) {
        Write-Error "No se pudo obtener la IP de la VM"
        Pop-Location
        exit 1
    }

    Write-Success "Copiando jobs desde $jobsSrc a VM"
    $jobs = Get-ChildItem $jobsSrc -Filter "*.nomad"
    foreach ($job in $jobs) {
        scp $job.FullName "azureuser@$vmIp`:/opt/nomad-jobs/"
    }
    Write-Success "Jobs copiados"

    Write-Host ""
    Write-Host "Próximos pasos:"
    Write-Host "1. Conectar: ssh azureuser@$vmIp"
    Write-Host "2. Desplegar jobs:"
    Write-Host "   nomad job run /opt/nomad-jobs/clients.nomad"
    Write-Host "   nomad job run /opt/nomad-jobs/products.nomad"
    Write-Host "   nomad job run /opt/nomad-jobs/sales.nomad"
    Pop-Location
}

function Cmd-Logs {
    Write-Header "Revisando logs de cloud-init"
    Check-Terraform

    Push-Location $ScriptDir

    $vmIp = terraform output -raw vm_public_ip 2>$null
    if (-not $vmIp) {
        Write-Error "No se pudo obtener la IP de la VM"
        Pop-Location
        exit 1
    }

    ssh "azureuser@$vmIp" "tail -100 /var/log/cloud-init-output.log"
    Pop-Location
}

function Cmd-Status {
    Write-Header "Estado de servicios"
    Check-Terraform

    Push-Location $ScriptDir

    $vmIp = terraform output -raw vm_public_ip 2>$null
    if (-not $vmIp) {
        Write-Error "No se pudo obtener la IP de la VM"
        Pop-Location
        exit 1
    }

    ssh "azureuser@$vmIp" "systemctl status consul-dev nomad-dev vault-dev fabio --no-pager"
    Pop-Location
}

function Cmd-Refresh {
    Write-Header "Refrescando estado"
    Check-Terraform
    Check-TFVars
    Push-Location $ScriptDir
    terraform refresh
    Pop-Location
    Write-Success "Estado refrescado"
}

function Cmd-Help {
    Write-Host ""
    Write-Host "Terraform Deployment Helper (Windows)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\deploy.ps1 -Command <comando>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Comandos:" -ForegroundColor Yellow
    Write-Host "  init          - Inicializar Terraform"
    Write-Host "  plan          - Planificar cambios"
    Write-Host "  apply         - Aplicar cambios (crear infraestructura)"
    Write-Host "  destroy       - Destruir todos los recursos"
    Write-Host "  output        - Mostrar información de despliegue"
    Write-Host "  connect       - Conectar por SSH a la VM"
    Write-Host "  copy-jobs     - Copiar jobs de Nomad a la VM"
    Write-Host "  logs          - Mostrar logs de cloud-init"
    Write-Host "  status        - Mostrar estado de servicios"
    Write-Host "  refresh       - Refrescar estado de Terraform"
    Write-Host "  help          - Mostrar esta ayuda"
    Write-Host ""
    Write-Host "Ejemplo flujo:" -ForegroundColor Yellow
    Write-Host "  .\deploy.ps1 -Command init"
    Write-Host "  .\deploy.ps1 -Command plan"
    Write-Host "  .\deploy.ps1 -Command apply"
    Write-Host "  .\deploy.ps1 -Command output"
    Write-Host "  .\deploy.ps1 -Command copy-jobs"
    Write-Host "  .\deploy.ps1 -Command connect"
    Write-Host ""
}

# Main
switch ($Command) {
    "init" { Cmd-Init }
    "plan" { Cmd-Plan }
    "apply" { Cmd-Apply }
    "destroy" { Cmd-Destroy }
    "output" { Cmd-Output }
    "connect" { Cmd-Connect }
    "copy-jobs" { Cmd-CopyJobs }
    "logs" { Cmd-Logs }
    "status" { Cmd-Status }
    "refresh" { Cmd-Refresh }
    "help" { Cmd-Help }
    default { Cmd-Help }
}

