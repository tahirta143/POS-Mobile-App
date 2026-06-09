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
  final _emailController = TextEditingController();
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

    // Clear error from previous login attempts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      debugPrint('UI: Login button pressed. Calling authProvider.login...');
      
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      debugPrint('UI: Login call returned success: $success');

      if (success && mounted) {
        debugPrint('UI: Navigating to /dashboard');
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    // Layout adaptivity (Responsive layout using MediaQuery)
    final isDesktopOrTablet = size.width > 700;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 850),
              decoration: BoxDecoration(
                color: isDark ? AppConstants.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                border: Border.all(
                  color: isDark ? AppConstants.darkBorder : AppConstants.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: isDesktopOrTablet
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Branding Panel
                        Expanded(
                          flex: 4,
                          child: _buildBrandingPanel(context),
                        ),
                        // Right Form Panel
                        Expanded(
                          flex: 6,
                          child: _buildFormPanel(context, authProvider),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        // Top Branding
                        _buildBrandingPanel(context, height: 220, isMobile: true),
                        // Bottom Form
                        _buildFormPanel(context, authProvider),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingPanel(BuildContext context, {double? height, bool isMobile = false}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                topRight: Radius.circular(AppConstants.borderRadiusLarge),
              )
            : const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusLarge),
                bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
              ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // POS Logo mark
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: const Text(
                'POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'POS System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage inventory, categories, and items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFCCFBF1), // teal-100
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            // Bullet points
            Column(
              children: [
                _buildBulletPoint('Category & item management'),
                const SizedBox(height: 6),
                _buildBulletPoint('Real-time inventory tracking'),
                const SizedBox(height: 6),
                _buildBulletPoint('Multi-user access control'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11),
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
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppConstants.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppConstants.primaryTeal,
                size: 22,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppConstants.darkTextPrimary : AppConstants.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please enter your details to sign in',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppConstants.darkTextSecondary : AppConstants.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // Error alert
            if (authProvider.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                ),
                child: Text(
                  authProvider.error!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            CustomTextField(
              label: 'Email Address',
              placeholder: 'name@company.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: authProvider.loading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryTeal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppConstants.primaryTeal.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: authProvider.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Don't have an account? Please contact your administrator.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
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
