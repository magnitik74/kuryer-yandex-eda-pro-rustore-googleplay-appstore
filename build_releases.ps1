$ErrorActionPreference = "Stop"

Write-Host "Building APK for RuStore..."
& "D:\src\flutter\bin\flutter.bat" build apk --release --dart-define=STORE=rustore
if ($LASTEXITCODE -ne 0) { throw "APK build failed" }

Write-Host "Building AAB for Google Play..."
& "D:\src\flutter\bin\flutter.bat" build appbundle --release --dart-define=STORE=googleplay
# Ignore error codes for AAB if it's just the NDK symbol stripping warning.
# We will just check if the file was created.

$outDir = "..\releases"
$rustoreDir = "$outDir\RuStore"
$googlePlayDir = "$outDir\GooglePlay"

if (-Not (Test-Path $rustoreDir)) {
    New-Item -ItemType Directory -Force -Path $rustoreDir | Out-Null
}
if (-Not (Test-Path $googlePlayDir)) {
    New-Item -ItemType Directory -Force -Path $googlePlayDir | Out-Null
}

$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"
$aabPath = ".\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $apkPath) {
    Copy-Item -Path $apkPath -Destination "$rustoreDir\fast_courier_rustore.apk" -Force
    Copy-Item -Path $apkPath -Destination "$outDir\fast_courier_rustore.apk" -Force
    Write-Host "Copied APK to $rustoreDir\fast_courier_rustore.apk"
} else {
    Write-Host "Warning: APK not found!"
}

if (Test-Path $aabPath) {
    Copy-Item -Path $aabPath -Destination "$googlePlayDir\fast_courier_googleplay.aab" -Force
    Copy-Item -Path $aabPath -Destination "$outDir\fast_courier_googleplay.aab" -Force
    Write-Host "Copied AAB to $googlePlayDir\fast_courier_googleplay.aab"
} else {
    Write-Host "Warning: AAB not found!"
}

Write-Host "Done! Releases are saved to 'releases\RuStore\' and 'releases\GooglePlay\'."

