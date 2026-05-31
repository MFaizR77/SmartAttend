import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/local/models/user.dart';
import 'package:smartattend/data/local/models/jadwal_kuliah.dart';
import 'package:smartattend/data/local/models/record_presensi.dart';
import 'package:smartattend/data/local/models/sesi_absensi.dart';
import 'package:smartattend/data/local/models/pengajuan_izin.dart';

void main() {
  group('User Model', () {
    test('M-01: fromMap() parsing data mahasiswa', () {
      final map = {
        'id': '2206001',
        'nama': 'Ahmad Fauzi',
        'email': 'ahmad@poltekpos.ac.id',
        'passwordHash': 'hashed',
        'kelas': '2B',
        'program': 'D3',
        'role': 'mahasiswa',
        'accountType': 'mahasiswa',
        'createdAt': '2025-09-01T00:00:00.000',
      };
      final user = User.fromMap(map);
      expect(user.id, '2206001');
      expect(user.nama, 'Ahmad Fauzi');
      expect(user.accountType, AccountType.mahasiswa);
      expect(user.kelas, '2B');
    });

    test('M-02: fromMap() parsing data dosen', () {
      final map = {
        'id': 'KO006N',
        'nama': 'Muhammad Faiz',
        'email': 'faiz@poltekpos.ac.id',
        'passwordHash': 'pass',
        'role': 'dosen',
        'accountType': 'dosen',
        'createdAt': '2025-09-01T00:00:00.000',
      };
      final user = User.fromMap(map);
      expect(user.accountType, AccountType.dosen);
      expect(user.roleLabel, 'Dosen');
    });

    test('M-03: fromMap() parsing data walidosen', () {
      final map = {
        'id': 'WD_KO006N_2B_D3',
        'nama': 'Muhammad Faiz',
        'email': 'faiz@poltekpos.ac.id',
        'passwordHash': 'pass',
        'dosenKode': 'KO006N',
        'kelasWali': '2B',
        'program': 'D3',
        'role': 'walidosen',
        'accountType': 'walidosen',
        'createdAt': '2025-09-01T00:00:00.000',
      };
      final user = User.fromMap(map);
      expect(user.accountType, AccountType.walidosen);
      expect(user.kelasWali, '2B');
      expect(user.dosenKode, 'KO006N');
    });

    test('M-04: toMap() output benar', () {
      final user = User(
        id: '2206001',
        nama: 'Ahmad',
        email: 'ahmad@test.com',
        role: UserRole.mahasiswa,
        accountType: AccountType.mahasiswa,
        passwordHash: 'pass',
        createdAt: DateTime(2025, 9, 1),
        kelas: '2B',
        program: 'D3',
      );
      final map = user.toMap();
      expect(map['id'], '2206001');
      expect(map['accountType'], 'mahasiswa');
      expect(map['kelas'], '2B');
    });

    test('M-05: roleLabel sesuai accountType', () {
      final mhs = User(
        id: '1', nama: 'A', email: 'a', role: UserRole.mahasiswa,
        accountType: AccountType.mahasiswa, passwordHash: '', createdAt: DateTime.now(),
      );
      final dsn = User(
        id: '2', nama: 'B', email: 'b', role: UserRole.dosen,
        accountType: AccountType.dosen, passwordHash: '', createdAt: DateTime.now(),
      );
      final wl = User(
        id: '3', nama: 'C', email: 'c', role: UserRole.dosen,
        accountType: AccountType.walidosen, passwordHash: '', createdAt: DateTime.now(),
      );
      final adm = User(
        id: '4', nama: 'D', email: 'd', role: UserRole.admin,
        accountType: AccountType.admin, passwordHash: '', createdAt: DateTime.now(),
      );
      expect(mhs.roleLabel, 'Mahasiswa');
      expect(dsn.roleLabel, 'Dosen');
      expect(wl.roleLabel, 'Wali Dosen');
      expect(adm.roleLabel, 'Admin');
    });

    test('M-06: kelasDisplay format', () {
      final dengan = User(
        id: '1', nama: 'A', email: 'a', role: UserRole.mahasiswa,
        accountType: AccountType.mahasiswa, passwordHash: '', createdAt: DateTime.now(),
        kelas: '2B', program: 'D3',
      );
      final tanpa = User(
        id: '2', nama: 'B', email: 'b', role: UserRole.mahasiswa,
        accountType: AccountType.mahasiswa, passwordHash: '', createdAt: DateTime.now(),
      );
      expect(dengan.kelasDisplay, '2B-D3');
      expect(tanpa.kelasDisplay, isNull);
    });
  });

  group('JadwalKuliah Model', () {
    test('M-07: fromMap() parsing lengkap', () {
      final map = {
        '_id': 'D3_2B_25IF2122_Senin_0700_PR',
        'kodeMK': '25IF2122',
        'namaMK': 'Pemrograman Mobile',
        'kelas': '2B',
        'program': 'D3',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '08:30',
        'tipe': 'PR',
        'ruangan': 'LAB-01',
        'dosenIds': ['KO006N'],
        'namaDosen': 'Muhammad Faiz',
        'isActive': true,
      };
      final j = JadwalKuliah.fromMap(map);
      expect(j.id, 'D3_2B_25IF2122_Senin_0700_PR');
      expect(j.namaMK, 'Pemrograman Mobile');
      expect(j.hari, 'Senin');
      expect(j.tipe, 'PR');
    });

    test('M-08: fromMap() team teaching', () {
      final map = {
        '_id': 'D3_2B_25IF2122_Senin_0700_PR',
        'kodeMK': '25IF2122',
        'namaMK': 'Proyek',
        'kelas': '2B',
        'program': 'D3',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '08:30',
        'tipe': 'PR',
        'ruangan': 'LAB-01',
        'dosenIds': ['KO006N', 'KO003N'],
        'namaDosen': 'Faiz; Bambang',
        'isActive': true,
      };
      final j = JadwalKuliah.fromMap(map);
      expect(j.dosenIds.length, 2);
      expect(j.dosenIds, contains('KO006N'));
      expect(j.dosenIds, contains('KO003N'));
    });

    test('M-09: fromMap() fallback dosenId tunggal', () {
      final map = {
        '_id': 'D3_2B_25IF2122_Senin_0700_PR',
        'kodeMK': '25IF2122',
        'namaMK': 'Pemrograman Mobile',
        'kelas': '2B',
        'program': 'D3',
        'hari': 'Senin',
        'jamMulai': '07:00',
        'jamSelesai': '08:30',
        'tipe': 'PR',
        'ruangan': 'LAB-01',
        'dosenId': 'KO006N',
        'namaDosen': 'Faiz',
        'isActive': true,
      };
      final j = JadwalKuliah.fromMap(map);
      expect(j.dosenIds, ['KO006N']);
    });

    test('M-10: toDisplayMap() output', () {
      final j = JadwalKuliah(
        id: 'D3_2B_25IF2122_Senin_0700_PR',
        kodeMK: '25IF2122',
        namaMK: 'Pemrograman Mobile',
        kelas: '2B',
        program: 'D3',
        hari: 'Senin',
        jamMulai: '07:00',
        jamSelesai: '08:30',
        tipe: 'PR',
        ruangan: 'LAB-01',
        dosenIds: ['KO006N'],
        namaDosen: 'Faiz',
        isActive: true,
        cachedAt: DateTime(2026, 1, 1),
      );
      final d = j.toDisplayMap();
      expect(d['_id'], 'D3_2B_25IF2122_Senin_0700_PR');
      expect(d['namaMK'], 'Pemrograman Mobile');
      expect(d['jamMulai'], '07:00');
    });
  });

  group('RecordPresensi Model', () {
    test('M-11: fromMap() parsing', () {
      final map = {
        'id': 'rec-001',
        'clientUuid': 'uuid-001',
        'sesiId': 'sesi-1',
        'mahasiswaId': '2206001',
        'timestamp': '2026-06-01T07:05:00.000',
        'statusHadir': true,
        'metode': 'manual',
        'syncStatus': 'pending',
        'createdAt': '2026-06-01T07:05:00.000',
        'updatedAt': '2026-06-01T07:05:00.000',
      };
      final r = RecordPresensi.fromMap(map);
      expect(r.clientUuid, 'uuid-001');
      expect(r.statusHadir, true);
      expect(r.syncStatus, 'pending');
    });

    test('M-12: markAsSynced()', () {
      final r = RecordPresensi(
        id: 'rec-001',
        clientUuid: 'uuid-001',
        sesiId: 'sesi-1',
        mahasiswaId: '2206001',
        timestamp: DateTime(2026, 6, 1),
        statusHadir: true,
        metode: 'manual',
        syncStatus: 'pending',
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );
      final synced = r.markAsSynced();
      expect(synced.syncStatus, 'synced');
    });
  });

  group('SesiAbsensi Model', () {
    test('M-13: open() → status open', () {
      final s = SesiAbsensi(
        sesiId: '1', jadwalId: '1', tanggal: DateTime.now(),
        status: 'closed', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final opened = s.open('KO006N');
      expect(opened.status, 'open');
      expect(opened.dibukaOleh, 'KO006N');
    });

    test('M-14: close() → status closed', () {
      final s = SesiAbsensi(
        sesiId: '1', jadwalId: '1', tanggal: DateTime.now(),
        status: 'open', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final closed = s.close();
      expect(closed.status, 'closed');
      expect(closed.closedAt, isNotNull);
    });

    test('M-15: autoOpen() → status auto', () {
      final s = SesiAbsensi(
        sesiId: '1', jadwalId: '1', tanggal: DateTime.now(),
        status: 'closed', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final auto = s.autoOpen();
      expect(auto.status, 'auto');
      expect(auto.dibukaOleh, 'system');
    });

    test('M-16: isOpen getter', () {
      final open = SesiAbsensi(
        sesiId: '1', jadwalId: '1', tanggal: DateTime.now(),
        status: 'open', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final closed = SesiAbsensi(
        sesiId: '2', jadwalId: '2', tanggal: DateTime.now(),
        status: 'closed', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      expect(open.isOpen, true);
      expect(closed.isOpen, false);
    });
  });

  group('PengajuanIzin Model', () {
    test('M-17: approve() → status approved', () {
      final izin = PengajuanIzin(
        id: '1', clientUuid: 'u1', mahasiswaId: 'm1', sesiId: 's1',
        jenis: 'sakit', keterangan: 'Demam',
        statusApproval: 'pending', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final approved = izin.approve('WD001', 'Disetujui');
      expect(approved.statusApproval, 'approved');
      expect(approved.disetujuiOleh, 'WD001');
      expect(approved.catatanDosen, 'Disetujui');
    });

    test('M-18: reject() → status rejected', () {
      final izin = PengajuanIzin(
        id: '1', clientUuid: 'u1', mahasiswaId: 'm1', sesiId: 's1',
        jenis: 'izin', keterangan: 'Acara',
        statusApproval: 'pending', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final rejected = izin.reject('WD001', 'Tolak');
      expect(rejected.statusApproval, 'rejected');
      expect(rejected.catatanDosen, 'Tolak');
    });

    test('M-19: markAsSynced()', () {
      final izin = PengajuanIzin(
        id: '1', clientUuid: 'u1', mahasiswaId: 'm1', sesiId: 's1',
        jenis: 'sakit', keterangan: 'Demam',
        statusApproval: 'pending', syncStatus: 'pending',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final synced = izin.markAsSynced();
      expect(synced.syncStatus, 'synced');
    });
  });
}
