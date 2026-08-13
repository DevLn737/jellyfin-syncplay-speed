# Protocol and compatibility

## Wire additions

- `ClientCapabilities.SupportsSyncPlayPlaybackRate: bool`, default `false`.
- `SendCommand.PlaybackRate: float?`, absent interpreted as `1.0`.
- `PlayQueueUpdate.PlaybackRate: float?`, absent interpreted as `1.0`.
- `POST /SyncPlay/SetPlaybackRate` with `{ "PlaybackRate": number }`.

The endpoint accepts finite values from `0.25` through `5.0`. Invalid input returns HTTP 400 without modifying group state.

## Capability gate

The server evaluates current session capabilities while the SyncPlay group lock is held. A non-`1×` request fails atomically when any participant is incompatible. HTTP 409 uses RFC 7807 Problem Details and includes:

```json
{
  "status": 409,
  "code": "SyncPlayPlaybackRateNotSupported",
  "unsupportedParticipants": 1
}
```

An incompatible client also cannot join an already accelerated group. Joining at `1×` and returning an existing group to `1×` remain allowed.

## Time model

`BasePlaybackRate` is persistent group state. While playing:

```text
media position = anchored ticks + elapsed wall time × base playback rate
```

A rate change first anchors position using the old base rate, then stores the new rate and enters the existing Seek/Ready barrier. A paused group remains paused; an idle group remembers the new value for the next playback.

The Web client separately tracks `effectivePlaybackRate` for temporary correction:

```text
effective = base + media-time difference / correction wall time
```

Effective rate is bounded to `0.2–5.0`. If the bounded correction cannot finish within five seconds, the client uses the existing SkipToSync path. Every timeout, pause, seek, buffering transition and resume restores the base rate.

## ABI policy

Existing `IGroupState`, `IGroupStateContext`, constructors and enum ordinals are preserved. New behavior is exposed through secondary interfaces and appended enum values. CI compares the public assemblies against the exact upstream 10.11.11 base using Microsoft's pinned ApiCompat tool.

## Logging and privacy

The server logs accepted/rejected rate changes using group ID, rate, state and participant counts. Web debug logs contain base/effective rate and numeric diff. Neither path logs usernames, media names, tokens or URLs. Debug logging is intended only for canary diagnosis.
