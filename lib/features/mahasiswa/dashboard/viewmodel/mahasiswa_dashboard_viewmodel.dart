import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard mahasiswa.
/// Load data jadwal dan statistik.
class MahasiswaDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalHariIni =
      ValueNotifier([]);
  final ValueNotifier<Map<String, int>> statistik = ValueNotifier({});

  Future<void> loadData(User user) async {
    // Load statistik (sementara masih dummy)
    statistik.value = {
      'hadir': DummyData.totalHadir,
      'izin': DummyData.totalIzin,
      'alpha': DummyData.totalAlpha,
      'total': DummyData.totalPertemuan,
    };

    if (user.kelas == null || user.kelas!.isEmpty) return;

    try {
      final jadwalDB = await DatabaseService().getJadwalMahasiswa(user.kelas!);
      
      final mappedJadwal = jadwalDB.map((doc) {
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['tipe']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
        };
      }).toList();

      jadwalHariIni.value = mappedJadwal;
    } catch (e) {
      print('Error load jadwal mahasiswa: \$e');
    }
  }

  void dispose() {
    jadwalHariIni.dispose();
    statistik.dispose();
  }
}
