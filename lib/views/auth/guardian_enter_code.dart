// lib/views/auth/guardian_enter_code.dart
// Redesigned to match new auth theme: dark gradient header + white card body.
// Guardian = amber/brown accent.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/app_theme.dart';

class GuardianEnterCodeView extends StatefulWidget {
  final String email, password, fullName, username;
  const GuardianEnterCodeView({
    super.key,
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  });

  @override
  State<GuardianEnterCodeView> createState() => _GuardianEnterCodeViewState();
}

class _GuardianEnterCodeViewState extends State<GuardianEnterCodeView> {
  final _codeCont = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  UserModel? _foundPatient;
  bool   _searching = false;
  String _errorMsg  = '';

  static const _gradTop = Color(0xFF1C1410);
  static const _gradMid = Color(0xFF78350F);
  static const _gradBot = Color(0xFFB45309);
  static const _amber   = Color(0xFF92400E);
  static const _amberSurf = Color(0xFFFEF3C7);

  @override
  void dispose() { _codeCont.dispose(); super.dispose(); }

  Future<void> _searchCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _searching = true; _errorMsg = ''; _foundPatient = null; });
    final auth    = context.read<AuthController>();
    final patient = await auth.findPatientByCode(_codeCont.text.trim().toUpperCase());
    if (!mounted) return;
    setState(() => _searching = false);
    if (patient == null) {
      setState(() => _errorMsg = 'Code not found or has expired. Ask the patient to regenerate.');
    } else if (patient.role != 'patient') {
      setState(() => _errorMsg = 'That code does not belong to a patient account.');
    } else {
      setState(() => _foundPatient = patient);
    }
  }

  Future<void> _confirmAndCreate() async {
    if (_foundPatient == null) return;
    final auth = context.read<AuthController>();
    await auth.signUp(widget.email, widget.password,
        widget.fullName, widget.username, 'guardian');
    if (auth.status.isNotEmpty && !auth.status.toLowerCase().contains('verify')) return;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: _amberSurf, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, color: _amber, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Account Created!', style: AppTextStyles.sectionTitle()),
        ]),
        content: Text(
          'Verify your email then log in. Once logged in, your request will be sent to ${_foundPatient!.fullName} for approval.',
          style: AppTextStyles.body(),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () => Navigator.of(context)..pop()..pop()..pop(),
            child: Text('Go to Login', style: AppTextStyles.buttonPrimary()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradTop, _gradMid, _gradBot],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _BackBtn(onTap: () => Navigator.pop(context)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text('Link Your\nPatient.',
                        style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white, fontSize: 36, height: 1.1)),
                    const SizedBox(height: 10),
                    Text('Enter the pairing code from your patient\'s profile',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 14, fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
              ),

              // ── Form Card ─────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Consumer<AuthController>(
                      builder: (context, auth, _) => Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tip box
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.base),
                              decoration: BoxDecoration(
                                color: _amberSurf,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('How to get the code',
                                            style: AppTextStyles.cardTitle()
                                                .copyWith(color: _amber)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ask your patient: Profile → Account Settings → Guardian Pairing → Generate Pairing Code.',
                                          style: AppTextStyles.bodySmall()
                                              .copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            Text('PAIRING CODE', style: AppTextStyles.labelCaps()),
                            const SizedBox(height: AppSpacing.md),

                            // Code input
                            TextFormField(
                              controller: _codeCont,
                              textCapitalization: TextCapitalization.characters,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmMono(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                  color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'PAT-XXXX',
                                hintStyle: GoogleFonts.dmMono(
                                    fontSize: 24, letterSpacing: 6,
                                    color: AppColors.textMuted),
                                prefixIcon: const Icon(Icons.qr_code_rounded,
                                    color: _amber, size: 20),
                                filled: true,
                                fillColor: AppColors.bgSection,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: _amber, width: 2)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    borderSide: const BorderSide(color: AppColors.error)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter the pairing code';
                                if (!RegExp(r'^PAT-[A-Z0-9]{4}$').hasMatch(v.trim().toUpperCase()))
                                  return 'Code format should be PAT-XXXX';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Errors
                            if (_errorMsg.isNotEmpty) ...[
                              _StatusBox(msg: _errorMsg, isError: true),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            if (auth.status.isNotEmpty) ...[
                              _StatusBox(
                                msg: auth.status,
                                isError: !auth.status.toLowerCase().contains('verify'),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],

                            // Patient preview
                            if (_foundPatient != null) ...[
                              _PatientCard(patient: _foundPatient!, accent: _amber),
                              const SizedBox(height: AppSpacing.xl),
                            ] else
                              const SizedBox(height: AppSpacing.sm),

                            // Button
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _amber, elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                                ),
                                onPressed: (_searching || auth.isLoading)
                                    ? null
                                    : _foundPatient == null ? _searchCode : _confirmAndCreate,
                                child: (_searching || auth.isLoading)
                                    ? const SizedBox(height: 22, width: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : Text(
                                        _foundPatient == null
                                            ? 'Find Patient'
                                            : 'Confirm & Create Account',
                                        style: AppTextStyles.buttonPrimary()),
                              ),
                            ),

                            if (_foundPatient != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Center(
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _foundPatient = null;
                                    _codeCont.clear();
                                    _errorMsg = '';
                                  }),
                                  child: Text('Use a different code',
                                      style: AppTextStyles.buttonSecondary()
                                          .copyWith(color: _amber)),
                                ),
                              ),
                            ],
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

