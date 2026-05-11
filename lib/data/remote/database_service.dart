import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;
  Future<void>? _connectionFuture;

  Future<void> connect() {
    if (_connectionFuture != null) {
      return _connectionFuture!;
    }
    _connectionFuture = _doConnect();
    return _connectionFuture!;
  }

  Future<void> _doConnect() async {
    try {
      if (_db != null) {
        if (_db!.state == State.OPENING) {
          // Tunggu sampai selesai opening
          int waitCount = 0;
          while (_db!.state == State.OPENING && waitCount < 100) {
            await Future.delayed(const Duration(milliseconds: 50));
            waitCount++;
          }
        }

        if (_db!.isConnected) {
          try {
            await _db!.serverStatus();
            return; // Koneksi masih bagus
          } catch (_) {
            // Koneksi rusak, buang dan buat ulang
            try { await _db!.close(); } catch (_) {}
            _db = null;
          }
        } else {
          // State CLOSED atau tidak connected — buang instance lama
          try { await _db!.close(); } catch (_) {}
          _db = null;
        }
      }
      
      await _openNewConnection();
    } catch (e) {
      // Retry 1x jika ConnectionException (transient network error)
      final msg = e.toString();
      if (msg.contains('ConnectionException') || msg.contains('reset by peer') || msg.contains('SocketException')) {
        try { _db?.close(); } catch (_) {}
        _db = null;
        await Future.delayed(const Duration(milliseconds: 300));
        await _openNewConnection();
      } else {
        rethrow;
      }
    } finally {
      _connectionFuture = null;
    }
  }

  Future<void> _openNewConnection() async {
    final mongoUri = dotenv.env['MONGODB_URI'];
    if (mongoUri == null || mongoUri.isEmpty) {
      throw Exception('MONGODB_URI tidak ditemukan. Pastikan sudah diset di .env atau tambahkan fallback url.');
    }

    _db = await Db.create(mongoUri);
    await _db!.open(secure: true, tlsAllowInvalidCertificates: true);
    print('Berhasil terhubung ke MongoDB');
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

  /// Mengambil semua jadwal kuliah seminggu untuk mahasiswa berdasarkan kelas
  Future<List<Map<String, dynamic>>> getSemuaJadwalMahasiswa(String kelas) async {
    await connect();
    final jadwalCollection = _db!.collection('jadwal_kuliah');

    final cursor = jadwalCollection.find({
      'kelas': kelas,
      'isActive': true,
    });

    final List<Map<String, dynamic>> jadwal = await cursor.toList();
    jadwal.sort((a, b) {
      const urutan = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final iA = urutan.indexOf(a['hari'] as String? ?? '');
      final iB = urutan.indexOf(b['hari'] as String? ?? '');
      if (iA != iB) return iA.compareTo(iB);
      return (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? '');
    });
    return jadwal;
  }

  /// Mengambil jadwal mengajar hari ini untuk dosen
  Future<List<Map<String, dynamic>>> getJadwalDosen(String dosenId) async {
    await connect();
    final hari = getHariIni();
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    final pengajuanCollection = _db!.collection('pengajuan_ganti_jadwal');
    
    Future<List<Map<String, dynamic>>> fetchJadwal() async {
      final cursor = jadwalCollection.find({
        '\$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId}
        ],
        'hari': hari,
      });
      final jadwalReguler = await cursor.toList();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final pengajuanCursor = pengajuanCollection.find({
        'dosenId': dosenId,
        'status': 'approved',
        'tanggalPengganti': {
          '\$gte': startOfDay.toIso8601String(),
          '\$lte': endOfDay.toIso8601String(),
        }
      });
      final pengajuan = await pengajuanCursor.toList();

      final List<Map<String, dynamic>> jadwalPengganti = pengajuan.map((p) {
        return {
          '_id': p['_id'],
          'namaMK': p['namaMK'] ?? 'Mata Kuliah',
          'kelas': p['kelas'] ?? '',
          'tipe': 'Pengganti',
          'jamMulai': p['jamMulaiPengganti'] ?? '',
          'jamSelesai': p['jamSelesaiPengganti'] ?? '',
          'ruangan': p['ruanganPengganti'] ?? '',
          'hari': hari,
        };
      }).toList();

      final List<Map<String, dynamic>> semuaJadwal = [...jadwalReguler, ...jadwalPengganti];
      semuaJadwal.sort((a, b) => (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? ''));
      return semuaJadwal;
    }

    try {
      return await fetchJadwal();
    } catch (e) {
      if (e.toString().contains('ConnectionException')) {
        _db = null;
        await connect();
        return await fetchJadwal();
      }
      rethrow;
    }
  }

  /// Mengambil semua jadwal mengajar dosen (semua hari)
  Future<List<Map<String, dynamic>>> getAllJadwalDosen(String dosenId) async {
    await connect();
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    
    try {
      final cursor = jadwalCollection.find({
        '\$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId}
        ]
      });
      
      final List<Map<String, dynamic>> jadwal = await cursor.toList();
      // Sort berdasarkan hari dan jam
      jadwal.sort((a, b) {
        int cmp = (a['hari'] as String? ?? '').compareTo(b['hari'] as String? ?? '');
        if (cmp != 0) return cmp;
        return (a['jamMulai'] as String? ?? '').compareTo(b['jamMulai'] as String? ?? '');
      });
      return jadwal;
    } catch (e) {
      if (e.toString().contains('ConnectionException')) {
        _db = null;
        await connect();
        final cursor = _db!.collection('jadwal_kuliah').find({
          '\$or': [
            {'kodeDosen': dosenId},
            {'dosenId': dosenId}
          ]
        });
        final List<Map<String, dynamic>> jadwal = await cursor.toList();
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

  /// Mendapatkan semua laporan BAP Dosen berdasarkan dosenId
  Future<List<Map<String, dynamic>>> getAllLaporanDosen(String dosenId) async {
    await connect();
    final collection = _db!.collection('laporan_dosen');
    
    final records = await collection.find({
      'dosenId': dosenId,
    }).toList();
    
    return records;
  }

  /// Mengecek apakah kelas sedang berjalan (Dosen sudah menekan Mulai Kuliah, tapi belum Selesai)
  Future<bool> isKelasBerjalan(String jadwalId) async {
    await connect();
    final collection = _db!.collection('laporan_dosen');
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Coba cari dengan tanggal sebagai BSON DateTime
    var record = await collection.findOne({
      'jadwalId': jadwalId,
      'tanggal': {
        '\$gte': startOfDay,
        '\$lte': endOfDay,
      }
    });

    // Jika tidak ditemukan, coba cari dengan tanggal sebagai ISO String
    if (record == null) {
      record = await collection.findOne({
        'jadwalId': jadwalId,
        'tanggal': {
          '\$gte': startOfDay.toIso8601String(),
          '\$lte': endOfDay.toIso8601String(),
        }
      });
    }

    // Fallback: cari tanpa filter tanggal, lalu cek manual
    if (record == null) {
      final allRecords = await collection.find({
        'jadwalId': jadwalId,
      }).toList();
      
      for (final r in allRecords) {
        DateTime? tanggal;
        if (r['tanggal'] is DateTime) {
          tanggal = r['tanggal'];
        } else if (r['tanggal'] is String) {
          tanggal = DateTime.tryParse(r['tanggal']);
        }
        if (tanggal != null &&
            tanggal.year == now.year &&
            tanggal.month == now.month &&
            tanggal.day == now.day) {
          record = r;
          break;
        }
      }
    }

    if (record == null) return false;
    
    // Jika waktuMulai ada dan waktuSelesai belum ada, berarti kelas sedang berjalan
    final waktuMulai = record['waktuMulai'];
    final waktuSelesai = record['waktuSelesai'];
    
    return waktuMulai != null && waktuSelesai == null;
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

  /// Mendapatkan nama hari dari DateTime
  String getHariFromDate(DateTime date) {
    switch (date.weekday) {
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

  /// Mengecek status semua master ruangan (tersedia/terpakai) pada tanggal dan jam tertentu
  Future<List<Map<String, dynamic>>> getRuanganTersedia(DateTime tanggal, String jamMulai, String jamSelesai) async {
    await connect();
    
    // 1. Ambil master ruangan
    final masterRuangan = await _db!.collection('ruangan').find().toList();
    
    // 2. Cari ruangan yang terpakai oleh jadwal reguler
    final hari = getHariFromDate(tanggal);
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    final regulerTerpakai = await jadwalCollection.find({
      'hari': hari,
      'isActive': true,
      '\$and': [
        {'jamMulai': {'\$lt': jamSelesai}},
        {'jamSelesai': {'\$gt': jamMulai}}
      ]
    }).toList();

    // 3. Cari ruangan yang terpakai oleh pengajuan_ganti_jadwal (pending/approved)
    final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final endOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);
    
    final pengajuanCollection = _db!.collection('pengajuan_ganti_jadwal');
    final pengajuanTerpakai = await pengajuanCollection.find({
      'tanggalPengganti': {
        '\$gte': startOfDay.toIso8601String(),
        '\$lte': endOfDay.toIso8601String(),
      },
      'status': {'\$in': ['pending', 'approved']},
      '\$and': [
        {'jamMulaiPengganti': {'\$lt': jamSelesai}},
        {'jamSelesaiPengganti': {'\$gt': jamMulai}}
      ]
    }).toList();

    // Himpun semua nama ruangan yang terpakai (handle split '-' jika data dari reguler memiliki postfix)
    final Set<String> ruanganTerpakai = {};
    for (var j in regulerTerpakai) {
      final r = j['ruangan'] as String;
      ruanganTerpakai.add(r.split('-')[0].trim());
    }
    for (var p in pengajuanTerpakai) {
      final r = p['ruanganPengganti'] as String;
      ruanganTerpakai.add(r.split('-')[0].trim());
    }

    // 4. Map hasil ke master ruangan
    final List<Map<String, dynamic>> hasil = [];
    for (var mr in masterRuangan) {
      final namaRuang = mr['nama'] as String;
      final isTerpakai = ruanganTerpakai.contains(namaRuang);
      hasil.add({
        'nama': namaRuang,
        'isTerpakai': isTerpakai,
      });
    }

    // Urutkan berdasarkan nama ruangan
    hasil.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));
    return hasil;
  }

  /// Mengambil rincian pemakaian suatu ruangan pada tanggal tertentu
  Future<List<Map<String, dynamic>>> getDetailJadwalRuangan(DateTime tanggal, String ruangan) async {
    await connect();
    
    final hari = getHariFromDate(tanggal);
    final jadwalCollection = _db!.collection('jadwal_kuliah');
    
    // 1. Jadwal reguler (match nama ruangan persis di awal, karena kadang ada - Gedung C)
    final regulerTerpakai = await jadwalCollection.find({
      'hari': hari,
      'ruangan': {'\$regex': '^$ruangan'},
    }).toList();

    // 2. Jadwal pengganti
    final startOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final endOfDay = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);
    
    final pengajuanCollection = _db!.collection('pengajuan_ganti_jadwal');
    final pengajuanTerpakai = await pengajuanCollection.find({
      'tanggalPengganti': {
        '\$gte': startOfDay.toIso8601String(),
        '\$lte': endOfDay.toIso8601String(),
      },
      'status': {'\$in': ['pending', 'approved']},
      'ruanganPengganti': {'\$regex': '^$ruangan'},
    }).toList();

    // 3. Gabungkan hasil
    final List<Map<String, dynamic>> detailJadwal = [];
    
    for (var j in regulerTerpakai) {
      detailJadwal.add({
        'jamMulai': j['jamMulai'] ?? '',
        'jamSelesai': j['jamSelesai'] ?? '',
        'namaMK': j['namaMK'] ?? j['mataKuliah'] ?? 'Mata Kuliah',
        'kelas': j['kelas'] ?? '',
        'jenis': 'Reguler',
      });
    }

    for (var p in pengajuanTerpakai) {
      detailJadwal.add({
        'jamMulai': p['jamMulaiPengganti'] ?? '',
        'jamSelesai': p['jamSelesaiPengganti'] ?? '',
        'namaMK': p['namaMK'] ?? 'Mata Kuliah',
        'kelas': p['kelas'] ?? '',
        'jenis': 'Pengganti',
      });
    }

    // Urutkan berdasarkan jamMulai
    detailJadwal.sort((a, b) => (a['jamMulai'] as String).compareTo(b['jamMulai'] as String));
    
    return detailJadwal;
  }

  /// Menyimpan pengajuan ganti jadwal dengan status pending
  Future<void> ajukanGantiJadwal(Map<String, dynamic> data) async {
    await connect();
    if (!data.containsKey('_id')) {
      data['_id'] = ObjectId();
    }
    if (data['tanggalPengganti'] is DateTime) {
      data['tanggalPengganti'] = (data['tanggalPengganti'] as DateTime).toIso8601String();
    }
    await _db!.collection('pengajuan_ganti_jadwal').insertOne(data);
  }

  /// Mengambil daftar histori pengajuan milik dosen tertentu
  Future<List<Map<String, dynamic>>> getPengajuanDosen(String dosenId) async {
    await connect();
    final cursor = _db!.collection('pengajuan_ganti_jadwal').find({
      'dosenId': dosenId,
    });
    final list = await cursor.toList();
    // sort descending (terbaru di atas)
    list.sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));
    return list;
  }

  /// Mengambil semua pengajuan untuk admin (urut terbaru)
  Future<List<Map<String, dynamic>>> getAllPengajuan() async {
    await connect();
    final cursor = _db!.collection('pengajuan_ganti_jadwal').find();
    final list = await cursor.toList();
    list.sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));
    return list;
  }

  /// Mengupdate status pengajuan ganti jadwal (approve/reject)
  Future<void> updateStatusPengajuan(dynamic id, String status) async {
    await connect();
    await _db!.collection('pengajuan_ganti_jadwal').update(
      where.id(id),
      modify.set('status', status).set('updatedAt', DateTime.now().toIso8601String()),
    );
  }

  /// Mengambil jadwal pengganti yang sudah di-approve untuk kelas tertentu HARI INI
  Future<List<Map<String, dynamic>>> getJadwalPenggantiMahasiswa(String kelas) async {
    await connect();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final cursor = _db!.collection('pengajuan_ganti_jadwal').find({
      'kelas': kelas,
      'status': 'approved',
      'tanggalPengganti': {
        '\$gte': startOfDay.toIso8601String(),
        '\$lte': endOfDay.toIso8601String(),
      }
    });

    final List<Map<String, dynamic>> jadwal = await cursor.toList();
    jadwal.sort((a, b) => (a['jamMulaiPengganti'] as String? ?? '').compareTo(b['jamMulaiPengganti'] as String? ?? ''));
    return jadwal;
  }

  /// Menutup koneksi database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
