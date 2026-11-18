# Configuration Reference

## Chart values (`helm-chart/mcp-server/values.yaml`)

| Key | Default | Notes |
|---|---|---|
| `replicaCount` | `1` | Keep at 1 for SQLite writers |
| `image.repository` | `""` | Required per release |
| `image.tag` | `""` | Falls back to chart `appVersion` |
| `image.pullPolicy` | `IfNotPresent` | Prefer this in air-gapped clusters |
| `imagePullSecrets` | `artifactory-registry-secret` | Rename as needed |
| `command` / `args` | `[]` | Override container entrypoint/CLI |
| `service.type` | `ClusterIP` | Default internal-only |
| `service.port` / `targetPort` | `8000` | Confirm against real bind port |
| `mcp.transport` | `streamable-http` | **Documentation/intent only** until verified |
| `mcp.endpoint` | `/mcp` | Preferred; verify support in script |
| `env` / `envFrom` | `[]` | Prefer Secret refs for credentials |
| `resources` | see values | Per-service overrides recommended |
| `probes.*.type` | `tcp` | Use `http` + `path` when app health exists |
| `serviceAccount.create` | `true` | |
| `serviceAccount.automount` | `false` | |
| `rbac.create` | `false` | Enable only if API access is required |
| `gateway.enabled` | `false` | Enable Gateway API HTTPRoute (and optional Gateway) |
| `gateway.create` | `true` | Create a Gateway that can allocate a routable/LB IP |
| `gateway.gatewayClassName` | `""` | Required when `create=true` (e.g. `cilium`) |
| `gateway.addresses` | `[]` | Optional static `IPAddress` / hostname requests |
| `gateway.hostnames` | `[]` | HTTPRoute / Certificate hostnames |
| `gateway.http.enabled` | `true` | Plaintext HTTP listener (set `false` for HTTPS-only) |
| `gateway.tls.enabled` | `false` | HTTPS listener with TLS terminate |
| `gateway.tls.port` | `443` | HTTPS listener port |
| `gateway.tls.sectionName` | `https` | Listener name used by HTTPRoute `parentRefs` |
| `gateway.certificate.enabled` | `false` | Enable cert-manager Certificate |
| `gateway.certificate.dnsNames` | `[]` | SANs; defaults to `gateway.hostnames` |
| `gateway.certificate.issuerRef` | see values | Internal CA Issuer/ClusterIssuer |
| `gateway.pathPrefix` | `""` | Defaults to `mcp.endpoint` then `/` |
| `gateway.parentRefs` | `[]` | Use instead of `create` to attach to a shared Gateway |
| `networkPolicy.enabled` | `false` | Cilium-compatible when enabled |
| `serviceMonitor.enabled` | `false` | Enable only with real `/metrics` |
| `persistence.enabled` | `false` | SQLite / file state |
| `persistence.existingClaim` | `""` | Prefer existing PVC when available |
| `extraVolumes` / `extraVolumeMounts` | `[]` | |
| `tmpVolume.enabled` | `true` | Needed with read-only root FS |

## Placeholder / verify-before-production settings

The following are **placeholders** until the Python scripts are inspected:

| Area | Placeholder | Action required |
|---|---|---|
| Neo4j env names | `NEO4J_URI`, `NEO4J_DATABASE`, `NEO4J_USERNAME`, `NEO4J_PASSWORD` | Confirm exact names in each Neo4j-backed script |
| SQLite env names | `SQLITE_DB_PATH`, `SQLITE_READ_ONLY` | Confirm against `wobbegong_sql_mcp.py` |
| DevSecOps URLs/tokens | `JIRA_*`, `GITLAB_*`, `CONFLUENCE_*`, `ARTIFACTORY_*` | Confirm names, auth scheme, and read-only controls |
| MCP transport | `streamable-http` + `/mcp` | Inspect entrypoint; adjust `command`/`args`/probes |
| Image registry host | `artifactory.tahaa.local/...` | Override if the internal registry differs |
| ServiceMonitor path | `/metrics` | Enable only if implemented |
| Health probes | TCP | Switch to HTTP health path if provided |

## Service-specific files

| File | Focus |
|---|---|
| `helm-deploy/technical-knowledge-values.yaml` | Neo4j technical graph |
| `helm-deploy/wobbegong-sql-values.yaml` | SQLite PVC, single replica |
| `helm-deploy/gtiss-dis-knowledge-values.yaml` | Independent Neo4j for GTISS/DIS |
| `helm-deploy/devsecops-knowledge-values.yaml` | Internal DevSecOps API credentials |
| `helm-deploy/atoms-knowledge-values.yaml` | Independent Neo4j for ATOMS |

## SQLite considerations

- One replica by default.
- Concurrent writers on shared filesystems are unsafe.
- Ensure PVC filesystem ownership matches container UID/GID (`10001`).
- Prefer read-only mode when the workload only needs queries.

## Transport configuration caution

Setting:

```yaml
mcp:
  transport: streamable-http
  endpoint: /mcp
```

does **not** change a stdio-only Python server into an HTTP server. Align the container `command`/`args` with the real application, and document any HTTP adapter requirement.
