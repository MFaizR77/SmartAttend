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
  final TextEditingController materiController = TextEditingController();

  DateTime? _waktuMulai;
  DateTime? _waktuSelesai;
  LaporanDosen? _currentLaporan;

  SesiDosenViewModel({required this.jadwalId, required this.dosenId});

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      // Coba load dari MongoDB
      final data = await DatabaseService().getLaporanDosen(jadwalId, dosenId);
      if (data != null) {
        _currentLaporan = LaporanDosen.fromMap(data);
        _applyData();
        return;
      }
    } catch (e) {
      // Offline fallback
      final box = HiveHelper.laporanDosenBoxInstance;
      final localRecords = box.values.where((r) => r.jadwalId == jadwalId && r.dosenId == dosenId && r.tanggal.day == DateTime.now().day).toList();
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
      } else {
        isKelasBerjalan.value = true;
        isKelasSelesai.value = false;
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
      syncStatus: 'pending'
    );

    await _saveData(laporan);
    isLoading.value = false;
  }

  Future<void> selesaiKuliah() async {
    isLoading.value = true;
    _waktuSelesai = DateTime.now();
    isKelasBerjalan.value = false;
    isKelasSelesai.value = true;

    final laporan = _currentLaporan?.copyWith(
      waktuSelesai: _waktuSelesai,
      syncStatus: 'pending'
    ) ?? LaporanDosen(
      jadwalId: jadwalId,
      dosenId: dosenId,
      waktuMulai: _waktuMulai ?? DateTime.now(),
      waktuSelesai: _waktuSelesai,
      syncStatus: 'pending'
    );

    await _saveData(laporan);
    
    // Jadwalkan pengingat jam 20:00 karena belum mengisi materi
    await NotificationService().scheduleDailyReminder();
    
    isLoading.value = false;
  }

  Future<void> simpanMateri() async {
    isLoading.value = true;
    final laporan = _currentLaporan?.copyWith(
      materi: materiController.text,
      syncStatus: 'pending'
    );

    if (laporan != null) {
      await _saveData(laporan);
      
      // Jika sudah diisi, batalkan notifikasi pengingat
      if (materiController.text.trim().isNotEmpty) {
        await NotificationService().cancelDailyReminder();
      }
    }
    isLoading.value = false;
  }

  Future<void> _saveData(LaporanDosen laporan) async {
    _currentLaporan = laporan;
    
    // Simpan offline
    final box = HiveHelper.laporanDosenBoxInstance;
    await box.put(laporan.id, laporan);

    // Coba simpan online
    try {
      await DatabaseService().insertOrUpdateLaporanDosen(laporan.toMap());
      final syncedLaporan = laporan.copyWith(syncStatus: 'synced');
      await box.put(syncedLaporan.id, syncedLaporan);
      _currentLaporan = syncedLaporan;
    } catch (e) {
      // Biarkan pending di Hive
      print('Gagal simpan online, tersimpan lokal: $e');
    }
  }

  void dispose() {
    isKelasBerjalan.dispose();
    isKelasSelesai.dispose();
    isLoading.dispose();
    materiController.dispose();
  }
}
