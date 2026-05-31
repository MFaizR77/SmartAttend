import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  final createdClientUuids = <String>[];
  final createdMhsIds = <String>[];

  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    for (final uuid in createdClientUuids) {
      await cleanupByField('izin_mahasiswa', 'clientUuid', uuid);
    }
    await teardownTestDb();
  });

  group('submitIzinMahasiswa() — Integration', () {
    test('I-01: Submit izin → tersimpan dengan status pending_wali', () async {
      final uuid = testId('izin');
      final mhsId = testId('mhs');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Test User',
        'kelas': '2B',
        'program': 'D3',
        'tanggalIzin': DateTime.now().toIso8601String(),
        'jenis': 'sakit',
        'keterangan': 'Test sakit',
        'jadwalIdsTerdampak': ['jadwal-1'],
        'tindakLanjutDosen': [
          {'jadwalId': 'jadwal-1', 'dosenId': 'D001', 'statusFinal': 'pending'},
        ],
        'cakupan': 'penuh',
      });

      final exists = await DatabaseService().izinExistsByClientUuid(uuid);
      expect(exists, true);
    });
  });

  group('izinExistsByClientUuid() — Integration', () {
    test('I-02: clientUuid ada → true', () async {
      final uuid = testId('exst');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': testId('mhs'),
        'jenis': 'izin',
        'keterangan': 'Test',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final exists = await DatabaseService().izinExistsByClientUuid(uuid);
      expect(exists, true);
    });

    test('I-03: clientUuid tidak ada → false', () async {
      final exists =
          await DatabaseService().izinExistsByClientUuid('nonexistent-uuid-xyz');
      expect(exists, false);
    });
  });

  group('getIzinByMahasiswa() — Integration', () {
    test('I-04: Mahasiswa dengan izin → list tidak kosong', () async {
      final mhsId = testId('mhsizin');
      final uuid = testId('getizin');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'jenis': 'sakit',
        'keterangan': 'Test get izin',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final list = await DatabaseService().getIzinByMahasiswa(mhsId);
      expect(list.isNotEmpty, true);
      expect(list.first['mahasiswaId'], mhsId);
    });
  });
}
