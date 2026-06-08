import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/izin_dosen_viewmodel.dart';

class IzinDosenScreen extends StatefulWidget {
  final User user;

  const IzinDosenScreen({super.key, required this.user});

  @override
  State<IzinDosenScreen> createState() => _IzinDosenScreenState();
}

class _IzinDosenScreenState extends State<IzinDosenScreen> {
  final _vm = IzinDosenViewModel();

  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedJadwal;
  String _jenis = 'izin';
  final _keteranganController = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _selectedJadwal = null;
    });
    await _vm.loadJadwalByTanggal(widget.user.id, picked);
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedJadwal == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final success = await _vm.submitIzin(
      dosenId: widget.user.id,
      tanggal: _selectedDate!,
      jadwal: _selectedJadwal!,
      jenis: _jenis,
      keterangan: _keteranganController.text.trim(),
    );

    if (success && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Pengajuan ${_jenis == 'sakit' ? 'sakit' : 'izin'} berhasil dikirim',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal: ${_vm.errorMessage ?? 'Terjadi kesalahan'}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _selectedDate != null && _selectedJadwal != null && !_vm.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF01018B),
        elevation: 0,
        toolbarHeight: 60,
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8003),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
        ),
        title: const Text(
          'Pengajuan Izin / Sakit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Jenis Pengajuan'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _jenisCard(
                        value: 'izin',
                        label: 'Izin',
                        icon: Icons.assignment_outlined,
                        selectedColor: const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _jenisCard(
                        value: 'sakit',
                        label: 'Sakit',
                        icon: Icons.healing_outlined,
                        selectedColor: const Color(0xFF8A94A6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _label('Tanggal'),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pilihTanggal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE7E7E7),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Pilih tanggal'
                                : DateFormat(
                                    'EEEE, dd MMMM yyyy',
                                    'id_ID',
                                  ).format(_selectedDate!),
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          color: Color(0xFFD1D5DB),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _label('Mata Kuliah'),
                const SizedBox(height: 6),
                _buildMataKuliahSection(),
                const SizedBox(height: 14),
                _label('Keterangan (opsional)'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE3E3E3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF171717),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _keteranganController,
                          maxLength: 300,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Tulis keterangan tambahan jika diperlukan...',
                            hintStyle: TextStyle(
                              color: Color(0xFF8A8F9A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14, top: 6),
                          child: Text(
                            '${_keteranganController.text.length}/300',
                            style: const TextStyle(
                              color: Color(0xFFC7C9D0),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD8D8D8),
                      disabledBackgroundColor: const Color(0xFFD8D8D8),
                      foregroundColor: const Color(0xFF929292),
                      disabledForegroundColor: const Color(0xFF929292),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _vm.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(
                            'Kirim Pengajuan ${_jenis == 'sakit' ? 'Sakit' : 'Izin'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMataKuliahSection() {
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E3E3), width: 1.2),
        ),
        child: const Text(
          'Pilih tanggal terlebih dahulu',
          style: TextStyle(
            color: Color(0xFFA0A0A0),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (_vm.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vm.jadwalHariIni.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E3E3), width: 1.2),
        ),
        child: const Text(
          'Tidak ada jadwal mengajar di hari tersebut',
          style: TextStyle(
            color: Color(0xFF8A8F9A),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      children: _vm.jadwalHariIni.map((j) {
        final isSelected = _selectedJadwal == j;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: InkWell(
            onTap: () => setState(() => _selectedJadwal = isSelected ? null : j),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF9800)
                      : const Color(0xFFE4E4E4),
                  width: isSelected ? 2 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color(0xFFFF9800)
                        : const Color(0xFF9CA3AF),
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          j['namaMK'] ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas ${j['kelas'] ?? '-'} • ${j['jamMulai']} - ${j['jamSelesai']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _jenisCard({
    required String value,
    required String label,
    required IconData icon,
    required Color selectedColor,
  }) {
    final isSelected = _jenis == value;

    return GestureDetector(
      onTap: () => setState(() => _jenis = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800)
                : const Color(0xFFE3E3E3),
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? selectedColor : const Color(0xFFB0B6C2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? selectedColor : const Color(0xFF9399A4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
