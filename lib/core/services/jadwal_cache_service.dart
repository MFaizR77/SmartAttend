import 'package:flutter/foundation.dart';

import '../../data/local/hive_helper.dart';
import '../../data/local/models/jadwal_kuliah.dart';
import '../../data/remote/database_service.dart';
import 'connectivity_service.dart';

/// Wrapper offline-first untuk jadwal mahasiswa.
///
/// **Strategi**:
/// - Saat online: fetch dari Mongo, simpan typed `JadwalKuliah` ke Hive,
///   simpan list `jadwalIds` enrollments per mahasiswa ke Hive box terpisah.
/// - Saat offline: rekonstruksi list jadwal dari cache lokal.
///
/// Sumber kebenaran tetap MongoDB. Cache di-refresh setiap kali fetch online
/// berhasil. Tidak ada TTL — selama mahasiswa belum buka app online lagi,
/// cache lama akan terus dipakai.
class JadwalCacheService {
  static final JadwalCacheService _instance = JadwalCacheService._internal();
  factory JadwalCacheService() => _instance;
  JadwalCacheService._internal();

  // ─────────────────────────────────────────────────────
  // PUBLIC API — Mahasiswa
  // ─────────────────────────────────────────────────────

  /// Jadwal mahasiswa untuk HARI INI (hari current weekday).
  /// Offline-first: coba server kalau online, fallback ke cache, return [].
  Future<List<Map<String, dynamic>>> getJadwalHariIni(String mahasiswaId) async {
    final hari = _hariIni();
    return _getFiltered(mahasiswaId, hari: hari);
  }

  /// Semua jadwal mahasiswa di periode aktif (semua hari).
  Future<List<Map<String, dynamic>>> getSemuaJadwal(String mahasiswaId) async {
    return _getFiltered(mahasiswaId, hari: null);
  }

  /// Force refresh dari server. Tidak fail kalau offline — sukses kalau berhasil
  /// fetch & cache, false kalau tidak.
  Future<bool> refreshFromServer(String mahasiswaId) async {
    if (!ConnectivityService().isOnline.value) return false;
    try {
      // Refresh enrollments + jadwal sekaligus.
      final ids = await DatabaseService().getEnrolledJadwalIds(mahasiswaId);
      await _writeEnrollmentsCache(mahasiswaId, ids);

      final remote = await DatabaseService().getSemuaJadwalMahasiswa(mahasiswaId);
      await _writeJadwalCache(remote);
      return true;
    } catch (e) {
      debugPrint('[JadwalCache] refreshFromServer error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────
  // PUBLIC API — Dosen
  // ─────────────────────────────────────────────────────

  /// Jadwal mengajar dosen untuk HARI INI.
  /// Offline-first: coba server kalau online, fallback ke cache lokal.
  Future<List<Map<String, dynamic>>> getJadwalDosenHariIni(String dosenId) async {
    return _getDosenFiltered(dosenId, hari: _hariIni());
  }

  /// Semua jadwal mengajar dosen (semua hari).
  Future<List<Map<String, dynamic>>> getSemuaJadwalDosen(String dosenId) async {
    return _getDosenFiltered(dosenId, hari: null);
  }

  // ─────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getFiltered(
    String mahasiswaId, {
    required String? hari,
  }) async {
    // 1. Coba server kalau online.
    if (ConnectivityService().isOnline.value) {
      try {
        final remote = hari == null
            ? await DatabaseService().getSemuaJadwalMahasiswa(mahasiswaId)
            : await DatabaseService().getJadwalMahasiswa(mahasiswaId);
        // Cache jadwal yang baru diterima + enrollments.
        await _writeJadwalCache(remote);
        // Cache enrollments (best-effort — boleh gagal silent).
        try {
          final ids = await DatabaseService().getEnrolledJadwalIds(mahasiswaId);
          await _writeEnrollmentsCache(mahasiswaId, ids);
        } catch (_) {}
        return remote;
      } catch (e) {
        debugPrint('[JadwalCache] server fetch failed, fallback cache: $e');
        // Lanjut ke cache.
      }
    }

    // 2. Fallback ke cache lokal.
    final ids = _readEnrollmentsCache(mahasiswaId);
    if (ids.isEmpty) return const [];

    final box = HiveHelper.jadwalKuliahTypedBoxInstance;
    final result = <JadwalKuliah>[];
    for (final id in ids) {
      final j = box.get(id);
      if (j == null) continue;
      if (!j.isActive) continue;
      if (hari != null && j.hari != hari) continue;
      result.add(j);
    }
    result.sort((a, b) {
      const urut = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final iA = urut.indexOf(a.hari);
      final iB = urut.indexOf(b.hari);
      if (iA != iB) return iA.compareTo(iB);
      return a.jamMulai.compareTo(b.jamMulai);
    });
    return result.map((j) => j.toDisplayMap()).toList();
  }

  Future<void> _writeJadwalCache(List<Map<String, dynamic>> remote) async {
    final box = HiveHelper.jadwalKuliahTypedBoxInstance;
    for (final doc in remote) {
      try {
        final j = JadwalKuliah.fromMap(doc);
        if (j.id.isEmpty) continue;
        await box.put(j.id, j);
      } catch (e) {
        debugPrint('[JadwalCache] failed cache one doc: $e');
      }
    }
  }

  // ─────────────────────────────────────────────────────
  // DOSEN — internal
  // ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getDosenFiltered(
    String dosenId, {
    required String? hari,
  }) async {
    // 1. Coba server kalau online.
    if (ConnectivityService().isOnline.value) {
      try {
        final remote = hari == null
            ? await DatabaseService().getAllJadwalDosen(dosenId)
            : await DatabaseService().getJadwalDosen(dosenId);
        await _writeJadwalCache(remote);
        return remote;
      } catch (e) {
        debugPrint('[JadwalCache-Dosen] server fetch failed, fallback cache: $e');
      }
    }

    // 2. Fallback ke cache: scan typed box untuk jadwal yg dosenIds-nya
    //    mengandung dosen ini. Tidak butuh koleksi mapping terpisah karena
    //    list-nya kecil (jadwal kampus 1 periode).
    final box = HiveHelper.jadwalKuliahTypedBoxInstance;
    final result = <JadwalKuliah>[];
    for (final j in box.values) {
      if (!j.isActive) continue;
      if (!j.dosenIds.contains(dosenId)) continue;
      if (hari != null && j.hari != hari) continue;
      result.add(j);
    }
    result.sort((a, b) {
      const urut = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final iA = urut.indexOf(a.hari);
      final iB = urut.indexOf(b.hari);
      if (iA != iB) return iA.compareTo(iB);
      return a.jamMulai.compareTo(b.jamMulai);
    });
    return result.map((j) => j.toDisplayMap()).toList();
  }

  Future<void> _writeEnrollmentsCache(
    String mahasiswaId,
    List<String> jadwalIds,
  ) async {
    final box = HiveHelper.enrollmentsBoxInstance;
    await box.put(mahasiswaId, {
      'jadwalIds': jadwalIds,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  List<String> _readEnrollmentsCache(String mahasiswaId) {
    final box = HiveHelper.enrollmentsBoxInstance;
    final raw = box.get(mahasiswaId);
    if (raw is! Map) return const [];
    final ids = raw['jadwalIds'];
    if (ids is List) {
      return ids.map((e) => e.toString()).toList();
    }
    return const [];
  }

  String _hariIni() {
    switch (DateTime.now().weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }
}
