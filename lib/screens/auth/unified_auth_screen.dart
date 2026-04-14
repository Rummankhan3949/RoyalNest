import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/app_startup_service.dart';
import '../../widgets/professional_button.dart';
import '../../widgets/google_signin_button.dart';

enum _AuthAction { none, login, signup, google }

/// Unified Auth Screen for both Admin and Client
/// Supports login and signup with toggle on same page
class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  bool _isLogin = true;
  _AuthAction _activeAuthAction = _AuthAction.none;
  AuthService? _authService;
  bool _isCoreReady = false;

  // Controllers for Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers for Signup
  final _signupUsernameController = TextEditingController();
  final _signupCnicController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isLoginLoading => _activeAuthAction == _AuthAction.login;
  bool get _isSignupLoading => _activeAuthAction == _AuthAction.signup;
  bool get _isGoogleLoading => _activeAuthAction == _AuthAction.google;

  bool get _isAnyAuthLoading =>
      _isLoginLoading || _isSignupLoading || _isGoogleLoading;

  void _setActiveAuthAction(_AuthAction action) {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAuthAction = action;
    });
  }

  @override
  void initState() {
    super.initState();
    _prepareAuthCore();
  }

  Future<void> _prepareAuthCore() async {
    final ready = await AppStartupService.instance.ensureCoreReady(
      timeout: const Duration(seconds: 6),
    );

    if (!mounted) {
      return;
    }

    if (ready) {
      setState(() {
        _authService = AuthService();
        _isCoreReady = true;
      });
      return;
    }

    setState(() {
      _isCoreReady = false;
    });
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupUsernameController.dispose();
    _signupCnicController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isAnyAuthLoading) {
      return;
    }

    if (!_isCoreReady || _authService == null) {
      _showMessage(
        'Please wait, secure services are still starting.',
        isError: true,
      );
      return;
    }

    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password', isError: true);
      return;
    }

    _setActiveAuthAction(_AuthAction.login);

    try {
      // Try admin login (Firebase) first when credentials match admin
      Map<String, dynamic> result;
      if (_authService!.isAdminCredentials(email, password)) {
        result = await _authService!.adminLogin(email, password);
        if (!result['success']) {
          _showMessage(result['message'], isError: true);
          return;
        }

        _showMessage(result['message']);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/admin-home');
        }
        return;
      }

      // Client login (Firebase)
      result = await _authService!.clientLogin(email, password);

      if (result['success']) {
        _showMessage(result['message']);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/client-main');
        }
      } else if (result['code'] == 'admin-email-restricted') {
        _showMessage(result['message'], isError: true);
      } else if (result['code'] == 'email-not-verified') {
        _showMessage(result['message'], isError: true);
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/verify-email', arguments: {'email': email});
        }
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Login failed. Please try again.', isError: true);
    } finally {
      _setActiveAuthAction(_AuthAction.none);
    }
  }

  Future<void> _handleSignup() async {
    if (_isAnyAuthLoading) {
      return;
    }

    if (!_isCoreReady || _authService == null) {
      _showMessage(
        'Please wait, secure services are still starting.',
        isError: true,
      );
      return;
    }

    final username = _signupUsernameController.text.trim();
    final cnic = _signupCnicController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _signupConfirmPasswordController.text;

    if (username.isEmpty || cnic.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    // Validate CNIC format (13 digits)
    if (cnic.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(cnic)) {
      _showMessage('Please enter a valid 13-digit CNIC', isError: true);
      return;
    }

    _setActiveAuthAction(_AuthAction.signup);

    try {
      final result = await _authService!.clientSignup(
        username: username,
        cnic: cnic,
        email: email,
        password: password,
      );

      if (result['success']) {
        _showMessage(result['message'] ?? 'Account created successfully');
        // Clear form fields
        _signupUsernameController.clear();
        _signupCnicController.clear();
        _signupEmailController.clear();
        _signupPasswordController.clear();
        _signupConfirmPasswordController.clear();

        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/verify-email', arguments: {'email': email});
        }
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Signup failed. Please try again.', isError: true);
    } finally {
      _setActiveAuthAction(_AuthAction.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width > 600 ? 480 : double.infinity,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isCoreReady)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Preparing secure login services...',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAuthCard(),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Secured login for RoyalNest clients',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.royalBlue.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/royalnest_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.home_work,
              size: 40,
              color: AppTheme.royalBlue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'ROYAL NEST',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppTheme.royalBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin ? 'Welcome back, login to continue' : 'Create your account',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildTabSwitcher(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Padding(
              key: ValueKey<bool>(_isLogin),
              padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 22.0),
              child: _isLogin ? _buildLoginForm() : _buildSignupForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _AuthTab(
            label: 'Signup',
            isSelected: !_isLogin,
            onTap: () {
              if (_isAnyAuthLoading) return;
              if (_isLogin) _toggleMode();
            },
          ),
          const SizedBox(width: 8),
          _AuthTab(
            label: 'Login',
            isSelected: _isLogin,
            onTap: () {
              if (_isAnyAuthLoading) return;
              if (!_isLogin) _toggleMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'E-mail',
          hint: 'Enter your email',
          controller: _loginEmailController,
          enabled: !_isAnyAuthLoading,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _loginPasswordController,
          enabled: !_isAnyAuthLoading,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isAnyAuthLoading
                ? null
                : () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Login',
          onPressed: _handleLogin,
          isLoading: _isLoginLoading,
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(),
        const SizedBox(height: 24),
        _buildSwitchText(
          prefix: "Don't have an account? ",
          actionText: 'SignUp',
          onTap: _toggleMode,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'Username',
          hint: 'Enter your username',
          controller: _signupUsernameController,
          enabled: !_isAnyAuthLoading,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'CNIC',
          hint: '1234567890123',
          controller: _signupCnicController,
          enabled: !_isAnyAuthLoading,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card,
          maxLength: 13,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'E-mail',
          hint: 'Enter your email',
          controller: _signupEmailController,
          enabled: !_isAnyAuthLoading,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Password',
          hint: 'Enter password',
          controller: _signupPasswordController,
          enabled: !_isAnyAuthLoading,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          label: 'Confirm Password',
          hint: 'Confirm your password',
          controller: _signupConfirmPasswordController,
          enabled: !_isAnyAuthLoading,
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: 'Sign Up',
          onPressed: _handleSignup,
          isLoading: _isSignupLoading,
        ),
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 16),
        _buildGoogleButton(),
        const SizedBox(height: 20),
        _buildSwitchText(
          prefix: 'Already have an account? ',
          actionText: 'Login',
          onTap: _toggleMode,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppTheme.royalBlue, size: 20)
                : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppTheme.royalBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ProfessionalButton(
      label: label,
      isLoading: isLoading,
      enabled: !_isAnyAuthLoading,
      onPressed: onPressed,
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(thickness: 0.8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(child: Divider(thickness: 0.8)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return GoogleSignInButton(
      label: 'Continue with Google',
      isLoading: _isGoogleLoading,
      enabled: !_isAnyAuthLoading,
      onPressed: _handleGoogleSignIn,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isAnyAuthLoading) return;
    if (!_isCoreReady || _authService == null) {
      _showMessage(
        'Please wait, secure services are still starting.',
        isError: true,
      );
      return;
    }

    _setActiveAuthAction(_AuthAction.google);

    try {
      final result = await _authService!.authenticateWithGoogle(
        isSignupMode: !_isLogin,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        _showMessage(result['message']?.toString() ?? 'Login successful');
        final role = result['role']?.toString();
        final route = role == 'admin' ? '/admin-home' : '/client-main';
        Navigator.of(context).pushReplacementNamed(route);
        return;
      }

      final wasCancelled = result['cancelled'] == true;
      if (wasCancelled) {
        return;
      }

      _showMessage(
        result['message']?.toString() ?? 'Google sign-in failed',
        isError: true,
      );
    } catch (e) {
      if (mounted) {
        _showMessage('Google sign-in error: ${e.toString()}', isError: true);
      }
    } finally {
      _setActiveAuthAction(_AuthAction.none);
    }
  }

  Widget _buildSwitchText({
    required String prefix,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: prefix),
            WidgetSpan(
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  actionText,
                  style: const TextStyle(
                    color: AppTheme.royalBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.royalBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
