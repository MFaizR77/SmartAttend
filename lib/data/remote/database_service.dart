import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;

  Future<void> connect() async {
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
    
    // Cari user berdasarkan _id (nim), nim, kode (dosen), atau email, DAN mencocokkan passwordPlain
    final user = await usersCollection.findOne({
      '\$or': [
        {'_id': identifier},
        {'nim': identifier},
        {'kode': identifier},
        {'email': identifier},
      ],
      'passwordPlain': password
    });
    
    return user;
  }
}
