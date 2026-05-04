import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

class JadwalViewModel {
  final ValueNotifier<Map<String, List<Map<String, dynamic>>>> jadwalPerHari =
      ValueNotifier({});
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  static const List<String> _urutanHari = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  Future<void> loadData(User user) async {
    if (user.kelas == null || user.kelas!.isEmpty) {
      errorMessage.value = 'Data kelas tidak ditemukan.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final allJadwal =
          await DatabaseService().getSemuaJadwalMahasiswa(user.kelas!);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final j in allJadwal) {
        final hari = j['hari']?.toString() ?? 'Lainnya';
        grouped.putIfAbsent(hari, () => []);
        grouped[hari]!.add(j);
      }

      final Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
      for (final hari in _urutanHari) {
        if (grouped.containsKey(hari)) {
          sortedGrouped[hari] = grouped[hari]!;
        }
      }
      for (final hari in grouped.keys) {
        if (!sortedGrouped.containsKey(hari)) {
          sortedGrouped[hari] = grouped[hari]!;
        }
      }

      jadwalPerHari.value = sortedGrouped;
    } catch (e) {
      errorMessage.value = 'Gagal memuat jadwal: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> getStatusJadwal(Map<String, dynamic> jadwal) {
    final now = DateTime.now();
    final hariSekarang = DatabaseService().getHariIni();
    final hariJadwal = jadwal['hari']?.toString() ?? '';

    if (hariJadwal != hariSekarang) {
      return {
        'status': 'Upcoming',
        'statusColor': const Color(0xFFEEF2FF),
        'statusTextColor': const Color(0xFF3949AB),
      };
    }

    final jamMulaiStr = jadwal['jamMulai']?.toString() ?? '';
    final jamSelesaiStr = jadwal['jamSelesai']?.toString() ?? '';

    if (jamMulaiStr.isEmpty || jamSelesaiStr.isEmpty) {
      return {
        'status': 'Upcoming',
        'statusColor': const Color(0xFFEEF2FF),
        'statusTextColor': const Color(0xFF3949AB),
      };
    }

    try {
      final mulaiParts = jamMulaiStr.split(':');
      final selesaiParts = jamSelesaiStr.split(':');
      final mulai = DateTime(now.year, now.month, now.day,
          int.parse(mulaiParts[0]), int.parse(mulaiParts[1]));
      final selesai = DateTime(now.year, now.month, now.day,
          int.parse(selesaiParts[0]), int.parse(selesaiParts[1]));

      if (now.isAfter(selesai)) {
        return {
          'status': 'Selesai',
          'statusColor': const Color(0xFFF3F4F6),
          'statusTextColor': const Color(0xFF9CA3AF),
        };
      } else if (!now.isBefore(mulai)) {
        return {
          'status': 'Berlangsung',
          'statusColor': const Color(0xFFDCFCE7),
          'statusTextColor': const Color(0xFF16A34A),
        };
      } else {
        return {
          'status': 'Upcoming',
          'statusColor': const Color(0xFFEEF2FF),
          'statusTextColor': const Color(0xFF3949AB),
        };
      }
    } catch (_) {
      return {
        'status': 'Upcoming',
        'statusColor': const Color(0xFFEEF2FF),
        'statusTextColor': const Color(0xFF3949AB),
      };
    }
  }

  void dispose() {
    jadwalPerHari.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
