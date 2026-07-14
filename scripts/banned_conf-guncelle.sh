#!/bin/bash

set -e

BANNED_FILE="${1:-files/etc/dnsmasq.d/banned.conf}"
USOM_PAGES=50
STATIC_MARKER="# ==USOM-BASLANGIC=="
END_MARKER="# ==USOM-BITIS=="
TEMP_FILE=$(mktemp)

echo "[*] USOM API Banned List Updater"
echo "[*] Hedef: $BANNED_FILE"

if [ ! -f "$BANNED_FILE" ]; then
    echo "[!] Uyarı: $BANNED_FILE bulunamadı, oluşturuluyor..."
    mkdir -p "$(dirname "$BANNED_FILE")"
    cat > "$BANNED_FILE" << 'EOF'
# ============================================================
#  STATIK ENGELLEMELER (MANUEL)
# ============================================================

# ==USOM-BASLANGIC==
# ==USOM-BITIS==
EOF
fi

# Statik bölümü al (marker'dan önceki kısım)
STATIC_PART=$(sed -n "1,/$STATIC_MARKER/p" "$BANNED_FILE" 2>/dev/null | sed '$d')

if [ -z "$STATIC_PART" ] || ! echo "$STATIC_PART" | grep -q "STATIK ENGELLEMELER"; then
    echo "[!] Statik bölüm bulunamadı, dosya yapısı bozuk!"
    exit 1
fi

echo "[*] USOM API'den veri çekiliyor ($USOM_PAGES sayfa)..."

> "$TEMP_FILE"

for page in $(seq 1 $USOM_PAGES); do
    RESPONSE=$(curl -s --max-time 15 "https://siberguvenlik.gov.tr/api/address/index?page=$page" 2>/dev/null || echo "")
    
    if [ -n "$RESPONSE" ] && echo "$RESPONSE" | grep -q '"models"'; then
        if command -v jq >/dev/null 2>&1; then
            PAGE_DOMAINS=$(echo "$RESPONSE" | jq -r '.models[] | select(.type == "domain") | .url' 2>/dev/null | \
                grep -oE '^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$' | \
                tr '[:upper:]' '[:lower:]' | sort -u)
        else
            PAGE_DOMAINS=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | \
                sed 's/"url":"//;s/"$//' | \
                grep -oE '^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z]{2,}$' | \
                tr '[:upper:]' '[:lower:]' | sort -u)
        fi
        
        if [ -n "$PAGE_DOMAINS" ]; then
            COUNT=$(echo "$PAGE_DOMAINS" | grep -c '^' || echo "0")
            echo "[+] Sayfa $page: $COUNT domain"
            echo "$PAGE_DOMAINS" >> "$TEMP_FILE"
        fi
    fi
done

echo "[*] Domainler filtreleniyor..."

# Benzersiz domainleri al, statik listede olanları çıkar
UNIQUE_DOMAINS=$(sort -u "$TEMP_FILE" | grep -v '^$')

FINAL_COUNT=0
{
    echo "$STATIC_PART"
    echo "$STATIC_MARKER"
    echo "# ============================================================"
    echo "#  USOM - ZARARLI DOMAIN LISTESI (OTOMATIK)"
    echo "#  Kaynak : USOM API"
    echo "#  Tarih  : $(date '+%Y-%m-%d %H:%M')"
    echo "#  Adet   : HESAPLANACAK"
    echo "# ============================================================"
    echo ""
    
    for domain in $UNIQUE_DOMAINS; do
        # Statik bölümde var mı kontrol et
        if ! echo "$STATIC_PART" | grep -q "/$domain/"; then
            echo "address=/$domain/0.0.0.0"
            FINAL_COUNT=$((FINAL_COUNT + 1))
        fi
    done
    
    echo ""
    echo "$END_MARKER"
} > "${BANNED_FILE}.tmp"

# Adet sayısını güncelle
sed -i "s/#  Adet   : HESAPLANACAK/#  Adet   : $FINAL_COUNT/" "${BANNED_FILE}.tmp"

# Dosyayı taşı
mv "${BANNED_FILE}.tmp" "$BANNED_FILE"
rm -f "$TEMP_FILE"

echo "[+] banned.conf güncellendi."
echo "[+] Toplam $FINAL_COUNT yeni USOM domaini eklendi."
echo "[+] Statik domainler korundu."