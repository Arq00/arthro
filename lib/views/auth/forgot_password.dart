// lib/views/auth/forgot_password.dart
// Redesigned to match the new auth screen style.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_theme.dart';

class ForgotPasswordView extends StatelessWidget {
  ForgotPasswordView({super.key});

  final emailCont = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('Reset\nPassword.',
                        style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white, fontSize: 38, height: 1.1)),
                    const SizedBox(height: 10),
                    Text('Enter your email and we\'ll send a reset link',
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
                            Text('EMAIL ADDRESS', style: AppTextStyles.labelCaps()),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: emailCont,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.body(),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email is required';
                                if (!v.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'your@email.com',
                                labelStyle: AppTextStyles.caption(),
                                prefixIcon: const Icon(Icons.mail_outline_rounded,
                                    color: AppColors.primary, size: 18),
                                filled: true, fillColor: AppColors.bgSection,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.error)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Status message
                            if (auth.status.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: auth.status.toLowerCase().contains('sent')
                                      ? AppColors.success.withOpacity(0.06)
                                      : AppColors.error.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: auth.status.toLowerCase().contains('sent')
                                        ? AppColors.success.withOpacity(0.25)
                                        : AppColors.error.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(children: [
                                  Icon(
                                    auth.status.toLowerCase().contains('sent')
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: auth.status.toLowerCase().contains('sent')
                                        ? AppColors.success
                                        : AppColors.error,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.status,
                                        style: AppTextStyles.bodySmall().copyWith(
                                          color: auth.status.toLowerCase().contains('sent')
                                              ? AppColors.success
                                              : AppColors.error,
                                        )),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Send button
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
                                          auth.resetPassword(emailCont.text.trim());
                                        }
                                      },
                                child: auth.isLoading
                                    ? const SizedBox(height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : Text('Send Reset Link',
                                        style: AppTextStyles.buttonPrimary()),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Help box
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.base),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.info.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: AppColors.info, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Check your spam folder if you don\'t receive the email within a few minutes.',
                                      style: AppTextStyles.bodySmall()
                                          .copyWith(color: AppColors.info),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                label: Text('Back to Login',
                                    style: AppTextStyles.bodySmall().copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
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