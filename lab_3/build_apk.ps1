Write-Host "Đang biên dịch ứng dụng Flutter sang APK..." -ForegroundColor Cyan
flutter build apk

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
$destPath = "build\app\outputs\flutter-apk\lab3.apk"

if (Test-Path $apkPath) {
    Move-Item -Path $apkPath -Destination $destPath -Force
    Write-Host "`nThành công! File APK đã được đổi tên thành công:" -ForegroundColor Green
    Write-Host (Get-Item $destPath).FullName -ForegroundColor Yellow
} else {
    Write-Host "`nLỗi: Không tìm thấy file app-release.apk. Vui lòng kiểm tra lại quá trình build." -ForegroundColor Red
}
