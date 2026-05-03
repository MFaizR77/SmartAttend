import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

class RekapanLaporanViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _laporanList = [];
  List<Map<String, dynamic>> get laporanList => _laporanList;

  Future<void> loadRekapan(String dosenId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseService();
      // 1. Ambil semua laporan
      final laporans = await db.getSemuaLaporanDosen(dosenId);
      
      // 2. Ambil semua jadwal dosen untuk di-join
      final jadwals = await db.getSemuaJadwalDosen(dosenId);
      
      // Bikin map untuk mempermudah pencarian (gabungan dari namaMK dan jam)
      // Karena jadwalId yang kita save formatnya bisa ObjectId atau String gabungan
      final Map<String, Map<String, dynamic>> jadwalMap = {};
      for (var j in jadwals) {
        // Coba tampung dua-duanya (id objectId dan id string gabungan)
        if (j['_id'] != null) {
          jadwalMap[j['_id'].toString()] = j;
        }
        final stringId = '${j['namaMK']}_${j['jamMulai']} - ${j['jamSelesai']}';
        jadwalMap[stringId] = j;
      }

      // 3. Gabungkan data
      final List<Map<String, dynamic>> mappedList = [];
      for (var lap in laporans) {
        final jId = lap['jadwalId'].toString();
        final jadwal = jadwalMap[jId];

        mappedList.add({
          ...lap,
          'namaMK': jadwal?['namaMK'] ?? 'Mata Kuliah Tidak Dikenal',
          'kelas': jadwal?['kelas'] ?? '-',
          'hari': jadwal?['hari'] ?? '-',
        });
      }

      _laporanList = mappedList;
    } catch (e) {
      print('Error load rekapan: \$e');
      _laporanList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
