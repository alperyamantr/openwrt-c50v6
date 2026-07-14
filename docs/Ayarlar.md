\# Archer C50 v6 - Ayarlar Dokümantasyonu



\## Zapret DPI Bypass



| Parametre | Değer | Açıklama |

|-----------|-------|----------|

| TCP 443 | `fake,split` | TLS handshake desync |

| TCP 80 | `fake,split` | HTTP desync |

| UDP 443 (QUIC) | `fake` | HTTP3 desync |

| UDP Discord | `fake` | Voice chat bypass |

| UDP STUN | `fake` | NAT traversal |



| Optimizasyon | Değer | Etki |

|--------------|-------|------|

| TTL TCP | `4` | Fake DPI'ya ulaşır, sunucuya gitmez |

| TTL QUIC | `2` | Fake sadece DPI'ya ulaşır |

| Connbytes | `1-4` | Sadece ilk 4 paket (CPU tasarrufu) |

| Cutoff | `d4/n2` | Handshake sonrası desync'i bırakır |

| Respawn | `3600 5 5` | Crash loop koruması |

| OOM Score | `-1000` | RAM dolsa bile zapret ölmez |

| Log | `kapalı` | Flash/RAM tasarrufu |



\## Sistem Optimizasyonları



```bash

\# /etc/sysctl.conf

net.ipv4.tcp\_congestion\_control=cubic

net.ipv4.tcp\_slow\_start\_after\_idle=0

net.ipv4.tcp\_ecn=0

net.netfilter.nf\_conntrack\_max=2048

net.core.rmem\_max=262144

net.core.wmem\_max=262144

DNS Güvenliği

Table

Bileşen	Boyut	Güncelleme

Hagezi light	~1.1MB (43K domain)	Her 3 gün

USOM zararlı	~500KB (857 domain)	Her 3 gün

Statik engelleme	~37KB	Manuel (siteekle)

Cron Zamanlaması

Table

Zaman	Görev

0 4 \* \* 0	Pazar 04:00 - Reboot (70sn gecikme)

17 4 \*/3 \* \*	Her 3 gün 04:17 - Hagezi güncelleme

41 4 \*/3 \* \*	Her 3 gün 04:41 - Fake paket güncelleme

RAM Kullanımı (C50 v6 - 64MB)

Table

Bileşen	Tahmini RAM

Kernel + sistem	~20MB

Zapret (nfqws)	~800KB

Dnsmasq + cache	~2-3MB

Hagezi blocklist (/tmp)	~1.1MB

LuCI (uhttpd)	~2-3MB

Boş available	~10-14MB

Dosya Yapısı

plain

files/

├── etc/

│   ├── config/           # network, wireless, firewall, dhcp, system

│   ├── crontabs/root     # Cron zamanlaması

│   ├── dnsmasq.d/        # banned.conf, whitelist.conf

│   ├── init.d/zapret     # Zapret init script

│   ├── uci-defaults/     # 01-zapret, 02-hagezi

│   ├── rc.local          # Boot komutları

│   ├── sysctl.conf       # Kernel ayarları

│   └── zapret-bypass-ips.txt  # IP bypass listesi

├── opt/zapret/           # nfqws, fake dosyalar

└── usr/bin/              # hagezi-guncelle, siteekle



Komutlar

bash

\# Zapret durum kontrolü

/etc/init.d/zapret status

ps | grep nfqws



\# RAM kontrolü

free



\# DNS test

nslookup youtube.com 127.0.0.1



\# Domain engelleme

siteekle domain.com



\# Manuel güncelleme

/usr/bin/hagezi-guncelle

/opt/zapret/update-fake.sh

Firmware Build

bash

\# Local build

./scripts/build.sh



\# GitHub Actions

\# .github/workflows/build.yml

Bilinen Sınırlamalar

CPU: 580MHz Single Core MIPS

RAM: 64MB (DDR2)

Flash: 8MB (SPI NOR)

USB: Yok (çoğu revizyon)

cpufreq: Sabit 580MHz, governor yok

