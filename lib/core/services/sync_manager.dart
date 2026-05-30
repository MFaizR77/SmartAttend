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
  //
  // Catatan schema:
  // Model `PengajuanIzin` di Hive hanya punya subset field workflow baru
  // (sesiId, statusApproval, dll yg legacy). Field workflow lengkap
  // (kelas, program, tanggalIzin, jadwalIdsTerdampak, tindakLanjutDosen,
  // namaMahasiswa) disimpan terpisah di `userBox` dengan key
  // `izin_extra_<clientUuid>` saat submit. Sync HARUS gabung keduanya
  // sebelum push ke Mongo, kalau tidak Mongo bakal punya dokumen tanpa
  // jadwalIdsTerdampak → wali tidak bisa approve, dosen tidak lihat,
  // dan UI riwayat tampil "-".

  Future<int> _syncPengajuanIzin() async {
    final box = HiveHelper.pengajuanIzinBoxInstance;
    final userBox = HiveHelper.userBoxInstance;
    final pending = box.values.where((p) => p.syncStatus == 'pending').toList();
    if (pending.isEmpty) return 0;

    int ok = 0;
    for (final izin in pending) {
      try {
        // Best-effort dedup: cek server.
        final exists = await DatabaseService()
            .izinExistsByClientUuid(izin.clientUuid);

        if (!exists) {
          // Build payload lengkap = base lokal + extras dari userBox.
          final extraRaw = userBox.get('izin_extra_${izin.clientUuid}');
          final extra = extraRaw is Map
              ? Map<String, dynamic>.from(extraRaw)
              : <String, dynamic>{};

          // tanggalIzin di extras tersimpan sebagai ISO string — convert ke
          // DateTime supaya Mongo simpan sebagai BSON date.
          DateTime? tanggalIzin;
          final tglStr = extra['tanggalIzin']?.toString();
          if (tglStr != null && tglStr.isNotEmpty) {
            tanggalIzin = DateTime.tryParse(tglStr);
          }

          final payload = <String, dynamic>{
            '_id': ObjectId(),
            'clientUuid': izin.clientUuid,
            'mahasiswaId': izin.mahasiswaId,
            'namaMahasiswa': extra['namaMahasiswa'],
            'kelas': extra['kelas'],
            'program': extra['program'],
            'tanggalIzin': tanggalIzin ?? izin.createdAt,
            'jenis': izin.jenis,
            'keterangan': izin.keterangan,
            'fotoPath': izin.fotoPath,
            'fotoUrl': izin.fotoUrl,
            'jadwalIdsTerdampak':
                (extra['jadwalIdsTerdampak'] as List?) ?? const [],
            'tindakLanjutDosen':
                (extra['tindakLanjutDosen'] as List?) ?? const [],
            'cakupan': extra['cakupan'],
            'status': 'pending_wali',
          };

          await DatabaseService().submitIzinMahasiswa(payload);
          debugPrint(
            '[SyncManager] izin ${izin.clientUuid} pushed '
            '(${(extra['jadwalIdsTerdampak'] as List?)?.length ?? 0} jadwal)',
          );
        } else {
          debugPrint('[SyncManager] izin ${izin.clientUuid} sudah ada di server, skip insert');
        }

        // Mark synced di Hive.
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
