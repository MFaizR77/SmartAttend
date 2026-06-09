import 'package:flutter/foundation.dart';

import '../../../../core/services/jadwal_cache_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard dosen — **offline-first**.
///
/// Jadwal mengajar di-load via [JadwalCacheService] yang otomatis fallback
/// ke Hive cache kalau offline atau server timeout.
class DosenDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalMengajar =
      ValueNotifier([]);
  final ValueNotifier<int> izinPending = ValueNotifier(0);

  bool _isDisposed = false;

  Future<void> loadData(User user) async {
    if (_isDisposed) return;

    // Load jadwal hari ini
    try {
      final jadwalDB = await JadwalCacheService().getJadwalDosenHariIni(user.id);
      if (_isDisposed) return;

      jadwalMengajar.value = jadwalDB.map((doc) {
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['kelas']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
          'tipe': doc['tipe']?.toString() ?? 'Reguler',
        };
      }).toList();

      // Schedule notifikasi terjadwal untuk dosen
      NotificationService().scheduleAbsensiReminder(jadwalDB);
      NotificationService().checkAndScheduleLaporanReminder(user.id);
    } catch (e) {
      debugPrint('[DosenDashboardVM] load jadwal error: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    jadwalMengajar.dispose();
    izinPending.dispose();
  }
}
