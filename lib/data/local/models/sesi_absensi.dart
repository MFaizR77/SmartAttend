import 'package:hive/hive.dart';

part 'sesi_absensi.g.dart';

@HiveType(typeId: 1)
class SesiAbsensi extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String sesiId;

  @HiveField(2)
  final String jadwalId;

  @HiveField(3)
  final DateTime tanggal;

  @HiveField(4)
  final String status;

  @HiveField(5)
  final String? dibukaOleh;

  @HiveField(6)
  final DateTime? openedAt;

  @HiveField(7)
  final DateTime? closedAt;

  @HiveField(8)
  final String syncStatus;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  SesiAbsensi({
    this.id,
    required this.sesiId,
    required this.jadwalId,
    required this.tanggal,
    required this.status,
    this.dibukaOleh,
    this.openedAt,
    this.closedAt,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'sesiId': sesiId,
      'jadwalId': jadwalId,
      'tanggal': tanggal.toIso8601String(),
      'status': status,
      'dibukaOleh': dibukaOleh,
      'openedAt': openedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SesiAbsensi.fromMap(Map<String, dynamic> map) {
    return SesiAbsensi(
      id: map['_id']?.toString(),
      sesiId: map['sesiId'] ?? '',
      jadwalId: map['jadwalId'] ?? '',
      tanggal: map['tanggal'] != null 
          ? DateTime.parse(map['tanggal']) 
          : DateTime.now(),
      status: map['status'] ?? 'closed',
      openedAt: map['openedAt'] != null 
          ? DateTime.parse(map['openedAt']) 
          : null,
      closedAt: map['closedAt'] != null 
          ? DateTime.parse(map['closedAt']) 
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

  bool get isOpen => status == 'open';

  SesiAbsensi open(String oleh) {
    return SesiAbsensi(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'open', dibukaOleh: oleh, openedAt: DateTime.now(),
      closedAt: null, syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensi close() {
    return SesiAbsensi(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'closed', dibukaOleh: dibukaOleh, openedAt: openedAt,
      closedAt: DateTime.now(), syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensi autoOpen() {
    return SesiAbsensi(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'auto', dibukaOleh: 'system', openedAt: DateTime.now(),
      closedAt: null, syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensi markAsSynced() {
    return SesiAbsensi(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: status, dibukaOleh: dibukaOleh, openedAt: openedAt,
      closedAt: closedAt, syncStatus: 'synced',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}