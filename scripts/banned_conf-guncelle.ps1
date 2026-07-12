# ============================================================
#  USOM API Banned List Updater (banned_conf-guncelle.ps1)
# ============================================================
# Bu betik, banned.conf içerisindeki statik engellemeleri (telemetri vb.) korur,
# USOM API'den en güncel zararlı domainleri çekerek listeyi otomatik günceller.
# GitOps uyumludur (dosyayı yerelde günceller, commit edip derleyebilirsiniz).

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

$bannedConfPath = Join-Path $PSScriptRoot "..\files\etc\dnsmasq.d\banned.conf"
$usomPagesToFetch = 50   # 50 sayfa × 20 kayıt = yaklaşık 1000 en güncel tehdit

if (-not (Test-Path $bannedConfPath)) {
    Write-Error "Hata: $bannedConfPath bulunamadı!"
    exit 1
}

Write-Host "[*] banned.conf dosyası okunuyor..." -ForegroundColor Cyan
$bannedContent = Get-Content -Path $bannedConfPath -Raw

# Statik bölümün sonunu belirleyen işaretçi
$usomMarker = "# ==USOM-BASLANGIC=="
$markerIndex = $bannedContent.IndexOf($usomMarker)

if ($markerIndex -lt 0) {
    Write-Error "Hata: '$usomMarker' işaretçisi bulunamadı!"
    exit 1
}

$staticPart = $bannedContent.Substring(0, $markerIndex + $usomMarker.Length)

# Benzersiz domainler
$allDomains = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

Write-Host "[*] USOM API üzerinden güncel tehdit verileri çekiliyor ($usomPagesToFetch sayfa)..." -ForegroundColor Cyan

for ($page = 1; $page -le $usomPagesToFetch; $page++) {

    $apiUrl = "https://siberguvenlik.gov.tr/api/address/index?page=$page"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 15

        if ($response -and $response.models) {

            $domains = $response.models |
                Where-Object {
                    $_.type -eq "domain" -and
                    $_.url -match "^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
                } |
                Select-Object -ExpandProperty url

            foreach ($dom in $domains) {
                $cleanDom = $dom.Trim().ToLowerInvariant()
                $null = $allDomains.Add($cleanDom)
            }

            Write-Host "[+] Sayfa $page : $($domains.Count) domain çekildi." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning ("[!] Sayfa {0} alınamadı: {1}" -f $page, $_.Exception.Message)
    }
}

Write-Host "[*] Toplam benzersiz USOM domaini: $($allDomains.Count)" -ForegroundColor Cyan

# Statik listede bulunanları tekrar ekleme
$finalDomains = foreach ($dom in ($allDomains | Sort-Object)) {
    if (-not $staticPart.Contains("/$dom/")) {
        $dom
    }
}

# Dnsmasq formatı
$formattedDomains = [System.Collections.Generic.List[string]]::new()

$formattedDomains.Add("")
$formattedDomains.Add("# ============================================================")
$formattedDomains.Add("#  USOM - ZARARLI DOMAIN LISTESI (OTOMATIK)")
$formattedDomains.Add("#  Kaynak : USOM API")
$formattedDomains.Add("#  Tarih  : $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$formattedDomains.Add("#  Adet   : $($finalDomains.Count)")
$formattedDomains.Add("# ============================================================")
$formattedDomains.Add("")

foreach ($dom in $finalDomains) {
    $formattedDomains.Add("address=/$dom/0.0.0.0")
}

$newContent =
    $staticPart +
    [Environment]::NewLine +
    ($formattedDomains -join [Environment]::NewLine) +
    [Environment]::NewLine

try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($bannedConfPath, $newContent, $utf8NoBom)

    Write-Host "[+] banned.conf başarıyla güncellendi." -ForegroundColor Green
    Write-Host "[+] Konum: $bannedConfPath" -ForegroundColor Green
}
catch {
    Write-Error ("Dosya yazılırken hata oluştu: {0}" -f $_.Exception.Message)
    exit 1
}