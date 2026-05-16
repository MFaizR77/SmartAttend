import 'package:flutter/foundation.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel untuk dosen menindaklanjuti izin yang sudah approved wali.
class TindakLanjutIzinViewModel {
  final ValueNotifier<List<Map<String, dynamic>>> izinList = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<void> load(User dosen) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      izinList.value = await DatabaseService().getIzinTindakLanjutByDosen(dosen.id);
    } catch (e) {
      errorMessage.value = 'Gagal memuat: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> tandai({
    required dynamic izinId,
    required String jadwalId,
    required String dosenKode,
    required String statusFinal,
    String? catatan,
  }) async {
    try {
      await DatabaseService().tandaiStatusFinalIzin(
        izinId: izinId,
        jadwalId: jadwalId,
        dosenKode: dosenKode,
        statusFinal: statusFinal,
        catatan: catatan,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal: $e';
      return false;
    }
  }

  void dispose() {
    izinList.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
