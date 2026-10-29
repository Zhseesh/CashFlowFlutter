import 'package:flutter/material.dart';

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