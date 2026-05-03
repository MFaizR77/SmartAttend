import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/pencarian_ruang_viewmodel.dart';

class PencarianRuangScreen extends StatefulWidget {
  final User user;
  const PencarianRuangScreen({super.key, required this.user});

  @override
  State<PencarianRuangScreen> createState() => _PencarianRuangScreenState();
}

class _PencarianRuangScreenState extends State<PencarianRuangScreen> {
  final _vm = PencarianRuangViewModel();
  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.fetchJadwalDosen(widget.user.id);
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _pilihJam(BuildContext context, bool isMulai) async {
    final initialTime = isMulai 
        ? TimeOfDay(hour: int.parse(_vm.jamMulai.split(':')[0]), minute: int.parse(_vm.jamMulai.split(':')[1]))
        : TimeOfDay(hour: int.parse(_vm.jamSelesai.split(':')[0]), minute: int.parse(_vm.jamSelesai.split(':')[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isMulai) {
        _vm.setJamMulai(formattedTime);
      } else {
        _vm.setJamSelesai(formattedTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pencarian Ruang', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, child) {
          return Column(
            children: [
              _buildFilterCard(context),
              Expanded(
                child: _buildResultList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cari Ruang Kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_vm.isLoading && _vm.daftarJadwal.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (_vm.daftarJadwal.isEmpty)
            const Text('Tidak ada jadwal ditemukan', style: TextStyle(color: Colors.red))
          else
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: _vm.selectedJadwal,
                  hint: const Text('Pilih Kelas / Mata Kuliah'),
                  items: _vm.daftarJadwal.map((j) {
                    final label = '${j["namaMK"]} - Kelas ${j["kelas"]} (${j["hari"]}, ${j["jamMulai"]})';
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: j,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(label),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    _vm.setSelectedJadwal(val);
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Hari',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _vm.selectedHari,
                      items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                      onChanged: (val) {
                        if (val != null) _vm.setHari(val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pilihJam(context, true),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Jam Mulai', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    child: Text(_vm.jamMulai, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pilihJam(context, false),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Jam Selesai', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    child: Text(_vm.jamSelesai, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _vm.isLoading
                ? null
                : () {
                    if (_vm.selectedJadwal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Silakan pilih Mata Kuliah yang ingin diganti terlebih dahulu!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    _vm.cariRuangan();
                  },
            icon: _vm.isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search, color: Colors.white),
            label: Text(_vm.isLoading ? 'Mencari...' : 'Cari Ruangan', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.ruanganKosong.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Belum ada pencarian atau\ntidak ada ruang kosong ditemukan.', 
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vm.ruanganKosong.length,
      itemBuilder: (context, index) {
        final ruang = _vm.ruanganKosong[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_circle_outline, color: AppColors.success),
            ),
            title: Text(ruang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: const Text('Tersedia', style: TextStyle(color: AppColors.success)),
            trailing: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  final jadwal = _vm.selectedJadwal;
                  if (jadwal == null) return;
                  
                  final namaMK = jadwal['namaMK'] ?? '-';
                  final kelas = jadwal['kelas'] ?? '-';
                  final hariBaru = _vm.selectedHari;
                  final jamMulaiBaru = _vm.jamMulai;
                  final jamSelesaiBaru = _vm.jamSelesai;

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Konfirmasi Pergantian'),
                      content: Text('Apakah Anda yakin ingin memindahkan kelas $namaMK ($kelas) ke ruangan $ruang pada hari $hariBaru, jam $jamMulaiBaru - $jamSelesaiBaru?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Tutup dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Berhasil mengajukan pergantian $namaMK ke $ruang.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            // TODO: Implementasi simpan ke database untuk pengajuan
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Yakin', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Pilih', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ),
        );
      },
    );
  }
}
