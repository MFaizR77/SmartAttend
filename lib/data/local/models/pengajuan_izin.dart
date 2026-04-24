import 'package:hive/hive.dart';

part 'pengajuan_izin.g.dart';

@HiveType(typeId: 2)
class PengajuanIzin extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String clientUuid;

  @HiveField(2)
  final String mahasiswaId;

  @HiveField(3)
  final String sesiId;

  @HiveField(4)
  final String jenis;

  @HiveField(5)
  final String keterangan;

  @HiveField(6)
  final String? fotoPath;

  @HiveField(7)
  final String? fotoUrl;

  @HiveField(8)
  final String statusApproval;

  @HiveField(9)
  final String? catatanDosen;

  @HiveField(10)
  final String? disetujuiOleh;

  @HiveField(11)
  final DateTime? disetujuiPada;

  @HiveField(12)
  final String syncStatus;

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  PengajuanIzin({
    this.id,
    required this.clientUuid,
    required this.mahasiswaId,
    required this.sesiId,
    required this.jenis,
    required this.keterangan,
    this.fotoPath,
    this.fotoUrl,
    this.statusApproval = 'pending',
    this.catatanDosen,
    this.disetujuiOleh,
    this.disetujuiPada,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'clientUuid': clientUuid,
      'mahasiswaId': mahasiswaId,
      'sesiId': sesiId,
      'jenis': jenis,
      'keterangan': keterangan,
      'fotoPath': fotoPath,
      'fotoUrl': fotoUrl,
      'statusApproval': statusApproval,
      'catatanDosen': catatanDosen,
      'disetujuiOleh': disetujuiOleh,
      'disetujuiPada': disetujuiPada?.toIso8601String(),
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PengajuanIzin.fromMap(Map<String, dynamic> map) {
    return PengajuanIzin(
      id: map['_id']?.toString(),
      clientUuid: map['clientUuid'] ?? '',
      mahasiswaId: map['mahasiswaId'] ?? '',
      sesiId: map['sesiId'] ?? '',
      jenis: map['jenis'] ?? 'izin',
      keterangan: map['keterangan'] ?? '',
      fotoPath: map['fotoPath'],
      fotoUrl: map['fotoUrl'],
      statusApproval: map['statusApproval'] ?? 'pending',
      catatanDosen: map['catatanDosen'],
      disetujuiOleh: map['disetujuiOleh'],
      disetujuiPada: map['disetujuiPada'] != null 
          ? DateTime.parse(map['disetujuiPada']) 
          : null,
      syncStatus: map['syncStatus'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  PengajuanIzin approve(String oleh, String? catatan) {
    return PengajuanIzin(
      id: id, clientUuid: clientUuid, mahasiswaId: mahasiswaId,
      sesiId: sesiId, jenis: jenis, keterangan: keterangan,
      fotoPath: fotoPath, fotoUrl: fotoUrl,
      statusApproval: 'approved', catatanDosen: catatan,
      disetujuiOleh: oleh, disetujuiPada: DateTime.now(),
      syncStatus: 'pending', createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  PengajuanIzin reject(String oleh, String? catatan) {
    return PengajuanIzin(
      id: id, clientUuid: clientUuid, mahasiswaId: mahasiswaId,
      sesiId: sesiId, jenis: jenis, keterangan: keterangan,
      fotoPath: fotoPath, fotoUrl: fotoUrl,
      statusApproval: 'rejected', catatanDosen: catatan,
      disetujuiOleh: oleh, disetujuiPada: DateTime.now(),
      syncStatus: 'pending', createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  PengajuanIzin markAsSynced() {
    return PengajuanIzin(
      id: id, clientUuid: clientUuid, mahasiswaId: mahasiswaId,
      sesiId: sesiId, jenis: jenis, keterangan: keterangan,
      fotoPath: fotoPath, fotoUrl: fotoUrl,
      statusApproval: statusApproval, catatanDosen: catatanDosen,
      disetujuiOleh: disetujuiOleh, disetujuiPada: disetujuiPada,
      syncStatus: 'synced', createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}