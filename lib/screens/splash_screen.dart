import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Constants ────────────────────────────────────────────────────────────
  static const _kMainDuration  = Duration(milliseconds: 900);
  static const _kBarDuration   = Duration(milliseconds: 2400);
  static const _kSplashHold    = Duration(milliseconds: 2600);

  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _mainCtrl;
  late final AnimationController _barCtrl;

  // Logo: fades in during first 50% of _mainCtrl
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // Text: fades + slides in during 35–100% of _mainCtrl (staggered)
  late final Animation<double> _textFade;
  late final Animation<Offset>  _textSlide;

  // Progress bar
  late final Animation<double> _barFill;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(vsync: this, duration: _kMainDuration);
    _barCtrl  = AnimationController(vsync: this, duration: _kBarDuration);

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _barFill = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    _mainCtrl.forward();
    _barCtrl.forward();

    await Future.delayed(_kSplashHold);
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacementNamed(
      auth.isAuthenticated ? '/main' : '/login',
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bg          = isDark ? AppConstants.darkBg          : AppConstants.lightBg;
    final cardBg      = isDark ? AppConstants.darkCard         : Colors.white;
    final borderColor = isDark ? AppConstants.darkBorder       : AppConstants.lightBorder;
    final textPrimary = isDark ? AppConstants.darkTextPrimary  : AppConstants.lightTextPrimary;
    final textMuted   = isDark ? AppConstants.darkTextSecondary: AppConstants.lightTextSecondary;
    final accent      = isDark ? Colors.white                  : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Centered logo + text ────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo card
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.point_of_sale_rounded,
                                size: 44,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App name + subtitle
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              Text(
                                'POS System',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Point of Sale Management',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: textMuted,
                                  letterSpacing: 0.2,
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: progress bar + version ─────────────────────────
            AnimatedBuilder(
              animation: _barFill,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 36,
                  ),
                  child: Column(
                    children: [
                      // Progress bar
                      Container(
                        height: 2,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _barFill.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}