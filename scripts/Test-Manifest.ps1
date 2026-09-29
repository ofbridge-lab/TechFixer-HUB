<#
.SYNOPSIS
  Valide versions.json avant publication (TechFixer-HUB).

.DESCRIPTION
  Bloquant (ERREUR) :
    - JSON invalide (analyse stricte : virgule en trop, guillemet manquant...)
    - champs racine manquants (schema, updated, meta.categories, tools)
    - outil sans lien de téléchargement (dl ou url)
    - URL invalide ou provisoire (example.invalid, example.com, localhost),
      sauf pour les outils listés dans -AllowPlaceholder (CyclObs par défaut)
    - sha256 mal formé (64 caractères hexadécimaux attendus)
    - catégorie qui référence un outil absent de "tools"
    - dlType inconnu
  Non bloquant (AVERTISSEMENT) :
    - lien en http:// au lieu de https://
    - outil présent dans "tools" mais rangé dans aucune catégorie
    - outil sans "latest"

  Utilisable en local avant un commit :
    pwsh ./scripts/Test-Manifest.ps1
  Code retour : 0 = OK, 1 = au moins une erreur.
#>
[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\versions.json'),

    # Outils autorisés à garder une URL provisoire (signalée en avertissement, pas en erreur).
    # CyclObs : pas encore distribué publiquement — retirer l'exception quand le vrai lien existe.
    [string[]]$AllowPlaceholder = @('CyclObs')
)

$ErrorActionPreference = 'Stop'
$errors   = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$inCI     = [bool]$env:GITHUB_ACTIONS

function Add-Err ([string]$msg) { $errors.Add($msg) }
function Add-Warn([string]$msg) { $warnings.Add($msg) }

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    Write-Host "ERREUR : fichier introuvable : $ManifestPath" -ForegroundColor Red
    exit 1
}
$text = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8

# ── 1. Syntaxe JSON stricte ────────────────────────────────
# System.Text.Json (PowerShell 7) refuse virgules en trop et commentaires,
# contrairement à ConvertFrom-Json qui peut être plus tolérant.
$stj = 'System.Text.Json.JsonDocument' -as [type]
if ($stj) {
    try {
        $doc = [System.Text.Json.JsonDocument]::Parse($text)
        $doc.Dispose()
    } catch {
        $inner = if ($_.Exception.InnerException) { $_.Exception.InnerException.Message } else { $_.Exception.Message }
        Write-Host "ERREUR : JSON invalide -> $inner" -ForegroundColor Red
        if ($inCI) { Write-Host "::error file=versions.json::JSON invalide : $inner" }
        exit 1
    }
}
try {
    $m = $text | ConvertFrom-Json
} catch {
    Write-Host "ERREUR : JSON invalide -> $($_.Exception.Message)" -ForegroundColor Red
    if ($inCI) { Write-Host "::error file=versions.json::JSON invalide" }
    exit 1
}

# ── 2. Structure racine ────────────────────────────────────
foreach ($k in 'schema', 'updated', 'meta', 'tools') {
    if (-not $m.PSObject.Properties[$k]) { Add-Err "champ racine manquant : '$k'" }
}
if ($m.updated -and $m.updated -notmatch '^\d{4}-\d{2}-\d{2}$') {
    Add-Err "'updated' doit être au format AAAA-MM-JJ (valeur : '$($m.updated)')"
}
if ($m.meta -and -not $m.meta.categories) { Add-Err "champ manquant : 'meta.categories'" }

# ── 3. Outils ──────────────────────────────────────────────
$validDlTypes = 'zip', 'exe', '7z', 'msi'
$placeholder  = '(?i)://([^/]*\.)?(example\.(invalid|com|org|net)|localhost|127\.0\.0\.1)(/|:|$)'
$toolNames    = @()

if ($m.tools) {
    $toolNames = @($m.tools.PSObject.Properties.Name)
    foreach ($name in $toolNames) {
        $t = $m.tools.$name

        $links = @('dl', 'url') | Where-Object { $t.PSObject.Properties[$_] -and $t.$_ }
        if ($links.Count -eq 0) { Add-Err "[$name] aucun lien de téléchargement (ni 'dl' ni 'url')" }

        foreach ($f in $links) {
            $u = [string]$t.$f
            $uri = $null
            if (-not [System.Uri]::TryCreate($u, [System.UriKind]::Absolute, [ref]$uri) -or
                $uri.Scheme -notin 'http', 'https') {
                Add-Err "[$name] '$f' n'est pas une URL valide : $u"
            } elseif ($u -match $placeholder) {
                if ($AllowPlaceholder -ccontains $name) {
                    Add-Warn "[$name] '$f' est une URL provisoire (exception autorisée) : $u"
                } else {
                    Add-Err "[$name] '$f' est une URL provisoire : $u"
                }
            } elseif ($uri.Scheme -eq 'http') {
                Add-Warn "[$name] '$f' en http:// (non chiffré) : $u"
            }
        }

        if ($t.PSObject.Properties['sha256'] -and $t.sha256 -notmatch '^[0-9a-fA-F]{64}$') {
            Add-Err "[$name] sha256 mal formé (64 caractères hexadécimaux attendus)"
        }
        if ($t.PSObject.Properties['dlType'] -and $t.dlType -notin $validDlTypes) {
            Add-Err "[$name] dlType inconnu : '$($t.dlType)' (attendu : $($validDlTypes -join ', '))"
        }
        if (-not $t.latest) { Add-Warn "[$name] pas de champ 'latest'" }
    }
}

# ── 4. Catégories <-> outils ───────────────────────────────
if ($m.meta.categories) {
    $categorized = @()
    foreach ($cat in $m.meta.categories.PSObject.Properties) {
        foreach ($ref in @($cat.Value)) {
            $categorized += $ref
            # Comparaison sensible à la casse : le Hub cherche la clé exacte
            if ($toolNames -cnotcontains $ref) {
                Add-Err "catégorie '$($cat.Name)' référence un outil inexistant : '$ref'"
            }
        }
    }
    foreach ($name in $toolNames) {
        if ($categorized -cnotcontains $name) { Add-Warn "[$name] n'apparaît dans aucune catégorie" }
    }
}

# ── Résultat ───────────────────────────────────────────────
foreach ($w in $warnings) {
    Write-Host "AVERTISSEMENT : $w" -ForegroundColor Yellow
    if ($inCI) { Write-Host "::warning file=versions.json::$w" }
}
foreach ($e in $errors) {
    Write-Host "ERREUR : $e" -ForegroundColor Red
    if ($inCI) { Write-Host "::error file=versions.json::$e" }
}

if ($errors.Count -gt 0) {
    Write-Host "`nManifeste REFUSÉ : $($errors.Count) erreur(s), $($warnings.Count) avertissement(s)." -ForegroundColor Red
    exit 1
}
Write-Host "`nManifeste OK : $($toolNames.Count) outils, $($warnings.Count) avertissement(s)." -ForegroundColor Green
exit 0
