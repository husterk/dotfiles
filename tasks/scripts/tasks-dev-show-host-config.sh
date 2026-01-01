#!/usr/bin/env bash
set -euo pipefail

# Show current environment configuration

HOST_DIR="${1:?HOST_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
BOOTSTRAP_TARGET="${3:?BOOTSTRAP_TARGET required}"
REPO_ROOT="${4:?REPO_ROOT required}"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     Environment Variables                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Task Variables:"
echo "  HOSTNAME:          $HOSTNAME"
echo "  BOOTSTRAP_TARGET:  $BOOTSTRAP_TARGET"
echo "  REPO_ROOT:         $REPO_ROOT"
echo "  HOST_DIR:          $HOST_DIR"
echo ""

if [ -f "$HOST_DIR/generated/.env" ]; then
  echo "Environment Variables (.env):"
  while IFS= read -r line; do
    # Skip comments and empty lines
    if [[ ! "$line" =~ ^[[:space:]]*# ]] && [ -n "$line" ]; then
      # Mask secret values
      var_name=$(echo "$line" | cut -d= -f1)
      echo "  $var_name: [set]"
    fi
  done < "$HOST_DIR/generated/.env"
else
  echo "⚠️  .env not found"
fi
echo ""
