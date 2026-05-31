/// Utility untuk "memecah" jadwal team teaching menjadi beberapa kartu —
/// satu kartu per dosen — KHUSUS untuk tampilan (display-only).
///
/// **Penting**: ini murni kosmetik. Semua kartu hasil expand tetap berbagi
/// `_id`/`jadwalId` yang sama, sehingga:
/// - Absen tetap 1x (record_presensi pakai sesiId = jadwalId yang sama).
/// - Buka sesi 1 dosen = sesi terbuka untuk semua kartu.
///
/// Hanya mata kuliah **Proyek** yang dipecah (sesuai kebiasaan akademik di
/// mana tiap pembimbing proyek tampil sebagai baris terpisah). Mata kuliah
/// lain dengan banyak dosen tetap 1 kartu dengan nama dosen digabung.
library;

/// Apakah jadwal ini tergolong mata kuliah "Proyek".
bool _isProyek(Map<String, dynamic> jadwal) {
  final namaMK = (jadwal['namaMK']?.toString() ?? '').toLowerCase();
  return namaMK.contains('proyek');
}

/// Ambil daftar kodeDosen dari sebuah jadwal (array `dosenIds`, fallback
/// ke field single).
List<String> _dosenIdsOf(Map<String, dynamic> jadwal) {
  final raw = jadwal['dosenIds'];
  if (raw is List) {
    final list = raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (list.isNotEmpty) return list;
  }
  final single = jadwal['kodeDosen']?.toString() ??
      jadwal['dosenId']?.toString() ??
      '';
  return single.isEmpty ? const [] : [single];
}

/// Ambil daftar nama dosen sejajar dengan `dosenIds`.
List<String> _namaDosenListOf(Map<String, dynamic> jadwal, int count) {
  final raw = jadwal['namaDosenList'];
  if (raw is List && raw.isNotEmpty) {
    return raw.map((e) => e?.toString() ?? '').toList();
  }
  // Fallback: split string namaDosen pakai ';'
  final gabung = jadwal['namaDosen']?.toString() ?? '';
  if (gabung.contains(';')) {
    return gabung.split(';').map((s) => s.trim()).toList();
  }
  // Tidak ada data nama per-dosen — kembalikan list kosong dengan panjang count.
  return List<String>.filled(count, gabung);
}

/// Pecah list jadwal: untuk tiap jadwal Proyek dengan >1 dosen, hasilkan
/// satu salinan per dosen. Jadwal lain dibiarkan apa adanya.
///
/// Setiap salinan:
/// - `kodeDosen` / `dosenId` / `dosenIds` → hanya 1 dosen.
/// - `namaDosen` / `namaDosenList` → hanya nama dosen tsb.
/// - `_dosenIndex` (int) & `_totalDosen` (int) → metadata untuk UI badge
///   (mis. "Dosen 1 dari 3").
/// - `_groupJadwalId` (String) → jadwalId asli, untuk key widget unik.
List<Map<String, dynamic>> expandTeamTeaching(
  List<Map<String, dynamic>> jadwalList,
) {
  final result = <Map<String, dynamic>>[];
  for (final j in jadwalList) {
    final dosenIds = _dosenIdsOf(j);

    if (_isProyek(j) && dosenIds.length > 1) {
      final namaList = _namaDosenListOf(j, dosenIds.length);
      for (var i = 0; i < dosenIds.length; i++) {
        final nama = i < namaList.length && namaList[i].isNotEmpty
            ? namaList[i]
            : dosenIds[i];
        final clone = Map<String, dynamic>.from(j);
        clone['kodeDosen'] = dosenIds[i];
        clone['dosenId'] = dosenIds[i];
        clone['dosenIds'] = [dosenIds[i]];
        clone['namaDosen'] = nama;
        clone['namaDosenList'] = [nama];
        clone['_dosenIndex'] = i;
        clone['_totalDosen'] = dosenIds.length;
        clone['_groupJadwalId'] = j['_id']?.toString() ?? j['jadwalId']?.toString() ?? '';
        result.add(clone);
      }
    } else {
      result.add(j);
    }
  }
  return result;
}
