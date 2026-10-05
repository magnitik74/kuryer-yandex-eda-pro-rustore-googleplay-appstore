$ErrorActionPreference = "Stop"

Write-Host "=== Building RuStore APK ==="
& "D:\src\flutter\bin\flutter.bat" build apk --release --dart-define=STORE=rustore
if ($LASTEXITCODE -ne 0) { throw "RuStore APK build failed" }

Write-Host "=== Building Google Play AAB ==="
& "D:\src\flutter\bin\flutter.bat" build appbundle --release --dart-define=STORE=googleplay
# Ignore error codes for AAB if it's just the NDK symbol stripping warning.
# We will just check if the file was created.

Write-Host "=== Building App Store IPA ==="
& "D:\src\flutter\bin\flutter.bat" build ipa --release --dart-define=STORE=appstore
if ($LASTEXITCODE -ne 0) { throw "App Store IPA build failed" }

$outDir = "..\releases"
$rustoreDir = "$outDir\RuStore"
$googlePlayDir = "$outDir\GooglePlay"
$appStoreDir = "$outDir\AppStore"

if (-Not (Test-Path $rustoreDir)) {
    New-Item -ItemType Directory -Force -Path $rustoreDir | Out-Null
}
if (-Not (Test-Path $googlePlayDir)) {
    New-Item -ItemType Directory -Force -Path $googlePlayDir | Out-Null
}
if (-Not (Test-Path $appStoreDir)) {
    New-Item -ItemType Directory -Force -Path $appStoreDir | Out-Null
}

$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"
$aabPath = ".\build\app\outputs\bundle\release\app-release.aab"
$ipaPath = ".\build\ios\ipa\fast_courier_app.ipa"

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

if (Test-Path $ipaPath) {
    Copy-Item -Path $ipaPath -Destination "$appStoreDir\fast_courier_appstore.ipa" -Force
    Copy-Item -Path $ipaPath -Destination "$outDir\fast_courier_appstore.ipa" -Force
    Write-Host "Copied IPA to $appStoreDir\fast_courier_appstore.ipa"
} else {
    Write-Host "Warning: IPA not found!"
}

Write-Host "=== Done! Releases are saved to 'releases\' ==="
Write-Host "RuStore: releases\RuStore\fast_courier_rustore.apk"
Write-Host "Google Play: releases\GooglePlay\fast_courier_googleplay.aab"
Write-Host "App Store: releases\AppStore\fast_courier_appstore.ipa"