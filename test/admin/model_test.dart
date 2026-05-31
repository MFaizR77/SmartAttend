import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/local/models/jadwal_kuliah.dart';

void main() {
  group('JadwalKuliah Model — Admin Upload', () {
    test('D-01: fromMap() parsing data lengkap', () {
      final map = {
        '_id': 'D3_2B_25IF2122_Senin_0700_PR',
        'kodeMK': '25IF2122',
        'namaMK': 'Pemrograman Mobile',
        'kelas': '2B',
        'program': 'D3',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '08:30',
        'tipe': 'PR',
        'ruangan': 'LAB-01',
        'dosenIds': ['KO006N'],
        'namaDosen': 'Muhammad Faiz',
        'isActive': true,
      };
      final j = JadwalKuliah.fromMap(map);
      expect(j.kodeMK, '25IF2122');
      expect(j.namaMK, 'Pemrograman Mobile');
      expect(j.kelas, '2B');
      expect(j.program, 'D3');
      expect(j.hari, 'Senin');
      expect(j.jamMulai, '07:00');
      expect(j.jamSelesai, '08:30');
      expect(j.tipe, 'PR');
      expect(j.ruangan, 'LAB-01');
    });

    test('D-02: fromMap() team teaching (multi dosenIds)', () {
      final map = {
        '_id': 'D3_2B_25IF2122_Senin_0700_PR',
        'kodeMK': '25IF2122',
        'namaMK': 'Proyek',
        'kelas': '2B',
        'program': 'D3',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '08:30',
        'tipe': 'PR',
        'ruangan': 'LAB-01',
        'dosenIds': ['KO006N', 'KO003N', 'KO067N'],
        'namaDosen': 'Faiz; Bambang; Asri',
        'isActive': true,
      };
      final j = JadwalKuliah.fromMap(map);
      expect(j.dosenIds.length, 3);
      expect(j.namaDosen, 'Faiz; Bambang; Asri');
    });
  });

  group('Format Validasi', () {
    test('D-03: Format jam HH:MM valid/invalid', () {
      final jamRegex = RegExp(r'^\d{2}:\d{2}$');
      expect(jamRegex.hasMatch('07:00'), true);
      expect(jamRegex.hasMatch('23:59'), true);
      expect(jamRegex.hasMatch('7:00'), false);
      expect(jamRegex.hasMatch('0700'), false);
    });

    test('D-04: Hari valid Senin-Minggu', () {
      final valid = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      expect(valid.contains('Senin'), true);
      expect(valid.contains('Minggu'), true);
      expect(valid.contains('Monday'), false);
    });

    test('D-05: Tipe valid TE/PR', () {
      final valid = ['TE', 'PR'];
      expect(valid.contains('TE'), true);
      expect(valid.contains('PR'), true);
      expect(valid.contains('Lab'), false);
    });
  });
}
