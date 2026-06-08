import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smartattend/data/remote/database_service.dart';

/// Setup koneksi MongoDB untuk integration test.
Future<void> setupTestDb() async {
  await dotenv.load(fileName: '.env');
  await DatabaseService().connect();
}

/// Tutup koneksi MongoDB setelah test selesai.
Future<void> teardownTestDb() async {
  await DatabaseService().close();
}

/// Generate ID unik untuk data test (prefix_test_TIMESTAMP).
String testId(String prefix) =>
    '${prefix}_test_${DateTime.now().millisecondsSinceEpoch}';

/// Hapus satu dokumen test dari collection berdasarkan field dan value.
/// HANYA dokumen yang field-nya cocok persis yang dihapus.
Future<void> cleanupByField(String collection, String field, dynamic value) async {
  try {
    await DatabaseService().db.collection(collection).remove(where.eq(field, value));
  } catch (_) {}
}

/// Hapus satu dokumen test dari collection berdasarkan _id.
Future<void> cleanupById(String collection, dynamic id) async {
  try {
    await DatabaseService().db.collection(collection).remove(where.id(id));
  } catch (_) {}
}

/// Hapus semua dokumen test dari collection berdasarkan pattern di field.
/// Contoh: cleanupByPattern('record_presensi', 'clientUuid', '_test_')
/// Akan hapus semua dokumen dimana clientUuid mengandung '_test_'.
Future<void> cleanupByPattern(String collection, String field, String pattern) async {
  try {
    await DatabaseService().db.collection(collection).remove(
      where.match(field, pattern),
    );
  } catch (_) {}
}
