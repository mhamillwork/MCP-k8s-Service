# MCP Kubernetes Services Platform

Production-oriented packaging for five existing Python Model Context Protocol (MCP) services on an **air-gapped** Kubernetes cluster.

This repository provides Dockerfiles, a reusable Helm chart, Helmfile releases, scripts, and documentation. The Python MCP implementations are supplied separately and copied into `src/`.

## Services

| Service | Script (expected in `src/`) | Helm release |
|---|---|---|
| Technical Knowledge | `technical_knowledge_mcp.py` | `mcp-technical-knowledge` |
| Wobbegong SQL | `wobbegong_sql_mcp.py` | `mcp-wobbegong-sql` |
| GTISS/DIS Knowledge | `gtiss_dis_knowledge_mcp.py` | `mcp-gtiss-dis-knowledge` |
| DevSecOps Knowledge | `devsecops_knowledge_mcp.py` | `mcp-devsecops-knowledge` |
| ATOMS Knowledge | `atoms_knowledge_mcp.py` | `mcp-atoms-knowledge` |

## Repository layout

```text
src/                 # Place existing MCP Python scripts here
dockerfiles/         # One Dockerfile per service
requirements/        # Per-service Python deps (unresolved until scripts arrive)
helm-chart/mcp-server/
helm-deploy/         # Helmfile + per-service values
docs/
scripts/
```

## Quick start

1. Copy the five existing Python scripts into `src/` (exact filenames above).
2. Inspect imports and update `requirements/*.txt` with verified pins.
3. Confirm MCP transport/port/endpoint; adjust Helm `command`/`args`/`mcp.*`/probes.
4. Create Kubernetes Secrets (see [docs/secrets.md](docs/secrets.md)).
5. Build and push images to the internal registry:

```bash
REGISTRY=artifactory.tahaa.local/tahaa-image-local/ai-services \
TAG=1.0.0 \
PYTHON_BASE_IMAGE=artifactory.tahaa.local/mirror/python:3.12-slim \
PUSH=true \
./scripts/build-images.sh
```

6. Validate infrastructure:

```bash
./scripts/validate.sh
```

7. Deploy with Helmfile (shared Gateway first, then MCP services):

```bash
./scripts/deploy.sh apply
# or:
./scripts/deploy.sh apply mcp-shared-gateway
./scripts/deploy.sh apply mcp-technical-knowledge
```

Shared Gateway client URLs (one IP, different ports):

```text
https://mcp.example.local:8443/mcp  # technical-knowledge
https://mcp.example.local:8444/mcp  # wobbegong-sql
https://mcp.example.local:8445/mcp  # gtiss-dis-knowledge
https://mcp.example.local:8446/mcp  # devsecops-knowledge
https://mcp.example.local:8447/mcp  # atoms-knowledge
```

## Documentation

- [Architecture](docs/architecture.md)
- [Build images](docs/build-images.md)
- [Helm deployment](docs/helm-deployment.md)
- [Helmfile usage](docs/helmfile-usage.md)
- [Configuration](docs/configuration.md)
- [Secrets](docs/secrets.md)
- [MCP client integration](docs/mcp-client-integration.md)
- [Monitoring](docs/monitoring.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Air-gapped deployment](docs/airgap-deployment.md)

## Status

**Infrastructure scaffolding is complete.** Functional MCP readiness requires the real Python scripts, verified dependencies, transport confirmation, and runtime testing. Missing sources and unresolved requirements are reported by `scripts/validate.sh` and documented under `requirements/` and `src/README.md`.
