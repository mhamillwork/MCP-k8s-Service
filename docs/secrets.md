# Secrets Management

## Rules

1. Never commit real credentials.
2. Never put passwords or tokens in Helm values files.
3. Reference Kubernetes Secrets via `env[].valueFrom.secretKeyRef` or `envFrom.secretRef`.
4. Prefer externally managed Secrets (sealed-secrets, external-secrets, vault injectors) in production.

## Example: Neo4j secret (Technical Knowledge)

```bash
kubectl -n mcp create secret generic mcp-technical-knowledge-neo4j \
  --from-literal=username='neo4j' \
  --from-literal=password='REDACTED'
```

Referenced in values as:

```yaml
env:
  - name: NEO4J_USERNAME
    valueFrom:
      secretKeyRef:
        name: mcp-technical-knowledge-neo4j
        key: username
  - name: NEO4J_PASSWORD
    valueFrom:
      secretKeyRef:
        name: mcp-technical-knowledge-neo4j
        key: password
```

Create analogous independent Secrets for GTISS/DIS and ATOMS; do not share credentials unless deliberately designed.

## Example: DevSecOps API tokens

```bash
kubectl -n mcp create secret generic mcp-devsecops-knowledge-apis \
  --from-literal=jira-token='REDACTED' \
  --from-literal=gitlab-token='REDACTED' \
  --from-literal=confluence-token='REDACTED' \
  --from-literal=artifactory-token='REDACTED'
```

Use least-privilege, preferably read-only tokens until mutating tools are explicitly authorized.

## Image pull secret

```bash
kubectl -n mcp create secret docker-registry artifactory-registry-secret \
  --docker-server=artifactory.tahaa.local \
  --docker-username='REDACTED' \
  --docker-password='REDACTED' \
  --docker-email='unused@example.invalid'
```

## Rotation

1. Create/update the Secret.
2. Restart only the affected Deployment (`kubectl -n mcp rollout restart deploy/<release>`).
3. Confirm pods remount env and reconnect.

## What not to do

- Do not store credentials in ConfigMaps.
- Do not bake credentials into images.
- Do not log Secret values in application output or metrics.
