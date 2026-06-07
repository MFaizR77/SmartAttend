import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/mahasiswa/dashboard/viewmodel/mahasiswa_dashboard_viewmodel.dart';
import 'package:smartattend/data/local/models/user.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test MahasiswaDashboardViewModel', () {
    late MahasiswaDashboardViewModel vm;

    setUp(() {
      vm = MahasiswaDashboardViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('MD-01: Initial jadwalHariIni kosong', () {
      expect(vm.jadwalHariIni.value, isEmpty);
    });

    test('MD-02: Initial jadwalPenggantiHariIni kosong', () {
      expect(vm.jadwalPenggantiHariIni.value, isEmpty);
    });

    test('MD-03: Initial statistik kosong', () {
      expect(vm.statistik.value, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test MahasiswaDashboardViewModel', () {
    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('MD-04: getStatistikMahasiswa() mengembalikan map dengan key hadir/izin/sakit/alpha', () async {
      const nimTest = '241511033'; // mahasiswa kelas 2B yang ada di DB
      final stats = await DatabaseService().getStatistikMahasiswa(nimTest);
      expect(stats, isA<Map<String, int>>());
      expect(stats.containsKey('hadir'), isTrue);
      expect(stats.containsKey('izin'), isTrue);
      expect(stats.containsKey('sakit'), isTrue);
      expect(stats.containsKey('alpha'), isTrue);
      print('[TEST] MD-04: statistik $nimTest = $stats');
    });

    test('MD-05: getStatistikMahasiswa() nilai tidak negatif', () async {
      const nimTest = '241511033';
      final stats = await DatabaseService().getStatistikMahasiswa(nimTest);
      for (final entry in stats.entries) {
        expect(entry.value, greaterThanOrEqualTo(0),
            reason: '${entry.key} tidak boleh negatif');
      }
      print('[TEST] MD-05: semua nilai statistik >= 0');
    });

    test('MD-06: getStatistikMahasiswa() NIM tidak ada → semua 0', () async {
      final stats = await DatabaseService().getStatistikMahasiswa('NIM_TIDAK_ADA_999');
      expect(stats['hadir'], 0);
      expect(stats['izin'], 0);
      expect(stats['alpha'], 0);
      print('[TEST] MD-06: NIM tidak ada -> semua statistik = 0');
    });

    test('MD-07: isKelasBerjalan() mengembalikan bool', () async {
      const jadwalId = 'D3_2B_25IF2122_Senin_0700_PR';
      final result = await DatabaseService().isKelasBerjalan(jadwalId);
      expect(result, isA<bool>());
      print('[TEST] MD-07: isKelasBerjalan($jadwalId) = $result');
    });

    test('MD-08: isKelasBerjalan() jadwal tidak ada → false', () async {
      final result = await DatabaseService().isKelasBerjalan('JADWAL_TIDAK_ADA_999');
      expect(result, isFalse);
      print('[TEST] MD-08: jadwal tidak ada -> isKelasBerjalan = false');
    });

    test('MD-09: getEnrolledJadwalIds() mahasiswa aktif punya jadwal', () async {
      const nimTest = '241511033';
      final jadwalIds = await DatabaseService().getEnrolledJadwalIds(nimTest);
      expect(jadwalIds, isA<List<String>>());
      expect(jadwalIds, isNotEmpty,
          reason: 'Mahasiswa $nimTest harus punya enrollment aktif');
      print('[TEST] MD-09: $nimTest terdaftar di ${jadwalIds.length} jadwal');
    });
  });
}
