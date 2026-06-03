import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard Kaprodi.
class KaprodiDashboardViewModel {
  final ValueNotifier<Map<String, List<Map<String, dynamic>>>> jadwalPerHari =
      ValueNotifier({});
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<String> selectedHari = ValueNotifier('Senin');

  final List<String> hariList = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
  ];

  Future<void> loadData(User user) async {
    if (user.program == null || user.program!.isEmpty) {
      errorMessage.value = 'Akun kaprodi tidak punya program.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      print('[KaprodiVM] Loading data for program: ${user.program}');
      final data = await DatabaseService()
          .getJadwalPerHariByProgram(user.program!)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timeout setelah 30 detik');
            },
          );
      print('[KaprodiVM] Data loaded successfully: ${data.keys.length} days');
      jadwalPerHari.value = data;
    } catch (e) {
      print('[KaprodiVM] Error loading data: $e');
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> bukaSesiAbsensi({
    required String jadwalId,
    required String kaprodiId,
  }) async {
    try {
      await DatabaseService().bukakanSesiAbsensi(
        jadwalId: jadwalId,
        kaprodiId: kaprodiId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal membuka sesi: $e';
      return false;
    }
  }

  Future<bool> tutupSesiAbsensi({
    required String laporanId,
    required String kaprodiId,
  }) async {
    try {
      await DatabaseService().tutupkanSesiAbsensi(
        laporanId: laporanId,
        kaprodiId: kaprodiId,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal menutup sesi: $e';
      return false;
    }
  }

  void dispose() {
    jadwalPerHari.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    selectedHari.dispose();
  }
}
