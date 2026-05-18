import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../data/remote/database_service.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/models/laporan_dosen.dart';
import '../../../../core/services/notification_service.dart';

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
      final data = await DatabaseService().getLaporanDosen(jadwalId, dosenId);
      if (data != null) {
        _currentLaporan = LaporanDosen.fromMap(data);
        _applyData();
        return;
      }
    } catch (e) {
      final box = HiveHelper.laporanDosenBoxInstance;
      final localRecords = box.values
          .where((r) => r.jadwalId == jadwalId && r.dosenId == dosenId && r.tanggal.day == DateTime.now().day)
          .toList();
      if (localRecords.isNotEmpty) {
        _currentLaporan = localRecords.first;
        _applyData();
        return;
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
    isLoading.value = false;

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
      print('Gagal simpan online, tersimpan lokal: $e');
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
