// scripts/seeder.example.dart
// COPY ini ke seeder.dart dan edit data sesuai kebutuhan
// Cara pakai: dart run scripts/seeder.dart

import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:io';

class DatabaseSeeder {
  static late Db db;
  static late DbCollection usersCollection;
  static late DbCollection jadwalCollection;
  static late DbCollection enrollmentsCollection;
  
  static const String dbName = 'smartattend_db';

  static Future<void> main() async {
    print('Memulai seeding database SmartAttend...');
    print('─' * 60);
    
    // Load environment variables
    final env = DotEnv();
    env.load();
    
    final mongoUri = env['MONGODB_URI'];
    if (mongoUri == null || mongoUri.isEmpty) {
      print(' ERROR: MONGODB_URI tidak ditemukan di file .env');
      print(' Buat file .env di root project dengan isi:');
      print('   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/smartattend_db');
      exit(1);
    }

    try {
      db = await Db.create(mongoUri);
      await db.open();
      print(' Terhubung ke MongoDB Atlas');

      usersCollection = db.collection('users');
      jadwalCollection = db.collection('jadwal_kuliah');
      enrollmentsCollection = db.collection('enrollments');

      // ============================================
      // EDIT DATA SEEDING DI BAWAH INI
      // ============================================
      await seedDosen();        // Seed dosen
      await seedMahasiswa();     // Seed mahasiswa
      await seedJadwalKuliah();  // Seed jadwal kuliah
      await seedEnrollments();   // Seed enrollments

      await _showSummary();

      print('\ SEEDING BERHASIL!');
      print('─' * 60);

    } catch (e, stack) {
      print('ERROR: $e');
      print('Stack: $stack');
      exit(1);
    } finally {
      if (db.isConnected) await db.close();
    }
  }

  // ─────────────────────────────────────────────
  // 1. SEED DOSEN
  // ─────────────────────────────────────────────
  static Future<void> seedDosen() async {
    print('\n Seeding dosen...');
    
    // ============================================
    // EDIT: Daftar dosen
    // ============================================
    final dosenList = [
      {'kode': 'DSN001', 'nama': 'Dr. Nama Dosen 1', 'email': 'dosen1@polban.ac.id'},
      {'kode': 'DSN002', 'nama': 'Dr. Nama Dosen 2', 'email': 'dosen2@polban.ac.id'},
      // Tambahkan dosen lainnya...
    ];

    final docs = dosenList.map((d) => {
      '_id': d['kode'],
      'kode': d['kode'],
      'nama': d['nama'],
      'email': d['email'],
      'role': 'dosen',
      'passwordHash': '\$2b\$10\$placeholderHash', // Ganti dengan bcrypt di production
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).toList();

    await usersCollection.insertMany(docs);
    print('${docs.length} dosen ditambahkan');
  }

  // ─────────────────────────────────────────────
  // 2. SEED MAHASISWA
  // ─────────────────────────────────────────────
  static Future<void> seedMahasiswa() async {
    print('\n Seeding mahasiswa...');
    
    // ============================================
    // EDIT: Daftar mahasiswa
    // ============================================
    final mahasiswaList = [
      {'nim': '241511001', 'nama': 'Mahasiswa Pertama', 'kelas': '2B'},
      {'nim': '241511002', 'nama': 'Mahasiswa Kedua', 'kelas': '2B'},
      // Tambahkan mahasiswa lainnya...
    ];

    final docs = mahasiswaList.map((m) => {
      '_id': m['nim'],
      'nim': m['nim'],
      'nama': m['nama'],
      'email': '${m['nim']}@mahasiswa.polban.ac.id',
      'role': 'mahasiswa',
      'kelas': m['kelas'],
      'passwordHash': '\$2b\$10\$placeholderHash',
      'passwordPlain': _generatePassword(m['nim']!), // Hapus di production!
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).toList();

    await usersCollection.insertMany(docs);
    print(' ${docs.length} mahasiswa ditambahkan');
    
    // Tampilkan sample password
    if (mahasiswaList.isNotEmpty) {
      print(' Sample Password: ${mahasiswaList[0]['nim']} → ${_generatePassword(mahasiswaList[0]['nim']!)}');
    }
  }

  // ─────────────────────────────────────────────
  // 3. SEED JADWAL KULIAH
  // ─────────────────────────────────────────────
  static Future<void> seedJadwalKuliah() async {
    print('\n Seeding jadwal kuliah...');
    
    // ============================================
    // EDIT: Daftar jadwal
    // ============================================
    final jadwalList = [
      {
        'kelas': '2B',
        'hari': 'Senin',
        'jamMulai': '08:40',
        'jamSelesai': '10:40',
        'kodeMK': 'IF2122',
        'namaMK': 'Proyek 4: Mobile',
        'tipe': 'PR',
        'kodeDosen': 'DSN001',
        'ruangan': 'D101-Lab'
      },
      // Tambahkan jadwal lainnya...
    ];

    final docs = jadwalList.map((j) {
      final jadwalId = _generateJadwalId(j);
      return {
        '_id': jadwalId,
        'jadwalId': jadwalId,
        'kelas': j['kelas'],
        'kodeMK': j['kodeMK'],
        'namaMK': j['namaMK'],
        'hari': j['hari'],
        'jamMulai': j['jamMulai'],
        'jamSelesai': j['jamSelesai'],
        'tipe': j['tipe'],
        'dosenId': j['kodeDosen'],
        'ruangan': j['ruangan'],
        'semester': '2025/2026-2',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }).toList();

    await jadwalCollection.insertMany(docs);
    print(' ${docs.length} jadwal ditambahkan');
  }

  // ─────────────────────────────────────────────
  // 4. SEED ENROLLMENTS
  // ─────────────────────────────────────────────
  static Future<void> seedEnrollments() async {
    print('\n Seeding enrollments...');
    
    final mahasiswaList = await usersCollection
        .find(where.eq('role', 'mahasiswa'))
        .toList();
    
    final jadwalList = await jadwalCollection.find().toList();
    
    final enrollments = <Map<String, dynamic>>[];
    
    for (final mhs in mahasiswaList) {
      for (final jadwal in jadwalList) {
        enrollments.add({
          '_id': ObjectId(),
          'mahasiswaId': mhs['_id'],
          'jadwalId': jadwal['jadwalId'],
          'semester': '2025/2026-2',
          'status': 'aktif',
          'enrolledAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    
    await enrollmentsCollection.insertMany(enrollments);
    print('${enrollments.length} enrollment ditambahkan');
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  
  static String _generatePassword(String nim) {
    final lastThree = nim.substring(nim.length - 3);
    return '*PassMhs$lastThree#';
  }

  static String _generateJadwalId(Map<String, dynamic> jadwal) {
    final jam = jadwal['jamMulai'].toString().replaceAll(':', '');
    return '${jadwal['kelas']}_${jadwal['kodeMK']}_${jadwal['hari']}_${jam}_${jadwal['tipe']}';
  }

  static Future<void> _showSummary() async {
    print('\n📊 Summary:');
    final mhs = await usersCollection.count(where.eq('role', 'mahasiswa'));
    final dosen = await usersCollection.count(where.eq('role', 'dosen'));
    final jadwal = await jadwalCollection.count();
    final enroll = await enrollmentsCollection.count();
    print('   Mahasiswa: $mhs');
    print('   Dosen: $dosen');
    print('   Jadwal: $jadwal');
    print('   Enrollments: $enroll');
  }
}

void main() => DatabaseSeeder.main();
