import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';
import '../../../../data/local/models/user.dart';

class RekapDosenViewModel extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _isDisposed = false;
  
  bool isLoading = false;
  String? errorMessage;
  
  // Data dikelompokkan berdasarkan nama mata kuliah / kelas
  // Map<String, List<Map<String, dynamic>>>
  Map<String, List<Map<String, dynamic>>> rekapPerKelas = {};

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadRekap(User dosen) async {
    isLoading = true;
    errorMessage = null;
    if (!_isDisposed) notifyListeners();

    try {
      final data = await _db.getAllLaporanDosen(dosen.id);
      
      // Kelompokkan data berdasarkan mataKuliah / jadwalId
      // Idealnya jadwal_kuliah di-join, tapi asumsikan mataKuliah ada di laporan atau kita ambil info kelasnya
      // Dari kode sebelumnya, laporan_dosen mungkin menyimpan jadwalId. 
      // Untuk tampilan, kita butuh informasi kelas & matkul. 
      // Kita fetch juga seluruh jadwal dosen ini untuk mapping.
      final seluruhJadwal = await _db.getJadwalDosen(dosen.id);
      final Map<String, Map<String, dynamic>> mapJadwal = {};
      for (var j in seluruhJadwal) {
        mapJadwal[j['_id'].toString()] = j;
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      
      for (var laporan in data) {
        final jId = laporan['jadwalId'] as String;
        final jadwalInfo = mapJadwal[jId];
        
        String groupName = jId; // Fallback ke jadwalId langsung (karena format di DB mengandung nama MK & kelas)
        if (jadwalInfo != null) {
          final matkul = jadwalInfo['namaMK'] ?? jadwalInfo['mataKuliah'] ?? 'Mata Kuliah';
          final kelas = jadwalInfo['kelas'] ?? 'Kelas';
          groupName = "$matkul - $kelas";
        }
        
        laporan['namaJadwal'] = groupName;

        if (!grouped.containsKey(groupName)) {
          grouped[groupName] = [];
        }
        grouped[groupName]!.add(laporan);
      }
      
      // Urutkan tiap grup berdasarkan tanggal terbaru
      for (var key in grouped.keys) {
        grouped[key]!.sort((a, b) {
          final t1 = a['tanggal'] as DateTime;
          final t2 = b['tanggal'] as DateTime;
          return t2.compareTo(t1); // Descending
        });
      }

      rekapPerKelas = grouped;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }
}
