import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../../data/local/hive_helper.dart';
import '../../data/remote/database_service.dart';
import 'connectivity_service.dart';

/// Background pipeline yang push semua entitas `pending` ke MongoDB ketika
/// koneksi tersedia.
///
/// Entitas yang di-handle (urutan penting — dependency dari yang paling root
/// ke yang paling leaf):
///
///   1. `LaporanDosen` (sesi mulai/selesai/materi) —
///      mahasiswa butuh ini untuk `isKelasBerjalan`.
///   2. `RecordPresensi` —
///      ini gantung ke `laporanDosen` (sesiId = jadwalId).
///   3. `PengajuanIzin` —
///      bisa terjadi sebelum atau sesudah dua di atas, tapi kita push
///      paling akhir karena workflow approval-nya server-side.
///
/// Setiap entitas yang berhasil sync diubah field `syncStatus` ke `'synced'`.
/// Yang gagal tetap `pending`, di-retry pada cycle berikutnya.
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySub;

  void init() {
    _connectivitySub?.cancel();
    _connectivitySub = ConnectivityService().onStatusChanged.listen((isOnline) {
      if (isOnline) {
        // Coba sync segera setelah online.
        // ignore: discarded_futures
        syncAll();
      }
    });

    if (ConnectivityService().isOnline.value) {
      // ignore: discarded_futures
      syncAll();
    }
  }

  /// Public entry untuk trigger manual (mis. dari refresh button).
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final laporanCount = await _syncLaporanDosen();
      final presensiCount = await _syncRecordPresensi();
      final izinCount = await _syncPengajuanIzin();

      final total = laporanCount + presensiCount + izinCount;
      if (total > 0) {
        debugPrint(
          '[SyncManager] selesai: laporan=$laporanCount, '
          'presensi=$presensiCount, izin=$izinCount',
        );
      }
    } catch (e, st) {
      debugPrint('[SyncManager] error: $e\n$st');
    } finally {
      _isSyncing = false;
    }
  }

  // ─────────────────────────────────────────────────────
  // 1. LaporanDosen
  // ─────────────────────────────────────────────────────

  Future<int> _syncLaporanDosen() async {
    final box = HiveHelper.laporanDosenBoxInstance;
    final pending = box.values.where((l) => l.syncStatus == 'pending').toList();
    if (pending.isEmpty) return 0;

    int ok = 0;
    for (final laporan in pending) {
      try {
        await DatabaseService().insertOrUpdateLaporanDosen(laporan.toMap());
        final synced = laporan.copyWith(syncStatus: 'synced');
        await box.put(synced.id, synced);
        ok++;
      } catch (e) {
        debugPrint('[SyncManager] laporan ${laporan.id} gagal: $e');
      }
    }
    return ok;
  }

  // ─────────────────────────────────────────────────────
  // 2. RecordPresensi
  // ─────────────────────────────────────────────────────

  Future<int> _syncRecordPresensi() async {
    final box = HiveHelper.recordPresensiBoxInstance;
    final pending = box.values.where((r) => r.syncStatus == 'pending').toList();
    if (pending.isEmpty) return 0;

    int ok = 0;
    for (final record in pending) {
      try {
        await DatabaseService().insertRecordPresensi(record.toMap());
        final synced = record.markAsSynced();
        await box.put(synced.clientUuid, synced);
        ok++;
      } catch (e) {
        debugPrint('[SyncManager] presensi ${record.clientUuid} gagal: $e');
      }
    }
    return ok;
  }

  // ─────────────────────────────────────────────────────
  // 3. PengajuanIzin
  // ─────────────────────────────────────────────────────

  Future<int> _syncPengajuanIzin() async {
    final box = HiveHelper.pengajuanIzinBoxInstance;
    final pending = box.values.where((p) => p.syncStatus == 'pending').toList();
    if (pending.isEmpty) return 0;

    int ok = 0;
    for (final izin in pending) {
      try {
        // Kirim sebagai dokumen baru (insert). Server akan generate ObjectId
        // kalau belum ada. Kalau sudah ada (re-submit accidental), unique
        // index di clientUuid akan menolak — kita cek deduplication via
        // clientUuid duluan agar tidak double.
        final data = izin.toMap();
        // Hapus field yang server-managed.
        data.remove('_id');
        // Tambah field tambahan yang perlu untuk workflow approval di server.
        data['status'] ??= 'pending_wali';

        // Best-effort: cek sudah ada di server berdasar clientUuid.
        final exists = await DatabaseService()
            .izinExistsByClientUuid(izin.clientUuid);
        if (!exists) {
          // Pakai ObjectId baru — server pakai ini sebagai _id.
          data['_id'] = ObjectId();
          await DatabaseService().submitIzinMahasiswa(data);
        }

        final synced = izin.markAsSynced();
        await box.put(synced.clientUuid, synced);
        ok++;
      } catch (e) {
        debugPrint('[SyncManager] izin ${izin.clientUuid} gagal: $e');
      }
    }
    return ok;
  }
}
