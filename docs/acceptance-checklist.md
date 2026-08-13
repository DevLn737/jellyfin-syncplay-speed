# Canary acceptance checklist

Use two real Windows PCs through one HTTPS/WSS canary hostname. One client should be local to the server and one remote. Test the Web client loaded from canary and Jellyfin Media Player 1.12.0 where available.

- [ ] Both clients advertise synchronized playback-rate support.
- [ ] Each client can initiate `1× → 1.25× → 1.5× → 1×`.
- [ ] The other client does not change locally before the authoritative server command.
- [ ] Pause/rate change keeps the group paused; resume uses the new base.
- [ ] Seek preserves the base rate.
- [ ] Artificial buffering enters and exits the barrier without spontaneous playback.
- [ ] Queue/item change preserves the base rate.
- [ ] Initiator exit does not reset group rate.
- [ ] Rejoin/reconnect receives the current base rate.
- [ ] Sync Correction temporarily deviates around the base, then returns exactly to it.
- [ ] After stabilization, each client's absolute diff is below the current 400 ms SkipToSync threshold without accumulating drift.
- [ ] A legacy session works at `1×` and blocks acceleration with the localized 409 message.
- [ ] A legacy session cannot join a group already running above `1×`.
- [ ] Public HTTPS and WebSocket traffic remain healthy.
- [ ] Direct play works.
- [ ] NVIDIA transcoding works on canary if the host exposes the GPU.
- [ ] No usernames, media names, tokens or URLs appear in added logs.

Desktop is forked only if logs show that Web issued the correct local-only rate but the native mpv adapter failed to apply it.
