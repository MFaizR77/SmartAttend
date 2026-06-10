import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel jadwal mingguan dosen.
/// Load semua jadwal dosen, kelompokkan per hari Senin–Jumat.
class JadwalDosenViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String> selectedHari = ValueNotifier('');
  final ValueNotifier<Map<String, List<Map<String, dynamic>>>> jadwalPerHari =
      ValueNotifier({});

  static const List<String> _urutan = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat',
  ];

  bool _isDisposed = false;

  /// Return hari hari ini dalam bahasa Indonesia
  static String hariIni() {
    const map = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return map[DateTime.now().weekday] ?? 'Senin';
  }

  Future<void> loadJadwal(String dosenId) async {
    if (_isDisposed) return;
    isLoading.value = true;

    // Set default hari ke hari ini (atau Senin kalau hari ini Sabtu/Minggu)
    final today = hariIni();
    if (!_urutan.contains(today)) {
      selectedHari.value = 'Senin';
    } else {
      selectedHari.value = today;
    }

    try {
      final list = await DatabaseService().getAllJadwalDosen(dosenId);
      if (_isDisposed) return;

      // Kelompokkan per hari
      final Map<String, List<Map<String, dynamic>>> grouped = {
        for (final h in _urutan) h: [],
      };
      for (final j in list) {
        final hari = j['hari']?.toString() ?? '';
        if (grouped.containsKey(hari)) {
          grouped[hari]!.add(j);
        }
      }
      jadwalPerHari.value = grouped;
    } catch (e) {
      debugPrint('[JadwalDosenVM] load error: $e');
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get jadwalHariDipilih =>
      jadwalPerHari.value[selectedHari.value] ?? [];

  static List<String> get hariList => _urutan;

  void pilihHari(String hari) {
    selectedHari.value = hari;
  }

  void dispose() {
    _isDisposed = true;
    isLoading.dispose();
    selectedHari.dispose();
    jadwalPerHari.dispose();
  }
}
