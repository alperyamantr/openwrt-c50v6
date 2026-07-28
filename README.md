# OpenWrt Archer C50 v6 Minimal

Custom OpenWrt firmware for TP-Link Archer C50 v6 (MT7628AN) optimized for Kablonet/Türk Telekom DPI bypass, gaming, and minimal resource usage.

## Hardware Specs

| Component | Value |
|-----------|-------|
| SoC | MediaTek MT7628AN |
| CPU | 580 MHz Single Core MIPS |
| RAM | 64 MB (DDR2) |
| Flash | 8 MB (SPI NOR) |
| WiFi | 2.4GHz + 5GHz |
| USB | None (most revisions) |

## Features

- **DPI Bypass** — Zapret (nfqws) with optimized parameters for Kablonet/TT
- **Gaming Optimized** — Westwood TCP, slow_start_after_idle=0, fq_codel, low-latency buffers
- **DNS Blocklist** — Hagezi light.txt (~43K domains, ~1.1MB RAM)
- **LuCI Web Interface** — Full admin panel (uhttpd)
- **ZRAM Swap** — LZO compressed swap for 64MB RAM
- **IPv6 Disabled** — Kernel and userspace completely removed
- **Minimal Footprint** — Optimized for 8MB flash

## Zapret Configuration

### DPI Bypass Parameters

| Protocol | Method | TTL | Repeats | Cutoff | Purpose |
|----------|--------|-----|---------|--------|---------|
| TCP 443 | fake,split | 3 | 1 | d3 | HTTPS/YouTube |
| TCP 80 | fake,split | 4 | 1 | — | HTTP |
| UDP 443 (QUIC) | fake | 3 | 1 | n2 | YouTube/HTTP3 |
| UDP 50000-60000 | fake | 4 | 1 | n2 | Discord Voice |
| UDP 3478-3480 | fake | 4 | 1 | n2 | STUN/NAT |

### Key Optimizations

- `connbytes 1-4` — Only first 4 packets to nfqueue (CPU save)
- `respawn 60 10 5` — Crash loop protection
- `oom_score_adj -500` — nfqws survives OOM kills
- `badsum` fooling — Lightest CPU option
- Software flow offload — Bypasses nfqueue after first 4 packets

## Sysctl Optimizations

```bash
net.ipv4.tcp_congestion_control=westwood
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_ecn=1
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_tw_buckets=2048
net.ipv4.ip_local_port_range=1024 65535
net.core.default_qdisc=fq_codel
net.core.rmem_max=262144
net.core.wmem_max=262144
net.core.netdev_budget=300
net.core.netdev_budget_usecs=3000
net.netfilter.nf_conntrack_udp_timeout=30
net.ipv4.tcp_keepalive_time=300
vm.swappiness=10
```

> **Note:** `nf_conntrack_max`, `nfnetlink_queue_maxlen`, and `netdev_max_backlog` are set by the Zapret init script to avoid duplication.

## Build System

### GitHub Actions

```yaml
# .github/workflows/build.yml
# See workflow file for full config
```

### Local Build

```bash
# 1. Clone OpenWrt
git clone --depth=1 --branch v25.12.5 https://github.com/openwrt/openwrt.git

# 2. Run build script
./scripts/build.sh
```

### Build Scripts

| Script | Purpose |
|--------|---------|
| `prepare.sh` | Apply packages.txt to .config |
| `patch-kernel.sh` | Kernel config patches (swap, westwood built-in) |
| `optimize.sh` | Permissions + build optimizations |
| `build.sh` | Full local build pipeline |

### Package List

**Included:**
- luci-base, luci-mod-* (web interface)
- dnsmasq-full (nftset support)
- firewall4 (nftables)
- kmod-nfnetlink-queue, kmod-nft-queue (zapret)
- kmod-sched (fq_codel support)
- zram-swap, kmod-zram (RAM compression)
- fstools, block-mount, blockd (mount chain)

**Excluded:**
- IPv6 stack (kernel + userspace)
- PPP, tunnel protocols
- USB support (no physical port)
- VPN modules (tun, wireguard)
- opkg (no flash space for packages)
- procd-ujail, procd-seccomp (overhead)
- kmod-tcp-westwood (built into kernel instead)

## File Structure

```
files/
├── etc/
│   ├── init.d/
│   │   ├── zapret          # Zapret init script
│   │   └── hagezi_init     # Hagezi symlink setup
│   ├── config/
│   │   ├── dhcp            # Dnsmasq config
│   │   ├── firewall        # nftables rules
│   │   ├── network         # Interface config
│   │   ├── system          # System + LED config
│   │   ├── uhttpd          # Web server (IPv4 only)
│   │   ├── wireless        # WiFi config (open by default)
│   │   └── zram-swap      # ZRAM config
│   ├── dnsmasq.d/
│   │   ├── banned.conf     # Static blocklist
│   │   └── whitelist.conf  # Domain whitelist
│   ├── uci-defaults/
│   │   ├── 01-zapret       # Zapret boot enable
│   │   ├── 02-hagezi       # Enable hagezi_init service
│   │   └── 03-zram         # Enable zram-swap
│   ├── crontabs/
│   │   └── root            # Periodic tasks
│   ├── rc.local            # Boot scripts
│   ├── sysctl.conf         # Kernel tuning
│   └── zapret-bypass-ips.txt  # IP whitelist
├── opt/
│   └── zapret/
│       ├── nfqws           # Binary
│       ├── files/fake/     # Fake packets
│       ├── ipset/          # Host lists
│       └── update-fake.sh  # Fake packet updater
└── usr/bin/
    ├── hagezi-guncelle     # Blocklist updater
    ├── banned-guncelle     # Static list updater
    └── siteekle            # Manual domain adder
```

## Hagezi Blocklist

- **URL:** https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/light.txt
- **Format:** dnsmasq `address=/domain.com/0.0.0.0`
- **Size:** ~1.1MB (RAM disk /tmp)
- **Entries:** ~43,000 domains
- **Update:** Every boot (60s delay via rc.local)

## ZRAM Swap

```uci
config zram 'zram'
    option enabled '1'
    option size_mb '32'
    option comp_algorithm 'lzo'
```

## Known Limitations

- **CPU:** 580MHz single core — nfqueue + nftables + conntrack on same core
- **RAM:** 64MB physical, ~58MB usable — 1.1MB hagezi on RAM disk
- **Flash:** 8MB, overlay ~1.1MB — opkg cannot install packages
- **cpufreq:** Fixed 580MHz, no governor support
- **USB:** Not present on most C50 v6 revisions
- **WiFi:** Open (no encryption) by default — configure via LuCI after flash
- **SQM/CAKE:** Not available on this target

## Status

✅ Stable — Tested on Kablonet/Türk Telekom

## License

Same as OpenWrt — GPL-2.0
