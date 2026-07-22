<#
    Update-Manifest.ps1
    -------------------
    Robot de mise a jour du manifeste versions.json du TechFixer Hub.
    Pilote par les donnees : chaque outil ayant un bloc "resolve" est resolu automatiquement.
    Ajouter un outil = ajouter un bloc "resolve" (AUCUN changement de code).

    Types de resolveur supportes :
      - github     : liste TOUTES les releases, ignore prerelease/draft, prend le plus haut numero
                     (repo, assetRx, [versionRx], [includePrerelease])
      - redirect   : HEAD une URL "toujours-derniere", lit la version dans le nom du fichier final
                     (url, versionRx)  -> dl reste l'URL stable
      - scrape     : GET une page, regex version (+ lien optionnel)
                     (url, versionRx, [linkRx])
      - majorgeeks : version depuis le <title> de la page de detail ; dl = page getmirror
                     (detail, mirror). Le telechargement se fait en 2 temps cote hub (dlVia=majorgeeks).

    Compatible Windows PowerShell 5.1 ET PowerShell 7 (utilise curl pour les redirections).
    Sur GitHub Actions : renseigner $env:GITHUB_TOKEN pour eviter le rate-limit de l'API.

    Usage : ./scripts/Update-Manifest.ps1 -ManifestPath versions.json
