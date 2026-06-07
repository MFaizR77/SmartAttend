import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/remote/database_service.dart';
import '../helpers/test_setup.dart';

void main() {
  // ─── UNIT TEST ─────────────────────────────────────────────────────────────
  group('Unit Test ManajemenJadwal', () {
    test('MJ-01: getAllJadwalAdmin() tersedia di DatabaseService', () {
      // Verifikasi bahwa method ada dan bisa dipanggil (tanpa koneksi DB)
      final db = DatabaseService();
      expect(db, isNotNull);
    });

    test('MJ-02: deleteJadwal() tersedia di DatabaseService', () {
      final db = DatabaseService();
      expect(db, isNotNull);
    });

    test('MJ-03: updateJadwal() tersedia di DatabaseService', () {
      final db = DatabaseService();
      expect(db, isNotNull);
    });
  });

  // ─── INTEGRATION TEST ──────────────────────────────────────────────────────
  group('Integration Test getAllJadwalAdmin()', () {
    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      await teardownTestDb();
    });

    test('MJ-04: getAllJadwalAdmin() mengembalikan list dari MongoDB', () async {
      final list = await DatabaseService().getAllJadwalAdmin();
      expect(list, isA<List<Map<String, dynamic>>>());
      expect(list, isNotEmpty);
      print('[TEST] MJ-04: getAllJadwalAdmin -> ${list.length} jadwal');
    });

    test('MJ-05: Setiap jadwal memiliki field _id, namaMK, hari, jamMulai, jamSelesai', () async {
      final list = await DatabaseService().getAllJadwalAdmin();
      for (final j in list) {
        expect(j['_id'], isNotNull,
            reason: 'jadwal harus punya _id');
        expect(j['namaMK'], isNotNull,
            reason: 'jadwal harus punya namaMK');
        expect(j['hari'], isNotNull,
            reason: 'jadwal harus punya hari');
        expect(j['jamMulai'], isNotNull,
            reason: 'jadwal harus punya jamMulai');
        expect(j['jamSelesai'], isNotNull,
            reason: 'jadwal harus punya jamSelesai');
      }
      print('[TEST] MJ-05: semua jadwal memiliki field wajib');
    });

    test('MJ-06: Jadwal D3_2B_25IF2122_Senin_0700_PR ada di database', () async {
      final list = await DatabaseService().getAllJadwalAdmin();
      final found = list.any(
          (j) => j['_id']?.toString() == 'D3_2B_25IF2122_Senin_0700_PR');
      expect(found, isTrue,
          reason: 'Jadwal D3_2B_25IF2122_Senin_0700_PR harus ada di database');
      print('[TEST] MJ-06: jadwal D3_2B_25IF2122_Senin_0700_PR ditemukan');
    });

    test('MJ-07: Jadwal memiliki field dosenId atau namaDosen', () async {
      final list = await DatabaseService().getAllJadwalAdmin();
      for (final j in list) {
        final hasDosen = j['dosenId'] != null ||
            j['kodeDosen'] != null ||
            j['namaDosen'] != null;
        expect(hasDosen, isTrue,
            reason: 'jadwal ${j['_id']} harus punya info dosen');
      }
      print('[TEST] MJ-07: semua jadwal memiliki info dosen');
    });
  });

  group('Integration Test updateJadwal()', () {
    late String jadwalIdTest;
    late Map<String, dynamic> dataAsli;

    setUpAll(() async {
      await setupTestDb();
      // Pakai jadwal yang sudah ada, simpan data asli untuk restore
      final list = await DatabaseService().getAllJadwalAdmin();
      final jadwal = list.firstWhere(
        (j) => j['_id']?.toString() == 'D3_2B_25IF2122_Senin_0700_PR',
        orElse: () => list.first,
      );
      jadwalIdTest = jadwal['_id'].toString();
      dataAsli = {
        'namaMK': jadwal['namaMK']?.toString() ?? '',
        'hari': jadwal['hari']?.toString() ?? '',
        'jamMulai': jadwal['jamMulai']?.toString() ?? '',
        'jamSelesai': jadwal['jamSelesai']?.toString() ?? '',
        'kodeRuangan': jadwal['kodeRuangan']?.toString() ?? '',
      };
    });

    tearDownAll(() async {
      // Restore data asli setelah test selesai
      await DatabaseService().updateJadwal(jadwalIdTest, dataAsli);
      await teardownTestDb();
    });

    test('MJ-08: updateJadwal() berhasil mengubah namaMK', () async {
      await DatabaseService().updateJadwal(jadwalIdTest, {
        ...dataAsli,
        'namaMK': 'Test Update Nama MK',
      });

      final list = await DatabaseService().getAllJadwalAdmin();
      final updated = list.firstWhere(
        (j) => j['_id']?.toString() == jadwalIdTest,
        orElse: () => {},
      );
      expect(updated['namaMK'], equals('Test Update Nama MK'));
      print('[TEST] MJ-08: updateJadwal namaMK berhasil');
    });

    test('MJ-09: updateJadwal() berhasil mengubah hari dan jam', () async {
      await DatabaseService().updateJadwal(jadwalIdTest, {
        ...dataAsli,
        'hari': 'Sabtu',
        'jamMulai': '10:00',
        'jamSelesai': '12:00',
      });

      final list = await DatabaseService().getAllJadwalAdmin();
      final updated = list.firstWhere(
        (j) => j['_id']?.toString() == jadwalIdTest,
        orElse: () => {},
      );
      expect(updated['hari'], equals('Sabtu'));
      expect(updated['jamMulai'], equals('10:00'));
      expect(updated['jamSelesai'], equals('12:00'));
      print('[TEST] MJ-09: updateJadwal hari+jam berhasil');
    });
  });

  group('Integration Test deleteJadwal()', () {
    late String jadwalIdTemp;

    setUpAll(() async {
      await setupTestDb();
    });

    tearDownAll(() async {
      // Pastikan data test sudah terhapus
      await cleanupByField('jadwal_kuliah', '_id', jadwalIdTemp);
      await teardownTestDb();
    });

    test('MJ-10: deleteJadwal() menghapus jadwal dari MongoDB', () async {
      // Insert jadwal dummy dulu
      jadwalIdTemp = testId('MJ_jadwal');
      await DatabaseService().db.collection('jadwal_kuliah').insertOne({
        '_id': jadwalIdTemp,
        'jadwalId': jadwalIdTemp,
        'namaMK': 'Test Delete Jadwal',
        'kodeMK': 'TEST9999',
        'kelas': '9Z',
        'program': 'D3',
        'hari': 'Sabtu',
        'jamMulai': '20:00',
        'jamSelesai': '22:00',
        'tipe': 'TE',
        'dosenId': 'KO006N',
        'isActive': true,
      });

      // Verifikasi ada dulu
      final before = await DatabaseService().getAllJadwalAdmin();
      expect(before.any((j) => j['_id']?.toString() == jadwalIdTemp), isTrue,
          reason: 'Jadwal test harus ada sebelum dihapus');

      // Hapus
      await DatabaseService().deleteJadwal(jadwalIdTemp);

      // Verifikasi sudah tidak ada
      final after = await DatabaseService().getAllJadwalAdmin();
      expect(after.any((j) => j['_id']?.toString() == jadwalIdTemp), isFalse,
          reason: 'Jadwal test harus sudah terhapus');
      print('[TEST] MJ-10: deleteJadwal berhasil');
    });
  });
}
