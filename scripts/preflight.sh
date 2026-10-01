#!/usr/bin/env bash
set -euo pipefail

fail=0

for cmd in terraform git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is not installed." >&2
    fail=1
  else
    echo "OK: $cmd -> $(command -v "$cmd")"
  fi
done

if [[ -z "${BLAND_API_KEY:-}" ]]; then
  echo "ERROR: BLAND_API_KEY is not set." >&2
  fail=1
else
  echo "OK: BLAND_API_KEY is set (value hidden)."
fi

if command -v terraform >/dev/null 2>&1; then
  echo "Terraform version:"
  terraform version | head -n 1
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "Running terraform fmt/validate prechecks..."
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate

echo "Preflight passed."