#>
[CmdletBinding()]
param(
    [string]$ManifestPath = 'versions.json'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$UA = 'TechFixer-Manifest-Bot/1.0'

# --- version -> cle comparable [version] (jusqu'a 4 segments) ------------------------------
function Get-VersionKey([string]$v) {
    $nums = [regex]::Matches($v, '\d+') | ForEach-Object { [int]$_.Value }
    if (-not $nums) { return [version]'0.0' }
    $nums = @($nums)
    while ($nums.Count -lt 2) { $nums += 0 }
    if ($nums.Count -gt 4) { $nums = $nums[0..3] }
    return [version]($nums -join '.')
}

# --- extrait la version depuis un texte via regex (concatene les groupes captures) ---------
function Extract-Version([string]$text, [string]$rx) {
    if ([string]::IsNullOrWhiteSpace($rx)) { $rx = '\d+(?:\.\d+)+' }
    $m = [regex]::Match($text, $rx)
    if (-not $m.Success) { return $null }
    $groups = @()
    for ($i = 1; $i -lt $m.Groups.Count; $i++) { if ($m.Groups[$i].Success) { $groups += $m.Groups[$i].Value } }
    if ($groups.Count -gt 0) { return ($groups -join '.') }
    return $m.Value
}

# --- HEAD via curl : renvoie @{ Final=<url finale>; FileName=<nom> } ------------------------
function Resolve-Redirect([string]$url) {
    $headers = & curl.exe -sIL -A $UA --connect-timeout 15 --max-time 40 $url 2>$null
    $final = $url; $cd = $null
    foreach ($line in $headers) {
        if ($line -match '^[Ll]ocation:\s*(.+?)\s*$') { $final = $Matches[1] }
        if ($line -match '^[Cc]ontent-[Dd]isposition:.*filename\*?=(?:UTF-8'''')?"?([^";]+)"?') { $cd = $Matches[1] }
    }
    $fname = if ($cd) { $cd.Trim('"') } else { [IO.Path]::GetFileName(($final -split '\?')[0]) }
    return @{ Final = $final; FileName = $fname }
}

function New-Headers {
    $h = @{ 'User-Agent' = $UA; 'Accept' = 'application/vnd.github+json' }
    if ($env:GITHUB_TOKEN) { $h['Authorization'] = "Bearer $($env:GITHUB_TOKEN)" }
    return $h
}

# ------------------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "Manifeste introuvable : $ManifestPath" }
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$changed = $false
$report = New-Object System.Collections.Generic.List[object]

foreach ($prop in $manifest.tools.PSObject.Properties) {
    $id = $prop.Name
    $tool = $prop.Value
    $r = $tool.resolve
    if (-not $r) { continue }

    $newLatest = $null; $newDl = $null; $newDlVia = $null; $newSha = $null; $err = $null
    try {
        switch ($r.type) {
            'github' {
                $rels = Invoke-RestMethod -Uri "https://api.github.com/repos/$($r.repo)/releases?per_page=30" -Headers (New-Headers) -TimeoutSec 40
                $bestKey = [version]'0.0'; $bestAsset = $null
                foreach ($rel in $rels) {
                    if ($rel.draft) { continue }
                    if ($rel.prerelease -and -not $r.includePrerelease) { continue }
                    $src = if ($rel.tag_name) { [string]$rel.tag_name } else { [string]$rel.name }
                    $ver = Extract-Version $src $r.versionRx
                    if (-not $ver) { $ver = Extract-Version ([string]$rel.name) $r.versionRx }
                    if (-not $ver) { continue }
                    $asset = $rel.assets | Where-Object { $_.name -match $r.assetRx } | Select-Object -First 1
                    if (-not $asset) { continue }
                    $key = Get-VersionKey $ver
                    if ($key -gt $bestKey) { $bestKey = $key; $newLatest = $ver; $newDl = $asset.browser_download_url; $bestAsset = $asset }
                }
                if (-not $newLatest) { throw 'aucune release exploitable (tag/asset non trouve)' }
                # sha256 de l'asset (integrite : le hub verifie ce hash au telechargement)
                if ($bestAsset -and $bestAsset.digest -and ([string]$bestAsset.digest) -match '^sha256:([0-9a-fA-F]{64})$') { $newSha = $Matches[1] }
            }
            'redirect' {
                $res = Resolve-Redirect $r.url
                $newLatest = Extract-Version $res.FileName $r.versionRx
                if (-not $newLatest) { throw "version illisible dans '$($res.FileName)'" }
                $newDl = $r.url   # l'URL stable reste le lien de telechargement
            }
            'scrape' {
                $html = Invoke-WebRequest -Uri $r.url -Headers (New-Headers) -UseBasicParsing -TimeoutSec 40
                $newLatest = Extract-Version ([string]$html.Content) $r.versionRx
                if (-not $newLatest) { throw 'version non trouvee sur la page' }
                if ($r.linkRx) {
                    $lm = [regex]::Match([string]$html.Content, $r.linkRx)
                    if ($lm.Success) { $newDl = $lm.Value }
                }
            }
            'majorgeeks' {
                # Version : lue dans le <title> de la page de detail ("Download <Nom> <version>  - MajorGeeks")
                $page = Invoke-WebRequest -Uri $r.detail -Headers (New-Headers) -UseBasicParsing -TimeoutSec 40
                $tm = [regex]::Match([string]$page.Content, '<title>(.*?)</title>', ([Text.RegularExpressions.RegexOptions]'IgnoreCase, Singleline'))
                $title = if ($tm.Success) { $tm.Groups[1].Value } else { '' }
                $newLatest = Extract-Version $title $r.versionRx
                if (-not $newLatest) { throw "version illisible dans le titre : '$title'" }
                # Si "mirror" fourni : telechargement via MajorGeeks (2 temps cote hub, dlVia=majorgeeks).
                # Sinon : mode "version seule" (on garde le dl direct deja present dans le manifeste).
                if ($r.mirror) { $newDl = $r.mirror; $newDlVia = 'majorgeeks' }
            }
            default { throw "type de resolveur inconnu : $($r.type)" }
        }
    } catch { $err = $_.Exception.Message }

    if ($err) {
        $report.Add([pscustomobject]@{ id=$id; type=$r.type; ancien=$tool.latest; nouveau='ERREUR'; note=$err })
        continue
    }

    # Applique si change
    $oldLatest = [string]$tool.latest
    $oldDl = if ($tool.PSObject.Properties.Name -contains 'dl') { [string]$tool.dl } else { $null }
    $note = 'inchange'
    if ($newLatest -and $newLatest -ne $oldLatest) {
        $tool.latest = $newLatest; $changed = $true; $note = "MAJ $oldLatest -> $newLatest"
    }
    if ($newDl -and $newDl -ne $oldDl) {
        if ($tool.PSObject.Properties.Name -contains 'dl') { $tool.dl = $newDl }
        else { $tool | Add-Member -NotePropertyName dl -NotePropertyValue $newDl -Force }
        # dlType deduit si absent (sauf majorgeeks : le vrai fichier est resolu cote hub)
        if (-not $newDlVia -and -not ($tool.PSObject.Properties.Name -contains 'dlType')) {
            $dt = if ($newDl -match '\.zip(\?|$)') { 'zip' } elseif ($newDl -match '\.exe(\?|$)') { 'exe' } else { 'zip' }
            $tool | Add-Member -NotePropertyName dlType -NotePropertyValue $dt -Force
        }
        $changed = $true
        if ($note -eq 'inchange') { $note = 'dl mis a jour' }
    }
    if ($newDlVia) {
        if ($tool.PSObject.Properties.Name -contains 'dlVia') {
            if ($tool.dlVia -ne $newDlVia) { $tool.dlVia = $newDlVia; $changed = $true }
        } else { $tool | Add-Member -NotePropertyName dlVia -NotePropertyValue $newDlVia -Force; $changed = $true }
    }
    if ($newSha) {
        if ($tool.PSObject.Properties.Name -contains 'sha256') {
            if ($tool.sha256 -ne $newSha) { $tool.sha256 = $newSha; $changed = $true }
        } else { $tool | Add-Member -NotePropertyName sha256 -NotePropertyValue $newSha -Force; $changed = $true }
    }
    $report.Add([pscustomobject]@{ id=$id; type=$r.type; ancien=$oldLatest; nouveau=$newLatest; note=$note })
}

Write-Host "`n=== Resolution du manifeste ==="
$report | Format-Table id, type, ancien, nouveau, note -AutoSize | Out-String -Width 4096 | Write-Host

if ($changed) {
    $manifest.updated = (Get-Date -Format 'yyyy-MM-dd')
    $json = $manifest | ConvertTo-Json -Depth 12
    Set-Content -LiteralPath $ManifestPath -Value $json -Encoding UTF8
    Write-Host "versions.json mis a jour."
    if ($env:GITHUB_OUTPUT) { "changed=true" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
} else {
    Write-Host "Aucun changement."
    if ($env:GITHUB_OUTPUT) { "changed=false" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
}
