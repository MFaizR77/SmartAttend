/// Tipe akun login. Setiap tipe punya koleksi MongoDB dan dashboard sendiri.
enum AccountType { mahasiswa, dosen, walidosen, admin }

/// Backward-compat: alias lama `UserRole`.
/// Beberapa file masih merujuk `UserRole.mahasiswa/dosen/admin`.
/// Wali dosen masuk kategori sendiri di [AccountType], tapi kalau ada kode
/// lama yang switch UserRole, walidosen akan jatuh ke `dosen` agar tidak crash.
enum UserRole { mahasiswa, dosen, admin }

/// Model User unified — merepresentasikan user yang sudah login dari salah satu
/// koleksi (mahasiswa / dosen / wali_dosen / admin).
class User {
  final String id;
  final String nama;
  final String email;
  final UserRole role;          // mapping kasar untuk UI lama
  final AccountType accountType; // sumber kebenaran
  final String passwordHash;     // plaintext password yg user ketik (utk login offline)
  final DateTime createdAt;

  // Mahasiswa
  final String? kelas;
  final String? program; // 'D3' | 'D4'

  // Wali dosen (dan dosen kalau perlu mapping)
  final String? kelasWali;       // hanya untuk wali dosen
  final String? dosenKode;       // ref ke dosen.kode (untuk wali dosen)

  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    required this.accountType,
    required this.passwordHash,
    required this.createdAt,
    this.kelas,
    this.program,
    this.kelasWali,
    this.dosenKode,
  });

  /// Label role yang mudah dibaca (untuk ditampilkan di UI).
  String get roleLabel {
    switch (accountType) {
      case AccountType.mahasiswa:
        return 'Mahasiswa';
      case AccountType.dosen:
        return 'Dosen';
      case AccountType.walidosen:
        return 'Wali Dosen';
      case AccountType.admin:
        return 'Admin';
    }
  }

  /// Tampilan kelas ringkas: "2B-D3" atau "2B" kalau program null.
  String? get kelasDisplay {
    if (kelas == null) return null;
    if (program == null || program!.isEmpty) return kelas;
    return '$kelas-$program';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'role': role.name,
      'accountType': accountType.name,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'kelas': kelas,
      'program': program,
      'kelasWali': kelasWali,
      'dosenKode': dosenKode,
    };
  }

  factory User.fromMap(Map<dynamic, dynamic> map) {
    final accStr = map['accountType']?.toString();
    final roleStr = map['role']?.toString();

    AccountType acc;
    if (accStr != null) {
      acc = AccountType.values.firstWhere(
        (e) => e.name == accStr,
        orElse: () => AccountType.mahasiswa,
      );
    } else {
      // Fallback dari role lama
      switch (roleStr) {
        case 'dosen':
          acc = AccountType.dosen;
          break;
        case 'admin':
          acc = AccountType.admin;
          break;
        case 'walidosen':
          acc = AccountType.walidosen;
          break;
        default:
          acc = AccountType.mahasiswa;
      }
    }

    UserRole roleMap;
    switch (acc) {
      case AccountType.mahasiswa:
        roleMap = UserRole.mahasiswa;
        break;
      case AccountType.dosen:
      case AccountType.walidosen:
        roleMap = UserRole.dosen;
        break;
      case AccountType.admin:
        roleMap = UserRole.admin;
        break;
    }

    return User(
      id: map['id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: roleMap,
      accountType: acc,
      passwordHash: map['passwordHash']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      kelas: map['kelas']?.toString(),
      program: map['program']?.toString(),
      kelasWali: map['kelasWali']?.toString(),
      dosenKode: map['dosenKode']?.toString(),
    );
  }
}
