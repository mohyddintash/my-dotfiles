# HP Pavilion x360 15-br1xx — BIOS update research (concluded, no update found)

**Bottom line: investigated thoroughly (2026-08-26 to 2026-08-28), found no BIOS
update confirmed compatible with this exact board. Current F.22 is likely the
only BIOS HP ever shipped for it.** Not acted on, and not expected to be
revisited unless new information turns up. See "Hardware notes" in
`README.md` for the AMD GPU bug this was investigated in relation to (the
`mo.lock` plugin clone + disabled screensaver are the actual, working fix for
that — this file was a side investigation into whether a firmware fix might
also exist, and it doesn't appear to).

## This machine's identifiers

- **Current BIOS: F.22, dated 2017-07-26**
- **Model:** HP Pavilion x360 Convertible 15-br1xx
- **Product number:** `2WA89EA#ABV` (region/config code, not a unique serial —
  safe to publish in this public repo)
- **Board name: `83CB`** — this turned out to be the critical identifier; see
  below. (`cat /sys/class/dmi/id/board_name`, or the full `dmi:...:rn83CB:...`
  string via `cat /sys/class/dmi/id/modalias`, no root needed for either.)

## What was checked, and why each lead didn't pan out

1. **`fwupdmgr get-updates`** (Linux's own firmware channel, LVFS): lists
   "System Firmware" under "no available updates". Turned out to just mean HP
   never published this model to LVFS at all — uninformative either way.

2. **A sibling model on the nominal same platform (`15-br077nr`) reported BIOS
   F.32 Rev 5.0** via a web search summary (original forum post was
   paywalled). This is what motivated the deeper dig — it implied *a*
   `15-br0xx/1xx` board got updates well past F.22. Turned out to be true, but
   only for *some* board revisions, not this one (see #5).

3. **First download found via `support.hp.com`'s family page, filtered to
   `Type: BIOS`: `SP153030`, version F.75 Rev.A (2024-05-17).** Looked
   promising (real, recent, actively maintained) — but its own metadata
   (verified two ways: the pasted release notes, and independently fetching
   HP's raw CVA record from `ftp.hp.com` directly) lists supported hardware as
   **"HP 15 Laptop" / "HP 256/250/258 G6 Notebook PC"** — a different HP
   product line (business-line "G6" budget notebooks) entirely, not the
   Pavilion x360 convertible line. **Rejected — wrong model family**, despite
   appearing on what looked like the right page. This one also had a
   worse-than-usual downside if wrong: its release notes state the update
   cannot be downgraded afterward.

4. **Second download, found the same way: `SP133135`, version F.50 Rev.A
   (2021-08-24).** Its own metadata (also verified via the raw `ftp.hp.com`
   CVA record, plus MD5 checksum matched HP's published value exactly —
   `6e8b5809b173d23bf7c5d6095ca77eeb`) genuinely lists **"HP Pavilion x360 15
   Convertible"** — the right product line this time.

5. **Extracted `SP133135.exe` on Linux and found the real problem.** `7z`
   unpacked it in two stages (outer PE → `InsydeFlash.exe` → inner 7z archive,
   54 files, standard Insyde BIOS-update layout: `CrisisFolder/`, `DEVFW/`,
   two firmware images). It covers **two board revisions, not one**:
   `08315.bin` (board `8315`) and `083CA.bin` (board `83CA`), each paired
   with a `platformXXXX.ini` whose `[Platform_Check]` section whitelists
   exactly those two board names and no others. **This machine's board is
   `83CB` — not in that list.** `strings` on both `.bin` files turned up
   nothing (modern compressed/structured UEFI images don't carry plain-text
   identifiers, so this check was inconclusive rather than reassuring).

6. **Why this particular mismatch matters more than "probably fine, try it
   anyway":** the extracted files include `H2OFFT.sys`/`H2OFFT.inf` — a
   Windows kernel driver that performs the actual live compatibility check
   (the ini's `Flag=3` behavior: "depends on what the on-board BIOS reports
   via IHISI") when `InsydeFlash.exe` is run normally, under Windows. The
   USB-based recovery-mode flash (Windows+B / F10 "Flash System BIOS") that
   this whole investigation was built around specifically to avoid Windows
   **bypasses that check** — it's a blunt, last-resort mechanism that writes
   whatever valid-looking firmware capsule it finds, by design, since it
   exists to recover a BIOS that's already too broken to run its own checks.
   So the one path available to us without Windows is also the one path with
   the least protection against exactly this kind of mismatch.

7. **Asked HP's own support/virtual-assistant chat directly**, twice,
   increasingly precisely (first generally, then explicitly "System BIOS, not
   ME/TXE firmware, for board 83CB, product 2WA89EA#ABV"). First answer
   returned Intel ME/TXE firmware SoftPaqs (`SP96325`, `SP90139`) — a
   different firmware component from the system BIOS entirely, doesn't
   address the ASPM/LTR bug and doesn't resolve the board question. Confirmed
   useful side fact: board `83CB` does belong to the right family
   ("15-br0xx/15t-br000" and "15-br1xx/15t-br100" are both named in that
   answer). Second, precisely-scoped answer: HP's own assistant explicitly
   said it **could not find** a System BIOS SoftPaq tied to board `83CB` /
   this model / this product number.

## Conclusion

Three independent sources — the SP133135 SoftPaq's own compatibility
whitelist, and HP's own assistant asked twice — all fail to produce a BIOS
update confirmed compatible with board `83CB`. The likely explanation: HP's
"15-br1xx" marketing name spans multiple distinct board revisions (`83CA`,
`8315`, `83CB`, possibly others) manufactured across different runs/markets,
and they didn't all get equal support — `83CA`/`8315` got updated at least to
F.50 (and unrelated boards on an entirely different product line reached
F.75), while `83CB` may simply never have received a BIOS update past F.22.

**Neither downloaded file (`SP153030` F.75, `SP153030` F.50) should be
flashed onto this machine.** `SP153030` is confirmed wrong-model. `SP133135`
is right-model but confirmed wrong-board, with no safety net available via
the only Windows-free flashing path.

If this is ever revisited: the one avenue not yet tried is HP's phone/email
support with a real support case number (rather than the chat assistant),
who can look up manufacturing/board records the public chat bot's knowledge
base apparently doesn't have. Not pursued given the working software-level
mitigations already in place (see README "Hardware notes") make this a
nice-to-have, not a need-to-have.

## Reference: the general (Windows-free) BIOS flashing method

Kept for future reference in case a genuinely-matched update ever turns up
for this or another machine — this part of the research was sound, the
problem was specifically board compatibility, not the method.

### Mechanism: HP hardware BIOS Recovery (no OS involved at all)

This is HP's built-in recovery firmware — it runs before any bootloader or
OS:

1. Format a USB stick FAT32, put the correct BIOS recovery file at its root
   (exact filename/layout is model-specific — inspect the real SoftPaq once
   downloaded, e.g. the `CrisisFolder`/`DEVFW` layout described below).
2. With the laptop **off**, hold **Windows key + B** (some Pavilion 15/x360
   variants use **Windows key + V** instead), then press and hold the power
   button for 2-3 seconds, then release all keys.
3. Screen stays blank for about 40 seconds, possibly a series of beeps
   (~8), then it boots straight into the recovery flash tool and reads the
   file from USB automatically.

There's also a manual **F10 setup → "Flash System BIOS" / "Update System
BIOS from USB"** menu option on many HP models as a second path.

### Getting the actual BIOS file, without running Windows

HP distributes BIOS updates as a Windows `.exe` ("SoftPaq"). Extraction, not
execution, is what's needed:

- **`sudo pacman -S --needed p7zip cabextract innoextract`**, then `7z x
  file.exe` — worked directly for both SoftPaqs tried here. HP's installer
  wraps a Microsoft CAB (`Type = Cab`, `LZX` compression per `7z`'s own
  output) containing `InsydeFlash.exe`, which is itself a 7z archive (`7z x
  InsydeFlash.exe` again) containing the actual payload: two board-specific
  `.bin` firmware images, matching `platformXXXX.ini` files (with the
  `[Platform_Check]`/`[FDFile]` sections that name the compatible board(s)
  and firmware filename — **read this before trusting any board "looks
  close enough"**), a `CrisisFolder/` (recovery-mode EFI binaries), and a
  `DEVFW/` folder.
- **If `7z` alone doesn't work:** run the `.exe` under **Wine** (a
  compatibility layer, not a Windows install) and copy the extracted files
  out of `$WINEPREFIX/drive_c/windows/temp/7z*.tmp/` before the installer
  finishes and cleans up. Not needed for either SoftPaq tried here.
- These three packages have no daemons/config/state — clean to
  `pacman -Rns` once done and not expected to be needed again.

### Verifying you have the right file, before touching a flash mechanism

In order of how much they're worth trusting:

1. **The `.ini`'s `[Platform_Check]` `PlatformNameN=` list, against `cat
   /sys/class/dmi/id/board_name`.** This is what actually gates the flash —
   an exact string match, not a family/model-name match.
2. MD5 of the downloaded file against HP's published value in the release
   notes — confirms the download wasn't corrupted, says nothing about
   whether it's the right file for your board.
3. The SoftPaq's "HARDWARE PRODUCT MODEL(S)" text — a marketing-level
   product line name, not a board-level guarantee. Necessary but not
   sufficient (this passed for `SP133135` while the board check still
   failed).
4. Asking HP support (chat or otherwise) for your exact board name +
   product number — useful when it gives a real answer, but its knowledge
   base may simply not have every board revision indexed (as happened here).

## Sources

- [HP laptop BIOS update from Linux — blog writeup with exact steps (HP Envy x360)](https://dvdkon.ggu.cz/blogpost/hp_ex360_bios_update/)
- [Instructions to Update the BIOS/UEFI for an HP Laptop on Linux (GitHub gist)](https://gist.github.com/eNV25/c8001491dc0440656ff7b0ae18993ba1)
- [HP Notebook PCs - Recovering the BIOS (official HP doc)](https://support.hp.com/us-en/document/ish_3932413-2337994-16)
- [Flashing BIOS from Linux — ArchWiki](https://wiki.archlinux.org/title/Flashing_BIOS_from_Linux)
- `support.hp.com` driver list for this model, `Type: BIOS` filter (screenshots provided directly by the user; `support.hp.com` itself never rendered for any automated fetch attempt this session)
- Raw SoftPaq CVA metadata fetched directly from `ftp.hp.com/pub/softpaq/sp<range>/sp<N>.html` for both `SP153030` and `SP133135` — the actual source of truth for hardware compatibility, more reliable than a driver-list page association
- HP's own support virtual assistant, queried directly for board `83CB` compatibility (no public URL — chat session)
