import 'package:flutter_test/flutter_test.dart';
import 'package:smartattend/data/local/models/user.dart';
import 'package:smartattend/data/local/models/pengajuan_izin.dart';

void main() {
  group('User Model — Wali Dosen', () {
    test('W-01: fromMap() punya kelasWali', () {
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

    test('W-02: roleLabel = "Wali Dosen"', () {
      final user = User(
        id: 'WD001',
        nama: 'Test',
        email: 'test@test.com',
        role: UserRole.dosen,
        accountType: AccountType.walidosen,
        passwordHash: 'pass',
        createdAt: DateTime.now(),
        kelasWali: '2B',
      );
      expect(user.roleLabel, 'Wali Dosen');
    });
  });

  group('PengajuanIzin — Approve/Reject', () {
    test('W-03: approve() → status approved, disetujuiOleh tercatat', () {
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

    test('W-04: reject() → status rejected, catatanDosen tercatat', () {
      final izin = PengajuanIzin(
        id: '1', clientUuid: 'u1', mahasiswaId: 'm1', sesiId: 's1',
        jenis: 'izin', keterangan: 'Acara',
        statusApproval: 'pending', syncStatus: 'synced',
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final rejected = izin.reject('WD001', 'Tidak ada surat');
      expect(rejected.statusApproval, 'rejected');
      expect(rejected.catatanDosen, 'Tidak ada surat');
    });
  });
}
