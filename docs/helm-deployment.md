# Helm Chart Deployment

## Chart location

```text
helm-chart/mcp-server
```

One chart deploys one MCP service. Do not duplicate the chart per service; use Helmfile releases with different values files.

## Resources created

| Resource | When |
|---|---|
| Deployment | Always |
| Service (ClusterIP) | Always |
| ServiceAccount | `serviceAccount.create=true` (default) |
| Role / RoleBinding | `rbac.create=true` (default **false**) |
| ConfigMap | `configMap.enabled=true` |
| PersistentVolumeClaim | `persistence.enabled=true` and no `existingClaim` |
| ServiceMonitor | `serviceMonitor.enabled=true` |
| HTTPRoute | `gateway.enabled=true` |
| NetworkPolicy | `networkPolicy.enabled=true` |

## Core parameters

See `helm-chart/mcp-server/values.yaml` and [configuration.md](configuration.md) for the full list.

Important groups:

- `image.*` / `imagePullSecrets`
- `command` / `args`
- `service.*`
- `mcp.transport` / `mcp.endpoint`
- `env` / `envFrom`
- `resources`
- `probes.*`
- `persistence.*`
- `gateway.*`
- `networkPolicy.*`
- `serviceMonitor.*`
- `rbac.*`
- security contexts

## Security defaults

- Non-root UID/GID `10001`
- Privilege escalation disabled
- All capabilities dropped
- Read-only root filesystem enabled (with `/tmp` emptyDir)
- ServiceAccount token not automounted
- RBAC off unless explicitly required

## Storage

Enable persistence for SQLite (Wobbegong) or other file state:

```yaml
persistence:
  enabled: true
  existingClaim: "wobbegong-sqlite-pvc"
  mountPath: /data
  readOnly: false
```

Do not enable PVC by default for Neo4j clients that only use external databases.

## Probes

Default probes are TCP against the service target port. Switch to HTTP only when the application exposes a dedicated health path. Do not probe `/mcp` unless that path is known to be safe for health checks.

## Rendering a single release

```bash
helm template mcp-technical-knowledge helm-chart/mcp-server \
  --namespace mcp \
  -f helm-deploy/technical-knowledge-values.yaml
```

## Lint

```bash
helm lint helm-chart/mcp-server
```
