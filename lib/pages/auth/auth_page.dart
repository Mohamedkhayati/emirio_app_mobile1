import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _loading = false;
  String? _errorMsg;
  bool _agreeTerms = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMsg = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await auth.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );

      if (!mounted) return;

      if (success) {
        if (auth.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMsg = 'Incorrect email or password. Please try again.';
          _loading = false;
        });
      }
    } else {
      if (!_agreeTerms) {
        setState(() {
          _errorMsg = 'You must agree to the terms and conditions.';
          _loading = false;
        });
        return;
      }

      // FIXED: Pass all 4 parameters
      final success = await auth.register(
        _nomCtrl.text.trim(),      // nom
        _prenomCtrl.text.trim(),   // prenom
        _emailCtrl.text.trim(),    // email
        _passwordCtrl.text,        // password
      );

      if (!mounted) return;

      if (success) {
        if (auth.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMsg = 'Signup failed. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If already logged in, redirect
    if (auth.isLoggedIn && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (auth.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/');
        }
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEF2FF), Color(0xFFF8F9FC), Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.9)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F0F172A), blurRadius: 60, offset: Offset(0, 24)),
                    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isLogin ? 'Welcome Back' : 'Get Started',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.96,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Log in to access your account' : 'Create an account to start shopping',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    if (_errorMsg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 14, height: 1.5),
                        ),
                      ),

                    // Signup fields
                    if (!_isLogin) ...[
                      _buildInputLabel('Nom'),
                      _buildInputField(controller: _nomCtrl),
                      const SizedBox(height: 12),
                      _buildInputLabel('Prenom'),
                      _buildInputField(controller: _prenomCtrl),
                      const SizedBox(height: 12),
                    ],

                    _buildInputLabel('Email'),
                    _buildInputField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email',
                    ),
                    const SizedBox(height: 12),

                    _buildInputLabel('Password'),
                    _buildInputField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      hintText: _isLogin ? 'Enter your password' : 'Min 8 characters',
                    ),

                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xFFFF2EA6), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                              activeColor: const Color(0xFFFF2EA6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            const Expanded(
                              child: Text(
                                'I agree to the terms & conditions',
                                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Login/Signup Button
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2EA6), Color(0xFFFF6ABF)],
                        ),
                        boxShadow: const [BoxShadow(color: Color(0x33FF2EA6), blurRadius: 22, offset: Offset(0, 10))],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                          _isLogin ? 'Login' : 'Sign Up',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        ),
                        Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Social buttons (placeholder - implement later)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.g_mobiledata, color: Color(0xFF111827)),
                            label: const Text('Google', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
                            label: const Text('Facebook', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Switch Mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? "Don't have an account? " : "Already have an account? ",
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: _switchMode,
                          child: Text(
                            _isLogin ? "Sign Up" : "Log In",
                            style: const TextStyle(color: Color(0xFFFF2EA6), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF111827), fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF2EA6), width: 1.5),
          ),
        ),
      ),
    );
  }
}