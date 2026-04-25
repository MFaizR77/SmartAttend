# SmartAttend

Proyek flutter tentang absensi dosen dan mahasiswa berbasis offline-first 

<<<<<<< HEAD
=======
## Struktur Folder

```
lib/
├── main.dart
├── core/
│   ├── services/
│   │   ├── connectivity_service.dart
│   │   ├── notification_service.dart
│   │   └── sync_manager.dart
│   └── utils/
│       └── uuid_helper.dart
├── data/
│   ├── local/
│   │   ├── models/
│   │   │   ├── jadwal_kuliah.dart
│   │   │   ├── pengajuan_izin.dart
│   │   │   ├── record_presensi.dart
│   │   │   ├── sesi_absensi.dart
│   │   │   └── user.dart
│   │   └── hive_helper.dart
│   ├── mapper/
│   │   ├── pengajuan_izin_mapper.dart
│   │   ├── record_presensi_mapper.dart
│   │   └── sesi_absensi_mapper.dart
│   └── remote/
│       ├── api_service.dart
│       └── models/
│           ├── jadwal_kuliah_model.dart
│           ├── pengajuan_izin_model.dart
│           ├── record_presensi_model.dart
│           ├── sesi_absensi_model.dart
│           └── user_model.dart
└── features/
    ├── auth/
    │   ├── view/
    │   │   ├── login_screen.dart
    │   │   └── widgets/
    │   │       └── login_form.dart
    │   └── viewmodel/
    │       └── auth_viewmodel.dart
    ├── dosen/
    │   ├── approval/
    │   │   ├── view/
    │   │   │   ├── approval_screen.dart
    │   │   │   └── widgets/
    │   │   │       └── approval_card.dart
    │   │   └── viewmodel/
    │   │       └── approval_viewmodel.dart
    │   └── sesi/
    │       ├── view/
    │       │   ├── sesi_screen.dart
    │       │   └── widgets/
    │       │       └── sesi_card.dart
    │       └── viewmodel/
    │           └── sesi_viewmodel.dart
    └── mahasiswa/
        ├── izin/
        │   ├── view/
        │   │   ├── izin_screen.dart
        │   │   └── widgets/
        │   │       ├── foto_picker.dart
        │   │       └── izin_form.dart
        │   └── viewmodel/
        │       └── izin_viewmodel.dart
        ├── jadwal/
        │   ├── view/
        │   │   ├── jadwal_screen.dart
        │   │   └── widgets/
        │   │       └── jadwal_card.dart
        │   └── viewmodel/
        │       └── jadwal_viewmodel.dart
        ├── presensi/
        │   ├── view/
        │   │   ├── presensi_screen.dart
        │   │   └── widgets/
        │   │       ├── checkin_button.dart
        │   │       └── status_badge.dart
        │   └── viewmodel/
        │       └── presensi_viewmodel.dart
        └── rekap/
            ├── view/
            │   ├── rekap_screen.dart
            │   └── widgets/
            │       └── rekap_tile.dart
            └── viewmodel/
                └── rekap_viewmodel.dart
```
>>>>>>> origin/main
