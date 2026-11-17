# Building Container Images

All images must be built from the **repository root** so Dockerfiles can access `src/` and `requirements/`.

## Prerequisites

- Docker (or compatible CLI)
- Mirrored Python base image available locally (air-gapped)
- Python MCP scripts present under `src/`
- Verified package pins in `requirements/*.txt`
- Optional: credentials configured for the internal Artifactory registry (via docker login; never in Dockerfiles)

## Build all images

```bash
./scripts/build-images.sh
```

## Build one image

```bash
./scripts/build-images.sh technical-knowledge
./scripts/build-images.sh wobbegong-sql
./scripts/build-images.sh gtiss-dis-knowledge
./scripts/build-images.sh devsecops-knowledge
./scripts/build-images.sh atoms-knowledge
```

## Manual docker build examples

```bash
docker build \
  -f dockerfiles/Dockerfile.technical-knowledge-mcp \
  -t technical-knowledge-mcp:1.0.0 \
  .

docker build \
  -f dockerfiles/Dockerfile.wobbegong-sql-mcp \
  -t wobbegong-sql-mcp:1.0.0 \
  .
```

## Air-gapped base image

```bash
PYTHON_BASE_IMAGE=artifactory.tahaa.local/mirror/python:3.12-slim \
  ./scripts/build-images.sh
```

Or per build:

```bash
docker build \
  -f dockerfiles/Dockerfile.atoms-knowledge-mcp \
  --build-arg PYTHON_BASE_IMAGE=artifactory.tahaa.local/mirror/python:3.12-slim \
  -t atoms-knowledge-mcp:1.0.0 \
  .
```

## Tag and push to Artifactory

```bash
REGISTRY=artifactory.tahaa.local/tahaa-image-local/ai-services \
TAG=1.0.0 \
PUSH=true \
./scripts/build-images.sh
```

Equivalent manual push:

```bash
docker tag technical-knowledge-mcp:1.0.0 \
  artifactory.tahaa.local/tahaa-image-local/ai-services/technical-knowledge-mcp:1.0.0

docker push \
  artifactory.tahaa.local/tahaa-image-local/ai-services/technical-knowledge-mcp:1.0.0
```

## Pip dependencies offline

Configure the build environment to use an internal PyPI mirror before `pip install` runs in the Dockerfile (for example Docker build secrets, build-args consumed by an extended Dockerfile, or a pre-baked builder image that already contains wheels). Do not download packages at container startup.

Until `src/*.py` files are present, builds fail intentionally with a clear missing-source error.
