# Architecture

## Overview

This repository packages five existing Python Model Context Protocol (MCP) services for air-gapped Kubernetes deployment. Each service runs in its own container, Helm release, Kubernetes Deployment, and ClusterIP Service. A single reusable Helm chart (`helm-chart/mcp-server`) is instantiated five times through Helmfile.

```text
MCP clients (Open WebUI, Cline, agents, …)
        │
        ▼
Kubernetes ClusterIP Services (namespace: mcp)
        │
        ├── mcp-technical-knowledge      → Technical Knowledge MCP  → Neo4j
        ├── mcp-wobbegong-sql            → Wobbegong SQL MCP        → SQLite PVC
        ├── mcp-gtiss-dis-knowledge      → GTISS/DIS Knowledge MCP  → Neo4j
        ├── mcp-devsecops-knowledge      → DevSecOps Knowledge MCP  → Jira/GitLab/Confluence/Artifactory
        └── mcp-atoms-knowledge          → ATOMS Knowledge MCP      → Neo4j
```

## Design principles

- **One chart, five releases** — independent upgrades, resources, secrets, and images.
- **ClusterIP by default** — no external exposure unless Gateway HTTPRoute is explicitly enabled.
- **Air-gapped friendly** — images and Python dependencies resolved at build time from internal mirrors.
- **No fabricated application logic** — Python entry points are supplied separately under `/src`.
- **Secrets outside Git** — credentials are referenced from Kubernetes Secrets only.

## Components

| Layer | Location | Role |
|---|---|---|
| Application sources | `src/*.py` | Existing MCP Python entry points (copied in manually) |
| Dependencies | `requirements/*.txt` | Per-service Python packages (verified after script inspection) |
| Images | `dockerfiles/*` | One Dockerfile per service |
| Chart | `helm-chart/mcp-server` | Reusable Deployment/Service/optional extras |
| Releases | `helm-deploy/*` | Helmfile + per-service values |
| Ops scripts | `scripts/*` | Build, validate, deploy wrappers |

## Networking

Each release creates a Service named after the Helm release:

| Service DNS | Intended use |
|---|---|
| `mcp-technical-knowledge.mcp.svc.cluster.local:8000` | Technical Knowledge |
| `mcp-wobbegong-sql.mcp.svc.cluster.local:8000` | Wobbegong SQL |
| `mcp-gtiss-dis-knowledge.mcp.svc.cluster.local:8000` | GTISS/DIS Knowledge |
| `mcp-devsecops-knowledge.mcp.svc.cluster.local:8000` | DevSecOps Knowledge |
| `mcp-atoms-knowledge.mcp.svc.cluster.local:8000` | ATOMS Knowledge |

If a service supports Streamable HTTP on `/mcp`, clients use:

```text
http://mcp-<service>.mcp.svc.cluster.local:8000/mcp
```

Do not treat that URL as confirmed until the corresponding Python script’s transport has been inspected and tested.

## Data dependencies

- **Neo4j-backed services** (Technical Knowledge, GTISS/DIS, ATOMS) use independent URIs, databases, and Secrets by default.
- **Wobbegong SQL** uses a file-backed SQLite database, typically on a PVC, with a single replica.
- **DevSecOps Knowledge** calls internal Jira, GitLab, Confluence, and Artifactory endpoints using Secret-backed tokens.

## MCP transport

Preferred transport is **Streamable HTTP** with endpoint `/mcp`. Actual transport depends on each Python implementation (stdio, SSE, or Streamable HTTP). Helm `mcp.transport` / `mcp.endpoint` document intent and feed Service notes; they do not rewrite the application. Use `command` / `args` to match the real CLI after inspection.

## Security boundaries

- Non-root containers, dropped capabilities, optional read-only root filesystem.
- RBAC disabled by default.
- Optional Cilium-compatible NetworkPolicy.
- MCP tools that can mutate external systems must be treated as privileged integrations.
