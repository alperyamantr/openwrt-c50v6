# Archer C50 v6 — OpenWrt Ayarları

> TP-Link Archer C50 v6 için düşük kaynak tüketimi, stabil DNS filtreleme ve Zapret DPI bypass yapılandırması.

---

## Sistem Bilgisi

| Parametre    | Değer                                       |
| ------------ | -------------------------------------------- |
| Model        | TP-Link Archer C50 v6                       |
| OpenWrt      | 25.12.5 r33051-f5dae5ece4                   |
| Kernel       | 6.12.94                                     |
| CPU          | MediaTek MT7628AN, 580 MHz Single-Core MIPS |
| RAM          | 64 MB DDR2                                  |
| Flash        | 8 MB SPI NOR                                |
| USB          | Yok                                          |
| CPU Governor | Yok / Sabit 580 MHz                         |

---

# Zapret DPI Bypass

Zapret, `nfqws` ve nftables NFQUEUE kullanılarak DPI bypass amacıyla çalışır. Custom procd init script (`/etc/init.d/zapret`), üstte değişkenlerle parametrize edilmiş:

```sh
FLOWOFFLOAD="software"
QUIC_MODE="desync"
WAN_IF="eth0.2"
LAN_IF="br-lan"
QUEUE_PKTS=4
```

## Trafik Yapısı

| Trafik      | Desync       | Amaç                  |
| ----------- | ------------ | --------------------- |
| TCP 443     | `fake,split` | TLS handshake bypass  |
| TCP 80      | `fake,split` | HTTP bypass           |
| UDP 443     | `fake`       | QUIC / HTTP3 bypass   |
| Discord UDP | `fake`       | UDP trafik bypass     |
| STUN        | `fake`       | NAT traversal         |

## Aktif Optimizasyonlar

| Parametre     | Değer      | Açıklama                          |
| ------------- | ---------- | ---------------------------------- |
| qnum          | `80`       | NFQUEUE numarası                   |
| TCP TTL       | `3-4`      | DPI için agresif olmayan fake TTL  |
| QUIC TTL      | `3`        | QUIC fake paketleri için TTL       |
| repeats       | `1`        | CPU tasarrufu için minimum tekrar  |
| fooling       | `badsum`   | md5sig kaldırıldı (Kablonet kopma) |
| TCP connbytes | `1-4`      | İlk 4 paket işlenir                |
| UDP connbytes | `1-4`      | İlk 4 paket işlenir                |
| TCP cutoff    | `d3/d4`    | Desync erken bırakılır             |
| UDP cutoff    | `n2`       | İlk paketler sonrası durur         |
| Respawn       | `60 10 5`  | Crash loop koruması                |
| oom_score_adj | `-500`     | RAM baskısında nfqws önceliği      |

### Neden `TTL=3-4`?

KabloNet üzerinde daha yumuşak TTL değerleri daha stabil çalışıyor. Aşırı agresif ayarlar (yüksek repeats, düşük TTL) CPU yükünü artırıp video/ses kesintilerine yol açtı; mevcut ayar denge noktası.

---

# Flow Offload (CPU Tasarrufu)

`FLOWOFFLOAD="software"` aktif. İlk `QUEUE_PKTS` (4) paketten sonraki trafik nftables flowtable üzerinden CPU'ya uğramadan hızlı yoldan geçer:

```sh
nft add flowtable inet zapret ft "{ hook ingress priority 0; devices = { br-lan, eth0.2 }; }"
```

Bypass/flow kuralları **queue kurallarından önce** tanımlanmalı, aksi halde DPI bypass etkisiz kalır.

---

# IP İstisna Listesi (`/etc/zapret-bypass-ips.txt`)

Bu IP blokları NFQUEUE'ya hiç girmez, doğrudan kabul edilir. **Sadece test edilmiş, dar (/24) bloklar** tutulur — geniş (/16, /8) aralıklar zapret'i büyük bölgelerde işlevsiz kılacağı için kullanılmaz.

```text
# Türk Telekom / TT Mobil
212.175.73.0/24
212.175.9.0/24
85.111.49.0/24
93.155.105.0/24

# Aveva / TTNet
217.174.44.0/24

# CleverTap CDN (TT Mobil push bildirimleri)
108.157.52.0/24

# Aras Kargo
31.206.55.115

# Steam
103.10.124.0/24
```

