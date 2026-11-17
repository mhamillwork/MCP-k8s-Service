# Air-Gapped Deployment

The target cluster has **no direct internet access**. All images, Python packages, and Helm assets must come from internal repositories or offline transfer bundles.

## Package checklist

Transfer (or mirror) the following into the air-gapped environment:

1. This Git repository (or a release tarball).
2. Mirrored Python base image (`python:3.12-slim` or approved equivalent).
3. Built MCP service images (or the ability to build them inside the air gap).
4. Python wheels / internal PyPI content required by `requirements/*.txt`.
5. Optional: mirrored debug images used for troubleshooting (`curl`, etc.).
6. Kubernetes Secret material created inside the cluster (not shipped in Git).

## Mirror the Python base image

On a connected machine:

```bash
docker pull python:3.12-slim
docker tag python:3.12-slim artifactory.tahaa.local/mirror/python:3.12-slim
docker push artifactory.tahaa.local/mirror/python:3.12-slim
```

Or save/load for sneaker-net:

```bash
docker save python:3.12-slim -o python-3.12-slim.tar
# transfer file
docker load -i python-3.12-slim.tar
```

## Build with internal dependencies

```bash
PYTHON_BASE_IMAGE=artifactory.tahaa.local/mirror/python:3.12-slim \
REGISTRY=artifactory.tahaa.local/tahaa-image-local/ai-services \
TAG=1.0.0 \
PUSH=true \
./scripts/build-images.sh
```

Configure pip to use the internal Artifactory PyPI repository during image build (index URL / trusted host / vendor wheels). Do not perform runtime downloads in the container entrypoint.

## Artifactory PyPI (conceptual)

1. Create/use an internal PyPI repository (for example `tahaa-pypi-local` / virtual).
2. Upload verified wheels for each MCP service’s dependencies after script inspection.
3. Point build-time pip at that repository.
4. Pin versions in `requirements/*.txt`.

Exact Artifactory project paths depend on the local instance and are not assumed by this repository.

## Push MCP images

Images should land under a configurable prefix such as:

```text
artifactory.tahaa.local/tahaa-image-local/ai-services/<service>:<tag>
```

Update `image.repository` / `image.tag` in each `helm-deploy/*-values.yaml` if the prefix differs.

## Deploy without internet

```bash
# 1. Create namespace + Secrets + imagePullSecret (docs/secrets.md)
kubectl create namespace mcp

# 2. Render/verify offline
./scripts/validate.sh --infra-only
./scripts/deploy.sh template

# 3. Apply
./scripts/deploy.sh apply
```

Helmfile uses the local chart path only (`helmDefaults.skipDeps: true`). No chart museum or internet Helm repos are required.

## Updating image tags offline

1. Build/push the new tag to Artifactory.
2. Edit the service values `image.tag`.
3. `./scripts/deploy.sh apply mcp-<service>`.

## What not to do

- Do not rely on Docker Hub or PyPI at deploy/runtime.
- Do not embed registry passwords in scripts or values files.
- Do not claim Cursor or the CI agent can reach the internal Artifactory instance.
