import 'package:hive/hive.dart';
import 'models/record_presensi.dart';
import 'models/sesi_absensi.dart';
import 'models/pengajuan_izin.dart';

class HiveHelper {
  static const String recordPresensiBox = 'record_presensi';
  static const String sesiAbsensiBox = 'sesi_absensi';
  static const String pengajuanIzinBox = 'pengajuan_izin';
  static const String jadwalKuliahBox = 'jadwal_kuliah';
  static const String userBox = 'user';

  static Future<void> init() async {
    await Hive.initFlutter();
    registerAdapters();
    await openBoxes();
  }

  static void registerAdapters() {
    Hive.registerAdapter(RecordPresensiAdapter());
    Hive.registerAdapter(SesiAbsensiAdapter());
    Hive.registerAdapter(PengajuanIzinAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<RecordPresensi>(recordPresensiBox);
    await Hive.openBox<SesiAbsensi>(sesiAbsensiBox);
    await Hive.openBox<PengajuanIzin>(pengajuanIzinBox);
    await Hive.openBox(jadwalKuliahBox);
    await Hive.openBox(userBox);
  }

  static Box<RecordPresensi> get recordPresensiBoxInstance =>
      Hive.box<RecordPresensi>(recordPresensiBox);

  static Box<SesiAbsensi> get sesiAbsensiBoxInstance =>
      Hive.box<SesiAbsensi>(sesiAbsensiBox);

  static Box<PengajuanIzin> get pengajuanIzinBoxInstance =>
      Hive.box<PengajuanIzin>(pengajuanIzinBox);

  static Box get jadwalKuliahBoxInstance => Hive.box(jadwalKuliahBox);

  static Box get userBoxInstance => Hive.box(userBox);
}