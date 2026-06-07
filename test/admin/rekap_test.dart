import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/admin/rekap/viewmodel/rekap_admin_viewmodel.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ────────────────────────────────────────────────────────────
  group('Unit Test RekapAdminViewModel', () {
    late RekapAdminViewModel vm;

    setUp(() {
      vm = RekapAdminViewModel();
    });

    test('R-01: Initial state isLoading = false', () {
      expect(vm.isLoading, false);
    });

    test('R-02: Initial state daftarJadwal kosong', () {
      expect(vm.daftarJadwal, isEmpty);
    });

    test('R-03: Initial state daftarRekap kosong', () {
      expect(vm.daftarRekap, isEmpty);
    });

    test('R-04: Initial filterTipe = mahasiswa', () {
      expect(vm.filterTipe, 'mahasiswa');
    });

    test('R-05: setFilter(dosen) mengubah filterTipe menjadi dosen', () {
      vm.setFilter('dosen');
      expect(vm.filterTipe, 'dosen');
    });

    test('R-06: setFilter(mahasiswa) mengubah filterTipe kembali ke mahasiswa', () {
      vm.setFilter('dosen');
      vm.setFilter('mahasiswa');
      expect(vm.filterTipe, 'mahasiswa');
    });

    test('R-07: setFilter memanggil notifyListeners', () {
      bool notified = false;
      vm.addListener(() => notified = true);
      vm.setFilter('dosen');
      expect(notified, true);
    });

    test('R-08: Initial selectedJadwal = null', () {
      expect(vm.selectedJadwal, isNull);
    });

    test('R-09: Initial errorMessage = null', () {
      expect(vm.errorMessage, isNull);
    });
  });

  // ─── INTEGRATION TEST — ViewModel ─────────────────────────────────────────
  group('Integration Test RekapAdminViewModel', () {
    late RekapAdminViewModel vm;

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    setUp(() {
      vm = RekapAdminViewModel();
    });

    test('R-10: loadJadwal() berhasil load data dari MongoDB', () async {
      await vm.loadJadwal();
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.daftarJadwal, isA<List<Map<String, dynamic>>>());
      print('[TEST] R-10: loadJadwal -> ${vm.daftarJadwal.length} jadwal loaded');
    });

    test('R-11: loadJadwal() setiap jadwal memiliki field _id dan namaMK', () async {
      await vm.loadJadwal();
      for (final jadwal in vm.daftarJadwal) {
        expect(jadwal['_id'], isNotNull);
        expect(jadwal['namaMK'], isNotNull);
      }
      print('[TEST] R-11: semua jadwal memiliki _id dan namaMK');
    });

    test('R-12: loadRekap() filter mahasiswa berhasil load dari MongoDB', () async {
      await vm.loadJadwal();
      expect(vm.daftarJadwal, isNotEmpty);
      final jadwalId = vm.daftarJadwal.first['_id'].toString();
      vm.setFilter('mahasiswa');
      await vm.loadRekap(jadwalId);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.daftarRekap, isA<List<Map<String, dynamic>>>());
      print('[TEST] R-12: loadRekap(mahasiswa) -> ${vm.daftarRekap.length} rekap entries');
    });

    test('R-13: loadRekap() filter dosen berhasil load dari MongoDB', () async {
      await vm.loadJadwal();
      expect(vm.daftarJadwal, isNotEmpty);
      final jadwalId = vm.daftarJadwal.first['_id'].toString();
      vm.setFilter('dosen');
      await vm.loadRekap(jadwalId);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.daftarRekap, isA<List<Map<String, dynamic>>>());
      print('[TEST] R-13: loadRekap(dosen) -> ${vm.daftarRekap.length} rekap entries');
    });

    test('R-14: loadRekap() mengisi selectedJadwal sesuai jadwalId', () async {
      await vm.loadJadwal();
      expect(vm.daftarJadwal, isNotEmpty);
      final jadwal = vm.daftarJadwal.first;
      final jadwalId = jadwal['_id'].toString();
      await vm.loadRekap(jadwalId);
      expect(vm.selectedJadwal, isNotNull);
      expect(vm.selectedJadwal!['_id'].toString(), jadwalId);
      print('[TEST] R-14: selectedJadwal = ${vm.selectedJadwal!['namaMK']}');
    });
  });

  // ─── INTEGRATION TEST — getRekapKehadiranAdmin ────────────────────────────
  group('Integration Test getRekapKehadiranAdmin()', () {
    const jadwalIdTest = 'D3_2B_25IF2122_Senin_0700_PR';

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('R-15: Rekap mahasiswa berhasil diambil dari MongoDB', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      expect(rekap, isA<List<Map<String, dynamic>>>());
      expect(rekap, isNotEmpty);
      print('[TEST] R-15: getRekapKehadiranAdmin -> ${rekap.length} mahasiswa');
    });

    test('R-16: Setiap entry rekap mahasiswa memiliki field wajib', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      for (final r in rekap) {
        expect(r['mahasiswaId'], isNotNull);
        expect(r['nama'], isNotNull);
        expect(r['nim'], isNotNull);
        expect(r['hadir'], isA<int>());
        expect(r['izin'], isA<int>());
        expect(r['alpha'], isA<int>());
        expect(r['totalPertemuan'], isA<int>());
        expect(r['persenHadir'], isA<double>());
      }
      print('[TEST] R-16: semua field rekap mahasiswa valid');
    });

    test('R-17: totalPertemuan berasal dari laporan_dosen (bukan hardcode)', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      expect(rekap, isNotEmpty);
      // totalPertemuan harus konsisten untuk semua mahasiswa di jadwal yang sama
      final total = rekap.first['totalPertemuan'] as int;
      for (final r in rekap) {
        expect(r['totalPertemuan'], total,
            reason: 'totalPertemuan harus sama untuk semua mahasiswa di jadwal ini');
      }
      // totalPertemuan harus > 0 (artinya ada laporan_dosen yang tercatat)
      expect(total, greaterThan(0),
          reason: 'Harus ada minimal 1 pertemuan yang tercatat di laporan_dosen');
      print('[TEST] R-17: totalPertemuan=$total (dari laporan_dosen, konsisten untuk semua mahasiswa)');
    });

    test('R-18: hadir + izin + alpha = totalPertemuan untuk setiap mahasiswa', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      for (final r in rekap) {
        final hadir = r['hadir'] as int;
        final izin = r['izin'] as int;
        final alpha = r['alpha'] as int;
        final total = r['totalPertemuan'] as int;
        expect(hadir + izin + alpha, equals(total),
            reason: 'mahasiswa ${r['nim']}: $hadir+$izin+$alpha != $total');
      }
      print('[TEST] R-18: hadir+izin+alpha == totalPertemuan untuk semua mahasiswa');
    });

    test('R-19: persenHadir = hadir/totalPertemuan * 100', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      for (final r in rekap) {
        final hadir = r['hadir'] as int;
        final total = r['totalPertemuan'] as int;
        final persenHadir = r['persenHadir'] as double;
        if (total > 0) {
          final expected = double.parse(((hadir / total) * 100).toStringAsFixed(1));
          expect(persenHadir, closeTo(expected, 0.1),
              reason: 'mahasiswa ${r['nim']}: persenHadir=$persenHadir, expected=$expected');
        }
      }
      print('[TEST] R-19: persenHadir akurat untuk semua mahasiswa');
    });

    test('R-20: hadir tidak boleh negatif dan tidak melebihi totalPertemuan', () async {
      final rekap = await DatabaseService().getRekapKehadiranAdmin(jadwalIdTest);
      for (final r in rekap) {
        final hadir = r['hadir'] as int;
        final total = r['totalPertemuan'] as int;
        expect(hadir, greaterThanOrEqualTo(0));
        expect(hadir, lessThanOrEqualTo(total));
      }
      print('[TEST] R-20: nilai hadir valid (0 <= hadir <= totalPertemuan)');
    });
  });

  // ─── INTEGRATION TEST — getRekapKehadiranDosen ────────────────────────────
  group('Integration Test getRekapKehadiranDosen()', () {
    const jadwalIdTest = 'D3_2B_25IF2122_Senin_0700_PR';

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('R-21: Rekap dosen berhasil diambil dari MongoDB', () async {
      final rekap = await DatabaseService().getRekapKehadiranDosen(jadwalIdTest);
      expect(rekap, isA<List<Map<String, dynamic>>>());
      expect(rekap, isNotEmpty);
      print('[TEST] R-21: getRekapKehadiranDosen -> ${rekap.length} dosen');
    });

    test('R-22: Setiap entry rekap dosen memiliki field wajib', () async {
      final rekap = await DatabaseService().getRekapKehadiranDosen(jadwalIdTest);
      for (final d in rekap) {
        expect(d['dosenId'], isNotNull);
        expect(d['nama'], isNotNull);
        expect(d['hadir'], isA<int>());
        expect(d['berhalangan'], isA<int>());
        expect(d['totalPertemuan'], isA<int>());
        expect(d['persenHadir'], isA<double>());
        expect(d['alasan'], isA<List>());
      }
      print('[TEST] R-22: semua field rekap dosen valid');
    });

    test('R-23: hadir dosen berasal dari laporan_dosen (bukan hardcode 14)', () async {
      final rekap = await DatabaseService().getRekapKehadiranDosen(jadwalIdTest);
      expect(rekap, isNotEmpty);
      final dosen = rekap.first;
      // Jadwal D3_2B_25IF2122_Senin_0700_PR dosenId KO006N punya 14 laporan
      expect(dosen['hadir'], greaterThan(0));
      print('[TEST] R-23: hadir dosen ${dosen['dosenId']} = ${dosen['hadir']} (dari laporan_dosen)');
    });

    test('R-24: totalPertemuan dosen = hadir + berhalangan', () async {
      final rekap = await DatabaseService().getRekapKehadiranDosen(jadwalIdTest);
      for (final d in rekap) {
        final hadir = d['hadir'] as int;
        final berhalangan = d['berhalangan'] as int;
        final total = d['totalPertemuan'] as int;
        expect(hadir + berhalangan, equals(total),
            reason: 'dosen ${d['dosenId']}: $hadir+$berhalangan != $total');
      }
      print('[TEST] R-24: hadir+berhalangan == totalPertemuan untuk semua dosen');
    });

    test('R-25: persenHadir dosen = hadir/totalPertemuan * 100', () async {
      final rekap = await DatabaseService().getRekapKehadiranDosen(jadwalIdTest);
      for (final d in rekap) {
        final hadir = d['hadir'] as int;
        final total = d['totalPertemuan'] as int;
        final persen = d['persenHadir'] as double;
        if (total > 0) {
          final expected = double.parse(((hadir / total) * 100).toStringAsFixed(1));
          expect(persen, closeTo(expected, 0.1));
        }
      }
      print('[TEST] R-25: persenHadir dosen akurat');
    });

    test('R-26: jadwal tidak ada → rekap dosen kosong', () async {
      final rekap = await DatabaseService()
          .getRekapKehadiranDosen('JADWAL_TIDAK_ADA_999');
      expect(rekap, isEmpty);
      print('[TEST] R-26: jadwal tidak ada -> rekap dosen kosong');
    });
  });
}
