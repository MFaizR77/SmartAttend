import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/rekap_admin_viewmodel.dart';

class RekapAdminScreen extends StatefulWidget {
  const RekapAdminScreen({super.key});

  @override
  State<RekapAdminScreen> createState() => _RekapAdminScreenState();
}

class _RekapAdminScreenState extends State<RekapAdminScreen> {
  final RekapAdminViewModel _vm = RekapAdminViewModel();
  int _selectedIndex = 0; // 0 Mahasiswa, 1 Dosen
  String? _selectedJadwalId;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onVm);
    _vm.loadJadwal();
  }

  void _onVm() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onVm);
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [
            Color(0xFF1A237E),
            Color(0xFF1E3A8A),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Rekap Admin',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                height: 1.1,
                fontSize: 28,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ToggleButtons(
              isSelected: [for (int i = 0; i < 2; i++) i == _selectedIndex],
              onPressed: (i) {
                setState(() => _selectedIndex = i);
                final tipe = i == 0 ? 'mahasiswa' : 'dosen';
                _vm.setFilter(tipe);
                if (_selectedJadwalId != null) {
                  _vm.loadRekap(_selectedJadwalId!);
                }
              },
              borderRadius: BorderRadius.circular(18),
              borderColor: AppColors.border,
              selectedBorderColor: AppColors.primaryBlue,
              disabledBorderColor: AppColors.border,
              fillColor: AppColors.primaryBlue,
              selectedColor: AppColors.textOnPrimary,
              color: AppColors.graySlate,
              hoverColor: AppColors.accentLight,
              splashColor: AppColors.accentLight,
              constraints: const BoxConstraints(minHeight: 54, minWidth: 150),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Center(child: Text('Mahasiswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Center(child: Text('Dosen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJadwalSelector() {
    final list = _vm.daftarJadwal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.view_list_rounded, size: 18, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Jadwal',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cari jadwal berdasarkan mata kuliah, kelas, hari, dan jam',
                        style: TextStyle(fontSize: 12, color: AppColors.graySlate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              menuMaxHeight: 320,
              initialValue: _selectedJadwalId,
              hint: const Text('Pilih jadwal yang ingin direkap'),
              selectedItemBuilder: (context) {
                return list.map((j) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatJadwalLabel(j),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList();
              },
              items: list.map((j) {
                final id = j['_id']?.toString() ?? '';
                final title = j['namaMK']?.toString() ?? j['kodeMK']?.toString() ?? id;
                final subtitle = _formatJadwalSubtitle(j);
                return DropdownMenuItem<String>(
                  value: id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.graySlate),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedJadwalId = v;
                });
                if (v != null) _vm.loadRekap(v);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJadwalLabel(Map<String, dynamic> jadwal) {
    final namaMk = jadwal['namaMK']?.toString() ?? jadwal['kodeMK']?.toString() ?? '-';
    final kelas = jadwal['kelas']?.toString() ?? '-';
    return '$namaMk · $kelas';
  }

  String _formatJadwalSubtitle(Map<String, dynamic> jadwal) {
    final hari = jadwal['hari']?.toString() ?? '-';
    final jamMulai = jadwal['jamMulai']?.toString() ?? '-';
    final jamSelesai = jadwal['jamSelesai']?.toString() ?? '-';
    final dosen = jadwal['namaDosen']?.toString() ?? jadwal['dosenId']?.toString() ?? '-';
    return '$hari • $jamMulai - $jamSelesai • $dosen';
  }

  Widget _buildSelectedJadwalSummary() {
    final jadwal = _vm.selectedJadwal;
    if (jadwal == null) {
      return const SizedBox.shrink();
    }

    final namaMk = jadwal['namaMK']?.toString() ?? '-';
    final kelas = jadwal['kelas']?.toString() ?? '-';
    final dosen = jadwal['namaDosen']?.toString() ?? jadwal['dosenId']?.toString() ?? '-';
    final hari = jadwal['hari']?.toString() ?? '-';
    final jamMulai = jadwal['jamMulai']?.toString() ?? '-';
    final jamSelesai = jadwal['jamSelesai']?.toString() ?? '-';
    final tipe = jadwal['tipe']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Detail Jadwal Dosen',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              namaMk,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$kelas • $hari • $jamMulai - $jamSelesai',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.graySlate,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip('Dosen', dosen),
                _buildInfoChip('Tipe', tipe),
                _buildInfoChip('Kelas', kelas),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.graySlate,
        ),
      ),
    );
  }

  Widget _buildMahasiswaRekap() {
    if (_vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (_vm.errorMessage != null) return Center(child: Text(_vm.errorMessage!));
    if (_vm.daftarRekap.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Belum ada rekap asli mahasiswa untuk jadwal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.graySlate),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        // Dosen summary metrics shown under admin rekap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _statPill('Hadir', _formatNumber(_vm.daftarRekap.fold<int>(0, (s, r) => s + (r['hadir'] as int? ?? 0))), AppColors.primaryBlue),
                const SizedBox(width: 8),
                _statPill('Berhalangan', _formatNumber(_vm.daftarRekap.fold<int>(0, (s, r) => s + (r['berhalangan'] as int? ?? 0))), const Color(0xFFB45309)),
                const SizedBox(width: 8),
                _statPill('Persen Hadir', _formatPercent(_vm.daftarRekap), const Color(0xFF0F766E)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildTableHeader(
          leftTitle: 'Mahasiswa',
          leftSubtitle: 'Nama / NIM',
          rightTitles: const ['Hadir', 'Izin'],
        ),
        const SizedBox(height: 8),
        ..._vm.daftarRekap.map((r) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                title: Text(r['nama']?.toString() ?? '-'),
                subtitle: Text('NIM: ${r['nim'] ?? '-'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hadir: ${r['hadir'] ?? 0}'),
                    Text('Izin: ${r['izin'] ?? 0}'),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDosenRekap() {
    if (_vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (_vm.errorMessage != null) return Center(child: Text(_vm.errorMessage!));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        const SizedBox(height: 10),
        _buildSelectedJadwalSummary(),
        const SizedBox(height: 10),
        // Show dosen metrics summary here as requested
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _statPill('Hadir', _formatNumber(_vm.daftarRekap.fold<int>(0, (s, r) => s + (r['hadir'] as int? ?? 0))), AppColors.primaryBlue),
                const SizedBox(width: 8),
                _statPill('Berhalangan', _formatNumber(_vm.daftarRekap.fold<int>(0, (s, r) => s + (r['berhalangan'] as int? ?? 0))), const Color(0xFFB45309)),
                const SizedBox(width: 8),
                _statPill('Persen Hadir', _formatPercent(_vm.daftarRekap), const Color(0xFF0F766E)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // If there are any berhalangan reasons, show them per dosen.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildDosenAlasanList(),
        ),
      ],
    );
  }

  Widget _buildTableHeader({
    required String leftTitle,
    required String leftSubtitle,
    required List<String> rightTitles,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leftTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(leftSubtitle, style: const TextStyle(fontSize: 12, color: AppColors.graySlate)),
              ],
            ),
          ),
          ...rightTitles.map(
            (title) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.graySlate),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int v) => v.toString();

  String _formatPercent(List<dynamic> rows) {
    final totalHadir = rows.fold<int>(0, (s, r) => s + (r['hadir'] as int? ?? 0));
    final totalPertemuan = rows.fold<int>(0, (s, r) => s + (r['totalPertemuan'] as int? ?? 0));
    if (totalPertemuan <= 0) return '0.0%';
    final p = (totalHadir / totalPertemuan) * 100.0;
    return '${p.toStringAsFixed(1)}%';
  }

  Widget _statPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.graySlate)),
          ],
        ),
      ),
    );
  }

  Widget _buildDosenAlasanList() {
    if (_vm.selectedJadwal == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Pilih jadwal untuk melihat detail.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.graySlate)),
      );
    }

    final List<Map<String, dynamic>> dosenWithAlasan = _vm.daftarRekap
        .where((r) => (r['berhalangan'] as int? ?? 0) > 0 || (r['alasan'] as List?)?.isNotEmpty == true)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (dosenWithAlasan.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Tidak ada dosen yang berhalangan hadir untuk jadwal ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.graySlate)),
      );
    }

    return Column(
      children: dosenWithAlasan.map((d) {
        final nama = d['nama']?.toString() ?? '-';
        final berhalangan = d['berhalangan']?.toString() ?? '0';
        final berhalanganInt = d['berhalangan'] as int? ?? 0;
        final displayList = berhalanganInt > 0 ? List<String>.filled(berhalanganInt, 'Sakit') : <String>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      Text('Berhalangan: $berhalangan', style: const TextStyle(color: AppColors.graySlate)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...displayList.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: AppColors.graySlate),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a, style: const TextStyle(color: AppColors.graySlate))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSegment(),
            const SizedBox(height: 8),
            _buildJadwalSelector(),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedIndex == 0 ? _buildMahasiswaRekap() : _buildDosenRekap(),
            ),
          ],
        ),
      ),
    );
  }
}
 
