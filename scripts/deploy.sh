#!/usr/bin/env bash
# Thin wrapper around helmfile for MCP releases.
# Does not deploy unless explicitly asked. Destructive actions require --yes.
#
# Usage:
#   ./scripts/deploy.sh template
#   ./scripts/deploy.sh lint
#   ./scripts/deploy.sh diff
#   ./scripts/deploy.sh apply
#   ./scripts/deploy.sh apply mcp-technical-knowledge
#   ./scripts/deploy.sh destroy mcp-wobbegong-sql --yes

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELM_DEPLOY="${ROOT_DIR}/helm-deploy"

usage() {
  cat <<EOF
Usage: $(basename "$0") <action> [release-name] [--yes]

Actions:
  lint       Validate helmfile/releases
  template   Render manifests
  diff       Show pending changes (requires cluster access)
  apply      Install/upgrade release(s)
  status     Show helmfile status
  destroy    Remove release(s) — requires --yes

Optional release-name selects a single Helmfile release, for example:
  mcp-technical-knowledge
  mcp-wobbegong-sql
  mcp-gtiss-dis-knowledge
  mcp-devsecops-knowledge
  mcp-atoms-knowledge

This script does not create unrelated Kubernetes resources and will not
uninstall releases unless destroy --yes is provided.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

ACTION="$1"
shift || true

RELEASE=""
CONFIRM=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      CONFIRM=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${RELEASE}" ]]; then
        RELEASE="$1"
        shift
      else
        echo "ERROR: Unexpected argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if ! command -v helmfile >/dev/null 2>&1; then
  echo "ERROR: helmfile is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "ERROR: helm is not installed or not on PATH." >&2
  exit 1
fi

SELECTOR_ARGS=()
if [[ -n "${RELEASE}" ]]; then
  SELECTOR_ARGS=(-l "name=${RELEASE}")
fi

cd "${HELM_DEPLOY}"

case "${ACTION}" in
  lint)
    helmfile "${SELECTOR_ARGS[@]}" lint
    ;;
  template)
    helmfile "${SELECTOR_ARGS[@]}" template
    ;;
  diff)
    helmfile "${SELECTOR_ARGS[@]}" diff
    ;;
  status)
    helmfile "${SELECTOR_ARGS[@]}" status
    ;;
  apply)
    echo "Applying MCP release(s) via helmfile (namespace creation enabled by helmfile defaults)."
    helmfile "${SELECTOR_ARGS[@]}" apply
    ;;
  destroy|delete|uninstall)
    if [[ "${CONFIRM}" != "true" ]]; then
      echo "ERROR: Refusing destructive action without --yes" >&2
      echo "Example: $0 destroy ${RELEASE:-mcp-technical-knowledge} --yes" >&2
      exit 1
    fi
    echo "Destroying MCP release(s) via helmfile..."
    helmfile "${SELECTOR_ARGS[@]}" destroy
    ;;
  *)
    echo "ERROR: Unknown action '${ACTION}'" >&2
    usage
    exit 1
    ;;
esac
