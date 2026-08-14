# Changelog

## 10.11.11-syncplay.4

- Honored `AudioStreamIndex` for audio-only streams instead of silently selecting the first embedded audio track.
- Added explicit FFmpeg stream mapping for external audio inputs, preventing a Russian sidecar URL from serving the Japanese track from the primary MKV.
- Deduplicated SyncPlay Buffering/Ready reports while preserving the first Ready event for a newly started item.
- Added controller regressions for external audio selection and FFmpeg `-map 1:0` generation.

## 10.11.11-syncplay.3

- Preserved sub-second JMP position precision by using the millisecond event position after detecting the native seconds-based asynchronous API.
- Avoided an otherwise possible extra Ready/Seek correction caused by JMP 1.12.0 truncating `228.736 s` to `228 s`.

## 10.11.11-syncplay.2

- Normalized native asynchronous player positions that are reported in seconds instead of the Web client's millisecond contract.
- Prevented an out-of-range Ready position from scheduling a group pause or resume minutes into the future.
- Added regressions for the observed `228 s` versus `0.228 s` mismatch and the Ready-barrier recovery path.

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
