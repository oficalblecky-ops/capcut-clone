# CapCut Clone

Editor video Android (Flutter + FFmpeg): multi-klip, trim, filter warna, transisi, export ke galeri.

## Cara mendapatkan APK tanpa install apa-apa (build di GitHub)

1. Buat repo baru di https://github.com/new (nama bebas, misal `capcut-clone`).
2. Extract zip ini, lalu seret SEMUA isinya (folder `lib`, folder `.github`, `pubspec.yaml`, `README.md`) ke halaman repo
   lewat **uploading an existing file**, lalu klik **Commit changes**.
   - Kalau folder `.github` tidak ikut ter-upload (folder tersembunyi): klik **Add file > Create new file**,
     isi nama file dengan `.github/workflows/build-apk.yml`, lalu paste isi file `build-apk.yml` dari zip.
3. Buka tab **Actions**. Workflow **Build APK** jalan otomatis (atau klik **Run workflow**). Tunggu sekitar 10-20 menit.
4. Buka run yang sudah hijau, scroll ke **Artifacts**, unduh **capcut-clone-apk**, extract.
5. Install `app-arm64-v8a-release.apk` di HP (untuk HP modern). Izinkan "install dari sumber tidak dikenal".

Kalau run merah, buka run itu, salin log langkah yang gagal, dan kirim ke saya.

## Build manual (jika Flutter sudah terpasang)

```bash
flutter create --platforms=android --project-name capcut_clone build_app
rm -rf build_app/lib && cp -r lib build_app/lib && cp pubspec.yaml build_app/
cd build_app
# set minSdk = 24 di android/app/build.gradle(.kts), lalu:
flutter pub get
flutter build apk --release --split-per-abi
```
