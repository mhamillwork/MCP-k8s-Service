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

## Gateway API (HTTPS + routable IP)

When `gateway.enabled=true` and `gateway.create=true`, the chart can create:

1. A **Gateway** (requests a routable/LB IP from the cluster GatewayClass)
2. An **HTTPRoute** that attaches to that Gateway and forwards to the ClusterIP Service
3. A cert-manager **Certificate** with `dnsNames` for TLS termination at the Gateway

Isolated-network defaults in `helm-deploy/*-values.yaml` use **HTTPS only** (`http.enabled: false`, `tls.enabled: true`).

```yaml
gateway:
  enabled: true
  create: true
  gatewayClassName: cilium
  hostnames:
    - technical-knowledge-mcp.example.local
  pathPrefix: /mcp
  http:
    enabled: false
  tls:
    enabled: true
    port: 443
    sectionName: https
    mode: Terminate
  certificate:
    enabled: true
    create: true
    dnsNames:
      - technical-knowledge-mcp.example.local
    issuerRef:
      name: internal-ca          # your air-gapped CA ClusterIssuer
      kind: ClusterIssuer
```

Prerequisites:

- Gateway API CRDs + a GatewayClass
- cert-manager installed
- An internal `Issuer` / `ClusterIssuer` that can sign the `dnsNames`
- DNS (or `/etc/hosts`) pointing those names at the Gateway address

To use a shared Gateway instead of one per release, set `gateway.create: false` and provide `gateway.parentRefs`. You can still create a Certificate in this chart, or reference an existing TLS Secret via `gateway.tls.secretName` / `certificateRefs`.

```bash
kubectl -n mcp get gateway,httproute,certificate
kubectl -n mcp get secret mcp-technical-knowledge-tls
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
