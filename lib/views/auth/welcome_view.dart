// lib/views/auth/welcome_view.dart

import 'package:arthro/views/auth/login_view.dart';
import 'package:arthro/views/auth/signup_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  String _selectedRole = 'patient';
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isPatient => _selectedRole == 'patient';

  Color get _accentColor   => _isPatient ? const Color(0xFF1B5F5F) : const Color(0xFF92400E);
  Color get _accentLight   => _isPatient ? const Color(0xFF2D8B8B) : const Color(0xFFB45309);
  Color get _accentSurface => _isPatient ? const Color(0xFFE8F5F5) : const Color(0xFFFEF3C7);
  Color get _bgTop         => _isPatient ? const Color(0xFF0D3D3D) : const Color(0xFF1C1410);
  Color get _bgMid         => _isPatient ? const Color(0xFF1B5F5F) : const Color(0xFF78350F);

  void _switchRole(String role) {
    if (role == _selectedRole) return;
    setState(() => _selectedRole = role);
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

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
            colors: [_bgTop, _bgMid, _accentLight],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top hero section — fixed height, no Spacer ──────────
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: _isPatient
                                        ? const Color(0xFF5EEAD4)
                                        : const Color(0xFFFCD34D),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('ArthroCare',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Role-based headline
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Column(
                              key: ValueKey(_selectedRole),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPatient
                                      ? 'Your health,\nyour control.'
                                      : 'Care for those\nyou love.',
                                  style: GoogleFonts.dmSerifDisplay(
                                    color: Colors.white,
                                    fontSize: 36,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isPatient
                                      ? 'Track symptoms, medications and appointments — all in one place.'
                                      : 'Monitor your patient\'s health journey and stay connected to their care.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    height: 1.55,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Decorative dots
                          Row(
                            children: List.generate(3, (i) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: i == 0 ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom card — intrinsic height, no flex ─────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FAFA),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Role toggle label
                    Text('I AM A',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8AABAB),
                          letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 10),

                    // Role toggle
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(children: [
                        _RoleTab(
                          label: 'Patient',
                          icon: Icons.person_rounded,
                          isSelected: _isPatient,
                          selectedColor: const Color(0xFF1B5F5F),
                          onTap: () => _switchRole('patient'),
                        ),
                        _RoleTab(
                          label: 'Guardian',
                          icon: Icons.favorite_rounded,
                          isSelected: !_isPatient,
                          selectedColor: const Color(0xFF92400E),
                          onTap: () => _switchRole('guardian'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Description chip
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_selectedRole),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _accentSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Icon(
                            _isPatient
                                ? Icons.monitor_heart_outlined
                                : Icons.shield_outlined,
                            color: _accentColor, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isPatient
                                  ? 'Track your RA symptoms and medications'
                                  : 'View and support a linked patient\'s care',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: _accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Get Started
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SignupView(initialRole: _selectedRole),
                            ),
                          ),
                          child: Text('Get Started',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sign in link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => LoginView())),
                        style: TextButton.styleFrom(
                            foregroundColor: _accentColor),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account?  ',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF8AABAB), fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: GoogleFonts.plusJakartaSans(
                                  color: _accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label, required this.icon,
    required this.isSelected, required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: selectedColor.withOpacity(0.12),
                      blurRadius: 8, offset: const Offset(0, 2))]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16,
                    color: isSelected ? selectedColor : const Color(0xFF8AABAB)),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: isSelected ? selectedColor : const Color(0xFF8AABAB),
                    )),
              ],
            ),
          ),
        ),
      );
}