> Daha önce eklenen `212.175.0.0/16`, `85.111.0.0/16`, Turkcell/Vodafone/TurkNet/Türksat `/16` blokları, Cloudflare (`162.159.0.0/16`) ve Google Cloud (`34.0.0.0/8`) kaldırıldı — bu geniş bloklar zapret'i milyonlarca IP için devre dışı bırakıyordu.

---

# NFQUEUE

```sh
cat /proc/net/netfilter/nfnetlink_queue
```

`nfnetlink_queue_maxlen` bu kernel sürümünde mevcut değil — normal, kernel desteklemiyor, manuel ayarlanmaya çalışılmaz.

---

# Sistem Optimizasyonları — /etc/sysctl.conf

```conf
# TCP Congestion & Performance
net.ipv4.tcp_congestion_control=westwood   # kmod-tcp-westwood eklendi; kernel'de yoksa cubic'e düşer
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_ecn=1                          # bufferbloat/gecikme azaltma için ACIK
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_tw_reuse=1

# Buffer Tuning (C50 RAM sinirina uygun)
net.core.netdev_max_backlog=1024
net.core.netdev_budget=300
net.core.netdev_budget_usecs=3000
net.core.rmem_max=262144
net.core.wmem_max=262144
net.core.rmem_default=163840
net.core.wmem_default=163840

# Keepalive (Ghost connection temizligi)
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=3

# RAM Yonetimi
vm.swappiness=10
```

> **Not:** `nf_conntrack_max` burada YOK — zapret init scripti kendi içinde set ediyor (`4096`). Çakışma olmaması için tek kaynak zapret script'i.

### fq_codel / kmod-sched

`net.core.default_qdisc=fq_codel` sysctl'de ayarlıydı ama `kmod-sched` paketi eksik olduğu için gerçekte `pfifo_fast` çalışıyordu (bufferbloat koruması aktif değildi). **`kmod-sched` artık `packages.txt`'e eklendi** — yeni build'de gerçek `fq_codel` aktif olacak.

### TCP Westwood

`kmod-tcp-westwood` `packages.txt`'e eklendi (önceki build'de mevcut değildi). Yeni build sonrası doğrulama:

```sh
sysctl net.ipv4.tcp_available_congestion_control
```

`westwood` listede çıkmazsa `cubic` fallback olarak kalır.

> **Önemli nüans:** Bu ayar sadece **router'ın kendi başlattığı** bağlantıları etkiler (DNS-over-TCP, NTP, Hagezi/USOM indirmeleri). LAN'daki cihazların (PC, telefon) NAT üzerinden geçen trafiğinin congestion control'ü kendi işletim sisteminde belirlenir, router ayarından etkilenmez.

---

# Zram Swap

RAM baskısını azaltmak için eklendi:

**/etc/config/zram-swap:**
```
config zram 'zram'
    option enabled '1'
    option size_mb '32'
    option comp_algorithm 'lzo'
```

