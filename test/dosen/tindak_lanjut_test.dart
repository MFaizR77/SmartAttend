import 'package:flutter_test/flutter_test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smartattend/data/remote/database_service.dart';
import 'package:smartattend/features/dosen/tindak_lanjut_izin/viewmodel/tindak_lanjut_viewmodel.dart';
import 'package:smartattend/data/local/models/user.dart';
import '../helpers/test_setup.dart';

void main() {
  final createdClientUuids = <String>[];
  final createdJadwalIds = <String>[];
  final createdIzinIds = <dynamic>[];

  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test TindakLanjutIzinViewModel', () {
    late TindakLanjutIzinViewModel vm;

    setUp(() {
      vm = TindakLanjutIzinViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('TL-01: Initial isLoading = false', () {
      expect(vm.isLoading.value, false);
    });

    test('TL-02: Initial errorMessage = null', () {
      expect(vm.errorMessage.value, isNull);
    });

    test('TL-03: Initial izinList kosong', () {
      expect(vm.izinList.value, isEmpty);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test TindakLanjutIzinViewModel', () {
    const dosenId = 'KO006N';
    late TindakLanjutIzinViewModel vm;
    late User testDosen;

    setUpAll(() async {
      await setupTestDb();
      testDosen = User(
        id: dosenId,
        nama: 'Irawan Thamrin',
        email: 'irawan@polban.ac.id',
        role: UserRole.dosen,
        accountType: AccountType.dosen,
        passwordHash: '',
        createdAt: DateTime.now(),
      );
    });

    tearDownAll(() async {
      for (final uuid in createdClientUuids) {
        await cleanupByField('izin_mahasiswa', 'clientUuid', uuid);
      }
      for (final id in createdJadwalIds) {
        await cleanupByField('jadwal_kuliah', '_id', id);
      }
      for (final id in createdIzinIds) {
        await cleanupById('izin_mahasiswa', id);
      }
      await teardownTestDb();
    });

    setUp(() {
      vm = TindakLanjutIzinViewModel();
    });

    tearDown(() {
      vm.dispose();
    });

    test('TL-04: load() berhasil mendapatkan izin approved_wali yang berdampak pada jadwal dosen', () async {
      final testJadwalId = testId('TL_jadwal');
      createdJadwalIds.add(testJadwalId);

      // 1. Insert jadwal dummy untuk dosen
      await DatabaseService().db.collection('jadwal_kuliah').insertOne({
        '_id': testJadwalId,
        'jadwalId': testJadwalId,
        'namaMK': 'Test Tindak Lanjut',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '09:00',
        'kelas': '9Z',
        'dosenId': dosenId,
        'isActive': true,
      });

      // 2. Insert izin_mahasiswa dummy dengan status 'approved_wali'
      final uuid = testId('TL_mhs');
      final mhsId = testId('mhs');
      createdClientUuids.add(uuid);

      await DatabaseService().db.collection('izin_mahasiswa').insertOne({
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Mahasiswa Test TL',
        'kelas': '9Z',
        'program': 'D3',
        'jenis': 'izin',
        'status': 'approved_wali',
        'jadwalIdsTerdampak': [testJadwalId],
        'tindakLanjutDosen': [
          {
            'jadwalId': testJadwalId,
            'dosenId': dosenId,
            'statusFinal': 'pending',
          }
        ],
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await vm.load(testDosen);

      expect(vm.isLoading.value, false);
      expect(vm.errorMessage.value, isNull);
      expect(vm.izinList.value, isNotEmpty);

      final found = vm.izinList.value.any((iz) => iz['clientUuid'] == uuid);
      expect(found, isTrue, reason: 'Izin dummy harus berhasil dimuat');
      print('[TEST] TL-04: load() berhasil memuat izin tindak lanjut dosen');
    });

    test('TL-05: tandai() berhasil mengubah status final izin mahasiswa', () async {
      final testJadwalId = testId('TL_jadwal_tandai');
      createdJadwalIds.add(testJadwalId);

      // 1. Insert jadwal dummy
      await DatabaseService().db.collection('jadwal_kuliah').insertOne({
        '_id': testJadwalId,
        'jadwalId': testJadwalId,
        'namaMK': 'Test Tandai Final',
        'hari': 'Selasa',
        'jamMulai': '10:00',
        'jamSelesai': '12:00',
        'kelas': '9Z',
        'dosenId': dosenId,
        'isActive': true,
      });

      // 2. Insert izin_mahasiswa
      final uuid = testId('TL_mhs_tandai');
      final mhsId = testId('mhs_tandai');
      createdClientUuids.add(uuid);

      final izinObjId = ObjectId();
      createdIzinIds.add(izinObjId);

      await DatabaseService().db.collection('izin_mahasiswa').insertOne({
        '_id': izinObjId,
        'clientUuid': uuid,
        'mahasiswaId': mhsId,
        'namaMahasiswa': 'Mahasiswa Test Tandai',
        'kelas': '9Z',
        'program': 'D3',
        'jenis': 'sakit',
        'status': 'approved_wali',
        'jadwalIdsTerdampak': [testJadwalId],
        'tindakLanjutDosen': [
          {
            'jadwalId': testJadwalId,
            'dosenId': dosenId,
            'statusFinal': 'pending',
          }
        ],
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 3. Panggil tandai() untuk menyetujui sakit
      final success = await vm.tandai(
        izinId: izinObjId,
        jadwalId: testJadwalId,
        dosenKode: dosenId,
        statusFinal: 'sakit',
        catatan: 'Surat dokter valid',
      );

      expect(success, isTrue);

      // 4. Verifikasi ke database
      final updatedIzin = await DatabaseService().db.collection('izin_mahasiswa').findOne(where.id(izinObjId));
      expect(updatedIzin, isNotNull);

      final tindakLanjutList = updatedIzin!['tindakLanjutDosen'] as List;
      final match = tindakLanjutList.firstWhere((t) => t['jadwalId'] == testJadwalId);
      expect(match['statusFinal'], 'sakit');
      expect(match['catatanDosen'], 'Surat dokter valid');
      expect(match['ditandaiOleh'], dosenId);
      print('[TEST] TL-05: tandai() berhasil mengubah statusFinal menjadi sakit');
    });
  });
}
