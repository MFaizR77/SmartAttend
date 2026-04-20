/// Role pengguna dalam sistem SmartAttend.
enum UserRole { mahasiswa, dosen, admin }

/// Model User sederhana.
/// Belum pakai Hive — ini versi dummy untuk pengembangan UI.
class User {
  final String id;
  final String nama;
  final String email;
  final UserRole role;
  final String passwordHash; // plain text untuk dummy
  final DateTime createdAt;

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.passwordHash,
    required this.createdAt,
  });

  /// Label role yang mudah dibaca (untuk ditampilkan di UI).
  String get roleLabel {
    switch (role) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
