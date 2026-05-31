import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/remote/database_service.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/laporan_dosen.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/fcm_sender_service.dart';
import '../../../../core/services/session_state_service.dart';
import '../../../../core/services/sync_manager.dart';

class SesiDosenViewModel {
  final String jadwalId;
  final String dosenId;

  final ValueNotifier<bool> isKelasBerjalan = ValueNotifier(false);
  final ValueNotifier<bool> isKelasSelesai = ValueNotifier(false);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isLaporanTerkirim = ValueNotifier(false);
  final ValueNotifier<List<Map<String, dynamic>>> statusMahasiswa = ValueNotifier([]);
  final TextEditingController materiController = TextEditingController();

  DateTime? _waktuMulai;
  DateTime? _waktuSelesai;
  LaporanDosen? _currentLaporan;
  Timer? _refreshTimer;

  SesiDosenViewModel({required this.jadwalId, required this.dosenId});

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      // Strategi offline-first:
      //   1. Cek Hive lokal dulu — sumber kebenaran untuk device ini.
      //      Kalau dosen tadi sudah Mulai/Selesai Kuliah (di sini atau di
      //      device lain yang sudah ke-sync), state-nya ada di Hive.
      //   2. Kalau online, refresh dari Mongo. Server data overwrite local
      //      cache supaya state up-to-date kalau dosen pakai 2 device.

      final box = HiveHelper.laporanDosenBoxInstance;
      final today = DateTime.now();
      final localRecords = box.values
          .where((r) =>
              r.jadwalId == jadwalId &&
              r.dosenId == dosenId &&
              r.tanggal.year == today.year &&
              r.tanggal.month == today.month &&
              r.tanggal.day == today.day)
          .toList();
      if (localRecords.isNotEmpty) {
        _currentLaporan = localRecords.first;
        _applyData();
      }

