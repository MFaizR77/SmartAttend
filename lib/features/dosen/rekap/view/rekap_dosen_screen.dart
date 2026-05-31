import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/models/user.dart';
import '../viewmodel/rekap_dosen_viewmodel.dart';

class RekapDosenScreen extends StatefulWidget {
  final User user;

  const RekapDosenScreen({super.key, required this.user});

  @override
  State<RekapDosenScreen> createState() => _RekapDosenScreenState();
}

class _RekapDosenScreenState extends State<RekapDosenScreen> {
  final _vm = RekapDosenViewModel();
  int _tabIndex = 0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _monthSyncedFromData = false;
  final Set<String> _expandedGroups = {};

  static const _kPrimary = Color(0xFF1A237E);
  static const _kPrimary2 = Color(0xFF3949AB);
  static const _kAccent = Color(0xFFFF8003);
  static const _kBgPage = Color(0xFFF6F6F6);
  static const _kCardBg = Colors.white;
  static const _kTextPrimary = Color(0xFF1F2937);
  static const _kTextMuted = Color(0xFF9CA3AF);
  static const _kSuccess = Color(0xFF43A047);
  static const _kWarning = Color(0xFFFBC02D);
  static const _kDanger = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _vm.loadRekap(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allReports {
    final items = <Map<String, dynamic>>[];
    for (final entry in _vm.rekapPerKelas.entries) {
      items.addAll(entry.value);
    }
    items.sort((a, b) {
      final aDate = _asDateTime(a['tanggal']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _asDateTime(b['tanggal']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return items;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime? _monthOf(dynamic value) {
    final date = _asDateTime(value);
    if (date == null) return null;
    return DateTime(date.year, date.month, 1);
  }

  String _monthLabel(DateTime month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];
    final index = month.month - 1;
    if (index >= 0 && index < months.length) return months[index];
    return DateFormat('MMM', 'id').format(month);
  }

  String _monthFullLabel(DateTime month) {
    return DateFormat('MMMM yyyy', 'id').format(month);
  }

  void _syncMonthFromDataIfNeeded() {
    if (_monthSyncedFromData) return;
    if (_vm.isLoading) return;

    final latest = _allReports.firstWhere(
      (item) => _asDateTime(item['tanggal']) != null,
      orElse: () => <String, dynamic>{},
    );
    final latestDate = _asDateTime(latest['tanggal']);
    if (latestDate != null) {
      _monthSyncedFromData = true;
      _selectedMonth = DateTime(latestDate.year, latestDate.month, 1);
    }
  }

  List<Map<String, dynamic>> _filteredReports() {
    return _allReports.where((laporan) {
      final month = _monthOf(laporan['tanggal']);
      if (month == null) return false;
      return month.year == _selectedMonth.year && month.month == _selectedMonth.month;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _filteredGroups() {
    final filtered = _filteredReports();
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final laporan in filtered) {
      final groupName = (laporan['namaJadwal'] ?? 'Mata Kuliah').toString();
      grouped.putIfAbsent(groupName, () => []);
      grouped[groupName]!.add(laporan);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final aDate = _asDateTime(a['tanggal']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = _asDateTime(b['tanggal']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    }

    return grouped;
  }

  int _countSynced(List<Map<String, dynamic>> items) {
    return items.where((item) => (item['syncStatus']?.toString() ?? 'synced') == 'synced').length;
  }

  int _countPending(List<Map<String, dynamic>> items) {
    return items.where((item) => (item['syncStatus']?.toString() ?? '') == 'pending').length;
  }

  int _countFailed(List<Map<String, dynamic>> items) {
    return items.where((item) => (item['syncStatus']?.toString() ?? '') == 'failed').length;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return '✓ Synced';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return _kWarning;
      case 'failed':
        return _kDanger;
      default:
        return _kSuccess;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'failed':
        return const Color(0xFFFCE4EC);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        if (_vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimary),
          );
        }

        if (_vm.errorMessage != null) {
          return Center(
            child: Text(
              _vm.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        _syncMonthFromDataIfNeeded();

        final reports = _filteredReports();
        final groups = _filteredGroups();
        final totalSessions = reports.length;
        final totalMatkul = groups.length;
        final pending = _countPending(reports);
        final synced = _countSynced(reports);
        final failed = _countFailed(reports);
        final percentSynced = totalSessions == 0 ? 0.0 : synced / totalSessions;
        final percentPending = totalSessions == 0 ? 0.0 : pending / totalSessions;
        final percentFailed = totalSessions == 0 ? 0.0 : failed / totalSessions;

        return Column(
          children: [
            _buildHeader(totalSessions: totalSessions, totalMatkul: totalMatkul, pending: pending),
            _buildTabBar(),
            _buildMonthChips(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _tabIndex == 0
                    ? _buildRiwayatTab(reports)
                    : _tabIndex == 1
                        ? _buildPerKelasTab(groups)
                        : _buildRekapTab(
                            totalSessions: totalSessions,
                            synced: synced,
                            pending: pending,
                            failed: failed,
                            percentSynced: percentSynced,
                            percentPending: percentPending,
                            percentFailed: percentFailed,
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader({
    required int totalSessions,
    required int totalMatkul,
    required int pending,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimary2],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 40,
            child: Center(
              child: Text(
                'Rekap Mengajar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _statBox('$totalSessions', 'Sesi')),
              const SizedBox(width: 10),
              Expanded(child: _statBox('$totalMatkul', 'Matkul')),
              const SizedBox(width: 10),
              Expanded(child: _statBox('$pending', 'Pending')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const labels = ['Riwayat', 'Per Kelas', 'Rekap'];
    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _tabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? _kPrimary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? _kPrimary : const Color(0xFF9CA3AF),
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthChips() {
    final months = [1, 2, 3, 4, 5, 6].map((m) => DateTime(_selectedMonth.year, m, 1)).toList();
    return Container(
      color: _kBgPage,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final month in months) ...[
              _monthChip(month),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthChip(DateTime month) {
    final selected = month.month == _selectedMonth.month;
    return GestureDetector(
      onTap: () => setState(() => _selectedMonth = month),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Text(
          _monthLabel(month),
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF757575),
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatTab(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return _emptyState('Belum ada sesi pada bulan ini');
    }

    final syncBreakdown = {
      'synced': _countSynced(reports),
      'pending': _countPending(reports),
      'failed': _countFailed(reports),
    };

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => _vm.loadRekap(widget.user),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          _rekapBarCard(reports, syncBreakdown),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              'RIWAYAT SESI MENGAJAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9CA3AF),
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final laporan in reports) _buildLogItem(laporan),
        ],
      ),
    );
  }

  Widget _rekapBarCard(
    List<Map<String, dynamic>> reports,
    Map<String, int> syncBreakdown,
  ) {
    final total = reports.isEmpty ? 1 : reports.length;
    final synced = syncBreakdown['synced'] ?? 0;
    final pending = syncBreakdown['pending'] ?? 0;
    final failed = syncBreakdown['failed'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rekap ${_monthFullLabel(_selectedMonth)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                Expanded(flex: synced, child: Container(height: 8, color: _kSuccess)),
                Expanded(flex: pending, child: Container(height: 8, color: _kWarning)),
                Expanded(flex: failed, child: Container(height: 8, color: _kDanger)),
                if (synced + pending + failed == 0)
                  Expanded(child: Container(height: 8, color: const Color(0xFFF0F0F0))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _legendItem(_kSuccess, 'Terlaksana ${reports.isEmpty ? 0 : ((synced / total) * 100).round()}%'),
              _legendItem(_kWarning, 'Pending ${reports.isEmpty ? 0 : ((pending / total) * 100).round()}%'),
              _legendItem(_kDanger, 'Failed ${reports.isEmpty ? 0 : ((failed / total) * 100).round()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF616161),
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(Map<String, dynamic> laporan) {
    final tanggal = _asDateTime(laporan['tanggal']);
    if (tanggal == null) return const SizedBox.shrink();

    final jamMulai = _asDateTime(laporan['waktuMulai']);
    final jamSelesai = _asDateTime(laporan['waktuSelesai']);
    final materi = (laporan['materi'] ?? 'Tidak ada materi').toString();
    final status = (laporan['syncStatus']?.toString() ?? 'synced');
    final namaJadwal = (laporan['namaJadwal'] ?? 'Mata Kuliah').toString();
    final ruangan = (laporan['ruangan'] ?? laporan['kelas'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(tanggal),
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Text(
                  DateFormat('MMM', 'id').format(tanggal).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 12), color: const Color(0xFFF0F0F0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaJadwal,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(jamMulai)} – ${_formatTime(jamSelesai)}${ruangan.isNotEmpty ? ' · $ruangan' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextMuted,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    materi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3949AB),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusBg(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _statusColor(status),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerKelasTab(Map<String, List<Map<String, dynamic>>> groups) {
    if (groups.isEmpty) {
      return _emptyState('Belum ada sesi pada bulan ini');
    }

    final entries = groups.entries.toList();
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => _vm.loadRekap(widget.user),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          for (final entry in entries) _buildKelasCard(entry.key, entry.value),
        ],
      ),
    );
  }

  Widget _buildKelasCard(String groupName, List<Map<String, dynamic>> list) {
    final first = list.isNotEmpty ? list.first : <String, dynamic>{};
    final isExpanded = _expandedGroups.contains(groupName);
    final matkul = groupName.split(' - ').first;
    final kelas = groupName.contains(' - ') ? groupName.split(' - ').skip(1).join(' - ') : '';
    final jamMulai = _formatTime(_asDateTime(first['waktuMulai']));
    final jamSelesai = _formatTime(_asDateTime(first['waktuSelesai']));
    final ruangan = (first['ruangan'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(groupName);
                } else {
                  _expandedGroups.add(groupName);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3434A2).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_outlined, color: _kPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matkul,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${kelas.isNotEmpty ? 'Kelas $kelas' : 'Kelas'} · ${jamMulai.isNotEmpty ? '$jamMulai – $jamSelesai' : 'Belum ada jam'}${ruangan.isNotEmpty ? ' · $ruangan' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kTextMuted,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${list.length} Sesi',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (int i = 0; i < list.length; i++) _buildPertemuanRow(i + 1, list[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPertemuanRow(int index, Map<String, dynamic> laporan) {
    final tanggal = _asDateTime(laporan['tanggal']);
    final status = (laporan['syncStatus']?.toString() ?? 'synced');
    final materi = (laporan['materi'] ?? 'Tidak ada materi').toString();
    final jamMulai = _formatTime(_asDateTime(laporan['waktuMulai']));
    final jamSelesai = _formatTime(_asDateTime(laporan['waktuSelesai']));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF3434A2).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tanggal == null
                      ? '-'
                      : '${DateFormat('dd MMM yyyy', 'id').format(tanggal)} · ${DateFormat('EEEE', 'id').format(tanggal)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$jamMulai – $jamSelesai (100 menit)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _kTextMuted,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  materi,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3949AB),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Detail',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekapTab({
    required int totalSessions,
    required int synced,
    required int pending,
    required int failed,
    required double percentSynced,
    required double percentPending,
    required double percentFailed,
  }) {
    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => _vm.loadRekap(widget.user),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
        children: [
          _summaryCard(totalSessions: totalSessions, synced: synced, pending: pending, failed: failed),
          const SizedBox(height: 14),
          _percentCard('Terlaksana', percentSynced, _kSuccess),
          _percentCard('Pending', percentPending, _kWarning),
          _percentCard('Failed', percentFailed, _kDanger),
          const SizedBox(height: 2),
          _syncStatusCard(synced: synced, pending: pending, failed: failed),
          const SizedBox(height: 12),
          _downloadButton(),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int totalSessions,
    required int synced,
    required int pending,
    required int failed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimary2],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekap Mengajar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_monthFullLabel(_selectedMonth)} · ${widget.user.nama}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumItem('$totalSessions', 'Total Sesi', const Color(0xFF69F0AE)),
              _sumItem('$synced', 'Terlaksana', Colors.white),
              _sumItem('$pending', 'Pending', const Color(0xFFFFD740)),
              _sumItem('$failed', 'Failed', const Color(0xFFFF5252)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _percentCard(String label, double percent, Color color) {
    final percentText = '${(percent * 100).round()}%';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  percentText,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncStatusCard({required int synced, required int pending, required int failed}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Sinkronisasi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kTextPrimary,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 10),
          _statusRow(_kSuccess, 'Synced', synced),
          _statusRow(_kWarning, 'Pending', pending),
          _statusRow(_kDanger, 'Failed', failed),
        ],
      ),
    );
  }

  Widget _statusRow(Color color, String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          Text(
            '$count Sesi',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimary2],
        ),
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unduh rekap belum dihubungkan ke export file.')),
          );
        },
        icon: const Icon(Icons.download_outlined, color: Colors.white),
        label: const Text(
          'Unduh Rekap (.xlsx)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_edu, size: 78, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: _kTextMuted,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime);
  }
}
