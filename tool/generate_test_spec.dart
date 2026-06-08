// Generator dokumen Test Spec (.xlsx) untuk bagian:
//   - Manajemen Jadwal Admin
//   - Rekap Admin
//
// Format mengikuti template tim: 2 sheet → Whitebox (automated) & Blackbox (manual).
// Jalankan dengan:  dart run tool/generate_test_spec.dart
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final excel = Excel.createExcel();

  _buildWhitebox(excel);
  _buildBlackbox(excel);

  // Hapus sheet default kosong bila ada.
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
  final file = File('docs/test-spec-rekap-jadwal-admin.xlsx');
  file.writeAsBytesSync(bytes);
  stdout.writeln('Berhasil membuat: ${file.path}');
}

void _row(Sheet s, List<String> cells) {
  s.appendRow(cells.map((c) => TextCellValue(c) as CellValue?).toList());
}

// ──────────────────────────────────────────────────────────────────────────
// SHEET 1 — WHITEBOX (Automated) : memetakan test otomatis yang sudah lolos.
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
    // ── Manajemen Jadwal Admin ──────────────────────────────────────────
    ['MJ-01', 'admin/manajemen_jadwal_test.dart', 'DatabaseService menyediakan method getAllJadwalAdmin() (dapat diinstansiasi tanpa koneksi DB)'],
    ['MJ-02', 'admin/manajemen_jadwal_test.dart', 'DatabaseService menyediakan method deleteJadwal() (dapat diinstansiasi tanpa koneksi DB)'],
    ['MJ-03', 'admin/manajemen_jadwal_test.dart', 'DatabaseService menyediakan method updateJadwal() (dapat diinstansiasi tanpa koneksi DB)'],
    ['MJ-04', 'admin/manajemen_jadwal_test.dart', 'getAllJadwalAdmin() mengembalikan List<Map> jadwal dari MongoDB dan tidak kosong'],
    ['MJ-05', 'admin/manajemen_jadwal_test.dart', 'Setiap jadwal memiliki field wajib: _id, namaMK, hari, jamMulai, jamSelesai'],
    ['MJ-06', 'admin/manajemen_jadwal_test.dart', 'Jadwal acuan D3_2B_25IF2122_Senin_0700_PR tersedia di database'],
    ['MJ-07', 'admin/manajemen_jadwal_test.dart', 'Setiap jadwal memiliki info dosen (dosenId / kodeDosen / namaDosen)'],
    ['MJ-08', 'admin/manajemen_jadwal_test.dart', 'updateJadwal() berhasil mengubah field namaMK dan perubahan tersimpan di MongoDB'],
    ['MJ-09', 'admin/manajemen_jadwal_test.dart', 'updateJadwal() berhasil mengubah hari, jamMulai, dan jamSelesai'],
    ['MJ-10', 'admin/manajemen_jadwal_test.dart', 'deleteJadwal() menghapus jadwal dari MongoDB sehingga tidak muncul lagi di daftar'],

    // ── Rekap Admin — Unit ViewModel ────────────────────────────────────
    ['R-01', 'admin/rekap_test.dart', 'RekapAdminViewModel: initial state isLoading = false'],
    ['R-02', 'admin/rekap_test.dart', 'RekapAdminViewModel: initial daftarJadwal kosong'],
    ['R-03', 'admin/rekap_test.dart', 'RekapAdminViewModel: initial daftarRekap kosong'],
    ['R-04', 'admin/rekap_test.dart', 'RekapAdminViewModel: filterTipe default = "mahasiswa"'],
    ['R-05', 'admin/rekap_test.dart', 'setFilter("dosen") mengubah filterTipe menjadi "dosen"'],
    ['R-06', 'admin/rekap_test.dart', 'setFilter("mahasiswa") mengembalikan filterTipe ke "mahasiswa"'],
    ['R-07', 'admin/rekap_test.dart', 'setFilter() memanggil notifyListeners (UI ter-update)'],
    ['R-08', 'admin/rekap_test.dart', 'RekapAdminViewModel: initial selectedJadwal = null'],
    ['R-09', 'admin/rekap_test.dart', 'RekapAdminViewModel: initial errorMessage = null'],

    // ── Rekap Admin — Integrasi ViewModel ───────────────────────────────
    ['R-10', 'admin/rekap_test.dart', 'loadJadwal() berhasil memuat data jadwal dari MongoDB (isLoading=false, errorMessage=null)'],
    ['R-11', 'admin/rekap_test.dart', 'loadJadwal(): setiap jadwal memiliki field _id dan namaMK'],
    ['R-12', 'admin/rekap_test.dart', 'loadRekap() dengan filter mahasiswa berhasil memuat rekap dari MongoDB'],
    ['R-13', 'admin/rekap_test.dart', 'loadRekap() dengan filter dosen berhasil memuat rekap dari MongoDB'],
    ['R-14', 'admin/rekap_test.dart', 'loadRekap() mengisi selectedJadwal sesuai jadwalId yang dipilih'],

    // ── Rekap Admin — getRekapKehadiranAdmin (mahasiswa) ────────────────
    ['R-15', 'admin/rekap_test.dart', 'getRekapKehadiranAdmin() mengembalikan rekap mahasiswa (tidak kosong)'],
    ['R-16', 'admin/rekap_test.dart', 'Setiap entry rekap mahasiswa memiliki field wajib (mahasiswaId, nama, nim, hadir, izin, alpha, totalPertemuan, persenHadir) dengan tipe benar'],
    ['R-17', 'admin/rekap_test.dart', 'totalPertemuan dihitung dari laporan_dosen (bukan hardcode) dan konsisten untuk semua mahasiswa di satu jadwal'],
    ['R-18', 'admin/rekap_test.dart', 'Validasi penjumlahan: hadir + izin + alpha = totalPertemuan untuk setiap mahasiswa'],
    ['R-19', 'admin/rekap_test.dart', 'persenHadir akurat = (hadir / totalPertemuan) x 100'],
    ['R-20', 'admin/rekap_test.dart', 'Nilai hadir valid: tidak negatif dan tidak melebihi totalPertemuan'],

    // ── Rekap Admin — getRekapKehadiranDosen ────────────────────────────
    ['R-21', 'admin/rekap_test.dart', 'getRekapKehadiranDosen() mengembalikan rekap dosen (tidak kosong)'],
    ['R-22', 'admin/rekap_test.dart', 'Setiap entry rekap dosen memiliki field wajib (dosenId, nama, hadir, berhalangan, totalPertemuan, persenHadir, alasan) dengan tipe benar'],
    ['R-23', 'admin/rekap_test.dart', 'hadir dosen dihitung dari laporan_dosen (bukan hardcode) dan bernilai > 0'],
    ['R-24', 'admin/rekap_test.dart', 'Validasi penjumlahan: hadir + berhalangan = totalPertemuan untuk setiap dosen'],
    ['R-25', 'admin/rekap_test.dart', 'persenHadir dosen akurat = (hadir / totalPertemuan) x 100'],
    ['R-26', 'admin/rekap_test.dart', 'jadwalId tidak ada → rekap dosen mengembalikan list kosong'],
  ];

  var no = 1;
  for (final d in data) {
    _row(s, [no.toString(), d[0], d[1], d[2], 'PASS']);
    no++;
  }

  // Lebar kolom biar enak dibaca.
  s.setColumnWidth(0, 5);
  s.setColumnWidth(1, 10);
  s.setColumnWidth(2, 36);
  s.setColumnWidth(3, 80);
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
    [
      'BB-MJW-01',
      'Manajemen Jadwal Admin',
      'Melihat Daftar Jadwal Kuliah',
      'Admin login. Terdapat data jadwal di database. Koneksi internet aktif.',
      '1. Admin login menggunakan akun administrator.\n'
          '2. Buka menu "Manajemen Jadwal" dari dashboard admin.\n'
          '3. Tunggu indikator loading selesai.\n'
          '4. Amati daftar kartu jadwal yang ditampilkan.',
      'Seluruh jadwal tampil dalam bentuk kartu berisi nama mata kuliah, kelas, dosen, hari, jam, dan ruangan.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-02',
      'Manajemen Jadwal Admin',
      'Memuat Ulang Daftar Jadwal (Pull to Refresh)',
      'Admin berada di halaman Manajemen Jadwal dengan daftar jadwal tampil.',
      '1. Pada daftar jadwal, tarik layar dari atas ke bawah (pull to refresh).\n'
          '2. Amati indikator refresh muncul.\n'
          '3. Tunggu hingga data selesai dimuat ulang.',
      'Daftar jadwal dimuat ulang dari MongoDB dan menampilkan data terbaru tanpa error.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-03',
      'Manajemen Jadwal Admin',
      'Edit Jadwal (Nama MK, Hari, Jam, Ruangan)',
      'Admin di halaman Manajemen Jadwal. Minimal ada satu jadwal.',
      '1. Pilih salah satu kartu jadwal, ketuk ikon menu (titik tiga).\n'
          '2. Pilih opsi "Edit".\n'
          '3. Pada dialog, ubah Nama MK, Hari, Jam Mulai, Jam Selesai, dan Kode Ruangan.\n'
          '4. Ketuk tombol "Simpan".\n'
          '5. Amati notifikasi dan daftar jadwal.',
      'Muncul snackbar "Jadwal disimpan", data jadwal diperbarui di MongoDB, dan daftar menampilkan nilai baru.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-04',
      'Manajemen Jadwal Admin',
      'Batal Edit Jadwal',
      'Admin membuka dialog edit jadwal.',
      '1. Buka menu jadwal, pilih "Edit".\n'
          '2. Ubah salah satu field pada dialog edit.\n'
          '3. Ketuk tombol "Batal".\n'
          '4. Amati data jadwal pada daftar.',
      'Dialog tertutup tanpa menyimpan perubahan. Data jadwal tetap seperti semula.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-05',
      'Manajemen Jadwal Admin',
      'Hapus Jadwal dengan Konfirmasi',
      'Admin di halaman Manajemen Jadwal. Ada jadwal yang akan dihapus.',
      '1. Pilih kartu jadwal, ketuk ikon menu (titik tiga).\n'
          '2. Pilih opsi "Hapus".\n'
          '3. Pada dialog "Hapus Jadwal", ketuk tombol "Hapus".\n'
          '4. Amati daftar jadwal dan notifikasi.',
      'Muncul snackbar "Jadwal dihapus", jadwal terhapus dari MongoDB, dan kartu jadwal hilang dari daftar.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-06',
      'Manajemen Jadwal Admin',
      'Batal Hapus Jadwal',
      'Admin membuka dialog konfirmasi hapus jadwal.',
      '1. Pilih menu jadwal, ketuk "Hapus".\n'
          '2. Saat dialog konfirmasi muncul, ketuk tombol "Batal".\n'
          '3. Amati daftar jadwal.',
      'Dialog tertutup dan jadwal TIDAK terhapus. Data tetap utuh di daftar.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-MJW-07',
      'Manajemen Jadwal Admin',
      'Tampilan Saat Belum Ada Jadwal (Empty State)',
      'Admin login pada database yang belum memiliki data jadwal.',
      '1. Buka menu "Manajemen Jadwal".\n'
          '2. Tunggu proses loading selesai.\n'
          '3. Amati tampilan layar.',
      'Muncul ilustrasi/ikon kalender dan teks "Belum ada jadwal" tanpa terjadi crash.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-01',
      'Rekap Admin',
      'Membuka Rekap & Memilih Jadwal (Mahasiswa)',
      'Admin login. Ada jadwal yang sudah memiliki laporan dosen dan presensi mahasiswa.',
      '1. Admin login, buka menu "Rekap Admin".\n'
          '2. Pastikan segment aktif pada "Mahasiswa".\n'
          '3. Ketuk dropdown "Pilih Jadwal".\n'
          '4. Pilih salah satu jadwal dari daftar.\n'
          '5. Tunggu data rekap dimuat.',
      'Tabel rekap kehadiran mahasiswa tampil berisi nama, NIM, jumlah hadir, izin, alpha, dan persentase kehadiran.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-02',
      'Rekap Admin',
      'Beralih Segment Mahasiswa ↔ Dosen',
      'Admin di halaman Rekap Admin dengan jadwal sudah dipilih.',
      '1. Pada halaman rekap dengan jadwal terpilih, ketuk segment "Dosen".\n'
          '2. Amati data yang dimuat ulang.\n'
          '3. Ketuk kembali segment "Mahasiswa".\n'
          '4. Amati perubahan tampilan.',
      'Tampilan berganti sesuai filter: rekap dosen saat "Dosen" dipilih dan rekap mahasiswa saat "Mahasiswa" dipilih, untuk jadwal yang sama.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-03',
      'Rekap Admin',
      'Melihat Ringkasan Statistik Kehadiran Mahasiswa',
      'Admin memilih jadwal pada segment Mahasiswa.',
      '1. Pilih jadwal pada segment "Mahasiswa".\n'
          '2. Amati banner ringkasan di atas tabel.\n'
          '3. Periksa nilai Total Hadir, Izin, Alpha, dan rata-rata persentase (Avg %).',
      'Banner ringkasan menampilkan total pertemuan, jumlah mahasiswa, akumulasi Hadir/Izin/Alpha, dan rata-rata persentase yang sesuai dengan isi tabel.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-04',
      'Rekap Admin',
      'Melihat Rekap Kehadiran Dosen & Keterangan Izin',
      'Admin login. Jadwal memiliki laporan dosen dan/atau izin dosen.',
      '1. Buka "Rekap Admin", pilih segment "Dosen".\n'
          '2. Pilih jadwal yang dosennya pernah mengajar/izin.\n'
          '3. Amati kartu detail jadwal dan kartu rekap dosen.\n'
          '4. Periksa bagian "Keterangan Izin" bila ada.',
      'Tampil detail jadwal, jumlah Hadir, Berhalangan, Total Pertemuan, persentase kehadiran dosen, serta daftar alasan izin bila tersedia.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-05',
      'Rekap Admin',
      'Jadwal Tanpa Data Rekap (Empty State)',
      'Admin login. Dipilih jadwal yang belum memiliki laporan/presensi.',
      '1. Buka "Rekap Admin".\n'
          '2. Pilih jadwal yang belum memiliki pertemuan/presensi.\n'
          '3. Amati area konten rekap.',
      'Muncul pesan "Belum ada rekap untuk jadwal ini." (mahasiswa) atau "Belum ada rekap dosen untuk jadwal ini." (dosen) tanpa crash.',
      'Sesuai Harapan (PASS)',
    ],
    [
      'BB-RKP-06',
      'Rekap Admin',
      'Akurasi Persentase & Warna Indikator Kehadiran',
      'Admin memilih jadwal dengan variasi kehadiran mahasiswa.',
      '1. Pilih jadwal pada segment "Mahasiswa".\n'
          '2. Bandingkan kolom %Hadir terhadap jumlah Hadir dan Total Pertemuan.\n'
          '3. Amati warna indikator persentase (hijau/biru ≥75%, oranye 50–74%, merah <50%).',
      'Persentase = hadir/totalPertemuan x 100 dan ditampilkan dengan warna sesuai ambang batas kehadiran.',
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
  s.setColumnWidth(2, 24);
  s.setColumnWidth(3, 38);
  s.setColumnWidth(4, 34);
  s.setColumnWidth(5, 60);
  s.setColumnWidth(6, 48);
  s.setColumnWidth(7, 22);
}
