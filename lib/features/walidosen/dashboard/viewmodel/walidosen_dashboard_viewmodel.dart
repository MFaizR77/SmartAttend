import 'package:flutter/foundation.dart';
import '../../../../core/services/fcm_sender_service.dart';
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

      // Kirim notifikasi ke dosen yang terdampak (best-effort)
      _tryNotifyDosen(izinId: izinId);

      return true;
    } catch (e) {
      errorMessage.value = 'Gagal approve: $e';
      return false;
    }
  }

  /// Kirim notifikasi ke dosen setelah walidosen approve izin.
  Future<void> _tryNotifyDosen({required dynamic izinId}) async {
    try {
      final db = DatabaseService();

      // Ambil data izin yang baru di-approve
      final izinDoc = await db.getIzinById(izinId);
      if (izinDoc == null) return;

      final namaMahasiswa = izinDoc['namaMahasiswa']?.toString() ?? 'Mahasiswa';
      final jenis = izinDoc['jenis']?.toString() ?? 'izin';
      final tanggalIzin = izinDoc['tanggalIzin'];
      final tanggal = tanggalIzin is DateTime
          ? '${tanggalIzin.day}/${tanggalIzin.month}/${tanggalIzin.year}'
          : tanggalIzin?.toString() ?? '';

      // Extract semua dosenId dari tindakLanjutDosen
      final tindakLanjut = izinDoc['tindakLanjutDosen'];
      if (tindakLanjut is! List) return;

      final dosenIds = tindakLanjut
          .map((t) => t['dosenId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (dosenIds.isEmpty) return;

      final tokens = await db.getFcmTokensByUserIds(dosenIds);
      if (tokens.isEmpty) return;

      final sent = await FCMSenderService().sendNotificationToTokens(
        tokens: tokens,
        title: 'Izin Mahasiswa Perlu Ditindaklanjuti',
        body: '$namaMahasiswa - $jenis tanggal $tanggal, silakan tindaklanjuti',
        data: {
          'type': 'izin_approved',
          'izinId': izinId.toString(),
        },
      );
      debugPrint('[FCM] Notifikasi izin terkirim ke dosen: $sent/${tokens.length}');
    } catch (e) {
      debugPrint('[FCM] Gagal notifikasi dosen: $e');
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
