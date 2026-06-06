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
            'Belum ada rekap untuk jadwal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.graySlate),
          ),
        ),
      );
    }

    final totalHadir = _vm.daftarRekap.fold<int>(0, (s, r) => s + (r['hadir'] as int? ?? 0));
    final totalIzin = _vm.daftarRekap.fold<int>(0, (s, r) => s + (r['izin'] as int? ?? 0));
    final totalAlpha = _vm.daftarRekap.fold<int>(0, (s, r) => s + (r['alpha'] as int? ?? 0));
    final totalPertemuan = (_vm.daftarRekap.isNotEmpty)
        ? (_vm.daftarRekap.first['totalPertemuan'] as int? ?? 0)
        : 0;
    final jumlahMhs = _vm.daftarRekap.length;
    final avgPersen = jumlahMhs > 0
        ? _vm.daftarRekap.fold<double>(0, (s, r) => s + (r['persenHadir'] as double? ?? 0.0)) / jumlahMhs
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        // ── Summary Banner ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Ringkasan · $totalPertemuan Pertemuan · $jumlahMhs Mahasiswa',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _statPill('Hadir', totalHadir.toString(), AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  _statPill('Izin', totalIzin.toString(), const Color(0xFF0F766E)),
                  const SizedBox(width: 8),
                  _statPill('Alpha', totalAlpha.toString(), const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  _statPill('Avg %', '${avgPersen.toStringAsFixed(1)}%', const Color(0xFFB45309)),
                ]),
              ],
            ),
          ),
        ),

        // ── Table Header ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Mahasiswa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              SizedBox(
                width: 40,
                child: Text('Hadir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.graySlate), textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 36,
                child: Text('Izin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.graySlate), textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 44,
                child: Text('Alpha', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.graySlate), textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 50,
                child: Text('%Hadir', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.graySlate), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── Rows ─────────────────────────────────────────────────────────────
        ..._vm.daftarRekap.map((r) {
          final hadir = r['hadir'] as int? ?? 0;
          final izin = r['izin'] as int? ?? 0;
          final alpha = r['alpha'] as int? ?? 0;
          final persen = r['persenHadir'] as double? ?? 0.0;
          final persenColor = persen >= 75
              ? AppColors.primaryBlue
              : persen >= 50
                  ? const Color(0xFFB45309)
                  : const Color(0xFFDC2626);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['nama']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          r['nim']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 11, color: AppColors.graySlate),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('$hadir', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('$izin', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('$alpha', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text('${persen.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: TextStyle(color: persenColor, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
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
    if (_vm.daftarRekap.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Belum ada rekap dosen untuk jadwal ini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.graySlate),
          ),
        ),
      );
    }

    final totalHadir = _vm.daftarRekap.fold<int>(0, (s, r) => s + (r['hadir'] as int? ?? 0));
    final totalBerhalangan = _vm.daftarRekap.fold<int>(0, (s, r) => s + (r['berhalangan'] as int? ?? 0));
    final avgPersen = _vm.daftarRekap.isNotEmpty
        ? _vm.daftarRekap.fold<double>(0, (s, r) => s + (r['persenHadir'] as double? ?? 0.0)) / _vm.daftarRekap.length
        : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        const SizedBox(height: 8),
        _buildSelectedJadwalSummary(),
        const SizedBox(height: 10),

        // ── Summary ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _statPill('Hadir', totalHadir.toString(), AppColors.primaryBlue),
              const SizedBox(width: 8),
              _statPill('Berhalangan', totalBerhalangan.toString(), const Color(0xFFB45309)),
              const SizedBox(width: 8),
              _statPill('Avg %', '${avgPersen.toStringAsFixed(1)}%', const Color(0xFF0F766E)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── List dosen ────────────────────────────────────────────────────────
        ..._vm.daftarRekap.map((d) {
          final hadir = d['hadir'] as int? ?? 0;
          final berhalangan = d['berhalangan'] as int? ?? 0;
          final totalPertemuan = d['totalPertemuan'] as int? ?? 0;
          final persen = d['persenHadir'] as double? ?? 0.0;
          final alasanList = (d['alasan'] as List?)?.cast<String>() ?? [];
          final persenColor = persen >= 75
              ? AppColors.primaryBlue
              : persen >= 50
                  ? const Color(0xFFB45309)
                  : const Color(0xFFDC2626);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d['nama']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${persen.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: persenColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${d['dosenId'] ?? '-'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.graySlate),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniStat('Hadir', '$hadir', AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      _miniStat('Berhalangan', '$berhalangan', const Color(0xFFB45309)),
                      const SizedBox(width: 8),
                      _miniStat('Total Pertemuan', '$totalPertemuan', AppColors.graySlate),
                    ],
                  ),
                  if (alasanList.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Keterangan Izin:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    ...alasanList.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.graySlate),
                              const SizedBox(width: 6),
                              Expanded(child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.graySlate))),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.graySlate), textAlign: TextAlign.center),
          ],
        ),
      ),
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
 
