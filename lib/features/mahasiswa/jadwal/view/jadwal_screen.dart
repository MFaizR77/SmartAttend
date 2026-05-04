import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';

class JadwalScreen extends StatefulWidget {
  final User user;

  const JadwalScreen({super.key, required this.user});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScheduleSection(
                        title: 'Jadwal Hari Ini',
                        schedules: [
                          {
                            'title': 'Pemrograman Mobile',
                            'time': '07:30 – 09:10',
                            'room': 'Ruang 204',
                            'lecturer': 'Dr. Hendra',
                            'status': 'Selesai',
                            'statusColor': const Color(0xFFF3F4F6),
                            'statusTextColor': const Color(0xFF9CA3AF),
                            'iconBg': const Color(0x213434A2),
                          },
                          {
                            'title': 'Basis Data Lanjut',
                            'time': '09:30 – 11:10',
                            'room': 'Lab DB',
                            'lecturer': 'Ir. Susanto',
                            'status': 'Berlangsung',
                            'statusColor': const Color(0xFFDCFCE7),
                            'statusTextColor': const Color(0xFF16A34A),
                            'iconBg': const Color(0x1E16A34A),
                          },
                          {
                            'title': 'Rekayasa Perangkat Lunak',
                            'time': '11:30 – 13:10',
                            'room': 'Ruang 301',
                            'lecturer': 'Dr. Kartini',
                            'status': 'Upcoming',
                            'statusColor': const Color(0xFFEEF2FF),
                            'statusTextColor': const Color(0xFF01018B),
                            'iconBg': const Color(0x213434A2),
                          },
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildScheduleSection(
                        title: 'Besok',
                        schedules: [
                          {
                            'title': 'Pemrograman Mobile',
                            'time': '09:30 – 11:10',
                            'room': 'Ruang 204',
                            'lecturer': 'Dr. Hendra',
                            'status': 'Upcoming',
                            'statusColor': const Color(0xFFEEF2FF),
                            'statusTextColor': const Color(0xFF01018B),
                            'iconBg': const Color(0x213434A2),
                          },
                          {
                            'title': 'Statistika & Probabilitas',
                            'time': '13:00 – 14:40',
                            'room': 'Ruang 105',
                            'lecturer': 'Dr. Anita',
                            'status': 'Upcoming',
                            'statusColor': const Color(0xFFEEF2FF),
                            'statusTextColor': const Color(0xFF01018B),
                            'iconBg': const Color(0x213434A2),
                          },
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF01018B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Jadwal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.20,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8003),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFF8003)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  spacing: 3,
                  children: [
                    Container(
                      width: 14,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      width: 7,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection({
    required String title,
    required List<Map<String, dynamic>> schedules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...schedules.map((schedule) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildScheduleCard(schedule),
        )).toList(),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: schedule['iconBg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.class_, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  schedule['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14.50,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 3,
                      child: Text(
                        schedule['time'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '•',
                        style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.location_on, size: 13, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: Text(
                        schedule['room'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.person, size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        schedule['lecturer'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11.50,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: schedule['statusColor'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              schedule['status'] as String,
              style: TextStyle(
                color: schedule['statusTextColor'] as Color,
                fontSize: 10.50,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
