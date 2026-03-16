#!/usr/bin/env bash
set -euo pipefail

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-kiro-cli-hero}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="kiro-cli-hero"

FULL_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
KIRO_HOME="${HOME}/.kiro-cli-hero"

mkdir -p "${KIRO_HOME}"

# Reattach if container already running
if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  echo "==> Attaching to running container..."
  exec docker exec -it "${CONTAINER_NAME}" /bin/bash
fi

# Remove stopped container if exists
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

echo "==> Starting ${CONTAINER_NAME}..."
exec docker run -it \
  --name "${CONTAINER_NAME}" \
  -v "${HOME}/.aws:/home/ubuntu/.aws:ro" \
  -v "${KIRO_HOME}:/home/ubuntu:rw" \
  -v "$(pwd):/home/ubuntu/workspace:rw" \
  "${FULL_IMAGE}"
