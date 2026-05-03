import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'laporan_dosen.g.dart';

@HiveType(typeId: 3)
class LaporanDosen extends HiveObject {
  @HiveField(0)
  final String id; // local uuid

  @HiveField(1)
  final String jadwalId;

  @HiveField(2)
  final String dosenId;

  @HiveField(3)
  final String? materi;

  @HiveField(4)
  final DateTime waktuMulai;

  @HiveField(5)
  final DateTime? waktuSelesai;

  @HiveField(6)
  final String syncStatus; // 'pending' or 'synced'

  @HiveField(7)
  final DateTime tanggal;

  LaporanDosen({
    String? id,
    required this.jadwalId,
    required this.dosenId,
    this.materi,
    required this.waktuMulai,
    this.waktuSelesai,
    this.syncStatus = 'pending',
    DateTime? tanggal,
  })  : id = id ?? const Uuid().v4(),
        tanggal = tanggal ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'jadwalId': jadwalId,
      'dosenId': dosenId,
      'materi': materi,
      'waktuMulai': waktuMulai.toIso8601String(),
      'waktuSelesai': waktuSelesai?.toIso8601String(),
      'syncStatus': syncStatus,
      'tanggal': tanggal.toIso8601String(),
    };
  }

  factory LaporanDosen.fromMap(Map<String, dynamic> map) {
    return LaporanDosen(
      id: map['_id']?.toString(), // Jika dari MongoDB, gunakan objectId string
      jadwalId: map['jadwalId'] ?? '',
      dosenId: map['dosenId'] ?? '',
      materi: map['materi'],
      waktuMulai: map['waktuMulai'] != null
          ? DateTime.parse(map['waktuMulai'].toString())
          : DateTime.now(),
      waktuSelesai: map['waktuSelesai'] != null
          ? DateTime.parse(map['waktuSelesai'].toString())
          : null,
      syncStatus: map['syncStatus'] ?? 'synced',
      tanggal: map['tanggal'] != null
          ? DateTime.parse(map['tanggal'].toString())
          : DateTime.now(),
    );
  }

  LaporanDosen copyWith({
    String? id,
    String? jadwalId,
    String? dosenId,
    String? materi,
    DateTime? waktuMulai,
    DateTime? waktuSelesai,
    String? syncStatus,
    DateTime? tanggal,
  }) {
    return LaporanDosen(
      id: id ?? this.id,
      jadwalId: jadwalId ?? this.jadwalId,
      dosenId: dosenId ?? this.dosenId,
      materi: materi ?? this.materi,
      waktuMulai: waktuMulai ?? this.waktuMulai,
      waktuSelesai: waktuSelesai ?? this.waktuSelesai,
      syncStatus: syncStatus ?? this.syncStatus,
      tanggal: tanggal ?? this.tanggal,
    );
  }
}
