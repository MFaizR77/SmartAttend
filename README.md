# SmartAttend

Aplikasi Flutter untuk absensi dosen dan mahasiswa berbasis **offline-first**. Data disimpan lokal dengan Hive lalu disinkronkan ke MongoDB saat perangkat online.

## Peran Pengguna

Aplikasi mendukung 4 tipe akun dengan dashboard dan alur masing-masing:

- **Mahasiswa** — lihat jadwal, presensi, ajukan izin, lihat rekap kehadiran
- **Dosen** — buka sesi absensi, approval presensi, tindak lanjut izin, pergantian jadwal, rekap
- **Wali Dosen** — dashboard pemantauan mahasiswa wali
- **Admin** — manajemen user/jadwal/periode, upload & approval jadwal, assign wali, kenaikan kelas, rekap

## Arsitektur

- **Pola:** MVVM (`view` + `viewmodel`) per fitur
- **Local storage:** Hive (offline-first, lihat `hive_helper.dart`)
- **Remote:** MongoDB via `mongo_dart` (`database_service.dart`)
- **Sinkronisasi:** `connectivity_service` + `sync_manager` (background sync)
- **Lainnya:** notifikasi lokal (`flutter_local_notifications`) & FCM (`firebase_messaging`), upload/ekspor Excel (`excel`, `file_picker`, `share_plus`)

## Dependensi Utama

`hive` / `hive_flutter`, `mongo_dart`, `connectivity_plus`, `flutter_dotenv`, `intl`, `flutter_local_notifications`, `timezone`, `firebase_messaging`, `file_picker`, `excel`, `share_plus`, `path_provider`.

## Struktur Folder

```
lib/
├── main.dart
├── core/
│   ├── services/
│   │   ├── connectivity_service.dart
│   │   ├── notification_service.dart
│   │   ├── jadwal_cache_service.dart
│   │   ├── session_state_service.dart
│   │   └── sync_manager.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── utils/
│       └── uuid_helper.dart
├── data/
│   ├── local/
│   │   ├── models/
│   │   │   ├── jadwal_kuliah.dart
│   │   │   ├── laporan_dosen.dart
│   │   │   ├── pengajuan_izin.dart
│   │   │   ├── record_presensi.dart
│   │   │   ├── sesi_absensi.dart
│   │   │   └── user.dart
│   │   ├── dummy_data.dart
│   │   └── hive_helper.dart
│   ├── mapper/
│   │   ├── pengajuan_izin_mapper.dart
│   │   ├── record_presensi_mapper.dart
│   │   └── sesi_absensi_mapper.dart
│   └── remote/
│       ├── models/
│       │   ├── jadwal_kuliah_model.dart
│       │   ├── pengajuan_izin_model.dart
│       │   ├── record_presensi_model.dart
│       │   ├── sesi_absensi_model.dart
│       │   └── user_model.dart
│       └── database_service.dart
└── features/
    ├── onboarding/
    │   └── view/
    │       ├── onboarding_screen.dart
    │       └── onboarding_slide.dart
    ├── auth/
    │   ├── view/
    │   │   ├── login_screen.dart
    │   │   └── widgets/
    │   │       ├── login_form.dart
    │   │       └── logout_confirm_dialog.dart
    │   └── viewmodel/
    │       └── auth_viewmodel.dart
    ├── profil/
    │   └── view/
    │       └── profil_screen.dart
    ├── admin/
    │   ├── dashboard/            # admin_dashboard_screen + viewmodel
    │   ├── manajemen_user/       # manajemen_user_screen
    │   ├── manajemen_jadwal/     # manajemen_jadwal_screen
    │   ├── manajemen_periode/    # manajemen_periode_screen
    │   ├── upload_jadwal/        # upload_jadwal_screen
    │   ├── approval_jadwal/      # approval_jadwal_screen + viewmodel
    │   ├── assign_wali/          # assign_wali_screen
    │   ├── kenaikan_kelas/       # kenaikan_kelas_screen
    │   └── rekap/                # rekap_admin_screen
    ├── dosen/
    │   ├── dashboard/            # dosen_dashboard_screen + viewmodel
    │   ├── sesi/                 # sesi_dosen_screen + viewmodel
    │   ├── approval/             # approval_screen + viewmodel
    │   ├── izin/                 # izin_dosen_screen + viewmodel
    │   ├── tindak_lanjut_izin/   # tindak_lanjut_screen + viewmodel
    │   ├── pergantian_jadwal/    # pergantian_jadwal / pilih_ruangan / form_pengajuan + viewmodel
    │   └── rekap/                # rekap_dosen_screen + viewmodel
    ├── walidosen/
    │   └── dashboard/            # walidosen_dashboard_screen + viewmodel
    └── mahasiswa/
        ├── dashboard/            # mahasiswa_dashboard_screen + viewmodel
        ├── jadwal/               # jadwal_screen + viewmodel
        ├── presensi/             # presensi_screen, absensi_list_screen + viewmodel
        ├── izin/                 # izin_screen + viewmodel
        └── rekap/                # rekap_screen + viewmodel
```

> Setiap fitur di `features/` mengikuti pola `view/` (UI + `widgets/`) dan `viewmodel/` (state & logika).

## Menjalankan Proyek

1. Salin konfigurasi environment ke file `.env` (URI MongoDB, dll).
2. Install dependensi:
   ```bash
   flutter pub get
   ```
3. Generate Hive adapter (file `*.g.dart`):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Jalankan aplikasi:
   ```bash
   flutter run
   ```
