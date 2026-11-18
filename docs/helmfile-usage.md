# Helmfile Usage

Working directory for all commands:

```bash
cd helm-deploy
```

Or use the wrapper from the repo root:

```bash
./scripts/deploy.sh <action> [release]
```

## Releases

| Release name | Values file | Role |
|---|---|---|
| `mcp-shared-gateway` | `shared-gateway-values.yaml` | One Gateway + Certificate (shared IP) |
| `mcp-technical-knowledge` | `technical-knowledge-values.yaml` | MCP pod + HTTPRoute |
| `mcp-wobbegong-sql` | `wobbegong-sql-values.yaml` | MCP pod + HTTPRoute |
| `mcp-gtiss-dis-knowledge` | `gtiss-dis-knowledge-values.yaml` | MCP pod + HTTPRoute |
| `mcp-devsecops-knowledge` | `devsecops-knowledge-values.yaml` | MCP pod + HTTPRoute |
| `mcp-atoms-knowledge` | `atoms-knowledge-values.yaml` | MCP pod + HTTPRoute |

MCP service releases declare `needs: mcp/mcp-shared-gateway` so the shared Gateway is applied first.

Namespace: `mcp` (created automatically when supported by the cluster/Helmfile settings).

## Validate / render

```bash
helmfile lint
helmfile template
./scripts/deploy.sh lint
./scripts/deploy.sh template
./scripts/deploy.sh template mcp-technical-knowledge
```

## Deploy all services

```bash
# Ensure Secrets exist first (see docs/secrets.md)
helmfile apply
# or
./scripts/deploy.sh apply
```

## Deploy / upgrade one service

```bash
helmfile -l name=mcp-technical-knowledge apply
./scripts/deploy.sh apply mcp-wobbegong-sql
```

Independent upgrades do not restart other MCP releases.

## Diff and status

```bash
helmfile diff
helmfile -l name=mcp-atoms-knowledge status
./scripts/deploy.sh diff mcp-devsecops-knowledge
```

## Remove a release

Destructive operations require an explicit confirmation flag with the wrapper:

```bash
./scripts/deploy.sh destroy mcp-wobbegong-sql --yes
# or
helmfile -l name=mcp-wobbegong-sql destroy
```

## Air-gapped notes

- Chart path is local (`../helm-chart/mcp-server`); no remote chart repositories are required.
- `helmDefaults.skipDeps: true` avoids dependency fetches.
- Images must already exist in the internal registry referenced by each values file.
