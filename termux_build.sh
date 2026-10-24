#!/data/data/com.termux/files/usr/bin/bash
# Build Cash Flow di Termux (aarch64) dengan flutter-for-termux.
#
# Pemakaian (dari folder proyek yang sudah berisi android/):
#   bash termux_build.sh --provision-ndk   # pertama kali (unduh NDK ~550 MB)
#   bash termux_build.sh                   # build berikutnya
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
cd "$(dirname "$0")"

if [ ! -d android ]; then
  echo "Folder android/ tidak ada. Buat dulu dengan:" >&2
  echo "  flutter create --org com.zsheesh --project-name cashflow --platforms android ." >&2
  exit 1
fi

# 1. Konfigurasi Gradle untuk Termux: aapt2 dari Termux, compileSdk/targetSdk,
#    abiFilters arm64-v8a (skrip bawaan flutter-for-termux, aman diulang).
bash "$PREFIX/share/flutter/flutter_project_config.sh" "$(pwd)"

# 2. NDK dibutuhkan oleh plugin berkode native (mis. paket 'jni' yang ditarik
#    path_provider_android). Tanpa ini Gradle gagal: "NDK not configured".
for arg in "$@"; do
  if [ "$arg" = "--provision-ndk" ]; then
    bash "$PREFIX/share/flutter/post_install.sh" --provision-ndk
  fi
done

# 3. Build APK debug (tree-shake ikon dimatikan sesuai panduan flutter-for-termux).
flutter pub get
flutter build apk --debug --no-tree-shake-icons

echo
echo "APK: $(pwd)/build/app/outputs/flutter-apk/app-debug.apk"
