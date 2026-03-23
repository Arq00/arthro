// lib/admin/views/admin_login_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arthro/admin/widgets/admin_theme.dart';
import '../controllers/admin_auth_controller.dart';

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});
  @override State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final _emailCtrl = TextEditingController(text: 'admin@arthrocare.com');
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAuthController()..checkSession(),
      child: Consumer<AdminAuthController>(
        builder: (context, ctrl, _) {
          if (ctrl.isAuthenticated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/admin/dashboard');
            });
          }

          return Scaffold(
            backgroundColor: AdminTheme.bg,
            body: Row(children: [
              // ── Left panel (branding) ──────────────────────────────────────
              if (MediaQuery.of(context).size.width > 900)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AdminTheme.primaryDark,
                          AdminTheme.primary,
                          AdminTheme.primaryLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(children: [
                      // Background pattern dots
                      ...List.generate(20, (i) => Positioned(
                        left: (i % 5) * 120.0 + 40,
                        top:  (i ~/ 5) * 160.0 + 60,
                        child: Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle),
                        ),
                      )),
                      Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.medical_services_rounded,
                                color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 24),
                          const Text('ArthroCare',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: AdminTheme.fontFamily,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Text('Admin Management Portal',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 15,
                                  fontFamily: AdminTheme.fontFamily)),
                          const SizedBox(height: 48),
                          _FeatureRow(Icons.group_rounded,
                              'Manage Patients & Guardians'),
                          _FeatureRow(Icons.analytics_rounded,
                              'Real-time RAPID3 Analytics'),
                          _FeatureRow(Icons.summarize_rounded,
                              'Manage Lifestyle Recommendation'),
                          _FeatureRow(Icons.shield_rounded,
                              'View Inactive Accounts'),
                        ],
                      )),
                    ]),
                  ),
                ),

              // ── Right panel (form) ─────────────────────────────────────────
              SizedBox(
                width: MediaQuery.of(context).size.width > 900
                    ? 460 : double.infinity,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mobile logo
                        if (MediaQuery.of(context).size.width <= 900) ...[
                          Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AdminTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medical_services_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text('ArthroCare Admin',
                                style: AdminTheme.tsTitle),
                          ]),
                          const SizedBox(height: 32),
                        ],

                        const Text('Welcome back 👋',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800,
                                color: AdminTheme.textPrimary,
                                fontFamily: AdminTheme.fontFamily)),
                        const SizedBox(height: 6),
                        const Text('Sign in to your admin account',
                            style: AdminTheme.tsBody),
                        const SizedBox(height: 32),

                        // Email
                        _FieldLabel('Email address'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: AdminTheme.inputDeco(
                              'admin@arthrocare.com',
                              icon: Icons.email_outlined),
                          style: const TextStyle(
                              fontFamily: AdminTheme.fontFamily),
                          onSubmitted: (_) => _login(ctrl),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _FieldLabel('Password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: AdminTheme.inputDeco('••••••••',
                              icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                                  size: 18, color: AdminTheme.textMuted),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          style: const TextStyle(
                              fontFamily: AdminTheme.fontFamily),
                          onSubmitted: (_) => _login(ctrl),
                        ),

                        // Error
                        if (ctrl.error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminTheme.redBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AdminTheme.red.withOpacity(0.25)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AdminTheme.red, size: 16),
                              const SizedBox(width: 10),
                              Expanded(child: Text(ctrl.error,
                                  style: const TextStyle(
                                      color: AdminTheme.red, fontSize: 13,
                                      fontFamily: AdminTheme.fontFamily))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AdminTheme.fontFamily),
                            ),
                            onPressed: ctrl.state == AdminAuthState.loading
                                ? null : () => _login(ctrl),
                            child: ctrl.state == AdminAuthState.loading
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In'),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Center(child: Text(
                            'Admin access only. Patient accounts will be denied.',
                            style: AdminTheme.tsSmall,
                            textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _login(AdminAuthController ctrl) =>
      ctrl.login(_emailCtrl.text, _passCtrl.text);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AdminTheme.textPrimary, fontFamily: AdminTheme.fontFamily));
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
      const SizedBox(width: 12),
      Text(text, style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 14, fontFamily: AdminTheme.fontFamily)),
    ]),
  );
}