import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'form_pengajuan_screen.dart';

class PergantianJadwalScreen extends StatefulWidget {
  final User user;

  const PergantianJadwalScreen({super.key, required this.user});

  @override
  State<PergantianJadwalScreen> createState() => _PergantianJadwalScreenState();
}

class _PergantianJadwalScreenState extends State<PergantianJadwalScreen> {
  final _vm = PergantianJadwalViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
    _loadData();
  }

  void _loadData() {
    _vm.loadRiwayat(widget.user.id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFFF8003);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          _vm.isLoading && _vm.riwayatPengajuan.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF01018B)))
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  color: const Color(0xFF01018B),
                  child: _vm.riwayatPengajuan.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.edit_calendar_outlined,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada riwayat pengajuan',
                                    style: TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 15,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 80),
                      itemCount: _vm.riwayatPengajuan.length,
                      itemBuilder: (context, index) {
                        final p = _vm.riwayatPengajuan[index];
                        final tgl = DateTime.tryParse(p['tanggalPengganti'] ?? '');
                        final tglStr = tgl != null ? DateFormat('dd MMM yyyy').format(tgl) : '-';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0x213434A2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.class_outlined,
                                      color: Color(0xFF01018B),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['namaMK'] ?? 'Jadwal Kuliah',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF1A1A1A),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kelas ${p['kelas']}',
                                          style: const TextStyle(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 12,
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(p['status']).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p['status'].toString().toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(p['status']),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Plus Jakarta Sans',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tglStr,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  const Icon(
                                    Icons.schedule_outlined,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p['jamMulaiPengganti']} - ${p['jamSelesaiPengganti']}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.room_outlined,
                                    size: 16,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ruangan: ${p['ruanganPengganti']}',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ganti Jadwal',
                      style: TextStyle(
                        color: Color(0xFFF6F6F6),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FormPengajuanScreen(user: widget.user, vm: _vm)),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF01018B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
    );
  }
}
