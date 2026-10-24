# Cash Flow

Aplikasi Android pengelola arus kas (Flutter + Dart), offline, dengan SQLite lokal,
analisis grafik bulanan, ekspor PDF/CSV, serta cadangan dan pemulihan JSON.

Package / Application ID: `com.zsheesh.cashflow`

## Cara menjalankan

Folder ini berisi kode sumber (`lib/`, `test/`, `pubspec.yaml`). Folder platform
Android dibuat oleh Flutter:

```bash
flutter create --org com.zsheesh --project-name cashflow --platforms android cashflow_app
# salin lib/, test/, pubspec.yaml, analysis_options.yaml dari folder ini ke cashflow_app/
# (timpa berkas bawaan; hapus test/widget_test.dart bawaan)
cd cashflow_app
flutter pub get
flutter test
flutter run
```

Application ID otomatis menjadi `com.zsheesh.cashflow`. Ubah label aplikasi menjadi
"Cash Flow" di `android/app/src/main/AndroidManifest.xml` (`android:label`).

Jika ada konflik versi paket: `flutter pub upgrade --major-versions`.

## Build di Termux (aarch64, flutter-for-termux)

Diuji untuk Flutter 3.47.7 / Dart 3.13.5 dari
[flutter-for-termux](https://github.com/GeneralKaos666/flutter-for-termux).

```bash
# di folder proyek yang sudah memiliki android/
bash termux_build.sh --provision-ndk   # pertama kali saja (unduh NDK ~550 MB)
bash termux_build.sh                   # build berikutnya
```

Skrip itu menjalankan `flutter_project_config.sh` bawaan flutter-for-termux (mengatur
`aapt2FromMavenOverride`, `compileSdk/targetSdk = 36`, dan `abiFilters arm64-v8a`),
menyiapkan NDK bila diminta, lalu `flutter build apk --debug --no-tree-shake-icons`.

Kenapa NDK dibutuhkan: dependensi transitif `jni` (dari plugin Android) berisi kode native.
Galat `NDK not configured ... project ':jni'` berarti NDK belum dipasang; jalankan
`bash $PREFIX/share/flutter/post_install.sh --provision-ndk`.

Jangan jalankan `flutter upgrade` di instalasi Termux.

## Build lewat GitHub Actions

Workflow `.github/workflows/build-apk.yml` membuat `android/` yang bersih, lalu membangun
APK release di runner Ubuntu (NDK tersedia, jadi paket `jni` tidak bermasalah).

1. Buat repo GitHub dan push isi folder ini (`android/` sudah diabaikan oleh `.gitignore`).
2. Buka tab **Actions**, jalankan **Build APK** (otomatis berjalan pada setiap push ke `main`).
3. Setelah selesai, unduh artefak `cashflow-apk` (`app-release.apk`).

APK ini ditandatangani dengan kunci debug bawaan Flutter: cukup untuk dipasang sendiri,
belum untuk Play Store.

## Struktur

| Lapisan | Berkas |
|---|---|
| UI | `lib/ui/` (dasbor, riwayat, analisis, data & laporan, form transaksi) |
| State | `lib/state/cashflow_controller.dart` (setara CashFlowViewModel) |
| Repository | `lib/data/repository.dart` |
| SQLite langsung | `lib/data/database_helper.dart` (tabel `categories`, `transactions`, indeks, transaksi atomik) |
| Ekspor | `lib/export/` (`pdf_exporter.dart`, `csv_exporter.dart`, `json_backup.dart`) |

## Catatan keputusan teknis

- Stack Flutter dipilih, sehingga komponen khusus Android pada spesifikasi diganti padanannya:
  `SQLiteOpenHelper` -> `sqflite` (SQL mentah, tanpa ORM), `PdfDocument` -> paket `pdf`
  (A4, tanpa library komersial), `FileProvider`/`ACTION_SEND` -> `share_plus`,
  `CreateDocument`/`OpenDocument` -> `file_picker` (Storage Access Framework).
- Grafik di aplikasi digambar dengan `CustomPainter` (tanpa paket grafik tambahan).
- Berkas ekspor selalu disalin ke folder dokumen aplikasi (`exports/`), lalu dibagikan
  atau disimpan lewat dialog sistem.
- CSV: UTF-8 dengan BOM, pemisah `;` atau `,`, nominal bertanda (pemasukan +, pengeluaran -),
  kolom `ID,Tanggal,Waktu,Tipe,Kategori,Judul,Catatan,Nominal,Saldo Berjalan`.
- Impor JSON divalidasi penuh (aplikasi, versi skema, tipe kolom, ID ganda) sebelum menyentuh
  database, lalu dijalankan dalam satu transaksi atomik. Mode: gabungkan (duplikat dilewati)
  atau ganti semua.
