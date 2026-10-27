import 'package:flutter/foundation.dart';
import '../models/wallet.dart';

class AppState {
  AppState._();
  
  // Menyimpan objek tabungan yang sedang aktif
  static final ValueNotifier<Wallet?> activeWallet = ValueNotifier(null);
  
  // Getter pintas untuk mengambil ID
  static int? get activeWalletId => activeWallet.value?.id;
}