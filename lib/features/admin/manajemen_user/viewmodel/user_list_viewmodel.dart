import 'package:flutter/foundation.dart';
import '../../../../data/remote/database_service.dart';

/// ViewModel untuk halaman Manajemen User Admin.
/// Menyimpan daftar per tipe user dan state loading/error.
class UserListViewModel {
  final ValueNotifier<List<Map<String, dynamic>>> mahasiswa = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> dosen = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> waliDosen = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> kaprodi = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  final _db = DatabaseService();

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final grouped = await _db.getAllUsersGrouped();
      mahasiswa.value = grouped['mahasiswa'] ?? [];
      dosen.value = grouped['dosen'] ?? [];
      waliDosen.value = grouped['waliDosen'] ?? [];
      kaprodi.value = grouped['kaprodi'] ?? [];
    } catch (e) {
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Mahasiswa ──────────────────────────────────────────────────────────────

  Future<String?> insertMahasiswa({
    required String nim,
    required String nama,
    required String email,
    required String password,
    required String kelas,
    required String program,
    required int semester,
  }) async {
    try {
      await _db.insertMahasiswa(
        nim: nim,
        nama: nama,
        email: email,
        password: password,
        kelas: kelas,
        program: program,
        semester: semester,
      );
      await load();
      return null; // sukses
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateMahasiswa({
    required String nim,
    required String nama,
    required String email,
    String? password,
    required String kelas,
    required String program,
    required int semester,
  }) async {
    try {
      await _db.updateMahasiswa(
        nim: nim,
        nama: nama,
        email: email,
        password: password,
        kelas: kelas,
        program: program,
        semester: semester,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Dosen ──────────────────────────────────────────────────────────────────

  Future<String?> insertDosen({
    required String kode,
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      await _db.insertDosen(
        kode: kode,
        nama: nama,
        email: email,
        password: password,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDosen({
    required String kode,
    required String nama,
    required String email,
    String? password,
  }) async {
    try {
      await _db.updateDosen(
        kode: kode,
        nama: nama,
        email: email,
        password: password,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Wali Dosen ─────────────────────────────────────────────────────────────
  // Wali dosen dikelola melalui fitur Assign Wali — tidak ada insert/update di sini.

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<String?> deleteMahasiswa(String nim) async {
    try {
      await _db.deleteMahasiswa(nim);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteDosen(String kode) async {
    try {
      await _db.deleteDosen(kode);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Bulk Upload ────────────────────────────────────────────────────────────

  Future<String?> bulkInsertMahasiswa(List<Map<String, dynamic>> rows) async {
    try {
      await _db.bulkInsertMahasiswa(rows);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> bulkInsertDosen(List<Map<String, dynamic>> rows) async {
    try {
      await _db.bulkInsertDosen(rows);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void dispose() {
    mahasiswa.dispose();
    dosen.dispose();
    waliDosen.dispose();
    kaprodi.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
