#!/usr/bin/env bash
# Validate MCP deployment infrastructure.
# Separates infrastructure checks from application readiness.
#
# Usage:
#   ./scripts/validate.sh
#   ./scripts/validate.sh --infra-only

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

INFRA_ONLY=false
if [[ "${1:-}" == "--infra-only" ]]; then
  INFRA_ONLY=true
fi

PASS=0
FAIL=0
SKIP=0
WARN=0

pass() { echo "[PASS] $*"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $*"; FAIL=$((FAIL + 1)); }
skip() { echo "[SKIP] $*"; SKIP=$((SKIP + 1)); }
warn() { echo "[WARN] $*"; WARN=$((WARN + 1)); }

need_cmd() {
  local cmd="$1"
  if command -v "${cmd}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

echo "=== MCP platform validation ==="
echo "Root: ${ROOT_DIR}"
echo

echo "--- Required infrastructure files ---"
REQUIRED_FILES=(
  dockerfiles/Dockerfile.technical-knowledge-mcp
  dockerfiles/Dockerfile.wobbegong-sql-mcp
  dockerfiles/Dockerfile.gtiss-dis-knowledge-mcp
  dockerfiles/Dockerfile.devsecops-knowledge-mcp
  dockerfiles/Dockerfile.atoms-knowledge-mcp
  helm-chart/mcp-server/Chart.yaml
  helm-chart/mcp-server/values.yaml
  helm-chart/mcp-server/templates/deployment.yaml
  helm-chart/mcp-server/templates/service.yaml
  helm-chart/mcp-server/templates/serviceaccount.yaml
  helm-chart/mcp-server/templates/rbac.yaml
  helm-chart/mcp-server/templates/servicemonitor.yaml
  helm-chart/mcp-server/templates/httproute.yaml
  helm-chart/mcp-server/templates/gateway.yaml
  helm-chart/mcp-server/templates/certificate.yaml
  helm-chart/mcp-server/templates/networkpolicy.yaml
  helm-chart/mcp-server/templates/configmap.yaml
  helm-chart/mcp-server/templates/_helpers.tpl
  helm-chart/mcp-server/templates/NOTES.txt
  helm-chart/mcp-server/.helmignore
  helm-chart/mcp-shared-gateway/Chart.yaml
  helm-chart/mcp-shared-gateway/values.yaml
  helm-chart/mcp-shared-gateway/templates/gateway.yaml
  helm-chart/mcp-shared-gateway/templates/certificate.yaml
  helm-chart/mcp-shared-gateway/templates/_helpers.tpl
  helm-chart/mcp-shared-gateway/templates/NOTES.txt
  helm-chart/mcp-shared-gateway/.helmignore
  helm-deploy/helmfile.yaml
  helm-deploy/shared-gateway-values.yaml
  helm-deploy/technical-knowledge-values.yaml
  helm-deploy/wobbegong-sql-values.yaml
  helm-deploy/gtiss-dis-knowledge-values.yaml
  helm-deploy/devsecops-knowledge-values.yaml
  helm-deploy/atoms-knowledge-values.yaml
  requirements/technical-knowledge.txt
  requirements/wobbegong-sql.txt
  requirements/gtiss-dis-knowledge.txt
  requirements/devsecops-knowledge.txt
  requirements/atoms-knowledge.txt
  scripts/build-images.sh
  scripts/validate.sh
  scripts/deploy.sh
  docs/architecture.md
  docs/build-images.md
  docs/helm-deployment.md
  docs/helmfile-usage.md
  docs/configuration.md
  docs/secrets.md
  docs/mcp-client-integration.md
  docs/monitoring.md
  docs/troubleshooting.md
  docs/airgap-deployment.md
  .dockerignore
  .gitignore
  README.md
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ -e "${f}" ]]; then
    pass "present: ${f}"
  else
    fail "missing: ${f}"
  fi
done

echo
echo "--- Python MCP sources (application readiness) ---"
SCRIPTS=(
  src/technical_knowledge_mcp.py
  src/wobbegong_sql_mcp.py
  src/gtiss_dis_knowledge_mcp.py
  src/devsecops_knowledge_mcp.py
  src/atoms_knowledge_mcp.py
)
MISSING_SCRIPTS=0
for s in "${SCRIPTS[@]}"; do
  if [[ -f "${s}" ]]; then
    pass "source present: ${s}"
  else
    warn "source missing: ${s} (expected; copy from isolated environment)"
    MISSING_SCRIPTS=$((MISSING_SCRIPTS + 1))
  fi
done

echo
echo "--- Requirements dependency status ---"
for req in requirements/*.txt; do
  if grep -Eq '^[[:space:]]*[^#[:space:]]' "${req}"; then
    pass "requirements has package entries: ${req}"
  else
    warn "unresolved dependencies (comments only): ${req}"
  fi
done

echo
echo "--- YAML / Helm infrastructure ---"
if need_cmd python3; then
  if python3 - <<'PY'
import sys, pathlib
try:
    import yaml  # type: ignore
except Exception:
    sys.exit(2)
root = pathlib.Path(".")
files = list(root.glob("helm-deploy/*.yaml")) + list(root.glob("helm-chart/mcp-server/values.yaml"))
for f in files:
    with f.open() as fh:
        list(yaml.safe_load_all(fh))
print("ok")
PY
  then
    pass "YAML parse (PyYAML) for helm values"
  else
    rc=$?
    if [[ "${rc}" -eq 2 ]]; then
      skip "PyYAML not installed; basic YAML parse skipped"
    else
      fail "YAML parse failed for helm values"
    fi
  fi
else
  skip "python3 not available for YAML parse"
fi

if need_cmd helm; then
  if helm lint helm-chart/mcp-server >/tmp/mcp-helm-lint.out 2>&1; then
    pass "helm lint mcp-server"
  else
    fail "helm lint failed (see /tmp/mcp-helm-lint.out)"
    cat /tmp/mcp-helm-lint.out >&2 || true
  fi

  if helm lint helm-chart/mcp-shared-gateway >/tmp/mcp-shared-gw-lint.out 2>&1; then
    pass "helm lint mcp-shared-gateway"
  else
    fail "helm lint mcp-shared-gateway failed"
    cat /tmp/mcp-shared-gw-lint.out >&2 || true
  fi

  mkdir -p validation-output
  if helm template mcp-shared-gateway helm-chart/mcp-shared-gateway \
    --namespace mcp \
    -f helm-deploy/shared-gateway-values.yaml \
    >validation-output/mcp-shared-gateway.yaml 2>/tmp/mcp-helm-template.err; then
    pass "helm template mcp-shared-gateway"
  else
    fail "helm template mcp-shared-gateway"
    cat /tmp/mcp-helm-template.err >&2 || true
  fi

  VALUES_FILES=(
    technical-knowledge-values.yaml
    wobbegong-sql-values.yaml
    gtiss-dis-knowledge-values.yaml
    devsecops-knowledge-values.yaml
    atoms-knowledge-values.yaml
  )
  RELEASE_NAMES=(
    mcp-technical-knowledge
    mcp-wobbegong-sql
    mcp-gtiss-dis-knowledge
    mcp-devsecops-knowledge
    mcp-atoms-knowledge
  )
  for i in "${!VALUES_FILES[@]}"; do
    vf="${VALUES_FILES[$i]}"
    rn="${RELEASE_NAMES[$i]}"
    out="validation-output/${rn}.yaml"
    if helm template "${rn}" helm-chart/mcp-server \
      --namespace mcp \
      -f "helm-deploy/${vf}" \
      >"${out}" 2>/tmp/mcp-helm-template.err; then
      pass "helm template ${rn}"
    else
      fail "helm template ${rn}"
      cat /tmp/mcp-helm-template.err >&2 || true
    fi
  done
else
  skip "helm not installed; chart lint/template skipped"
fi

if need_cmd helmfile; then
  if (cd helm-deploy && helmfile lint >/tmp/mcp-helmfile-lint.out 2>&1); then
    pass "helmfile lint"
  else
    # Older helmfile may not support lint the same way; try template as fallback signal.
    if (cd helm-deploy && helmfile template >/tmp/mcp-helmfile-template.out 2>&1); then
      warn "helmfile lint unavailable/failed; template succeeded"
      cat /tmp/mcp-helmfile-lint.out >&2 || true
    else
      fail "helmfile lint/template failed"
      cat /tmp/mcp-helmfile-lint.out >&2 || true
      cat /tmp/mcp-helmfile-template.out >&2 || true
    fi
  fi

  if (cd helm-deploy && helmfile template >/tmp/mcp-helmfile-template.out 2>&1); then
    pass "helmfile template"
    cp /tmp/mcp-helmfile-template.out validation-output/helmfile-template.yaml 2>/dev/null || true
  else
    fail "helmfile template failed"
    cat /tmp/mcp-helmfile-template.out >&2 || true
  fi
else
  skip "helmfile not installed; helmfile checks skipped"
fi

echo
echo "--- Script executability ---"
for s in scripts/build-images.sh scripts/validate.sh scripts/deploy.sh; do
  if [[ -x "${s}" ]]; then
    pass "executable: ${s}"
  else
    warn "not executable (chmod +x recommended): ${s}"
  fi
done

if [[ "${INFRA_ONLY}" == "true" ]]; then
  echo
  echo "Infra-only mode: skipping application build/runtime checks."
else
  echo
  echo "--- Application readiness (informational) ---"
  if [[ "${MISSING_SCRIPTS}" -gt 0 ]]; then
    warn "${MISSING_SCRIPTS} Python MCP scripts missing; Docker builds and runtime MCP tests cannot succeed yet."
  else
    pass "all Python MCP scripts present"
  fi
  if need_cmd docker; then
    skip "Docker image builds not run by validate.sh (use scripts/build-images.sh after sources exist)"
  else
    skip "docker not available; image build checks skipped"
  fi
fi

echo
echo "=== Summary ==="
echo "PASS=${PASS} FAIL=${FAIL} WARN=${WARN} SKIP=${SKIP}"
echo
if [[ "${FAIL}" -gt 0 ]]; then
  echo "Infrastructure validation FAILED."
  exit 1
fi

if [[ "${MISSING_SCRIPTS}" -gt 0 ]]; then
  echo "Infrastructure validation PASSED with unresolved application sources/dependencies."
  echo "Functional MCP readiness is NOT claimed."
  exit 0
fi

echo "Infrastructure validation PASSED."
exit 0
