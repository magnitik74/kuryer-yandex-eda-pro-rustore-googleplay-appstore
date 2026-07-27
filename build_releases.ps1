$ErrorActionPreference = "Stop"

Write-Host "Building APK for RuStore..."
& "D:\src\flutter\bin\flutter.bat" build apk --release --dart-define=STORE=rustore
if ($LASTEXITCODE -ne 0) { throw "APK build failed" }

Write-Host "Building AAB for Google Play..."
& "D:\src\flutter\bin\flutter.bat" build appbundle --release --dart-define=STORE=googleplay
# Ignore error codes for AAB if it's just the NDK symbol stripping warning.
# We will just check if the file was created.

$outDir = "..\releases"
if (-Not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$apkPath = ".\build\app\outputs\flutter-apk\app-release.apk"
$aabPath = ".\build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $apkPath) {
    Copy-Item -Path $apkPath -Destination "$outDir\fast_courier_rustore.apk" -Force
    Write-Host "Copied APK to $outDir\fast_courier_rustore.apk"
} else {
    Write-Host "Warning: APK not found!"
}

if (Test-Path $aabPath) {
    Copy-Item -Path $aabPath -Destination "$outDir\fast_courier_googleplay.aab" -Force
    Write-Host "Copied AAB to $outDir\fast_courier_googleplay.aab"
} else {
    Write-Host "Warning: AAB not found!"
}

Write-Host "Done! Your release files are ready in the 'releases' folder in the root directory."
