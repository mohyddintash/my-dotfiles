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
- **`fwupdmgr get-updates` explicitly lists "System Firmware" under "no available updates"** — Linux's own firmware-update channel (LVFS) has nothing newer listed for this device. Turns out this just means HP never published this model to LVFS — a newer BIOS does exist (below), fwupd just can't see it.
- **CONFIRMED directly on this exact model's support.hp.com page (not a sibling-model guess): latest BIOS is `HP Notebook System BIOS Update (Intel Processors)`, version F.75 Rev.A, released May 17, 2024.** That's 53 versions past this machine's current F.22 (2017-07-26). An intermediate F.50 Rev.A (Aug 24, 2021) is also listed, confirming HP kept updating this platform steadily over years, not just once. ("Intel Processors" in the name refers to the platform variant — this laptop's CPU is Intel (i7-8550U); the AMD chip is a discrete GPU only, not the CPU platform HP is distinguishing here.)
- Automated fetching of `support.hp.com` failed on every attempt from this session (empty/timed-out JS shell, tried the generic family page and a direct `?sku=` URL) — this F.75 confirmation came from the user manually loading the page in a real browser, filtering `Type: BIOS`, and screenshotting the result. Sharing that screenshot is what actually resolved this, not further automated searching.
- Have **not** confirmed whether F.75 (or anything between F.22 and F.75) actually addresses the ASPM/LTR suspend-buffer bug — HP's consumer BIOS changelogs essentially never name a specific low-level hardware bug like this, so there'd be no way to know without reading each version's release notes on the download page, or just trying it.

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

1. ~~Find the exact latest version for this model~~ — **done**: F.75 Rev.A,
   May 17, 2024, confirmed above.
2. **Download the F.75 Rev.A SoftPaq** from the same `support.hp.com` page
   (product number `2WA89EA#ABV`, Type filter → BIOS) — the "Download" link
   next to that row gives the Windows `.exe` installer.
3. Extract it on Linux (`7z x`, or Wine if that fails — see "Getting the
   actual BIOS file" above) to get the raw firmware image and any
   accompanying signature/crisis-recovery files.
4. Prepare the USB stick and flash via the Windows+B recovery combo or F10
   setup's "Flash System BIOS" option (see "Mechanism" above). Exact file
   naming/folder layout HP expects is only knowable once the real F.75
   SoftPaq is extracted and inspected.

## Sources

- [HP laptop BIOS update from Linux — blog writeup with exact steps (HP Envy x360)](https://dvdkon.ggu.cz/blogpost/hp_ex360_bios_update/)
- [Instructions to Update the BIOS/UEFI for an HP Laptop on Linux (GitHub gist)](https://gist.github.com/eNV25/c8001491dc0440656ff7b0ae18993ba1)
- [HP Notebook PCs - Recovering the BIOS (official HP doc)](https://support.hp.com/us-en/document/ish_3932413-2337994-16)
- [Flashing BIOS from Linux — ArchWiki](https://wiki.archlinux.org/title/Flashing_BIOS_from_Linux)
- `support.hp.com` driver list for this exact model (product number
  `2WA89EA#ABV`), `Type: BIOS` filter — confirmed F.75 Rev.A (2024-05-17)
  and F.50 Rev.A (2021-08-24) via a screenshot the user provided directly;
  not independently re-fetched by an automated tool.

## Overall recommendation (updated after confirming F.75 exists)

This laptop is roughly 9 years old (BIOS dated 2017, `i7-8550U` CPU from
that era), but HP kept it updated far more recently than that — F.75 is
from May 2024, not some decade-old abandonware. The two current
software-level workarounds (`mo.lock` plugin clone + screensaver disabled —
see README "Hardware notes") are confirmed working via direct testing, so
there's no urgency. But given a real, current, actively-maintained BIOS
update exists, downloading it and at least reading its own release notes
(HP's download page typically has a "What's new" / changelog section per
version) is a low-cost next step whenever there's time for it — it might
turn out to be irrelevant to the ASPM/LTR bug, or it might not; won't know
without looking.
