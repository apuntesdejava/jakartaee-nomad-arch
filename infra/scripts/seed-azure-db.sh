#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$INFRA_DIR/terraform"
SQL_FILE="${SQL_FILE:-$INFRA_DIR/mysql/init/init.sql}"

RESET=false

usage() {
  cat <<EOF
Uso: $0 [--reset]

Carga infra/mysql/init/init.sql en Azure MySQL usando la VM de control como salto.

Opciones:
  --reset   Elimina las tablas de demo y las vuelve a crear antes de cargar datos.

Variables opcionales:
  SQL_FILE        Ruta del script SQL a ejecutar.
  MYSQL_HOST      Host Azure MySQL. Si no se define, se lee de terraform output.
  MYSQL_USER      Usuario MySQL. Si no se define, se lee de terraform.tfvars.
  MYSQL_PASSWORD  Password MySQL. Si no se define, se lee de terraform.tfvars.
  SSH_TARGET      Usuario/IP SSH. Si no se define, se arma con terraform output.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --reset)
      RESET=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "✗ Opción no reconocida: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "✗ '$1' no encontrado."
    exit 1
  fi
}

tfvar() {
  local name="$1"
  awk -F= -v key="$name" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value=$2
      sub(/#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$TERRAFORM_DIR/terraform.tfvars"
}

run_mysql() {
  local query="$1"
  ssh "$SSH_TARGET" "docker run --rm mysql:9.7 mysql -N -B -h '$MYSQL_HOST' -u '$MYSQL_USER' -p'$MYSQL_PASSWORD' appdb -e \"$query\""
}

require_tool terraform
require_tool ssh

if [ ! -f "$SQL_FILE" ]; then
  echo "✗ No existe el archivo SQL: $SQL_FILE"
  exit 1
fi

MYSQL_HOST="${MYSQL_HOST:-}"
MYSQL_USER="${MYSQL_USER:-}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-}"
SSH_TARGET="${SSH_TARGET:-}"

if [ -z "$MYSQL_HOST" ]; then
  MYSQL_HOST="$(terraform -chdir="$TERRAFORM_DIR" output -raw mysql_host)"
fi

if [ -z "$SSH_TARGET" ]; then
  CONTROL_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw control_public_ip)"
  ADMIN_USER="$(tfvar admin_username)"
  SSH_TARGET="${ADMIN_USER:-azureuser}@$CONTROL_IP"
fi

if [ -z "$MYSQL_USER" ]; then
  MYSQL_USER="$(tfvar mysql_user)"
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  MYSQL_PASSWORD="$(tfvar mysql_password)"
fi

if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
  echo "✗ No se pudo obtener mysql_user/mysql_password."
  echo "  Define MYSQL_USER y MYSQL_PASSWORD, o revisa infra/terraform/terraform.tfvars."
  exit 1
fi

echo "── Azure MySQL: $MYSQL_HOST/appdb"
echo "── SSH control: $SSH_TARGET"
echo "── SQL: $SQL_FILE"

TABLE_COUNT="$(run_mysql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='appdb' AND table_name IN ('client','product','sale','sale_detail');" | tr -d '[:space:]')"

if [ "$TABLE_COUNT" != "0" ] && [ "$RESET" = false ]; then
  echo "✗ La base appdb ya tiene tablas de demo ($TABLE_COUNT/4)."
  echo "  Para recrearlas y sembrar desde cero ejecuta:"
  echo "  $0 --reset"
  exit 1
fi

if [ "$RESET" = true ]; then
  echo "── Eliminando tablas de demo..."
  run_mysql "SET FOREIGN_KEY_CHECKS=0; DROP TABLE IF EXISTS sale_detail; DROP TABLE IF EXISTS sale; DROP TABLE IF EXISTS client; DROP TABLE IF EXISTS product; SET FOREIGN_KEY_CHECKS=1;"
fi

echo "── Cargando datos iniciales..."
ssh "$SSH_TARGET" "docker run --rm -i mysql:9.7 mysql -h '$MYSQL_HOST' -u '$MYSQL_USER' -p'$MYSQL_PASSWORD' appdb" < "$SQL_FILE"

echo "── Verificando..."
run_mysql "SHOW TABLES; SELECT COUNT(*) AS clients FROM client; SELECT COUNT(*) AS products FROM product; SELECT COUNT(*) AS sales FROM sale;"

echo ""
echo "✓ Azure MySQL sembrado correctamente."
