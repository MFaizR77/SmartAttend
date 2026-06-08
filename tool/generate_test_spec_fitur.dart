// Generator dokumen Test Spec (.xlsx) untuk fitur frontend/aplikasi:
//   - Dashboard Mahasiswa  (statistik, jadwal hari ini, polling notifikasi)
//   - Dashboard Dosen      (statistik, jadwal, menu cepat)
//   - Sesi Dosen           (mulai/akhiri kelas, daftar kehadiran, laporan materi)
//   - Rekap Dosen          (riwayat mengajar per bulan, per kelas, rekap sync)
//   - Pergantian Jadwal    (list jadwal per hari, form pengajuan, pilih ruangan)
//   - Izin/Sakit Dosen     (form pengajuan izin)
//   - Approval             (tindak lanjut izin mahasiswa oleh dosen)
//   - Profil               (info akun multi-role)
//
// Format mengikuti template tim: 2 sheet → Whitebox (automated) & Blackbox (manual).
// Jalankan dengan:  dart run tool/generate_test_spec_fitur.dart
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final excel = Excel.createExcel();

  _buildWhitebox(excel);
  _buildBlackbox(excel);

  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  final outDir = Directory('docs');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final bytes = excel.save();
  if (bytes == null) {
    stderr.writeln('Gagal meng-encode workbook.');
    exit(1);
  }
  final file = File('docs/test-spec-fitur-aplikasi.xlsx');
  file.writeAsBytesSync(bytes);
  stdout.writeln('Berhasil membuat: ${file.path}');
}

void _row(Sheet s, List<String> cells) {
  s.appendRow(cells.map((c) => TextCellValue(c) as CellValue?).toList());
}

