import 'package:flutter/foundation.dart';

import '../../../../core/services/jadwal_cache_service.dart';
import '../../../../data/local/dummy_data.dart';
import '../../../../data/local/models/user.dart';

/// ViewModel dashboard dosen — **offline-first**.
///
/// Jadwal mengajar di-load via [JadwalCacheService] yang otomatis fallback
/// ke Hive cache kalau offline atau server timeout. Tidak ada try-catch
/// ke service karena cache service yang handle fallback.
class DosenDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalMengajar =
      ValueNotifier([]);
  final ValueNotifier<int> mahasiswaHadir = ValueNotifier(0);
  final ValueNotifier<int> totalMahasiswa = ValueNotifier(0);
  final ValueNotifier<int> izinPending = ValueNotifier(0);

  bool _isDisposed = false;

  Future<void> loadData(User user) async {
    if (_isDisposed) return;

    // Statistik masih dummy untuk MVP — bisa di-replace nanti dengan
    // perhitungan dari cache lokal RecordPresensi.
    mahasiswaHadir.value = DummyData.mahasiswaHadirHariIni;
    totalMahasiswa.value = DummyData.totalMahasiswaKelas;
    izinPending.value = DummyData.pengajuanIzinPending;

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
    } catch (e) {
      debugPrint('[DosenDashboardVM] load jadwal error: $e');
      if (_isDisposed) return;
      // Cache service tidak throw — kalau sampai sini, error parsing.
      // Biarkan list lama, jangan kosongkan.
    }
  }

  void dispose() {
    _isDisposed = true;
    jadwalMengajar.dispose();
    mahasiswaHadir.dispose();
    totalMahasiswa.dispose();
    izinPending.dispose();
  }
}
