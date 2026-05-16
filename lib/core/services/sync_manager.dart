import 'dart:async';

import '../../data/local/hive_helper.dart';
import '../../data/remote/database_service.dart';
import 'connectivity_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  void init() {
    // Subscribe ke ConnectivityService — hanya sync ketika status berubah
    // menjadi online (transisi offline → online).
    _connectivitySub?.cancel();
    _connectivitySub = ConnectivityService().onStatusChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingRecords();
      }
    });

    // Coba sync sekali saat pertama kali diinisialisasi (jika sudah online).
    if (ConnectivityService().isOnline.value) {
      syncPendingRecords();
    }
  }

  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final box = HiveHelper.recordPresensiBoxInstance;
      final pendingRecords = box.values.where((r) => r.syncStatus == 'pending').toList();

      if (pendingRecords.isEmpty) {
        _isSyncing = false;
        return;
      }

      print('🔄 Memulai sinkronisasi ${pendingRecords.length} record presensi...');

      for (var record in pendingRecords) {
        try {
          await DatabaseService().insertRecordPresensi(record.toMap());
          
          // Update status lokal menjadi synced
          final syncedRecord = record.markAsSynced();
          await box.put(syncedRecord.clientUuid, syncedRecord);
          print('✅ Record ${record.clientUuid} tersinkronisasi.');
        } catch (e) {
          print('❌ Gagal sinkronisasi record ${record.clientUuid}: $e');
        }
      }
    } catch (e) {
      print('Terjadi kesalahan pada SyncManager: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
