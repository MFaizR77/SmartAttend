import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/pergantian_jadwal/viewmodel/pergantian_jadwal_viewmodel.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test PergantianJadwalViewModel', () {
    late PergantianJadwalViewModel vm;

    setUp(() {
      vm = PergantianJadwalViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('PJ-01: Initial isLoading = false', () {
      expect(vm.isLoading, false);
    });

    test('PJ-02: Initial errorMessage = null', () {
      expect(vm.errorMessage, isNull);
    });

    test('PJ-03: Initial riwayatPengajuan kosong', () {
      expect(vm.riwayatPengajuan, isEmpty);
    });

    test('PJ-04: Initial daftarJadwalAsli kosong', () {
      expect(vm.daftarJadwalAsli, isEmpty);
    });

    test('PJ-05: Initial daftarRuangan kosong', () {
      expect(vm.daftarRuangan, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test PergantianJadwalViewModel', () {
    const dosenId = 'KO006N';
    late PergantianJadwalViewModel vm;
    late String pengajuanIdTemp;

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      // Cleanup pengajuan test jika ada
      await cleanupByPattern('pengajuan_ganti_jadwal', 'jadwalIdAsli', '_test_');
      await teardownTestDb();
    });

    setUp(() {
      vm = PergantianJadwalViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('PJ-06: loadJadwalAsli() berhasil load jadwal dosen dari MongoDB', () async {
      await vm.loadJadwalAsli(dosenId);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.daftarJadwalAsli, isA<List<Map<String, dynamic>>>());
      expect(vm.daftarJadwalAsli, isNotEmpty,
          reason: '$dosenId harus punya jadwal');
      print('[TEST] PJ-06: loadJadwalAsli -> ${vm.daftarJadwalAsli.length} jadwal');
    });

    test('PJ-07: loadRiwayat() berhasil load riwayat pengajuan dari MongoDB', () async {
      await vm.loadRiwayat(dosenId);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.riwayatPengajuan, isA<List<Map<String, dynamic>>>());
      print('[TEST] PJ-07: loadRiwayat -> ${vm.riwayatPengajuan.length} riwayat');
    });

    test('PJ-08: cariRuangan() mengembalikan daftar ruangan dengan status', () async {
      final tanggal = DateTime(2026, 9, 5); // Sabtu, tidak ada jadwal
      await vm.cariRuangan(tanggal, '10:00', '12:00');
      expect(vm.isLoading, false);
      expect(vm.daftarRuangan, isA<List<Map<String, dynamic>>>());
      for (final r in vm.daftarRuangan) {
        expect(r['nama'], isNotNull);
        expect(r['isTerpakai'], isA<bool>());
      }
      print('[TEST] PJ-08: cariRuangan -> ${vm.daftarRuangan.length} ruangan');
    });

    test('PJ-09: getPengajuanDosen() mengembalikan list', () async {
      final list = await DatabaseService().getPengajuanDosen(dosenId);
      expect(list, isA<List<Map<String, dynamic>>>());
      print('[TEST] PJ-09: getPengajuanDosen -> ${list.length} pengajuan');
    });

    test('PJ-10: ajukan() berhasil submit pengajuan ke MongoDB', () async {
      final jadwalAsli = {
        'jadwalId': testId('PJ_jadwal'),
        'namaMK': 'Test Pergantian Jadwal',
        'kelas': '9Z',
      };
      final tanggal = DateTime(2026, 9, 7);

      final ok = await vm.ajukan(
        dosenId,
        jadwalAsli,
        tanggal,
        '10:00',
        '12:00',
        'Lab-Test',
      );
      expect(ok, isTrue,
          reason: 'ajukan() harus berhasil');
      expect(vm.errorMessage, isNull);
      print('[TEST] PJ-10: ajukan() berhasil, status=${vm.errorMessage ?? 'ok'}');

      // Simpan ID untuk cleanup
      final riwayat = await DatabaseService().getPengajuanDosen(dosenId);
      final inserted = riwayat.where((r) =>
        r['namaMK']?.toString() == 'Test Pergantian Jadwal').toList();
      if (inserted.isNotEmpty) {
        pengajuanIdTemp = inserted.first['_id'].toString();
        await cleanupById('pengajuan_ganti_jadwal', inserted.first['_id']);
      }
    });

    test('PJ-11: Riwayat pengajuan punya field status (pending/approved/rejected)', () async {
      await vm.loadRiwayat(dosenId);
      for (final r in vm.riwayatPengajuan) {
        final status = r['status']?.toString() ?? '';
        expect(
          ['pending', 'approved', 'rejected'].contains(status) || status.isEmpty,
          isTrue,
          reason: 'status harus pending/approved/rejected',
        );
      }
      print('[TEST] PJ-11: semua status riwayat valid');
    });
  });
}
