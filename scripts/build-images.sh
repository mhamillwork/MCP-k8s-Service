#!/usr/bin/env bash
# Build (and optionally push) MCP service container images.
# Always build from the repository root so Dockerfiles can access /src and /requirements.
#
# Usage:
#   ./scripts/build-images.sh                     # build all
#   ./scripts/build-images.sh technical-knowledge # build one
#   REGISTRY=artifactory.tahaa.local/tahaa-image-local/ai-services \
#     TAG=1.0.0 PUSH=true ./scripts/build-images.sh
#
# Environment:
#   REGISTRY              Image registry prefix (default: local names only)
#   TAG                   Image tag (default: 1.0.0)
#   PYTHON_BASE_IMAGE     Base image override for air-gapped mirrors
#   PUSH                  Set to true to docker push after build
#   DOCKER                Docker-compatible CLI (default: docker)
#   PIP_INDEX_URL         Optional pip index for air-gapped builds (passed as build-arg)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

DOCKER="${DOCKER:-docker}"
TAG="${TAG:-1.0.0}"
REGISTRY="${REGISTRY:-}"
PYTHON_BASE_IMAGE="${PYTHON_BASE_IMAGE:-python:3.12-slim}"
PUSH="${PUSH:-false}"
PIP_INDEX_URL="${PIP_INDEX_URL:-}"

declare -A SERVICES=(
  [technical-knowledge]="dockerfiles/Dockerfile.technical-knowledge-mcp|src/technical_knowledge_mcp.py|technical-knowledge-mcp"
  [wobbegong-sql]="dockerfiles/Dockerfile.wobbegong-sql-mcp|src/wobbegong_sql_mcp.py|wobbegong-sql-mcp"
  [gtiss-dis-knowledge]="dockerfiles/Dockerfile.gtiss-dis-knowledge-mcp|src/gtiss_dis_knowledge_mcp.py|gtiss-dis-knowledge-mcp"
  [devsecops-knowledge]="dockerfiles/Dockerfile.devsecops-knowledge-mcp|src/devsecops_knowledge_mcp.py|devsecops-knowledge-mcp"
  [atoms-knowledge]="dockerfiles/Dockerfile.atoms-knowledge-mcp|src/atoms_knowledge_mcp.py|atoms-knowledge-mcp"
)

ORDER=(technical-knowledge wobbegong-sql gtiss-dis-knowledge devsecops-knowledge atoms-knowledge)

usage() {
  cat <<EOF
Usage: $(basename "$0") [service-key]

Service keys:
  ${ORDER[*]}

Environment overrides:
  REGISTRY, TAG, PYTHON_BASE_IMAGE, PUSH, DOCKER, PIP_INDEX_URL
EOF
}

image_ref() {
  local name="$1"
  if [[ -n "${REGISTRY}" ]]; then
    printf "%s/%s:%s" "${REGISTRY%/}" "${name}" "${TAG}"
  else
    printf "%s:%s" "${name}" "${TAG}"
  fi
}

require_tools() {
  if ! command -v "${DOCKER}" >/dev/null 2>&1; then
    echo "ERROR: ${DOCKER} is not available on PATH." >&2
    exit 1
  fi
}

check_sources() {
  local key="$1"
  local IFS='|'
  local parts=(${SERVICES[$key]})
  local dockerfile="${parts[0]}"
  local script="${parts[1]}"
  local missing=0

  if [[ ! -f "${dockerfile}" ]]; then
    echo "ERROR: Missing Dockerfile: ${dockerfile}" >&2
    missing=1
  fi
  if [[ ! -f "${script}" ]]; then
    echo "ERROR: Missing Python source: ${script}" >&2
    echo "       Copy the existing MCP script into place before building." >&2
    missing=1
  fi
  return "${missing}"
}

build_one() {
  local key="$1"
  if [[ -z "${SERVICES[$key]+x}" ]]; then
    echo "ERROR: Unknown service key '${key}'" >&2
    usage
    return 1
  fi

  local IFS='|'
  local parts=(${SERVICES[$key]})
  local dockerfile="${parts[0]}"
  local image_name="${parts[2]}"
  local ref
  ref="$(image_ref "${image_name}")"

  echo "==> Building ${key}"
  echo "    Dockerfile: ${dockerfile}"
  echo "    Image:      ${ref}"
  echo "    Base:       ${PYTHON_BASE_IMAGE}"

  if ! check_sources "${key}"; then
    echo "ERROR: Build aborted for ${key} due to missing inputs." >&2
    return 1
  fi

  local -a build_args=(
    --file "${dockerfile}"
    --tag "${ref}"
    --build-arg "PYTHON_BASE_IMAGE=${PYTHON_BASE_IMAGE}"
  )

  if [[ -n "${PIP_INDEX_URL}" ]]; then
    # Consumers can extend Dockerfiles to honor PIP_INDEX_URL if needed.
    build_args+=(--build-arg "PIP_INDEX_URL=${PIP_INDEX_URL}")
  fi

  if ! "${DOCKER}" build "${build_args[@]}" "${ROOT_DIR}"; then
    echo "ERROR: docker build failed for ${key}" >&2
    echo "Hints:" >&2
    echo "  - Ensure base image '${PYTHON_BASE_IMAGE}' is available locally or in the mirror." >&2
    echo "  - Ensure requirements/*.txt contain verified packages for air-gapped pip installs." >&2
    echo "  - Build context must be the repository root." >&2
    return 1
  fi

  if [[ "${PUSH}" == "true" ]]; then
    if [[ -z "${REGISTRY}" ]]; then
      echo "ERROR: PUSH=true requires REGISTRY to be set." >&2
      return 1
    fi
    echo "==> Pushing ${ref}"
    "${DOCKER}" push "${ref}"
  fi

  echo "==> OK ${key} -> ${ref}"
}

main() {
  require_tools

  local targets=()
  if [[ $# -eq 0 ]]; then
    targets=("${ORDER[@]}")
  elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  else
    targets=("$@")
  fi

  local failed=0
  local key
  for key in "${targets[@]}"; do
    if ! build_one "${key}"; then
      failed=1
    fi
  done

  if [[ "${failed}" -ne 0 ]]; then
    echo "ERROR: One or more image builds failed." >&2
    exit 1
  fi
  echo "All requested image builds succeeded."
}

main "$@"
