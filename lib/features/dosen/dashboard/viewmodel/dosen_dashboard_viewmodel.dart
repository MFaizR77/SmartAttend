import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel dashboard dosen.
/// Load data jadwal mengajar dan statistik kehadiran.
class DosenDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalMengajar =
      ValueNotifier([]);
  final ValueNotifier<int> mahasiswaHadir = ValueNotifier(0);
  final ValueNotifier<int> totalMahasiswa = ValueNotifier(0);
  final ValueNotifier<int> izinPending = ValueNotifier(0);

  bool _isDisposed = false;

  Future<void> loadData(User user) async {
    if (_isDisposed) return;
    mahasiswaHadir.value = DummyData.mahasiswaHadirHariIni;
    totalMahasiswa.value = DummyData.totalMahasiswaKelas;
    izinPending.value = DummyData.pengajuanIzinPending;

    try {
      print('=== DEBUG: DosenDashboardViewModel loadData dipanggil. User ID: ${user.id} ===');
      final jadwalDB = await DatabaseService().getJadwalDosen(user.id);
      print('=== DEBUG: Hasil getJadwalDosen: ${jadwalDB.length} data ===');
      
      final mappedJadwal = jadwalDB.map((doc) {
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['kelas']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
          'tipe': doc['tipe']?.toString() ?? 'Reguler',
        };
      }).toList();

      if (_isDisposed) return;
      jadwalMengajar.value = mappedJadwal;
      
      // Cache jadwal ke Hive untuk mode offline (berbasis hari)
      final hariIni = DateTime.now().weekday;
      final box = HiveHelper.jadwalKuliahBoxInstance;
      await box.put('jadwal_dosen_${user.id}_$hariIni', jsonEncode(mappedJadwal));

    } catch (e) {
      // Jika terjadi error koneksi, ambil dari cache lokal Hive
      final isNetworkError = e.toString().contains('SocketException') || 
                             e.toString().contains('ConnectionException') ||
                             e.toString().contains('HandshakeException');
                             
      if (isNetworkError) {
        final hariIni = DateTime.now().weekday;
        final box = HiveHelper.jadwalKuliahBoxInstance;
        final cachedDataStr = box.get('jadwal_dosen_${user.id}_$hariIni');
        
        if (cachedDataStr != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedDataStr);
            if (_isDisposed) return;
            jadwalMengajar.value = decoded.map((e) => Map<String, String>.from(e)).toList();
            print('=== DEBUG: Berhasil meload jadwal dosen offline dari Hive ===');
          } catch (err) {
            print('Gagal membaca cache jadwal dosen: $err');
          }
        }
      } else {
        print('=== DEBUG Error load jadwal dosen: $e ===');
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    jadwalMengajar.dispose();
    mahasiswaHadir.dispose();
    totalMahasiswa.dispose();
    izinPending.dispose();
  }
}
