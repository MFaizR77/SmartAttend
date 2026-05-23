import 'package:flutter/foundation.dart';

import '../../data/local/hive_helper.dart';
import '../../data/local/models/sesi_absensi.dart';
import '../../data/remote/database_service.dart';
import 'connectivity_service.dart';

/// Status kelas dilihat dari sisi mahasiswa, evaluated lokal-first.
enum SessionState {
  /// Belum waktunya — sebelum jamMulai - 15 menit.
  beforeWindow,

  /// Dosen sudah menekan "Mulai Kuliah" — boleh absen dengan metode 'manual'.
  open,

  /// Belum ada record dosen, tapi grace period (15 menit setelah jamMulai)
  /// sudah lewat — boleh absen dengan metode 'auto'.
  autoOpen,

  /// Antara jamMulai - 15 menit dan jamMulai + 15 menit, dosen belum buka.
  /// Mahasiswa diminta menunggu.
  waitingDosen,

  /// Sesi sudah di-close oleh dosen.
  closed,

  /// Lewat jamSelesai dan tidak pernah dibuka.
  expired,
}

/// Hasil evaluasi state untuk satu jadwal pada hari ini.
class SessionStatus {
  final SessionState state;

  /// Apakah mahasiswa boleh absen sekarang.
  bool get canCheckIn =>
      state == SessionState.open || state == SessionState.autoOpen;

  /// Metode yang akan tercatat di RecordPresensi.
  String get checkInMetode => state == SessionState.autoOpen ? 'auto' : 'manual';

  /// Pesan untuk UI.
  final String message;

  const SessionStatus(this.state, this.message);
}

/// Service yang menentukan apakah suatu jadwal "sedang berjalan" dengan
/// **strategi C (hybrid)**:
///   1. Cek cache lokal `SesiAbsensi` Hive box — kalau dosen sudah buka
///      (status 'open'/'auto'), langsung return open.
///   2. Kalau ada koneksi, cek Mongo `laporan_dosen` (sumber kebenaran).
///      Hasilnya di-cache ke Hive untuk pengecekan offline berikutnya.
///   3. Fallback time-window: kalau sekarang ≥ jamMulai + 15 menit dan
///      < jamSelesai, anggap auto-open. Ini memungkinkan mahasiswa absen
///      walau dosen sama-sekali tidak online (UC-10).
///   4. Antara jamMulai - 15 menit dan jamMulai + 15 menit → "menunggu dosen".
///   5. Sebelum window → "belum waktunya".
class SessionStateService {
  static const Duration graceBeforeStart = Duration(minutes: 15);
  static const Duration autoOpenAfter = Duration(minutes: 15);

  static final SessionStateService _instance = SessionStateService._internal();
  factory SessionStateService() => _instance;
  SessionStateService._internal();

