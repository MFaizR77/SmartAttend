import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/local/hive_helper.dart';
import '../../data/remote/database_service.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _isSyncing = false;

  void init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        syncPendingRecords();
      }
    });
    
    // Coba sync saat pertama kali diinisialisasi
    syncPendingRecords();
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
