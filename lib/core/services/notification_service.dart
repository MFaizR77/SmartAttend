import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../data/local/hive_helper.dart';
import '../../../data/remote/database_service.dart';

// Harus top-level function untuk background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Lazy — hanya dibuat setelah Firebase.initializeApp() berhasil
  FirebaseMessaging? _firebaseMessaging;
  String? _currentToken;

  Future<void> init() async {
    // Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[Notif] Tapped: ${response.payload}');
      },
    );

    // Inisialisasi FCM — best-effort, tidak crash jika Firebase belum init
    await _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      // FirebaseMessaging.instance akan throw jika Firebase belum diinit
      _firebaseMessaging = FirebaseMessaging.instance;

      // Minta izin notifikasi
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] Authorization: ${settings.authorizationStatus}');

      // Dapatkan token
      if (!kIsWeb && Platform.isIOS) {
        bool apnsReady = false;
        for (int i = 0; i < 15; i++) {
          try {
            final apnsToken = await _firebaseMessaging!.getAPNSToken();
            if (apnsToken != null) {
              apnsReady = true;
              break;
            }
          } catch (_) {}
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsReady) {
          _currentToken = await _firebaseMessaging!.getToken();
        } else {
          debugPrint('[FCM] APNS tidak tersedia setelah 15 detik, skip.');
        }
      } else {
        _currentToken = await _firebaseMessaging!.getToken();
      }
      debugPrint('[FCM] Token: $_currentToken');

      // ✅ Simpan token ke Hive untuk akses offline
      if (_currentToken != null) {
        await HiveHelper.userBoxInstance.put('fcm_token', _currentToken);
      }

      // Listen token refresh → update cache lokal
      _firebaseMessaging!.onTokenRefresh.listen((token) {
        _currentToken = token;
        HiveHelper.userBoxInstance.put('fcm_token', token);
        debugPrint('[FCM] Token refreshed & saved: $token');
      });

      // Foreground message
      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('[FCM] Foreground: ${msg.notification?.title}');
        _showFCMNotification(msg);
      });

      // Background tap
      FirebaseMessaging.onMessageOpenedApp.listen((msg) {
        debugPrint('[FCM] Opened: ${msg.data}');
      });

      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Terminated state
      final initialMsg = await _firebaseMessaging!.getInitialMessage();
      if (initialMsg != null) {
        debugPrint('[FCM] Opened from terminated: ${initialMsg.data}');
      }
    } catch (e) {
      // Firebase belum diinit — baca token dari cache lokal Hive jika ada
      final cachedToken = HiveHelper.userBoxInstance.get('fcm_token') as String?;
      if (cachedToken != null) {
        _currentToken = cachedToken;
        debugPrint('[FCM] Firebase tidak tersedia, pakai token cache: $cachedToken');
      } else {
        debugPrint('[FCM] Tidak tersedia & tidak ada cache: $e');
      }
      _firebaseMessaging = null;
    }
  }

  /// Simpan FCM token ke MongoDB setelah user login.
  Future<void> saveTokenForUser(String userId, String accountType) async {
    if (_currentToken == null) return;
    try {
      await DatabaseService().saveFcmToken(
        userId: userId,
        accountType: accountType,
        token: _currentToken!,
      );
      debugPrint('[FCM] Token saved for $userId ($accountType)');
    } catch (e) {
      debugPrint('[FCM] Gagal simpan token: $e');
    }
  }

  void _showFCMNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'FCM Notifications',
            channelDescription: 'Notifikasi dari Firebase Cloud Messaging',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Meminta izin notifikasi untuk Android 13+
  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Menjadwalkan pengingat harian pada jam tertentu (misal: 20:00)
  Future<void> scheduleDailyReminder() async {
    await requestPermission();

    const int notificationId = 100;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Pengingat Laporan Sesi',
      'Jangan lupa mengisi laporan/materi untuk sesi perkuliahan Anda hari ini.',
      _nextInstanceOfTime(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminder',
          channelDescription: 'Pengingat harian untuk laporan dosen',
          importance: Importance.max,
          priority: Priority.high,
        ),

        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Menghapus notifikasi pengingat jika dosen sudah mengisi laporan
  Future<void> cancelDailyReminder() async {
    await flutterLocalNotificationsPlugin.cancel(100);
  }

  /// Jadwalkan notifikasi -5 menit sebelum jamMulai untuk setiap jadwal hari ini.
  Future<void> scheduleAbsensiReminder(List<Map<String, dynamic>> jadwalHariIni) async {
    await requestPermission();

    final now = DateTime.now();
    final tanggal = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    for (final jadwal in jadwalHariIni) {
      try {
        final jadwalId = jadwal['id']?.toString() ?? jadwal['_id']?.toString() ?? '';
        final namaMK = jadwal['namaMK']?.toString() ?? jadwal['mataKuliah']?.toString() ?? 'Mata Kuliah';
        final jamMulai = jadwal['jamMulai']?.toString() ?? '';
        final jamSelesai = jadwal['jamSelesai']?.toString() ?? '';
        final ruangan = jadwal['ruangan']?.toString() ?? '';

        if (jadwalId.isEmpty || jamMulai.isEmpty) continue;

        // Parse jamMulai "HH:MM" → kurangi 5 menit
        final parts = jamMulai.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        var scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute)
            .subtract(const Duration(minutes: 5));

        // Skip jika waktu sudah lewat
        if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

        // ID unik per jadwal per hari
        final notificationId = ('${jadwalId}_$tanggal').hashCode.abs() % 100000;

        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Jangan Lupa Buka Absensi',
          '$namaMK jam $jamMulai - $jamSelesai, ruang $ruangan',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'absensi_reminder_channel',
              'Absensi Reminder',
              channelDescription: 'Pengingat buka absensi sebelum kelas',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        debugPrint('[Notif] Scheduled absensi reminder untuk $namaMK jam ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
      } catch (e) {
        debugPrint('[Notif] Gagal schedule absensi reminder: $e');
      }
    }
  }

  /// Cek apakah ada laporan yang belum diisi, kalau ada schedule reminder jam 8 malam.
  Future<void> checkAndScheduleLaporanReminder(String dosenId) async {
    try {
      final db = DatabaseService();

      // Ambil jadwal dosen hari ini
      final jadwalHariIni = await db.getJadwalDosen(dosenId);
      if (jadwalHariIni.isEmpty) {
        await cancelDailyReminder();
        return;
      }

      // Cek laporan_dosen untuk setiap jadwal hari ini
      bool adaYangBelumIsi = false;
      for (final jadwal in jadwalHariIni) {
        final jadwalId = jadwal['_id']?.toString() ?? '';
        if (jadwalId.isEmpty) continue;

        final laporan = await db.getLaporanDosen(jadwalId, dosenId);
        if (laporan == null || laporan['materi'] == null || laporan['materi'].toString().trim().isEmpty) {
          adaYangBelumIsi = true;
          break;
        }
      }

      if (adaYangBelumIsi) {
        await scheduleDailyReminder();
        debugPrint('[Notif] Laporan reminder dijadwalkan (ada yang belum diisi)');
      } else {
        await cancelDailyReminder();
        debugPrint('[Notif] Laporan reminder dibatalkan (semua sudah diisi)');
      }
    } catch (e) {
      debugPrint('[Notif] Gagal cek laporan reminder: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}