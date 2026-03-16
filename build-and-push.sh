#!/usr/bin/env bash
set -euo pipefail

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-kiro-cli-hero}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

PRIVATE_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
FULL_IMAGE="${PRIVATE_REGISTRY}/${REPO_NAME}:${IMAGE_TAG}"

echo "==> Authenticating to public ECR..."
aws ecr-public get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin public.ecr.aws

echo "==> Authenticating to private ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | \
  docker login --username AWS --password-stdin "${PRIVATE_REGISTRY}"

echo "==> Building ${FULL_IMAGE}..."
docker build -t "${FULL_IMAGE}" "$(dirname "$0")"

echo "==> Pushing ${FULL_IMAGE}..."
docker push "${FULL_IMAGE}"

echo "==> Done."
