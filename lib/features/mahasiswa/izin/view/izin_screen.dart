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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan wajib diisi.')),
      );
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
      SnackBar(content: Text(ok ? 'Izin terkirim, menunggu approval wali.' : 'Gagal mengirim izin.')),
    );
    if (ok) {
      _keteranganCtrl.clear();
      _tabCtrl.animateTo(1);
      await _vm.loadRiwayat(widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        title: const Text('Pengajuan Izin'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.grayMedium,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Buat Baru'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildForm(),
          _buildRiwayat(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tanggal Izin', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickTanggal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 12),
                  Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_tanggal)),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Jenis', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _jenisChip('sakit', 'Sakit', Icons.healing),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _jenisChip('izin', 'Izin', Icons.event_note),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _keteranganCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Contoh: Demam tinggi, butuh istirahat',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Jadwal Terdampak', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _vm.jadwalTerdampakPreview,
            builder: (_, list, __) {
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Text('Tidak ada jadwal di tanggal tersebut.'),
                );
              }
              return Column(
                children: list.map((j) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.book_outlined),
                    title: Text(j['namaMK']?.toString() ?? '-'),
                    subtitle: Text(
                      '${j['hari']} • ${j['jamMulai']}-${j['jamSelesai']}\n'
                      'Dosen: ${j['namaDosen'] ?? j['kodeDosen'] ?? '-'} • ${j['ruangan'] ?? '-'}',
                    ),
                    isThreeLine: true,
                  ),
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          ValueListenableBuilder<bool>(
            valueListenable: _vm.isLoading,
            builder: (_, loading, __) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('AJUKAN IZIN'),
              ),
            ),
          ),

          ValueListenableBuilder<String?>(
            valueListenable: _vm.errorMessage,
            builder: (_, msg, __) => msg == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(msg, style: const TextStyle(color: Colors.red)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _jenisChip(String value, String label, IconData icon) {
    final selected = _jenis == value;
    return GestureDetector(
      onTap: () => setState(() => _jenis = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : Colors.grey,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey[700], size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                )),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Belum ada riwayat izin.', style: TextStyle(color: Colors.grey[600])),
              ],
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
    if (tgl is DateTime) tglStr = DateFormat('d MMM yyyy', 'id_ID').format(tgl);
    else if (tgl is String) {
      final p = DateTime.tryParse(tgl);
      if (p != null) tglStr = DateFormat('d MMM yyyy', 'id_ID').format(p);
    }

    Color color;
    String label;
    switch (status) {
      case 'pending_wali': color = Colors.orange; label = 'PENDING WALI'; break;
      case 'approved_wali': color = Colors.blue; label = 'DISETUJUI WALI'; break;
      case 'rejected_wali': color = Colors.red; label = 'DITOLAK WALI'; break;
      case 'closed': color = Colors.green; label = 'SELESAI'; break;
      default: color = Colors.grey; label = status.toUpperCase();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: jenis == 'sakit' ? Colors.red[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(jenis.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: jenis == 'sakit' ? Colors.red[700] : Colors.blue[700],
                      )),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tglStr, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(izin['keterangan']?.toString() ?? '-',
                style: const TextStyle(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            if (izin['catatanWali'] != null && izin['catatanWali'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Catatan wali: ${izin['catatanWali']}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
