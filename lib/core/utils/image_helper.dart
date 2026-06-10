import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Hasil pick foto: berisi base64 untuk dikirim ke server, plus path lokal
/// untuk preview UI sebelum sync.
class PickedPhoto {
  /// Base64-encoded JPEG (tanpa prefix `data:image/...`).
  final String base64;

  /// Path lokal file asli di device (untuk preview).
  final String localPath;

  /// Ukuran final base64 dalam bytes — buat estimasi BSON size.
  final int sizeBytes;

  const PickedPhoto({
    required this.base64,
    required this.localPath,
    required this.sizeBytes,
  });
}

/// Helper untuk pick gambar dari device, resize, dan encode ke base64.
///
/// Strategi resize:
/// - Max dimension 800px (proporsional). Foto kamera HP biasa ~3000-4000px,
///   jadi penurunan signifikan.
/// - JPEG quality 75 — masih readable, ukuran 50-150KB per foto.
/// - Tujuan: BSON document izin tetap < 1MB walau ada foto.
class ImageHelper {
  static const int _maxDimension = 800;
  static const int _jpegQuality = 75;
  static const int _maxBase64Bytes = 800 * 1024; // 800KB hard cap

  /// Pick satu gambar dari device, resize, encode base64.
  /// Return null kalau user cancel atau ada error.
  static Future<PickedPhoto?> pickAndCompress() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false, // kita baca via path supaya tidak load ke memory dua kali
      );
      if (result == null || result.files.isEmpty) return null;

      final picked = result.files.first;
      final path = picked.path;
      if (path == null) {
        debugPrint('[ImageHelper] picker tidak return path');
        return null;
      }

      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        debugPrint('[ImageHelper] gagal decode gambar');
        return null;
      }

      // Resize proporsional: sisi terpanjang jadi _maxDimension.
      final w = decoded.width;
      final h = decoded.height;
      img.Image resized;
      if (w <= _maxDimension && h <= _maxDimension) {
        resized = decoded;
      } else if (w >= h) {
        resized = img.copyResize(decoded, width: _maxDimension);
      } else {
        resized = img.copyResize(decoded, height: _maxDimension);
      }

      // Encode JPEG.
      final jpegBytes = img.encodeJpg(resized, quality: _jpegQuality);
      final encoded = base64Encode(jpegBytes);

      if (encoded.length > _maxBase64Bytes) {
        debugPrint(
          '[ImageHelper] foto terlalu besar bahkan setelah resize: '
          '${encoded.length} bytes',
        );
        // Tetap return — biar user lihat preview, tapi caller bisa warning.
      }

      return PickedPhoto(
        base64: encoded,
        localPath: path,
        sizeBytes: encoded.length,
      );
    } catch (e, st) {
      debugPrint('[ImageHelper] pickAndCompress error: $e\n$st');
      return null;
    }
  }
}
