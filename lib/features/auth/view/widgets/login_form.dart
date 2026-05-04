import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Form login reusable dengan desain baru (retro style).
/// Hanya UI — logika login dipanggil via callback [onLogin].
class LoginForm extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final void Function(String identifier, String password) onLogin;

  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onLogin,
    this.errorMessage,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onLogin(_identifierController.text.trim(), _passwordController.text);
  }

  // ── Shared border decoration ──────────────────────────────────────
  OutlineInputBorder _border({Color color = AppColors.grayDark}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(width: 2, color: color),
      );

  // ── Shared label style ────────────────────────────────────────────
  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 12,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 1.20,
  );

  // ── Shared hint / input style ─────────────────────────────────────
  static const TextStyle _hintStyle = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 16,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
  );

  static const TextStyle _inputStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 16,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── USERNAME ─────────────────────────────────────────────
          const Text('USERNAME', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            style: _inputStyle,
            decoration: InputDecoration(
              hintText: 'Masukkan username',
              hintStyle: _hintStyle,
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.grayDark,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: _border(),
              focusedBorder: _border(),
              errorBorder: _border(color: Colors.red),
              focusedErrorBorder: _border(color: Colors.red),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // ── PASSWORD ─────────────────────────────────────────────
          const Text('PASSWORD', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: _inputStyle,
            decoration: InputDecoration(
              hintText: 'Masukkan password',
              hintStyle: _hintStyle,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: AppColors.grayDark,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.grayDark,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: _border(),
              focusedBorder: _border(),
              errorBorder: _border(color: Colors.red),
              focusedErrorBorder: _border(color: Colors.red),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),
          // ── Pesan error ───────────────────────────────────────────
          if (widget.errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Spasi panjang untuk menekan tombol ke bawah
          const SizedBox(height: 60),

          // ── Tombol MASUK ─────────────────────────────────────────
          GestureDetector(
            onTap: widget.isLoading ? null : _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: ShapeDecoration(
                color: widget.isLoading
                    ? AppColors.primaryBlue.withValues(alpha: 0.55)
                    : AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.charcoal,
                        ),
                      )
                    : const Text(
                        'MASUK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: 16,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          height: 1.50,
                          letterSpacing: 1.60,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
