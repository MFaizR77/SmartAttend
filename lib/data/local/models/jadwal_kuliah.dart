import 'package:hive/hive.dart';

part 'jadwal_kuliah.g.dart';

/// Cache lokal jadwal kuliah.
///
/// Diisi dari koleksi MongoDB `jadwal_kuliah` saat online, dipakai sebagai
/// fallback offline untuk dashboard, jadwal, dan presensi.
///
/// Bukan source of truth — selalu refresh dari Mongo saat online tersedia.
@HiveType(typeId: 4)
class JadwalKuliah extends HiveObject {
  @HiveField(0)
  final String id; // composite jadwalId

  @HiveField(1)
  final String kodeMK;

  @HiveField(2)
  final String namaMK;

  @HiveField(3)
  final String kelas;

  @HiveField(4)
  final String program;

  @HiveField(5)
  final String hari;

  @HiveField(6)
  final String jamMulai;

  @HiveField(7)
  final String jamSelesai;

  @HiveField(8)
  final String tipe; // TE | PR

  @HiveField(9)
  final String ruangan;

  @HiveField(10)
  final List<String> dosenIds;

  @HiveField(11)
  final String namaDosen; // string display, gabungan team teaching pakai ';'

  @HiveField(12)
  final String? periodeAkademikKode;

  @HiveField(13)
  final bool isActive;

  @HiveField(14)
  final DateTime cachedAt;

  JadwalKuliah({
    required this.id,
    required this.kodeMK,
    required this.namaMK,
    required this.kelas,
    required this.program,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.tipe,
    required this.ruangan,
    required this.dosenIds,
    required this.namaDosen,
    this.periodeAkademikKode,
    this.isActive = true,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Build dari dokumen Mongo.
  factory JadwalKuliah.fromMap(Map<dynamic, dynamic> map) {
    final dosenIdsRaw = map['dosenIds'];
    final dosenIds = <String>[];
    if (dosenIdsRaw is List) {
      for (final d in dosenIdsRaw) {
        final s = d?.toString() ?? '';
        if (s.isNotEmpty) dosenIds.add(s);
      }
    } else {
      // Fallback ke field single (back-compat schema lama)
      final single = map['kodeDosen']?.toString() ??
          map['dosenId']?.toString() ??
          '';
      if (single.isNotEmpty) dosenIds.add(single);
    }

    return JadwalKuliah(
      id: map['_id']?.toString() ?? map['jadwalId']?.toString() ?? '',
      kodeMK: map['kodeMK']?.toString() ?? '',
      namaMK: map['namaMK']?.toString() ?? '',
      kelas: map['kelas']?.toString() ?? '',
      program: map['program']?.toString() ?? '',
      hari: map['hari']?.toString() ?? '',
      jamMulai: map['jamMulai']?.toString() ?? '',
      jamSelesai: map['jamSelesai']?.toString() ?? '',
      tipe: map['tipe']?.toString() ?? '',
      ruangan: map['ruangan']?.toString() ??
          map['ruanganNama']?.toString() ??
          map['ruanganKode']?.toString() ??
          '',
      dosenIds: dosenIds,
      namaDosen: map['namaDosen']?.toString() ?? '',
      periodeAkademikKode: map['periodeAkademikKode']?.toString(),
      isActive: map['isActive'] != false, // default true kalau missing
    );
  }

  /// Kembali ke Map agar UI yang sudah expect format dokumen Mongo bisa
  /// dipakai apa adanya.
  Map<String, dynamic> toDisplayMap() {
    return {
      '_id': id,
      'jadwalId': id,
      'kodeMK': kodeMK,
      'namaMK': namaMK,
      'kelas': kelas,
      'program': program,
      'hari': hari,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'tipe': tipe,
      'ruangan': ruangan,
      'ruanganNama': ruangan,
      'dosenIds': dosenIds,
      'kodeDosen': dosenIds.isNotEmpty ? dosenIds.first : '',
      'dosenId': dosenIds.isNotEmpty ? dosenIds.first : '',
      'namaDosen': namaDosen,
      'periodeAkademikKode': periodeAkademikKode,
      'isActive': isActive,
    };
  }
}
