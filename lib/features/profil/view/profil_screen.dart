import 'package:flutter/material.dart';
import '../../../../data/local/models/user.dart';

class ProfilScreen extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const ProfilScreen({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(user.nama);

    return Container(
      color: const Color(0xFFF6F6F6),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.16, -0.45),
                end: Alignment(0.84, 1.45),
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF283593),
                  Color(0xFF3949AB),
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              'Profil ${user.roleLabel}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                letterSpacing: 0.30,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  _buildAvatarSection(initials),
                  const SizedBox(height: 12),
                  _buildSectionLabel('AKUN'),
                  const SizedBox(height: 10),
                  _buildCard(
                    children: [
                      _buildActionRow(
                        icon: Icons.photo_camera_outlined,
                        iconBg: const Color(0xFFE8EAF6),
                        title: 'Edit Foto Profil',
                        subtitle: 'Ubah foto tampilan profil',
                        onTap: () => _showComingSoon(context),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        icon: Icons.edit_outlined,
                        iconBg: const Color(0xFFE3F2FD),
                        title: 'Edit Nama',
                        subtitle: user.nama,
                        onTap: () => _showComingSoon(context),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        icon: Icons.lock_outline,
                        iconBg: const Color(0xFFFCE4EC),
                        title: 'Ganti Password',
                        subtitle: 'Terakhir diubah 30 hari lalu',
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('INFORMASI'),
                  const SizedBox(height: 10),
                  _buildCard(
                    children: [
                      _buildInfoRow(
                        icon: Icons.school_outlined,
                        iconBg: const Color(0xFFE8F5E9),
                        title: 'Program Studi',
                        subtitle: user.kelas?.isNotEmpty == true
                            ? user.kelas!
                            : 'Teknik Informatika',
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.event_note_outlined,
                        iconBg: const Color(0xFFFFF8E1),
                        title: 'ID / NIM',
                        subtitle: user.id,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        iconBg: const Color(0xFFE0F2F1),
                        title: 'Email',
                        subtitle: user.email.isNotEmpty
                            ? user.email
                            : '${user.id.toLowerCase()}@polban.ac.id',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCard(
                    children: [
                      _buildActionRow(
                        icon: Icons.logout_rounded,
                        iconBg: const Color(0xFFFBE9E7),
                        title: 'Keluar',
                        subtitle: 'Akhiri sesi saat ini',
                        titleColor: const Color(0xFFE53935),
                        onTap: onLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SmartAttend v1.0.0',
                    style: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 11,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String initials) {
    return Column(
      children: [
        Container(
          width: 92,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8003),
            borderRadius: BorderRadius.circular(46),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
              ),
              borderRadius: BorderRadius.circular(43),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFFF6F6F6),
                      fontSize: 28,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3949AB),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          width: 2,
                          color: const Color(0xFFFF8003),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          user.nama,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontSize: 18,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'NIM: ${user.id}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.roleLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF3949AB),
              fontSize: 11,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFF0F0F0));
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF212121),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconBox(icon, iconBg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIconBox(icon, iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 14,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color bgColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF3949AB)),
    );
  }

  String _initials(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts[0].substring(0, 1);
    final second = parts[1].substring(0, 1);
    return '$first$second'.toUpperCase();
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini belum tersedia'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
