import 'package:flutter/foundation.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/jadwal_cache_service.dart';
import '../../../../core/utils/jadwal_expander.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard mahasiswa — offline-first.
///
/// Jadwal hari ini di-load via [JadwalCacheService] yang otomatis fallback
/// ke Hive cache kalau offline atau server timeout.
class MahasiswaDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalHariIni =
      ValueNotifier([]);
  final ValueNotifier<List<Map<String, String>>> jadwalPenggantiHariIni =
      ValueNotifier([]);
  final ValueNotifier<Map<String, int>> statistik = ValueNotifier({});

  Future<void> loadData(User user) async {
    // Statistik: online → MongoDB + cache ke Hive, offline → dari cache.
    try {
      final stats = await DatabaseService().getStatistikMahasiswa(user.id);
      statistik.value = stats;
      // Cache ke Hive
      final box = HiveHelper.userBoxInstance;
      await box.put('statistik_${user.id}', stats);
    } catch (e) {
      debugPrint('[MhsDashboard] load statistik dari server gagal: $e');
      // Fallback: baca dari Hive cache
      final box = HiveHelper.userBoxInstance;
      final cached = box.get('statistik_${user.id}');
      if (cached is Map) {
        statistik.value = cached.map((k, v) => MapEntry(k.toString(), v is int ? v : int.tryParse(v.toString()) ?? 0));
      } else {
        statistik.value = {'hadir': 0, 'izin': 0, 'sakit': 0, 'alpha': 0, 'total': 0};
      }
    }

    // Jadwal regular — offline-first via cache.
    try {
      final jadwalDB = await JadwalCacheService().getJadwalHariIni(user.id);

      // Expand team teaching (khusus Proyek) jadi 1 kartu per dosen —
      // display-only, consistent dengan JadwalScreen & AbsensiListScreen.
      final expanded = expandTeamTeaching(jadwalDB);

      jadwalHariIni.value = expanded.map((doc) {
        final namaDosen = doc['namaDosen']?.toString() ??
            doc['dosenId']?.toString() ??
            '';
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['tipe']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
          'dosen': namaDosen,
        };
      }).toList();
    } catch (e) {
      debugPrint('[MhsDashboard] load jadwal regular gagal: $e');
      jadwalHariIni.value = [];
    }

    // Pengganti — masih berbasis kelas. Kalau offline, skip (kosong) karena
    // belum di-cache. Bukan critical untuk MVP.
    if (user.kelas != null && ConnectivityService().isOnline.value) {
      try {
        final penggantiDB =
            await DatabaseService().getJadwalPenggantiMahasiswa(user.kelas!);
        jadwalPenggantiHariIni.value = penggantiDB.map((doc) {
          return {
            'id': doc['_id']?.toString() ?? '',
            'mataKuliah': '${doc['namaMK']} (Pengganti)',
            'jam':
                '${doc['jamMulaiPengganti']} - ${doc['jamSelesaiPengganti']}',
            'ruang': doc['ruanganPengganti']?.toString() ?? '-',
          };
        }).toList();
      } catch (e) {
        debugPrint('[MhsDashboard] load pengganti gagal: $e');
        jadwalPenggantiHariIni.value = [];
      }
    } else {
      jadwalPenggantiHariIni.value = [];
    }
  }

  void dispose() {
    jadwalHariIni.dispose();
    jadwalPenggantiHariIni.dispose();
    statistik.dispose();
  }
}
