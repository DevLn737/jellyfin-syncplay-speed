#!/usr/bin/env bash
set -euo pipefail

case "${CANARY_IMAGE:-}" in
    *@sha256:*) ;;
    *)
        echo "CANARY_IMAGE must be pinned as registry/repository@sha256:digest" >&2
        exit 2
        ;;
esac

: "${CANARY_MEDIA_PATH:?Set CANARY_MEDIA_PATH to a read-only media root}"

docker compose -f deploy/docker-compose.canary.yml config --quiet
docker compose -f deploy/docker-compose.canary.yml up --detach --wait
docker compose -f deploy/docker-compose.canary.yml ps
