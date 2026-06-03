import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard admin.
/// Load statistik real dari MongoDB.
class AdminDashboardViewModel {
  final ValueNotifier<Map<String, dynamic>> statistik = ValueNotifier({});
  final ValueNotifier<List<Map<String, String>>> logAktivitas =
      ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final stats = await DatabaseService().getAdminDashboardStats();
      statistik.value = stats;
    } catch (e) {
      print('[AdminDashboardVM] Error loading stats: $e');
      // Fallback ke data kosong
      statistik.value = {
        'totalMahasiswa': 0,
        'totalDosen': 0,
        'sesiHariIni': 0,
        'tingkatKehadiran': '0.0',
      };
    } finally {
      isLoading.value = false;
    }

    // Log aktivitas tetap kosong untuk sekarang (bisa ditambahkan nanti)
    logAktivitas.value = [];
  }

  void dispose() {
    statistik.dispose();
    logAktivitas.dispose();
    isLoading.dispose();
  }
}
