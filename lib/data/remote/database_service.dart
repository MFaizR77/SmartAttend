import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Singleton service untuk operasi MongoDB.
///
/// Struktur koleksi (target — sesuai IMPLEMENTATION_PLAN.md):
///   - mahasiswa, dosen, wali_dosen, admin   (login)
///   - periode_akademik                      (master, hanya 1 yg aktif)
///   - mata_kuliah, ruangan                  (master)
///   - jadwal_kuliah (ref+snapshot, ada field `program`)
///   - enrollments
///   - izin_mahasiswa                        (workflow izin sakit/izin)
///   - izin_dosen                            (legacy, untuk dosen ajukan izin)
///   - laporan_dosen, record_presensi        (legacy presensi)
///   - pengajuan_ganti_jadwal                (legacy ganti jadwal)
///   - wali_assignments                      (audit assign wali)
///   - upload_jadwal                         (audit upload csv)
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Db? _db;
  Future<void>? _connectionFuture;

  // ─────────────────────────────────────────────────────
  // KONEKSI
  // ─────────────────────────────────────────────────────

  Future<void> connect() {
    if (_connectionFuture != null) return _connectionFuture!;
    _connectionFuture = _doConnect();
    return _connectionFuture!;
  }

  Future<void> _doConnect() async {
    try {
      if (_db != null) {
        if (_db!.state == State.OPENING) {
          int wait = 0;
          while (_db!.state == State.OPENING && wait < 100) {
            await Future.delayed(const Duration(milliseconds: 50));
            wait++;
          }
        }
        if (_db!.isConnected) {
          try {
            await _db!.serverStatus();
            return;
          } catch (_) {
            try {
              await _db!.close();
            } catch (_) {}
            _db = null;
          }
        } else {
          try {
            await _db!.close();
          } catch (_) {}
          _db = null;
        }
      }
      await _openNewConnection();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ConnectionException') ||
          msg.contains('reset by peer') ||
          msg.contains('SocketException')) {
        try {
          _db?.close();
        } catch (_) {}
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
      throw Exception('MONGODB_URI tidak ditemukan di .env');
    }
    _db = await Db.create(mongoUri);
    await _db!.open(secure: true, tlsAllowInvalidCertificates: true);
    print('Berhasil terhubung ke MongoDB (db=${_db!.databaseName})');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Db get _requireDb {
    if (_db == null)
      throw StateError('DB belum connect; panggil connect() dulu.');
    return _db!;
  }

  /// Mutex serial untuk operasi DB. mongo_dart tidak aman dipakai paralel dari
  /// banyak Future di koneksi yang sama (apalagi saat retry — reconnect
  /// menutup socket di tengah query lain → query yg lain hang/timeout).
  /// Semua call _withReconnect akan antri lewat _opQueue.
  Future<void> _opQueue = Future.value();

  /// Eksekusi operasi DB dengan retry sekali jika koneksi reset di tengah query.
  /// Atlas free tier sering tutup idle connection → method ini handle reconnect.
  /// Operasi diserialisasi via _opQueue agar tidak ada race saat reconnect.
  Future<T> _withReconnect<T>(Future<T> Function() op) {
    final completer = Completer<T>();
    final prev = _opQueue;
    _opQueue = prev.then((_) async {
      try {
        await connect();
        try {
          final result = await op();
          completer.complete(result);
        } catch (e) {
          print('[DBG ERR] _withReconnect caught: $e');
          final msg = e.toString();
          final transient =
              msg.contains('ConnectionException') ||
              msg.contains('reset by peer') ||
              msg.contains('SocketException') ||
              msg.contains('connection closed');
          if (!transient) {
            print('[DBG ERR] non-transient, rethrowing');
            completer.completeError(e);
            return;
          }
          // Force reconnect lalu coba sekali lagi.
          print('[DBG ERR] transient, retrying...');
          try {
            await _db?.close();
          } catch (_) {}
          _db = null;
          _connectionFuture = null;
          await Future.delayed(const Duration(milliseconds: 300));
          await connect();
          try {
            final result = await op();
            completer.complete(result);
          } catch (e2) {
            print('[DBG ERR] retry failed: $e2');
            completer.completeError(e2);
          }
        }
      } catch (outer) {
        // gagal connect / sesuatu di luar op
        if (!completer.isCompleted) completer.completeError(outer);
      }
    });
    return completer.future;
  }

  /// Bangun selector yang permissive terhadap field `periodeAkademikKode`:
  /// match dokumen yang punya field == [periodeKode], ATAU yang field-nya null/missing.
  /// Ini melindungi dari kasus seeder.dart over-write field saat re-run, sehingga
  /// jadwal lama yang field periode-nya hilang tetap muncul.
  ///
  /// `base` adalah selector yang sudah dibangun (boleh punya `\$or`); akan
  /// di-merge ke struktur `\$and` agar tidak konflik dengan `\$or` periode.
  Map<String, dynamic> _withPeriodeFilter(
    Map<String, dynamic> base,
    String? periodeKode,
  ) {
    if (periodeKode == null) return base;

    final periodeClause = {
      r'$or': [
        {'periodeAkademikKode': periodeKode},
        {
          'periodeAkademikKode': null,
        }, // matches null AND missing field di MongoDB
      ],
    };

    // Kalau base sudah ada $or atau field lain, bungkus di $and.
    final andClauses = <Map<String, dynamic>>[];
    base.forEach((k, v) {
      andClauses.add({k: v});
    });
    andClauses.add(periodeClause);
    return {r'$and': andClauses};
  }

  // ─────────────────────────────────────────────────────
  // LOGIN MULTI-KOLEKSI
  // ─────────────────────────────────────────────────────

  /// Login ke koleksi `mahasiswa` dengan NIM/email + password.
  Future<Map<String, dynamic>?> loginMahasiswa(
    String identifier,
    String password,
  ) async {
    return _withReconnect(
      () => _requireDb.collection('mahasiswa').findOne({
        r'$and': [
          {
            r'$or': [
              {'_id': identifier},
              {'nim': identifier},
              {'email': identifier},
            ],
          },
          {
            r'$or': [
              {'passwordPlain': password},
              {'passwordHash': password},
            ],
          },
        ],
      }),
    );
  }

  /// Login ke koleksi `dosen` dengan kode/email + password.
  Future<Map<String, dynamic>?> loginDosen(
    String identifier,
    String password,
  ) async {
    return _withReconnect(
      () => _requireDb.collection('dosen').findOne({
        r'$and': [
          {
            r'$or': [
              {'_id': identifier},
              {'kode': identifier},
              {'email': identifier},
            ],
          },
          {
            r'$or': [
              {'passwordPlain': password},
              {'passwordHash': password},
            ],
          },
        ],
      }),
    );
  }

  /// Login ke koleksi `wali_dosen` dengan kode (mis. WD_KO071N_2B_D3) + password.
  Future<Map<String, dynamic>?> loginWaliDosen(
    String identifier,
    String password,
  ) async {
    return _withReconnect(
      () => _requireDb.collection('wali_dosen').findOne({
        r'$and': [
          {
            r'$or': [
              {'_id': identifier},
              {'kode': identifier},
              {'email': identifier},
            ],
          },
          {
            r'$or': [
              {'passwordPlain': password},
              {'passwordHash': password},
            ],
          },
        ],
      }),
    );
  }

  /// Login ke koleksi `admin` dengan kode/email + password.
  Future<Map<String, dynamic>?> loginAdmin(
    String identifier,
    String password,
  ) async {
    return _withReconnect(
      () => _requireDb.collection('admin').findOne({
        r'$and': [
          {
            r'$or': [
              {'_id': identifier},
              {'kode': identifier},
              {'email': identifier},
            ],
          },
          {
            r'$or': [
              {'passwordPlain': password},
              {'passwordHash': password},
            ],
          },
        ],
      }),
    );
  }

  /// Login ke koleksi `kaprodi` dengan kode/email + password.
  Future<Map<String, dynamic>?> loginKaprodi(
    String identifier,
    String password,
  ) async {
    return _withReconnect(
      () => _requireDb.collection('kaprodi').findOne({
        r'$and': [
          {
            r'$or': [
              {'_id': identifier},
              {'kode': identifier},
              {'email': identifier},
            ],
          },
          {
            r'$or': [
              {'passwordPlain': password},
              {'passwordHash': password},
            ],
          },
        ],
      }),
    );
  }

  /// Backward-compat untuk kode lama yang masih panggil `login(identifier, password)`.
  /// Cari di semua koleksi role; return user pertama yang cocok beserta tag accountType.
  Future<Map<String, dynamic>?> login(
    String identifier,
    String password,
  ) async {
    final mhs = await loginMahasiswa(identifier, password);
    if (mhs != null) return {...mhs, '_accountType': 'mahasiswa'};
    final dsn = await loginDosen(identifier, password);
    if (dsn != null) return {...dsn, '_accountType': 'dosen'};
    final wd = await loginWaliDosen(identifier, password);
    if (wd != null) return {...wd, '_accountType': 'walidosen'};
    final kp = await loginKaprodi(identifier, password);
    if (kp != null) return {...kp, '_accountType': 'kaprodi'};
    final ad = await loginAdmin(identifier, password);
    if (ad != null) return {...ad, '_accountType': 'admin'};
    return null;
  }

  // ─────────────────────────────────────────────────────
  // PERIODE AKADEMIK
  // ─────────────────────────────────────────────────────

  /// Ambil periode akademik aktif. Cache ringan (per koneksi).
  Map<String, dynamic>? _activePeriodeCache;

  Future<Map<String, dynamic>?> getActivePeriode({
    bool forceRefresh = false,
  }) async {
    if (_activePeriodeCache != null && !forceRefresh)
      return _activePeriodeCache;
    return _withReconnect(() async {
      print('[getActivePeriode] Querying periode_akademik with aktif=true');
      _activePeriodeCache = await _requireDb
          .collection('periode_akademik')
          .findOne(where.eq('aktif', true));
      if (_activePeriodeCache != null) {
        print('[getActivePeriode] Found: ${_activePeriodeCache!['kode']}');
      } else {
        print('[getActivePeriode] No active periode found!');
      }
      return _activePeriodeCache;
    });
  }

  /// Internal: ambil periode aktif TANPA antri di `_opQueue`.
  /// HANYA boleh dipanggil dari dalam callback `_withReconnect` lain — kalau
  /// dipanggil di luar, koneksi belum tentu siap. Tujuannya: hindari deadlock
  /// nested mutex (outer _withReconnect menunggu inner yang antri di belakangnya).
  Future<Map<String, dynamic>?> _getActivePeriodeRaw() async {
    if (_activePeriodeCache != null) return _activePeriodeCache;
    print('[_getActivePeriodeRaw] Querying periode_akademik with aktif=true');
    _activePeriodeCache = await _requireDb
        .collection('periode_akademik')
        .findOne(where.eq('aktif', true));
    if (_activePeriodeCache != null) {
      print('[_getActivePeriodeRaw] Found: ${_activePeriodeCache!['kode']}');
    } else {
      print('[_getActivePeriodeRaw] No active periode found!');
    }
    return _activePeriodeCache;
  }

  Future<List<Map<String, dynamic>>> getAllPeriode() async {
    await connect();
    final list = await _requireDb
        .collection('periode_akademik')
        .find()
        .toList();
    list.sort(
      (a, b) =>
          (b['kode'] as String? ?? '').compareTo(a['kode'] as String? ?? ''),
    );
    return list;
  }

  /// Aktivasi 1 periode (yang lain auto non-aktif). Idempotent.
  Future<void> setAktifPeriode(String kodePeriode) async {
    await connect();
    final coll = _requireDb.collection('periode_akademik');
    await coll.updateMany(
      <String, dynamic>{},
      modify.set('aktif', false).set('updatedAt', DateTime.now()),
    );
    await coll.updateOne(
      where.eq('kode', kodePeriode),
      modify.set('aktif', true).set('updatedAt', DateTime.now()),
    );
    _activePeriodeCache = null;
  }

  /// Buat periode baru (non-aktif). Return doc yang dibuat.
  Future<Map<String, dynamic>> createPeriode({
    required String kode,
    required String tahunAjaran,
    required String jenis, // 'Ganjil' | 'Genap'
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
  }) async {
    await connect();
    final id = ObjectId();
    final doc = {
      '_id': id,
      'kode': kode,
      'tahunAjaran': tahunAjaran,
      'jenis': jenis,
      'tanggalMulai': tanggalMulai,
      'tanggalSelesai': tanggalSelesai,
      'aktif': false,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
    await _requireDb.collection('periode_akademik').insertOne(doc);
    return doc;
  }

  // ─────────────────────────────────────────────────────
  // HARI HELPERS
  // ─────────────────────────────────────────────────────

  String getHariIni() => getHariFromDate(DateTime.now());

  String getHariFromDate(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      default:
        return 'Senin';
    }
  }

  // ─────────────────────────────────────────────────────
  // JADWAL — MAHASISWA (via enrollments × periode aktif)
  // ─────────────────────────────────────────────────────
  //
  // SUMBER KEBENARAN: koleksi `enrollments`. Dokumen jadwal_kuliah hanya
  // di-resolve setelah daftar jadwalId mahasiswa tertentu didapat dari
  // enrollments-nya (status='aktif' di periode aktif).
  //
  // Manfaat:
  // - Tidak campur antar program (D3 vs D4) walau kelas namanya sama.
  // - Mahasiswa drop/pindah matkul otomatis hilang dari list.
  // - Konsisten dengan PD-Dikti (1 mhs ↔ N enrollment).

  /// Internal: ambil semua jadwalId aktif mahasiswa di periode aktif.
  /// HARUS dipanggil dari dalam callback `_withReconnect` (tidak antri di queue
  /// sendiri, supaya outer caller tidak deadlock).
  Future<List<String>> _enrolledJadwalIds(String mahasiswaId) async {
    final periode = await _getActivePeriodeRaw();
    final periodeKode = periode?['kode'] as String?;
    final selector = <String, dynamic>{
      'mahasiswaId': mahasiswaId,
      'status': 'aktif',
    };
    if (periodeKode != null) {
      selector['periodeAkademikKode'] = periodeKode;
    }
    final enrolls = await _requireDb
        .collection('enrollments')
        .find(selector)
        .toList();
    return enrolls
        .map((e) => e['jadwalId']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Public: ambil enrollments aktif mahasiswa di periode aktif.
  /// Dipakai oleh JadwalCacheService untuk caching offline.
  Future<List<String>> getEnrolledJadwalIds(String mahasiswaId) async {
    return _withReconnect(() => _enrolledJadwalIds(mahasiswaId));
  }

  /// Jadwal mahasiswa untuk HARI INI.
  /// `mahasiswaId` = NIM (sesuai `_id` di koleksi `mahasiswa`).
  Future<List<Map<String, dynamic>>> getJadwalMahasiswa(
    String mahasiswaId,
  ) async {
    return _withReconnect(() async {
      final jadwalIds = await _enrolledJadwalIds(mahasiswaId);
      if (jadwalIds.isEmpty) return const <Map<String, dynamic>>[];

      final hari = getHariIni();
      final list = await _requireDb.collection('jadwal_kuliah').find({
        '_id': {r'$in': jadwalIds},
        'hari': hari,
        'isActive': true,
      }).toList();
      list.sort(
        (a, b) => (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        ),
      );
      return list;
    });
  }

  /// Semua jadwal mahasiswa di periode aktif (semua hari).
  Future<List<Map<String, dynamic>>> getSemuaJadwalMahasiswa(
    String mahasiswaId,
  ) async {
    return _withReconnect(() async {
      final jadwalIds = await _enrolledJadwalIds(mahasiswaId);
      if (jadwalIds.isEmpty) return const <Map<String, dynamic>>[];

      final list = await _requireDb.collection('jadwal_kuliah').find({
        '_id': {r'$in': jadwalIds},
        'isActive': true,
      }).toList();
      const urut = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
      ];
      list.sort((a, b) {
        final iA = urut.indexOf(a['hari'] as String? ?? '');
        final iB = urut.indexOf(b['hari'] as String? ?? '');
        if (iA != iB) return iA.compareTo(iB);
        return (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        );
      });
      return list;
    });
  }

  /// Jadwal pengganti yang sudah approved untuk kelas tertentu HARI INI.
  Future<List<Map<String, dynamic>>> getJadwalPenggantiMahasiswa(
    String kelas,
  ) async {
    await connect();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final cursor = _requireDb.collection('pengajuan_ganti_jadwal').find({
      'kelas': kelas,
      'status': 'approved',
      'tanggalPengganti': {
        r'$gte': start.toIso8601String(),
        r'$lte': end.toIso8601String(),
      },
    });
    final list = await cursor.toList();
    list.sort(
      (a, b) => (a['jamMulaiPengganti'] as String? ?? '').compareTo(
        b['jamMulaiPengganti'] as String? ?? '',
      ),
    );
    return list;
  }

  // ─────────────────────────────────────────────────────
  // JADWAL — DOSEN
  // ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getJadwalDosen(String dosenId) async {
    return _withReconnect(() async {
      final hari = getHariIni();
      // Match: dosenId / kodeDosen single, ATAU dosenIds array (team teaching).
      final selector = <String, dynamic>{
        r'$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId},
          {'dosenIds': dosenId},
        ],
        'hari': hari,
      };

      final reguler = await _requireDb
          .collection('jadwal_kuliah')
          .find(selector)
          .toList();

      // Pengganti yang approved hari ini
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final pengajuan = await _requireDb
          .collection('pengajuan_ganti_jadwal')
          .find({
            'dosenId': dosenId,
            'status': 'approved',
            'tanggalPengganti': {
              r'$gte': start.toIso8601String(),
              r'$lte': end.toIso8601String(),
            },
          })
          .toList();

      final pengganti = pengajuan
          .map<Map<String, dynamic>>(
            (p) => {
              '_id': p['_id'],
              'namaMK': p['namaMK'] ?? 'Mata Kuliah',
              'kelas': p['kelas'] ?? '',
              'tipe': 'Pengganti',
              'jamMulai': p['jamMulaiPengganti'] ?? '',
              'jamSelesai': p['jamSelesaiPengganti'] ?? '',
              'ruangan': p['ruanganPengganti'] ?? '',
              'hari': hari,
            },
          )
          .toList();

      final all = [...reguler, ...pengganti];
      all.sort(
        (a, b) => (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        ),
      );
      return all;
    });
  }

  Future<List<Map<String, dynamic>>> getAllJadwalDosen(String dosenId) async {
    return _withReconnect(() async {
      print('[DBG] getAllJadwalDosen called with dosenId="$dosenId"');
      // Selector simpel — tidak filter periode untuk avoid $and complexity di mongo_dart.
      // Periode filter bisa ditambahkan kalau multi-periode aktif sudah didukung UI.
      final selector = <String, dynamic>{
        r'$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId},
          {'dosenIds': dosenId},
        ],
      };
      final list = await _requireDb
          .collection('jadwal_kuliah')
          .find(selector)
          .toList();
      print('[DBG] getAllJadwalDosen returned ${list.length} jadwal');
      if (list.isEmpty) {
        final sample = await _requireDb
            .collection('jadwal_kuliah')
            .find()
            .take(3)
            .toList();
        print('[DBG] sample jadwal docs (first 3): ');
        for (final s in sample) {
          print(
            '  _id=${s['_id']}, dosenId=${s['dosenId']}, dosenIds=${s['dosenIds']}, periodeAkademikKode=${s['periodeAkademikKode']}',
          );
        }
      }
      list.sort((a, b) {
        final cmp = (a['hari'] as String? ?? '').compareTo(
          b['hari'] as String? ?? '',
        );
        if (cmp != 0) return cmp;
        return (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        );
      });
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> getJadwalDosenByHari(
    String dosenId,
    DateTime tanggal,
  ) async {
    return _withReconnect(() async {
      final hari = getHariFromDate(tanggal);
      final list = await _requireDb.collection('jadwal_kuliah').find({
        r'$or': [
          {'kodeDosen': dosenId},
          {'dosenId': dosenId},
          {'dosenIds': dosenId},
        ],
        'hari': hari,
      }).toList();
      list.sort(
        (a, b) => (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        ),
      );
      return list;
    });
  }

  // ─────────────────────────────────────────────────────
  // PRESENSI (legacy — tetap pakai record_presensi, sesiId = jadwalId)
  // ─────────────────────────────────────────────────────

  /// Mengambil status presensi semua mahasiswa untuk satu sesi (jadwalId + hari ini).
  /// Status: 'belum' | 'hadir' | 'izin' | 'sakit' | 'alpha'
  Future<List<Map<String, dynamic>>> getStatusPresensiMahasiswaByJadwal(
    String jadwalId,
  ) async {
    await connect();

    // 1. Ambil daftar mahasiswa terdaftar di jadwal ini
    final enrollments = await _requireDb.collection('enrollments').find({
      'jadwalId': jadwalId,
      'status': 'aktif',
    }).toList();

    if (enrollments.isEmpty) return [];

    final mahasiswaIds = enrollments
        .map((e) => e['mahasiswaId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // 2. Ambil nama mahasiswa
    final mahasiswaList = await _requireDb.collection('mahasiswa').find({
      '_id': {r'$in': mahasiswaIds},
    }).toList();
    final Map<String, String> namaMap = {
      for (var m in mahasiswaList)
        m['_id']?.toString() ?? '':
            m['nama']?.toString() ?? m['name']?.toString() ?? '-',
    };

    // 3. Ambil record presensi hari ini untuk sesi ini
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final presensiRaw = await _requireDb.collection('record_presensi').find({
      'sesiId': jadwalId,
    }).toList();

    // Filter hari ini secara manual (handle DateTime & String)
    final Map<String, String> presensiMap = {};
    for (final p in presensiRaw) {
      final mahId = p['mahasiswaId']?.toString() ?? '';
      if (mahId.isEmpty) continue;
      final ts = p['timestamp'];
      DateTime? tsDate;
      if (ts is DateTime)
        tsDate = ts;
      else if (ts is String)
        tsDate = DateTime.tryParse(ts);
      if (tsDate == null) continue;
      if (tsDate.isBefore(startOfDay) || tsDate.isAfter(endOfDay)) continue;
      final status = p['status']?.toString() ?? 'hadir';
      presensiMap[mahId] = status;
    }

    // 4. Ambil izin/sakit yang berlaku hari ini dan menyertakan jadwalId ini
    final izinRaw = await _requireDb.collection('izin_mahasiswa').find({
      'jadwalIdsTerdampak': {
        r'$in': [jadwalId],
      },
      'status': {
        r'$in': ['approved_wali', 'closed'],
      },
    }).toList();

    final Map<String, String> izinMap = {};
    for (final izin in izinRaw) {
      final mahId = izin['mahasiswaId']?.toString() ?? '';
      if (mahId.isEmpty) continue;
      final tgl = izin['tanggalIzin'];
      DateTime? tglDate;
      if (tgl is DateTime)
        tglDate = tgl;
      else if (tgl is String)
        tglDate = DateTime.tryParse(tgl);
      if (tglDate == null) continue;
      // Tanggal izin disimpan sebagai UTC midnight (date-only). Bandingkan
      // di UTC supaya tidak ter-shift oleh timezone lokal.
      final tglUtc = tglDate.toUtc();
      final nowUtc = now.toUtc();
      if (tglUtc.year == nowUtc.year &&
          tglUtc.month == nowUtc.month &&
          tglUtc.day == nowUtc.day) {
        izinMap[mahId] = izin['jenis']?.toString() ?? 'izin';
      }
    }

    // 5. Gabungkan hasil
    final result = mahasiswaIds.map((nim) {
      String status = 'belum';
      if (presensiMap.containsKey(nim)) {
        final s = presensiMap[nim]!;
        // Status dari record_presensi bisa: hadir, alpha, izin, sakit (manual dosen)
        status = (s == 'hadir' || s == 'alpha' || s == 'izin' || s == 'sakit')
            ? s
            : 'hadir';
      } else if (izinMap.containsKey(nim)) {
        // Izin dari wali/mahasiswa
        status = izinMap[nim]!;
      }
      return {'nim': nim, 'nama': namaMap[nim] ?? nim, 'status': status};
    }).toList();

    result.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));
    return result;
  }

  /// Menandai status mahasiswa secara manual oleh dosen.
  /// status: 'alpha' | 'izin' | 'sakit' | 'hapus' (hapus = kembali ke Belum Absen)
  Future<void> tandaiStatusMahasiswaByDosen(
    String jadwalId,
    String mahasiswaId,
    String status,
  ) async {
    await connect();
    final coll = _requireDb.collection('record_presensi');
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Cari record yang sudah ada hari ini
    final allToday = await coll.find({
      'sesiId': jadwalId,
      'mahasiswaId': mahasiswaId,
    }).toList();
    Map<String, dynamic>? existing;
    for (final r in allToday) {
      final ts = r['timestamp'];
      DateTime? tsDate;
      if (ts is DateTime)
        tsDate = ts;
      else if (ts is String)
        tsDate = DateTime.tryParse(ts);
      if (tsDate != null && !tsDate.isBefore(start) && !tsDate.isAfter(end)) {
        existing = r;
        break;
      }
    }

    if (existing != null) {
      if (status == 'hapus') {
        // Hapus record manual (kembali ke "Belum Absen") — hanya hapus jika markedByDosen
        if (existing['markedByDosen'] == true) {
          await coll.deleteOne({'_id': existing['_id']});
        }
      } else {
        await coll.updateOne(
          {'_id': existing['_id']},
          {
            r'$set': {
              'status': status,
              'markedByDosen': true,
              'updatedAt': now,
            },
          },
        );
      }
    } else if (status != 'hapus') {
      await coll.insertOne({
        '_id': ObjectId(),
        'sesiId': jadwalId,
        'mahasiswaId': mahasiswaId,
        'status': status,
        'timestamp': now,
        'createdAt': now,
        'markedByDosen': true,
      });
    }
  }

  Future<void> insertRecordPresensi(Map<String, dynamic> record) async {
    await connect();
    final coll = _requireDb.collection('record_presensi');
    if (!record.containsKey('_id')) record['_id'] = ObjectId();
    if (record['timestamp'] is String) {
      record['timestamp'] =
          DateTime.tryParse(record['timestamp']) ?? record['timestamp'];
    }
    if (record['createdAt'] is String) {
      record['createdAt'] =
          DateTime.tryParse(record['createdAt']) ?? record['createdAt'];
    }
    if (record['updatedAt'] is String) {
      record['updatedAt'] =
          DateTime.tryParse(record['updatedAt']) ?? record['updatedAt'];
    }
    await coll.insertOne(record);
  }

  Future<bool> checkPresensiExists(String sesiId, String mahasiswaId) async {
    await connect();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final r = await _requireDb.collection('record_presensi').findOne({
      'sesiId': sesiId,
      'mahasiswaId': mahasiswaId,
      'timestamp': {
        r'$gte': start.toIso8601String(),
        r'$lte': end.toIso8601String(),
      },
    });
    return r != null;
  }

  // ─────────────────────────────────────────────────────
  // LAPORAN DOSEN (BAP) — legacy tetap dipakai
  // ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getLaporanDosen(
    String jadwalId,
    String dosenId,
  ) async {
    await connect();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _requireDb.collection('laporan_dosen').findOne({
      'jadwalId': jadwalId,
      'dosenId': dosenId,
      'tanggal': {r'$gte': start, r'$lte': end},
    });
  }

  Future<List<Map<String, dynamic>>> getAllLaporanDosen(String dosenId) async {
    await connect();
    return _requireDb.collection('laporan_dosen').find({
      'dosenId': dosenId,
    }).toList();
  }

  Future<bool> isKelasBerjalan(String jadwalId) async {
    await connect();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final coll = _requireDb.collection('laporan_dosen');

    var r = await coll.findOne({
      'jadwalId': jadwalId,
      'tanggal': {r'$gte': start, r'$lte': end},
    });
    String matchedVia = r != null ? 'tanggal-DateTime' : 'none';
    if (r == null) {
      r = await coll.findOne({
        'jadwalId': jadwalId,
        'tanggal': {
          r'$gte': start.toIso8601String(),
          r'$lte': end.toIso8601String(),
        },
      });
      if (r != null) matchedVia = 'tanggal-String';
    }
    if (r == null) {
      final all = await coll.find({'jadwalId': jadwalId}).toList();
      for (final rec in all) {
        DateTime? t;
        final v = rec['tanggal'];
        if (v is DateTime)
          t = v;
        else if (v is String)
          t = DateTime.tryParse(v);
        if (t != null &&
            t.year == now.year &&
            t.month == now.month &&
            t.day == now.day) {
          r = rec;
          matchedVia = 'tanggal-fallback';
          break;
        }
      }
    }
    if (r == null) {
      print('[isKelasBerjalan] $jadwalId → null (matchedVia=$matchedVia)');
      return false;
    }
    final result = r['waktuMulai'] != null && r['waktuSelesai'] == null;
    print(
      '[isKelasBerjalan] $jadwalId → $result '
      '(matchedVia=$matchedVia, waktuMulai=${r['waktuMulai']}, waktuSelesai=${r['waktuSelesai']})',
    );
    return result;
  }

  Future<void> insertOrUpdateLaporanDosen(Map<String, dynamic> record) async {
    await connect();
    final coll = _requireDb.collection('laporan_dosen');
    for (final key in ['waktuMulai', 'waktuSelesai', 'tanggal']) {
      if (record[key] is String && record[key] != null) {
        record[key] = DateTime.tryParse(record[key]) ?? record[key];
      }
    }
    final tgl = record['tanggal'] as DateTime;
    final query = {
      'jadwalId': record['jadwalId'],
      'dosenId': record['dosenId'],
      'tanggal': {
        r'$gte': DateTime(tgl.year, tgl.month, tgl.day),
        r'$lte': DateTime(tgl.year, tgl.month, tgl.day, 23, 59, 59),
      },
    };
    final existing = await coll.findOne(query);
    if (existing != null) {
      await coll.update(
        where.id(existing['_id']),
        modify
            .set('waktuSelesai', record['waktuSelesai'])
            .set('materi', record['materi'])
            .set('updatedAt', DateTime.now()),
      );
    } else {
      if (!record.containsKey('_id')) record['_id'] = ObjectId();
      record['createdAt'] = DateTime.now();
      await coll.insertOne(record);
    }
  }

  // ─────────────────────────────────────────────────────
  // PERGANTIAN JADWAL (legacy)
  // ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRuanganTersedia(
    DateTime tanggal,
    String jamMulai,
    String jamSelesai,
  ) async {
    await connect();
    final master = await _requireDb.collection('ruangan').find().toList();
    final hari = getHariFromDate(tanggal);
    final reguler = await _requireDb.collection('jadwal_kuliah').find({
      'hari': hari,
      'isActive': true,
      r'$and': [
        {
          'jamMulai': {r'$lt': jamSelesai},
        },
        {
          'jamSelesai': {r'$gt': jamMulai},
        },
      ],
    }).toList();

    final start = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final end = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);
    final pengajuan = await _requireDb
        .collection('pengajuan_ganti_jadwal')
        .find({
          'tanggalPengganti': {
            r'$gte': start.toIso8601String(),
            r'$lte': end.toIso8601String(),
          },
          'status': {
            r'$in': ['pending', 'approved'],
          },
          r'$and': [
            {
              'jamMulaiPengganti': {r'$lt': jamSelesai},
            },
            {
              'jamSelesaiPengganti': {r'$gt': jamMulai},
            },
          ],
        })
        .toList();

    final terpakai = <String>{};
    for (final j in reguler) {
      final r = j['ruangan'] as String? ?? '';
      terpakai.add(r.split('-')[0].trim());
    }
    for (final p in pengajuan) {
      final r = p['ruanganPengganti'] as String? ?? '';
      terpakai.add(r.split('-')[0].trim());
    }

    final hasil = master
        .map(
          (m) => {
            'nama': m['nama'] ?? m['kode'] ?? '',
            'isTerpakai': terpakai.contains(m['kode'] ?? m['nama']),
          },
        )
        .toList();
    hasil.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));
    return hasil;
  }

  Future<List<Map<String, dynamic>>> getDetailJadwalRuangan(
    DateTime tanggal,
    String ruangan,
  ) async {
    await connect();
    final hari = getHariFromDate(tanggal);
    final reguler = await _requireDb.collection('jadwal_kuliah').find({
      'hari': hari,
      'ruangan': {r'$regex': '^$ruangan'},
    }).toList();

    final start = DateTime(tanggal.year, tanggal.month, tanggal.day);
    final end = DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);
    final pengajuan = await _requireDb
        .collection('pengajuan_ganti_jadwal')
        .find({
          'tanggalPengganti': {
            r'$gte': start.toIso8601String(),
            r'$lte': end.toIso8601String(),
          },
          'status': {
            r'$in': ['pending', 'approved'],
          },
          'ruanganPengganti': {r'$regex': '^$ruangan'},
        })
        .toList();

    final detail = <Map<String, dynamic>>[];
    for (final j in reguler) {
      detail.add({
        'jamMulai': j['jamMulai'] ?? '',
        'jamSelesai': j['jamSelesai'] ?? '',
        'namaMK': j['namaMK'] ?? j['mataKuliah'] ?? 'Mata Kuliah',
        'kelas': j['kelas'] ?? '',
        'jenis': 'Reguler',
      });
    }
    for (final p in pengajuan) {
      detail.add({
        'jamMulai': p['jamMulaiPengganti'] ?? '',
        'jamSelesai': p['jamSelesaiPengganti'] ?? '',
        'namaMK': p['namaMK'] ?? 'Mata Kuliah',
        'kelas': p['kelas'] ?? '',
        'jenis': 'Pengganti',
      });
    }
    detail.sort(
      (a, b) => (a['jamMulai'] as String).compareTo(b['jamMulai'] as String),
    );
    return detail;
  }

  Future<List<Map<String, dynamic>>> getPengajuanDosen(String dosenId) async {
    return _withReconnect(() async {
      print('[DBG] getPengajuanDosen called with dosenId="$dosenId"');
      final list = await _requireDb.collection('pengajuan_ganti_jadwal').find({
        'dosenId': dosenId,
      }).toList();
      print('[DBG] getPengajuanDosen returned ${list.length} docs');
      if (list.isEmpty) {
        // Sanity check — apa saja dosenId yg ada di koleksi ini?
        final all = await _requireDb
            .collection('pengajuan_ganti_jadwal')
            .find()
            .toList();
        print('[DBG] total docs in pengajuan_ganti_jadwal: ${all.length}');
        print(
          '[DBG] dosenIds in collection: ${all.map((d) => d['dosenId']).toList()}',
        );
      }
      list.sort(
        (a, b) => (b['createdAt'] as String? ?? '').compareTo(
          a['createdAt'] as String? ?? '',
        ),
      );
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> getAllPengajuan() async {
    return _withReconnect(() async {
      final list = await _requireDb
          .collection('pengajuan_ganti_jadwal')
          .find()
          .toList();
      list.sort(
        (a, b) => (b['createdAt'] as String? ?? '').compareTo(
          a['createdAt'] as String? ?? '',
        ),
      );
      return list;
    });
  }

  Future<void> updateStatusPengajuan(dynamic id, String status) async {
    await _withReconnect(() async {
      await _requireDb
          .collection('pengajuan_ganti_jadwal')
          .update(
            where.id(id),
            modify
                .set('status', status)
                .set('updatedAt', DateTime.now().toIso8601String()),
          );
    });
  }

  Future<void> ajukanGantiJadwal(Map<String, dynamic> data) async {
    await _withReconnect(() async {
      if (!data.containsKey('_id')) data['_id'] = ObjectId();
      if (data['tanggalPengganti'] is DateTime) {
        data['tanggalPengganti'] = (data['tanggalPengganti'] as DateTime)
            .toIso8601String();
      }
      await _requireDb.collection('pengajuan_ganti_jadwal').insertOne(data);
    });
  }

  Future<void> submitIzinDosen(Map<String, dynamic> data) async {
    await connect();
    if (!data.containsKey('_id')) data['_id'] = ObjectId();
    await _requireDb.collection('izin_dosen').insertOne(data);
  }

  // ─────────────────────────────────────────────────────
  // IZIN MAHASISWA — workflow baru
  // ─────────────────────────────────────────────────────
  //
  // status: pending_wali → approved_wali → closed
  //                     ↘ rejected_wali (terminal)

  /// Submit izin oleh mahasiswa. Aplikasi yang isi `jadwalIdsTerdampak` —
  /// service ini hanya insert data apa adanya.
  Future<void> submitIzinMahasiswa(Map<String, dynamic> data) async {
    await _withReconnect(() async {
      if (!data.containsKey('_id')) data['_id'] = ObjectId();
      data['status'] ??= 'pending_wali';
      data['createdAt'] ??= DateTime.now();
      data['updatedAt'] = DateTime.now();
      await _requireDb.collection('izin_mahasiswa').insertOne(data);
    });
  }

  /// Cek apakah dokumen izin dengan `clientUuid` ini sudah ada di server.
  /// Dipakai SyncManager sebagai dedup guard sebelum re-insert.
  Future<bool> izinExistsByClientUuid(String clientUuid) async {
    return _withReconnect(() async {
      final r = await _requireDb
          .collection('izin_mahasiswa')
          .findOne(where.eq('clientUuid', clientUuid));
      return r != null;
    });
  }

  Future<List<Map<String, dynamic>>> getIzinByMahasiswa(
    String mahasiswaId,
  ) async {
    return _withReconnect(() async {
      final list = await _requireDb
          .collection('izin_mahasiswa')
          .find(where.eq('mahasiswaId', mahasiswaId))
          .toList();
      list.sort((a, b) {
        final ta = a['createdAt'] is DateTime
            ? (a['createdAt'] as DateTime)
            : DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        final tb = b['createdAt'] is DateTime
            ? (b['createdAt'] as DateTime)
            : DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// List izin yang menunggu approval wali untuk kelas tertentu.
  ///
  /// Filter `program` dibuat permissive: match dokumen yang `program == [program]`
  /// ATAU yang `program` null/missing. Ini mengantisipasi kasus dokumen mahasiswa
  /// tidak punya field `program` (sehingga izin yang ia submit `program: null`),
  /// padahal akun wali dosen punya `program: 'D3'`.
  Future<List<Map<String, dynamic>>> getIzinPendingByWali({
    required String kelas,
    String? program,
  }) async {
    return _withReconnect(() async {
      final selector = <String, dynamic>{
        'kelas': kelas,
        'status': 'pending_wali',
      };
      final finalSelector = program == null
          ? selector
          : {
              r'$and': [
                ...selector.entries.map((e) => {e.key: e.value}),
                {
                  r'$or': [
                    {'program': program},
                    {'program': null},
                  ],
                },
              ],
            };
      final list = await _requireDb
          .collection('izin_mahasiswa')
          .find(finalSelector)
          .toList();
      print(
        '[getIzinPendingByWali] kelas=$kelas program=$program → ${list.length} doc',
      );
      list.sort((a, b) {
        final ta = a['createdAt'] is DateTime
            ? (a['createdAt'] as DateTime)
            : DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        final tb = b['createdAt'] is DateTime
            ? (b['createdAt'] as DateTime)
            : DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// List izin (riwayat) untuk wali tanpa filter status — buat tab riwayat.
  /// Filter `program` permissive (lihat catatan di [getIzinPendingByWali]).
  Future<List<Map<String, dynamic>>> getAllIzinByKelas({
    required String kelas,
    String? program,
  }) async {
    return _withReconnect(() async {
      final selector = <String, dynamic>{'kelas': kelas};
      final finalSelector = program == null
          ? selector
          : {
              r'$and': [
                ...selector.entries.map((e) => {e.key: e.value}),
                {
                  r'$or': [
                    {'program': program},
                    {'program': null},
                  ],
                },
              ],
            };
      final list = await _requireDb
          .collection('izin_mahasiswa')
          .find(finalSelector)
          .toList();
      print(
        '[getAllIzinByKelas] kelas=$kelas program=$program → ${list.length} doc',
      );
      list.sort((a, b) {
        final ta = a['createdAt'] is DateTime
            ? (a['createdAt'] as DateTime)
            : DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        final tb = b['createdAt'] is DateTime
            ? (b['createdAt'] as DateTime)
            : DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                  DateTime(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  Future<void> approveIzinByWali({
    required dynamic izinId,
    required String walidosenId,
    String? catatan,
  }) async {
    await connect();
    await _requireDb
        .collection('izin_mahasiswa')
        .update(
          where.id(
            izinId is ObjectId
                ? izinId
                : ObjectId.fromHexString(izinId.toString()),
          ),
          modify
              .set('status', 'approved_wali')
              .set('approvedByWali', walidosenId)
              .set('approvedByWaliAt', DateTime.now())
              .set('catatanWali', catatan)
              .set('updatedAt', DateTime.now()),
        );
  }

  Future<void> rejectIzinByWali({
    required dynamic izinId,
    required String walidosenId,
    String? catatan,
  }) async {
    await connect();
    await _requireDb
        .collection('izin_mahasiswa')
        .update(
          where.id(
            izinId is ObjectId
                ? izinId
                : ObjectId.fromHexString(izinId.toString()),
          ),
          modify
              .set('status', 'rejected_wali')
              .set('rejectedByWali', walidosenId)
              .set('rejectedByWaliAt', DateTime.now())
              .set('catatanWali', catatan)
              .set('updatedAt', DateTime.now()),
        );
  }

  /// Untuk dosen pengampu: ambil izin yang sudah approved wali, dan jadwal yang
  /// dia ampu ada di `jadwalIdsTerdampak`, dan belum ditandai final.
  Future<List<Map<String, dynamic>>> getIzinTindakLanjutByDosen(
    String dosenKode,
  ) async {
    return _withReconnect(() async {
      // Step 1: ambil semua jadwalId yang dosen ini ampu (single atau team teaching)
      final jadwalDosen = await _requireDb.collection('jadwal_kuliah').find({
        r'$or': [
          {'kodeDosen': dosenKode},
          {'dosenId': dosenKode},
          {'dosenIds': dosenKode},
        ],
      }).toList();
      final jadwalIds = jadwalDosen.map((j) => j['_id'].toString()).toSet();
      if (jadwalIds.isEmpty) return [];

      // Step 2: ambil izin yg approved_wali dan punya jadwal yg dosen ampu
      final list = await _requireDb.collection('izin_mahasiswa').find({
        'status': {
          r'$in': ['approved_wali', 'closed'],
        },
        'jadwalIdsTerdampak': {r'$in': jadwalIds.toList()},
      }).toList();
      list.sort((a, b) {
        final ta = a['updatedAt'] is DateTime
            ? (a['updatedAt'] as DateTime)
            : DateTime.tryParse(a['updatedAt']?.toString() ?? '') ??
                  DateTime(0);
        final tb = b['updatedAt'] is DateTime
            ? (b['updatedAt'] as DateTime)
            : DateTime.tryParse(b['updatedAt']?.toString() ?? '') ??
                  DateTime(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// Dosen menandai status final izin per-jadwal.
  Future<void> tandaiStatusFinalIzin({
    required dynamic izinId,
    required String jadwalId,
    required String dosenKode,
    required String statusFinal, // 'izin' | 'sakit' | 'alpha'
    String? catatan,
  }) async {
    await connect();
    final coll = _requireDb.collection('izin_mahasiswa');
    final id = izinId is ObjectId
        ? izinId
        : ObjectId.fromHexString(izinId.toString());
    final doc = await coll.findOne(where.id(id));
    if (doc == null) return;

    final List existing = (doc['tindakLanjutDosen'] as List?) ?? [];
    final List<Map<String, dynamic>> updated = [];
    bool found = false;
    for (final t in existing) {
      final m = Map<String, dynamic>.from(t as Map);
      if (m['jadwalId']?.toString() == jadwalId) {
        m['statusFinal'] = statusFinal;
        m['catatanDosen'] = catatan;
        m['ditandaiOleh'] = dosenKode;
        m['ditandaiPada'] = DateTime.now();
        found = true;
      }
      updated.add(m);
    }
    if (!found) {
      updated.add({
        'jadwalId': jadwalId,
        'dosenId': dosenKode,
        'statusFinal': statusFinal,
        'catatanDosen': catatan,
        'ditandaiOleh': dosenKode,
        'ditandaiPada': DateTime.now(),
      });
    }

    // Cek apakah semua jadwalIdsTerdampak sudah ditandai → status closed
    final List jadwalIds = (doc['jadwalIdsTerdampak'] as List?) ?? [];
    final taggedIds = updated
        .where((t) => t['statusFinal'] != null && t['statusFinal'] != 'pending')
        .map((t) => t['jadwalId']?.toString())
        .toSet();
    final allClosed =
        jadwalIds.isNotEmpty &&
        jadwalIds.every((j) => taggedIds.contains(j.toString()));

    await coll.update(
      where.id(id),
      modify
          .set('tindakLanjutDosen', updated)
          .set('status', allClosed ? 'closed' : 'approved_wali')
          .set('updatedAt', DateTime.now()),
    );
  }

  // ─────────────────────────────────────────────────────
  // ADMIN: ASSIGN WALI DOSEN
  // ─────────────────────────────────────────────────────

  /// Buat akun wali dosen baru. ID = `WD_<dosenKode>_<kelas>_<program>`.
  Future<Map<String, dynamic>> assignWaliDosen({
    required String adminId,
    required String kelas,
    required String program,
    required String dosenKode,
    String passwordPlain = 'pass123',
    String? email,
  }) async {
    await connect();
    final dosen = await _requireDb
        .collection('dosen')
        .findOne(where.eq('_id', dosenKode));
    if (dosen == null) {
      throw Exception('Dosen $dosenKode tidak ditemukan.');
    }
    final waliId = 'WD_${dosenKode}_${kelas}_$program';
    final waliDoc = {
      '_id': waliId,
      'kode': waliId,
      'dosenKode': dosenKode,
      'nama': dosen['nama'],
      'email': email ?? dosen['email'],
      'kelasWali': kelas,
      'program': program,
      'passwordHash': r'$2b$10$placeholder',
      'passwordPlain': passwordPlain,
      'isActive': true,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
    await _requireDb
        .collection('wali_dosen')
        .replaceOne(where.eq('_id', waliId), waliDoc, upsert: true);

    final periode = await getActivePeriode();
    final periodeKode = periode?['kode'] ?? '';
    final assignId = '${waliId}_$periodeKode';
    await _requireDb
        .collection('wali_assignments')
        .replaceOne(where.eq('_id', assignId), {
          '_id': assignId,
          'kelas': kelas,
          'program': program,
          'walidosenId': waliId,
          'dosenKode': dosenKode,
          'periodeAkademikKode': periodeKode,
          'periodeAkademikId': periode?['_id'],
          'assignedBy': adminId,
          'assignedAt': DateTime.now(),
          'active': true,
        }, upsert: true);
    return waliDoc;
  }

  Future<List<Map<String, dynamic>>> getAllWaliDosen() async {
    await connect();
    return _requireDb.collection('wali_dosen').find().toList();
  }

  Future<List<Map<String, dynamic>>> getAllDosen() async {
    await connect();
    return _requireDb.collection('dosen').find().toList();
  }

  Future<List<Map<String, dynamic>>> getAllRuangan() async {
    await connect();
    return _requireDb.collection('ruangan').find().toList();
  }

  Future<List<Map<String, dynamic>>> getAllMataKuliah() async {
    await connect();
    return _requireDb.collection('mata_kuliah').find().toList();
  }

  // ─────────────────────────────────────────────────────
  // ADMIN: ASSIGN KAPRODI
  // ─────────────────────────────────────────────────────

  /// Buat akun kaprodi baru. ID = `KP_<dosenKode>_<program>`.
  Future<Map<String, dynamic>> assignKaprodi({
    required String adminId,
    required String program,
    required String dosenKode,
    String passwordPlain = 'pass123',
    String? email,
  }) async {
    await connect();
    final dosen = await _requireDb
        .collection('dosen')
        .findOne(where.eq('_id', dosenKode));
    if (dosen == null) {
      throw Exception('Dosen $dosenKode tidak ditemukan.');
    }
    final kaprodiId = 'KP_${dosenKode}_$program';
    final kaprodiDoc = {
      '_id': kaprodiId,
      'kode': kaprodiId,
      'dosenKode': dosenKode,
      'nama': dosen['nama'],
      'email': email ?? dosen['email'],
      'program': program,
      'passwordHash': r'$2b$10$placeholder',
      'passwordPlain': passwordPlain,
      'isActive': true,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
    await _requireDb
        .collection('kaprodi')
        .replaceOne(where.eq('_id', kaprodiId), kaprodiDoc, upsert: true);

    final periode = await getActivePeriode();
    final periodeKode = periode?['kode'] ?? '';
    final assignId = '${kaprodiId}_$periodeKode';
    await _requireDb
        .collection('kaprodi_assignments')
        .replaceOne(where.eq('_id', assignId), {
          '_id': assignId,
          'program': program,
          'kaprodiId': kaprodiId,
          'dosenKode': dosenKode,
          'periodeAkademikKode': periodeKode,
          'periodeAkademikId': periode?['_id'],
          'assignedBy': adminId,
          'assignedAt': DateTime.now(),
          'active': true,
        }, upsert: true);
    return kaprodiDoc;
  }

  Future<List<Map<String, dynamic>>> getAllKaprodi() async {
    await connect();
    return _requireDb.collection('kaprodi').find().toList();
  }

  // ─────────────────────────────────────────────────────
  // KAPRODI: KELOLA SESI ABSENSI DOSEN
  // ─────────────────────────────────────────────────────

  /// Ambil jadwal per hari dengan status sesi absensi untuk program tertentu
  Future<Map<String, List<Map<String, dynamic>>>> getJadwalPerHariByProgram(
    String program,
  ) async {
    return _withReconnect(() async {
      try {
        print('[getJadwalPerHariByProgram] START - program: $program');
        
        // Step 1: Get active periode (use raw to avoid nested _withReconnect)
        print('[getJadwalPerHariByProgram] Step 1: Getting active periode...');
        final periode = await _getActivePeriodeRaw();
        
        if (periode == null) {
          print('[getJadwalPerHariByProgram] ERROR: No active periode found');
          return {};
        }
        
        print('[getJadwalPerHariByProgram] Active periode: ${periode['kode']}');

        // Step 2: Get jadwal list
        print('[getJadwalPerHariByProgram] Step 2: Getting jadwal list...');
        List<Map<String, dynamic>> jadwalList;
        try {
          jadwalList = await _requireDb.collection('jadwal_kuliah')
              .find({
                'program': program,
                'periodeAkademikKode': periode['kode'],
              })
              .toList()
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          print('[getJadwalPerHariByProgram] TIMEOUT/ERROR getting jadwal: $e');
          return {};
        }

        print('[getJadwalPerHariByProgram] Found ${jadwalList.length} jadwal');

        if (jadwalList.isEmpty) {
          print('[getJadwalPerHariByProgram] No jadwal found, returning empty');
          return {};
        }

        // Step 3: Get all dosen (batch)
        print('[getJadwalPerHariByProgram] Step 3: Getting dosen data...');
        final dosenKodes = jadwalList
            .map((j) => j['kodeDosen']?.toString() ?? '')
            .where((k) => k.isNotEmpty)
            .toSet()
            .toList();

        print('[getJadwalPerHariByProgram] Fetching ${dosenKodes.length} dosen...');
        
        List<Map<String, dynamic>> dosenList;
        try {
          dosenList = await _requireDb.collection('dosen')
              .find({
                '_id': {r'$in': dosenKodes},
              })
              .toList()
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          print('[getJadwalPerHariByProgram] TIMEOUT/ERROR getting dosen: $e');
          dosenList = [];
        }

        print('[getJadwalPerHariByProgram] Found ${dosenList.length} dosen');

        final Map<String, String> dosenMap = {
          for (var d in dosenList)
            d['_id']?.toString() ?? '': d['nama']?.toString() ?? '-',
        };

        // Step 4: Get laporan for today (batch)
        print('[getJadwalPerHariByProgram] Step 4: Getting laporan...');
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final jadwalIds = jadwalList.map((j) => j['_id'].toString()).toList();
        
        print('[getJadwalPerHariByProgram] Fetching laporan for ${jadwalIds.length} jadwal...');
        
        List<Map<String, dynamic>> laporanList;
        try {
          laporanList = await _requireDb.collection('laporan_dosen')
              .find({
                'jadwalId': {r'$in': jadwalIds},
              })
              .toList()
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          print('[getJadwalPerHariByProgram] TIMEOUT/ERROR getting laporan: $e');
          laporanList = [];
        }

        print('[getJadwalPerHariByProgram] Found ${laporanList.length} total laporan');

        // Filter laporan untuk hari ini
        final Map<String, Map<String, dynamic>> laporanMap = {};
        for (final lap in laporanList) {
          final tanggal = lap['tanggal'];
          DateTime? tglDate;
          if (tanggal is DateTime) {
            tglDate = tanggal;
          } else if (tanggal is String) {
            tglDate = DateTime.tryParse(tanggal);
          }
          if (tglDate != null &&
              !tglDate.isBefore(startOfDay) &&
              !tglDate.isAfter(endOfDay)) {
            final jadwalId = lap['jadwalId']?.toString() ?? '';
            laporanMap[jadwalId] = lap;
          }
        }

        print('[getJadwalPerHariByProgram] Found ${laporanMap.length} laporan for today');

        // Step 5: Group by hari
        print('[getJadwalPerHariByProgram] Step 5: Grouping by hari...');
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        
        for (final jadwal in jadwalList) {
          final hari = jadwal['hari']?.toString() ?? 'Unknown';
          if (!grouped.containsKey(hari)) {
            grouped[hari] = [];
          }

          final jadwalId = jadwal['_id'].toString();
          final kodeDosen = jadwal['kodeDosen']?.toString() ?? '';
          final laporan = laporanMap[jadwalId];

          grouped[hari]!.add({
            ...jadwal,
            'namaDosen': dosenMap[kodeDosen] ?? '-',
            'statusSesi': laporan != null
                ? (laporan['waktuSelesai'] != null ? 'closed' : 'open')
                : 'not_opened',
            'waktuMulai': laporan?['waktuMulai'],
            'waktuSelesai': laporan?['waktuSelesai'],
            'laporanId': laporan?['_id']?.toString(),
          });
        }

        print('[getJadwalPerHariByProgram] SUCCESS - Grouped into ${grouped.length} days');
        return grouped;
      } catch (e, stackTrace) {
        print('[getJadwalPerHariByProgram] ERROR: $e');
        print('[getJadwalPerHariByProgram] StackTrace: $stackTrace');
        rethrow;
      }
    });
  }

  /// Kaprodi membuka sesi absensi untuk dosen yang lupa
  Future<void> bukakanSesiAbsensi({
    required String jadwalId,
    required String kaprodiId,
  }) async {
    await connect();
    final now = DateTime.now();

    // Cek apakah sudah ada laporan hari ini
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final existing = await _requireDb.collection('laporan_dosen').findOne({
      'jadwalId': jadwalId,
      'tanggal': {
        r'$gte': startOfDay,
        r'$lte': endOfDay,
      },
    });

    if (existing != null) {
      throw Exception('Sesi sudah dibuka untuk jadwal ini hari ini.');
    }

    // Ambil info jadwal untuk dosenId
    final jadwal = await _requireDb
        .collection('jadwal_kuliah')
        .findOne(where.eq('_id', jadwalId));
    if (jadwal == null) {
      throw Exception('Jadwal tidak ditemukan.');
    }

    final dosenId = jadwal['kodeDosen']?.toString() ?? '';

    // Buat laporan dosen baru
    await _requireDb.collection('laporan_dosen').insertOne({
      '_id': ObjectId(),
      'jadwalId': jadwalId,
      'dosenId': dosenId,
      'tanggal': now,
      'waktuMulai': now,
      'waktuSelesai': null,
      'materi': null,
      'dibukaOleh': 'kaprodi',
      'kaprodiId': kaprodiId,
      'syncStatus': 'synced',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  /// Kaprodi menutup sesi absensi untuk dosen yang lupa
  Future<void> tutupkanSesiAbsensi({
    required String laporanId,
    required String kaprodiId,
  }) async {
    await connect();
    final id = ObjectId.fromHexString(laporanId);
    await _requireDb.collection('laporan_dosen').updateOne(
      where.id(id),
      modify
          .set('waktuSelesai', DateTime.now())
          .set('ditutupOleh', 'kaprodi')
          .set('kaprodiId', kaprodiId)
          .set('updatedAt', DateTime.now()),
    );
  }

  // ─────────────────────────────────────────────────────
  // ADMIN: UPLOAD JADWAL (Excel/CSV)
  // ─────────────────────────────────────────────────────

  /// Validasi rows. Return list error per baris (kosong = aman).
  ///
  /// Aturan:
  /// - Field wajib non-kosong (mandatory).
  /// - Master data harus ada (`dosen`, `ruangan`).
  /// - Enum: `tipe ∈ {TE, PR}`, `program ∈ {D3, D4}`,
  ///   `hari ∈ {Senin..Minggu}`.
  /// - Format jam HH:MM atau HH.MM, dan jamMulai < jamSelesai.
  /// - Deteksi baris duplikat (composite ID sama persis).
  Future<List<String>> validateJadwalRows(
    List<Map<String, dynamic>> rows,
  ) async {
    await connect();
    final errors = <String>[];
    final dosenSet = (await _requireDb.collection('dosen').find().toList())
        .map((d) => d['_id'].toString())
        .toSet();
    final ruanganSet = (await _requireDb.collection('ruangan').find().toList())
        .map((r) => r['_id'].toString())
        .toSet();

    const validTipe = {'TE', 'PR'};
    const validProgram = {'D3', 'D4'};
    const validHari = {
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
    };

    // Untuk deteksi duplikat: composite ID + dosenKode (karena 1 jadwal bisa
    // diajar banyak dosen — itu BUKAN duplikat, tapi team teaching).
    final seen = <String, int>{}; // compositeId|dosen → first row

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final ln = i + 2; // baris di file (header = 1)

      // 1. Mandatory fields
      const mandatory = [
        'kodeMK',
        'namaMK',
        'kelas',
        'kodeDosen',
        'hari',
        'jamMulai',
        'jamSelesai',
        'kodeRuangan',
        'tipe',
        'program',
      ];
      bool hasEmpty = false;
      for (final f in mandatory) {
        if ((r[f]?.toString().trim() ?? '').isEmpty) {
          errors.add('Baris $ln: field "$f" kosong');
          hasEmpty = true;
        }
      }
      if (hasEmpty) continue; // skip cek lanjut kalau ada yg kosong

      // 2. Master data
      final kodeDosen = r['kodeDosen'].toString().trim();
      if (!dosenSet.contains(kodeDosen)) {
        errors.add(
          'Baris $ln: kodeDosen "$kodeDosen" tidak ada di koleksi dosen',
        );
      }
      final kodeRuangan = r['kodeRuangan'].toString().trim();
      if (!ruanganSet.contains(kodeRuangan)) {
        errors.add(
          'Baris $ln: kodeRuangan "$kodeRuangan" tidak ada di koleksi ruangan',
        );
      }

      // 3. Enum
      final tipe = r['tipe'].toString().trim();
      if (!validTipe.contains(tipe)) {
        errors.add('Baris $ln: tipe "$tipe" — harus TE atau PR');
      }
      final program = r['program'].toString().trim();
      if (!validProgram.contains(program)) {
        errors.add('Baris $ln: program "$program" — harus D3 atau D4');
      }
      final hari = r['hari'].toString().trim();
      if (!validHari.contains(hari)) {
        errors.add('Baris $ln: hari "$hari" tidak valid (Senin-Minggu)');
      }

      // 4. Jam: format & range
      final jamMulai = _normalizeJam(r['jamMulai'].toString().trim());
      final jamSelesai = _normalizeJam(r['jamSelesai'].toString().trim());
      if (jamMulai == null) {
        errors.add(
          'Baris $ln: jamMulai "${r['jamMulai']}" tidak valid (HH:MM)',
        );
      }
      if (jamSelesai == null) {
        errors.add(
          'Baris $ln: jamSelesai "${r['jamSelesai']}" tidak valid (HH:MM)',
        );
      }
      if (jamMulai != null && jamSelesai != null) {
        if (jamMulai.compareTo(jamSelesai) >= 0) {
          errors.add('Baris $ln: jamMulai harus lebih awal dari jamSelesai');
        }
      }

      // 5. Duplikat (composite + dosen)
      if (jamMulai != null &&
          validTipe.contains(tipe) &&
          validProgram.contains(program)) {
        final jamId = jamMulai.replaceAll(':', '');
        final compositeKey =
            '${program}_${r['kelas']}_${r['kodeMK']}_${hari}_${jamId}_${tipe}_$kodeDosen';
        if (seen.containsKey(compositeKey)) {
          errors.add(
            'Baris $ln: duplikat dengan baris ${seen[compositeKey]} '
            '(jadwal+dosen sama persis)',
          );
        } else {
          seen[compositeKey] = ln;
        }
      }
    }
    return errors;
  }

  /// Normalisasi format jam ke "HH:MM". Terima "HH.MM" atau "HH:MM".
  /// Return null kalau tidak valid.
  String? _normalizeJam(String raw) {
    final s = raw.replaceAll('.', ':').trim();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!);
    final mn = int.tryParse(m.group(2)!);
    if (h == null || mn == null) return null;
    if (h < 0 || h > 23 || mn < 0 || mn > 59) return null;
    return '${h.toString().padLeft(2, '0')}:${mn.toString().padLeft(2, '0')}';
  }

  /// Commit upload jadwal. `rows` sudah divalidasi.
  ///
  /// **Team teaching support**: Kalau beberapa baris punya composite ID identik
  /// (program+kelas+kodeMK+hari+jamMulai+tipe) tapi `kodeDosen` berbeda, mereka
  /// dianggap **satu jadwal team teaching**. Output dokumen punya:
  ///   - `dosenIds: [KO067N, KO003N, KO006N]`   (array, sumber kebenaran)
  ///   - `dosenId: KO067N`                       (primary, untuk back-compat)
  ///   - `kodeDosen: KO067N`                     (back-compat)
  ///   - `namaDosenList: ['Asri Maspupah', ...]` (array)
  ///   - `namaDosen: 'Asri Maspupah; Bambang Wisnuadhi; Irawan Thamrin'`
  ///     (string gabungan, untuk tampilan singkat)
  Future<Map<String, dynamic>> commitJadwalRows({
    required String adminId,
    required String periodeKode,
    required List<Map<String, dynamic>> rows,
    String? fileName,
  }) async {
    await connect();
    final periode = await _requireDb
        .collection('periode_akademik')
        .findOne(where.eq('kode', periodeKode));
    if (periode == null)
      throw Exception('Periode $periodeKode tidak ditemukan.');

    // Cache nama dosen & ruangan
    final dosenList = await _requireDb.collection('dosen').find().toList();
    final dosenName = {
      for (final d in dosenList)
        d['_id'].toString(): d['nama']?.toString() ?? '',
    };
    final ruanganList = await _requireDb.collection('ruangan').find().toList();
    final ruanganName = {
      for (final r in ruanganList)
        r['_id'].toString(): r['nama']?.toString() ?? r['_id'].toString(),
    };
    final mkColl = _requireDb.collection('mata_kuliah');
    final jadwalColl = _requireDb.collection('jadwal_kuliah');

    // ── 1. Group rows by composite jadwalId ──────────────────────────
    // Beberapa baris dengan jadwalId sama → team teaching.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final program = r['program'].toString().trim();
      final kelas = r['kelas'].toString().trim();
      final kodeMK = r['kodeMK'].toString().trim();
      final hari = r['hari'].toString().trim();
      final jamMulai =
          _normalizeJam(r['jamMulai'].toString()) ?? r['jamMulai'].toString();
      final tipe = r['tipe'].toString().trim();
      final jamId = jamMulai.replaceAll(':', '');
      final jadwalId = '${program}_${kelas}_${kodeMK}_${hari}_${jamId}_$tipe';
      groups.putIfAbsent(jadwalId, () => []).add({
        ...r,
        '_normalizedJamMulai': jamMulai,
      });
    }

    int matkulCreated = 0;
    int jadwalCreated = 0;
    int jadwalUpdated = 0;
    int teamTeachingCount = 0;

    for (final entry in groups.entries) {
      final jadwalId = entry.key;
      final groupRows = entry.value;
      final first = groupRows.first;

      final kodeMK = first['kodeMK'].toString().trim();
      final program = first['program'].toString().trim();
      final kelas = first['kelas'].toString().trim();
      final hari = first['hari'].toString().trim();
      final jamMulai = first['_normalizedJamMulai'].toString();
      final jamSelesai =
          _normalizeJam(first['jamSelesai'].toString()) ??
          first['jamSelesai'].toString();
      final tipe = first['tipe'].toString().trim();
      final kodeRuangan = first['kodeRuangan'].toString().trim();
      final namaMK = first['namaMK'].toString().trim();
      final sks = int.tryParse(first['sks']?.toString() ?? '0') ?? 0;
      final semester = int.tryParse(first['semester']?.toString() ?? '0') ?? 0;

      // ── 2. Upsert mata kuliah ──
      final existingMK = await mkColl.findOne(where.eq('_id', kodeMK));
      if (existingMK == null) {
        await mkColl.insertOne({
          '_id': kodeMK,
          'kode': kodeMK,
          'nama': namaMK,
          'sks': sks,
          'semester': semester,
          'program': program,
          'prodi': program == 'D4'
              ? 'D4 Teknik Informatika'
              : 'D3 Teknik Informatika',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
        matkulCreated++;
      }

      // ── 3. Build dosenIds (preserve order) ──
      final dosenIds = <String>[];
      final namaDosenList = <String>[];
      final seenDosen = <String>{};
      for (final r in groupRows) {
        final kd = r['kodeDosen'].toString().trim();
        if (seenDosen.add(kd)) {
          dosenIds.add(kd);
          namaDosenList.add(dosenName[kd] ?? kd);
        }
      }
      if (dosenIds.length > 1) teamTeachingCount++;

      // ── 4. Upsert jadwal_kuliah ──
      final existingJadwal = await jadwalColl.findOne(
        where.eq('_id', jadwalId),
      );
      final doc = <String, dynamic>{
        '_id': jadwalId,
        'jadwalId': jadwalId,
        'periodeAkademikKode': periodeKode,
        'periodeAkademikId': periode['_id'],
        'mataKuliahId': kodeMK,
        'kodeMK': kodeMK,
        'namaMK': namaMK,
        'sks': sks,
        'semester': semester,
        'kelas': kelas,
        'program': program,
        // Dosen — primary single (back-compat) + array (sumber kebenaran)
        'dosenId': dosenIds.first,
        'kodeDosen': dosenIds.first,
        'dosenIds': dosenIds,
        'namaDosen': namaDosenList.join('; '),
        'namaDosenList': namaDosenList,
        // Ruangan
        'ruanganId': kodeRuangan,
        'ruanganKode': kodeRuangan,
        'ruanganNama': ruanganName[kodeRuangan] ?? kodeRuangan,
        'ruangan': ruanganName[kodeRuangan] ?? kodeRuangan,
        // Slot
        'hari': hari,
        'jamMulai': jamMulai,
        'jamSelesai': jamSelesai,
        'tipe': tipe,
        'isActive': true,
        'createdAt': existingJadwal?['createdAt'] ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      await jadwalColl.replaceOne(where.eq('_id', jadwalId), doc, upsert: true);
      if (existingJadwal == null) {
        jadwalCreated++;
      } else {
        jadwalUpdated++;
      }
    }

    // ── 5. Audit log ──
    final auditId = ObjectId();
    final summary = {
      'totalRows': rows.length,
      'totalGroups': groups.length,
      'jadwalCreated': jadwalCreated,
      'jadwalUpdated': jadwalUpdated,
      'matkulCreated': matkulCreated,
      'teamTeachingCount': teamTeachingCount,
    };
    await _requireDb.collection('upload_jadwal').insertOne({
      '_id': auditId,
      'adminId': adminId,
      'fileName': fileName ?? 'manual',
      'periodeAkademikKode': periodeKode,
      'periodeAkademikId': periode['_id'],
      'tanggalUpload': DateTime.now(),
      'status': 'completed',
      'summary': summary,
      'createdAt': DateTime.now(),
    });
    return summary;
  }

  Future<List<Map<String, dynamic>>> getUploadJadwalHistory() async {
    await connect();
    final list = await _requireDb.collection('upload_jadwal').find().toList();
    list.sort((a, b) {
      final ta = a['tanggalUpload'] is DateTime
          ? (a['tanggalUpload'] as DateTime)
          : DateTime.tryParse(a['tanggalUpload']?.toString() ?? '') ??
                DateTime(0);
      final tb = b['tanggalUpload'] is DateTime
          ? (b['tanggalUpload'] as DateTime)
          : DateTime.tryParse(b['tanggalUpload']?.toString() ?? '') ??
                DateTime(0);
      return tb.compareTo(ta);
    });
    return list;
  }

  // ─────────────────────────────────────────────────────
  // STATS — Mahasiswa & Dosen rekap (sederhana)
  // ─────────────────────────────────────────────────────

  /// Hitung statistik mahasiswa: hadir/izin/sakit/alpha untuk periode aktif.
  /// Hitung dari record_presensi (hadir) + izin_mahasiswa (statusFinal).
  Future<Map<String, int>> getStatistikMahasiswa(String mahasiswaId) async {
    await connect();
    final hadir = await _requireDb.collection('record_presensi').count({
      'mahasiswaId': mahasiswaId,
      'statusHadir': true,
    });

    int izin = 0, sakit = 0, alpha = 0;
    final izinDocs = await _requireDb.collection('izin_mahasiswa').find({
      'mahasiswaId': mahasiswaId,
    }).toList();
    for (final d in izinDocs) {
      final List tindak = (d['tindakLanjutDosen'] as List?) ?? const [];
      for (final t in tindak) {
        final m = t as Map?;
        switch (m?['statusFinal']?.toString()) {
          case 'izin':
            izin++;
            break;
          case 'sakit':
            sakit++;
            break;
          case 'alpha':
            alpha++;
            break;
        }
      }
    }
    return {
      'hadir': hadir,
      'izin': izin,
      'sakit': sakit,
      'alpha': alpha,
      'total': hadir + izin + sakit + alpha,
    };
  }

  // ─────────────────────────────────────────────────────
  // ADMIN: KENAIKAN KELAS / SEMESTER
  // ─────────────────────────────────────────────────────

  /// Ambil semua mahasiswa (untuk listing & filter).
  Future<List<Map<String, dynamic>>> getAllMahasiswa() async {
    return _withReconnect(() async {
      final list = await _requireDb.collection('mahasiswa').find().toList();
      list.sort(
        (a, b) => (a['nama']?.toString() ?? '').compareTo(
          b['nama']?.toString() ?? '',
        ),
      );
      return list;
    });
  }

  /// Ambil daftar kelas unik dari koleksi mahasiswa.
  /// Return list of { 'kelas': '2B', 'program': 'D3', 'jumlah': 25 }.
  Future<List<Map<String, dynamic>>> getDistinctKelas() async {
    return _withReconnect(() async {
      final allMhs = await _requireDb.collection('mahasiswa').find().toList();
      final groups = <String, Map<String, dynamic>>{};
      for (final m in allMhs) {
        final kelas = m['kelas']?.toString() ?? '';
        final program = m['program']?.toString() ?? '';
        if (kelas.isEmpty) continue;
        final key = '${kelas}_$program';
        if (!groups.containsKey(key)) {
          groups[key] = {'kelas': kelas, 'program': program, 'jumlah': 0};
        }
        groups[key]!['jumlah'] = (groups[key]!['jumlah'] as int) + 1;
      }
      final list = groups.values.toList();
      list.sort((a, b) {
        final cmp = (a['program'] as String).compareTo(b['program'] as String);
        if (cmp != 0) return cmp;
        return (a['kelas'] as String).compareTo(b['kelas'] as String);
      });
      return list;
    });
  }

  /// Ambil semua user dari 3 koleksi (mahasiswa, dosen, wali_dosen),
  /// masing-masing sudah diurutkan berdasarkan ID (_id) ascending (terkecil->terbesar).
  Future<Map<String, List<Map<String, dynamic>>>> getAllUsersGrouped() async {
    return _withReconnect(() async {
      // -- Mahasiswa -- sort by NIM (numeric jika bisa, fallback string) --
      final mhsRaw = await _requireDb.collection('mahasiswa').find().toList();
      mhsRaw.sort((a, b) {
        final ia = int.tryParse(a['_id']?.toString() ?? '');
        final ib = int.tryParse(b['_id']?.toString() ?? '');
        if (ia != null && ib != null) return ia.compareTo(ib);
        return (a['_id']?.toString() ?? '').compareTo(
          b['_id']?.toString() ?? '',
        );
      });

      // -- Dosen -- sort by kode ascending --
      final dosenRaw = await _requireDb.collection('dosen').find().toList();
      dosenRaw.sort(
        (a, b) =>
            (a['_id']?.toString() ?? '').compareTo(b['_id']?.toString() ?? ''),
      );

      // -- Wali Dosen -- sort by _id ascending --
      final waliRaw = await _requireDb.collection('wali_dosen').find().toList();
      waliRaw.sort(
        (a, b) =>
            (a['_id']?.toString() ?? '').compareTo(b['_id']?.toString() ?? ''),
      );

      // -- Kaprodi -- sort by _id ascending --
      final kaprodiRaw = await _requireDb.collection('kaprodi').find().toList();
      kaprodiRaw.sort(
        (a, b) =>
            (a['_id']?.toString() ?? '').compareTo(b['_id']?.toString() ?? ''),
      );

      return {
        'mahasiswa': mhsRaw,
        'dosen': dosenRaw,
        'waliDosen': waliRaw,
        'kaprodi': kaprodiRaw,
      };
    });
  }

  /// Ambil statistik dashboard admin dari database (real-time).
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    return _withReconnect(() async {
      // Total mahasiswa
      final totalMahasiswa = await _requireDb
          .collection('mahasiswa')
          .count();

      // Total dosen
      final totalDosen = await _requireDb
          .collection('dosen')
          .count();

      // Sesi hari ini (laporan_dosen yang dibuat hari ini)
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final laporanToday = await _requireDb
          .collection('laporan_dosen')
          .find({
            'tanggal': {
              r'$gte': startOfDay,
              r'$lte': endOfDay,
            },
          })
          .toList();

      // Jika query tanggal tidak bekerja (karena format), coba filter manual
      int sesiHariIni = laporanToday.length;
      if (sesiHariIni == 0) {
        final allLaporan = await _requireDb
            .collection('laporan_dosen')
            .find()
            .toList();
        sesiHariIni = allLaporan.where((lap) {
          final tanggal = lap['tanggal'];
          DateTime? tglDate;
          if (tanggal is DateTime) tglDate = tanggal;
          else if (tanggal is String) tglDate = DateTime.tryParse(tanggal);
          if (tglDate == null) return false;
          return tglDate.year == today.year &&
              tglDate.month == today.month &&
              tglDate.day == today.day;
        }).length;
      }

      // Tingkat kehadiran: hitung dari record_presensi hari ini
      double tingkatKehadiran = 0;
      final presensiToday = await _requireDb
          .collection('record_presensi')
          .find()
          .toList();

      final presensiHariIni = presensiToday.where((p) {
        final ts = p['timestamp'];
        DateTime? tsDate;
        if (ts is DateTime) tsDate = ts;
        else if (ts is String) tsDate = DateTime.tryParse(ts);
        if (tsDate == null) return false;
        return tsDate.year == today.year &&
            tsDate.month == today.month &&
            tsDate.day == today.day;
      }).toList();

      final hadirCount = presensiHariIni
          .where((p) => p['status']?.toString() != 'alpha')
          .length;
      final totalPresensi = presensiHariIni.length;

      if (totalPresensi > 0) {
        tingkatKehadiran = (hadirCount / totalPresensi) * 100;
      } else {
        // Jika belum ada presensi hari ini, ambil rata-rata keseluruhan
        final allPresensi = presensiToday;
        final allHadir = allPresensi
            .where((p) => p['status']?.toString() != 'alpha')
            .length;
        if (allPresensi.isNotEmpty) {
          tingkatKehadiran = (allHadir / allPresensi.length) * 100;
        }
      }

      return {
        'totalMahasiswa': totalMahasiswa,
        'totalDosen': totalDosen,
        'sesiHariIni': sesiHariIni,
        'tingkatKehadiran': tingkatKehadiran.toStringAsFixed(1),
      };
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CRUD MANAJEMEN USER
  // ─────────────────────────────────────────────────────────────────────────

  /// Tambah mahasiswa baru ke koleksi `mahasiswa`.
  /// [nim] digunakan sebagai `_id`.
  Future<void> insertMahasiswa({
    required String nim,
    required String nama,
    required String email,
    required String password,
    required String kelas,
    required String program,
    required int semester,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('mahasiswa');
      final existing = await coll.findOne(where.eq('_id', nim));
      if (existing != null) {
        throw Exception('NIM $nim sudah terdaftar.');
      }
      await coll.insertOne({
        '_id': nim,
        'nama': nama,
        'email': email,
        'password': password,
        'kelas': kelas,
        'program': program,
        'semester': semester,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    });
  }

  /// Update data mahasiswa berdasarkan NIM (_id).
  Future<void> updateMahasiswa({
    required String nim,
    required String nama,
    required String email,
    String? password,
    required String kelas,
    required String program,
    required int semester,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('mahasiswa');
      final mods = modify
          .set('nama', nama)
          .set('email', email)
          .set('kelas', kelas)
          .set('program', program)
          .set('semester', semester)
          .set('updatedAt', DateTime.now());
      if (password != null && password.isNotEmpty) {
        mods.set('password', password);
      }
      await coll.updateOne(where.eq('_id', nim), mods);
    });
  }

  /// Tambah dosen baru ke koleksi `dosen`.
  /// [kode] digunakan sebagai `_id`.
  Future<void> insertDosen({
    required String kode,
    required String nama,
    required String email,
    required String password,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('dosen');
      final existing = await coll.findOne(where.eq('_id', kode));
      if (existing != null) {
        throw Exception('Kode dosen $kode sudah terdaftar.');
      }
      await coll.insertOne({
        '_id': kode,
        'kode': kode,
        'nama': nama,
        'email': email,
        'password': password,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    });
  }

  /// Update data dosen berdasarkan kode (_id).
  Future<void> updateDosen({
    required String kode,
    required String nama,
    required String email,
    String? password,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('dosen');
      final mods = modify
          .set('nama', nama)
          .set('email', email)
          .set('updatedAt', DateTime.now());
      if (password != null && password.isNotEmpty) {
        mods.set('password', password);
      }
      await coll.updateOne(where.eq('_id', kode), mods);
    });
  }

  /// Hapus mahasiswa berdasarkan NIM (_id).
  Future<void> deleteMahasiswa(String nim) async {
    return _withReconnect(() async {
      await _requireDb.collection('mahasiswa').deleteOne(where.eq('_id', nim));
    });
  }

  /// Hapus dosen berdasarkan kode (_id).
  Future<void> deleteDosen(String kode) async {
    return _withReconnect(() async {
      await _requireDb.collection('dosen').deleteOne(where.eq('_id', kode));
    });
  }

  /// Bulk insert mahasiswa dari list of maps (upload Excel).
  Future<void> bulkInsertMahasiswa(List<Map<String, dynamic>> rows) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('mahasiswa');
      final now = DateTime.now();
      for (final row in rows) {
        final nim = row['nim']?.toString().trim() ?? '';
        if (nim.isEmpty) continue;
        await coll.replaceOne(
          where.eq('_id', nim),
          {
            '_id': nim,
            'nama': row['nama']?.toString().trim() ?? '',
            'email': row['email']?.toString().trim() ?? '',
            'password': row['password']?.toString().trim() ?? 'pass123',
            'kelas': row['kelas']?.toString().trim() ?? '',
            'program': row['program']?.toString().trim() ?? 'D3',
            'semester': int.tryParse(row['semester']?.toString() ?? '1') ?? 1,
            'createdAt': now,
            'updatedAt': now,
          },
          upsert: true,
        );
      }
    });
  }

  /// Bulk insert dosen dari list of maps (upload Excel).
  Future<void> bulkInsertDosen(List<Map<String, dynamic>> rows) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('dosen');
      final now = DateTime.now();
      for (final row in rows) {
        final kode = row['kode']?.toString().trim() ?? '';
        if (kode.isEmpty) continue;
        await coll.replaceOne(
          where.eq('_id', kode),
          {
            '_id': kode,
            'kode': kode,
            'nama': row['nama']?.toString().trim() ?? '',
            'email': row['email']?.toString().trim() ?? '',
            'password': row['password']?.toString().trim() ?? 'pass123',
            'createdAt': now,
            'updatedAt': now,
          },
          upsert: true,
        );
      }
    });
  }

  /// Tambah wali dosen baru ke koleksi `wali_dosen`.
  /// [id] digunakan sebagai `_id` (format bebas, misal WD_<kode>_<kelas>).
  Future<void> insertWaliDosen({
    required String id,
    required String nama,
    required String email,
    required String password,
    required String kelasWali,
    required String program,
    String? dosenKode,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('wali_dosen');
      final existing = await coll.findOne(where.eq('_id', id));
      if (existing != null) {
        throw Exception('ID wali dosen $id sudah terdaftar.');
      }
      await coll.insertOne({
        '_id': id,
        'nama': nama,
        'email': email,
        'password': password,
        'kelasWali': kelasWali,
        'program': program,
        if (dosenKode != null) 'dosenKode': dosenKode,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    });
  }

  /// Update data wali dosen berdasarkan _id.
  Future<void> updateWaliDosen({
    required String id,
    required String nama,
    required String email,
    String? password,
    required String kelasWali,
    required String program,
    String? dosenKode,
  }) async {
    return _withReconnect(() async {
      final coll = _requireDb.collection('wali_dosen');
      final mods = modify
          .set('nama', nama)
          .set('email', email)
          .set('kelasWali', kelasWali)
          .set('program', program)
          .set('updatedAt', DateTime.now());
      if (password != null && password.isNotEmpty) {
        mods.set('password', password);
      }
      if (dosenKode != null) {
        mods.set('dosenKode', dosenKode);
      }
      await coll.updateOne(where.eq('_id', id), mods);
    });
  }

  /// Promosikan semua mahasiswa dari [kelasLama] ke [kelasBaru].
  /// Juga update semester jika [semesterBaru] diberikan.
  /// Update juga wali_dosen yang kelasWali-nya sama.
  /// Auto-enroll mahasiswa ke jadwal kelas baru di periode aktif.
  /// Return jumlah mahasiswa, wali, dan enrollment yang di-update/dibuat.
  Future<Map<String, int>> promosikanKelas({
    required String kelasLama,
    required String programFilter,
    required String kelasBaru,
    int? semesterBaru,
  }) async {
    return _withReconnect(() async {
      final mhsColl = _requireDb.collection('mahasiswa');
      final waliColl = _requireDb.collection('wali_dosen');
      final enrollColl = _requireDb.collection('enrollments');
      final jadwalColl = _requireDb.collection('jadwal_kuliah');

      // 1. Update semua mahasiswa di kelas lama + program
      final selector = <String, dynamic>{'kelas': kelasLama};
      if (programFilter.isNotEmpty) {
        selector['program'] = programFilter;
      }

      final mhsList = await mhsColl.find(selector).toList();
      int updatedMhs = 0;

      for (final mhs in mhsList) {
        final mods = modify
            .set('kelas', kelasBaru)
            .set('updatedAt', DateTime.now());
        if (semesterBaru != null) {
          mods.set('semester', semesterBaru);
        }
        await mhsColl.update(where.id(mhs['_id']), mods);
        updatedMhs++;
      }

      // 2. Update wali_dosen yang kelasWali == kelasLama
      final waliSelector = <String, dynamic>{'kelasWali': kelasLama};
      if (programFilter.isNotEmpty) {
        waliSelector['program'] = programFilter;
      }
      final waliList = await waliColl.find(waliSelector).toList();
      int updatedWali = 0;

      for (final wali in waliList) {
        await waliColl.update(
          where.id(wali['_id']),
          modify.set('kelasWali', kelasBaru).set('updatedAt', DateTime.now()),
        );
        updatedWali++;
      }

      // 3. Auto-enroll ke jadwal kelas baru di periode aktif
      int createdEnrollments = 0;
      final periode = await _getActivePeriodeRaw();
      final periodeKode = periode?['kode'] as String?;

      if (periodeKode != null) {
        // Cari semua jadwal yang cocok dengan kelas baru + program di periode aktif
        final jadwalSelector = <String, dynamic>{
          'kelas': kelasBaru,
          'isActive': true,
        };
        if (programFilter.isNotEmpty) {
          jadwalSelector['program'] = programFilter;
        }
        // Filter periode: match persis ATAU null/missing
        final jadwalList = await jadwalColl
            .find(_withPeriodeFilter(jadwalSelector, periodeKode))
            .toList();

        print(
          '[promosikanKelas] Found ${jadwalList.length} jadwal for $kelasBaru-$programFilter in periode $periodeKode',
        );

        if (jadwalList.isNotEmpty) {
          for (final mhs in mhsList) {
            final mhsId = mhs['_id'].toString();
            for (final jadwal in jadwalList) {
              final jadwalId = jadwal['_id'].toString();
              final enrollId = '${periodeKode}_${mhsId}_$jadwalId';

              // Cek apakah enrollment sudah ada (hindari duplikat)
              final existing = await enrollColl.findOne(
                where.eq('_id', enrollId),
              );
              if (existing == null) {
                await enrollColl.insertOne({
                  '_id': enrollId,
                  'mahasiswaId': mhsId,
                  'jadwalId': jadwalId,
                  'periodeAkademikKode': periodeKode,
                  'status': 'aktif',
                  'createdAt': DateTime.now(),
                  'updatedAt': DateTime.now(),
                });
                createdEnrollments++;
              }
            }
          }
        }
      }

      print(
        '[promosikanKelas] Updated: $updatedMhs mhs, $updatedWali wali, $createdEnrollments enrollments',
      );

      return {
        'mahasiswa': updatedMhs,
        'waliDosen': updatedWali,
        'enrollments': createdEnrollments,
      };
    });
  }
}
