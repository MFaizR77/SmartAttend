import '../local/models/sesi_absensi.dart';
import '../remote/models/sesi_absensi_model.dart';

class SesiAbsensiMapper {
static SesiAbsensiModel hiveToMongo(SesiAbsensi hive) {
    return SesiAbsensiModel(
      sesiId: hive.sesiId,
      jadwalId: hive.jadwalId,
      tanggal: hive.tanggal,
      status: hive.status,
      openedBy: hive.dibukaOleh,
      openedAt: hive.openedAt,
      closedAt: hive.closedAt,
      syncStatus: hive.syncStatus,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }

  static SesiAbsensi mongoToHive(SesiAbsensiModel mongo) {
    return SesiAbsensi(
      id: mongo.id?.toHexString(),
      sesiId: mongo.sesiId,
      jadwalId: mongo.jadwalId,
      tanggal: mongo.tanggal,
      status: mongo.status,
      openedBy: mongo.openedBy,
      openedAt: mongo.openedAt,
      closedAt: mongo.closedAt,
      syncStatus: mongo.syncStatus,
      createdAt: mongo.createdAt,
      updatedAt: mongo.updatedAt,
    );
  }
}