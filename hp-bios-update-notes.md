# HP Pavilion x360 15-br1xx — BIOS update without Windows

Research notes on whether the BIOS can be updated from Linux, without
installing Windows. Not yet acted on — this is reference material for when
(if) it's worth revisiting. See "Hardware notes" in `README.md` for the
AMD GPU bug this would potentially (unconfirmed) relate to.

## Current state (checked 2026-08-26)

- **Current BIOS: F.22, dated 2017-07-26** (`cat /sys/class/dmi/id/bios_version` / `bios_date`, no root needed)
- **Model:** HP Pavilion x360 Convertible 15-br1xx (`cat /sys/class/dmi/id/product_name`)
- **HP Product Number (for support.hp.com's product search): `2WA89EA#ABV`**
  (`cat /sys/class/dmi/id/product_sku`, no root needed). This is a
  model+configuration code shared by every identically-configured unit sold
  — not this specific device's unique serial number, which is intentionally
  not recorded here since this repo is public on GitHub.
- **`fwupdmgr get-updates` explicitly lists "System Firmware" under "no available updates"** — Linux's own firmware-update channel (LVFS) has nothing newer listed for this device. Doesn't prove F.22 is HP's last-ever release (HP may simply never have published this model to LVFS at all) — just that this specific channel has nothing.
- **A newer BIOS almost certainly exists.** A sibling model on the exact same platform family (`15-br077nr`, same `15-br0xx`/`15-br1xx` generation) has been confirmed by a user on **BIOS F.32 Rev 5.0** — ten-plus versions past this machine's F.22. HP typically ships one BIOS SoftPaq per motherboard platform covering the whole family of marketing SKUs together, so this strongly suggests (not proven) a similarly newer version is available for this exact `15-br1xx` unit too.
- **Could not confirm the exact version/date for `15-br1xx` specifically, or get it from an automated tool at all** — `support.hp.com` (timeout/empty JS shell on three separate attempts, including with the exact SKU as a query param), Softpedia, and Vinafix all blocked or failed automated fetching. This needs a real browser — see "What's still needed" below.
- Have **not** confirmed whether any newer BIOS actually addresses the ASPM/LTR suspend-buffer bug — HP's consumer BIOS changelogs essentially never name a specific low-level hardware bug like this, so there'd be no way to know without just trying it.

## Mechanism: HP hardware BIOS Recovery (no OS involved at all)

This is HP's built-in recovery firmware — it runs before any bootloader or
OS, so it doesn't matter that this machine runs Linux, and doesn't require
Windows to trigger it:

1. Format a USB stick FAT32, put the correct BIOS recovery file at its root
   (exact filename is model/platform-specific — only knowable once the real
   SoftPaq is downloaded and inspected, see below).
2. With the laptop **off**, hold **Windows key + B** (some Pavilion 15/x360
   variants use **Windows key + V** instead — try B first), then press and
   hold the power button for 2-3 seconds, then release all keys.
3. Screen stays blank for about 40 seconds, possibly a series of beeps
   (~8), then it boots straight into the recovery flash tool and reads the
   file from USB automatically.

This exact key-combo + USB method is documented specifically for the
Pavilion x360 / Pavilion 15 family (not a generic guess extrapolated from
other HP lines).

There's also a manual **F10 setup → "Flash System BIOS" / "Update System
BIOS from USB"** menu option on many HP models, as a second path if the
recovery-mode combo doesn't behave as expected — worth checking once in the
BIOS setup screen regardless.

## Getting the actual BIOS file, without running Windows

HP distributes BIOS updates as a Windows `.exe` ("SoftPaq"). Running it
isn't required — only *extracting* it:

- **Try first:** `7z x file.exe`, then `7z x BIOSUpdate.exe` on whatever
  that produces — works directly for many SoftPaqs, especially older ones
  (like what's needed here, since F.22 is a 2017-era release and older
  installers tend to extract more easily than newer ones).
- **If that fails:** run the `.exe` under **Wine** (a Linux compatibility
  layer — installing Wine is not installing Windows). Let its installer GUI
  launch, then copy the extracted files out of
  `$WINEPREFIX/drive_c/windows/temp/7z*.tmp/` before the installer finishes
  and cleans up.
- One documented case (HP Envy x360, a sibling model in HP's consumer x360
  convertible line) used exactly this Wine-extraction approach, then
  triggered the flash with the same Windows+B combo above.

Once extracted, look for the actual firmware image (something like an
`.fd`/`.bin`/`.wcp` file) plus any accompanying `.sig` signature file, and
any `CrisisFolder`/`DEVFW` directories in the SoftPaq's contents — the exact
required USB folder layout HP expects varies by BIOS generation (some want
just the two files at the USB root, some want a nested `HP/BIOS/New/`
structure) and is only knowable once the real SoftPaq for this model is in
hand.

## What's still needed before doing this

1. **The exact SoftPaq download for this model — needs a real browser, not
   an automated tool.** `support.hp.com` is a JavaScript app that returned
   empty/timed-out content on every automated fetch attempt (tried the
   generic family page, a direct `?sku=` URL, three times total). Open
   `https://support.hp.com/us-en/drivers` yourself, search product number
   `2WA89EA#ABV` (see above), Software & Drivers → BIOS. See what version
   is listed and whether it's newer than F.22 — given the F.32 sibling-model
   finding above, expect it to be.
2. If a newer version exists, download it and hand it over (or the SoftPaq
   number) to extract and prepare the USB.
3. If F.22 turns out to already be the latest for this exact `15-br1xx`
   variant specifically (possible even if `15-br0xx` got more updates —
   variants within a family don't always get identical support windows),
   this is moot.

## Sources

- [HP laptop BIOS update from Linux — blog writeup with exact steps (HP Envy x360)](https://dvdkon.ggu.cz/blogpost/hp_ex360_bios_update/)
- [Instructions to Update the BIOS/UEFI for an HP Laptop on Linux (GitHub gist)](https://gist.github.com/eNV25/c8001491dc0440656ff7b0ae18993ba1)
- [HP Notebook PCs - Recovering the BIOS (official HP doc)](https://support.hp.com/us-en/document/ish_3932413-2337994-16)
- [Flashing BIOS from Linux — ArchWiki](https://wiki.archlinux.org/title/Flashing_BIOS_from_Linux)
- F.32 Rev 5.0 on a `15-br077nr` (sibling model, same platform family) — found via web search summary of an HP Support Community/forum discussion; the source thread itself was behind a paywall/bot-block (`tollbit.overclock.net`, HTTP 402) so this is secondhand, not independently verified against the original post.

## Overall recommendation (updated after the F.32 finding)

This laptop is roughly 9 years old (BIOS dated 2017, `i7-8550U` CPU from
that era). The two current software-level workarounds (`mo.lock` plugin
clone + screensaver disabled — see README "Hardware notes") are confirmed
working via direct testing. A newer BIOS now looks likely to exist (not
just theoretically possible), which shifts this from "probably not worth
it" toward "worth a five-minute look" — checking `support.hp.com` in an
actual browser costs little. Whether it's worth the flash itself still
depends on what's actually listed there and whether its notes suggest
anything relevant; the uncertainty over whether it fixes *this specific*
bug remains unchanged. Still not urgent given the working mitigations.
