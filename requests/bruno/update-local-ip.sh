#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WSL_IP="$(hostname -I | awk '{print $1}')"

if [ -z "$WSL_IP" ]; then
  echo "✗ No se pudo determinar la IP actual de WSL." >&2
  exit 1
fi

echo "── IP de WSL detectada: $WSL_IP"

(
  cd "$SCRIPT_DIR"
  java UpdateIps.java env=LOCAL_HC ip="$WSL_IP"
)

echo "✓ Ambiente Bruno LOCAL_HC actualizado correctamente."

