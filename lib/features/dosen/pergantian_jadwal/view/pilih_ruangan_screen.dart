import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';

// -- warna lokal --
const _kNavy = Color(0xFF01018B);
const _kBg = Color(0xFFF6F6F6);
const _kWhite = Colors.white;
const _kDark = Color(0xFF1A1A1A);
const _kGrey = Color(0xFF9CA3AF);
const _kMid = Color(0xFF6B7280);
const _kBorder = Color(0xFFF3F4F6);
const _kSuccess = Color(0xFF16A34A);
const _kError = Color(0xFFDC2626);
const _kIconBg = Color(0x213434A2);

class PilihRuanganScreen extends StatelessWidget {
  final User user;
  final PergantianJadwalViewModel vm;
  final Map<String, dynamic> jadwalAsli;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;

  const PilihRuanganScreen({
    super.key,
    required this.user,
    required this.vm,
    required this.jadwalAsli,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
  });

  void _konfirmasiPilih(BuildContext context, String namaRuang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: _kSuccess,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Konfirmasi Pengajuan',
              style: TextStyle(
                color: _kDark,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan data jadwal pengganti sudah benar sebelum mengajukan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kGrey,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                children: [
                  _modalRow('Mata Kuliah', jadwalAsli['namaMK'] ?? '-'),
                  _modalRow('Kelas', jadwalAsli['kelas'] ?? '-'),
                  _modalRow('Tanggal', DateFormat('dd MMM yyyy').format(tanggal)),
                  _modalRow('Jam', '$jamMulai - $jamSelesai'),
                  _modalRow('Ruangan', namaRuang),
                  _modalRow(
                    'Status',
                    'Menunggu Persetujuan',
                    valueColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final success = await vm.ajukan(
                  user.id,
                  jadwalAsli,
                  tanggal,
                  jamMulai,
                  jamSelesai,
                  namaRuang,
                );
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhasil mengajukan ganti jadwal!'),
                      backgroundColor: _kSuccess,
                    ),
                  );
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengajukan: ${vm.errorMessage}'),
                      backgroundColor: _kError,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D01018B),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Kirim Pengajuan',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _kWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: const Text(
                  'Batalkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _kGrey,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kGrey,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _kDark,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 20),
            decoration: const BoxDecoration(
              color: _kNavy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pilih Ruangan Kosong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF6F6F6),
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kIconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: _kNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(tanggal),
                      style: const TextStyle(
                        color: _kDark,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$jamMulai - $jamSelesai',
                      style: const TextStyle(
                        color: _kGrey,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                _legendItem(_kWhite, 'Kosong', borderColor: _kBorder),
                const SizedBox(width: 20),
                _legendItem(
                  const Color(0xFFFEE2E2),
                  'Terpakai',
                  textColor: _kError,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: vm,
              builder: (context, _) {
                if (vm.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kNavy),
                  );
                }
                if (vm.daftarRuangan.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada data ruangan.',
                      style: TextStyle(
                        color: _kGrey,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: vm.daftarRuangan.length,
                  itemBuilder: (context, index) {
                    final r = vm.daftarRuangan[index];
                    final nama = r['nama'] as String;
                    final isTerpakai = r['isTerpakai'] as bool;

                    return GestureDetector(
                      onTap: isTerpakai
                          ? null
                          : () => _konfirmasiPilih(context, nama),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isTerpakai
                              ? const Color(0xFFFEE2E2)
                              : _kWhite,
                          border: Border.all(
                            color: isTerpakai
                                ? const Color(0xFFFCA5A5)
                                : _kBorder,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.room_outlined,
                              color: isTerpakai ? _kError : _kNavy,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nama,
                              style: TextStyle(
                                color: isTerpakai ? _kError : _kDark,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    Color color,
    String label, {
    Color? borderColor,
    Color? textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor ?? color, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: textColor ?? _kMid,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
