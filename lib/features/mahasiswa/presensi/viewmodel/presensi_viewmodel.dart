import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/record_presensi.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

class PresensiViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isHadir = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<bool> isOfflineMode = ValueNotifier(false);

  Future<void> checkInitialStatus(String jadwalId, User user) async {
    isLoading.value = true;
    try {
      // 1. Cek dari lokal (Hive) dulu
      final presensiBox = HiveHelper.recordPresensiBoxInstance;
      final localRecords = presensiBox.values.where((r) => 
        r.sesiId == jadwalId && 
        r.mahasiswaId == user.id &&
        r.timestamp.day == DateTime.now().day &&
        r.timestamp.month == DateTime.now().month &&
        r.timestamp.year == DateTime.now().year
      ).toList();

      if (localRecords.isNotEmpty) {
        isHadir.value = true;
        isOfflineMode.value = localRecords.first.syncStatus != 'synced';
        isLoading.value = false;
        return;
      }

      // 2. Jika tidak ada di lokal, cek online (ke MongoDB)
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);
      
      if (isOnline) {
        final exists = await DatabaseService().checkPresensiExists(jadwalId, user.id);
        if (exists) {
          isHadir.value = true;
          isOfflineMode.value = false;
        }
      }
    } catch (e) {
      print('Error checking initial presensi status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> doCheckIn(String jadwalId, User user) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Cek koneksi internet
      final List<ConnectivityResult> connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

      final record = RecordPresensi(
        clientUuid: const Uuid().v4(),
        sesiId: jadwalId,
        mahasiswaId: user.id,
        timestamp: DateTime.now(),
        statusHadir: true,
        metode: 'manual',
        syncStatus: isOnline ? 'synced' : 'pending',
      );

      if (isOnline) {
        // Langsung simpan ke MongoDB
        await DatabaseService().insertRecordPresensi(record.toMap());
        isOfflineMode.value = false;
        
        // Simpan juga ke Hive sebagai riwayat (sudah synced)
        final presensiBox = HiveHelper.recordPresensiBoxInstance;
        await presensiBox.put(record.clientUuid, record);
      } else {
        // Simpan ke Hive saja (offline)
        final presensiBox = HiveHelper.recordPresensiBoxInstance;
        await presensiBox.put(record.clientUuid, record);
        isOfflineMode.value = true;
      }
      
      isHadir.value = true;
    } catch (e) {
      errorMessage.value = 'Gagal menyimpan data presensi: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    isHadir.dispose();
    errorMessage.dispose();
  }
}
