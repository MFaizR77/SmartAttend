import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin: list periode akademik + tombol aktivasi + tombol buat baru.
class ManajemenPeriodeScreen extends StatefulWidget {
  final User user;
  const ManajemenPeriodeScreen({super.key, required this.user});

  @override
  State<ManajemenPeriodeScreen> createState() => _ManajemenPeriodeScreenState();
}

class _ManajemenPeriodeScreenState extends State<ManajemenPeriodeScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _list = await DatabaseService().getAllPeriode();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aktivasi(String kode) async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan periode?'),
        content: Text('Periode "$kode" akan jadi aktif. Periode lain otomatis non-aktif.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aktifkan')),
        ],
      ),
    );
    if (konfirm != true) return;
    try {
      await DatabaseService().setAktifPeriode(kode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Periode "$kode" diaktifkan.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _buatBaru() async {
    final tahunCtrl = TextEditingController();
    String jenis = 'Ganjil';

    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Buat Periode Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tahunCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tahun ajaran (mis. 2026/2027)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: jenis,
                decoration: const InputDecoration(
                  labelText: 'Jenis',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                  DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                ],
                onChanged: (v) => setStateDialog(() => jenis = v ?? 'Ganjil'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: tahunCtrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
    if (konfirm != true) return;
    final tahun = tahunCtrl.text.trim();
    final tahunNorm = tahun.replaceAll('/', '-');
    final kode = '$tahunNorm-$jenis';
    try {
      await DatabaseService().createPeriode(
        kode: kode,
        tahunAjaran: tahun,
        jenis: jenis,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Periode "$kode" dibuat (non-aktif).')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        title: const Text('Manajemen Periode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buatBaru,
        icon: const Icon(Icons.add),
        label: const Text('Periode Baru'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _list[i];
                  final aktif = p['aktif'] == true;
                  return Card(
                    color: aktif ? Colors.green[50] : null,
                    child: ListTile(
                      leading: Icon(
                        aktif ? Icons.check_circle : Icons.circle_outlined,
                        color: aktif ? Colors.green : Colors.grey,
                      ),
                      title: Text(p['kode']?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${p['tahunAjaran']} • ${p['jenis']}'
                        '${aktif ? "  (AKTIF)" : ""}',
                      ),
                      trailing: aktif
                          ? const Chip(
                              label: Text('AKTIF', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          : OutlinedButton(
                              onPressed: () => _aktivasi(p['kode']?.toString() ?? ''),
                              child: const Text('Aktifkan'),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
