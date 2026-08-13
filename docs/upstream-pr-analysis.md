# Upstream PR analysis

Analysis date: 2026-08-13. The original feature request, [jellyfin-web issue #7185](https://github.com/jellyfin/jellyfin-web/issues/7185), was closed by stale automation rather than by a shipped fix.

| Proposal | Useful idea | Blocking issue for this release |
| --- | --- | --- |
| [server #15921](https://github.com/jellyfin/jellyfin/pull/15921) + [web #7463](https://github.com/jellyfin/jellyfin-web/pull/7463) | Closest end-to-end group-rate design | Changes existing public interfaces/constructors, re-anchors elapsed time using the new rate instead of the old rate, and keeps Sync Correction centered on `1×`. |
| [server #14155](https://github.com/jellyfin/jellyfin/pull/14155) + [web #6892](https://github.com/jellyfin/jellyfin-web/pull/6892) | Strong Ready/Waiting barrier | A legacy client omitting initial speed can create a group at `0.1×`; wire field names differ; SpeedToSync is disabled away from `1×`. |
| [server #16875](https://github.com/jellyfin/jellyfin/pull/16875) + [web #7938](https://github.com/jellyfin/jellyfin-web/pull/7938) | Per-session speed and remote-control plumbing | Does not model playback rate as SyncPlay group state. |
| [server #9329](https://github.com/jellyfin/jellyfin/pull/9329) | Explores queue-level modeling | Treats rate as a queue mutation, has unresolved architectural objections and lacks complete state propagation. |

## Root cause

The stalled work is not one isolated bug. It is a contract-integration problem across independently reviewed server and Web changes:

- competing `PlaybackSpeed` and `PlaybackRate` wire models;
- paired backend/frontend PRs without a single end-to-end release gate;
- breaking changes to public constructors and state interfaces;
- inconsistent wall-clock versus media-time arithmetic;
- correction logic hard-coded to `1×`;
- no legacy capability gate for mixed client groups;
- missing tests for pause, seek, buffering, queue changes, reconnect and initiator exit.

## What this project borrows

The implementation borrows the Ready/Waiting barrier concept and the goal of carrying rate in group commands/snapshots. It does not transplant any PR wholesale. It preserves existing public contracts, adds secondary playback-rate interfaces, anchors position at the old rate before a change, and makes mixed-client behavior explicit.
