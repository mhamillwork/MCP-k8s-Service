# Troubleshooting

## ImagePullBackOff

- Confirm the image repository/tag in the values file.
- Verify `imagePullSecrets` exists in namespace `mcp`.
- Confirm the node can reach the internal Artifactory registry.
- Check `kubectl -n mcp describe pod <pod>` for auth vs not-found errors.

## CrashLoopBackOff

- `kubectl -n mcp logs deploy/<release> --previous`
- Common causes: missing Secret keys, wrong Neo4j URI, missing SQLite file permissions, Python import errors from incomplete requirements.
- Confirm `command`/`args` match the real script entrypoint.

## Python dependency failures

- Rebuild the image after updating `requirements/<service>.txt` with verified pins.
- Ensure air-gapped builds use an internal PyPI/wheel mirror.
- Do not `pip install` at container startup.

## MCP transport mismatch

- Symptoms: client HTTP errors, empty responses, connection refused on expected path.
- Inspect the Python script for stdio vs SSE vs Streamable HTTP.
- Update Helm `mcp.*`, `command`, `args`, and Service port to match reality.
- For stdio-only servers, deploy an HTTP adapter (see `docs/mcp-client-integration.md`).

## Neo4j connection failures

- Verify Secret username/password keys.
- Confirm bolt/neo4j URI and database name.
- Check NetworkPolicy egress if enabled.
- Ensure each service uses the intended independent Neo4j instance/database.

## SQLite permission / locking errors

- PVC must be writable by UID/GID `10001` (unless securityContext overridden).
- Keep `replicaCount: 1` for writers.
- Avoid multi-writer mounts across nodes.
- Confirm `SQLITE_DB_PATH` (or real env name) points at the mounted file.

## Authentication failures (DevSecOps APIs)

- Rotate/recreate `mcp-devsecops-knowledge-apis`.
- Confirm base URLs are reachable from the cluster.
- Prefer read-only tokens; check token scopes.
- Do not log tokens when debugging.

## ServiceMonitor discovery problems

- `serviceMonitor.enabled` must be true and labels must match the Prometheus Operator selector.
- Namespace may differ (`serviceMonitor.namespace`).
- Application must actually expose the configured metrics path.

## DNS / Service connectivity

```bash
kubectl -n mcp get svc
kubectl -n mcp run -it --rm debug --image=artifactory.tahaa.local/mirror/curlimages/curl --restart=Never -- \
  curl -v http://mcp-technical-knowledge.mcp.svc.cluster.local:8000/
```

- Confirm Service selector labels match Pod labels.
- Confirm targetPort matches container listen port.
- Check NetworkPolicy ingress rules.

## Helm / Helmfile issues

- Run commands from `helm-deploy/` or use `./scripts/deploy.sh`.
- `helmfile template` / `./scripts/validate.sh` for local render checks.
- Missing values files fail fast (`missingFileHandler: Error`).