// ── Guardian Link View (post-login unlinked state) ────────────────────────────
class GuardianLinkView extends StatefulWidget {
  final VoidCallback? onLogout;
  const GuardianLinkView({super.key, this.onLogout});
  @override
  State<GuardianLinkView> createState() => _GuardianLinkViewState();
}

class _GuardianLinkViewState extends State<GuardianLinkView> {
  final _codeCont = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  UserModel? _foundPatient;
  bool   _searching   = false;
  String _errorMsg    = '';
  bool   _requestSent = false;

  static const _amber    = Color(0xFF92400E);
  static const _amberSurf = Color(0xFFFEF3C7);

  @override
  void dispose() { _codeCont.dispose(); super.dispose(); }

  Future<void> _searchCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _searching = true; _errorMsg = ''; _foundPatient = null; _requestSent = false; });
    final auth    = context.read<AuthController>();
    final patient = await auth.findPatientByCode(_codeCont.text.trim().toUpperCase());
    if (!mounted) return;
    setState(() => _searching = false);
    if (patient == null) {
      setState(() => _errorMsg = 'Code not found or has expired. Ask the patient to regenerate.');
    } else if (patient.role != 'patient') {
      setState(() => _errorMsg = 'That code does not belong to a patient account.');
    } else {
      setState(() => _foundPatient = patient);
    }
  }

  Future<void> _sendRequest() async {
    if (_foundPatient == null) return;
    await context.read<AuthController>().requestToLink(_foundPatient!.uid);
    if (!mounted) return;
    setState(() => _requestSent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Link Patient', style: AppTextStyles.sectionTitle()),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textMuted, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl)),
                  title: Text('Sign Out', style: AppTextStyles.sectionTitle()),
                  content: Text('Are you sure you want to sign out?',
                      style: AppTextStyles.body()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: AppTextStyles.buttonSecondary()),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text('Sign Out',
                          style: AppTextStyles.buttonPrimary()),
                    ),
                  ],
                ),
              );
              if (confirm == true) widget.onLogout?.call();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              if (!_requestSent) ...[
                // ── Hero ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: _amberSurf, shape: BoxShape.circle),
                  child: const Icon(Icons.favorite_rounded,
                      size: 40, color: _amber),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text("You're a Guardian", style: AppTextStyles.pageTitle()),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your patient\'s pairing code to link accounts and start viewing their health data.',
                  style: AppTextStyles.bodySmall().copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Tip box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: _amberSurf,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: _amber.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How to get the code',
                                style: AppTextStyles.cardTitle().copyWith(color: _amber)),
                            const SizedBox(height: 4),
                            Text(
                              'Ask your patient: Profile → Account Settings → Guardian Pairing → Generate Pairing Code.',
                              style: AppTextStyles.bodySmall()
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form
                Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      controller: _codeCont,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmMono(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          letterSpacing: 6, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'PAT-XXXX',
                        hintStyle: GoogleFonts.dmMono(
                            fontSize: 22, letterSpacing: 6, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.qr_code_rounded, color: _amber, size: 20),
                        filled: true, fillColor: AppColors.bgSection,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: _amber, width: 2)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.error)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter the pairing code';
                        if (!RegExp(r'^PAT-[A-Z0-9]{4}$').hasMatch(v.trim().toUpperCase()))
                          return 'Code format should be PAT-XXXX';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_errorMsg.isNotEmpty) ...[
                      _StatusBox(msg: _errorMsg, isError: true),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    if (_foundPatient != null) ...[
                      _PatientCard(patient: _foundPatient!, accent: _amber),
                      const SizedBox(height: AppSpacing.xl),
                    ] else
                      const SizedBox(height: AppSpacing.sm),

                    Consumer<AuthController>(
                      builder: (_, auth, __) => SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amber, elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.lg)),
                          ),
                          onPressed: (_searching || auth.isLoading)
                              ? null
                              : _foundPatient == null ? _searchCode : _sendRequest,
                          child: (_searching || auth.isLoading)
                              ? const SizedBox(height: 22, width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  _foundPatient == null ? 'Find Patient' : 'Send Link Request',
                                  style: AppTextStyles.buttonPrimary()),
                        ),
                      ),
                    ),

                    if (_foundPatient != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => setState(() {
                          _foundPatient = null; _codeCont.clear(); _errorMsg = '';
                        }),
                        child: Text('Use a different code',
                            style: AppTextStyles.buttonSecondary().copyWith(color: _amber)),
                      ),
                    ],
                  ]),
                ),
              ] else ...[
                // ── Waiting state ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: _amberSurf, shape: BoxShape.circle),
                  child: const Icon(Icons.hourglass_top_rounded,
                      size: 40, color: _amber),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Request Sent!', style: AppTextStyles.pageTitle()),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Waiting for ${_foundPatient?.fullName ?? 'the patient'} to approve your request. This screen will update automatically once they accept.',
                  style: AppTextStyles.bodySmall().copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: _amberSurf,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: _amber.withOpacity(0.25)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 32, color: _amber),
                    const SizedBox(height: AppSpacing.md),
                    Text('Pending Approval',
                        style: AppTextStyles.sectionTitle().copyWith(color: _amber)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'The patient will receive a notification to approve your request.',
                      style: AppTextStyles.bodySmall().copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => setState(() {
                    _requestSent = false; _foundPatient = null;
                    _codeCont.clear(); _errorMsg = '';
                  }),
                  child: Text('Send to a different patient',
                      style: AppTextStyles.buttonSecondary().copyWith(color: _amber)),
                ),
              ],

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final UserModel patient;
  final Color accent;
  const _PatientCard({required this.patient, required this.accent});

  @override
  Widget build(BuildContext context) {
    final initial = patient.fullName.isNotEmpty
        ? patient.fullName[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: accent, radius: 22,
          child: Text(initial,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(patient.fullName, style: AppTextStyles.cardTitle()),
            const SizedBox(height: 2),
            Text('@${patient.username}',
                style: AppTextStyles.caption().copyWith(color: AppColors.textMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.tierRemission.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.tierRemission.withOpacity(0.3)),
          ),
          child: Text('✓ Found',
              style: AppTextStyles.labelCaps().copyWith(color: AppColors.tierRemission)),
        ),
      ]),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String msg;
  final bool isError;
  const _StatusBox({required this.msg, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.tierRemission;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: AppTextStyles.bodySmall().copyWith(color: color))),
      ]),
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