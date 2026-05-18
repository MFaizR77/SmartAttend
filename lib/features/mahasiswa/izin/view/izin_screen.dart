import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/izin_viewmodel.dart';

/// Layar mahasiswa untuk ajukan izin/sakit + lihat riwayat.
class IzinScreen extends StatefulWidget {
  final User user;

  const IzinScreen({super.key, required this.user});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen>
    with SingleTickerProviderStateMixin {
  late final IzinViewModel _vm;
  late final TabController _tabCtrl;

  // Form state
  DateTime _tanggal = DateTime.now();
  String _jenis = 'sakit';
  final _keteranganCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = IzinViewModel();
    _tabCtrl = TabController(length: 2, vsync: this);
    _vm.previewJadwalTerdampak(user: widget.user, tanggal: _tanggal);
    _vm.loadRiwayat(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _tanggal = picked);
      _vm.previewJadwalTerdampak(user: widget.user, tanggal: picked);
    }
  }

  Future<void> _submit() async {
    if (_keteranganCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keterangan wajib diisi.')));
      return;
    }
    final ok = await _vm.submitIzin(
      user: widget.user,
      tanggalIzin: _tanggal,
      jenis: _jenis,
      keterangan: _keteranganCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Izin terkirim, menunggu approval wali.'
              : 'Gagal mengirim izin.',
        ),
      ),
    );
    if (ok) {
      _keteranganCtrl.clear();
      _tabCtrl.animateTo(1);
      await _vm.loadRiwayat(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(showBack: canPop),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [_buildForm(), _buildRiwayat()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({bool showBack = false}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Pengajuan Izin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabCtrl,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.55),
            indicatorColor: Colors.white,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Plus Jakarta Sans',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Plus Jakarta Sans',
            ),
            tabs: const [
              Tab(text: 'Buat Baru'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 8),
        ],
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 12,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tanggal Izin'),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickTanggal,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF1E3A8A),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Tanggal',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(_tanggal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Jenis Pengajuan'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _jenisChip('sakit', 'Sakit', Icons.healing_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _jenisChip('izin', 'Izin', Icons.event_note_rounded),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionTitle('Keterangan Alasan'),
          const SizedBox(height: 10),
          TextField(
            controller: _keteranganCtrl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText:
                  'Contoh: Mengalami demam tinggi, perlu istirahat total.',
              hintStyle: const TextStyle(
                color: Color(0xA06B7280),
                fontSize: 13,
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3A8A),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('Jadwal Berdampak'),
          const SizedBox(height: 10),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _vm.jadwalTerdampakPreview,
            builder: (_, list, __) {
              if (list.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFEF3C7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tidak ada jadwal kuliah terdampak di tanggal tersebut.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: list
                    .map((j) => _buildJadwalTerdampakCard(j))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 28),
          ValueListenableBuilder<bool>(
            valueListenable: _vm.isLoading,
            builder: (_, loading, __) => Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: loading
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF1E3A8A)],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: loading
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.24),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: loading ? Colors.grey : Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'AJUKAN IZIN SEKARANG',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
              ),
            ),
          ),

          ValueListenableBuilder<String?>(
            valueListenable: _vm.errorMessage,
            builder: (_, msg, __) => msg == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        msg,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalTerdampakCard(Map<String, dynamic> j) {
    final namaMK = j['namaMK']?.toString() ?? '-';
    final tipe = j['tipe']?.toString() ?? '';
    final jamMulai = j['jamMulai']?.toString() ?? '--:--';
    final jamSelesai = j['jamSelesai']?.toString() ?? '--:--';
    final dosen = j['namaDosen'] ?? j['kodeDosen'] ?? '-';
    final ruangan = j['ruangan']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: AppColors.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.class_,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipe.isNotEmpty ? '$namaMK ($tipe)' : namaMK,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14.50,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 13,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$jamMulai – $jamSelesai',
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
                        style: TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        ruangan,
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
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dosen,
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
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Absen Izin',
              style: TextStyle(
                color: Colors.red,
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

  Widget _jenisChip(String value, String label, IconData icon) {
    final selected = _jenis == value;
    final activeColor = value == 'sakit' ? Colors.red : const Color(0xFF1E3A8A);
    final activeBg = value == 'sakit'
        ? Colors.red.shade50
        : const Color(0xFFEFF6FF);

    return GestureDetector(
      onTap: () => setState(() => _jenis = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : Colors.black.withOpacity(0.08),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? activeColor : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? activeColor : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayat() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _vm.riwayat,
      builder: (_, list, __) {
        if (list.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inbox_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Riwayat Izin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Semua pengajuan izin/sakit Anda akan tercatat di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _vm.loadRiwayat(widget.user),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) => _riwayatCard(list[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: list.length,
          ),
        );
      },
    );
  }

  Widget _riwayatCard(Map<String, dynamic> izin) {
    final status = izin['status']?.toString() ?? 'pending_wali';
    final jenis = izin['jenis']?.toString() ?? 'izin';
    final tgl = izin['tanggalIzin'];
    String tglStr = '-';
    if (tgl is DateTime) {
      tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(tgl);
    } else if (tgl is String) {
      final p = DateTime.tryParse(tgl);
      if (p != null) tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(p);
    }

    Color color;
    String label;
    IconData statusIcon;
    switch (status) {
      case 'pending_wali':
        color = Colors.orange;
        label = 'PENDING WALI';
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'approved_wali':
        color = const Color(0xFF1E3A8A);
        label = 'DISETUJUI WALI';
        statusIcon = Icons.verified_user_rounded;
        break;
      case 'rejected_wali':
        color = Colors.red;
        label = 'DITOLAK WALI';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'closed':
        color = Colors.green;
        label = 'SELESAI';
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
        statusIcon = Icons.info_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: jenis == 'sakit'
                      ? Colors.red.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: jenis == 'sakit'
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      jenis == 'sakit'
                          ? Icons.healing_rounded
                          : Icons.event_note_rounded,
                      size: 14,
                      color: jenis == 'sakit'
                          ? Colors.red.shade700
                          : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jenis.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: jenis == 'sakit'
                            ? Colors.red.shade800
                            : Colors.blue.shade800,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tglStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF1B1B19),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              izin['keterangan']?.toString() ?? '-',
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF4A4A4A),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (izin['catatanWali'] != null &&
              izin['catatanWali'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.speaker_notes_rounded,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan Wali: ${izin['catatanWali']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
