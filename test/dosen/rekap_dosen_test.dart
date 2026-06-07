import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/rekap/viewmodel/rekap_dosen_viewmodel.dart';
import 'package:smartattend/data/local/models/user.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test RekapDosenViewModel', () {
    late RekapDosenViewModel vm;

    setUp(() {
      vm = RekapDosenViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('RD-01: Initial isLoading = false', () {
      expect(vm.isLoading, false);
    });

    test('RD-02: Initial errorMessage = null', () {
      expect(vm.errorMessage, isNull);
    });

    test('RD-03: Initial rekapPerKelas kosong', () {
      expect(vm.rekapPerKelas, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test RekapDosenViewModel', () {
    const dosenId = 'KO006N';

    late RekapDosenViewModel vm;

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    setUp(() {
      vm = RekapDosenViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('RD-04: loadRekap() berhasil load data dari MongoDB', () async {
      final dosen = User(
        id: dosenId,
        nama: 'Irawan Thamrin',
        email: 'irawan.thamrin@polban.ac.id',
        role: UserRole.dosen,
        accountType: AccountType.dosen,
        passwordHash: '',
        createdAt: DateTime.now(),
      );
      await vm.loadRekap(dosen);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.rekapPerKelas, isA<Map<String, List<Map<String, dynamic>>>>());
      print('[TEST] RD-04: loadRekap -> ${vm.rekapPerKelas.length} grup kelas');
    });

    test('RD-05: rekapPerKelas tidak kosong untuk dosen yang punya laporan', () async {
      final dosen = User(
        id: dosenId,
        nama: 'Irawan Thamrin',
        email: 'irawan.thamrin@polban.ac.id',
        role: UserRole.dosen,
        accountType: AccountType.dosen,
        passwordHash: '',
        createdAt: DateTime.now(),
      );
      await vm.loadRekap(dosen);
      expect(vm.rekapPerKelas, isNotEmpty,
          reason: 'KO006N harus punya laporan mengajar');
      print('[TEST] RD-05: rekapPerKelas = ${vm.rekapPerKelas.keys.toList()}');
    });

    test('RD-06: Setiap laporan punya field jadwalId, tanggal, syncStatus', () async {
      final dosen = User(
        id: dosenId,
        nama: 'Irawan Thamrin',
        email: 'irawan.thamrin@polban.ac.id',
        role: UserRole.dosen,
        accountType: AccountType.dosen,
        passwordHash: '',
        createdAt: DateTime.now(),
      );
      await vm.loadRekap(dosen);
      for (final group in vm.rekapPerKelas.values) {
        for (final laporan in group) {
          expect(laporan['jadwalId'], isNotNull,
              reason: 'laporan harus punya jadwalId');
          expect(laporan['tanggal'], isNotNull,
              reason: 'laporan harus punya tanggal');
        }
      }
      print('[TEST] RD-06: semua laporan punya field wajib');
    });

    test('RD-07: getAllLaporanDosen() mengembalikan list berisi laporan', () async {
      final list = await DatabaseService().getAllLaporanDosen(dosenId);
      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list, isNotEmpty);
      print('[TEST] RD-07: getAllLaporanDosen -> ${list.length} laporan');
    });

    test('RD-08: getAllLaporanDosen() dosen tidak ada → list kosong', () async {
      final list = await DatabaseService().getAllLaporanDosen('DOSEN_TIDAK_ADA_999');
      expect(list, isEmpty);
      print('[TEST] RD-08: dosen tidak ada -> laporan kosong');
    });
  });
}
