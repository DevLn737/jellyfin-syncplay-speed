# Two-client acceptance report — 2026-08-20

## Validated components

- Jellyfin Server/Web `10.11.11-syncplay.4`, pinned by `release-manifest.json`.
- Jellyfin Media Player `1.12.0-syncplay.1` on two remote Windows PCs.
- One public HTTPS/WSS canary endpoint backed by an isolated container.

## Automated gates

The coordinated CI run passed the complete server build and tests, controller
regressions, public ABI comparison, OpenAPI compatibility comparison, Web lint,
type checking, Vitest, production build and combined-container smoke test.

The Desktop workflow passed its external-audio/subtitle lifecycle test and
produced the Windows x64 installer used for acceptance.

## Live results

- Each participant independently selected embedded and external audio in both
  directions. The other participant's audible track did not change.
- External subtitle visibility remained independent in both directions.
- Server FFmpeg commands mapped the selected sidecar audio input explicitly;
  completed processes exited successfully.
- Playback-rate changes were applied to both participants through the existing
  Waiting/Ready barrier.
- Rate changes while paused returned the group to Paused; resume used the new
  base rate.
- Seek worked both while playing and paused and preserved synchronized time.
- Item restart, pause/resume and repeated stress-test switching recovered from
  Waiting without an infinite loading state.
- After stabilization, both participants observed the same playback position
  without accumulating drift.
- Client and server memory remained bounded during repeated audio, subtitle,
  rate, pause and seek operations. The previously observed runaway allocation
  was not reproduced.

## Accepted limitation

The first switch to an external sidecar audio stream may take up to about eight
seconds while the stream is opened and buffered. Playback subsequently remains
synchronized, so this is accepted for the stable release.
