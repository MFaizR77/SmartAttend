import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';

/// ViewModel dashboard admin.
/// Load statistik, log aktivitas, dan alert dari dummy.
class AdminDashboardViewModel {
  final ValueNotifier<Map<String, dynamic>> statistik = ValueNotifier({});
  final ValueNotifier<List<Map<String, String>>> logAktivitas =
      ValueNotifier([]);

  Future<void> loadData() async {
    statistik.value = {
      'totalMahasiswa': DummyData.totalMahasiswa,
      'totalDosen': DummyData.totalDosen,
      'sesiHariIni': DummyData.sesiHariIni,
      'tingkatKehadiran': DummyData.tingkatKehadiran,
    };
    logAktivitas.value = DummyData.logAktivitas;
  }

  void dispose() {
    statistik.dispose();
    logAktivitas.dispose();
  }
}
