import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  final createdDosenIds = <String>[];

  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    for (final dosenId in createdDosenIds) {
      await cleanupByField('pengajuan_ganti_jadwal', 'dosenId', dosenId);
    }
    await teardownTestDb();
  });

  group('ajukanGantiJadwal() — Integration', () {
    test('G-01: Submit pengajuan → tersimpan', () async {
      final dosenId = testId('dsn');
      final jadwalAsli = testId('jadwal');
      createdDosenIds.add(dosenId);

      await DatabaseService().ajukanGantiJadwal({
        'dosenId': dosenId,
        'jadwalIdAsli': jadwalAsli,
        'namaMK': 'Test Ganti Jadwal',
        'kelas': '2B',
        'tanggalPengganti': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'jamMulaiPengganti': '07:00',
        'jamSelesaiPengganti': '08:30',
        'ruanganPengganti': 'LAB-01',
        'status': 'pending',
      });

      final all = await DatabaseService().getAllPengajuan();
      final ada = all.where((p) => p['dosenId'] == dosenId).toList();
      expect(ada.isNotEmpty, true);
      expect(ada.first['status'], 'pending');
    });
  });

  group('getAllPengajuan() — Integration', () {
    test('G-02: Return list (bisa kosong atau berisi)', () async {
      final all = await DatabaseService().getAllPengajuan();
      expect(all, isA<List<Map<String, dynamic>>>());
    });
  });

  group('updateStatusPengajuan() — Integration', () {
    test('G-03: Approve → status approved', () async {
      final dosenId = testId('dsnupd');
      final jadwalAsli = testId('jadwal');
      createdDosenIds.add(dosenId);

      await DatabaseService().ajukanGantiJadwal({
        'dosenId': dosenId,
        'jadwalIdAsli': jadwalAsli,
        'namaMK': 'Test Update Status',
        'kelas': '2B',
        'tanggalPengganti': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'jamMulaiPengganti': '07:00',
        'jamSelesaiPengganti': '08:30',
        'ruanganPengganti': 'LAB-01',
        'status': 'pending',
      });

      final all = await DatabaseService().getAllPengajuan();
      final pengajuan = all.where((p) => p['dosenId'] == dosenId).first;
      final id = pengajuan['_id'];

      await DatabaseService().updateStatusPengajuan(id, 'approved');

      final updated = await DatabaseService().getAllPengajuan();
      final found = updated.where((p) => p['_id'].toString() == id.toString()).first;
      expect(found['status'], 'approved');
    });
  });

  group('getRuanganTersedia() — Integration', () {
    test('G-04: Return list ruangan dengan isTerpakai flag', () async {
      final tanggal = DateTime.now().add(const Duration(days: 1));
      final ruangan = await DatabaseService().getRuanganTersedia(
        tanggal,
        '07:00',
        '08:30',
      );
      expect(ruangan, isA<List<Map<String, dynamic>>>());
      if (ruangan.isNotEmpty) {
        expect(ruangan.first.containsKey('nama'), true);
        expect(ruangan.first.containsKey('isTerpakai'), true);
      }
    });
  });
}
