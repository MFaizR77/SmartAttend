import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';

/// ViewModel dashboard mahasiswa.
/// Load data jadwal dan statistik dari dummy.
class MahasiswaDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalHariIni =
      ValueNotifier([]);
  final ValueNotifier<Map<String, int>> statistik = ValueNotifier({});

  void loadData() {
    jadwalHariIni.value = DummyData.jadwalHariIni;
    statistik.value = {
      'hadir': DummyData.totalHadir,
      'izin': DummyData.totalIzin,
      'alpha': DummyData.totalAlpha,
      'total': DummyData.totalPertemuan,
    };
  }

  void dispose() {
    jadwalHariIni.dispose();
    statistik.dispose();
  }
}
