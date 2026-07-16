# Archer C50 v6 - Ayarlar Dokümantasyonu

## Sistem Bilgisi

| Parametre | Değer |
|-----------|-------|
| Model | TP-Link Archer C50 v6 |
| OpenWrt | 25.12.5 r33051-f5dae5ece4 |
| Kernel | 6.12.94 mipsel_24kc |
| RAM | 64MB DDR2 |
| Flash | 8MB SPI NOR |
| CPU | 580MHz Single Core MIPS |
| USB | Yok (çoğu revizyon) |
| cpufreq | Sabit 580MHz, governor yok |

## Zapret DPI Bypass

| Parametre | Değer | Açıklama |
|-----------|-------|----------|
| TCP 443 | `fake,split` | TLS handshake desync |
| TCP 80 | `fake,split` | HTTP desync |
| UDP 443 (QUIC) | `fake` | HTTP3 desync |
| UDP Discord | `fake` | Voice chat bypass |
| UDP STUN | `fake` | NAT traversal |

### Optimizasyonlar

| Parametre | Değer | Etki |
|-----------|-------|------|
| TTL TCP | `4` | Fake DPI'ya ulaşır, sunucuya gitmez |
| TTL QUIC | `2` | Fake sadece DPI'ya ulaşır |
| Connbytes | `1-4` | Sadece ilk 4 paket (CPU tasarrufu) |
| Cutoff | `d4/n2` | Handshake sonrası desync'i bırakır |
| Respawn | `3600 5 5` | Crash loop koruması |
| OOM Score | `-1000` | RAM dolsa bile zapret ölmez |
| Log | `kapalı` | Flash/RAM tasarrufu |

## Sistem Optimizasyonları

```bash
# /etc/sysctl.conf
net.ipv4.tcp_congestion_control=cubic
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_ecn=0
net.netfilter.nf_conntrack_max=8192
net.core.rmem_max=262144
net.core.wmem_max=262144
Not: nf_conntrack_max=8192 init.d/zapret tarafından da set edilir. Tutarlılık için tek kaynak.
DNS Güvenliği
Table
Bileşen	Dosya	Boyut	Güncelleme
Hagezi light	hagezi_multi.conf (symlink → /tmp)	~1.17MB	Boot + her 3 gün
USOM zararlı	banned.conf	~42KB	Her 3 gün
Statik engelleme	banned.conf içinde	~37KB	Manuel (siteekle)
Beyaz liste	whitelist.conf	340B	Manuel
Boot Sırası (DNS)
Table
Sıra	Script	START	Görev
1	init.d/hagezi_init	5	Symlink + boş dosya oluştur
2	init.d/dnsmasq	20+	Config parse, başlat
3	rc.local	99	Internet bekle, hagezi-guncelle
4	init.d/zapret	99	nfqws başlat
Önemli: hagezi_init dnsmasq'dan ÖNCE çalışır. Symlink olmadan dnsmasq crash loop'a girer.
Cron Zamanlaması
Table
Zaman	Görev
0 4 * * 0	Pazar 04:00 - Reboot (70sn gecikme)
41 4 */3 * *	Her 3 gün 04:41 - Fake paket güncelleme
0 4 1 * *	Aylık - banned-guncelle (USOM)
RAM Kullanımı (C50 v6 - 64MB)
Table
Bileşen	Tahmini RAM
Kernel + sistem	~20MB
Zapret (nfqws)	~800KB
Dnsmasq + cache	~2-3MB
Hagezi blocklist (/tmp)	~1.17MB
LuCI (uhttpd)	~2-3MB
Boş available	~10-14MB
Dosya Yapısı
plain
files/
├── etc/
│   ├── config/              # network, wireless, firewall, dhcp, system
│   ├── crontabs/root        # Cron zamanlaması
│   ├── dnsmasq.d/
│   │   ├── banned.conf      # USOM + statik engelleme
│   │   └── whitelist.conf   # Beyaz liste
│   ├── init.d/
│   │   ├── hagezi_init      # Boot'ta symlink oluştur (START=5)
│   │   └── zapret           # nfqws başlat (START=99)
│   ├── rc.local             # Boot: nfqws chmod, internet bekle, hagezi güncelle
│   ├── sysctl.conf          # Kernel ayarları
│   └── zapret-bypass-ips.txt # IP bypass listesi
├── opt/zapret/              # nfqws, fake dosyalar
└── usr/bin/
    ├── hagezi-guncelle      # Hagezi blocklist indir, dnsmasq restart
    ├── banned-guncelle      # USOM listesi indir, dnsmasq reload
    └── siteekle             # Manuel domain engelleme
Komutlar
bash
# Zapret durum kontrolü
/etc/init.d/zapret status
ps | grep nfqws
cat /proc/net/netfilter/nfnetlink_queue

# RAM kontrolü
free

# DNS test
nslookup youtube.com 127.0.0.1

# Domain engelleme
siteekle domain.com

# Manuel güncelleme
/usr/bin/hagezi-guncelle
/usr/bin/banned-guncelle
/opt/zapret/update-fake.sh
Firmware Build
bash
# Local build
./scripts/build.sh

# GitHub Actions
# .github/workflows/build.yml
Bilinen Sınırlamalar
Table
Sınırlama	Açıklama
CPU	580MHz Single Core MIPS
RAM	64MB (DDR2)
Flash	8MB (SPI NOR)
USB	Yok (çoğu revizyon)
cpufreq	Sabit 580MHz, governor yok
Westwood/BBR	Kernel'de yok, sadece cubic/reno
Sorun Giderme
Table
Sorun	Çözüm
dnsmasq boot'ta crash	hagezi_init enable edildi mi kontrol et
hagezi.conf ghost file	Sil, hagezi_multi.conf symlink kullan
nfnetlink_queue_maxlen yok	Normal, kernel desteklemiyor, 65531 default
queue-len ekleme	Gereksiz, 65531 zaten yeterli
