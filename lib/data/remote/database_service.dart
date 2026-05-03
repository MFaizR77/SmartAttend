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
    
    final cursor = jadwalCollection.find(where
      .eq('kelas', kelas)
      .eq('hari', hari)
    );
    
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
      final cursor = jadwalCollection.find(where
        .eq('hari', hari)
        .and(where.eq('kodeDosen', dosenId).or(where.eq('dosenId', dosenId)))
      );
      
      final List<Map<String, dynamic>> jadwal = await cursor.toList();
      jadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
      return jadwal;
    } catch (e) {
      if (e.toString().contains('ConnectionException')) {
        _db = null;
        await connect();
        final cursor = _db!.collection('jadwal_kuliah').find(where
          .eq('hari', hari)
          .and(where.eq('kodeDosen', dosenId).or(where.eq('dosenId', dosenId)))
        );
        final List<Map<String, dynamic>> jadwal = await cursor.toList();
        jadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
        return jadwal;
      }
      rethrow;
    }
  }

  /// Mengambil semua jadwal mengajar dosen (semua hari)
  Future<List<Map<String, dynamic>>> getSemuaJadwalDosen(String dosenId) async {
    await connect();
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    
    try {
      final cursor = jadwalCollection.find({
        r'$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId},
        ]
      });
      
      final List<Map<String, dynamic>> jadwal = await cursor.toList();
      // Urutkan berdasarkan hari, lalu jam mulai
      final hariOrder = {'Senin': 1, 'Selasa': 2, 'Rabu': 3, 'Kamis': 4, 'Jumat': 5, 'Sabtu': 6, 'Minggu': 7};
      jadwal.sort((a, b) {
        final hariA = hariOrder[a['hari']] ?? 99;
        final hariB = hariOrder[b['hari']] ?? 99;
        if (hariA != hariB) return hariA.compareTo(hariB);
        return (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? '');
      });
      return jadwal;
    } catch (e) {
      if (e.toString().contains('ConnectionException')) {
        _db = null;
        await connect();
        final cursor = _db!.collection('jadwal_kuliah').find({
          r'$or': [
            {'kodeDosen': dosenId},
            {'dosenId': dosenId},
          ]
        });
        final List<Map<String, dynamic>> jadwal = await cursor.toList();
        return jadwal;
      }
      rethrow;
    }
  }



  /// Mengambil seluruh rekapan laporan dosen
  Future<List<Map<String, dynamic>>> getSemuaLaporanDosen(String dosenId) async {
    await connect();
    final collection = _db!.collection('laporan_dosen');
    final cursor = collection.find(where.eq('dosenId', dosenId).sortBy('waktuMulai', descending: true));
    return await cursor.toList();
  }

  /// Menyimpan data presensi langsung ke MongoDB (ketika online)
  Future<void> insertRecordPresensi(Map<String, dynamic> record) async {
    await connect();
    final collection = _db!.collection('record_presensi');
    
    // Pastikan _id digenerate jika tidak ada
    if (!record.containsKey('_id')) {
      record['_id'] = ObjectId();
    }
    
    // Konversi string ISO ke BSON Date (DateTime) agar waktu asli tidak tertimpa waktu sync
    if (record['timestamp'] is String) {
      record['timestamp'] = DateTime.tryParse(record['timestamp']) ?? record['timestamp'];
    }
    if (record['createdAt'] is String) {
      record['createdAt'] = DateTime.tryParse(record['createdAt']) ?? record['createdAt'];
    }
    if (record['updatedAt'] is String) {
      record['updatedAt'] = DateTime.tryParse(record['updatedAt']) ?? record['updatedAt'];
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

  /// Mendapatkan Laporan Dosen berdasarkan jadwalId dan tanggal hari ini
  Future<Map<String, dynamic>?> getLaporanDosen(String jadwalId, String dosenId) async {
    await connect();
    final collection = _db!.collection('laporan_dosen');
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final record = await collection.findOne({
      'jadwalId': jadwalId,
      'dosenId': dosenId,
      'tanggal': {
        '\$gte': startOfDay,
        '\$lte': endOfDay,
      }
    });

    return record;
  }

  /// Insert atau Update Laporan Dosen
  Future<void> insertOrUpdateLaporanDosen(Map<String, dynamic> record) async {
    await connect();
    final collection = _db!.collection('laporan_dosen');
    
    // Pastikan konversi string date ke BSON Date
    if (record['waktuMulai'] is String) {
      record['waktuMulai'] = DateTime.tryParse(record['waktuMulai']) ?? record['waktuMulai'];
    }
    if (record['waktuSelesai'] is String && record['waktuSelesai'] != null) {
      record['waktuSelesai'] = DateTime.tryParse(record['waktuSelesai']) ?? record['waktuSelesai'];
    }
    if (record['tanggal'] is String) {
      record['tanggal'] = DateTime.tryParse(record['tanggal']) ?? record['tanggal'];
    }

    final query = {
      'jadwalId': record['jadwalId'],
      'dosenId': record['dosenId'],
      'tanggal': {
        '\$gte': DateTime(record['tanggal'].year, record['tanggal'].month, record['tanggal'].day),
        '\$lte': DateTime(record['tanggal'].year, record['tanggal'].month, record['tanggal'].day, 23, 59, 59),
      }
    };

    final existing = await collection.findOne(query);

    if (existing != null) {
      // Update
      await collection.update(
        where.id(existing['_id']),
        modify
            .set('waktuSelesai', record['waktuSelesai'])
            .set('materi', record['materi'])
            .set('updatedAt', DateTime.now()),
      );
    } else {
      // Insert
      if (!record.containsKey('_id')) {
        record['_id'] = ObjectId();
      }
      record['createdAt'] = DateTime.now();
      await collection.insertOne(record);
    }
  }

  /// Mendapatkan daftar semua ruangan yang ada di jadwal
  Future<List<String>> getSemuaRuangan() async {
    try {
      await connect();
      if (_db == null) {
        print('DEBUG getSemuaRuangan: _db is null setelah connect()');
        return [];
      }
      final collection = _db!.collection('jadwal_kuliah');
      final jadwals = await collection.find().toList();
      print('DEBUG getSemuaRuangan: Ditemukan \${jadwals.length} jadwal total');
      final Set<String> ruanganSet = {};
      for (var j in jadwals) {
        if (j['ruangan'] != null && j['ruangan'].toString().trim().isNotEmpty) {
          ruanganSet.add(j['ruangan'].toString().trim());
        }
      }
      final result = ruanganSet.toList();
      result.sort();
      print('DEBUG getSemuaRuangan: Ditemukan \${result.length} ruangan unik (\${result})');
      return result;
    } catch (e) {
      print('DEBUG getSemuaRuangan ERROR: \$e');
      return [];
    }
  }

  /// Mencari ruangan kosong pada hari dan jam tertentu
  Future<List<String>> cariRuangKosong(String hari, String jamMulai, String jamSelesai, {String? abaikanJadwalId}) async {
    print('DEBUG cariRuangKosong: Mulai mencari hari=$hari, jamMulai=$jamMulai, jamSelesai=$jamSelesai');
    try {
      await connect();
      if (_db == null) {
        print('DEBUG cariRuangKosong: _db is null');
        return [];
      }
      
      // 1. Dapatkan semua ruangan
      final semuaRuangan = await getSemuaRuangan();
      if (semuaRuangan.isEmpty) {
        print('DEBUG cariRuangKosong: Semua ruangan kosong, batalkan pencarian.');
        return [];
      }
      
      // 2. Ambil jadwal pada hari tersebut
      final collection = _db!.collection('jadwal_kuliah');
      final jadwalHariIni = await collection.find({'hari': hari}).toList();
      print('DEBUG cariRuangKosong: Ditemukan \${jadwalHariIni.length} jadwal pada hari \$hari');
      
      // 3. Filter ruangan yang terpakai
      final Set<String> ruanganTerpakai = {};
      
      // Helper: Konversi jam string ke menit (HH:mm -> menit)
      int timeToMinutes(String time) {
        try {
          time = time.replaceAll('.', ':');
          final parts = time.split(':');
          if (parts.length != 2) return 0;
          return int.parse(parts[0].trim()) * 60 + int.parse(parts[1].trim());
        } catch (e) {
          print('Error parse time: \$time');
          return 0;
        }
      }
      
      final int reqStart = timeToMinutes(jamMulai);
      final int reqEnd = timeToMinutes(jamSelesai);
      
      for (var j in jadwalHariIni) {
        // Abaikan jadwal yang sedang ingin diganti agar tidak dianggap bentrok dengan dirinya sendiri
        if (abaikanJadwalId != null && j['_id'].toString() == abaikanJadwalId) continue;
        
        if (j['ruangan'] == null || j['jamMulai'] == null || j['jamSelesai'] == null) continue;
        
        final int jStart = timeToMinutes(j['jamMulai'].toString());
        final int jEnd = timeToMinutes(j['jamSelesai'].toString());
        
        // Cek overlap
        if (jStart < reqEnd && jEnd > reqStart) {
          ruanganTerpakai.add(j['ruangan'].toString().trim());
        }
      }
      print('DEBUG cariRuangKosong: Ruangan terpakai = \$ruanganTerpakai');
      
      // 4. Hapus ruangan yang terpakai dari semua ruangan
      final ruanganKosong = semuaRuangan.where((r) => !ruanganTerpakai.contains(r)).toList();
      print('DEBUG cariRuangKosong: Ruangan kosong = \$ruanganKosong');
      
      return ruanganKosong;
    } catch (e) {
      print('DEBUG cariRuangKosong ERROR: \$e');
      return [];
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
