import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/izin/viewmodel/izin_dosen_viewmodel.dart';
import '../helpers/test_setup.dart';

void main() {
  // Track IDs untuk cleanup
  final createdIzinIds = <String>[];
  final createdJadwalIds = <String>[];

  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test IzinDosenViewModel', () {
    late IzinDosenViewModel vm;

    setUp(() {
      vm = IzinDosenViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('ID-01: Initial isLoading = false', () {
      expect(vm.isLoading, false);
    });

    test('ID-02: Initial errorMessage = null', () {
      expect(vm.errorMessage, isNull);
    });

    test('ID-03: Initial jadwalHariIni kosong', () {
      expect(vm.jadwalHariIni, isEmpty);
    });

    test('ID-04: Initial riwayatIzin kosong', () {
      expect(vm.riwayatIzin, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test IzinDosenViewModel', () {
    const dosenId = 'KO006N'; // Dosen yang digunakan untuk pengujian
    late IzinDosenViewModel vm;

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      // Cleanup data test yang dibuat
      for (final id in createdIzinIds) {
        await cleanupByField('izin_dosen', 'dosenId', id);
      }
      for (final id in createdJadwalIds) {
        await cleanupByField('jadwal_kuliah', '_id', id);
      }
      await teardownTestDb();
    });

    setUp(() {
      vm = IzinDosenViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('ID-05: loadJadwalByTanggal() berhasil memuat jadwal dari MongoDB', () async {
      final testJadwalId = testId('ID_jadwal');
      createdJadwalIds.add(testJadwalId);

      final tanggalTest = DateTime(2026, 9, 7); // Hari Senin
      final hariName = DatabaseService().getHariFromDate(tanggalTest); // 'Senin'

      // Insert jadwal dummy untuk hari Senin
      await DatabaseService().db.collection('jadwal_kuliah').insertOne({
        '_id': testJadwalId,
        'jadwalId': testJadwalId,
        'namaMK': 'Test Izin Dosen',
        'hari': hariName,
        'jamMulai': '08:00',
        'jamSelesai': '10:00',
        'kelas': '9Z',
        'tipe': 'TE',
        'dosenId': dosenId,
        'isActive': true,
      });

      await vm.loadJadwalByTanggal(dosenId, tanggalTest);

      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.jadwalHariIni, isNotEmpty);

      final found = vm.jadwalHariIni.any((j) => j['_id'] == testJadwalId);
      expect(found, isTrue, reason: 'Jadwal dummy harus ditemukan');
      print('[TEST] ID-05: loadJadwalByTanggal berhasil memuat jadwal dummy');
    });

    test('ID-06: submitIzin() berhasil menyimpan pengajuan izin/sakit ke MongoDB', () async {
      final testDosenId = testId('ID_dosen');
      createdIzinIds.add(testDosenId);

      final tanggalTest = DateTime(2026, 9, 7);
      final dummyJadwal = {
        '_id': 'dummy_jadwal_id',
        'namaMK': 'Pemrograman Mobile',
        'kelas': '2B',
        'jamMulai': '07:00',
        'jamSelesai': '09:00',
      };

      final success = await vm.submitIzin(
        dosenId: testDosenId,
        tanggal: tanggalTest,
        jadwal: dummyJadwal,
        jenis: 'izin',
        keterangan: 'Ada kepentingan keluarga mendesak',
      );

      expect(success, isTrue);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);

      // Verifikasi di database
      final record = await DatabaseService().db.collection('izin_dosen').findOne({
        'dosenId': testDosenId,
      });

      expect(record, isNotNull);
      expect(record!['jenis'], 'izin');
      expect(record['keterangan'], 'Ada kepentingan keluarga mendesak');
      expect(record['namaMK'], 'Pemrograman Mobile');
      expect(record['status'], 'pending');
      print('[TEST] ID-06: submitIzin berhasil menyimpan data ke koleksi izin_dosen');
    });

    test('ID-07: loadJadwalByTanggal() pada hari tanpa jadwal mengembalikan list kosong', () async {
      final tanggalTest = DateTime(2026, 9, 6); // Hari Minggu
      await vm.loadJadwalByTanggal(dosenId, tanggalTest);

      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.jadwalHariIni, isEmpty);
      print('[TEST] ID-07: loadJadwalByTanggal hari Minggu -> list kosong');
    });
  });
}
