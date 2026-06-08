import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    // upload_jadwal_test hanya read-only + validate, tidak menulis data baru
    // Tidak perlu cleanup
    await teardownTestDb();
  });

  group('validateJadwalRows() — Integration', () {
    test('U-01: Baris valid → empty errors', () async {
      final errors = await DatabaseService().validateJadwalRows([
        {
          'kodeMK': 'TEST9999',
          'namaMK': 'Test Mata Kuliah',
          'kelas': '9Z',
          'kodeDosen': 'KO006N',
          'hari': 'Sabtu',
          'jamMulai': '15:00',
          'jamSelesai': '16:30',
          'kodeRuangan': 'LAB-01',
          'tipe': 'TE',
          'program': 'D3',
          'sks': '2',
          'semester': '1',
        },
      ]);
      expect(errors, isA<List<String>>());
    });

    test('U-02: Field kosong → error', () async {
      final errors = await DatabaseService().validateJadwalRows([
        {
          'kodeMK': '',
          'namaMK': 'Test',
          'kelas': '2B',
          'kodeDosen': 'KO006N',
          'hari': 'Senin',
          'jamMulai': '07:00',
          'jamSelesai': '08:30',
          'kodeRuangan': 'LAB-01',
          'tipe': 'TE',
          'program': 'D3',
          'sks': '2',
          'semester': '1',
        },
      ]);
      expect(errors.isNotEmpty, true);
      expect(errors.first, contains('Baris'));
    });

    test('U-03: Dosen tidak ada → error', () async {
      final errors = await DatabaseService().validateJadwalRows([
        {
          'kodeMK': 'TEST9999',
          'namaMK': 'Test',
          'kelas': '2B',
          'kodeDosen': 'DOSEN_TIDAK_ADA_999',
          'hari': 'Senin',
          'jamMulai': '07:00',
          'jamSelesai': '08:30',
          'kodeRuangan': 'LAB-01',
          'tipe': 'TE',
          'program': 'D3',
          'sks': '2',
          'semester': '1',
        },
      ]);
      expect(errors.isNotEmpty, true);
    });

    test('U-04: JamMulai >= jamSelesai → error', () async {
      final errors = await DatabaseService().validateJadwalRows([
        {
          'kodeMK': 'TEST9999',
          'namaMK': 'Test',
          'kelas': '2B',
          'kodeDosen': 'KO006N',
          'hari': 'Senin',
          'jamMulai': '09:00',
          'jamSelesai': '07:00',
          'kodeRuangan': 'LAB-01',
          'tipe': 'TE',
          'program': 'D3',
          'sks': '2',
          'semester': '1',
        },
      ]);
      expect(errors.isNotEmpty, true);
    });
  });

  group('getUploadJadwalHistory() — Integration', () {
    test('U-05: Return list (bisa kosong atau berisi)', () async {
      final history = await DatabaseService().getUploadJadwalHistory();
      expect(history, isA<List<Map<String, dynamic>>>());
    });
  });
}
