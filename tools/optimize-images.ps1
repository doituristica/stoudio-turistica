# Re-encodes downloaded Airtable images for the web and generates card thumbnails,
# then patches site\data\activities.json and writes the lightweight list index.
#
#   .\tools\optimize-images.ps1
#   .\tools\optimize-images.ps1 -Force     re-run over already optimized files
#
# Uses only System.Drawing (ships with Windows) - no ImageMagick, no Node.
# Originals are kept in backup\img-orig\ (OUTSIDE site\, so they are never published)
# the first time this runs, which also makes -Force re-runs lossless.
param(
  [int]$MaxWidth   = 1400,
  [int]$ThumbWidth = 640,
  [int]$Quality    = 80,
  [int]$ThumbQuality = 72,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root    = Split-Path $PSScriptRoot -Parent
$site    = Join-Path $root 'site'
$imgRoot = Join-Path $site 'assets\img'
$backup  = Join-Path $root 'backup\img-orig'
$jsonPath = Join-Path $site 'data\activities.json'

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
             Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Jpeg([System.Drawing.Bitmap]$bmp, [string]$path, [int]$q) {
  $p = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
      [System.Drawing.Imaging.Encoder]::Quality, [int64]$q)
  $bmp.Save($path, $jpegCodec, $p)
  $p.Dispose()
}

