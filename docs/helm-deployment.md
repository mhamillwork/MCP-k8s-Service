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
| Certificate (cert-manager) | `gateway.certificate.enabled=true` and `gateway.certificate.create=true` |
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

## Gateway API (one shared HTTPS IP)

Default layout:

1. **`mcp-shared-gateway`** Helm release (`helm-chart/mcp-shared-gateway`)
   - One Gateway → one routable/LB IP
   - One cert-manager Certificate for `mcp.example.local`
   - Five HTTPS listeners on ports **8443–8447** (same hostname, different port)
2. **Five MCP releases** each create only an **HTTPRoute** (+ Deployment/Service)
   - `gateway.create: false`
   - `parentRefs` point at `mcp-shared-gateway` + the service `sectionName`
   - Pods stay separate (one MCP container per pod)

| Service | Port | Client URL |
|---|---|---|
| Technical Knowledge | 8443 | `https://mcp.example.local:8443/mcp` |
| Wobbegong SQL | 8444 | `https://mcp.example.local:8444/mcp` |
| GTISS/DIS | 8445 | `https://mcp.example.local:8445/mcp` |
| DevSecOps | 8446 | `https://mcp.example.local:8446/mcp` |
| ATOMS | 8447 | `https://mcp.example.local:8447/mcp` |

```yaml
# shared-gateway-values.yaml (excerpt)
hostname: mcp.example.local
listeners:
  - name: technical-knowledge
    port: 8443
    sectionName: technical-knowledge
```

```yaml
# technical-knowledge-values.yaml (excerpt)
gateway:
  enabled: true
  create: false
  parentRefs:
    - name: mcp-shared-gateway
      namespace: mcp
      sectionName: technical-knowledge
  hostnames:
    - mcp.example.local
  pathPrefix: /mcp
```

Prerequisites:

- Gateway API CRDs + a GatewayClass
- cert-manager + internal CA `ClusterIssuer` (`internal-ca` placeholder)
- DNS / hosts entry: `mcp.example.local` → shared Gateway address
- Clients trust the internal CA

```bash
kubectl -n mcp get gateway mcp-shared-gateway -o wide
kubectl -n mcp get httproute,certificate
```

The per-service chart can still create its own Gateway when `gateway.create: true` (not used by default anymore).

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
