import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/remote/database_service.dart';

class ManajemenJadwalScreen extends StatefulWidget {
  const ManajemenJadwalScreen({super.key});

  @override
  State<ManajemenJadwalScreen> createState() => _ManajemenJadwalScreenState();
}

class _ManajemenJadwalScreenState extends State<ManajemenJadwalScreen> {
  final _db = DatabaseService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jadwal = [];
  String? _selectedHari;

  static const List<String> _hariOrder = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _jadwal = await _db.getAllJadwalAdmin();
      final days = _groupByHari().map((e) => e.key).toList();
      if (days.isNotEmpty && (_selectedHari == null || !days.contains(_selectedHari))) {
        final today = _hariOrder[DateTime.now().weekday - 1];
        _selectedHari = days.contains(today) ? today : days.first;
      }
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
      _jadwal = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Kelompokkan jadwal per hari (urut Senin→Minggu), tiap grup diurutkan jam mulai.
  List<MapEntry<String, List<Map<String, dynamic>>>> _groupByHari() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final j in _jadwal) {
      final hari = (j['hari']?.toString().trim().isNotEmpty ?? false)
          ? j['hari'].toString().trim()
          : 'Lainnya';
      map.putIfAbsent(hari, () => []).add(j);
    }
    for (final list in map.values) {
      list.sort((a, b) => (a['jamMulai']?.toString() ?? '')
          .compareTo(b['jamMulai']?.toString() ?? ''));
    }

    final result = <MapEntry<String, List<Map<String, dynamic>>>>[];
    for (final hari in _hariOrder) {
      if (map.containsKey(hari)) result.add(MapEntry(hari, map[hari]!));
    }
    // Hari di luar Senin-Minggu (mis. 'Lainnya') ditaruh paling akhir.
    for (final entry in map.entries) {
      if (!_hariOrder.contains(entry.key)) result.add(entry);
    }
    return result;
  }

  // ── Helper waktu ──────────────────────────────────────────────────────────
  TimeOfDay? _parseTime(String s) {
    final parts = s.split(RegExp(r'[:.]'));
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── CRUD ────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final nama = item['namaMK']?.toString() ?? item['kodeMK']?.toString() ?? 'jadwal ini';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Jadwal'),
        content: Text('Yakin ingin menghapus "$nama"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) await _delete(item['_id']);
  }

  Future<void> _delete(dynamic id) async {
    try {
      await _db.deleteJadwal(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final namaCtl = TextEditingController(text: item['namaMK']?.toString() ?? '');
    final ruanganCtl = TextEditingController(text: item['kodeRuangan']?.toString() ?? '');
    String hari = item['hari']?.toString() ?? 'Senin';
    if (!_hariOrder.contains(hari)) hari = 'Senin';
    String jamMulai = item['jamMulai']?.toString() ?? '';
    String jamSelesai = item['jamSelesai']?.toString() ?? '';

    final kelas = item['kelas']?.toString() ?? '-';
    final dosen = item['namaDosen']?.toString() ?? item['kodeDosen']?.toString() ?? '-';

    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) {
          Future<void> pickTime(bool mulai) async {
            final initial = _parseTime(mulai ? jamMulai : jamSelesai) ??
                const TimeOfDay(hour: 7, minute: 0);
            final picked = await showTimePicker(
              context: c,
              initialTime: initial,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                child: child!,
              ),
            );
            if (picked != null) {
              setLocal(() {
                if (mulai) {
                  jamMulai = _fmtTime(picked);
                } else {
                  jamSelesai = _fmtTime(picked);
                }
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Edit Jadwal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Konteks (read-only)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kelas $kelas  •  $dosen',
                        style: const TextStyle(fontSize: 12, color: AppColors.graySlate, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: namaCtl,
                      decoration: _dec('Nama Mata Kuliah', Icons.menu_book_rounded),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: hari,
                      isExpanded: true,
                      decoration: _dec('Hari', Icons.today_rounded),
                      items: _hariOrder
                          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                          .toList(),
                      onChanged: (v) => setLocal(() => hari = v ?? hari),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _timeField('Jam Mulai', jamMulai, () => pickTime(true))),
                        const SizedBox(width: 12),
                        Expanded(child: _timeField('Jam Selesai', jamSelesai, () => pickTime(false))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ruanganCtl,
                      decoration: _dec('Kode Ruangan', Icons.meeting_room_rounded),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                onPressed: () {
                  Navigator.pop(c, {
                    'namaMK': namaCtl.text.trim(),
                    'hari': hari,
                    'jamMulai': jamMulai.trim(),
                    'jamSelesai': jamSelesai.trim(),
                    'kodeRuangan': ruanganCtl.text.trim(),
                  });
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != null) {
      try {
        await _db.updateJadwal(item['_id'], saved);
        if (!mounted) return;
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal disimpan')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
      }
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.graySlate),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E4EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
        ),
      );

  Widget _timeField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _dec(label, Icons.schedule_rounded),
        child: Text(
          value.isEmpty ? '--:--' : value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: value.isEmpty ? AppColors.grayLight : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────
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
            'Manajemen\nJadwal',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
          if (!_loading && _error == null && _jadwal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_jadwal.length} jadwal • ${_groupByHari().length} hari',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final grouped = _groupByHari();
    if (grouped.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: grouped.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final hari = grouped[i].key;
          final count = grouped[i].value.length;
          final selected = hari == _selectedHari;
          return GestureDetector(
            onTap: () => setState(() => _selectedHari = hari),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.border),
              ),
              child: Text(
                '$hari ($count)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.graySlate,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final title = item['namaMK']?.toString() ?? item['kodeMK']?.toString() ?? 'Jadwal';
    final kelas = item['kelas']?.toString() ?? '';
    final dosen = item['namaDosen']?.toString() ?? item['kodeDosen']?.toString() ?? '';
    final jamMulai = item['jamMulai']?.toString() ?? '--:--';
    final jamSelesai = item['jamSelesai']?.toString() ?? '--:--';
    final ruangan = item['ruangan']?.toString() ?? item['ruanganNama']?.toString() ?? item['kodeRuangan']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom waktu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(jamMulai, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                  Container(
                    width: 14,
                    height: 1.4,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.grayLight,
                  ),
                  Text(jamSelesai, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.graySlate)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (kelas.isNotEmpty) _tag(Icons.groups_rounded, kelas),
                      if (ruangan.isNotEmpty) _tag(Icons.meeting_room_rounded, ruangan),
                    ],
                  ),
                  if (dosen.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 14, color: AppColors.graySlate),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(dosen,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.graySlate)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Aksi
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.graySlate),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'edit') _edit(item);
                if (v == 'hapus') _confirmDelete(item);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 10), Text('Edit')]),
                ),
                PopupMenuItem(
                  value: 'hapus',
                  child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), SizedBox(width: 10), Text('Hapus', style: TextStyle(color: AppColors.error))]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.graySlate),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.graySlate)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_jadwal.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.calendar_month, size: 80, color: AppColors.border),
            SizedBox(height: 16),
            Text('Belum ada jadwal', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    final grouped = _groupByHari();
    if (grouped.isEmpty) return const SizedBox.shrink();
    final entry = grouped.firstWhere(
      (e) => e.key == _selectedHari,
      orElse: () => grouped.first,
    );
    final list = entry.value;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              '${entry.key} — ${list.length} mata kuliah',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
          ),
          ...list.map(_buildCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        if (!_loading && _error == null && _jadwal.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDaySelector(),
          const SizedBox(height: 4),
        ],
        Expanded(child: _buildBody()),
      ],
    );
  }
}
