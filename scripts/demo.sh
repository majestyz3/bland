#!/usr/bin/env bash
set -euo pipefail

bash scripts/preflight.sh

echo
echo "=== PLAN ==="
terraform plan -out=demo.tfplan

echo
echo "=== APPLY ==="
terraform apply demo.tfplan

echo
echo "=== OUTPUTS ==="
terraform output

echo
echo "=== IDEMPOTENCY CHECK ==="
set +e
terraform plan -detailed-exitcode
code=$?
set -e

case "$code" in
  0)
    echo "PASS: second plan is clean. Terraform configuration is idempotent."
    ;;
  2)
    echo "WARNING: second plan contains changes. Review before interview." >&2
    exit 2
    ;;
  *)
    echo "ERROR: terraform plan failed." >&2
    exit "$code"
    ;;
esac
