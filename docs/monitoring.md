# Monitoring

## Layers

| Layer | What it measures | How |
|---|---|---|
| Infrastructure | Pod restarts, CPU/memory, probe failures | kube-state-metrics / cAdvisor / Prometheus |
| Service connectivity | ClusterIP reachability | blackbox / synthetic checks |
| Application metrics | Custom MCP/business metrics | Only if the Python app exposes Prometheus metrics |
| Logs | Startup errors, dependency failures | container stdout/stderr → cluster log stack |

Do not assume `/metrics` exists on the MCP scripts.

## ServiceMonitor

Optional Prometheus Operator scrape config:

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  scrapeTimeout: 10s
  path: /metrics
  port: http
  labels:
    release: monitoring
```

Enable only after confirming:

1. The container exposes a Prometheus text endpoint.
2. The path/port are correct.
3. Metrics do not leak secrets or sensitive payloads.

## Health checks

Default chart probes are TCP. Prefer a dedicated HTTP health endpoint when the application provides one:

```yaml
probes:
  readiness:
    enabled: true
    type: http
    path: /healthz
```

Do not use the MCP protocol endpoint as a generic health check unless the application explicitly supports that behavior.

## Logging guidance

- Keep credentials out of logs.
- Log dependency connection failures with redacted endpoints where needed.
- Correlate by Kubernetes pod name / release label `app.kubernetes.io/instance`.

## Suggested alerts (cluster-level)

- Deployment unavailable / replica mismatch
- CrashLoopBackOff
- Persistent probe failures
- PVC almost full (Wobbegong)
- ImagePullBackOff for Artifactory credentials/tags
