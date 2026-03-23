// lib/views/auth/login_view.dart
// Redesigned: dark teal gradient header + clean white form card.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_theme.dart';
import 'signup_view.dart';
import 'forgot_password.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailCont = TextEditingController();
  final passCont  = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;

  @override
  void dispose() {
    emailCont.dispose();
    passCont.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3D3D), Color(0xFF1B5F5F), Color(0xFF2D8B8B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _BackBtn(onTap: () => Navigator.pop(context)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome\nback.',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.1,
                        )),
                    const SizedBox(height: 12),
                    Text('Sign in to continue your health journey',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),

              // ── Form Card ───────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Consumer<AuthController>(
                        builder: (context, auth, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuthField(
                              controller: emailCont,
                              label: 'Email Address',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email is required';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(
                              controller: passCont,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscure,
                              suffixIcon: _VisToggle(
                                  obscure: _obscure,
                                  onTap: () => setState(() => _obscure = !_obscure)),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password is required';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary),
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordView())),
                                child: Text('Forgot Password?',
                                    style: AppTextStyles.bodySmall().copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Error
                            if (auth.status.isNotEmpty) ...[
                              _AuthErrorBox(message: auth.status),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Login button
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState!.validate()) {
                                          auth.login(emailCont.text.trim(),
                                              passCont.text.trim(), context);
                                        }
                                      },
                                child: auth.isLoading
                                    ? const SizedBox(height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : Text('Sign In', style: AppTextStyles.buttonPrimary()),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Divider
                            Row(children: [
                              const Expanded(child: Divider(color: AppColors.divider)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: AppTextStyles.labelCaps()),
                              ),
                              const Expanded(child: Divider(color: AppColors.divider)),
                            ]),
                            const SizedBox(height: AppSpacing.xl),

                            // Sign up button
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                onPressed: () => Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (_) => const SignupView())),
                                child: Text('Create New Account',
                                    style: AppTextStyles.buttonSecondary()),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Don\'t have an account?  ',
                                  style: AppTextStyles.bodySmall(),
                                  children: [
                                    TextSpan(text: 'Join us today',
                                        style: AppTextStyles.bodySmall().copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
        ),
      );
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _AuthField({required this.controller, required this.label,
      required this.icon, this.obscure = false, this.suffixIcon,
      this.keyboardType, this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: keyboardType, validator: validator,
        style: AppTextStyles.body(),
        decoration: InputDecoration(
          labelText: label, labelStyle: AppTextStyles.caption(),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          suffixIcon: suffixIcon, filled: true, fillColor: AppColors.bgSection,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
}

class _VisToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _VisToggle({required this.obscure, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textMuted, size: 18),
        onPressed: onTap,
      );
}

class _AuthErrorBox extends StatelessWidget {
  final String message;
  const _AuthErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withOpacity(0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: AppTextStyles.bodySmall().copyWith(color: AppColors.error))),
        ]),
      );
}