  /// Evaluasi status sesi untuk jadwal ini pada hari ini.
  ///
  /// [jadwalId] — composite ID di `jadwal_kuliah`.
  /// [jamMulai] / [jamSelesai] — format "HH:MM" dari dokumen jadwal.
  /// [tanggal] — biasanya `DateTime.now()`. Bisa diinjeksi untuk testing.
  Future<SessionStatus> evaluate({
    required String jadwalId,
    required String jamMulai,
    required String jamSelesai,
    DateTime? tanggal,
  }) async {
    final now = tanggal ?? DateTime.now();

    final mulai = _parseJam(now, jamMulai);
    final selesai = _parseJam(now, jamSelesai);
    if (mulai == null || selesai == null) {
      return const SessionStatus(
        SessionState.beforeWindow,
        'Format jam jadwal tidak valid.',
      );
    }

    final earliestCheckIn = mulai.subtract(graceBeforeStart);
    final autoOpenTime = mulai.add(autoOpenAfter);

    // 1. Cek cache lokal dulu (offline-first)
    final cachedSesi = _findCachedSesi(jadwalId, now);
    if (cachedSesi != null) {
      if (cachedSesi.status == 'closed') {
        return SessionStatus(
          SessionState.closed,
          'Sesi sudah ditutup oleh dosen.',
        );
      }
      if (cachedSesi.status == 'open' || cachedSesi.status == 'auto') {
        if (now.isAfter(selesai)) {
          return SessionStatus(
            SessionState.expired,
            'Jadwal kelas sudah selesai.',
          );
        }
        return SessionStatus(
          cachedSesi.status == 'auto'
              ? SessionState.autoOpen
              : SessionState.open,
          'Kelas sedang berjalan.',
        );
      }
    }

    // 2. Refresh dari server kalau online (dan update cache).
    if (ConnectivityService().isOnline.value) {
      try {
        final buka = await DatabaseService().isKelasBerjalan(jadwalId);
        if (buka) {
          await _writeCache(jadwalId, status: 'open');
          if (now.isAfter(selesai)) {
            return SessionStatus(
              SessionState.expired,
              'Jadwal kelas sudah selesai.',
            );
          }
          return const SessionStatus(
            SessionState.open,
            'Kelas sedang berjalan.',
          );
        }
        // Catatan: kalau buka == false bisa berarti dosen belum mulai ATAU
        // sudah selesai. `isKelasBerjalan` di DatabaseService return false
        // di kedua kasus. Lanjut ke logika time-window.
      } catch (e) {
        debugPrint('[SessionState] gagal cek isKelasBerjalan: $e');
        // Diam-diam fallback ke time-window.
      }
    }

    // 3. Time window logic
    if (now.isBefore(earliestCheckIn)) {
      return SessionStatus(
        SessionState.beforeWindow,
        'Belum waktunya absen. Bisa absen mulai ${_fmtTime(earliestCheckIn)}.',
      );
    }
    if (now.isAfter(selesai)) {
      return const SessionStatus(
        SessionState.expired,
        'Jadwal kelas sudah selesai.',
      );
    }
    if (now.isBefore(autoOpenTime)) {
      return SessionStatus(
        SessionState.waitingDosen,
        'Menunggu dosen membuka sesi (auto-open ${_fmtTime(autoOpenTime)}).',
      );
    }
    // ≥ jamMulai + 15 menit & < jamSelesai → auto-open.
    await _writeCache(jadwalId, status: 'auto');
    return const SessionStatus(
      SessionState.autoOpen,
      'Sesi auto-open. Anda boleh absen.',
    );
  }

  /// Dipanggil dari sisi dosen ketika menekan "Mulai Kuliah".
  /// Update cache lokal supaya UI mahasiswa di device ini juga langsung tahu.
  Future<void> markOpenedLocally(String jadwalId) async {
    await _writeCache(jadwalId, status: 'open');
  }

  /// Dipanggil dari sisi dosen ketika menekan "Selesai Kuliah".
  Future<void> markClosedLocally(String jadwalId) async {
    await _writeCache(jadwalId, status: 'closed');
  }

  // ─────────────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────────────

  SesiAbsensi? _findCachedSesi(String jadwalId, DateTime now) {
    final box = HiveHelper.sesiAbsensiBoxInstance;
    for (final s in box.values) {
      if (s.jadwalId != jadwalId) continue;
      if (!_isSameDay(s.tanggal, now)) continue;
      return s;
    }
    return null;
  }

  Future<void> _writeCache(String jadwalId, {required String status}) async {
    final box = HiveHelper.sesiAbsensiBoxInstance;
    final now = DateTime.now();
    final existing = _findCachedSesi(jadwalId, now);

    final updated = SesiAbsensi(
      id: existing?.id,
      sesiId: existing?.sesiId ?? '${jadwalId}_${_dateKey(now)}',
      jadwalId: jadwalId,
      tanggal: existing?.tanggal ?? DateTime(now.year, now.month, now.day),
      status: status,
      dibukaOleh: existing?.dibukaOleh ?? (status == 'auto' ? 'system' : null),
      openedAt: existing?.openedAt ?? (status == 'open' || status == 'auto' ? now : null),
      closedAt: status == 'closed' ? now : existing?.closedAt,
      syncStatus: 'synced', // cache server-truth, tidak perlu sync balik
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final key = updated.sesiId;
    await box.put(key, updated);
  }

  DateTime? _parseJam(DateTime base, String jamStr) {
    final cleaned = jamStr.replaceAll('.', ':').trim();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(cleaned);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mn = int.tryParse(m.group(2)!);
    if (h == null || mn == null) return null;
    return DateTime(base.year, base.month, base.day, h, mn);
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateKey(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
