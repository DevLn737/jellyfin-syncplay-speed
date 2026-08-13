# Canary runbook

Canary is a separate Jellyfin instance. It must not reuse production config/cache or a writable production media mount.

## Prerequisites

- immutable image reference in `name@sha256:digest` form;
- a dedicated host directory or Docker volume for config and cache;
- a read-only media root;
- a dedicated bind address/port;
- a separate HTTPS/WSS reverse-proxy hostname with WebSocket forwarding;
- test users created only in canary.

Do not commit the concrete hostname, paths, credentials or `.env` file.

## Start

```bash
export CANARY_IMAGE='ghcr.io/devln737/jellyfin-syncplay-speed@sha256:<digest>'
export CANARY_MEDIA_PATH='/absolute/read-only/media/path'
export CANARY_BIND_ADDRESS='127.0.0.1'
export CANARY_PORT='18096'
docker login ghcr.io
./scripts/canary-up.sh
```

Configure the reverse proxy only after direct health succeeds. Proxy HTTP and WebSocket traffic to the canary port, enable normal TLS validation, and do not route production traffic to canary.

## Validate

```bash
CANARY_BASE_URL='http://127.0.0.1:18096' ./scripts/canary-smoke.sh
```

Then complete [the two-PC acceptance checklist](acceptance-checklist.md). Enable extended debug logging only during this period and disable it afterward.

## Remove

Stopping/removing the canary container is safe; retain its dedicated config volume until acceptance evidence is recorded. Do not delete production volumes or change the production container during canary cleanup.