**/etc/uci-defaults/03-zram** (ilk boot'ta otomatik enable):
```sh
#!/bin/sh
/etc/init.d/zram-swap enable
exit 0
```

> İlk build'de paket kuruluydu ama servis/config eksikti (`/etc/init.d/zram-swap` yoktu, `zramctl` çalışmıyordu). Bu iki dosya eksikliği gideriyor.

Doğrulama (yeni build sonrası):
```sh
zramctl
cat /proc/swaps
```

---

# DNS Güvenliği ve Hagezi

## Hagezi — Light Liste

RAM tasarrufu için **Light** listesine geçildi (önceki `pro.mini`'den daha küçük):

```text
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/light.txt
```

Liste `/tmp/hagezi_multi.conf`'a indirilir, `/etc/dnsmasq.d/hagezi_multi.conf` symlink'i üzerinden dnsmasq tarafından okunur.

### Hagezi Boot Akışı

```text
hagezi_init (START=5)
        ↓
/tmp/hagezi_multi.conf oluşturulur (boş, symlink hedefi olarak)
        ↓
hagezi_multi.conf symlink oluşturulur
        ↓
dnsmasq başlar
        ↓
rc.local çalışır
        ↓
internet beklenir (max 60sn)
        ↓
hagezi-guncelle çalışır
```

> `hagezi_init` dnsmasq'tan önce çalışmalı (START=5), symlink oluşturma mantığı `rc.local`'a taşınmamalı — aksi halde dnsmasq boot'ta "bad option" hatasıyla çöker.

---

# DNS Filtreleri (banned.conf)

Statik + kategori bazlı liste:

- Windows/Microsoft telemetri
- Google Analytics / Firebase / Crashlytics
- **YouTube/Google reklam sunucuları** (googlevideo.com'a dokunulmuyor — video ve reklam aynı stream'den geldiği için DNS ile ayrılamaz, sadece banner/companion-ad sunucuları bloklanıyor: doubleclick.net, googlesyndication.com, adservice.google.com vb.)
- Adjust mobil tracking
- USOM tehdit listesi (aylık güncellenir)
- Türkiye'ye özel phishing/zararlı domainler

> **2026 itibarıyla doğrulandı:** YouTube app içi video-arası (mid-roll) reklamlar server-side insertion nedeniyle DNS seviyesinde engellenemiyor — reklam ve video verisi aynı `googlevideo.com` bağlantısından geliyor. Mevcut liste, DNS seviyesinde ulaşılabilecek pratik tavan. Tam reklamsız deneyim için istemci tarafı (ReVanced) gerekli.

| Liste            | Dosya                    | Güncelleme        |
| ----------------- | ------------------------ | ------------------ |
| Hagezi Light      | /tmp/hagezi_multi.conf   | Boot + periyodik   |
| USOM / Zararlı    | banned.conf              | Aylık              |
| Statik engelleme  | banned.conf              | Manuel             |
| Beyaz liste       | whitelist.conf           | Manuel (TT Mobil)  |

DNS upstream: **AdGuard DNS** (94.140.14.14 / 94.140.15.15)

---

# Boot Yapısı

| Sıra | Servis        | START | Görev                                |
| ---- | ------------- | ----: | -------------------------------------- |
| 1    | hagezi_init   |     5 | Hagezi symlink + boş dosya             |
| 2    | dnsmasq       |   20+ | DNS servisi                            |
| 3    | zram-swap     |  N/A  | uci-defaults ile ilk boot'ta enable    |
| 4    | rc.local      |    99 | İnternet bekleme + Hagezi güncelleme   |
| 5    | zapret        |    99 | nfqws + nftables + flowtable           |

---

# /etc/rc.local

```sh
#!/bin/sh
chmod +x /opt/zapret/nfqws

(
    for i in $(seq 1 12); do
        wget -qO- --timeout=5 http://1.1.1.1 >/dev/null 2>&1 && break
        sleep 5
    done
    /usr/bin/hagezi-guncelle
) &

exit 0
```

İnternet maksimum 60 saniye kontrol edilir, bağlantı geldiğinde Hagezi güncellemesi başlar.

---

# Cron

```cron
# Pazar 04:00 - Haftalik reboot
0 4 * * 0 /bin/sleep 70 && /sbin/reboot

# Her 3 gunde bir 04:41 - Zapret fake dosyalari (bol-van/zapret upstream'den)
41 4 */3 * * /opt/zapret/update-fake.sh >/dev/null 2>&1

# Her ayin 1'i 04:00 - USOM / banned listesi
0 4 1 * * /usr/bin/banned-guncelle
```

---

# RAM Kullanımı

| Bileşen         |     RAM |
| ---------------- | ------: |
| Kernel + sistem   |  ~20 MB |
| Zapret / nfqws    | ~800 KB |
| Dnsmasq           | ~2-3 MB |
| Hagezi (Light)    | ~1 MB   |
| LuCI              | ~2-3 MB |

Firmware flash sonrası overlay kullanımı **~89% → ~22-34%**'e düştü, RAM kullanımı kabaca yarıya indi.

---

# Dosya Yapısı

```text
files/
├── etc/
│   ├── config/
│   │   ├── dhcp
│   │   ├── firewall
│   │   ├── network
│   │   ├── system
│   │   ├── wireless
│   │   └── zram-swap
│   │
│   ├── crontabs/
│   │   └── root
│   │
│   ├── dnsmasq.d/
│   │   ├── banned.conf
│   │   └── whitelist.conf
│   │
│   ├── init.d/
│   │   ├── hagezi_init
│   │   └── zapret
│   │
│   ├── uci-defaults/
│   │   ├── 01-zapret
│   │   ├── 02-hagezi
│   │   └── 03-zram
│   │
│   ├── rc.local
│   ├── sysctl.conf
│   └── zapret-bypass-ips.txt
│
├── opt/
│   └── zapret/
│       ├── nfqws
│       ├── files/
│       └── update-fake.sh
│
└── usr/
    └── bin/
        ├── hagezi-guncelle
        ├── banned-guncelle
        └── siteekle
```

---

# Kontrol Komutları

## Zapret
```sh
/etc/init.d/zapret status
pgrep -a nfqws
nft list ruleset | grep -i "flowtable\|queue"
cat /proc/net/netfilter/nfnetlink_queue
```

## RAM / Zram
```sh
free
zramctl
cat /proc/swaps
```

## TCP / qdisc
```sh
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_ecn
lsmod | grep fq_codel
```

## DNS
```sh
nslookup youtube.com 127.0.0.1
dnsmasq --test
```

## Hagezi
```sh
ls -lh /tmp/hagezi_multi.conf
wc -l /tmp/hagezi_multi.conf
/usr/bin/hagezi-guncelle
```

## Banned List
```sh
/usr/bin/banned-guncelle
```

## Fake Dosyaları
```sh
/opt/zapret/update-fake.sh
```

## Disk
```sh
df -h /overlay
```

---

# Firmware Build

## Local Build
```sh
./scripts/build.sh
```

## GitHub Actions
```text
.github/workflows/build.yml
```

Repo: `alperyamantr/openwrt-c50v6`

Build akışı: checkout → dependencies kur → OpenWrt clone → feeds update/install → `prepare.sh` (paket listesi uygula + `\r` temizle + explicit disable) → `files/` kopyala → `optimize.sh` (chmod +x) → `make download` → `make` → checksum → artifact upload.

> `prepare.sh` kritik kural: device-default paketleri (ppp, odhcp6c vb.) sadece `=y` satırını silmek yetmez, **`# CONFIG_PACKAGE_x is not set`** olarak açıkça belirtmek gerekir — full buildroot cihaz profilinden bu paketleri otomatik çekiyor.

---

# Bilinen Sınırlamalar

| Sınırlama                | Açıklama                              |
| -------------------------- | -------------------------------------- |
| CPU                       | 580 MHz Single-Core MIPS              |
| RAM                       | 64 MB DDR2                            |
| Flash                     | 8 MB SPI NOR (~1.1MB overlay)         |
| USB                       | Yok                                    |
| cpufreq                  | Yok                                    |
| BBR                      | Kernel'de yok, router için de önerilmez (endpoint'lerde faydalı) |
| SQM / CAKE                | kmod-sched-cake/kmod-ifb bu hedef için mevcut değil |
| nfnetlink_queue_maxlen    | Kernel'de mevcut değil                |
| YouTube app içi reklam    | Server-side insertion nedeniyle DNS ile engellenemiyor |

---

# Sorun Giderme

| Sorun                                   | Çözüm                                          |
| ------------------------------------------ | ------------------------------------------------ |
| dnsmasq boot'ta crash                     | hagezi_init START=5 kontrol et; banned.conf'ta BOM olmadığından emin ol |
| hagezi_multi.conf bulunamıyor            | Symlink'i kontrol et, /tmp reboot'ta sıfırlanır |
| Hagezi boş / format hatası               | /usr/bin/hagezi-guncelle çalıştır, dnsmasq formatında olduğunu doğrula |
| nfqws çalışmıyor                          | pgrep -a nfqws; procd restart bazen "Command failed: Not found" verip başlamayabilir, stop + start dene |
| Overlay doluyor                           | df -h /overlay; kullanılmayan binary'leri sil (ör. tpws) |
| TT Mobil/Aras Kargo açılmıyor             | zapret-bypass-ips.txt kontrol et, IP değişmiş olabilir |
| RAM düşük                                 | free ile kontrol et; zram-swap aktif mi bak    |
| Zapret çalışıyor ama trafik takılıyor     | NFQUEUE ve connbytes kontrol et, repeats/ttl değerlerini gözden geçir |
| PowerShell script Türkçe karakter bozuk   | Script BOM'suz UTF-8 kaydedilmiş olabilir, BOM'lu UTF-8 + ASCII path kullan |

---

## Proje Özeti

Bu yapılandırma **TP-Link Archer C50 v6'nın 580 MHz tek çekirdek MIPS CPU ve 64 MB RAM sınırları göz önünde bulundurularak** hazırlanmıştır.

Öncelikler:

1. Stabil bağlantı
2. Düşük CPU kullanımı
3. Minimum RAM tüketimi (zram-swap ile desteklenir)
4. Zapret DPI bypass + flow offload ile CPU tasarrufu
5. DNS seviyesinde zararlı/istenmeyen domain filtreleme
6. Reboot sonrası güvenilir servis başlatma

**Minimal sistem, maksimum stabilite.**
