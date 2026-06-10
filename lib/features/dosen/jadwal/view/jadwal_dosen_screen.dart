import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/jadwal_dosen_viewmodel.dart';

/// Tampilan jadwal mingguan dosen (Senin–Jumat).
class JadwalDosenScreen extends StatefulWidget {
  final User user;

  const JadwalDosenScreen({super.key, required this.user});

  @override
  State<JadwalDosenScreen> createState() => _JadwalDosenScreenState();
}

class _JadwalDosenScreenState extends State<JadwalDosenScreen> {
  late final JadwalDosenViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = JadwalDosenViewModel();
    _vm.loadJadwal(widget.user.id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildHariSelector(),
        Expanded(child: _buildJadwalList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Mengajar',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.user.nama,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHariSelector() {
    return ValueListenableBuilder<String>(
      valueListenable: _vm.selectedHari,
      builder: (_, selected, __) {
        final today = JadwalDosenViewModel.hariIni();
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: JadwalDosenViewModel.hariList.map((hari) {
                final isSelected = hari == selected;
                final isToday = hari == today;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _vm.pilihHari(hari)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : isToday
                                  ? AppColors.primaryBlue.withOpacity(0.4)
                                  : AppColors.border,
                          width: isToday && !isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        hari,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJadwalList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isLoading,
      builder: (_, loading, __) {
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ValueListenableBuilder<String>(
          valueListenable: _vm.selectedHari,
          builder: (_, selectedHari, __) {
            return ValueListenableBuilder<Map<String, List<Map<String, dynamic>>>>(
              valueListenable: _vm.jadwalPerHari,
              builder: (_, perHari, __) {
                final list = perHari[selectedHari] ?? [];
                return RefreshIndicator(
                  onRefresh: () => _vm.loadJadwal(widget.user.id),
                  color: AppColors.primaryBlue,
                  child: list.isEmpty
                      ? _buildKosong(selectedHari)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _buildJadwalCard(list[i]),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKosong(String hari) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada jadwal hari $hari',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> j) {
    final namaMK = j['namaMK']?.toString() ?? '-';
    final kelas = j['kelas']?.toString() ?? '';
    final jamMulai = j['jamMulai']?.toString() ?? '-';
    final jamSelesai = j['jamSelesai']?.toString() ?? '-';
    final ruangan = j['ruangan']?.toString() ?? '-';
    final program = j['program']?.toString() ?? '';
    final tipe = j['tipe']?.toString() ?? 'Reguler';
    final isPengganti = tipe == 'Pengganti';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPengganti ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPengganti ? Colors.blue.shade200 : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Jam block
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isPengganti
                    ? Colors.blue.shade100
                    : AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    jamMulai,
                    style: TextStyle(
                      color: isPengganti
                          ? Colors.blue.shade700
                          : AppColors.primaryBlue,
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    width: 2,
                    height: 12,
                    color: isPengganti
                        ? Colors.blue.shade300
                        : AppColors.primaryBlue.withOpacity(0.3),
                  ),
                  Text(
                    jamSelesai,
                    style: TextStyle(
                      color: isPengganti
                          ? Colors.blue.shade600
                          : AppColors.primaryBlue.withOpacity(0.7),
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info MK
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaMK,
                    style: TextStyle(
                      color: isPengganti
                          ? Colors.blue.shade800
                          : AppColors.primary,
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (kelas.isNotEmpty) ...[
                        _infoChip(kelas, Icons.group_outlined),
                        const SizedBox(width: 6),
                      ],
                      _infoChip(ruangan, Icons.room_outlined),
                    ],
                  ),
                  if (program.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      program,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Badge pengganti
            if (isPengganti)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pengganti',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
