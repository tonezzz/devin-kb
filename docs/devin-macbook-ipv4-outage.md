# tony-macbook: IPv4 dead → Devin "loading session forever" (2026-10-21)

Symptom: Devin IDE spins on "Loading session…" forever. Exit/reopen doesn't help.

## Root cause

NOT a Devin problem — **IPv4 on `enx00e04c361276` was dead** while IPv6 worked:

- DHCPv4 handed out `192.168.1.106/24` gw `192.168.1.1` — but that subnet doesn't
  exist on the segment (real LAN is `192.168.2.x`). Every IPv4 ARP → INCOMPLETE,
  including the gateway. DHCP option 6 in the lease even contained `0.0.0.0` —
  signature of a rogue/broken DHCP server on the segment (a device whose v4 stack
  is wedged: dhcpd answers via raw socket but nothing ARPs).
- `ping6` fine; `curl api.devin.ai` works (has AAAA); `windsurf-stable.codeium.com`
  and `unleash.codeium.com` are **IPv4-only** → `EHOSTUNREACH`.
- Same L2 segment as tony-dell confirmed via IPv6 neighbors (dell's
  `2001:fb1:8f:c47e:a505:...` REACHABLE on the macbook's NIC).

Log signature: `~/.config/Devin/logs/<ts>/main.log` shows
`CodeWindow: failed to load (reason: ERR_ADDRESS_UNREACHABLE, code: -109)` —
the window can't even fetch its UI → UI sits on "loading session" forever.

## Workaround deployed (until LAN v4 is fixed)

SOCKS tunnel over Tailscale to tony-dell + local CONNECT bridge, all user-level
(no sudo on this host — polkit denies `nmcli dev connect` over SSH):

- `~/.config/systemd/user/v4fix-socks.service` — `ssh -N -D 127.0.0.1:1080 tony-dell`
  (macbook's `~/.ssh/config` already has `Host tony-dell` → 100.68.142.13).
- `~/.local/bin/connect2socks.py` + `~/.config/systemd/user/connect2socks.service` —
  HTTP CONNECT proxy on `127.0.0.1:8888` that dials out via the SOCKS port.
  Needed because devin-cli (reqwest) treats `socks5://` in HTTPS_PROXY as an
  HTTP proxy → "Connect HTTP error" (`Failed to fetch team settings`).
- GNOME system proxy: `gsettings org.gnome.system.proxy mode manual`,
  `proxy.socks host=127.0.0.1 port=1080` (covers Chromium window loads).
- `~/.config/Devin/User/settings.json`: `"http.proxy": "socks5://127.0.0.1:1080"`.
- `~/.config/devin/config.json`: `"proxy": {"mode":"manual","url":"http://127.0.0.1:8888","no_proxy":"localhost,127.0.0.1"}`.
- Launch env for the CLI/Node children: `HTTP(S)_PROXY=http://127.0.0.1:8888`,
  `ALL_PROXY=socks5://127.0.0.1:1080`, `NO_PROXY=localhost,127.0.0.1`,
  plus `--proxy-server=socks5://127.0.0.1:1080` on the command line.
  Both user units are `enabled` → restart with the login session.

## Revert checklist (once real IPv4 is back)

```bash
gsettings set org.gnome.system.proxy mode 'none'
systemctl --user disable --now connect2socks v4fix-socks
# remove "http.proxy" from ~/.config/Devin/User/settings.json
# remove "proxy" block from ~/.config/devin/config.json
```

## Rogue DHCP server identified (2026-10-22)

The LAN has **two competing DHCP servers**; whichever OFFER lands first wins:

| | Rogue | Real router |
|---|---|---|
| Reply src / Server-ID | `0.0.0.0` | `192.168.2.1` |
| Lease offered | `192.168.1.x`, gw `192.168.1.1`, DNS `192.168.1.1, 0.0.0.0`, 1h | `192.168.2.x`, 24h |
| Reply src MAC | **`06:28:58:26:4b:2c`** | `98:00:6a:68:f7:c6` |

- The rogue box holds **`192.168.2.93`** on the real subnet (captured via
  `sudo tcpdump -e 'udp port 67'` + `nmap --script broadcast-dhcp-discover`).
  Locally-administered MAC, all TCP ports closed, UDP 53+67 open → embedded
  dnsmasq on an **unnumbered interface** (that's why replies come from
  `0.0.0.0` and `192.168.1.1` never ARPs — the advertised gateway doesn't
  exist on this segment).
- Suspects: WiFi extender / spare router in broken AP mode / TV box.
  Locate via router client list at `192.168.2.1` for MAC `06:28:58:26:4b:2c`.
- **mn01 is also a victim**: its wired `enp1s0` took rogue lease
  `192.168.1.101` (its own libvirt dnsmasq only binds `virbr0` — not the culprit).
- WiFi was NOT at fault: `wlp3s0` (BCM43602/brcmfmac on a MacBookPro13,3)
  joined the real AP (BSSID `98:00:6a:68:f7:c8`) but got a poisoned lease —
  `192.168.1.111` with the dead-gw default route at metric 20060, which then
  **wins over ethernet's good route** (30000). Missing `clm_blob`/`txcap_blob`
  are advisory only ("limited channels").

## Real fix still needed

- **Find & unplug/fix `06:28:58:26:4b:2c`** (check router client list).
- Immune-by-config alternative: static IPv4 on the macbook's ethernet —
  `nmcli con mod netplan-enx00e04c361276 ipv4.method manual
  ipv4.addresses 192.168.2.65/24 ipv4.gateway 192.168.2.1 ipv4.dns 192.168.2.1`
  (rogue leases then can't poison it; wifi can also be left disconnected).
- Repro command to catch both servers:
  `sudo tcpdump -i <iface> -nn -e 'udp port 67 or udp port 68'` while running
  `sudo nmap --script broadcast-dhcp-discover -e <iface>`.
- Second USB NIC `enx7ed2da73308a` has link but no NM profile — can't
  activate without local polkit auth (SSH polkit denies `nmcli dev connect`).

## Gotchas learned

- **Relaunching while an old instance is still dying**: the new main (pid
  never written to `~/.config/Devin/code.lock`) starts with no window and no
  main.log — silently orphaned "secondary". Always `pgrep -c devin-desktop` = 0
  AND remove `code.lock` before relaunch.
- 98 stale `~/.local/share/devin/cli/session_locks/*.lock` (dead PIDs) — cleared.
- `sessions.db` is **4.2 GB** + 79 MB WAL on the macbook — expect slow loads;
  consider archiving old sessions (see devin-desktop-sluggishness.md).
- One transient `ERR_BLOCKED_BY_RESPONSE (-27)` on first window nav through the
  proxy is normal; the retry succeeds (workbenchReady ~4s later).
