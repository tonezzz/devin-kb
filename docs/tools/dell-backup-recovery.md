# tony-dell disk layout & disaster recovery

Set up 2026-11-18. Goal: SSD-dead recovery + fast system rollback.

## Disk map

| Device | Size | FS | Label | Mount | Role |
|---|---|---|---|---|---|
| nvme0n1p3 | 224G | ext4 | dell-root | `/` | live system (Samsung 970 EVO Plus 250G) |
| nvme0n1p1 | 512M | vfat | DELL-EFI | `/boot/efi` | live ESP |
| nvme0n1p2 | 8G | swap | dell-swap | swap | |
| sda1 | 1G | vfat | rescue-efi | (rescue only) | rescue OS ESP |
| sda2 | 79G | ext4 | rescue-root | (rescue only) | minimal Ubuntu 26.04 rescue OS |
| sda3 | 386G | ext4 | timeshift | `/timeshift` | Timeshift RSYNC snapshots of `/` |
| sdb1 | 916G | ext4 | dell-backup | `/dell-backup` | restic repo (USB HDD) |

sda = internal Seagate 500G SATA HDD (was old Windows disk). sdb = USB HGST 1TB.

## Backups

### restic → /dell-backup/restic (sdb1, USB)

- Repo: `/dell-backup/restic`, encrypted. Passphrase: `~/.config/secrets/restic-dell.env` (`RESTIC_REPOSITORY`, `RESTIC_PASSWORD`). **Keep an offline copy of the passphrase — without it the repo is unrecoverable.**
- Script: `~/.local/bin/dell-restic-backup.sh <critical|home>`
- Timers (user): `dell-restic-critical.timer` daily 03:30, `dell-restic-home.timer` weekly Sun 02:00.
- Tags/retention: `critical` keep 7d/4w/6m; `home` keep last 4 + 6 monthly; `sda5-archive` one-shot.
- critical = ~/.config/{secrets,systemd,devin,containers,go}, ~/.local/bin, ~/.ssh, /var/backups/dell-etc-snapshot.tar.gz
- home = /home/tony minus GoogleDrive/.cache/node_modules/container data
- Logs: `~/var/log/dell-restic-<mode>.log`

### Fleet restic → /dell-backup/restic-fleet/<host> (added 2026-11-18)

Per-host rebuild-set backups over sftp from idc03, idc02, tony-omen,
tony-macbook, mn01 → separate encrypted repo per host on dell's sdb.
Each host: `~/.local/bin/fleet-restic-backup.sh` + user timer
(fleet-restic-backup.timer, daily ~04:30-05:30 staggered).
Backs up ~/.config/{secrets,systemd,containers,devin}, ~/.local/bin,
~/bin, ~/.ssh + /var/backups/host-etc-snapshot.tar.gz.
macbook uses a static binary in ~/.local/bin (no sudo needed) and has
no /etc snapshot (no sudo) — Persistent timer catches up when awake.
Passphrases: `~/.config/secrets/restic-fleet-<host>.env` on BOTH the
host and dell (dell copies are inside the critical backup).

### Off-site leg → idc03:~/restic-offsite (added 2026-11-18)

