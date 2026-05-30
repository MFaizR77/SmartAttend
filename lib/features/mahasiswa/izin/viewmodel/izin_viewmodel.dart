import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/jadwal_cache_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/pengajuan_izin.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel pengajuan izin/sakit oleh mahasiswa — **offline-first**.
///
/// Strategi:
/// - **Submit**: tulis ke Hive `pengajuanIzin` box (status `pending`),
///   lalu trigger SyncManager. Kalau online, sync langsung jalan dan
///   field `syncStatus` jadi `synced`. Kalau offline, akan otomatis
///   ter-sync saat koneksi balik.
/// - **Riwayat**: gabungkan data dari Hive (yang masih `pending` /
///   baru di-submit) dengan data dari server (yang sudah disimpan).
///   Saat offline, hanya tampilkan dari Hive.
class IzinViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<List<Map<String, dynamic>>> riwayat = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> jadwalTerdampakPreview =
      ValueNotifier([]);

  /// Hitung jadwal yang akan ter-skip pada `tanggal` untuk mahasiswa.
  /// Pakai cache offline-first.
  Future<void> previewJadwalTerdampak({
    required User user,
    required DateTime tanggal,
  }) async {
    if (user.kelas == null) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final all = await JadwalCacheService().getSemuaJadwal(user.id);
      final hari = _hariDari(tanggal);
      jadwalTerdampakPreview.value =
          all.where((j) => j['hari']?.toString() == hari).toList();
    } catch (e) {
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

  /// Submit izin — offline-first.
  /// Selalu tulis ke Hive dulu, lalu trigger sync di background.
  ///
  /// [selectedJadwalIds] — kalau `null`, izin berlaku untuk SEMUA jadwal di
  /// tanggal tsb (izin penuh, perilaku lama). Kalau diisi, hanya jadwal yang
  /// ID-nya ada di list yang diizinkan (izin sebagian). Matkul lain di hari
  /// itu tetap wajib presensi.
  Future<bool> submitIzin({
    required User user,
    required DateTime tanggalIzin,
    required String jenis, // 'izin' | 'sakit'
    required String keterangan,
    String? fotoPath,
    String? fotoUrl,
    List<String>? selectedJadwalIds,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Pastikan preview ada untuk tanggal ini.
      await previewJadwalTerdampak(user: user, tanggal: tanggalIzin);

      // Filter jadwal sesuai pilihan. Kalau selectedJadwalIds null → semua.
      final semuaJadwal = jadwalTerdampakPreview.value;
      final List<Map<String, dynamic>> jadwalDipilih;
      if (selectedJadwalIds == null) {
        jadwalDipilih = semuaJadwal;
      } else {
        final selectedSet = selectedJadwalIds.toSet();
        jadwalDipilih = semuaJadwal
            .where((j) => selectedSet.contains(j['_id']?.toString() ?? ''))
            .toList();
      }

      // Guard: minimal 1 jadwal harus terpilih (izin tanpa matkul tidak valid).
      if (jadwalDipilih.isEmpty) {
        errorMessage.value =
            'Pilih minimal satu mata kuliah yang ingin diizinkan.';
        return false;
      }

      final jadwalIds = jadwalDipilih
          .map((j) => j['_id']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      // Cakupan: 'penuh' kalau semua jadwal hari itu diizinkan, 'sebagian'
      // kalau hanya sebagian. Dipakai untuk label di UI & audit.
      final cakupan =
          jadwalDipilih.length >= semuaJadwal.length ? 'penuh' : 'sebagian';

      // Build tindakLanjutDosen (1 entry per dosen yg ngajar slot).
      final tindakLanjut = <Map<String, dynamic>>[];
      for (final j in jadwalDipilih) {
        final jadwalId = j['_id']?.toString();
        if (jadwalId == null) continue;
        final dosenList = <String>{};
        if (j['dosenIds'] is List) {
          for (final d in j['dosenIds'] as List) {
            final s = d?.toString() ?? '';
            if (s.isNotEmpty) dosenList.add(s);
          }
        }
        if (dosenList.isEmpty) {
          final single = j['kodeDosen']?.toString() ??
              j['dosenId']?.toString() ?? '';
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

      // 1. Tulis ke Hive.
      final clientUuid = const Uuid().v4();
      final izin = PengajuanIzin(
        clientUuid: clientUuid,
        mahasiswaId: user.id,
        sesiId: '',
        jenis: jenis,
        keterangan: keterangan,
        fotoPath: fotoPath,
        fotoUrl: fotoUrl,
      );

      // Karena PengajuanIzin model belum punya semua field workflow (kelas,
      // program, jadwalIdsTerdampak, tanggalIzin), kita simpan supplemental
      // ke `userBox` keyed by clientUuid, dan SyncManager pakai itu saat push.
      // Agar simple di MVP, kita persist Map lengkap ke Hive dynamic box dan
      // panggil submitIzinMahasiswa langsung kalau online — kalau offline,
      // simpan supplemental untuk dikirim nanti.
      await HiveHelper.pengajuanIzinBoxInstance.put(clientUuid, izin);

      // Supplemental data (field yang tidak ada di model PengajuanIzin lokal).
      // Tanggal disimpan sebagai UTC midnight (date-only) lalu di-encode ke ISO
      // dengan suffix 'Z' agar konsisten dengan apa yang dikirim ke server,
      // sehingga round-trip Mongo BSON tidak menggeser tanggal.
      final tanggalUtc = DateTime.utc(
        tanggalIzin.year,
        tanggalIzin.month,
        tanggalIzin.day,
      );
      await HiveHelper.userBoxInstance.put(
        'izin_extra_$clientUuid',
        {
          'clientUuid': clientUuid,
          'namaMahasiswa': user.nama,
          'kelas': user.kelas,
          'program': user.program,
          'tanggalIzin': tanggalUtc.toIso8601String(),
          'jadwalIdsTerdampak': jadwalIds,
          'tindakLanjutDosen': tindakLanjut,
          'cakupan': cakupan,
        },
      );

      // 2. Coba push langsung kalau online.
      if (ConnectivityService().isOnline.value) {
        try {
          await DatabaseService().submitIzinMahasiswa({
            'clientUuid': clientUuid,
            'mahasiswaId': user.id,
            'namaMahasiswa': user.nama,
            'kelas': user.kelas,
            'program': user.program,
            // Normalisasi ke UTC midnight (date-only) supaya tidak digeser
            // timezone saat round-trip Mongo BSON ↔ DateTime.
            'tanggalIzin': DateTime.utc(
              tanggalIzin.year,
              tanggalIzin.month,
              tanggalIzin.day,
            ),
            'jenis': jenis,
            'keterangan': keterangan,
            'fotoPath': fotoPath,
            'fotoUrl': fotoUrl,
            'jadwalIdsTerdampak': jadwalIds,
            'tindakLanjutDosen': tindakLanjut,
            'cakupan': cakupan,
            'status': 'pending_wali',
          });
          // Mark synced.
          await HiveHelper.pengajuanIzinBoxInstance
              .put(clientUuid, izin.markAsSynced());
        } catch (e) {
          debugPrint('[IzinVM] online submit gagal, akan disync nanti: $e');
          // Tetap return true — data sudah di Hive, akan ter-sync nanti.
          // ignore: discarded_futures
          SyncManager().syncAll();
        }
      } else {
        // Offline — biarkan SyncManager handle saat online.
      }

      return true;
    } catch (e) {
      errorMessage.value = 'Gagal submit izin: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Riwayat = gabungan data lokal (offline pending) + server.
  Future<void> loadRiwayat(User user) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      // Lokal — tampilkan semua izin yang dibuat di device ini.
      final localIzin = HiveHelper.pengajuanIzinBoxInstance.values
          .where((i) => i.mahasiswaId == user.id)
          .toList();
      final localMaps = localIzin.map((i) {
        final extra = HiveHelper.userBoxInstance
            .get('izin_extra_${i.clientUuid}');
        final extraMap = extra is Map
            ? Map<String, dynamic>.from(extra)
            : <String, dynamic>{};
        return <String, dynamic>{
          'clientUuid': i.clientUuid,
          'mahasiswaId': i.mahasiswaId,
          'namaMahasiswa': extraMap['namaMahasiswa'] ?? user.nama,
          'kelas': extraMap['kelas'],
          'program': extraMap['program'],
          'tanggalIzin': extraMap['tanggalIzin'],
          'jenis': i.jenis,
          'keterangan': i.keterangan,
          'fotoPath': i.fotoPath,
          'fotoUrl': i.fotoUrl,
          'jadwalIdsTerdampak': extraMap['jadwalIdsTerdampak'] ?? const [],
          'tindakLanjutDosen': extraMap['tindakLanjutDosen'] ?? const [],
          'cakupan': extraMap['cakupan'],
          'status': i.statusApproval == 'pending'
              ? 'pending_wali'
              : i.statusApproval,
          'createdAt': i.createdAt.toIso8601String(),
          'updatedAt': i.updatedAt.toIso8601String(),
          '_isLocal': true,
          '_syncStatus': i.syncStatus,
        };
      }).toList();

      List<Map<String, dynamic>> remote = const [];
      if (ConnectivityService().isOnline.value) {
        try {
          remote = await DatabaseService().getIzinByMahasiswa(user.id);
        } catch (e) {
          debugPrint('[IzinVM] load riwayat server gagal: $e');
        }
      }

      // Merge: server adalah sumber kebenaran untuk **status & approval**,
      // tapi metadata jadwal (jadwalIdsTerdampak, tindakLanjutDosen yang
      // berisi namaMK/jam/dosen) dipertahankan dari local extras kalau
      // server doc tidak punya — defensive terhadap dokumen lama yang
      // tersinkron saat extras belum ikut dikirim.
      final byUuid = <String, Map<String, dynamic>>{};
      for (final m in localMaps) {
        final k = m['clientUuid']?.toString() ?? '';
        if (k.isNotEmpty) byUuid[k] = m;
      }
      for (final m in remote) {
        final k = m['clientUuid']?.toString() ?? '';
        if (k.isEmpty) continue;
        final localCopy = byUuid[k];
        if (localCopy == null) {
          byUuid[k] = m;
        } else {
          // Mulai dari server (untuk status terbaru), lalu fill missing field
          // dari local (mis. jadwalIdsTerdampak yang tidak ikut sync).
          final merged = Map<String, dynamic>.from(m);
          for (final entry in localCopy.entries) {
            final serverVal = merged[entry.key];
            final localVal = entry.value;
            final serverEmpty = serverVal == null ||
                (serverVal is List && serverVal.isEmpty) ||
                (serverVal is String && serverVal.isEmpty);
            if (serverEmpty && localVal != null) {
              merged[entry.key] = localVal;
            }
          }
          byUuid[k] = merged;
        }
      }
      final merged = byUuid.values.toList();

      // Sort terbaru duluan.
      merged.sort((a, b) {
        final ta = a['createdAt'] is DateTime
            ? a['createdAt'] as DateTime
            : DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
        final tb = b['createdAt'] is DateTime
            ? b['createdAt'] as DateTime
            : DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
      riwayat.value = merged;
    } catch (e) {
      errorMessage.value = 'Gagal memuat riwayat: $e';
    } finally {
      isLoading.value = false;
    }
  }

  String _hariDari(DateTime tanggal) {
    switch (tanggal.weekday) {
      case DateTime.monday: return 'Senin';
      case DateTime.tuesday: return 'Selasa';
      case DateTime.wednesday: return 'Rabu';
      case DateTime.thursday: return 'Kamis';
      case DateTime.friday: return 'Jumat';
      case DateTime.saturday: return 'Sabtu';
      case DateTime.sunday: return 'Minggu';
      default: return 'Senin';
    }
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    riwayat.dispose();
    jadwalTerdampakPreview.dispose();
  }
}
