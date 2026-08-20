# Jellyfin SyncPlay Playback Rate

A capability-gated extension for synchronized playback speeds in Jellyfin 10.11.11.

The project deliberately keeps the server and Web client as native public Jellyfin forks:

- [`DevLn737/jellyfin`](https://github.com/DevLn737/jellyfin), branch `syncplay-rate/10.11`
- [`DevLn737/jellyfin-web`](https://github.com/DevLn737/jellyfin-web), branch `syncplay-rate/10.11`
- [`DevLn737/jellyfin-desktop`](https://github.com/DevLn737/jellyfin-desktop), branch `codex/external-audio-1.12`
- this repository coordinates analysis, reproducible builds, releases and canary operations

## Safety model

Playback rate is owned by the SyncPlay group and defaults to `1.0`. A non-default rate is accepted only when every current participant advertises `SupportsSyncPlayPlaybackRate`. Legacy clients continue to use SyncPlay at `1×`; they receive an HTTP 409 conflict instead of entering or accelerating an incompatible group.

The first supported release scenarios are `1×`, `1.25×` and `1.5×`. The API validates the broader finite range `0.25–5.0` so malformed values, `NaN` and infinities cannot enter group state.

## Reproducible release

[`release-manifest.json`](release-manifest.json) pins the exact server, Web and official packaging commits. CI checks those pins, builds only `linux/amd64`, runs server/Web/API compatibility gates, smoke-tests the combined image and publishes:

```text
ghcr.io/devln737/jellyfin-syncplay-speed:10.11.11-syncplay.4
ghcr.io/devln737/jellyfin-syncplay-speed:sha-<coordination-commit>
```

Production must use the resulting `@sha256:...` digest, never a floating tag. The manifest's `publishedImageDigest` remains `null` until a successful release has produced a digest.

## Documentation

- [Upstream PR analysis](docs/upstream-pr-analysis.md)
- [Protocol and compatibility guarantees](docs/protocol.md)
- [Canary runbook](docs/canary-runbook.md)
- [Acceptance checklist](docs/acceptance-checklist.md)
- [Release and rollback](docs/release-runbook.md)

No production hostname, account, token, media path or homelab configuration belongs in this repository. No upstream Jellyfin PR or comment is created by this project without separate authorization.

## Status

Release `10.11.11-syncplay.4` passed automated CI and two-client Windows canary acceptance. The Web fork normalizes Jellyfin Media Player 1.12.0's seconds-based asynchronous position result against the millisecond event position. The Desktop fork supports independent external audio selection, while the coordinated server image explicitly maps the selected sidecar input so the requested track is actually served.

The stable Windows client is [Jellyfin Media Player 1.12.0 SyncPlay 1](https://github.com/DevLn737/jellyfin-desktop/releases/tag/v1.12.0-syncplay.1). Detailed live-test evidence is recorded in the [acceptance report](docs/acceptance-report-2026-08-20.md).

## Licenses

Coordination files in this repository are licensed under MIT. The Jellyfin forks retain their original GPL-2.0-or-later licenses and notices. Builds use the pinned official `jellyfin-packaging` revision under its upstream license.
