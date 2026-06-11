import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Fade-in animation on launch
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Rebuild UI when typing to update prefix icon dynamically (person vs email)
    _identifierController.addListener(_onIdentifierChanged);

    // Clear error from previous login attempts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  void _onIdentifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _identifierController.removeListener(_onIdentifierChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('UI: Login button pressed. Calling authProvider.login...');
      
      final success = await authProvider.login(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      debugPrint('UI: Login call returned success: $success');

      if (success && mounted) {
        debugPrint('UI: Navigating to /main');
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDesktopOrTablet = size.width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppConstants.darkBg
          : Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isDesktopOrTablet
            ? Row(
                children: [
                  // Left Side: Beautiful colorized branding panel (exactly 50%)
                  Expanded(
                    child: _buildBrandingPanel(context, isMobile: false),
                  ),
                  // Right Side: Clean login form panel (exactly 50%)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: _buildFormPanel(context, authProvider),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Side: Colorized branding panel with height constraints
                    _buildBrandingPanel(context, height: 320, isMobile: true),
                    // Bottom Side: Clean login form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFormPanel(context, authProvider),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBrandingPanel(BuildContext context, {double? height, bool isMobile = false}) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: isMobile ? height : double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D9488), // Teal 600
            Color(0xFF14B8A6), // Teal 500
            Color(0xFF10B981), // Emerald 500
          ],
        ),
        borderRadius: isMobile
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              )
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Overlapping decorative circles (matching React UI circles)
          Positioned(
            left: -80,
            top: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: size.width * (isMobile ? 0.2 : 0.08),
            top: size.height * (isMobile ? 0.15 : 0.35),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo mark
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'POS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'POS System',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage your inventory, categories, and items from one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCCFBF1), // teal-100
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bullet points (wrap nicely)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        _buildBulletPoint('Category & item management'),
                        const SizedBox(height: 12),
                        _buildBulletPoint('Real-time inventory tracking'),
                        const SizedBox(height: 12),
                        _buildBulletPoint('Multi-user access control'),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel(BuildContext context, AuthProvider authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppConstants.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppConstants.primaryTeal,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in with your email or username',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Error alert
            if (authProvider.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  authProvider.error!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
            ],

            CustomTextField(
              label: 'Email or Username',
              placeholder: 'name@company.com or username',
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              required: true,
              prefixIcon: Icon(
                _identifierController.text.contains('@')
                    ? Icons.alternate_email_rounded
                    : Icons.person_outline_rounded,
                color: isDark ? Colors.grey : Colors.blueGrey,
                size: 18,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email or Username is required';
                }
                final trimmed = value.trim();
                if (trimmed.contains('@')) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                    return 'Please enter a valid email';
                  }
                } else {
                  if (trimmed.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Password',
              placeholder: '••••••••',
              controller: _passwordController,
              isPassword: true,
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: authProvider.loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppConstants.primaryTeal.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: authProvider.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                "Don't have an account? Please contact your administrator.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
