import '../local/models/record_presensi.dart';
import '../remote/models/record_presensi_model.dart';

class RecordPresensiMapper {
  static RecordPresensiModel hiveToMongo(RecordPresensi hive) {
    return RecordPresensiModel(
      clientUuid: hive.clientUuid,
      sesiId: hive.sesiId,
      mahasiswaId: hive.mahasiswaId,
      timestamp: hive.timestamp,
      statusHadir: hive.statusHadir,
      metode: hive.metode,
      syncStatus: hive.syncStatus,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }

  static RecordPresensi mongoToHive(RecordPresensiModel mongo) {
    return RecordPresensi(
      id: mongo.id?.toHexString(),
      clientUuid: mongo.clientUuid,
      sesiId: mongo.sesiId,
      mahasiswaId: mongo.mahasiswaId,
      timestamp: mongo.timestamp,
      statusHadir: mongo.statusHadir,
      metode: mongo.metode,
      syncStatus: mongo.syncStatus,
      createdAt: mongo.createdAt,
      updatedAt: mongo.updatedAt,
    );
  }
}