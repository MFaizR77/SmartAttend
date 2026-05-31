import 'package:hive_flutter/hive_flutter.dart';
import 'models/record_presensi.dart';
import 'models/sesi_absensi.dart';
import 'models/pengajuan_izin.dart';
import 'models/laporan_dosen.dart';
import 'models/jadwal_kuliah.dart';

class HiveHelper {
  static const String recordPresensiBox = 'record_presensi';
  static const String sesiAbsensiBox = 'sesi_absensi';
  static const String pengajuanIzinBox = 'pengajuan_izin';
  static const String laporanDosenBox = 'laporan_dosen';
  static const String jadwalKuliahBox = 'jadwal_kuliah';
  static const String jadwalKuliahTypedBox = 'jadwal_kuliah_typed';
  static const String enrollmentsBox = 'enrollments';
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
    Hive.registerAdapter(LaporanDosenAdapter());
    Hive.registerAdapter(JadwalKuliahAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<RecordPresensi>(recordPresensiBox);
    await Hive.openBox<SesiAbsensi>(sesiAbsensiBox);
    await Hive.openBox<PengajuanIzin>(pengajuanIzinBox);
    await Hive.openBox<LaporanDosen>(laporanDosenBox);
    await Hive.openBox<JadwalKuliah>(jadwalKuliahTypedBox);
    // Box generic untuk cache JSON-string lama (dipertahankan sementara
    // agar tidak break kode yang masih pakai). Akan di-deprecate.
    await Hive.openBox(jadwalKuliahBox);
    // Box enrollments: key = NIM mahasiswa, value = Map dengan key
    // 'jadwalIds' (List<String>) + 'cachedAt' (ISO string).
    await Hive.openBox(enrollmentsBox);
    await Hive.openBox(userBox);
  }

  static Box<RecordPresensi> get recordPresensiBoxInstance =>
      Hive.box<RecordPresensi>(recordPresensiBox);

  static Box<SesiAbsensi> get sesiAbsensiBoxInstance =>
      Hive.box<SesiAbsensi>(sesiAbsensiBox);

  static Box<PengajuanIzin> get pengajuanIzinBoxInstance =>
      Hive.box<PengajuanIzin>(pengajuanIzinBox);

  static Box<LaporanDosen> get laporanDosenBoxInstance =>
      Hive.box<LaporanDosen>(laporanDosenBox);

  static Box<JadwalKuliah> get jadwalKuliahTypedBoxInstance =>
      Hive.box<JadwalKuliah>(jadwalKuliahTypedBox);

  /// Box generic legacy (cache JSON-string per kelas+hari).
  /// Pakai [jadwalKuliahTypedBoxInstance] untuk write baru.
  static Box get jadwalKuliahBoxInstance => Hive.box(jadwalKuliahBox);

  static Box get enrollmentsBoxInstance => Hive.box(enrollmentsBox);

  static Box get userBoxInstance => Hive.box(userBox);
}
