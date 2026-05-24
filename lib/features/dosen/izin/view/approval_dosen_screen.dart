import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApprovalDosenScreen extends StatefulWidget {
  const ApprovalDosenScreen({super.key});

  @override
  State<ApprovalDosenScreen> createState() => _ApprovalDosenScreenState();
}

class _ApprovalDosenScreenState extends State<ApprovalDosenScreen> {
  int _tabIndex = 0; // 0: Menunggu, 1: Disetujui, 2: Ditolak

  final _items = [
    {
      'nama': 'Idham Khalid',
      'inisial': 'IK',
      'unit': 'Pemrograman Mobile',
      'jenis': 'Izin',
      'keterangan': 'Izin menghadiri pernikahan kakak kandung.',
      'lampiran': 'surat_izin.pdf',
      'tanggal': DateTime(2026, 5, 5),
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0596),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Approval',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Izin & Sakit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tabButton('Menunggu', 0, selectedColor: Colors.white, selectedTextColor: Color(0xFF09039C)),
              const SizedBox(width: 8),
              _tabButton('Disetujui', 1),
              const SizedBox(width: 8),
              _tabButton('Ditolak', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, {Color? selectedColor, Color? selectedTextColor}) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? (selectedColor ?? const Color(0xFF0A0596)) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(selected ? 0.0 : 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? (selectedTextColor ?? Colors.white) : Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HARI INI - ${DateFormat('dd MMM yyyy').format(DateTime.now()).toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._items.map((it) => _buildCard(it)).toList(),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF2E2BF6),
                child: Text(
                  it['inisial'] ?? '-',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it['nama'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${it['jenis']} · ${it['unit']}',
                      style: const TextStyle(
                        color: Color(0xFF9AA0B0),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            it['keterangan'] ?? '-',
            style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.attachment_outlined, size: 18, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Text(
                it['lampiran'] ?? '-',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM yyyy', 'id_ID').format(it['tanggal']),
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onReject(it),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1B6B6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: const Color(0xFFD54B4B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onApprove(it),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0596),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onApprove(Map<String, dynamic> it) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan disetujui')));
  }

  void _onReject(Map<String, dynamic> it) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan ditolak')));
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      showUnselectedLabels: true,
      selectedItemColor: const Color(0xFF0A0596),
      unselectedItemColor: const Color(0xFF9CA3AF),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Jadwal'),
        BottomNavigationBarItem(icon: Icon(Icons.checklist_rtl), label: 'Approval'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
      ],
    );
  }
}
