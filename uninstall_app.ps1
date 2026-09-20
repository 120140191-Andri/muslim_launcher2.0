# ============================================================
# Uninstall Muslim Launcher 2 via ADB
# ============================================================
$ADB = "C:\Users\andri\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$PACKAGE = "com.kraftech.muslim_launcher_2"

# Cek ADB tersedia
if (-not (Test-Path $ADB)) {
    Write-Error "ADB tidak ditemukan di: $ADB"
    exit 1
}

# Cek device terhubung
$devices = & $ADB devices | Select-String "device$"
if (-not $devices) {
    Write-Error "Tidak ada device yang terhubung. Pastikan USB Debugging aktif."
    exit 1
}

Write-Host "Device ditemukan:" -ForegroundColor Green
& $ADB devices

Write-Host ""
Write-Host "Menguninstall $PACKAGE ..." -ForegroundColor Yellow
& $ADB uninstall $PACKAGE

Write-Host ""
Write-Host "Selesai." -ForegroundColor Green
