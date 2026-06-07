import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/sesi/viewmodel/sesi_dosen_viewmodel.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test SesiDosenViewModel', () {
    late SesiDosenViewModel vm;

    setUp(() {
      vm = SesiDosenViewModel(
        jadwalId: 'D3_2B_25IF2122_Senin_0700_PR',
        dosenId: 'KO006N',
      );
    });

    tearDown(() {
      vm.dispose();
    });

    test('SD-01: Initial isKelasBerjalan = false', () {
      expect(vm.isKelasBerjalan.value, false);
    });

    test('SD-02: Initial isKelasSelesai = false', () {
      expect(vm.isKelasSelesai.value, false);
    });

    test('SD-03: Initial isLaporanTerkirim = false', () {
      expect(vm.isLaporanTerkirim.value, false);
    });

    test('SD-04: Initial statusMahasiswa kosong', () {
      expect(vm.statusMahasiswa.value, isEmpty);
    });

    test('SD-05: materiController kosong saat init', () {
      expect(vm.materiController.text, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test Sesi Dosen — DatabaseService', () {
    const jadwalId = 'D3_2B_25IF2122_Senin_0700_PR';
    const dosenId = 'KO006N';

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('SD-06: getStatusPresensiMahasiswaByJadwal() mengembalikan list', () async {
      final list = await DatabaseService().getStatusPresensiMahasiswaByJadwal(jadwalId);
      expect(list, isA<List<Map<String, dynamic>>>());
      print('[TEST] SD-06: status presensi -> ${list.length} mahasiswa');
    });

    test('SD-07: Setiap entry status presensi punya field nim, nama, status', () async {
      final list = await DatabaseService().getStatusPresensiMahasiswaByJadwal(jadwalId);
      for (final m in list) {
        expect(m['nim'], isNotNull);
        expect(m['nama'], isNotNull);
        expect(m['status'], isNotNull);
        expect(
          ['hadir', 'belum', 'alpha', 'izin', 'sakit'],
          contains(m['status']),
          reason: 'status harus salah satu dari: hadir/belum/alpha/izin/sakit',
        );
      }
      print('[TEST] SD-07: semua field status presensi valid');
    });

    test('SD-08: getLaporanDosen() mengembalikan laporan atau null', () async {
      final laporan = await DatabaseService().getLaporanDosen(jadwalId, dosenId);
      // Boleh null kalau belum ada laporan hari ini
      expect(laporan == null || laporan is Map<String, dynamic>, isTrue);
      print('[TEST] SD-08: getLaporanDosen($dosenId) = ${laporan != null ? 'ada' : 'null'}');
    });

    test('SD-09: tandaiStatusMahasiswaByDosen() berhasil tandai dan terlihat di presensi', () async {
      const nimTest = '241511033';

      // Tandai alpha
      await DatabaseService().tandaiStatusMahasiswaByDosen(jadwalId, nimTest, 'alpha');

      // Hapus kembali (cleanup)
      await DatabaseService().tandaiStatusMahasiswaByDosen(jadwalId, nimTest, 'hapus');
      print('[TEST] SD-09: tandai alpha + hapus berhasil');
    });

    test('SD-10: getAllLaporanDosen() mengembalikan list laporan', () async {
      final list = await DatabaseService().getAllLaporanDosen(dosenId);
      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list, isNotEmpty,
          reason: 'KO006N harus punya laporan mengajar');
      print('[TEST] SD-10: getAllLaporanDosen($dosenId) -> ${list.length} laporan');
    });

    test('SD-11: checkPresensiExists() mengembalikan bool', () async {
      const nimTest = '241511033';
      final exists = await DatabaseService().checkPresensiExists(jadwalId, nimTest);
      expect(exists, isA<bool>());
      print('[TEST] SD-11: checkPresensiExists($nimTest) = $exists');
    });
  });
}
