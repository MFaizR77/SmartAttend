import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';

/// Form login dengan dropdown role (mahasiswa/dosen/walidosen/admin).
class LoginForm extends StatefulWidget {
  final bool isLoading;
  final String? errorMessage;
  final void Function(AccountType accountType, String identifier, String password) onLogin;
  final AccountType initialRole;

  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onLogin,
    this.errorMessage,
    this.initialRole = AccountType.mahasiswa,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AccountType _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onLogin(
      _selectedRole,
      _identifierController.text.trim(),
      _passwordController.text,
    );
  }

  String _hintForRole(AccountType r) {
    switch (r) {
      case AccountType.mahasiswa: return 'Masukkan NIM';
      case AccountType.dosen: return 'Masukkan kode dosen (mis. KO009N)';
      case AccountType.walidosen: return 'Masukkan kode wali dosen (mis. WD_KO071N_2B_D3)';
      case AccountType.admin: return 'Masukkan kode admin';
    }
  }

  String _labelForRole(AccountType r) {
    switch (r) {
      case AccountType.mahasiswa: return 'Mahasiswa';
      case AccountType.dosen: return 'Dosen';
      case AccountType.walidosen: return 'Wali Dosen';
      case AccountType.admin: return 'Admin';
    }
  }

  // ── Shared border ──────────────────────────────────────────────────
  OutlineInputBorder _border({Color color = AppColors.grayDark}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(width: 2, color: color),
      );

  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 12,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 1.20,
  );

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
          // ── ROLE SELECTOR ────────────────────────────────────────
          const Text('LOGIN SEBAGAI', style: _labelStyle),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(width: 2, color: AppColors.grayDark),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AccountType>(
                isExpanded: true,
                value: _selectedRole,
                style: _inputStyle,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.grayDark),
                items: AccountType.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(_iconForRole(role), size: 20, color: AppColors.grayDark),
                        const SizedBox(width: 12),
                        Text(_labelForRole(role)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: widget.isLoading
                    ? null
                    : (v) {
                        if (v != null) setState(() => _selectedRole = v);
                      },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── USERNAME ─────────────────────────────────────────────
          const Text('USERNAME', style: _labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            style: _inputStyle,
            decoration: InputDecoration(
              hintText: _hintForRole(_selectedRole),
              hintStyle: _hintStyle,
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AppColors.grayDark,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: _border(),
              focusedBorder: _border(),
              errorBorder: _border(color: Colors.red),
              focusedErrorBorder: _border(color: Colors.red),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Username tidak boleh kosong' : null,
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
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.grayDark,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: _border(),
              focusedBorder: _border(),
              errorBorder: _border(color: Colors.red),
              focusedErrorBorder: _border(color: Colors.red),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password tidak boleh kosong' : null,
          ),

          const SizedBox(height: 16),
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

          const SizedBox(height: 40),

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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  IconData _iconForRole(AccountType r) {
    switch (r) {
      case AccountType.mahasiswa: return Icons.school_outlined;
      case AccountType.dosen: return Icons.person_outline;
      case AccountType.walidosen: return Icons.supervisor_account_outlined;
      case AccountType.admin: return Icons.admin_panel_settings_outlined;
    }
  }
}
