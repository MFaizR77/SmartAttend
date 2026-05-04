import 'package:flutter/foundation.dart';
import '../../../../../data/remote/database_service.dart';
import 'package:intl/intl.dart';

class PergantianJadwalViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  bool isLoading = false;
  String? errorMessage;
  
  List<Map<String, dynamic>> riwayatPengajuan = [];
  List<Map<String, dynamic>> daftarJadwalAsli = [];
  List<Map<String, dynamic>> daftarRuangan = [];
  
  Future<void> loadRiwayat(String dosenId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      riwayatPengajuan = await _db.getPengajuanDosen(dosenId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJadwalAsli(String dosenId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      daftarJadwalAsli = await _db.getAllJadwalDosen(dosenId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cariRuangan(DateTime tanggal, String jamMulai, String jamSelesai) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      daftarRuangan = await _db.getRuanganTersedia(tanggal, jamMulai, jamSelesai);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> ajukan(String dosenId, Map<String, dynamic> jadwalAsli, DateTime tanggalPengganti, String jamMulai, String jamSelesai, String ruangan) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _db.ajukanGantiJadwal({
        'dosenId': dosenId,
        'jadwalIdAsli': jadwalAsli['jadwalId'],
        'namaMK': jadwalAsli['namaMK'],
        'kelas': jadwalAsli['kelas'],
        'tanggalPengganti': tanggalPengganti,
        'jamMulaiPengganti': jamMulai,
        'jamSelesaiPengganti': jamSelesai,
        'ruanganPengganti': ruangan,
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
}
