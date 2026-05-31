import 'package:flutter/material.dart';
import '../../../../data/remote/database_service.dart';

class RekapAdminViewModel extends ChangeNotifier {
  final _db = DatabaseService();

  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> daftarJadwal = [];
  List<Map<String, dynamic>> daftarRekap = [];
  Map<String, dynamic>? selectedJadwal;

  String filterTipe = 'mahasiswa'; // 'mahasiswa' atau 'dosen'

  Future<void> loadJadwal() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      daftarJadwal = await _db.getAllJadwalAdmin();
      // debug: print jumlah jadwal yang di-load
      print('[DBG] RekapAdminViewModel.loadJadwal -> ${daftarJadwal.length} jadwal loaded');
    } catch (e) {
      errorMessage = 'Gagal load jadwal: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRekap(String jadwalId) async {
    isLoading = true;
    errorMessage = null;
    final jadwalMatches = daftarJadwal
        .where((j) => j['_id']?.toString() == jadwalId)
        .toList();
    selectedJadwal = jadwalMatches.isNotEmpty ? jadwalMatches.first : null;
    notifyListeners();
    try {
      if (filterTipe == 'dosen') {
        // for dosen, the DB returns a different structure
        final dRecap = await _db.getRekapKehadiranDosen(jadwalId);
        // normalize to daftarRekap list-of-maps for UI; keep fields as-is
        daftarRekap = dRecap.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        daftarRekap = await _db.getRekapKehadiranAdmin(jadwalId);
      }
      print('[DBG] RekapAdminViewModel.loadRekap($jadwalId) -> ${daftarRekap.length} rekap entries');
    } catch (e) {
      errorMessage = 'Gagal load rekap: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String tipe) {
    filterTipe = tipe;
    notifyListeners();
  }
}