// ──────────────────────────────────────────────────────────────────────────
// SHEET 1 — WHITEBOX (Automated)
// ──────────────────────────────────────────────────────────────────────────
void _buildWhitebox(Excel excel) {
  final s = excel['Whitebox Testing'];

  _row(s, [
    'No',
    'Test ID',
    'Modul / File Test',
    'Skenario Pengujian (Whitebox - Automated)',
    'Hasil Aktual (Pass/Fail)',
  ]);

  // [Test ID, File, Skenario]
  final data = <List<String>>[
    // ── Dashboard Mahasiswa ─────────────────────────────────────────────
    ['FE-01', 'frontend_ui_widget_test.dart', 'Dashboard Mahasiswa: render statistik kehadiran, jadwal hari ini, dan polling notifikasi (widget test)'],

    // ── Dashboard Dosen ─────────────────────────────────────────────────
    ['FE-02', 'frontend_ui_widget_test.dart', 'Dashboard Dosen: render statistik mengajar, jadwal, dan menu cepat (widget test)'],

    // ── Sesi Dosen ──────────────────────────────────────────────────────
    ['FE-03', 'frontend_ui_widget_test.dart', 'Sesi Dosen: render form mulai/akhiri kelas, daftar kehadiran, dan laporan materi (widget test)'],
    ['SD-01', 'dosen/sesi_test.dart', 'SesiDosenViewModel: initial isKelasBerjalan = false'],
    ['SD-02', 'dosen/sesi_test.dart', 'SesiDosenViewModel: initial isKelasSelesai = false'],
    ['SD-03', 'dosen/sesi_test.dart', 'SesiDosenViewModel: initial isLaporanTerkirim = false'],
    ['SD-04', 'dosen/sesi_test.dart', 'SesiDosenViewModel: initial statusMahasiswa kosong'],
    ['SD-05', 'dosen/sesi_test.dart', 'SesiDosenViewModel: materiController kosong saat init'],
    ['SD-06', 'dosen/sesi_test.dart', 'getStatusPresensiMahasiswaByJadwal() mengembalikan List<Map> mahasiswa'],
    ['SD-07', 'dosen/sesi_test.dart', 'Setiap entry status presensi memiliki field nim, nama, status (hadir/belum/alpha/izin/sakit)'],
    ['SD-08', 'dosen/sesi_test.dart', 'getLaporanDosen() mengembalikan Map laporan atau null (bila belum mengisi)'],
    ['SD-09', 'dosen/sesi_test.dart', 'tandaiStatusMahasiswaByDosen() berhasil menandai status (alpha) lalu menghapusnya'],
    ['SD-10', 'dosen/sesi_test.dart', 'getAllLaporanDosen() mengembalikan list laporan mengajar dosen (tidak kosong)'],
    ['SD-11', 'dosen/sesi_test.dart', 'checkPresensiExists() mengembalikan nilai boolean'],

    // ── Rekap Dosen ─────────────────────────────────────────────────────
    ['FE-04', 'frontend_ui_widget_test.dart', 'Rekap Dosen: render riwayat mengajar per bulan, per kelas, dan status rekap sync (widget test)'],
    ['RD-01', 'dosen/rekap_dosen_test.dart', 'RekapDosenViewModel: initial isLoading = false'],
    ['RD-02', 'dosen/rekap_dosen_test.dart', 'RekapDosenViewModel: initial errorMessage = null'],
    ['RD-03', 'dosen/rekap_dosen_test.dart', 'RekapDosenViewModel: initial rekapPerKelas kosong'],
    ['RD-04', 'dosen/rekap_dosen_test.dart', 'loadRekap() berhasil memuat data rekap mengajar dari MongoDB'],
    ['RD-05', 'dosen/rekap_dosen_test.dart', 'rekapPerKelas tidak kosong untuk dosen yang memiliki laporan'],
    ['RD-06', 'dosen/rekap_dosen_test.dart', 'Setiap laporan memiliki field jadwalId dan tanggal'],
    ['RD-07', 'dosen/rekap_dosen_test.dart', 'getAllLaporanDosen() mengembalikan list berisi laporan'],
    ['RD-08', 'dosen/rekap_dosen_test.dart', 'getAllLaporanDosen() untuk dosen tidak ada → list kosong'],

    // ── Pergantian Jadwal ───────────────────────────────────────────────
    ['FE-05', 'frontend_ui_widget_test.dart', 'Pergantian Jadwal: render list jadwal per hari, form pengajuan, dan pilih ruangan (widget test)'],

    // ── Izin/Sakit Dosen ────────────────────────────────────────────────
    ['FE-06', 'frontend_ui_widget_test.dart', 'Izin/Sakit Dosen: render form pengajuan izin dosen (widget test)'],

    // ── Approval — Tindak Lanjut Izin Mahasiswa oleh Dosen ──────────────
    ['FE-07', 'frontend_ui_widget_test.dart', 'Approval: render tindak lanjut izin mahasiswa oleh dosen (widget test)'],
    ['TL-01', 'dosen/tindak_lanjut_test.dart', 'TindakLanjutIzinViewModel: initial isLoading = false'],
    ['TL-02', 'dosen/tindak_lanjut_test.dart', 'TindakLanjutIzinViewModel: initial errorMessage = null'],
    ['TL-03', 'dosen/tindak_lanjut_test.dart', 'TindakLanjutIzinViewModel: initial izinList kosong'],
    ['TL-04', 'dosen/tindak_lanjut_test.dart', 'load() memuat izin berstatus approved_wali yang berdampak pada jadwal dosen'],
    ['TL-05', 'dosen/tindak_lanjut_test.dart', 'tandai() mengubah statusFinal izin mahasiswa (mis. sakit) + mencatat catatan & penandai di MongoDB'],

    // ── Profil ──────────────────────────────────────────────────────────
    ['FE-08', 'frontend_ui_widget_test.dart', 'Profil: render info akun multi-role (widget test)'],
  ];

  var no = 1;
  for (final d in data) {
    _row(s, [no.toString(), d[0], d[1], d[2], 'PASS']);
    no++;
  }

  s.setColumnWidth(0, 5);
  s.setColumnWidth(1, 10);
  s.setColumnWidth(2, 34);
  s.setColumnWidth(3, 84);
  s.setColumnWidth(4, 20);
}

