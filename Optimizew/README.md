# Optimization PC — Documentation

[ПЕРЕВОД](RREADME.md)

A console menu written as a `.bat` file for routine Windows 10/11 maintenance: junk cleanup, cache resets, power plan, disk optimization and system file checks. It includes a power plan rollback, restore point creation and an action log.

**File:** `optimize_pc.bat`

---

## Requirements

- Windows 10 or 11.
- Administrator rights.
- PowerShell (built into Windows) — used for the Recycle Bin and the restore point.
- For the restore point: **System Protection** must be enabled for drive C: (see "Troubleshooting").
- For option 7 (DISM): an internet connection.

## How to run

1. Put `optimize_pc.bat` in its own folder, for example `C:\Tools\Optimization`. The script creates its log and backup file next to itself.
2. Right-click the file → **Run as administrator**.
3. Type a menu number and press Enter.

Without administrator rights the script shows a warning and exits.

---

## Menu options

| # | Action | What it does | Reversible? |
|---|--------|--------------|-------------|
| 1 | Temporary files | Deletes the contents of `%TEMP%` and `C:\Windows\Temp` | No (programs recreate them) |
| 2 | Windows Update cache | Stops the `wuauserv` and `bits` services, clears `SoftwareDistribution\Download`, starts the services again | No (Windows re-downloads what it needs) |
| 3 | Recycle Bin | Empties the Recycle Bin via PowerShell and **asks for confirmation (Y/N)** | No |
| 4 | DNS cache | `ipconfig /flushdns` | The cache refills by itself |
| 5 | High Performance | Saves the current power plan and switches to "High performance" | **Yes — option 10** |
| 6 | Optimize drive C: | `defrag C: /O`: TRIM on SSD, defragmentation on HDD | Not needed |
| 7 | Check system files | `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth` | Not needed (repairs corruption) |
| 8 | Do everything | Restore point, then options 1–7 | Partially (see below) |
| 9 | Create a restore point | Creates a restore point named "Optimization PC" | — |
| 10 | Restore previous power plan | Switches back to the plan that was active before option 5 | — |
| 11 | Open System Restore | Opens the `rstrui.exe` wizard | — |
| 0 | Exit | | |

### Notes on each option

- **Option 1.** Files locked by running programs are skipped silently. Close browsers and editors before running it.
- **Option 2.** Do not run it while updates are installing. The next update check may take longer than usual.
- **Option 5.** The backup of the previous plan is created once and deleted after a successful rollback. If the "High performance" plan does not exist on the PC (common on laptops), the script creates a copy of it. On a laptop this plan drains the battery faster and runs the fans harder.
- **Option 6.** Defragmenting an HDD can take a long time.
- **Option 7.** Takes from a few minutes to about an hour. Do not interrupt it.
- **Option 8.** If the restore point cannot be created, the script prints a warning and continues.

---

## What can and cannot be undone

The script only removes temporary data and caches, but **deleted data is not recoverable**. Rollback is possible in two cases:

| What | How to undo |
|------|-------------|
| Power plan | Menu option 10 |
| System-level changes (Windows files, registry, drivers) | Restore point (options 9 and 11) |
| Temporary files, update cache, DNS cache | Not needed: they are recreated automatically |
| Recycle Bin contents | **Cannot be recovered.** Review the bin before running option 3 |

A restore point does **not bring back personal files** (documents, photos, code) and does not recover the Recycle Bin contents.

## How to get back to the previous state

1. **Power plan.** Run the script as administrator and choose option 10. Manually: `powercfg /list`, then `powercfg /setactive <GUID>`.
2. **System rollback.** Choose option 11 (or press `Win+R` → `rstrui`) and select the "Optimization PC" restore point. Save your work first: the computer will restart.
3. **If Windows Update behaves oddly after option 2:** restart the PC. The `SoftwareDistribution` folder is recreated automatically.

---

## Files created by the script

| File | Location | Purpose |
|------|----------|---------|
| `optimize.log` | next to the script | Log: date, time and action |
| `optimize_power_backup.txt` | next to the script | GUID of the previous power plan; deleted after option 10 |

Example log line:

```
09.10.2026 14:32:05,12 - Temporary files cleaned
```

The date format depends on the Windows regional settings.

---

## How the code works

Useful for walking through the script in class:

- `net session` — administrator check: the command only works with elevated rights.
- `:label` and `call :label` — functions; `exit /b` returns control to the caller.
- `goto done` — jumps to the "Ready / pause" label so the result is not wiped by `cls`.
- `set /p` — keyboard input; `set "choice="` comes first so an empty input does not repeat the previous choice.
- `%~dp0` — the folder containing the `.bat` itself; the log and backup are created next to the script regardless of the current directory.
- `for /f ... in ('powercfg ...')` — parses command output to extract the power plan GUID.
- `>nul 2>&1` — hides normal output and error messages.
- PowerShell calls — for the Recycle Bin (`Clear-RecycleBin`) and the restore point (`Checkpoint-Computer`).

---

## Troubleshooting

**The restore point is not created.**
Enable System Protection: `Win+R` → `sysdm.cpl` → "System Protection" tab → select drive C: → "Configure" → "Turn on system protection". Also, by default Windows creates at most one restore point per 24 hours, so a new one may be skipped.

**"The system cannot find the batch label specified".**
The file is damaged or saved with the wrong line endings. Use the original file, or save your copy with Windows (CRLF) line endings.

**Garbled characters instead of text.**
Save the file as UTF-8 without BOM, or as ANSI. The script contains no Cyrillic characters; everything is plain ASCII.

**Option 5 does not change the plan on a laptop.**
On some devices (Modern Standby) power plans are restricted by the manufacturer. Use the standard Windows power settings instead.

**Antivirus or SmartScreen warns about the file.**
This is a normal reaction to any `.bat` that asks for elevated rights. The code is open — read it before running.

---

## Limitations and safety

- The script does **not** modify the registry, does **not** permanently disable services and does **not** touch the Prefetch folder.
- Do not run it during Windows updates or heavy disk activity.
- On work or school computers, administrator policies may block some actions.
- The script is not a magic speed-up: a clean startup list, free disk space and enough RAM help far more.

## Changelog

- **2.0** — added: restore point, power plan rollback, log, Recycle Bin confirmation, a menu item to open System Restore, automatic creation of the "High performance" plan when it is missing.
- **1.0** — basic menu: cleanup, DNS, power, disk, sfc/DISM.