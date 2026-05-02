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
  final ValueNotifier<bool> isKelasBuka = ValueNotifier(false);

  Future<void> checkInitialStatus(String jadwalId, User user) async {
    isLoading.value = true;
    try {
      // Cek apakah kelas sedang berjalan (dari sisi Dosen)
      final kelasBerjalan = await DatabaseService().isKelasBerjalan(jadwalId);
      isKelasBuka.value = kelasBerjalan;

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

  /// Validasi jendela waktu kelas (Local Time-Window)
  bool isWithinTimeWindow(String jamStr) {
    if (!jamStr.contains('-')) return true; // fallback aman jika format salah
    
    try {
      final parts = jamStr.split('-');
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');
      
      if (startParts.length == 2 && endParts.length == 2) {
        final startHour = int.parse(startParts[0]);
        final startMin = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMin = int.parse(endParts[1]);
        
        final now = DateTime.now();
        final startTime = DateTime(now.year, now.month, now.day, startHour, startMin);
        final endTime = DateTime(now.year, now.month, now.day, endHour, endMin);
        
        // Boleh absen 15 menit SEBELUM kelas dimulai, dan ditutup tepat saat kelas selesai
        final allowedStart = startTime.subtract(const Duration(minutes: 15));
        
        return now.isAfter(allowedStart) && now.isBefore(endTime);
      }
    } catch (e) {
      return true; // fallback aman
    }
    return true;
  }

  void dispose() {
    isLoading.dispose();
    isHadir.dispose();
    errorMessage.dispose();
    isKelasBuka.dispose();
  }
}