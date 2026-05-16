import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin: assign wali dosen untuk kelas tertentu.
class AssignWaliScreen extends StatefulWidget {
  final User user;
  const AssignWaliScreen({super.key, required this.user});

  @override
  State<AssignWaliScreen> createState() => _AssignWaliScreenState();
}

class _AssignWaliScreenState extends State<AssignWaliScreen> {
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _waliList = [];
  bool _loading = false;

  // Form state
  final _kelasCtrl = TextEditingController();
  String _program = 'D3';
  String? _selectedDosenKode;
  final _passwordCtrl = TextEditingController(text: 'pass123');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _kelasCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _dosenList = await DatabaseService().getAllDosen();
      _waliList = await DatabaseService().getAllWaliDosen();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal load: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final kelas = _kelasCtrl.text.trim();
    if (kelas.isEmpty || _selectedDosenKode == null || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi semua field.')),
      );
      return;
    }
    try {
      final wali = await DatabaseService().assignWaliDosen(
        adminId: widget.user.id,
        kelas: kelas,
        program: _program,
        dosenKode: _selectedDosenKode!,
        passwordPlain: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun ${wali['_id']} dibuat. Login: ${wali['_id']} / ${_passwordCtrl.text}')),
      );
      _kelasCtrl.clear();
      setState(() => _selectedDosenKode = null);
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
      appBar: AppBar(title: const Text('Assign Wali Dosen')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Buat Akun Wali Dosen Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _kelasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kelas (mis. 2B, 1A)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _program,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'D3', child: Text('D3')),
                    DropdownMenuItem(value: 'D4', child: Text('D4')),
                  ],
                  onChanged: (v) => setState(() => _program = v ?? 'D3'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDosenKode,
                  decoration: const InputDecoration(
                    labelText: 'Dosen',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: _dosenList.map((d) {
                    return DropdownMenuItem(
                      value: d['_id']?.toString(),
                      child: Text(
                        '${d['_id']} — ${d['nama']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedDosenKode = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password wali (default pass123)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add),
                  label: const Text('Assign Wali'),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                Text('Daftar Wali Dosen (${_waliList.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._waliList.map((w) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.supervisor_account, color: AppColors.primaryBlue),
                    title: Text(w['_id']?.toString() ?? '-'),
                    subtitle: Text(
                      '${w['nama']} • Kelas ${w['kelasWali']}-${w['program']}',
                    ),
                    trailing: Text(
                      'Pass: ${w['passwordPlain'] ?? '-'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.grayMedium),
                    ),
                  ),
                )),
              ],
            ),
    );
  }
}