      // Refresh dari server (best-effort).
      try {
        final data = await DatabaseService().getLaporanDosen(jadwalId, dosenId);
        if (data != null) {
          _currentLaporan = LaporanDosen.fromMap(data);
          // Simpan juga ke Hive supaya cache up-to-date.
          await box.put(_currentLaporan!.id, _currentLaporan!);
          _applyData();
        }
      } catch (e) {
        debugPrint('[SesiDosenVM] server fetch laporan failed (offline?): $e');
        // Keep local state.
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _applyData() {
    if (_currentLaporan != null) {
      _waktuMulai = _currentLaporan!.waktuMulai;
      _waktuSelesai = _currentLaporan!.waktuSelesai;

      if (_waktuSelesai != null) {
        isKelasBerjalan.value = false;
        isKelasSelesai.value = true;
        materiController.text = _currentLaporan!.materi ?? '';
        isLaporanTerkirim.value =
            (_currentLaporan!.materi != null && _currentLaporan!.materi!.trim().isNotEmpty);
      } else {
        isKelasBerjalan.value = true;
        isKelasSelesai.value = false;
        // Kelas sudah berjalan (reload setelah app restart), langsung load mahasiswa
        loadStatusMahasiswa();
        _startRefreshTimer();
      }
    }
  }

  Future<void> mulaiKuliah() async {
    isLoading.value = true;
    _waktuMulai = DateTime.now();
    isKelasBerjalan.value = true;

    final laporan = LaporanDosen(
      jadwalId: jadwalId,
      dosenId: dosenId,
      waktuMulai: _waktuMulai!,
      syncStatus: 'pending',
    );

    await _saveData(laporan);
    // Update cache lokal sesi supaya UI mahasiswa di device ini tahu (penting
    // untuk skenario satu device dipakai bergantian, dan untuk konsistensi
    // dengan SessionStateService).
    await SessionStateService().markOpenedLocally(jadwalId);
    isLoading.value = false;

    // Kirim notifikasi ke mahasiswa (best-effort, jangan ganggu flow utama)
    _trySendAbsensiNotification();

    // Langsung load daftar mahasiswa & mulai auto-refresh
    await loadStatusMahasiswa();
    _startRefreshTimer();
  }

  Future<void> selesaiKuliah() async {
    isLoading.value = true;
    _stopRefreshTimer();
    _waktuSelesai = DateTime.now();
    isKelasBerjalan.value = false;
    isKelasSelesai.value = true;

    final laporan = _currentLaporan?.copyWith(
          waktuSelesai: _waktuSelesai,
          syncStatus: 'pending',
        ) ??
        LaporanDosen(
          jadwalId: jadwalId,
          dosenId: dosenId,
          waktuMulai: _waktuMulai ?? DateTime.now(),
          waktuSelesai: _waktuSelesai,
          syncStatus: 'pending',
        );

    await _saveData(laporan);
    await SessionStateService().markClosedLocally(jadwalId);
    await NotificationService().scheduleDailyReminder();
    isLoading.value = false;
  }

  Future<void> simpanMateri() async {
    isLoading.value = true;
    final laporan = _currentLaporan?.copyWith(
          materi: materiController.text,
          syncStatus: 'pending',
        ) ??
        LaporanDosen(
          jadwalId: jadwalId,
          dosenId: dosenId,
          waktuMulai: _waktuMulai ?? DateTime.now(),
          materi: materiController.text,
          syncStatus: 'pending',
        );

    await _saveData(laporan);

    if (materiController.text.trim().isNotEmpty) {
      isLaporanTerkirim.value = true;
      await NotificationService().cancelDailyReminder();
    }
    isLoading.value = false;
  }

  /// Load / refresh daftar status presensi mahasiswa dari MongoDB
  Future<void> loadStatusMahasiswa() async {
    try {
      final list = await DatabaseService().getStatusPresensiMahasiswaByJadwal(jadwalId);
      statusMahasiswa.value = list;
    } catch (_) {
      // Diam-diam, jangan ganggu UI utama
    }
  }

  /// Dosen menandai status mahasiswa secara manual
  /// status: 'alpha' | 'izin' | 'sakit' | 'hapus'
  Future<void> tandaiStatus(String nim, String status) async {
    await DatabaseService().tandaiStatusMahasiswaByDosen(jadwalId, nim, status);
    await loadStatusMahasiswa();
  }

  /// Tandai banyak mahasiswa sekaligus (bulk action)
  Future<void> tandaiStatusBulk(List<String> nimList, String status) async {
    for (final nim in nimList) {
      await DatabaseService().tandaiStatusMahasiswaByDosen(jadwalId, nim, status);
    }
    await loadStatusMahasiswa();
  }

  /// Kirim push notification ke mahasiswa yang ter-enroll di jadwal ini.
  /// Best-effort: jika gagal, hanya log error, tidak mengganggu flow utama.
  Future<void> _trySendAbsensiNotification() async {
    try {
      final db = DatabaseService();

      // Ambil info jadwal untuk nama mata kuliah
      final jadwalInfo = await db.getJadwalInfo(jadwalId);
      final namaMK = jadwalInfo?['namaMK']?.toString() ??
          jadwalInfo?['mataKuliah']?.toString() ??
          'Mata Kuliah';

      // Ambil FCM token milik mahasiswa yang ter-enroll
      final tokens = await db.getFcmTokensByJadwal(jadwalId);
      if (tokens.isEmpty) {
        print('[FCM] Tidak ada token mahasiswa untuk jadwal $jadwalId');
        return;
      }

      // Kirim notifikasi
      final sent = await FCMSenderService().sendNotificationToTokens(
        tokens: tokens,
        title: 'Absensi Dibuka',
        body: 'Absensi $namaMK sudah dibuka, segera lakukan presensi',
        data: {
          'type': 'absensi_dibuka',
          'jadwalId': jadwalId,
        },
      );

      print('[FCM] Notifikasi terkirim ke $sent/${tokens.length} device');
    } catch (e) {
      print('[FCM] Gagal mengirim notifikasi: $e');
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isKelasBerjalan.value) loadStatusMahasiswa();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _saveData(LaporanDosen laporan) async {
    _currentLaporan = laporan;
    final box = HiveHelper.laporanDosenBoxInstance;
    await box.put(laporan.id, laporan);

    try {
      await DatabaseService().insertOrUpdateLaporanDosen(laporan.toMap());
      final syncedLaporan = laporan.copyWith(syncStatus: 'synced');
      await box.put(syncedLaporan.id, syncedLaporan);
      _currentLaporan = syncedLaporan;
    } catch (e) {
      debugPrint('Gagal simpan online, tersimpan lokal: $e');
      // Trigger sync queue — akan retry saat online.
      // ignore: discarded_futures
      SyncManager().syncAll();
    }
  }

  void dispose() {
    _stopRefreshTimer();
    isKelasBerjalan.dispose();
    isKelasSelesai.dispose();
    isLoading.dispose();
    isLaporanTerkirim.dispose();
    statusMahasiswa.dispose();
    materiController.dispose();
  }
}
