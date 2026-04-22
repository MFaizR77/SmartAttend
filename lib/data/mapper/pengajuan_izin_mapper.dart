import '../local/models/pengajuan_izin.dart';
import '../remote/models/pengajuan_izin_model.dart';

class PengajuanIzinMapper {
  static IzinModel hiveToMongo(PengajuanIzin hive) {
    return IzinModel(
      clientUuid: hive.clientUuid,
      mahasiswaId: hive.mahasiswaId,
      sesiId: hive.sesiId,
      jenis: hive.jenis,
      keterangan: hive.keterangan,
      fotoPath: hive.fotoPath,
      fotoUrl: hive.fotoUrl,
      statusApproval: hive.statusApproval,
      catatanDosen: hive.catatanDosen,
      disetujuiOleh: hive.disetujuiOleh,
      disetujuiPada: hive.disetujuiPada,
      syncStatus: hive.syncStatus,
      createdAt: hive.createdAt,
      updatedAt: hive.updatedAt,
    );
  }

  static PengajuanIzin mongoToHive(IzinModel mongo) {
    return PengajuanIzin(
      id: mongo.id?.toHexString(),
      clientUuid: mongo.clientUuid,
      mahasiswaId: mongo.mahasiswaId,
      sesiId: mongo.sesiId,
      jenis: mongo.jenis,
      keterangan: mongo.keterangan,
      fotoPath: mongo.fotoPath,
      fotoUrl: mongo.fotoUrl,
      statusApproval: mongo.statusApproval,
      catatanDosen: mongo.catatanDosen,
      disetujuiOleh: mongo.disetujuiOleh,
      disetujuiPada: mongo.disetujuiPada,
      syncStatus: mongo.syncStatus,
      createdAt: mongo.createdAt,
      updatedAt: mongo.updatedAt,
    );
  }
}