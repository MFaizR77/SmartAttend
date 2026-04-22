import 'package:mongo_dart/mongo_dart.dart';

class RecordPresensiModel {
  final ObjectId? id;
  final String clientUuid;
  final String sesiId;
  final String mahasiswaId;
  final DateTime timestamp;
  final bool statusHadir;
  final String metode;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecordPresensiModel({
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

  factory RecordPresensiModel.fromMap(Map<String, dynamic> map) {
    return RecordPresensiModel(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
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

  RecordPresensiModel markAsSynced() {
    return RecordPresensiModel(
      id: id, clientUuid: clientUuid, sesiId: sesiId,
      mahasiswaId: mahasiswaId, timestamp: timestamp,
      statusHadir: statusHadir, metode: metode,
      syncStatus: 'synced',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  RecordPresensiModel markAsConflict() {
    return RecordPresensiModel(
      id: id, clientUuid: clientUuid, sesiId: sesiId,
      mahasiswaId: mahasiswaId, timestamp: timestamp,
      statusHadir: statusHadir, metode: metode,
      syncStatus: 'conflict',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}