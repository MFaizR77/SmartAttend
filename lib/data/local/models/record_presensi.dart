import 'package:hive/hive.dart';

part 'record_presensi.g.dart';

@HiveType(typeId: 0)
class RecordPresensi extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String clientUuid;

  @HiveField(2)
  final String sesiId;

  @HiveField(3)
  final String mahasiswaId;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final bool statusHadir;

  @HiveField(6)
  final String metode;

  @HiveField(7)
  final String syncStatus;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  RecordPresensi({
    this.id,
    required this.clientUuid,
    required this.sesiId,
    required this.mahasiswaId,
    required this.timestamp,
    required this.statusHadir,
    required this.metode,
    this.syncStatus = 'pending',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'clientUuid': clientUuid,
      'sesiId': sesiId,
      'mahasiswaId': mahasiswaId,
      'timestamp': timestamp.toIso8601String(),
      'statusHadir': statusHadir,
      'metode': metode,
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RecordPresensi.fromMap(Map<String, dynamic> map) {
    return RecordPresensi(
      id: map['_id']?.toString(),
      clientUuid: map['clientUuid'] ?? '',
      sesiId: map['sesiId'] ?? '',
      mahasiswaId: map['mahasiswaId'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
      statusHadir: map['statusHadir'] ?? true,
      metode: map['metode'] ?? 'manual',
      syncStatus: map['syncStatus'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  RecordPresensi markAsSynced() {
    return RecordPresensi(
      id: id, clientUuid: clientUuid, sesiId: sesiId,
      mahasiswaId: mahasiswaId, timestamp: timestamp,
      statusHadir: statusHadir, metode: metode,
      syncStatus: 'synced',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  RecordPresensi markAsConflict() {
    return RecordPresensi(
      id: id, clientUuid: clientUuid, sesiId: sesiId,
      mahasiswaId: mahasiswaId, timestamp: timestamp,
      statusHadir: statusHadir, metode: metode,
      syncStatus: 'conflict',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}