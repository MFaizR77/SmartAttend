import 'package:flutter/foundation.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/jadwal_cache_service.dart';
import '../../../../data/local/dummy_data.dart';
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
    // Statistik sementara dari dummy. Kelak: ambil dari Mongo + cache.
    statistik.value = {
      'hadir': DummyData.totalHadir,
      'izin': DummyData.totalIzin,
      'alpha': DummyData.totalAlpha,
      'total': DummyData.totalPertemuan,
    };

    // Jadwal regular — offline-first via cache.
    try {
      final jadwalDB = await JadwalCacheService().getJadwalHariIni(user.id);
      jadwalHariIni.value = jadwalDB.map((doc) {
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['tipe']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
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
