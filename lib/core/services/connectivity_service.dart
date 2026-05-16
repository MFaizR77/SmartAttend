import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton wrapper untuk `connectivity_plus`.
///
/// Menyediakan API tunggal yang dipakai seluruh app sehingga setiap layar
/// tidak perlu lagi me-listen `Connectivity` secara manual.
///
/// Pemakaian:
/// 1. Panggil [init] sekali dari `main()` sebelum `runApp`.
/// 2. Bind UI ke [isOnline] memakai `ValueListenableBuilder<bool>`.
/// 3. Service yang butuh subscribe stream pakai [onStatusChanged].
/// 4. Pengecekan satu kali (mis. sebelum POST) pakai [checkNow].
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> _isOnline = ValueNotifier<bool>(true);
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _initialized = false;

  /// Status koneksi terakhir yang diketahui — reaktif untuk UI.
  ValueListenable<bool> get isOnline => _isOnline;

  /// Stream broadcast status koneksi (`true` = online, `false` = offline).
  /// Berguna untuk service di luar widget tree (mis. `SyncManager`).
  Stream<bool> get onStatusChanged => _statusController.stream;

  /// Inisialisasi listener. Aman dipanggil berkali-kali; hanya berjalan sekali.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final initial = await _connectivity.checkConnectivity();
    _emit(_resolveOnline(initial));

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _emit(_resolveOnline(results)),
    );
  }

  /// Snapshot status koneksi saat ini (one-shot). Juga memperbarui [isOnline].
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    final online = _resolveOnline(results);
    _emit(online);
    return online;
  }

  bool _resolveOnline(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  void _emit(bool online) {
    if (_isOnline.value != online) {
      _isOnline.value = online;
    }
    if (!_statusController.isClosed) {
      _statusController.add(online);
    }
  }

  /// Bersihkan resource. Biasanya tidak perlu dipanggil karena service
  /// hidup sepanjang umur aplikasi; disediakan untuk skenario test.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _statusController.close();
    _isOnline.dispose();
    _initialized = false;
  }
}
