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
| Gateway | `gateway.enabled=true` and `gateway.create=true` |
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

## Gateway API (routable IP)

When `gateway.enabled=true` and `gateway.create=true`, the chart creates:

1. A **Gateway** (requests a routable/LB IP from the cluster GatewayClass)
2. An **HTTPRoute** that attaches to that Gateway and forwards to the ClusterIP Service

```yaml
gateway:
  enabled: true
  create: true
  gatewayClassName: cilium   # must match a cluster GatewayClass
  addresses: []              # optional static IPAddress request
  hostnames:
    - technical-knowledge-mcp.example.local
  pathPrefix: /mcp
```

To use a shared Gateway instead of one per release, set `gateway.create: false` and provide `gateway.parentRefs`.

Read the assigned address after deploy:

```bash
kubectl -n mcp get gateway
kubectl -n mcp get httproute
```

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
