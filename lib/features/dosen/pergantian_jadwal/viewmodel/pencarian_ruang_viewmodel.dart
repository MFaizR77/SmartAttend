import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

class PencarianRuangViewModel extends ChangeNotifier {
  String _selectedHari = 'Senin';
  String get selectedHari => _selectedHari;

  String _jamMulai = '08:00';
  String get jamMulai => _jamMulai;

  String _jamSelesai = '10:00';
  String get jamSelesai => _jamSelesai;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _ruanganKosong = [];
  List<String> get ruanganKosong => _ruanganKosong;

  List<Map<String, dynamic>> _daftarJadwal = [];
  List<Map<String, dynamic>> get daftarJadwal => _daftarJadwal;

  Map<String, dynamic>? _selectedJadwal;
  Map<String, dynamic>? get selectedJadwal => _selectedJadwal;

  void setSelectedJadwal(Map<String, dynamic>? jadwal) {
    _selectedJadwal = jadwal;
    if (jadwal != null) {
      _selectedHari = jadwal['hari'] ?? 'Senin';
      _jamMulai = jadwal['jamMulai'] ?? '08:00';
      _jamSelesai = jadwal['jamSelesai'] ?? '10:00';
    }
    notifyListeners();
  }

  Future<void> fetchJadwalDosen(String dosenId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseService();
      final hasil = await db.getSemuaJadwalDosen(dosenId);
      _daftarJadwal = hasil;
    } catch (e) {
      print('Error fetch jadwal dosen: $e');
      _daftarJadwal = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setHari(String hari) {
    _selectedHari = hari;
    notifyListeners();
  }

  void setJamMulai(String jam) {
    _jamMulai = jam;
    notifyListeners();
  }

  void setJamSelesai(String jam) {
    _jamSelesai = jam;
    notifyListeners();
  }

  Future<void> cariRuangan() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseService();
      final abaikanId = _selectedJadwal?['_id']?.toString();
      final hasil = await db.cariRuangKosong(_selectedHari, _jamMulai, _jamSelesai, abaikanJadwalId: abaikanId);
      _ruanganKosong = hasil;
    } catch (e) {
      print('Error cari ruangan: $e');
      _ruanganKosong = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
