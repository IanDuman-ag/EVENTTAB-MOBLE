import 'package:flutter/material.dart';

import 'role.dart';

class InterfacePage extends StatelessWidget {
  const InterfacePage({super.key, this.onGetStarted});

  final VoidCallback? onGetStarted;

  void _handleGetStarted(BuildContext context) {
    if (onGetStarted != null) {
      onGetStarted!();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RolePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFFB6A6E7),
                  tooltip: 'Back',
                ),
              ),
              const Spacer(flex: 2),
              const _BrandHeader(),
              const SizedBox(height: 56),
              const _CelebrationIllustration(),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleGetStarted(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D16C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Image.asset(
            'assets/eventtablogo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(text: 'EVENT', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'TAB', style: TextStyle(color: Color(0xFF6A1FD0))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'EVENTS. MANAGED. SIMPLIFIED.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFC8C2D8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _CelebrationIllustration extends StatelessWidget {
  const _CelebrationIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ConfettiPainter()),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CelebrationPerson(
                  shirtColor: Color(0xFF7E2BFF),
                  accentColor: Color(0xFFEAD8FF),
                  armSpread: false,
                ),
                SizedBox(width: 8),
                _CelebrationPerson(
                  shirtColor: Color(0xFFBC8BFF),
                  accentColor: Color(0xFF5D16C1),
                  armSpread: true,
                  isCenter: true,
                ),
                SizedBox(width: 8),
                _CelebrationPerson(
                  shirtColor: Color(0xFF7E2BFF),
                  accentColor: Color(0xFFEAD8FF),
                  armSpread: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPerson extends StatelessWidget {
  const _CelebrationPerson({
    required this.shirtColor,
    required this.accentColor,
    required this.armSpread,
    this.isCenter = false,
  });

  final Color shirtColor;
  final Color accentColor;
  final bool armSpread;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final double bodyHeight = isCenter ? 82 : 74;
    final double bodyWidth = isCenter ? 24 : 22;

    return SizedBox(
      width: 58,
      height: 118,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE1CB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 28,
            child: Container(
              width: bodyWidth,
              height: bodyHeight,
              decoration: BoxDecoration(
                color: shirtColor,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            top: armSpread ? 36 : 42,
            left: armSpread ? 2 : 4,
            child: Transform.rotate(
              angle: armSpread ? -0.85 : -0.45,
              child: Container(
                width: 10,
                height: armSpread ? 44 : 34,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            top: armSpread ? 36 : 42,
            right: armSpread ? 2 : 4,
            child: Transform.rotate(
              angle: armSpread ? 0.85 : 0.45,
              child: Container(
                width: 10,
                height: armSpread ? 44 : 34,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 17,
            child: Transform.rotate(
              angle: 0.08,
              child: Container(
                width: 10,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2343),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 17,
            child: Transform.rotate(
              angle: -0.08,
              child: Container(
                width: 10,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2343),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purple = Paint()..color = const Color(0xFFB162FF).withValues(alpha: 0.9);
    final lilac = Paint()..color = const Color(0xFFE5D5FF).withValues(alpha: 0.9);

    final dots = <Offset>[
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.28, size.height * 0.08),
      Offset(size.width * 0.36, size.height * 0.23),
      Offset(size.width * 0.44, size.height * 0.05),
      Offset(size.width * 0.56, size.height * 0.16),
      Offset(size.width * 0.64, size.height * 0.07),
      Offset(size.width * 0.72, size.height * 0.2),
      Offset(size.width * 0.82, size.height * 0.12),
    ];

    for (var i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], i.isEven ? 3.2 : 2.4, i.isEven ? purple : lilac);
    }

    final lines = <List<Offset>>[
      [Offset(size.width * 0.14, size.height * 0.34), Offset(size.width * 0.10, size.height * 0.42)],
      [Offset(size.width * 0.24, size.height * 0.28), Offset(size.width * 0.20, size.height * 0.36)],
      [Offset(size.width * 0.35, size.height * 0.3), Offset(size.width * 0.33, size.height * 0.4)],
      [Offset(size.width * 0.48, size.height * 0.22), Offset(size.width * 0.48, size.height * 0.32)],
      [Offset(size.width * 0.62, size.height * 0.28), Offset(size.width * 0.66, size.height * 0.38)],
      [Offset(size.width * 0.74, size.height * 0.34), Offset(size.width * 0.79, size.height * 0.42)],
      [Offset(size.width * 0.86, size.height * 0.28), Offset(size.width * 0.91, size.height * 0.36)],
    ];

    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    for (var i = 0; i < lines.length; i++) {
      stroke.color = i.isEven ? purple.color : lilac.color;
      canvas.drawLine(lines[i][0], lines[i][1], stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
