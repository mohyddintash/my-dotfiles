# Omarchy bug reports — drafts for review

Not filed. Two separate items below: one is a **comment to add to an existing
issue** (#7507 already covers this exact bug), the other is a **new issue**
(searched `basecamp/omarchy` for anything matching — nothing found).

System info common to both (from this machine):

- Omarchy: 4.0.1-1 (Quattro)
- Hyprland: 0.56.2-1 · quickshell: 0.3.1-1
- Kernel: 7.1.9-arch1-2, cmdline includes `amdgpu.aspm=0`
- Hardware: HP Pavilion x360 Convertible 15-br1xx, BIOS F.22 (2017-07-26)
- CPU: Intel Core i7-8550U (Kaby Lake-R) — hybrid graphics
- GPU: Intel UHD Graphics 620 (iGPU) + AMD Radeon 530/535-series "Topaz XT" [1002:6900] (discrete, drives the panels)
- Monitors: `eDP-1` 1920x1080@60 scale 1.5, `HDMI-A-1` 2560x1080@60 scale 1.25
- Idle config: `{"idle": {"screensaver": 150, "lock": 300}}` (defaults, untouched)

---

## 1. Comment to add to #7507 (existing issue — do not file new)

**Issue:** ["No way to opt out of lock-time display blanking in 4.0 (OMARCHY_LOCK_ONLY dropped, no shell.json equivalent)"](https://github.com/basecamp/omarchy/issues/7507)

This is the same bug the original reporter (MarcelHuang, RX 9070 discrete) already
described in full — `Service.qml`'s `armBlankTimer()`/`runBlank()` unconditionally
calling `omarchy-brightness-display off` 5s after any lock, no `shell.json` gate,
`OMARCHY_LOCK_ONLY` dead. Nothing to add to that diagnosis. What this comment adds:
**a second, different GPU where the same call produced the same class of failure**,
plus a confirmed reproduction (the original reporter explicitly said they hadn't
run the destructive test on their machine).

Proposed comment body:

> Confirming this on different hardware — Intel/AMD hybrid laptop (i7-8550U + AMD
> Radeon 530-series discrete, not the RX 9070 in the OP), Omarchy 4.0.1-1.
>
> This exact call (`omarchy-brightness-display off` → `hl.dsp.dpms({ action =
> "disable" })`) reproduced a hard hang here too — not a discrete-GPU-only or
> RDNA-only issue. Root cause on this hardware is a known BIOS bug (HP never
> allocates an LTR suspend buffer for the AMD GPU: `amdgpu: no suspend buffer for
> LTR; ASPM issues possible after resume`, present in `dmesg` on every boot,
> unfixable by `amdgpu.aspm=0` since the BIOS already declares ASPM unsupported at
> the FADT level). Reproduced twice: once from directly testing the dpms dispatch,
> once from an idle-triggered lock (system unresponsive, required a forced
> reboot, confirmed via `journalctl -b -1` — clean session activity right up to
> `lock-requested`, then nothing, no kernel error logged before the boot ends).
>
> Workaround in the meantime, for anyone who hits this before a `shell.json`
> gate ships: `omarchy plugin clone omarchy.lock` and remove the
> `omarchy-brightness-display off` call from the cloned `Service.qml`'s
> `blankProcess`. Keeps `omarchy-brightness-keyboard off` (harmless). Full
> writeup: [link to your dotfiles README if you want to share it publicly —
> optional].
>
> +1 on the suggested `shell.json` `blankOnLock` gate — would let us delete the
> plugin clone entirely.
>
> Filed by Claude Sonnet 5 via Claude Code.

---

## 2. New issue: idle-cycle race launches a second screensaver concurrently with the lock's own surface creation

Searched for: `screensaverLaunchGraceTimer`, `idledThisCycle`, `"screensaver
cycle remains armed"`, `handleActiveSignal`, "idle cycle restart concurrent",
"two idle cycles" — no matches in open or closed issues. Related but distinct:
#8114 (screensaver self-terminates on 3+ monitor setups from a *different*
race, in `omarchy-screensaver`'s focus-check polling) — not the same mechanism
and not the same file.

**Proposed title:**
`Idle cycle can restart itself mid-lock, launching a second screensaver concurrently with lock-surface creation (Service.qml)`

**Proposed body:**

```
## Summary

A brief activity blip during the screensaver's launch grace window can leave
an idle cycle "armed" instead of cancelling it. When the lock timer then
fires, the idle-monitor immediately reports "idle" again and starts a
*second* idle cycle — including a fresh screensaver launch across every
monitor — at the same moment the lock is creating its own session-lock
surfaces. On fragile GPUs this concurrent multi-output surface/modeset burst
can be fatal (see "Hardware impact" below), but the race itself is a logic
bug independent of that.

## Where

`shell/plugins/services/idle/Service.qml`

## Mechanism

1. Idle detected → `startIdleCycle()`. With defaults (`screensaver: 150,
   lock: 300`), `screensaverDelaySeconds` is `0` (fires immediately),
   `lockDelaySeconds` is `150` (fires 150s after this point). Both timers
   are logically part of one `idledThisCycle` session.
2. `launchScreensaver()` starts `screensaverProcess` and restarts
   `screensaverLaunchGraceTimer` (3000ms).
3. If the compositor reports brief activity (e.g. cursor jitter) *inside*
   that 3-second window, `handleActiveSignal()` takes this branch:
   ```qml
   if (root.screensaverStartedThisCycle && (root.screensaverWindowCount > 0 || screensaverLaunchGraceTimer.running)) {
     logEvent("idle-monitor-active", "screensaver cycle remains armed")
     return   // <-- does NOT cancel the idle cycle
   }
   ```
   So the cycle keeps running — `lockTimer` (armed with the full 150s
   `lockDelaySeconds` from step 1) is untouched and keeps counting down.
4. 150 seconds later, `lockTimer` fires: `lockSystem("lock-timeout")`. This
   sets `root.idledThisCycle = false` and starts `lockProcess`
   (`omarchy-system-lock`).
5. Because `idledThisCycle` is now `false`, the idle-monitor's next "idle"
   report (which can follow almost immediately — the compositor's own idle
   state didn't necessarily change, but the guard in `handleIdleChanged()`
   that would otherwise ignore a same-state signal no longer applies once
   `idledThisCycle` is `false`) passes the `if (!root.idleEnabled) return`
   check and calls `startIdleCycle()` again — a brand new cycle, including
   a brand new `launchScreensaver()` call.
6. Step 5's screensaver launch (which opens fullscreen terminal windows on
   *every* connected monitor via `omarchy-launch-screensaver`, moving
   `hyprctl` focus between them) now runs concurrently with step 4's lock
   sequence creating its own `WlSessionLock` surfaces on the same outputs.

## Reproduction

1. `shell.json`: `{"idle": {"screensaver": 150, "lock": 300}}` (default).
2. Let the system sit idle. Right as the screensaver would launch (~150s),
   nudge the mouse/trackpad once, briefly — enough to register activity but
   not enough to feel like you interrupted anything.
3. Do not touch the system again. Watch `journalctl -f` for `omarchy idle`
   and `omarchy lock` debug lines (needs the shell's debug logging enabled).
4. At ~150s + 150s = ~300s from the original idle-start, you'll see
   `lock-system: lock-timeout` and `lock-requested` immediately followed by
   a second `idle-monitor: idle` / `idle-cycle-start` / `process-start:
   screensaver` — all within under a second of each other.

Confirmed via `journalctl` on this machine (timestamps redacted to relative
seconds for clarity):

```
T+0.000  idle-monitor: idle
T+0.000  idle-cycle-start: screensaver=150 lock=300
T+0.000  process-start: screensaver [...] || omarchy-launch-screensaver
T+0.159  idle-monitor: active
T+0.159  idle-monitor-active: screensaver cycle remains armed
T+0.318  process-exit: screensaver exitCode=0 status=0
... (150s of normal activity, no further idle events — lockTimer keeps
     running uninterrupted in the background) ...
T+150.06 lock-system: lock-timeout
T+150.06 process-start: lock omarchy-system-lock
T+150.25 lock-requested
T+150.25 lock-pending: screen-stabilizing
T+150.34 idle-monitor: idle                    <-- second cycle starts
T+150.34 idle-cycle-start: screensaver=150 lock=300
T+150.34 process-start: screensaver [...] || omarchy-launch-screensaver
[machine became unresponsive here on affected hardware; see below]
```

Two other lock cycles on the same machine that day, where the screensaver had
already exited *minutes* before the lock fired (no overlap), both completed
normally (`process-exit: lock exitCode=0`, `secure=true`).

## Hardware impact (this reporter's case, not necessarily universal)

On a laptop with a known GPU firmware bug (BIOS never allocates an LTR
suspend buffer for the AMD GPU — `amdgpu: no suspend buffer for LTR; ASPM
issues possible after resume` in dmesg on every boot), this concurrent
multi-output surface/modeset burst produced a full system hang requiring a
forced reboot. `journalctl -b -1` shows clean activity right up to the
overlap point above, then nothing — no kernel error logged before the
journal for that boot simply ends. Not claiming every system will hang here;
plenty of hardware will absorb this fine. The race itself is real and
reproducible regardless of what it does to a given GPU.

## Suggested fix

`handleActiveSignal()`'s "screensaver cycle remains armed" branch should
also actively confirm the *lock* portion of the cycle is still coherent —
e.g. re-validate `lockTimer.running` reflects the correct remaining delay
from the point activity was detected, or simply have `lockSystem()` check
`idleMonitor.isIdle` before calling `startIdleCycle()` again immediately
after resetting `idledThisCycle`, rather than reacting to what may be a
stale/transient idle-monitor signal from the lock's own surface-creation
activity.

Filed by Claude Sonnet 5 via Claude Code.
```

---

## Before filing either of these

- `gh auth status` succeeds on this machine (logged in as `mohyddintash`) —
  filing is possible if you decide to go ahead.
- Per Omarchy's own contribution guidance, filing needs your explicit
  go-ahead on the exact text above — nothing gets submitted automatically.
- If you want changes to either draft (tone, trimming, adding/removing the
  public-writeup link in the #7507 comment, etc.), say so and I'll revise
  before anything goes out.
