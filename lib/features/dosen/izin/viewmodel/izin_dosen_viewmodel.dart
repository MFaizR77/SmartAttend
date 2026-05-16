import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

class IzinDosenViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  bool isLoading = false;
  String? errorMessage;
  List<Map<String, dynamic>> jadwalHariIni = [];
  List<Map<String, dynamic>> riwayatIzin = [];

  /// Ambil jadwal dosen berdasarkan hari sesuai tanggal yang dipilih
  Future<void> loadJadwalByTanggal(String dosenId, DateTime tanggal) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      jadwalHariIni = await _db.getJadwalDosenByHari(dosenId, tanggal);
    } catch (e) {
      errorMessage = e.toString();
      jadwalHariIni = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Submit pengajuan izin/sakit dosen ke MongoDB
  Future<bool> submitIzin({
    required String dosenId,
    required DateTime tanggal,
    required Map<String, dynamic> jadwal,
    required String jenis, // 'izin' atau 'sakit'
    String? keterangan,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.submitIzinDosen({
        'dosenId': dosenId,
        'tanggal': tanggal.toIso8601String(),
        'jadwalId': jadwal['_id']?.toString() ?? '',
        'namaMK': jadwal['namaMK'] ?? '',
        'kelas': jadwal['kelas'] ?? '',
        'jamMulai': jadwal['jamMulai'] ?? '',
        'jamSelesai': jadwal['jamSelesai'] ?? '',
        'jenis': jenis,
        'keterangan': keterangan ?? '',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
