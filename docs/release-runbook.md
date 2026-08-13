# Release and rollback runbook

## Release gates

The image is releasable only after all GitHub Actions jobs pass:

- complete Release solution build;
- server unit tests and OpenAPI generation;
- public ABI comparison against upstream 10.11.11;
- OpenAPI breaking-change comparison;
- Web lint, TypeScript check, Vitest and production build;
- combined-image container health/Web smoke test.

Create the coordinated tag named by `releaseTag` in `release-manifest.json`. Record the resulting GHCR digest in the release notes and then update `publishedImageDigest` in a follow-up manifest commit. Deployment references use the digest.

## Production promotion

Promotion is intentionally manual and occurs only after canary acceptance:

1. Back up the current `/config` using the existing homelab backup process.
2. Record the exact digest of the currently running official image.
3. Change only `JELLYFIN_IMAGE` to the accepted custom digest.
4. Recreate only the Jellyfin service.
5. Verify container health, public HTTPS, WebSocket, playback and NVIDIA transcoding.
6. Observe warning/error logs for 24 hours.

No schema migration is introduced; both builds share the 10.11.11 base.

## Rollback

Restore the previously recorded official image digest and recreate only Jellyfin. Use the config backup only if data corruption is actually observed; an image rollback should not require restoring config.
