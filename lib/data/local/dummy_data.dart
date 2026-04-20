import 'models/user.dart';

/// Data dummy untuk development UI.
/// Ganti dengan Hive/MongoDB nanti saat backend siap.
class DummyData {
  DummyData._();

  // ──────────────────────────────────────────
  // Akun dummy (password semua: 123456)
  // ──────────────────────────────────────────

  static final List<User> users = [
    User(
      id: 'mhs-001',
      nama: 'Idham Khalid',
      email: 'mahasiswa@smartattend.com',
      role: UserRole.mahasiswa,
      passwordHash: '123456',
      createdAt: DateTime(2026, 1, 1),
    ),
    User(
      id: 'dsn-001',
      nama: 'Dr. Ahmad Fauzi',
      email: 'dosen@smartattend.com',
      role: UserRole.dosen,
      passwordHash: '123456',
      createdAt: DateTime(2026, 1, 1),
    ),
    User(
      id: 'adm-001',
      nama: 'Admin SmartAttend',
      email: 'admin@smartattend.com',
      role: UserRole.admin,
      passwordHash: '123456',
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  // ──────────────────────────────────────────
  // Jadwal kuliah dummy
  // ──────────────────────────────────────────

  static final List<Map<String, String>> jadwalHariIni = [
    {
      'mataKuliah': 'Pemrograman Mobile',
      'jam': '08:00 - 10:00',
      'ruang': 'Lab 3.1',
      'dosen': 'Dr. Ahmad Fauzi',
    },
    {
      'mataKuliah': 'Basis Data Lanjut',
      'jam': '10:15 - 12:15',
      'ruang': 'R. 204',
      'dosen': 'Ir. Siti Rahayu',
    },
    {
      'mataKuliah': 'Rekayasa Perangkat Lunak',
      'jam': '13:00 - 15:00',
      'ruang': 'R. 301',
      'dosen': 'Dr. Budi Santoso',
    },
  ];

  // ──────────────────────────────────────────
  // Statistik kehadiran dummy (mahasiswa)
  // ──────────────────────────────────────────

  static const int totalHadir = 34;
  static const int totalIzin = 4;
  static const int totalAlpha = 2;
  static int get totalPertemuan => totalHadir + totalIzin + totalAlpha;

  // ──────────────────────────────────────────
  // Statistik admin dummy
  // ──────────────────────────────────────────

  static const int totalMahasiswa = 120;
  static const int totalDosen = 15;
  static const int sesiHariIni = 8;
  static const double tingkatKehadiran = 87.5;

  // ──────────────────────────────────────────
  // Log aktivitas dummy (admin)
  // ──────────────────────────────────────────

  static final List<Map<String, String>> logAktivitas = [
    {
      'aksi': 'Mahasiswa Idham check-in Pemrograman Mobile',
      'waktu': '08:05',
    },
    {
      'aksi': 'Dr. Ahmad Fauzi membuka sesi Pemrograman Mobile',
      'waktu': '07:58',
    },
    {
      'aksi': 'Mahasiswa Rina mengajukan izin sakit',
      'waktu': '07:30',
    },
    {
      'aksi': 'Sesi Basis Data auto-open (dosen belum hadir)',
      'waktu': '10:15',
    },
  ];

  // ──────────────────────────────────────────
  // Statistik dosen dummy
  // ──────────────────────────────────────────

  static const int mahasiswaHadirHariIni = 28;
  static const int totalMahasiswaKelas = 32;
  static const int pengajuanIzinPending = 3;
}
