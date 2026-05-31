import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  // Track IDs untuk cleanup
  final createdUuids = <String>[];
  final createdSesiIds = <String>[];
  final createdMhsIds = <String>[];

  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    // Cleanup: hapus hanya data test yang dibuat
    for (final uuid in createdUuids) {
      await cleanupByField('record_presensi', 'clientUuid', uuid);
    }
    await teardownTestDb();
  });

  group('insertRecordPresensi() — Integration', () {
    test('P-01: Insert baru → tersimpan', () async {
      final uuid = testId('uuid');
      final sesiId = testId('sesi');
      final mhsId = testId('mhs');
      createdUuids.add(uuid);

      await DatabaseService().insertRecordPresensi({
        'clientUuid': uuid,
        'sesiId': sesiId,
        'mahasiswaId': mhsId,
        'timestamp': DateTime.now().toIso8601String(),
        'statusHadir': true,
        'metode': 'manual',
      });

      final exists = await DatabaseService().checkPresensiExists(sesiId, mhsId);
      expect(exists, true);
    });

    test('P-02: Insert dengan clientUuid sama → idempotent (no-op)', () async {
      final uuid = testId('dup');
      final sesiId = testId('sesi');
      final mhsId = testId('mhs');
      createdUuids.add(uuid);

      await DatabaseService().insertRecordPresensi({
        'clientUuid': uuid,
        'sesiId': sesiId,
        'mahasiswaId': mhsId,
        'timestamp': DateTime.now().toIso8601String(),
        'statusHadir': true,
        'metode': 'manual',
      });

      // Insert kedua — seharusnya no-op
      await DatabaseService().insertRecordPresensi({
        'clientUuid': uuid,
        'sesiId': sesiId,
        'mahasiswaId': mhsId,
        'timestamp': DateTime.now().toIso8601String(),
        'statusHadir': true,
        'metode': 'manual',
      });

      final exists = await DatabaseService().checkPresensiExists(sesiId, mhsId);
      expect(exists, true);
    });
  });

  group('checkPresensiExists() — Integration', () {
    test('P-03: Ada record hari ini → true', () async {
      final uuid = testId('chk');
      final sesiId = testId('sesi');
      final mhsId = testId('mhs');
      createdUuids.add(uuid);

      await DatabaseService().insertRecordPresensi({
        'clientUuid': uuid,
        'sesiId': sesiId,
        'mahasiswaId': mhsId,
        'timestamp': DateTime.now().toIso8601String(),
        'statusHadir': true,
        'metode': 'manual',
      });

      final exists = await DatabaseService().checkPresensiExists(sesiId, mhsId);
      expect(exists, true);
    });

    test('P-04: Tidak ada record → false', () async {
      final sesiId = testId('none');
      final mhsId = testId('none');

      final exists = await DatabaseService().checkPresensiExists(sesiId, mhsId);
      expect(exists, false);
    });
  });
}
