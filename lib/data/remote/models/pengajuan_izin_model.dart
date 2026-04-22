import 'package:mongo_dart/mongo_dart.dart';

class IzinModel {
  final ObjectId? id;
  final String clientUuid;
  final String mahasiswaId;
  final String sesiId;
  final String jenis;
  final String keterangan;
  final String? fotoPath;
  final String? fotoUrl;
  final String statusApproval;
  final String? catatanDosen;
  final String? disetujuiOleh;
  final DateTime? disetujuiPada;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  IzinModel({
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

  factory IzinModel.fromMap(Map<String, dynamic> map) {
    return IzinModel(
      id: map['_id'] is ObjectId ? map['_id'] as ObjectId : null,
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

  IzinModel approve(String oleh, String? catatan) {
    return IzinModel(
      id: id, clientUuid: clientUuid, mahasiswaId: mahasiswaId,
      sesiId: sesiId, jenis: jenis, keterangan: keterangan,
      fotoPath: fotoPath, fotoUrl: fotoUrl,
      statusApproval: 'approved', catatanDosen: catatan,
      disetujuiOleh: oleh, disetujuiPada: DateTime.now(),
      syncStatus: 'pending', createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  IzinModel reject(String oleh, String? catatan) {
    return IzinModel(
      id: id, clientUuid: clientUuid, mahasiswaId: mahasiswaId,
      sesiId: sesiId, jenis: jenis, keterangan: keterangan,
      fotoPath: fotoPath, fotoUrl: fotoUrl,
      statusApproval: 'rejected', catatanDosen: catatan,
      disetujuiOleh: oleh, disetujuiPada: DateTime.now(),
      syncStatus: 'pending', createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  IzinModel markAsSynced() {
    return IzinModel(
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