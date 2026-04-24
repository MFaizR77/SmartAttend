import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;
  bool _isConnecting = false;

  Future<void> connect() async {
    // Tunggu jika sedang ada proses koneksi lain yang berjalan
    while (_isConnecting) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_db != null) {
      if (_db!.isConnected) {
        // Coba ping untuk memastikan socket tidak mati
        try {
          await _db!.serverStatus();
        } catch (_) {
          _db = null;
        }
      }
    }
    
    if (_db != null && _db!.isConnected) return;
    
    _isConnecting = true;
    try {
      // Ambil MONGODB_URI
      final mongoUri = dotenv.env['MONGODB_URI'];
      if (mongoUri == null || mongoUri.isEmpty) {
        throw Exception('MONGODB_URI tidak ditemukan. Pastikan sudah diset di .env atau tambahkan fallback url.');
      }

      _db = await Db.create(mongoUri);
      await _db!.open(secure: true, tlsAllowInvalidCertificates: true);
      print('✅ Berhasil terhubung ke MongoDB');
    } finally {
      _isConnecting = false;
    }
  }

  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    await connect();
    
    final usersCollection = _db!.collection('users');
    
    // Cari user berdasarkan _id (nim/kode), nim, kode (dosen), atau email
    // Dan mencocokkan password dengan passwordPlain ATAU passwordHash
    final user = await usersCollection.findOne({
      '\$and': [
        {
          '\$or': [
            {'_id': identifier},
            {'nim': identifier},
            {'kode': identifier},
            {'email': identifier},
          ]
        },
        {
          '\$or': [
            {'passwordPlain': password},
            {'passwordHash': password},
          ]
        }
      ]
    });
    
    return user;
  }

  /// Mendapatkan nama hari ini dalam Bahasa Indonesia
  String getHariIni() {
    final int weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1: return 'Senin';
      case 2: return 'Selasa';
      case 3: return 'Rabu';
      case 4: return 'Kamis';
      case 5: return 'Jumat';
      case 6: return 'Sabtu';
      case 7: return 'Minggu';
      default: return 'Senin';
    }
  }

  /// Mengambil jadwal kuliah hari ini untuk mahasiswa berdasarkan kelas
  Future<List<Map<String, dynamic>>> getJadwalMahasiswa(String kelas) async {
    await connect();
    final hari = getHariIni();
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    
    final cursor = jadwalCollection.find({
      'kelas': kelas,
      'hari': hari,
      'isActive': true,
    });
    
    final List<Map<String, dynamic>> jadwal = await cursor.toList();
    jadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
    return jadwal;
  }

  /// Mengambil jadwal mengajar hari ini untuk dosen
  Future<List<Map<String, dynamic>>> getJadwalDosen(String dosenId) async {
    await connect();
    final hari = getHariIni();
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    
    try {
      final cursor = jadwalCollection.find({
        'dosenId': dosenId,
        'hari': hari,
        'isActive': true,
      });
      
      final List<Map<String, dynamic>> jadwal = await cursor.toList();
      jadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
      return jadwal;
    } catch (e) {
      if (e.toString().contains('ConnectionException')) {
        _db = null;
        await connect();
        final cursor = _db!.collection('jadwal_kuliah').find({
          'dosenId': dosenId,
          'hari': hari,
          'isActive': true,
        });
        final List<Map<String, dynamic>> jadwal = await cursor.toList();
        jadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
        return jadwal;
      }
      rethrow;
    }
  }

  /// Menyimpan data presensi langsung ke MongoDB (ketika online)
  Future<void> insertRecordPresensi(Map<String, dynamic> record) async {
    await connect();
    final collection = _db!.collection('record_presensi');
    
    // Pastikan _id digenerate jika tidak ada
    if (!record.containsKey('_id')) {
      record['_id'] = ObjectId();
    }
    
    await collection.insertOne(record);
  }

  /// Mengecek apakah mahasiswa sudah presensi untuk sesi/jadwal tersebut hari ini
  Future<bool> checkPresensiExists(String sesiId, String mahasiswaId) async {
    await connect();
    final collection = _db!.collection('record_presensi');
    
    // Gunakan batasan waktu hari ini untuk mengecek
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final record = await collection.findOne({
      'sesiId': sesiId,
      'mahasiswaId': mahasiswaId,
      'timestamp': {
        '\$gte': startOfDay.toIso8601String(),
        '\$lte': endOfDay.toIso8601String(),
      }
    });

    return record != null;
  }

  /// Menutup koneksi database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