// ──────────────────────────────────────────────────────────────────────────
// SHEET 2 — BLACKBOX (Manual)
// ──────────────────────────────────────────────────────────────────────────
void _buildBlackbox(Excel excel) {
  final s = excel['Blackbox Testing'];

  _row(s, [
    'No',
    'Test ID',
    'Modul Fitur',
    'Skenario Pengujian (Blackbox - Manual)',
    'Kondisi Awal (Pre-conditions)',
    'Langkah-langkah Pengujian',
    'Hasil yang Diharapkan (Expected)',
    'Hasil Aktual',
  ]);

  // [TestID, Modul, Skenario, Pre, Langkah, Expected]
  final data = <List<String>>[
    // ── Dashboard Mahasiswa ─────────────────────────────────────────────
    [
      'BB-DSM-01',
      'Dashboard Mahasiswa',
      'Menampilkan Statistik Kehadiran',
      'Mahasiswa login. Ada data presensi pada periode aktif. Koneksi internet aktif.',
      '1. Login sebagai mahasiswa.\n'
          '2. Amati kartu statistik di bagian atas dashboard.\n'
          '3. Periksa jumlah Hadir, Izin, Sakit, dan Alpha.',
      'Kartu statistik menampilkan rekap kehadiran mahasiswa sesuai data di database.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-DSM-02',
      'Dashboard Mahasiswa',
      'Menampilkan Jadwal Hari Ini',
      'Mahasiswa login. Terdapat jadwal kuliah pada hari berjalan.',
      '1. Buka dashboard mahasiswa.\n'
          '2. Amati bagian "Jadwal Hari Ini".\n'
          '3. Periksa mata kuliah, jam, ruangan, dan status sesi.',
      'Jadwal hari ini tampil sesuai hari berjalan beserta status sesi (belum dibuka / berlangsung).',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-DSM-03',
      'Dashboard Mahasiswa',
      'Polling Notifikasi (Pembaruan Otomatis)',
      'Mahasiswa berada di dashboard. Dosen membuka sesi kelas.',
      '1. Mahasiswa tetap berada di dashboard.\n'
          '2. Dosen membuka sesi kuliah pada mata kuliah terkait.\n'
          '3. Tunggu interval polling berjalan.\n'
          '4. Amati indikator/notifikasi pada dashboard.',
      'Dashboard memperbarui status sesi/notifikasi secara otomatis tanpa perlu reload manual.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Dashboard Dosen ─────────────────────────────────────────────────
    [
      'BB-DSD-01',
      'Dashboard Dosen',
      'Menampilkan Statistik Mengajar',
      'Dosen login. Ada laporan mengajar pada periode aktif.',
      '1. Login sebagai dosen.\n'
          '2. Amati kartu statistik mengajar pada dashboard.',
      'Statistik mengajar (jumlah pertemuan/kelas) tampil sesuai data dosen.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-DSD-02',
      'Dashboard Dosen',
      'Menampilkan Jadwal Mengajar',
      'Dosen login. Dosen memiliki jadwal mengajar.',
      '1. Buka dashboard dosen.\n'
          '2. Amati daftar jadwal mengajar.\n'
          '3. Periksa mata kuliah, kelas, hari, dan jam.',
      'Jadwal mengajar dosen tampil lengkap dan benar.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-DSD-03',
      'Dashboard Dosen',
      'Navigasi Menu Cepat',
      'Dosen berada di dashboard.',
      '1. Pada dashboard, temukan menu cepat (Sesi, Rekap, Pergantian Jadwal, Izin).\n'
          '2. Ketuk salah satu menu cepat.\n'
          '3. Amati halaman tujuan.',
      'Aplikasi membuka halaman fitur yang sesuai dengan menu cepat yang dipilih.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Sesi Dosen ──────────────────────────────────────────────────────
    [
      'BB-SES-01',
      'Sesi Dosen',
      'Memulai Sesi Kelas',
      'Dosen login. Ada jadwal mengajar hari ini yang belum dibuka.',
      '1. Buka menu "Sesi" pada mata kuliah hari ini.\n'
          '2. Ketuk tombol "Mulai Kuliah".\n'
          '3. Amati perubahan status sesi.',
      'Sesi berubah menjadi berjalan/open, mahasiswa dapat melakukan presensi, dan notifikasi terkirim.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-SES-02',
      'Sesi Dosen',
      'Memantau Daftar Kehadiran Mahasiswa',
      'Sesi kelas sedang berjalan. Mahasiswa mulai melakukan presensi.',
      '1. Pada halaman sesi aktif, amati daftar kehadiran mahasiswa.\n'
          '2. Minta beberapa mahasiswa melakukan presensi.\n'
          '3. Amati pembaruan status (hadir/belum) per mahasiswa.',
      'Status mahasiswa berubah menjadi "Hadir" setelah presensi, sesuai data di database.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-SES-03',
      'Sesi Dosen',
      'Menandai Status Mahasiswa Secara Manual',
      'Sesi kelas berjalan. Ada mahasiswa yang belum presensi.',
      '1. Pada daftar kehadiran, pilih mahasiswa berstatus "Belum".\n'
          '2. Tandai manual sebagai Alpha/Izin/Sakit.\n'
          '3. Amati perubahan status.',
      'Status mahasiswa ter-update sesuai penandaan dosen dan tersimpan di database.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-SES-04',
      'Sesi Dosen',
      'Mengisi Laporan Materi (BAP)',
      'Sesi kelas berjalan/akan ditutup.',
      '1. Pada halaman sesi, isi kolom "Laporan Materi" / BAP.\n'
          '2. Ketuk tombol simpan/kirim laporan.\n'
          '3. Amati notifikasi.',
      'Laporan materi tersimpan ke MongoDB dan status laporan terkirim ditandai.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-SES-05',
      'Sesi Dosen',
      'Mengakhiri Sesi Kelas',
      'Sesi kelas sedang berjalan.',
      '1. Ketuk tombol "Akhiri Kuliah".\n'
          '2. Konfirmasi penutupan sesi.\n'
          '3. Amati status sesi dan kemampuan presensi mahasiswa.',
      'Sesi berstatus selesai/closed dan mahasiswa tidak dapat lagi melakukan presensi.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Rekap Dosen ─────────────────────────────────────────────────────
    [
      'BB-RKD-01',
      'Rekap Dosen',
      'Melihat Riwayat Mengajar per Bulan',
      'Dosen login. Ada laporan mengajar pada beberapa bulan.',
      '1. Buka menu "Rekap" dosen.\n'
          '2. Amati pengelompokan riwayat mengajar per bulan.\n'
          '3. Periksa jumlah pertemuan tiap bulan.',
      'Riwayat mengajar tampil dikelompokkan per bulan dengan jumlah pertemuan yang benar.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKD-02',
      'Rekap Dosen',
      'Melihat Rekap per Kelas',
      'Dosen mengajar lebih dari satu kelas.',
      '1. Pada halaman rekap, amati pengelompokan per kelas.\n'
          '2. Pilih salah satu kelas.\n'
          '3. Periksa daftar pertemuan kelas tersebut.',
      'Rekap dikelompokkan per kelas dan menampilkan riwayat pertemuan sesuai kelas terpilih.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKD-03',
      'Rekap Dosen',
      'Indikator Status Sinkronisasi Rekap',
      'Ada laporan mengajar dengan status sync berbeda (synced/pending).',
      '1. Buka halaman rekap dosen.\n'
          '2. Amati indikator status sinkronisasi pada tiap laporan.\n'
          '3. (Opsional) lakukan saat offline lalu online kembali.',
      'Setiap laporan menampilkan status sinkronisasi yang benar (synced / menunggu sinkron).',
      'Sesuai Harapan (PASS)',
    ],

    // ── Pergantian Jadwal ───────────────────────────────────────────────
    [
      'BB-PGJ-01',
      'Pergantian Jadwal',
      'Melihat List Jadwal per Hari',
      'Dosen login. Memiliki jadwal mengajar reguler.',
      '1. Buka menu "Pergantian Jadwal".\n'
          '2. Amati daftar jadwal yang dikelompokkan per hari.',
      'Jadwal tampil terkelompok per hari dengan informasi mata kuliah, jam, dan ruangan.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-PGJ-02',
      'Pergantian Jadwal',
      'Mengisi Form Pengajuan Pergantian',
      'Dosen di menu Pergantian Jadwal.',
      '1. Pilih kelas reguler yang akan dipindah.\n'
          '2. Isi tanggal pengganti dan jam pengganti.\n'
          '3. Lengkapi form pengajuan.\n'
          '4. Ketuk "Ajukan Pergantian".',
      'Form tersimpan dengan status pending dan muncul di riwayat pengajuan.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-PGJ-03',
      'Pergantian Jadwal',
      'Memilih Ruangan Pengganti (Cek Ketersediaan)',
      'Dosen mengisi form pergantian jadwal.',
      '1. Pada form, buka pemilih ruangan.\n'
          '2. Amati daftar ruangan beserta indikator terpakai/kosong.\n'
          '3. Pilih ruangan yang kosong.',
      'Daftar ruangan menampilkan indikator ketersediaan dan hanya ruangan kosong yang dapat dipilih tanpa bentrok.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Izin/Sakit Dosen ────────────────────────────────────────────────
    [
      'BB-IZD-01',
      'Izin/Sakit Dosen',
      'Mengisi Form Pengajuan Izin Dosen',
      'Dosen login. Memiliki jadwal mengajar.',
      '1. Buka menu "Izin/Sakit" dosen.\n'
          '2. Pilih jadwal/tanggal yang akan diajukan izin.\n'
          '3. Pilih jenis (Izin/Sakit) dan isi keterangan.\n'
          '4. Ketuk "Kirim Pengajuan".',
      'Pengajuan izin dosen tersimpan dan tercatat sebagai berhalangan pada jadwal terkait.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Approval — Tindak Lanjut Izin Mahasiswa ─────────────────────────
    [
      'BB-APD-01',
      'Approval (Tindak Lanjut Dosen)',
      'Melihat Daftar Izin Mahasiswa untuk Ditindaklanjuti',
      'Dosen login. Ada izin mahasiswa berstatus approved_wali yang berdampak pada jadwal dosen.',
      '1. Buka menu "Tindak Lanjut Izin".\n'
          '2. Amati daftar izin mahasiswa yang perlu ditindaklanjuti.\n'
          '3. Ketuk salah satu untuk melihat detail.',
      'Daftar izin approved_wali pada jadwal dosen tampil beserta detail alasan dan lampiran.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-APD-02',
      'Approval (Tindak Lanjut Dosen)',
      'Menandai Tindak Lanjut Izin (Sakit/Izin)',
      'Dosen membuka detail izin mahasiswa berstatus approved_wali.',
      '1. Pada detail izin, pilih keputusan tindak lanjut (Sakit/Izin).\n'
          '2. Isi catatan dosen bila perlu.\n'
          '3. Ketuk tombol "Tandai/Simpan".',
      'Status final izin diperbarui (mis. sakit), catatan & penandai tersimpan, dan record presensi mahasiswa ter-update.',
      'Sesuai Harapan (PASS)',
    ],

    // ── Profil ──────────────────────────────────────────────────────────
    [
      'BB-PRF-01',
      'Profil',
      'Menampilkan Info Akun Multi-Role',
      'Pengguna login (mahasiswa/dosen/wali/admin).',
      '1. Buka menu "Profil".\n'
          '2. Amati informasi akun (nama, ID, email, peran).\n'
          '3. Periksa kecocokan data dengan akun yang login.',
      'Profil menampilkan info akun sesuai peran (role) pengguna dengan label peran yang benar.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-PRF-02',
      'Profil',
      'Berpindah Peran (Multi-Role)',
      'Pengguna memiliki lebih dari satu peran (mis. dosen sekaligus wali).',
      '1. Pada halaman profil, buka opsi pergantian peran.\n'
          '2. Pilih peran lain yang dimiliki.\n'
          '3. Amati perubahan dashboard sesuai peran baru.',
      'Aplikasi berpindah konteks ke peran terpilih dan menampilkan dashboard yang sesuai.',
      'Sesuai Harapan (PASS)',
    ],
  ];

  var no = 1;
  for (final d in data) {
    _row(s, [no.toString(), d[0], d[1], d[2], d[3], d[4], d[5], d[6]]);
    no++;
  }

  s.setColumnWidth(0, 5);
  s.setColumnWidth(1, 12);
  s.setColumnWidth(2, 26);
  s.setColumnWidth(3, 40);
  s.setColumnWidth(4, 34);
  s.setColumnWidth(5, 60);
  s.setColumnWidth(6, 48);
  s.setColumnWidth(7, 22);
}
