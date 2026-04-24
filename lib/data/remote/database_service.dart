import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;

  Future<void> connect() async {
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
    
    // Ambil MONGODB_URI
    final mongoUri = dotenv.env['MONGODB_URI'];
    if (mongoUri == null || mongoUri.isEmpty) {
      throw Exception('MONGODB_URI tidak ditemukan. Pastikan sudah diset di .env atau tambahkan fallback url.');
    }

    _db = await Db.create(mongoUri);
    await _db!.open();
    print('✅ Berhasil terhubung ke MongoDB');
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

  /// Menutup koneksi database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
