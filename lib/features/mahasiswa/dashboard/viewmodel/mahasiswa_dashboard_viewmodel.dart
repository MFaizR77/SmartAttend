import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../data/local/dummy_data.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';
import '../../../../data/local/hive_helper.dart';

/// ViewModel dashboard mahasiswa.
/// Load data jadwal dan statistik.
class MahasiswaDashboardViewModel {
  final ValueNotifier<List<Map<String, String>>> jadwalHariIni =
      ValueNotifier([]);
  final ValueNotifier<Map<String, int>> statistik = ValueNotifier({});

  Future<void> loadData(User user) async {
    // Load statistik (sementara masih dummy)
    statistik.value = {
      'hadir': DummyData.totalHadir,
      'izin': DummyData.totalIzin,
      'alpha': DummyData.totalAlpha,
      'total': DummyData.totalPertemuan,
    };

    if (user.kelas == null || user.kelas!.isEmpty) return;

    try {
      final jadwalDB = await DatabaseService().getJadwalMahasiswa(user.kelas!);
      
      final mappedJadwal = jadwalDB.map((doc) {
        return {
          'id': doc['_id']?.toString() ?? '',
          'mataKuliah': '${doc['namaMK']} (${doc['tipe']})',
          'jam': '${doc['jamMulai']} - ${doc['jamSelesai']}',
          'ruang': doc['ruangan']?.toString() ?? '-',
        };
      }).toList();

      jadwalHariIni.value = mappedJadwal;

      // Cache jadwal ke Hive untuk mode offline (berbasis hari)
      final hariIni = DateTime.now().weekday;
      final box = HiveHelper.jadwalKuliahBoxInstance;
      await box.put('jadwal_${user.kelas}_$hariIni', jsonEncode(mappedJadwal));

    } catch (e) {
      // Jika terjadi error koneksi, ambil dari cache lokal Hive
      final isNetworkError = e.toString().contains('SocketException') || 
                             e.toString().contains('ConnectionException') ||
                             e.toString().contains('HandshakeException');
                             
      if (isNetworkError) {
        final hariIni = DateTime.now().weekday;
        final box = HiveHelper.jadwalKuliahBoxInstance;
        final cachedDataStr = box.get('jadwal_${user.kelas}_$hariIni');
        
        if (cachedDataStr != null) {
          try {
            final List<dynamic> decoded = jsonDecode(cachedDataStr);
            jadwalHariIni.value = decoded.map((e) => Map<String, String>.from(e)).toList();
          } catch (err) {
            print('Gagal membaca cache jadwal: $err');
          }
        }
      } else {
        print('Error load jadwal mahasiswa: $e');
      }
    }
  }

  void dispose() {
    jadwalHariIni.dispose();
    statistik.dispose();
  }
}
