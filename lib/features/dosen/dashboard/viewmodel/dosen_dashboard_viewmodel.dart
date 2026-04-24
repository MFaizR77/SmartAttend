import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard dosen.
/// Load data jadwal mengajar dan statistik kehadiran.
class DosenDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalMengajar =
      ValueNotifier([]);
  final ValueNotifier<int> mahasiswaHadir = ValueNotifier(0);
  final ValueNotifier<int> totalMahasiswa = ValueNotifier(0);
  final ValueNotifier<int> izinPending = ValueNotifier(0);

  Future<void> loadData(User user) async {
    mahasiswaHadir.value = DummyData.mahasiswaHadirHariIni;
    totalMahasiswa.value = DummyData.totalMahasiswaKelas;
    izinPending.value = DummyData.pengajuanIzinPending;

    try {
      print('=== DEBUG: DosenDashboardViewModel loadData dipanggil. User ID: ${user.id} ===');
      final jadwalDB = await DatabaseService().getJadwalDosen(user.id);
      print('=== DEBUG: Hasil getJadwalDosen: ${jadwalDB.length} data ===');
      
      final mappedJadwal = jadwalDB.map((doc) {
        return {
          'mataKuliah': '${doc['namaMK']} (${doc['kelas']} - ${doc['tipe']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
        };
      }).toList();

      jadwalMengajar.value = mappedJadwal;
    } catch (e) {
      print('=== DEBUG Error load jadwal dosen: $e ===');
    }
  }

  void dispose() {
    jadwalMengajar.dispose();
    mahasiswaHadir.dispose();
    totalMahasiswa.dispose();
    izinPending.dispose();
  }
}
