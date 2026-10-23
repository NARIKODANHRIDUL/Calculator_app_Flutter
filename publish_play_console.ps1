<#
.SYNOPSIS
    Builds the Android App Bundle and publishes it to Google Play Console.

.DESCRIPTION
    This script runs "flutter build appbundle --release" and uploads the generated
    .aab bundle to the specified Google Play Console track (internal, alpha, beta, production).

.PARAMETER Track
    The release track. Options: 'internal', 'alpha', 'beta', 'production'.
    Default: 'internal'

.PARAMETER Status
    The release status. Options: 'completed', 'draft', 'inProgress', 'halted'.
    Default: 'completed'

.PARAMETER UserFraction
    Staged rollout fraction (e.g. 0.1 for 10%), used when Status is 'inProgress'.

.PARAMETER ReleaseNotes
    Optional release notes text to attach to the release (en-US).

.PARAMETER KeyFile
    Path to the Google Play Service Account JSON key.
    Default: 'android/play-service-account.json'

.PARAMETER SkipBuild
    If specified, skips running 'flutter build appbundle --release' and uploads existing .aab.

.EXAMPLE
    .\publish_play_console.ps1 -Track internal
    .\publish_play_console.ps1 -Track production -Status inProgress -UserFraction 0.2
    .\publish_play_console.ps1 -SkipBuild -Track alpha
#>

param(
    [ValidateSet('internal', 'alpha', 'beta', 'production')]
    [string]$Track = 'internal',

    [ValidateSet('completed', 'draft', 'inProgress', 'halted')]
    [string]$Status = 'completed',

    [double]$UserFraction = 0.0,

    [string]$ReleaseNotes = '',

    [string]$KeyFile = 'android/play-service-account.json',

    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Google Play Console App Bundle Publisher" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Track:    $Track"
Write-Host "Status:   $Status"
Write-Host "Key file: $KeyFile"
Write-Host ""

# Check key file
$hasKey = (Test-Path $KeyFile) -or ($env:GOOGLE_APPLICATION_CREDENTIALS -and (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) -or ($env:PLAY_SERVICE_ACCOUNT_JSON)
if (-not $hasKey) {
    Write-Host "Error: Service account key not found at '$KeyFile'!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To obtain your Google Play service account key for neriquest@gmail.com:" -ForegroundColor Yellow
    Write-Host "1. Go to Google Play Console (logged in as neriquest@gmail.com) -> Setup -> API Access"
    Write-Host "2. Link / create a Service Account in Google Cloud Console"
    Write-Host "3. Grant 'Release manager' or Admin permissions for 'neriquest.calculator'"
    Write-Host "4. Create & download a JSON key, and save it as: $KeyFile"
    Write-Host "   (or set the GOOGLE_APPLICATION_CREDENTIALS environment variable)"
    exit 1
}

# 1. Build appbundle unless skipped
if (-not $SkipBuild) {
    Write-Host "==> Running: flutter build appbundle --release..." -ForegroundColor Green
    & flutter build appbundle --release
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
} else {
    Write-Host "==> Skipping build step (--SkipBuild specified)." -ForegroundColor Yellow
}

# 2. Prepare arguments for Dart publisher
$dartArgs = @(
    "run",
    "tool/publish_to_play_console.dart",
    "--key-file=$KeyFile",
    "--track=$Track",
    "--status=$Status"
)

if ($UserFraction -gt 0.0) {
    $dartArgs += "--user-fraction=$UserFraction"
}

if ($ReleaseNotes -ne '') {
    $dartArgs += "--release-notes=$ReleaseNotes"
}

# 3. Publish
Write-Host "==> Publishing to Google Play Console..." -ForegroundColor Green
& dart @dartArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==> Successfully uploaded to Google Play Console ($Track track)!" -ForegroundColor Green
} else {
    Write-Host "Publishing failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
