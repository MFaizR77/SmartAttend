import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'form_pengajuan_screen.dart';

class PergantianJadwalScreen extends StatefulWidget {
  final User user;

  const PergantianJadwalScreen({super.key, required this.user});

  @override
  State<PergantianJadwalScreen> createState() => _PergantianJadwalScreenState();
}

class _PergantianJadwalScreenState extends State<PergantianJadwalScreen>
    with SingleTickerProviderStateMixin {
  final _vm = PergantianJadwalViewModel();
  int _selectedTabIndex = 0;
  bool _showRiwayat = false;

  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
    _vm.loadJadwalAsli(widget.user.id);
    _vm.loadRiwayat(widget.user.id);

    // Set tab awal ke hari ini
    final hariIni = DateTime.now().weekday; // 1=Senin ... 5=Jumat
    if (hariIni >= 1 && hariIni <= 5) {
      _selectedTabIndex = hariIni - 1;
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pergantian Jadwal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showRiwayat = !_showRiwayat),
            icon: Icon(_showRiwayat ? Icons.calendar_today : Icons.history,
                color: Colors.white, size: 18),
            label: Text(_showRiwayat ? 'Jadwal' : 'Riwayat',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _showRiwayat ? _buildRiwayat() : _buildJadwalView(),
    );
  }

  Widget _buildJadwalView() {
    return Column(
      children: [
        // Chip filter hari
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(_hariList.length, (index) {
              final isSelected = _selectedTabIndex == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        _hariList[index].substring(0, 3), // Sen, Sel, Rab, Kam, Jum
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // Daftar jadwal
        Expanded(
          child: _vm.isLoading && _vm.daftarJadwalAsli.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildJadwalHari(_hariList[_selectedTabIndex]),
        ),
      ],
    );
  }

  Widget _buildJadwalHari(String hari) {
    final jadwalHari = _vm.daftarJadwalAsli
        .where((j) => (j['hari'] as String? ?? '') == hari)
        .toList();

    if (jadwalHari.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.border),
            const SizedBox(height: 12),
            Text('Tidak ada jadwal pada hari $hari',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jadwalHari.length,
      itemBuilder: (context, index) {
        final j = jadwalHari[index];
        return _buildJadwalCard(j);
      },
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> j) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormPengajuanScreen(
                user: widget.user,
                vm: _vm,
                jadwalTerpilih: j,
              ),
            ),
          );
          if (result == true) {
            _vm.loadRiwayat(widget.user.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_outlined,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j['namaMK'] ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelas ${j['kelas'] ?? '-'}  •  ${j['jamMulai'] ?? ''} - ${j['jamSelesai'] ?? ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      'Ruang: ${j['ruangan'] ?? '-'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayat() {
    if (_vm.isLoading && _vm.riwayatPengajuan.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.riwayatPengajuan.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _vm.loadRiwayat(widget.user.id),
        child: const Center(
          child: Text('Belum ada riwayat pengajuan',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _vm.loadRiwayat(widget.user.id),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vm.riwayatPengajuan.length,
        itemBuilder: (context, index) {
          final p = _vm.riwayatPengajuan[index];
          final tgl = DateTime.tryParse(p['tanggalPengganti'] ?? '');
          final tglStr =
              tgl != null ? DateFormat('dd MMM yyyy').format(tgl) : '-';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p['namaMK'] ?? 'Jadwal Kuliah',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(p['status'] ?? 'pending')
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (p['status'] as String? ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(p['status'] ?? 'pending'),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Kelas: ${p['kelas'] ?? '-'}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Jadwal Pengganti:',
                      style:
                          const TextStyle(color: AppColors.textSecondary)),
                  Text(
                      '$tglStr  •  ${p['jamMulaiPengganti']} - ${p['jamSelesaiPengganti']}'),
                  Text('Ruangan: ${p['ruanganPengganti']}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
