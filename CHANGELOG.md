# Changelog

## 10.11.11-syncplay.1

- Added a server-owned SyncPlay base playback rate with a default of `1.0`.
- Added `POST /SyncPlay/SetPlaybackRate` with finite `0.25–5.0` validation.
- Added an all-participants capability gate and structured HTTP 409 conflicts.
- Preserved legacy constructors and payload defaults.
- Scaled position and Ready/Waiting timing by the base playback rate.
- Added synchronized rate changes through the existing Seek/Ready barrier.
- Kept temporary SpeedToSync correction separate from the group base rate.
- Added bounded correction with SkipToSync fallback.
- Preserved the user's personal playback speed after leaving SyncPlay.
- Added server, Web, legacy compatibility and paused-barrier tests.
- Added a pinned Linux/amd64 combined-image release workflow and canary runbooks.
