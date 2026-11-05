import 'package:material_ui/material_ui.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      // Nav
      'dashboard': 'Dasbor',
      'analytics': 'Analisis',
      'reports': 'Laporan',
      // Dashboard
      'main_wallet': 'Dompet Utama',
      'current_balance': 'Saldo Saat Ini',
      'income': 'Pemasukan',
      'expense': 'Pengeluaran',
      'recent_transactions': 'Transaksi Terbaru',
      'search_hint': 'Cari transaksi...',
      'no_transactions': 'Belum ada transaksi',
      'no_transactions_sub': 'Catat pengeluaran pertamamu hari ini',
      // Settings
      'settings': 'Pengaturan',
      'appearance': 'Tampilan',
      'system': 'Ikuti Sistem',
      'light': 'Terang',
      'dark': 'Gelap',
      'language': 'Bahasa',
      'indonesian': 'Bahasa Indonesia',
      'english': 'English',
      'features': 'Fitur',
      'budget': 'Atur Anggaran',
      'budget_sub': 'Batas maksimal pengeluaran per kategori',
      'others': 'Lainnya',
      'about': 'Tentang Aplikasi',
      'about_sub': 'Versi, informasi, & cek update',
      // About
      'version': 'Versi',
      'check_update': 'Cek Pembaruan',
      'checking': 'Memeriksa...',
      'made_with': 'Dibuat dengan ❤️ menggunakan Flutter',
      'update_available': 'Update Tersedia!',
      'update_msg': 'Versi terbaru tersedia di GitHub. Versi kamu saat ini:',
      'later': 'Nanti',
      'open_github': 'Buka GitHub',
      'up_to_date': 'Aplikasi Up-to-Date',
      'up_to_date_msg': 'Kamu sudah menggunakan versi terbaru.',
      'close': 'Tutup',
      'info': 'Informasi',
      'no_release': 'Belum ada rilis pembaruan yang tersedia di GitHub.',
      'error_update': 'Gagal cek update: Pastikan internet stabil dan coba lagi.',
      // Budget
      'monthly_budget': 'Anggaran Bulanan',
      'no_budget': 'Belum ada anggaran. Ketuk untuk mengatur.',
      'save': 'Simpan',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'edit': 'Edit',
      'add': 'Tambah',
      'reset': 'Reset',
      // Transaction Form
      'new_transaction': 'Transaksi Baru',
      'edit_transaction': 'Edit Transaksi',
      'title': 'Judul',
      'title_hint': 'Contoh: Gaji bulanan',
      'amount': 'Nominal',
      'category': 'Kategori',
      'date': 'Tanggal',
      'note': 'Catatan',
      'note_hint': 'Tambahkan detail...',
      'attachment': 'Bukti Transfer',
      'add_attachment': 'Tambah Bukti Transfer',
      'saved_attachment': 'Lampiran tersimpan',
      'unsaved_attachment': 'Belum disimpan',
      'update': 'Perbarui',
      'delete_confirm': 'Hapus Transaksi?',
      'delete_msg': 'akan dihapus permanen.',
      'manage_category': 'Kelola Kategori',
      // Reports
      'reports_data': 'Laporan & Data',
      'report_for': 'Laporan untuk:',
      'export_document': 'Ekspor Dokumen',
      'export_pdf': 'Ekspor PDF Bulanan',
      'export_pdf_sub': 'Laporan lengkap dengan grafik & mutasi',
      'export_csv': 'Ekspor CSV',
      'export_csv_sub': 'Spreadsheet siap Excel/Sheets',
      'backup_data': 'Cadangan Data',
      'backup_json': 'Cadangkan (JSON)',
      'backup_json_sub': 'Simpan & bagikan seluruh data',
      'restore_json': 'Pulihkan (JSON)',
      'restore_json_sub': 'Impor dari berkas cadangan',
      'import_confirm': 'Impor Cadangan',
      'import_msg': 'Ditemukan transaksi. Pilih mode impor:',
      'append': 'Tumpuk',
      'replace': 'Ganti Semua',
      'saved_success': 'Berhasil disimpan!',
      'import_success': 'Impor berhasil',
      // Category Management
      'custom_category': 'Kategori Kustom',
      'add_category': 'Tambah Kategori',
      'edit_category': 'Edit Kategori',
      'category_name': 'Nama Kategori',
      'delete_category_confirm': 'Hapus Kategori?',
      'delete_category_msg': 'akan dihapus. Transaksi lama tidak akan terpengaruh.',
      // Wallet Management
      'manage_wallet': 'Kelola Tabungan',
      'add_wallet': 'Tambah Tabungan Baru',
      'wallet_name': 'Nama Tabungan',
      'wallet_name_hint': 'Contoh: Dompet Utama',
      'initial_balance': 'Saldo Awal (Opsional)',
      'created_at': 'Dibuat',
      'delete_wallet_confirm': 'Hapus Tabungan?',
      'delete_wallet_msg': 'Semua transaksi di',
      'delete_wallet_msg2': 'akan dihapus permanen.',
      'cannot_delete_last_wallet': 'Tidak bisa menghapus tabungan terakhir',
      'wallet': 'Tabungan',
    },
    'en': {
      // Nav
      'dashboard': 'Dashboard',
      'analytics': 'Analytics',
      'reports': 'Reports',
      // Dashboard
      'main_wallet': 'Main Wallet',
      'current_balance': 'Current Balance',
      'income': 'Income',
      'expense': 'Expense',
      'recent_transactions': 'Recent Transactions',
      'search_hint': 'Search transactions...',
      'no_transactions': 'No transactions yet',
      'no_transactions_sub': 'Record your first expense today',
      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'system': 'Follow System',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'indonesian': 'Bahasa Indonesia',
      'english': 'English',
      'features': 'Features',
      'budget': 'Set Budget',
      'budget_sub': 'Maximum spending limit per category',
      'others': 'Others',
      'about': 'About App',
      'about_sub': 'Version, info, & check update',
      // About
      'version': 'Version',
      'check_update': 'Check for Updates',
      'checking': 'Checking...',
      'made_with': 'Made with ❤️ using Flutter',
      'update_available': 'Update Available!',
      'update_msg': 'A new version is available on GitHub. Your current version:',
      'later': 'Later',
      'open_github': 'Open GitHub',
      'up_to_date': 'App is Up-to-Date',
      'up_to_date_msg': 'You are using the latest version.',
      'close': 'Close',
      'info': 'Information',
      'no_release': 'No release updates available on GitHub yet.',
      'error_update': 'Failed to check update: Ensure stable internet and try again.',
      // Budget
      'monthly_budget': 'Monthly Budget',
      'no_budget': 'No budget yet. Tap to set.',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'reset': 'Reset',
      // Transaction Form
      'new_transaction': 'New Transaction',
      'edit_transaction': 'Edit Transaction',
      'title': 'Title',
      'title_hint': 'e.g., Monthly Salary',
      'amount': 'Amount',
      'category': 'Category',
      'date': 'Date',
      'note': 'Note',
      'note_hint': 'Add details...',
      'attachment': 'Transfer Receipt',
      'add_attachment': 'Add Receipt',
      'saved_attachment': 'Saved attachment',
      'unsaved_attachment': 'Not saved yet',
      'update': 'Update',
      'delete_confirm': 'Delete Transaction?',
      'delete_msg': 'will be permanently deleted.',
      'manage_category': 'Manage Category',
      // Reports
      'reports_data': 'Reports & Data',
      'report_for': 'Report for:',
      'export_document': 'Export Document',
      'export_pdf': 'Export Monthly PDF',
      'export_pdf_sub': 'Full report with charts & mutations',
      'export_csv': 'Export CSV',
      'export_csv_sub': 'Spreadsheet ready for Excel/Sheets',
      'backup_data': 'Data Backup',
      'backup_json': 'Backup (JSON)',
      'backup_json_sub': 'Save & share all data',
      'restore_json': 'Restore (JSON)',
      'restore_json_sub': 'Import from backup file',
      'import_confirm': 'Import Backup',
      'import_msg': 'Transactions found. Choose import mode:',
      'append': 'Append',
      'replace': 'Replace All',
      'saved_success': 'Saved successfully!',
      'import_success': 'Import successful',
      // Category Management
      'custom_category': 'Custom Category',
      'add_category': 'Add Category',
      'edit_category': 'Edit Category',
      'category_name': 'Category Name',
      'delete_category_confirm': 'Delete Category?',
      'delete_category_msg': 'will be deleted. Old transactions will not be affected.',
      // Wallet Management
      'manage_wallet': 'Manage Wallets',
      'add_wallet': 'Add New Wallet',
      'wallet_name': 'Wallet Name',
      'wallet_name_hint': 'e.g., Main Wallet',
      'initial_balance': 'Initial Balance (Optional)',
      'created_at': 'Created',
      'delete_wallet_confirm': 'Delete Wallet?',
      'delete_wallet_msg': 'All transactions in',
      'delete_wallet_msg2': 'will be permanently deleted.',
      'cannot_delete_last_wallet': 'Cannot delete the last wallet',
      'wallet': 'Wallet',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['id', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}