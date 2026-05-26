import 'package:flutter/material.dart';

import '../auth/judge_auth_service.dart';
import '../auth/login.dart';

// ─── palette ─────────────────────────────────────────────
const _kBg     = Color(0xFF0B0B12);
const _kCard   = Color(0xFF17131F);
const _kBorder = Color(0xFF2A2433);
const _kPurple = Color(0xFF9F66FF);
const _kMuted  = Color(0xFF7F7890);

class JudgeProfilePage extends StatefulWidget {
  const JudgeProfilePage({super.key});

  @override
  State<JudgeProfilePage> createState() => _JudgeProfilePageState();
}

class _JudgeProfilePageState extends State<JudgeProfilePage> {
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

  // ── Derived from session ──────────────────────────────

  String get _displayName {
    final username = JudgeAuthSession.current?.username.trim() ?? '';
    if (username.isEmpty) return 'Judge';
    return username
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  String get _email =>
      JudgeAuthSession.current?.email.trim() ?? '';

  String get _initials {
    final parts = _displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'J';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ── Logout ────────────────────────────────────────────

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await judgeAuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: _kCard,
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: _kPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Profile',
                      style: TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero card ──
                    _HeroCard(initials: _initials, displayName: _displayName),
                    const SizedBox(height: 36),
                    // ── Account section ──
                    _SectionLabel('ACCOUNT'),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Username',
                      subtitle: JudgeAuthSession.current?.username ?? '—',
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.mail_outline_rounded,
                      title: 'Email Address',
                      subtitle: _email.isEmpty ? '—' : _email,
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.gavel_rounded,
                      title: 'Role',
                      subtitle: 'Judge',
                      accent: _kPurple,
                    ),
                    const SizedBox(height: 36),
                    // ── Preferences section ──
                    _SectionLabel('PREFERENCES'),
                    const SizedBox(height: 12),
                    _NotifRow(
                      enabled: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    const SizedBox(height: 2),
                    _ThemeRow(),
                    const SizedBox(height: 36),
                    // ── Logout ──
                    _LogoutButton(
                        isBusy: _isLoggingOut, onPressed: _handleLogout),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.initials, required this.displayName});
  final String initials, displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A1050), Color(0xFF1A102D)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kPurple, width: 2),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                        color: _kPurple,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      )),
                ),
              ),
              Positioned(
                right: -6, bottom: -6,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: _kPurple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _kPurple.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gavel_rounded,
                          color: _kPurple, size: 12),
                      SizedBox(width: 5),
                      Text('JUDGE',
                          style: TextStyle(
                            color: _kPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
          color: _kMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.7,
        ));
  }
}

// ─── Info row ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = _kPurple,
  });
  final IconData icon;
  final String title, subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _kMuted, size: 18),
        ],
      ),
    );
  }
}

// ─── Notification row ─────────────────────────────────────

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: _kPurple, size: 18),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                SizedBox(height: 3),
                Text('Event assignments and score reminders.',
                    style: TextStyle(
                      color: _kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _kPurple,
            inactiveThumbColor: const Color(0xFF7B7F85),
            inactiveTrackColor: const Color(0xFF2A2D34),
          ),
        ],
      ),
    );
  }
}

// ─── Theme row ────────────────────────────────────────────

class _ThemeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _kCard,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.dark_mode_outlined, color: _kPurple, size: 18),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Theme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.12),
              border: Border.all(color: _kPurple.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('DARK',
                style: TextStyle(
                  color: _kPurple,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isBusy, required this.onPressed});
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isBusy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF5A241A)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          foregroundColor: const Color(0xFFF16A52),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFF16A52)))
            : const Icon(Icons.logout_rounded, size: 16),
        label: Text(
          isBusy ? 'LOGGING OUT...' : 'LOG OUT',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
          ),
        ),
      ),
    );
  }
}
