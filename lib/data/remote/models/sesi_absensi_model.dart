import 'package:mongo_dart/mongo_dart.dart';

class SesiAbsensiModel {
  final ObjectId? id;
  final String sesiId;
  final String jadwalId;
  final DateTime tanggal;
  final String status;
  final String? openedBy;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  SesiAbsensiModel({
    this.id,
    required this.sesiId,
    required this.jadwalId,
    required this.tanggal,
    required this.status,
    this.openedBy,
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
      'openedBy': openedBy,
      'openedAt': openedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SesiAbsensiModel.fromMap(Map<String, dynamic> map) {
    return SesiAbsensiModel(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
      sesiId: map['sesiId'] ?? '',
      jadwalId: map['jadwalId'] ?? '',
      tanggal: map['tanggal'] != null 
          ? DateTime.parse(map['tanggal']) 
          : DateTime.now(),
      status: map['status'] ?? 'closed',
      openedBy: map['openedBy'],
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

  SesiAbsensiModel open(String oleh) {
    return SesiAbsensiModel(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'open', openedBy: oleh, openedAt: DateTime.now(),
      closedAt: null, syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensiModel close() {
    return SesiAbsensiModel(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'closed', openedBy: openedBy, openedAt: openedAt,
      closedAt: DateTime.now(), syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensiModel autoOpen() {
    return SesiAbsensiModel(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: 'auto', openedBy: 'system', openedAt: DateTime.now(),
      closedAt: null, syncStatus: 'pending',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  SesiAbsensiModel markAsSynced() {
    return SesiAbsensiModel(
      id: id, sesiId: sesiId, jadwalId: jadwalId, tanggal: tanggal,
      status: status, openedBy: openedBy, openedAt: openedAt,
      closedAt: closedAt, syncStatus: 'synced',
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}