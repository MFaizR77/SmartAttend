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
    } catch (e) {
      _error = 'Gagal memuat jadwal: $e';
      _jadwal = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: const Text('Yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) await _delete(id);
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
    final hariCtl = TextEditingController(text: item['hari']?.toString() ?? '');
    final jamMulaiCtl = TextEditingController(text: item['jamMulai']?.toString() ?? '');
    final jamSelesaiCtl = TextEditingController(text: item['jamSelesai']?.toString() ?? '');
    final kodeRuanganCtl = TextEditingController(text: item['kodeRuangan']?.toString() ?? '');

    final saved = await showDialog<dynamic>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Jadwal'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: namaCtl, decoration: const InputDecoration(labelText: 'Nama MK')),
              TextField(controller: hariCtl, decoration: const InputDecoration(labelText: 'Hari')),
              Row(children: [
                Expanded(child: TextField(controller: jamMulaiCtl, decoration: const InputDecoration(labelText: 'Jam Mulai'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: jamSelesaiCtl, decoration: const InputDecoration(labelText: 'Jam Selesai'))),
              ]),
              TextField(controller: kodeRuanganCtl, decoration: const InputDecoration(labelText: 'Kode Ruangan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final data = {
                'namaMK': namaCtl.text.trim(),
                'hari': hariCtl.text.trim(),
                'jamMulai': jamMulaiCtl.text.trim(),
                'jamSelesai': jamSelesaiCtl.text.trim(),
                'kodeRuangan': kodeRuanganCtl.text.trim(),
              };
              Navigator.pop(c, data);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved is Map<String, dynamic>) {
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
      child: const Text(
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
    );
  }

  Widget _buildList() {
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _jadwal.length,
        itemBuilder: (context, i) {
          final item = _jadwal[i];
          final title = item['namaMK']?.toString() ?? item['kodeMK']?.toString() ?? 'Jadwal';
          final kelas = item['kelas']?.toString() ?? '';
          final dosen = item['namaDosen']?.toString() ?? item['kodeDosen']?.toString() ?? '';
          final waktu = '${item['hari'] ?? '-'} • ${item['jamMulai'] ?? '-'}—${item['jamSelesai'] ?? '-'}';
          final ruangan = item['ruangan']?.toString() ?? item['ruanganNama']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text('$kelas • $dosen\n$waktu\n$ruangan', maxLines: 3, overflow: TextOverflow.ellipsis),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _edit(item);
                      if (v == 'hapus') _confirmDelete(item['_id']);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildList()),
      ],
    );
  }
}
