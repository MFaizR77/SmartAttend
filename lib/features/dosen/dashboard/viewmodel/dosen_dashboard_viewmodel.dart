import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';

/// ViewModel dashboard dosen.
/// Load data jadwal mengajar dan statistik kehadiran dari dummy.
class DosenDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalMengajar =
      ValueNotifier([]);
  final ValueNotifier<int> mahasiswaHadir = ValueNotifier(0);
  final ValueNotifier<int> totalMahasiswa = ValueNotifier(0);
  final ValueNotifier<int> izinPending = ValueNotifier(0);

  void loadData() {
    jadwalMengajar.value = DummyData.jadwalHariIni;
    mahasiswaHadir.value = DummyData.mahasiswaHadirHariIni;
    totalMahasiswa.value = DummyData.totalMahasiswaKelas;
    izinPending.value = DummyData.pengajuanIzinPending;
  }

  void dispose() {
    jadwalMengajar.dispose();
    mahasiswaHadir.dispose();
    totalMahasiswa.dispose();
    izinPending.dispose();
  }
}
