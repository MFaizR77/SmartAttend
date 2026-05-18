import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel pengajuan izin/sakit oleh mahasiswa.
class IzinViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<Map<String, dynamic>>> riwayat = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> jadwalTerdampakPreview =
      ValueNotifier([]);

  /// Hitung jadwal yang akan ter-skip pada `tanggal` untuk mahasiswa.
  Future<void> previewJadwalTerdampak({
    required User user,
    required DateTime tanggal,
  }) async {
    if (user.kelas == null) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final all = await DatabaseService().getSemuaJadwalMahasiswa(user.id);
      final hari = DatabaseService().getHariFromDate(tanggal);
      jadwalTerdampakPreview.value =
          all.where((j) => j['hari']?.toString() == hari).toList();
    } catch (e) {
      // Pesan ramah, sembunyikan stack mongo_dart yang panjang
      final msg = e.toString();
      if (msg.contains('ConnectionException') ||
          msg.contains('SocketException') ||
          msg.contains('reset by peer')) {
        errorMessage.value =
            'Koneksi server bermasalah. Periksa internet dan coba lagi.';
      } else {
        errorMessage.value = 'Gagal memuat jadwal.';
      }
      jadwalTerdampakPreview.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit izin. Auto-isi `jadwalIdsTerdampak` dari preview.
  Future<bool> submitIzin({
    required User user,
    required DateTime tanggalIzin,
    required String jenis, // 'izin' | 'sakit'
    required String keterangan,
    String? fotoPath,
    String? fotoUrl,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Pastikan preview sudah ada untuk tanggal ini
      await previewJadwalTerdampak(user: user, tanggal: tanggalIzin);
      final jadwalIds = jadwalTerdampakPreview.value
          .map((j) => j['_id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // Generate tindakLanjutDosen — 1 entry per (jadwalId, dosenKode).
      // Untuk team teaching, satu jadwal bisa punya banyak dosen → tiap dosen
      // dapat row tindak lanjut sendiri.
      final tindakLanjut = <Map<String, dynamic>>[];
      for (final j in jadwalTerdampakPreview.value) {
        final jadwalId = j['_id']?.toString();
        if (jadwalId == null) continue;
        // Kumpulkan dosen-dosen yang ngajar slot ini
        final dosenList = <String>{};
        if (j['dosenIds'] is List) {
          for (final d in j['dosenIds'] as List) {
            final s = d?.toString() ?? '';
            if (s.isNotEmpty) dosenList.add(s);
          }
        }
        if (dosenList.isEmpty) {
          final single = j['kodeDosen']?.toString() ?? j['dosenId']?.toString() ?? '';
          if (single.isNotEmpty) dosenList.add(single);
        }
        for (final dosenKode in dosenList) {
          tindakLanjut.add({
            'jadwalId': jadwalId,
            'dosenId': dosenKode,
            'namaMK': j['namaMK']?.toString(),
            'jamMulai': j['jamMulai']?.toString(),
            'jamSelesai': j['jamSelesai']?.toString(),
            'statusFinal': 'pending',
            'catatanDosen': null,
            'ditandaiPada': null,
          });
        }
      }

      final data = <String, dynamic>{
        'clientUuid': const Uuid().v4(),
        'mahasiswaId': user.id,
        'namaMahasiswa': user.nama,
        'kelas': user.kelas,
        'program': user.program,
        'tanggalIzin': tanggalIzin,
        'jenis': jenis,
        'keterangan': keterangan,
        'fotoPath': fotoPath,
        'fotoUrl': fotoUrl,
        'jadwalIdsTerdampak': jadwalIds,
        'tindakLanjutDosen': tindakLanjut,
        'status': 'pending_wali',
      };
      await DatabaseService().submitIzinMahasiswa(data);
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal submit izin: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRiwayat(User user) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      riwayat.value = await DatabaseService().getIzinByMahasiswa(user.id);
    } catch (e) {
      errorMessage.value = 'Gagal memuat riwayat: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    riwayat.dispose();
    jadwalTerdampakPreview.dispose();
  }
}
