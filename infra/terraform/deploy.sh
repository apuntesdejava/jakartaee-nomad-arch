#!/bin/bash
# Helper script para gestionar la infraestructura Terraform en Azure
# Uso: ./deploy.sh [init|plan|apply|destroy|output|connect|copy-jobs]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${SCRIPT_DIR}/terraform.tfstate"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones
print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform no está instalado"
        exit 1
    fi
    print_success "Terraform encontrado: $(terraform version -json | grep terraform_version -m 1)"
}

check_tfvars() {
    if [ ! -f "${SCRIPT_DIR}/terraform.tfvars" ]; then
        print_error "terraform.tfvars no encontrado"
        echo "Crear desde ejemplo:"
        echo "  cp ${SCRIPT_DIR}/terraform.tfvars.example ${SCRIPT_DIR}/terraform.tfvars"
        echo "  nano ${SCRIPT_DIR}/terraform.tfvars"
        exit 1
    fi
    print_success "terraform.tfvars encontrado"
}

cmd_init() {
    print_header "Inicializando Terraform"
    check_terraform
    cd "${SCRIPT_DIR}"
    terraform init
    print_success "Terraform inicializado"
}

cmd_plan() {
    print_header "Planificando cambios"
    check_terraform
    check_tfvars
    cd "${SCRIPT_DIR}"
    terraform plan -out=tfplan
    print_success "Plan generado: tfplan"
}

cmd_apply() {
    print_header "Aplicando cambios"
    check_terraform
    check_tfvars

    if [ ! -f "${SCRIPT_DIR}/tfplan" ]; then
        print_error "tfplan no encontrado. Ejecuta primero: $0 plan"
        exit 1
    fi

    cd "${SCRIPT_DIR}"
    print_warning "Esto creará recursos en Azure y incurrirá en costos"
    read -p "¿Continuar? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        terraform apply tfplan
        rm tfplan
        print_success "Infraestructura desplegada"
        sleep 2
        cmd_output
    else
        print_warning "Operación cancelada"
    fi
}

cmd_destroy() {
    print_header "Destruyendo recursos"
    check_terraform
    check_tfvars

    cd "${SCRIPT_DIR}"
    print_error "ADVERTENCIA: Esto eliminará TODOS los recursos en Azure"
    read -p "¿Estás seguro? (escribir 'sí' para confirmar): " -r
    echo
    if [[ $REPLY == "sí" ]]; then
        terraform destroy
        print_success "Recursos destruidos"
    else
        print_warning "Operación cancelada"
    fi
}

cmd_output() {
    print_header "Información de Despliegue"
    check_terraform
    cd "${SCRIPT_DIR}"

    if [ ! -f "${STATE_FILE}" ]; then
        print_error "No hay estado de Terraform. Ejecuta primero: $0 apply"
        exit 1
    fi

    terraform output deployment_info
}

cmd_connect() {
    print_header "Conectando a la VM"
    check_terraform
    cd "${SCRIPT_DIR}"

    if [ ! -f "${STATE_FILE}" ]; then
        print_error "No hay estado de Terraform"
        exit 1
    fi

    VM_IP=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")
    if [ -z "$VM_IP" ]; then
        print_error "No se pudo obtener la IP de la VM"
        exit 1
    fi

    print_success "Conectando a azureuser@${VM_IP}"
    ssh -o StrictHostKeyChecking=no "azureuser@${VM_IP}"
}

cmd_copy_jobs() {
    print_header "Copiando jobs de Nomad a la VM"
    check_terraform

    JOBS_SRC="../nomad"
    if [ ! -d "${JOBS_SRC}" ]; then
        print_error "Directorio de jobs no encontrado: ${JOBS_SRC}"
        exit 1
    fi

    cd "${SCRIPT_DIR}"

    VM_IP=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")
    if [ -z "$VM_IP" ]; then
        print_error "No se pudo obtener la IP de la VM"
        exit 1
    fi

    print_success "Copiando jobs desde ${JOBS_SRC}/ a VM"
    scp -r "${JOBS_SRC}"/* "azureuser@${VM_IP}:/opt/nomad-jobs/" || print_error "Error al copiar"
    print_success "Jobs copiados"

    echo ""
    echo "Próximos pasos:"
    echo "1. Conectar: ssh azureuser@${VM_IP}"
    echo "2. Desplegar jobs:"
    echo "   nomad job run /opt/nomad-jobs/clients.nomad"
    echo "   nomad job run /opt/nomad-jobs/products.nomad"
    echo "   nomad job run /opt/nomad-jobs/sales.nomad"
}

cmd_logs() {
    print_header "Revisando logs de cloud-init"
    check_terraform

    cd "${SCRIPT_DIR}"

    VM_IP=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")
    if [ -z "$VM_IP" ]; then
        print_error "No se pudo obtener la IP de la VM"
        exit 1
    fi

    ssh "azureuser@${VM_IP}" "tail -100 /var/log/cloud-init-output.log"
}

cmd_status() {
    print_header "Estado de servicios"
    check_terraform

    cd "${SCRIPT_DIR}"

    VM_IP=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")
    if [ -z "$VM_IP" ]; then
        print_error "No se pudo obtener la IP de la VM"
        exit 1
    fi

    ssh "azureuser@${VM_IP}" "systemctl status consul-dev nomad-dev vault-dev fabio --no-pager"
}

cmd_refresh() {
    print_header "Refrescando estado"
    check_terraform
    check_tfvars
    cd "${SCRIPT_DIR}"
    terraform refresh
    print_success "Estado refrescado"
}

# Main
case "${1:-help}" in
    init)
        cmd_init
        ;;
    plan)
        cmd_plan
        ;;
    apply)
        cmd_apply
        ;;
    destroy)
        cmd_destroy
        ;;
    output)
        cmd_output
        ;;
    connect)
        cmd_connect
        ;;
    copy-jobs)
        cmd_copy_jobs
        ;;
    logs)
        cmd_logs
        ;;
    status)
        cmd_status
        ;;
    refresh)
        cmd_refresh
        ;;
    *)
        echo "Terraform Deployment Helper"
        echo ""
        echo "Uso: $0 <comando>"
        echo ""
        echo "Comandos:"
        echo "  init          - Inicializar Terraform"
        echo "  plan          - Planificar cambios"
        echo "  apply         - Aplicar cambios (crear infraestructura)"
        echo "  destroy       - Destruir todos los recursos"
        echo "  output        - Mostrar información de despliegue"
        echo "  connect       - Conectar por SSH a la VM"
        echo "  copy-jobs     - Copiar jobs de Nomad a la VM"
        echo "  logs          - Mostrar logs de cloud-init"
        echo "  status        - Mostrar estado de servicios"
        echo "  refresh       - Refrescar estado de Terraform"
        echo ""
        echo "Ejemplo flujo:"
        echo "  $0 init"
        echo "  $0 plan"
        echo "  $0 apply"
        echo "  $0 output"
        echo "  $0 copy-jobs"
        echo "  $0 connect"
        echo ""
        exit 0
        ;;
esac

