# ============================================================
#  USOM API Banned List Updater (banned_conf-guncelle.ps1)
# ============================================================
# Bu betik, banned.conf içerisindeki statik engellemeleri (telemetri vs.) korur,
# USOM API'den en güncel zararlı domainleri çekerek listeyi otomatik günceller.
# Git-Ops uyumludur (dosyayı yerelde günceller, commit edip derleyebilirsiniz).

$bannedConfPath = Join-Path $PSScriptRoot "..\files\etc\dnsmasq.d\banned.conf"
$usomPagesToFetch = 50  # 50 sayfa x 20 limit = En taze 1000 tehdit (64MB RAM sınırı için ideal)

if (-not (Test-Path $bannedConfPath)) {
    Write-Error "Hata: $bannedConfPath bulunamadı!"
    exit 1
}

Write-Host "[*] banned.conf dosyası okunuyor..." -ForegroundColor Cyan
$bannedContent = Get-Content -Path $bannedConfPath -Raw

# USOM başlangıç işaretçisini bul ve statik kısmı ayır
$usomMarker = "# ==USOM-BASLANGIC=="
$markerIndex = $bannedContent.IndexOf($usomMarker)

if ($markerIndex -lt 0) {
    Write-Error "Hata: Dosyada '$usomMarker' işareti bulunamadı!"
    exit 1
}

$staticPart = $bannedContent.Substring(0, $markerIndex + $usomMarker.Length)

# USOM API'den taze tehditleri çek
$allDomains = [System.Collections.Generic.List[string]]::new()

Write-Host "[*] USOM API üzerinden taze tehdit verileri çekiliyor ($($usomPagesToFetch) sayfa)..." -ForegroundColor Cyan
for ($page = 1; $page -le $usomPagesToFetch; $page++) {
    $apiUrl = "https://siberguvenlik.gov.tr/api/address/index?page=$page"
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 15
        if ($response -and $response.models) {
            # Sadece 'domain' tipinde ve geçerli biçimdeki url'leri çek
            $domains = $response.models | 
                       Where-Object { $_.type -eq "domain" -and $_.url -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" } | 
                       Select-Object -ExpandProperty url
            
            foreach ($dom in $domains) {
                # Küçük harfe çevir ve temizle
                $cleanDom = $dom.ToLower().Trim()
                if (-not $allDomains.Contains($cleanDom)) {
                    $allDomains.Add($cleanDom)
                }
            }
            Write-Host "[+] Sayfa $($page): $($domains.Count) adet domain çekildi." -ForegroundColor Green
        }
    } catch {
        Write-Warning "[!] Sayfa $page çekilirken bağlantı hatası oluştu: $_"
    }
}

Write-Host "[*] Toplam benzersiz USOM domain sayısı: $($allDomains.Count)" -ForegroundColor Cyan

# Sırala ve statik kısımda olmayanları ayıkla (Mükerrer ve çakışma önleme)
$finalDomains = [System.Collections.Generic.List[string]]::new()
foreach ($dom in ($allDomains | Sort-Object)) {
    if (-not $staticPart.Contains("/$dom/")) {
        $finalDomains.Add($dom)
    }
}

# Dnsmasq formatına çevir (address=/domain/0.0.0.0)
$formattedDomains = [System.Collections.Generic.List[string]]::new()
$formattedDomains.Add("")
$formattedDomains.Add("# ============================================================")
$formattedDomains.Add("#  USOM -- ZARARLI DOMAIN LISTESI (API OTOMATIK)")
$formattedDomains.Add("#  Kaynak: usom.gov.tr API | Tarih: $(Get-Date -Format 'yyyy-MM-dd HH:mm') | Adet: $($finalDomains.Count)")
$formattedDomains.Add("# ============================================================")
$formattedDomains.Add("")

foreach ($dom in $finalDomains) {
    $formattedDomains.Add("address=/$dom/0.0.0.0")
}

# Yeni içeriği birleştir ve dosyaya yaz
$newContent = $staticPart + [System.Environment]::NewLine + ($formattedDomains -join [System.Environment]::NewLine) + [System.Environment]::NewLine

try {
    # UTF-8 No BOM olarak kaydet
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($bannedConfPath, $newContent, $utf8NoBom)
    Write-Host "[+] banned.conf başarıyla güncellendi!" -ForegroundColor Green
    Write-Host "[+] Konum: $bannedConfPath" -ForegroundColor Green
} catch {
    Write-Error "[!] Dosya yazılırken hata oluştu: $_"
}
