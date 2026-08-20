# Acceptance report — 2026-08-20 through 2026-08-21

## Validated components

- Jellyfin Server/Web `10.11.11-syncplay.4`, pinned by `release-manifest.json`.
- Jellyfin Media Player `1.12.0-syncplay.1` on two remote Windows PCs.
- One public HTTPS/WSS canary endpoint backed by an isolated container.
- The same pinned Server/Web release on the production endpoint with four
  simultaneous Jellyfin Media Player sessions.

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

## Four-client production acceptance

After the canary passed, the immutable `10.11.11-syncplay.4` image was deployed
to production with the existing configuration and read-only media mounts. Four
Windows clients then exercised the release concurrently.

- A four-participant group completed synchronized rate barriers at `1×`, `2×`
  and `0.5×`; the wider values were used as stress cases inside the validated
  server range.
- Required `1.25×` and `1.5×` modes were subsequently verified while the four
  sessions were split across two concurrent SyncPlay groups.
- A rate change while paused returned the group to Paused. A later resume and
  seek preserved the selected base rate and returned to Playing.
- Three simultaneous external Russian sidecar-audio requests were mapped to
  independent FFmpeg jobs and all exited successfully. Subtitle visibility and
  audible tracks remained client-local.
- Two SyncPlay groups operated concurrently while one used NVIDIA `h264_nvenc`
  transcoding and the other used external-audio transcoding.
- One client disconnect/rejoin cycle delayed its Ready event and triggered the
  existing lost-time correction. The group recovered, and later four-client
  rate barriers completed in under a second.
- Jellyfin memory remained bounded between approximately 363 and 412 MiB during
  the stress session. CPU returned to approximately 2% after active operations;
  no runaway allocation, server exception or failed FFmpeg process occurred.

The four participants accepted the production session. The production rollout
therefore remains on `10.11.11-syncplay.4`; rollback was not required.