function Resize-To([System.Drawing.Image]$src, [int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $bmp.SetResolution(72, 72)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CompositingQuality = 'HighQuality'
  $g.InterpolationMode  = 'HighQualityBicubic'
  $g.SmoothingMode      = 'HighQuality'
  $g.PixelOffsetMode    = 'HighQuality'
  # white matte so transparent PNGs do not turn black when saved as JPEG
  $g.Clear([System.Drawing.Color]::White)
  $g.DrawImage($src, 0, 0, $w, $h)
  $g.Dispose()
  return $bmp
}

$before = 0; $after = 0; $done = 0; $skipped = 0; $videos = 0
$map = @{}   # original src -> @{ src; thumb; w; h }

$files = Get-ChildItem $imgRoot -Recurse -File | Where-Object { $_.Name -notlike '*-t.jpg' }

foreach ($f in $files) {
  $rel = $f.FullName.Substring($imgRoot.Length).TrimStart('\')
  $relUrl = 'assets/img/' + ($rel -replace '\\', '/')
  $before += $f.Length

  if ($f.Extension -in '.mp4', '.mov', '.webm') {
    $videos++
    $after += $f.Length
    continue
  }

  $dir      = $f.DirectoryName
  $stem     = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
  $outPath  = Join-Path $dir "$stem.jpg"
  $thumbPath = Join-Path $dir "$stem-t.jpg"

  # Keep a pristine copy the first time we touch a file. Match on the stem, not the
  # full name: a .png source is written out as .jpg, so on a second run the backup
  # is 01.png while the working file is 01.jpg - looking up 01.jpg would miss it and
  # re-compress an already compressed image.
  $bakDir  = Join-Path $backup (Split-Path $rel -Parent)
  $bakPath = $null
  if (Test-Path $bakDir) {
    $hit = Get-ChildItem $bakDir -File | Where-Object {
      [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $stem
    } | Select-Object -First 1
    if ($hit) { $bakPath = $hit.FullName }
  }

  if (-not $bakPath) {
    $bakPath = Join-Path $backup $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $bakPath -Parent) | Out-Null
    Copy-Item $f.FullName $bakPath
  } elseif (-not $Force) {
    # already optimized in a previous run
    if (Test-Path $thumbPath) {
      $skipped++
      $img = [System.Drawing.Image]::FromFile($outPath)
      $map[$relUrl] = @{ src = ('assets/img/' + (($rel -replace '\\','/') -replace '\.[^.]+$', '.jpg'))
                         thumb = ('assets/img/' + ((($rel -replace '\\','/') -replace '\.[^.]+$', '') + '-t.jpg'))
                         w = $img.Width; h = $img.Height }
      $img.Dispose()
      $after += (Get-Item $outPath).Length + (Get-Item $thumbPath).Length
      continue
    }
  }

  $src = [System.Drawing.Image]::FromFile($bakPath)
  try {
    $w = $src.Width; $h = $src.Height

    $scale = [Math]::Min(1.0, $MaxWidth / [double]([Math]::Max($w, $h)))
    $fw = [int][Math]::Round($w * $scale); $fh = [int][Math]::Round($h * $scale)
    $full = Resize-To $src $fw $fh
    Save-Jpeg $full $outPath $Quality
    $full.Dispose()

    $tscale = [Math]::Min(1.0, $ThumbWidth / [double]([Math]::Max($w, $h)))
    $tw = [int][Math]::Round($w * $tscale); $th = [int][Math]::Round($h * $tscale)
    $thumb = Resize-To $src $tw $th
    Save-Jpeg $thumb $thumbPath $ThumbQuality
    $thumb.Dispose()

    $map[$relUrl] = @{
      src   = 'assets/img/' + (($rel -replace '\\','/') -replace '\.[^.]+$', '.jpg')
      thumb = 'assets/img/' + ((($rel -replace '\\','/') -replace '\.[^.]+$', '') + '-t.jpg')
      w = $fw; h = $fh
    }
    $done++
    $after += (Get-Item $outPath).Length + (Get-Item $thumbPath).Length
  } finally {
    $src.Dispose()
  }

  # a .png source becomes .jpg - drop the leftover
  if ($f.Extension -ne '.jpg' -and (Test-Path $f.FullName) -and $f.FullName -ne $outPath) {
    Remove-Item $f.FullName -Force
  }
}

# --- hero backgrounds ------------------------------------------------------
# These load on every page, so they get the same treatment. Logos stay untouched
# (they are PNGs with transparency).
foreach ($hero in (Get-ChildItem (Join-Path $site 'assets\brand') -File -Filter 'hero-*.jpg')) {
  $bak = Join-Path $backup ('brand\' + $hero.Name)
  if (-not (Test-Path $bak)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $bak -Parent) | Out-Null
    Copy-Item $hero.FullName $bak
  } elseif (-not $Force) { continue }

  $src = [System.Drawing.Image]::FromFile($bak)
  try {
    $s = [Math]::Min(1.0, 1920 / [double]$src.Width)
    $bmp = Resize-To $src ([int][Math]::Round($src.Width * $s)) ([int][Math]::Round($src.Height * $s))
    Save-Jpeg $bmp $hero.FullName 74
    $bmp.Dispose()
  } finally { $src.Dispose() }
}

# --- patch activities.json -------------------------------------------------
$acts = Get-Content $jsonPath -Raw -Encoding utf8 | ConvertFrom-Json
foreach ($a in $acts) {
  $newImages = @()
  foreach ($im in @($a.images)) {
    if ($im.kind -eq 'video') { $newImages += $im; continue }
    $m = $map[[string]$im.src]
    if ($m) {
      $newImages += [ordered]@{ src = $m.src; thumb = $m.thumb; kind = 'image'; w = $m.w; h = $m.h }
    } else {
      $newImages += $im
    }
  }
  $a.images = $newImages
}

$json = $acts | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($jsonPath, $json, (New-Object System.Text.UTF8Encoding($false)))

# --- lightweight index for the list pages (no long body text) --------------
$index = foreach ($a in $acts) {
  [ordered]@{
    id = $a.id; slug = $a.slug; title = $a.title; type = $a.type
    category = $a.category; catLabel = $a.catLabel; catLabelEn = $a.catLabelEn
    start = $a.start; finish = $a.finish
    lead = $a.lead; leadEn = $a.leadEn
    organizers = @($a.organizers)
    # No @() here - it would serialize as a one-element array instead of an object.
    cover = ($a.images | Where-Object { $_.kind -ne 'video' } | Select-Object -First 1)
  }
}
$idxPath = Join-Path $site 'data\activities-index.json'
[System.IO.File]::WriteAllText($idxPath, ($index | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))

# Compare against the pristine backup, not against whatever is currently on disk -
# on a re-run the working files are already optimized and the delta would read as 0.
# Videos are excluded from both sides: they are passed through untouched.
function Sum-Bytes($items) { ($items | Measure-Object Length -Sum).Sum }

$origBytes = Sum-Bytes (Get-ChildItem $backup -Recurse -File -ErrorAction SilentlyContinue)
$newBytes  = Sum-Bytes (Get-ChildItem (Join-Path $site 'assets') -Recurse -File |
                        Where-Object { $_.Extension -notin '.mp4', '.mov', '.webm', '.woff2' })
$videoBytes = Sum-Bytes (Get-ChildItem (Join-Path $site 'assets') -Recurse -File |
                         Where-Object { $_.Extension -in '.mp4', '.mov', '.webm' })

"OK  optimized: $done  reused: $skipped"
if ($origBytes) {
  "    images {0:N1} MB -> {1:N1} MB  ({2:N0}% smaller)" -f `
    ($origBytes/1MB), ($newBytes/1MB), ((1 - $newBytes/$origBytes) * 100)
}
if ($videoBytes) {
  "    plus {0:N1} MB of video ({1} file(s)) passed through as-is" -f ($videoBytes/1MB), $videos
}
"    activities.json {0:N0} KB | activities-index.json {1:N0} KB" -f ((Get-Item $jsonPath).Length/1KB), ((Get-Item $idxPath).Length/1KB)
