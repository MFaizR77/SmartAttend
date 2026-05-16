import 'package:flutter/foundation.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard Wali Dosen.
class WaliDosenDashboardViewModel {
  final ValueNotifier<List<Map<String, dynamic>>> izinPending = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> izinSemua = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<void> loadData(User user) async {
    if (user.kelasWali == null || user.kelasWali!.isEmpty) {
      errorMessage.value = 'Akun wali dosen tidak punya kelas wali.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: user.kelasWali!,
        program: user.program,
      );
      izinPending.value = pending;

      final semua = await DatabaseService().getAllIzinByKelas(
        kelas: user.kelasWali!,
        program: user.program,
      );
      izinSemua.value = semua;
    } catch (e) {
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> approveIzin({
    required dynamic izinId,
    required String walidosenId,
    String? catatan,
  }) async {
    try {
      await DatabaseService().approveIzinByWali(
        izinId: izinId,
        walidosenId: walidosenId,
        catatan: catatan,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal approve: $e';
      return false;
    }
  }

  Future<bool> rejectIzin({
    required dynamic izinId,
    required String walidosenId,
    String? catatan,
  }) async {
    try {
      await DatabaseService().rejectIzinByWali(
        izinId: izinId,
        walidosenId: walidosenId,
        catatan: catatan,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal reject: $e';
      return false;
    }
  }

  void dispose() {
    izinPending.dispose();
    izinSemua.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
