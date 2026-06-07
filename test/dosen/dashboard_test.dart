import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/dashboard/viewmodel/dosen_dashboard_viewmodel.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test DosenDashboardViewModel', () {
    late DosenDashboardViewModel vm;

    setUp(() {
      vm = DosenDashboardViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('DD-01: Initial jadwalMengajar kosong', () {
      expect(vm.jadwalMengajar.value, isEmpty);
    });

    test('DD-02: Initial mahasiswaHadir = 0', () {
      expect(vm.mahasiswaHadir.value, 0);
    });

    test('DD-03: Initial izinPending = 0', () {
      expect(vm.izinPending.value, 0);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test Dosen Dashboard — DatabaseService', () {
    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('DD-04: getAllJadwalDosen() mengembalikan jadwal untuk dosen yang ada', () async {
      const dosenId = 'KO006N';
      final list = await DatabaseService().getAllJadwalDosen(dosenId);
      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list, isNotEmpty,
          reason: 'KO006N harus punya jadwal');
      print('[TEST] DD-04: getAllJadwalDosen($dosenId) -> ${list.length} jadwal');
    });

    test('DD-05: getAllJadwalDosen() setiap jadwal punya field _id, namaMK, hari', () async {
      const dosenId = 'KO006N';
      final list = await DatabaseService().getAllJadwalDosen(dosenId);
      for (final j in list) {
        expect(j['_id'], isNotNull);
        expect(j['namaMK'], isNotNull);
        expect(j['hari'], isNotNull);
      }
      print('[TEST] DD-05: semua jadwal $dosenId punya field wajib');
    });

    test('DD-06: getAllJadwalDosen() dosen tidak ada → list kosong', () async {
      final list = await DatabaseService().getAllJadwalDosen('DOSEN_TIDAK_ADA_999');
      expect(list, isEmpty);
      print('[TEST] DD-06: dosen tidak ada -> jadwal kosong');
    });

    test('DD-07: getJadwalDosenByHari() filter hari benar', () async {
      const dosenId = 'KO006N';
      // Senin
      final senin = await DatabaseService().getJadwalDosenByHari(
        dosenId, DateTime(2026, 2, 16), // Senin 16 Feb 2026
      );
      for (final j in senin) {
        expect(j['hari'], equals('Senin'),
            reason: 'Semua jadwal harus hari Senin');
      }
      print('[TEST] DD-07: getJadwalDosenByHari Senin -> ${senin.length} jadwal');
    });

    test('DD-08: getFcmTokensByJadwal() mengembalikan list', () async {
      const jadwalId = 'D3_2B_25IF2122_Senin_0700_PR';
      final tokens = await DatabaseService().getFcmTokensByJadwal(jadwalId);
      expect(tokens, isA<List<String>>());
      print('[TEST] DD-08: getFcmTokensByJadwal -> ${tokens.length} token');
    });

    test('DD-09: getJadwalInfo() jadwal ada → data tidak null', () async {
      const jadwalId = 'D3_2B_25IF2122_Senin_0700_PR';
      final info = await DatabaseService().getJadwalInfo(jadwalId);
      expect(info, isNotNull);
      expect(info?['namaMK'], isNotNull);
      print('[TEST] DD-09: getJadwalInfo($jadwalId) = ${info?['namaMK']}');
    });

    test('DD-10: getJadwalInfo() jadwal tidak ada → null', () async {
      final info = await DatabaseService().getJadwalInfo('JADWAL_TIDAK_ADA_999');
      expect(info, isNull);
      print('[TEST] DD-10: jadwal tidak ada -> getJadwalInfo = null');
    });
  });
}
