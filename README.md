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

- **DPI Bypass** - Zapret (nfqws) with optimized parameters for Kablonet/TT
- **Gaming Optimized** - cubic TCP, slow_start_after_idle=0, fq_codel
- **DNS Blocklist** - Hagezi light.txt (~43K domains, ~1.1MB RAM)
- **LuCI Web Interface** - Full admin panel (uhttpd)
- **ZRAM Swap** - LZ4 compressed swap for 64MB RAM
- **IPv6 Disabled** - Kernel and userspace completely removed
- **Minimal Footprint** - Optimized for 8MB flash

## Zapret Configuration

### DPI Bypass Parameters

| Protocol | Method | TTL | Repeats | Cutoff | Purpose |
|----------|--------|-----|---------|--------|---------|
| TCP 443 | fake,split | 4 | 2 | d4 | HTTPS/YouTube |
| TCP 80 | fake,split | 4 | 2 | - | HTTP |
| UDP 443 (QUIC) | fake | 2 | 6 | d4 | YouTube/HTTP3 |
| UDP 50000-60000 | fake | 4 | 3 | n2 | Discord Voice |
| UDP 3478-3480 | fake | 4 | 3 | n2 | STUN/NAT |

### Key Optimizations

- `connbytes 1-4` - Only first 4 packets to nfqueue (CPU save)
- `respawn 3600 5 5` - Crash loop protection
- `oom_score -1000` - nfqws survives OOM kills
- `stdout/stderr 0` - No logging (flash/RAM save)
- `badsum` fooling - Lightest CPU option

## Sysctl Optimizations

```bash
net.ipv4.tcp_congestion_control=cubic
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_ecn=0
net.netfilter.nf_conntrack_max=2048
net.core.rmem_max=262144
net.core.wmem_max=262144
```

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
| `optimize.sh` | Kernel config + permissions |
| `build.sh` | Full local build pipeline |

### Package List

**Included:**
- luci-base, luci-mod-* (web interface)
- dnsmasq-full (nftset support)
- firewall4 (nftables)
- kmod-nfnetlink-queue, kmod-nft-queue (zapret)
- zram-swap, kmod-zram (RAM compression)
- fstools, block-mount, blockd (mount chain)

**Excluded:**
- IPv6 stack (kernel + userspace)
- PPP, tunnel protocols
- USB support (no physical port)
- VPN modules (tun, wireguard)
- opkg (no flash space for packages)
- procd-ujail, procd-seccomp (overhead)

## File Structure

```
files/
├── etc/
│   ├── init.d/zapret          # Zapret init script
│   ├── rc.local               # Boot scripts
│   ├── sysctl.conf            # Kernel tuning
│   └── config/
│       └── dhcp               # Dnsmasq config
├── opt/
│   └── zapret/
│       ├── nfqws              # Binary
│       └── files/fake/        # Fake packets
└── usr/bin/
    └── hagezi-guncelle         # Blocklist updater
```

## Hagezi Blocklist

- **URL:** https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/light.txt
- **Format:** dnsmasq `address=/domain.com/0.0.0.0`
- **Size:** ~1.1MB (RAM disk /tmp)
- **Entries:** ~43,000 domains
- **Update:** Every boot (25s delay)

## Known Limitations

- **CPU:** 580MHz single core - nfqueue + nftables + conntrack on same core
- **RAM:** 64MB physical, ~58MB usable - 1.1MB hagezi on RAM disk
- **Flash:** 8MB, overlay ~1.1MB - opkg cannot install packages
- **cpufreq:** Fixed 580MHz, no governor support
- **USB:** Not present on most C50 v6 revisions

## Status

✅ Stable - Tested on Kablonet/Türk Telekom

## License

Same as OpenWrt - GPL-2.0