Weekly Sun 06:00 `dell-restic-offsite.timer` runs
`~/.local/bin/dell-restic-offsite-copy.sh`: `restic copy` of the latest
3 critical snapshots from the main repo + latest snapshot from each
fleet repo into `sftp:tony@idc03:restic-offsite` (single consolidated
encrypted repo, ~2-3G). Home-tier snapshots stay local-only (50G+ —
idc03 disk can't hold them); documented gap.
Offsite password: `~/.config/secrets/restic-offsite.env` on dell.

### Timeshift → sda3 (internal HDD)

- Config: `/etc/timeshift/timeshift.json` — RSYNC mode, weekly schedule, keep 4 weekly/6 monthly.
- Snapshots land in `/timeshift/timeshift/snapshots/` and register in the **live** GRUB menu (restore without rescue OS when SSD is alive).
- Excludes /home, /root, /srv, /var/log, /tmp, /swapfile, /timeshift, /dell-backup → system-only; /home is covered by restic.
- Restore: `sudo timeshift --restore --snapshot '<name>'` (interactive) or `--target-device`.

### sda5-archive (one-shot, 2026-11-18)

Old June-2026 `/home/tony` (79.7 GiB processed) archived to restic tag `sda5-archive`, snapshot `6b797162` before sda was repartitioned.

## Recovery procedures

### A. System broken, SSD alive → Timeshift

Reboot → GRUB menu → Timeshift snapshots appear under live Ubuntu entries → pick snapshot → boot → `sudo timeshift --restore` if needed.

### B. NVMe SSD dead → rescue OS on sda

1. Power on — firmware falls through BootOrder (`0005` NVMe fails → `0004` Ubuntu-Rescue on sda1 ESP).
2. Rescue boots minimal Ubuntu (kernel 7.0.0-43), DHCP on ethernet (`en*`), ssh as `tony` (same authorized_keys, NOPASSWD sudo).
3. In rescue:
   - `sudo mount /dell-backup` (sdb1, USB repo)
   - `source ~/.config/secrets/restic-dell.env && restic snapshots` — env file was backed up in `critical` tag; if missing, passphrase must come from offline copy.
   - `restic restore latest --target /mnt/newroot` (after installing new NVMe + Ubuntu, or restore into a mounted target).
   - Timeshift snapshots on sda3 can also be mounted/copied manually.
4. New NVMe: install Ubuntu 26.04 normally → boot → run restic restore for `critical` then `home`.

### C. Both local disks dead → off-box

GitHub (code), idc03 MDDB (fleet data), and optionally `restic copy` repo to idc03/gdrive (not yet configured).

## UEFI boot entries (dell)

- `Boot0005 Ubuntu-NVMe` — live system, first in BootOrder.
- `Boot0004 Ubuntu-Rescue` — sda1 ESP `\EFI\ubuntu-rescue\grubx64.efi`, second.
- `\EFI\BOOT\BOOTX64.EFI` fallback copy also on sda1.
- Rescue GRUB menu also lists the live NVMe system (os-prober) — handy for booting live from rescue if needed.

Stale entries to be aware of: `Boot0000 Windows Boot Manager`, `Boot0001 Ubuntu (sda)`, `Boot0002 Ubuntu` all point at the OLD sda layout (dead since repartition) — harmless, firmware skips missing paths; can be deleted with `efibootmgr -b XXXX -B`.

## Test-boot (declined 2026-11-18)

Not performed — entry verified statically only (ESP files, grub.cfg, UEFI entry, BootOrder). If ever needed: reboot → firmware boot menu / `efibootmgr -n 0004` → verify ssh in, `mount /dell-backup`, `restic snapshots`, `mount /timeshift`.

## Known gaps

- No off-site restic copy yet (repo is single-copy on USB disk attached to same box).
- Timeshift excludes /home — intentional (restic covers it), but a bare-metal restore needs BOTH steps.
- Rescue OS has no WiFi (ethernet DHCP only) and no Tailscale — fine for recovery, install tailscale manually if tailnet needed.
- sda is a 5400rpm-class HDD — Timeshift weekly snapshots of ~system-size are fine; avoid putting big data there.
- One unreadable file during sda5 archive (restic warning) — likely a socket/vanished file; acceptable for a fossil snapshot.
- RESTIC_PASSWORD offline copy: verify Tony has it stored somewhere safe (password manager) — repo is useless without it.

## Verify commands

```bash
df -h / /timeshift /dell-backup
restic -r /dell-backup/restic snapshots   # with env sourced
sudo timeshift --list
sudo efibootmgr | grep -E "Boot0004|Boot0005|BootOrder"
```
