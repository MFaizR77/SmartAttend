import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  final createdClientUuids = <String>[];
  final createdIzinIds = <dynamic>[];

  setUpAll(() async {
    await setupTestDb();
  });

  tearDownAll(() async {
    for (final uuid in createdClientUuids) {
      await cleanupByField('izin_mahasiswa', 'clientUuid', uuid);
    }
    for (final id in createdIzinIds) {
      await cleanupById('izin_mahasiswa', id);
    }
    await teardownTestDb();
  });

  group('getIzinPendingByWali() — Integration', () {
    test('A-01: Izin pending untuk kelas yang sesuai → returned', () async {
      final kelas = testId('kelas');
      final uuid = testId('wali');
      final mhsId = testId('mhs');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Test Wali',
        'kelas': kelas,
        'program': 'D3',
        'jenis': 'sakit',
        'keterangan': 'Test wali',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: kelas,
        program: 'D3',
      );

      expect(pending.isNotEmpty, true);
      expect(pending.first['kelas'], kelas);
      expect(pending.first['status'], 'pending_wali');
    });

    test('A-02: Izin untuk kelas lain → tidak returned', () async {
      final kelas = testId('kelasLain');
      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: kelas,
        program: 'D3',
      );
      final adaIzinKelasIni = pending.where((p) => p['kelas'] == kelas).toList();
      expect(adaIzinKelasIni.isEmpty, true);
    });
  });

  group('approveIzinByWali() — Integration', () {
    test('A-03: Approve → status approved_wali', () async {
      final uuid = testId('appr');
      final mhsId = testId('mhs');
      final kelas = testId('kappr');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Test Approve',
        'kelas': kelas,
        'program': 'D3',
        'jenis': 'sakit',
        'keterangan': 'Test approve',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: kelas,
        program: 'D3',
      );
      expect(pending.isNotEmpty, true);

      final izinId = pending.first['_id'];
      createdIzinIds.add(izinId);

      await DatabaseService().approveIzinByWali(
        izinId: izinId,
        walidosenId: 'WD_TEST',
        catatan: 'Disetujui otomatis',
      );

      final izin = await DatabaseService().getIzinById(izinId);
      expect(izin, isNotNull);
      expect(izin!['status'], 'approved_wali');
      expect(izin['approvedByWali'], 'WD_TEST');
      expect(izin['catatanWali'], 'Disetujui otomatis');
    });
  });

  group('rejectIzinByWali() — Integration', () {
    test('A-04: Reject → status rejected_wali', () async {
      final uuid = testId('rej');
      final mhsId = testId('mhs');
      final kelas = testId('krej');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Test Reject',
        'kelas': kelas,
        'program': 'D3',
        'jenis': 'izin',
        'keterangan': 'Test reject',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: kelas,
        program: 'D3',
      );
      expect(pending.isNotEmpty, true);

      final izinId = pending.first['_id'];
      createdIzinIds.add(izinId);

      await DatabaseService().rejectIzinByWali(
        izinId: izinId,
        walidosenId: 'WD_TEST',
        catatan: 'Ditolak',
      );

      final izin = await DatabaseService().getIzinById(izinId);
      expect(izin, isNotNull);
      expect(izin!['status'], 'rejected_wali');
      expect(izin['rejectedByWali'], 'WD_TEST');
    });
  });

  group('getIzinById() — Integration', () {
    test('A-05: ID valid → dokumen returned', () async {
      final uuid = testId('byid');
      final mhsId = testId('mhs');
      final kelas = testId('kbyid');
      createdClientUuids.add(uuid);

      await DatabaseService().submitIzinMahasiswa({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Test GetById',
        'kelas': kelas,
        'program': 'D3',
        'jenis': 'sakit',
        'keterangan': 'Test getbyid',
        'jadwalIdsTerdampak': [],
        'tindakLanjutDosen': [],
        'cakupan': 'penuh',
      });

      final pending = await DatabaseService().getIzinPendingByWali(
        kelas: kelas,
        program: 'D3',
      );
      expect(pending.isNotEmpty, true);

      final izinId = pending.first['_id'];
      createdIzinIds.add(izinId);

      final izin = await DatabaseService().getIzinById(izinId);
      expect(izin, isNotNull);
      expect(izin!['_id'], izinId);
    });

    test('A-06: ID tidak valid → null', () async {
      final fakeId = ObjectId.fromHexString('000000000000000000000000');
      final izin = await DatabaseService().getIzinById(fakeId);
      expect(izin, isNull);
    });
  });
}
