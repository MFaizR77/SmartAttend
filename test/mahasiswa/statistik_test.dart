import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    await teardownTestDb();
  });

  group('getStatistikMahasiswa() — Integration', () {
    test('S-01: Mahasiswa tanpa record → semua 0', () async {
      final fakeId = testId('NOMHS');
      final stats = await DatabaseService().getStatistikMahasiswa(fakeId);

      expect(stats['hadir'], 0);
      expect(stats['izin'], 0);
      expect(stats['sakit'], 0);
      expect(stats['alpha'], 0);
      expect(stats['total'], 0);
    });

    test('S-02: Map statistik memiliki semua key yang dibutuhkan', () async {
      final fakeId = testId('NOMHS');
      final stats = await DatabaseService().getStatistikMahasiswa(fakeId);

      expect(stats.containsKey('hadir'), true);
      expect(stats.containsKey('izin'), true);
      expect(stats.containsKey('sakit'), true);
      expect(stats.containsKey('alpha'), true);
      expect(stats.containsKey('total'), true);
    });

    test('S-03: Total = hadir + izin + sakit + alpha', () async {
      final fakeId = testId('NOMHS');
      final stats = await DatabaseService().getStatistikMahasiswa(fakeId);

      final expected = (stats['hadir'] ?? 0) +
          (stats['izin'] ?? 0) +
          (stats['sakit'] ?? 0) +
          (stats['alpha'] ?? 0);
      expect(stats['total'], expected);
    });
  });
}
