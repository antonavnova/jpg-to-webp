<#
.SYNOPSIS
Конвертирует JPEG изображения в WebP с помощью ImageMagick (magick)
.DESCRIPTION
Поддерживает одиночный файл и пакетную конвертацию из списка.
Автоматически разрешает коллизии имён.
#>

# ========== ПАРАМЕТРЫ КОМАНДНОЙ СТРОКИ ==========
param(
    [string]$file,
    [string]$list,
    [switch]$help
)

# ========== НАСТРОЙКИ КАЧЕСТВА (менять здесь) ==========
$WebPQuality = 85        # качество WebP (0-100)
$WebPMethod = 4          # метод сжатия (0-6)
$WebPLossless = $false   # lossless режим
# =======================================================

function Resolve-FilePath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path) -or $Path -match '^\.\.?\\|^\.\.?/') {
        if (Test-Path $Path) {
            return (Resolve-Path $Path).Path
        }
        return $Path
    }
    else {
        return (Join-Path (Get-Location) $Path)
    }
}

function Get-UniqueOutputPath {
    param([string]$OutputPath)
    if (-not (Test-Path $OutputPath)) {
        return $OutputPath
    }
    $directory = Split-Path $OutputPath -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)
    $extension = [System.IO.Path]::GetExtension($OutputPath)
    $counter = 1
    do {
        $newPath = Join-Path $directory "$baseName($counter)$extension"
        $counter++
    } while (Test-Path $newPath)
    return $newPath
}

function Convert-JpegToWebP {
    param([string]$InputPath, [switch]$Verbose)
    
    $resolvedPath = Resolve-FilePath $InputPath
    if (-not (Test-Path $resolvedPath)) {
        Write-Host "❌ Файл не найден: $resolvedPath" -ForegroundColor Red
        return $false
    }
    
    $extension = [System.IO.Path]::GetExtension($resolvedPath).ToLower()
    if ($extension -notin '.jpg', '.jpeg') {
        Write-Host "❌ Не JPEG файл: $resolvedPath" -ForegroundColor Red
        return $false
    }
    
    $outDir = Split-Path $resolvedPath -Parent
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)
    $outPath = Join-Path $outDir "$baseName.webp"
    $outPath = Get-UniqueOutputPath $outPath
    
    # Параметры качества для ImageMagick
    $qualityParams = @("-quality", $WebPQuality.ToString())
    if ($WebPLossless) {
        $qualityParams = @("-define", "webp:lossless=true")
    }
    if ($WebPMethod -ge 0 -and $WebPMethod -le 6) {
        $qualityParams += @("-define", "webp:method=$WebPMethod")
    }
    
    try {
        $originalSize = (Get-Item $resolvedPath).Length / 1024
        & magick convert $resolvedPath $qualityParams $outPath 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick вернул код $LASTEXITCODE"
        }
        $newSize = (Get-Item $outPath).Length / 1024
        if ($Verbose) {
            Write-Host "✅ $([System.IO.Path]::GetFileName($resolvedPath)) -> $([System.IO.Path]::GetFileName($outPath)) ($([math]::Round($originalSize,1))KB -> $([math]::Round($newSize,1))KB)" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "❌ Ошибка конвертации $resolvedPath : $_" -ForegroundColor Red
        return $false
    }
}

function Convert-FromList {
    param([string]$ListPath, [switch]$Verbose)
    
    $resolvedList = Resolve-FilePath $ListPath
    if (-not (Test-Path $resolvedList)) {
        Write-Host "❌ Файл списка не найден: $resolvedList" -ForegroundColor Red
        return @(0, 0)
    }
    
    $paths = Get-Content $resolvedList -Encoding UTF8 | Where-Object {
        $_.Trim() -and (-not $_.Trim().StartsWith('#'))
    } | ForEach-Object { $_.Trim() }
    
    $success = 0
    $failed = 0
    foreach ($p in $paths) {
        if (Convert-JpegToWebP $p -Verbose:$Verbose) {
            $success++
        } else {
            $failed++
        }
    }
    return @($success, $failed)
}

function Show-Help {
    $helpText = @"
═══════════════════════════════════════════════════════════════
🖼️  JPEG → WebP Конвертер (PowerShell + ImageMagick)
═══════════════════════════════════════════════════════════════

Использование:
  .\convert_jpg_to_webp.ps1 -file "путь\к\файлу.jpg"
  .\convert_jpg_to_webp.ps1 -list "путь\к\список.txt"
  .\convert_jpg_to_webp.ps1 -help

Аргументы:
  -file <path>    Конвертировать один JPG файл
  -list <path>    Конвертировать файлы из текстового списка
  -help           Показать эту справку

Правила работы с путями:
  • Если путь не абсолютный и не начинается с .\ или ..\,
    файл ищется в текущей рабочей директории.
  • Выходной WebP создаётся рядом с исходным JPG.
  • При коллизии имён добавляется суффикс (1), (2)...

Примеры:
  .\convert_jpg_to_webp.ps1 -file "photo.jpg"
  .\convert_jpg_to_webp.ps1 -file "C:\images\photo.jpg"
  .\convert_jpg_to_webp.ps1 -list ".\images.txt"

Настройки качества (изменить в скрипте):
  `$WebPQuality = 85
  `$WebPMethod = 4
  `$WebPLossless = `$false
═══════════════════════════════════════════════════════════════
"@
    Write-Host $helpText
}

# ========== ОСНОВНОЙ КОД ==========

# Проверка наличия ImageMagick
$magickCheck = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magickCheck) {
    Write-Host "❌ Ошибка: ImageMagick (magick) не найден в PATH." -ForegroundColor Red
    Write-Host "Установите: winget install ImageMagick.ImageMagick или скачайте с https://imagemagick.org" -ForegroundColor Yellow
    exit 1
}

if ($help -or (-not $file -and -not $list)) {
    Show-Help
    exit 0
}

$startTime = Get-Date

if ($file) {
    $result = Convert-JpegToWebP $file -Verbose
    $success = [int]$result
    $failed = 1 - $success
} else {
    $results = Convert-FromList $list -Verbose
    $success = $results[0]
    $failed = $results[1]
}

$elapsed = (Get-Date) - $startTime
$total = $success + $failed

Write-Host "`n📊 Статистика: успешно $success / всего $total файлов" -ForegroundColor Cyan
Write-Host "⏱️  Время: $([math]::Round($elapsed.TotalSeconds,2)) сек" -ForegroundColor Cyan