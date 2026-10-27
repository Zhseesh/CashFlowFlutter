import 'package:flutter/foundation.dart';
import '../models/wallet.dart';

class AppState {
  AppState._();
  
  // Menyimpan ID tabungan yang sedang aktif
  static final ValueNotifier<int?> activeWalletId = ValueNotifier(null);
  
  // Menyimpan objek tabungan yang aktif (untuk judul di AppBar)
  static final ValueNotifier<Wallet?> activeWallet = ValueNotifier(null);
}