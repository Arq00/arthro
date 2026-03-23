// lib/views/auth/signup_view.dart
// Redesigned: role-aware colours, app_theme typography, clean card layout.
// Patient = teal. Guardian = amber/brown.


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_theme.dart';
import 'login_view.dart';

class SignupView extends StatefulWidget {
  final String initialRole;
  const SignupView({super.key, this.initialRole = 'patient'});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final fullNameCont    = TextEditingController();
  final usernameCont    = TextEditingController();
  final emailCont       = TextEditingController();
  final passCont        = TextEditingController();
  final confirmPassCont = TextEditingController();
  final _formKey        = GlobalKey<FormState>();

  late String selectedRole;
  bool agreedToTerms   = false;
  bool _obscurePass    = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    fullNameCont.dispose(); usernameCont.dispose();
    emailCont.dispose(); passCont.dispose(); confirmPassCont.dispose();
    super.dispose();
  }

  bool get _isPatient => selectedRole == 'patient';
  Color get _accent     => _isPatient ? AppColors.primary : const Color(0xFF92400E);
  Color get _accentSurf => _isPatient ? AppColors.primarySurface : const Color(0xFFFEF3C7);
  Color get _gradTop    => _isPatient ? const Color(0xFF0D3D3D) : const Color(0xFF1C1410);
  Color get _gradMid    => _isPatient ? AppColors.primary : const Color(0xFF78350F);
  Color get _gradBot    => _isPatient ? const Color(0xFF2D8B8B) : const Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradTop, _gradMid, _gradBot],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _BackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 16),
                  Text('Create Account',
                      style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white, fontSize: 22)),
                ]),
              ),

              // ── Role pills ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Row(children: [
                  _HeaderRolePill(
                    label: 'Patient', icon: Icons.person_rounded,
                    isSelected: _isPatient,
                    onTap: () => setState(() => selectedRole = 'patient'),
                  ),
                  const SizedBox(width: 10),
                  _HeaderRolePill(
                    label: 'Guardian', icon: Icons.favorite_rounded,
                    isSelected: !_isPatient,
                    onTap: () => setState(() => selectedRole = 'guardian'),
                  ),
                ]),
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
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Consumer<AuthController>(
                        builder: (context, auth, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Context banner
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(selectedRole),
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _accentSurf,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Row(children: [
                                  Icon(
                                    _isPatient
                                        ? Icons.monitor_heart_outlined
                                        : Icons.shield_outlined,
                                    color: _accent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isPatient
                                          ? 'You\'ll manage your own health data'
                                          : 'You\'ll link to a patient after logging in',
                                      style: AppTextStyles.bodySmall()
                                          .copyWith(color: _accent),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            _SectionLabel('Personal Details'),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(controller: fullNameCont, label: 'Full Name',
                                icon: Icons.person_outline_rounded, accent: _accent,
                                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(controller: usernameCont, label: 'Username',
                                icon: Icons.alternate_email_rounded, accent: _accent,
                                validator: (v) => (v != null && v.length < 3) ? 'Min 3 characters' : null),
                            const SizedBox(height: AppSpacing.xl),

                            _SectionLabel('Account Details'),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(controller: emailCont, label: 'Email Address',
                                icon: Icons.mail_outline_rounded, accent: _accent,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v != null && !v.contains('@')) ? 'Invalid email' : null),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(controller: passCont, label: 'Password',
                                icon: Icons.lock_outline_rounded, accent: _accent,
                                obscure: _obscurePass,
                                suffixIcon: _VisToggle(obscure: _obscurePass,
                                    onTap: () => setState(() => _obscurePass = !_obscurePass)),
                                validator: (v) => (v != null && v.length < 6) ? 'Min 6 characters' : null),
                            const SizedBox(height: AppSpacing.md),
                            _AuthField(controller: confirmPassCont, label: 'Confirm Password',
                                icon: Icons.lock_outline_rounded, accent: _accent,
                                obscure: _obscureConfirm,
                                suffixIcon: _VisToggle(obscure: _obscureConfirm,
                                    onTap: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                                validator: (v) => v != passCont.text ? 'Passwords don\'t match' : null),
                            const SizedBox(height: AppSpacing.xl),

                            // Terms checkbox
                            GestureDetector(
                              onTap: () => setState(() => agreedToTerms = !agreedToTerms),
                              child: Row(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: agreedToTerms ? _accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: agreedToTerms ? _accent : AppColors.border, width: 2),
                                  ),
                                  child: agreedToTerms
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'I agree to the ',
                                      style: AppTextStyles.bodySmall(),
                                      children: [
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: AppTextStyles.bodySmall().copyWith(
                                              color: _accent, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            if (auth.status.isNotEmpty) ...[
                              _AuthErrorBox(message: auth.status),
                              const SizedBox(height: AppSpacing.md),
                            ],

                            // Submit button
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: agreedToTerms ? _accent : AppColors.border,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                onPressed: (agreedToTerms && !auth.isLoading)
                                    ? () {
                                        if (_formKey.currentState!.validate()) {
                                          // Both patient and guardian create account directly.
                                          // Guardian will link to a patient after login via GuardianLinkView.
                                          auth.signUp(
                                            emailCont.text.trim(),
                                            passCont.text.trim(),
                                            fullNameCont.text.trim(),
                                            usernameCont.text.trim(),
                                            selectedRole,
                                          );
                                        }
                                      }
                                    : null,
                                child: auth.isLoading
                                    ? const SizedBox(height: 22, width: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text(
                                        'Create Account',
                                        style: AppTextStyles.buttonPrimary()),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (_) => LoginView())),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account?  ',
                                    style: AppTextStyles.bodySmall(),
                                    children: [
                                      TextSpan(text: 'Sign in',
                                          style: AppTextStyles.bodySmall()
                                              .copyWith(color: _accent, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
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

// ── Shared auth sub-widgets ───────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
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

class _HeaderRolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _HeaderRolePill({required this.label, required this.icon,
      required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14,
                color: isSelected ? const Color(0xFF1B5F5F) : Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF1B5F5F) : Colors.white.withOpacity(0.8),
                )),
          ]),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTextStyles.labelCaps());
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _AuthField({required this.controller, required this.label,
      required this.icon, required this.accent, this.obscure = false,
      this.suffixIcon, this.keyboardType, this.validator});
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: keyboardType, validator: validator,
        style: AppTextStyles.body(),
        decoration: InputDecoration(
          labelText: label, labelStyle: AppTextStyles.caption(),
          prefixIcon: Icon(icon, color: accent, size: 18),
          suffixIcon: suffixIcon, filled: true, fillColor: AppColors.bgSection,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: accent, width: 2)),
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