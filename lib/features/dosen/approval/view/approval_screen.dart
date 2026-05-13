import 'package:flutter/material.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  static const Color _kNavy = Color(0xFF01018B);
  static const Color _kHeaderText = Color(0xFFF6F6F6);
  static const Color _kBg = Color(0xFFF6F6F6);
  static const Color _kCardBorder = Color(0xFFF3F4F6);
  static const Color _kGrey = Color(0xFF9CA3AF);

  int _selectedTab = 0;

  final List<Map<String, dynamic>> _mockData = [
    {
      'nama': 'Idham Khalid',
      'status': 'Izin',
      'tipe': 'Pemrograman Mobile',
      'keterangan': 'Izin menghadiri pernikahan kakak kandung.',
      'file': 'surat_izin.pdf',
      'tanggal': '05 Mei 2026',
      'avatar': 'IK',
      'color': const Color(0xFF3434A2),
      'approved': false,
      'tabIndex': 0,
    },
    {
      'nama': 'Siti Rahmawati',
      'status': 'Sakit',
      'tipe': 'Basis Data Lanjut',
      'keterangan': 'Demam tinggi 39°C. Surat keterangan dokter terlampir.',
      'file': 'surat_sakit.jpg',
      'tanggal': '06 Mei 2026',
      'avatar': 'SR',
      'color': const Color(0xFFB41D7F),
      'approved': true,
      'tabIndex': 1,
    },
    {
      'nama': 'Budi Pratama',
      'status': 'Izin',
      'tipe': 'Rekayasa PL',
      'keterangan': 'Mengikuti lomba hackathon nasional mewakili kampus.',
      'file': 'undangan_hackathon.pdf',
      'tanggal': '09 Mei 2026',
      'avatar': 'BP',
      'color': const Color(0xFF0891B2),
      'approved': false,
      'tabIndex': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: _kNavy,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Approval\nIzin & Sakit',
                style: TextStyle(
                  color: _kHeaderText,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  fontSize: 28,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              _buildTabs(),
            ],
          ),
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildTabs() {
    const tabs = ['Menunggu', 'Disetujui', 'Ditolak'];
    return Row(
      children: List.generate(tabs.length, (index) {
        final isActive = _selectedTab == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isActive ? _kNavy : _kHeaderText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    final filtered = _mockData
        .where((item) => item['tabIndex'] == _selectedTab)
        .toList();

    return Container(
      color: _kBg,
      child: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _kCardBorder,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: _kGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedTab == 0
                        ? 'Tidak ada pengajuan menunggu'
                        : _selectedTab == 1
                        ? 'Belum ada pengajuan disetujui'
                        : 'Tidak ada pengajuan ditolak',
                    style: const TextStyle(
                      color: _kGrey,
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'HARI INI - 10 MEI 2026',
                      style: TextStyle(
                        color: _kGrey,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  ...filtered.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key < filtered.length - 1 ? 16 : 0,
                      ),
                      child: _buildApprovalCard(entry.value),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> item) {
    final bool approved = item['approved'] as bool;
    final bool waiting = _selectedTab == 0;
    final Color avatarColor = item['color'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: Text(
                  item['avatar'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] as String,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['status']} • ${item['tipe']}',
                      style: const TextStyle(
                        color: _kGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              if (!waiting)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: approved
                        ? const Color(0xFFEAF8F0)
                        : const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    approved ? 'Disetujui' : 'Ditolak',
                    style: TextStyle(
                      color: approved
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['keterangan'] as String,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 13,
              height: 1.4,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, size: 16, color: _kGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['file'] as String,
                  style: const TextStyle(
                    color: _kGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              Text(
                item['tanggal'] as String,
                style: const TextStyle(
                  color: _kGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          if (waiting) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
