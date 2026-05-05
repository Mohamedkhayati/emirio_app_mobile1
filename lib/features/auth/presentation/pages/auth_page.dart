import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthPage extends StatefulWidget {
  final String baseUrl;
  final void Function(String token, Map<String, dynamic> me)? onAuthSuccess;

  const AuthPage({
    super.key,
    required this.baseUrl,
    this.onAuthSuccess,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  bool isLogin = true;
  bool loading = false;
  bool agree = false;

  String err = '';
  String ok = '';

  final loginEmailCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();

  final nomCtrl = TextEditingController();
  final prenomCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  OverlayEntry? _alertEntry;

  Uri _uri(String path) {
    final base = Uri.parse(widget.baseUrl);
    return base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
    );
  }

  Future<dynamic> _postJson(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _uri(path),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeResponse(res);
  }

  Future<dynamic> _getJson(String path, String token) async {
    final res = await http.get(
      _uri(path),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decodeResponse(res);
  }

  dynamic _decodeResponse(http.Response res) {
    final body = res.body.trim();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final decoded = body.isEmpty ? {} : jsonDecode(body);
        throw Exception(
          decoded is Map && decoded['message'] != null
              ? decoded['message'].toString()
              : decoded is Map && decoded['error'] != null
              ? decoded['error'].toString()
              : 'Request failed (${res.statusCode})',
        );
      } catch (_) {
        throw Exception(body.isEmpty ? 'Request failed (${res.statusCode})' : body);
      }
    }
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String _extractErrorMessage(Object e, String fallback) {
    final msg = e.toString().replaceFirst('Exception: ', '').trim();
    return msg.isEmpty ? fallback : msg;
  }

  String _getLoginErrorMessage(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('401') ||
        msg.contains('invalid') ||
        msg.contains('incorrect') ||
        msg.contains('wrong') ||
        msg.contains('credentials') ||
        msg.contains('password') ||
        msg.contains('email')) {
      return 'Incorrect email or password. Please check your credentials.';
    }
    return e.toString().replaceFirst('Exception: ', '').trim().isEmpty
        ? 'Login failed. Please try again later.'
        : e.toString().replaceFirst('Exception: ', '').trim();
  }

  Future<void> _syncMeAndGo(String token) async {
    try {
      final me = await _getJson('/api/profile', token);
      widget.onAuthSuccess?.call(token, (me as Map).cast<String, dynamic>());
    } catch (_) {
      widget.onAuthSuccess?.call(token, {});
    }
  }

  void _showTopAlert(String message, {bool success = false}) {
    _alertEntry?.remove();
    final overlay = Overlay.of(context);

    _alertEntry = OverlayEntry(
      builder: (context) => _TopAlert(
        message: message,
        success: success,
        onClose: () {
          _alertEntry?.remove();
          _alertEntry = null;
        },
      ),
    );

    overlay.insert(_alertEntry!);

    Future.delayed(const Duration(seconds: 4), () {
      _alertEntry?.remove();
      _alertEntry = null;
    });
  }

  void _switchMode(bool login) {
    setState(() {
      err = '';
      ok = '';
      isLogin = login;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      err = '';
      ok = '';
      loading = true;
    });

    try {
      if (isLogin) {
        final res = await _postJson('/api/auth/login', {
          'email': loginEmailCtrl.text.trim(),
          'password': loginPasswordCtrl.text,
        });

        final token = (res is Map ? res['token'] : null)?.toString() ?? '';
        if (token.isEmpty) {
          throw Exception('No token returned from login.');
        }

        await _syncMeAndGo(token);

        if (!mounted) return;
        _showTopAlert('Login successful.', success: true);
      } else {
        if (!agree) {
          setState(() {
            loading = false;
            err = 'Please accept the terms.';
          });
          _showTopAlert('Please accept the terms.');
          return;
        }

        await _postJson('/api/auth/signup', {
          'nom': nomCtrl.text.trim(),
          'prenom': prenomCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
        });

        final loginRes = await _postJson('/api/auth/login', {
          'email': emailCtrl.text.trim(),
          'password': passwordCtrl.text,
        });

        final token = (loginRes is Map ? loginRes['token'] : null)?.toString() ?? '';
        if (token.isEmpty) {
          throw Exception('No token returned after signup.');
        }

        await _syncMeAndGo(token);

        if (!mounted) return;
        _showTopAlert('Account created successfully.', success: true);
      }
    } catch (e) {
      final message = isLogin
          ? _getLoginErrorMessage(e)
          : _extractErrorMessage(e, 'Signup failed.');

      setState(() {
        err = message;
      });
      _showTopAlert(message);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    loginEmailCtrl.dispose();
    loginPasswordCtrl.dispose();
    nomCtrl.dispose();
    prenomCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _alertEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Welcome back' : 'Get started';
    final subtitle = isLogin
        ? 'Login to continue your Emirio experience.'
        : 'Create your account to start shopping in style.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFF8F9FC), Color(0xFFEEF2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 960;
                final cardWidth = constraints.maxWidth > 1200 ? 1100.0 : constraints.maxWidth * 0.94;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    width: cardWidth,
                    constraints: const BoxConstraints(minHeight: 620),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xE6E2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.12),
                          blurRadius: 60,
                          offset: Offset(0, 24),
                        ),
                        BoxShadow(
                          color: Color.fromRGBO(15, 23, 42, 0.08),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: mobile
                        ? _buildFormPanel(title, subtitle, mobile: true)
                        : Row(
                      children: isLogin
                          ? [
                        Expanded(child: _buildFormPanel(title, subtitle)),
                        Expanded(child: _buildImagePanel()),
                      ]
                          : [
                        Expanded(child: _buildImagePanel()),
                        Expanded(child: _buildFormPanel(title, subtitle)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(String title, String subtitle, {bool mobile = false}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        final offsetTween = Tween<Offset>(
          begin: isLogin ? const Offset(-0.08, 0) : const Offset(0.08, 0),
          end: Offset.zero,
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetTween.animate(animation), child: child),
        );
      },
      child: Container(
        key: ValueKey(isLogin ? 'login' : 'signup'),
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 18 : 48,
          vertical: mobile ? 28 : 56,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 38,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            if (err.isNotEmpty)
              _inlineAlert(err, error: true),
            if (ok.isNotEmpty)
              _inlineAlert(ok, error: false),
            const SizedBox(height: 8),
            if (isLogin) _buildLoginForm() else _buildSignupForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Email'),
        _input(
          controller: loginEmailCtrl,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        _label('Password'),
        _input(
          controller: loginPasswordCtrl,
          hint: 'Enter your password',
          obscure: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text(
              'Forgot password?',
              style: TextStyle(
                color: Color(0xFFFF2EA6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _primaryButton(
          text: loading ? 'Logging in...' : 'Login',
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: 14),
        _divider(),
        const SizedBox(height: 10),
        _socialButtons(),
        const SizedBox(height: 14),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'No account? ',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              TextButton(
                onPressed: () => _switchMode(false),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Color(0xFFFF2EA6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nom'),
        _input(controller: nomCtrl),
        _label('Prenom'),
        _input(controller: prenomCtrl),
        _label('Email'),
        _input(
          controller: emailCtrl,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
        ),
        _label('Password'),
        _input(
          controller: passwordCtrl,
          hint: 'Minimum 8 characters',
          obscure: true,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: agree,
              activeColor: const Color(0xFFFF2EA6),
              onChanged: (v) => setState(() => agree = v ?? false),
            ),
            const Expanded(
              child: Text(
                'I agree to the terms and conditions',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _primaryButton(
          text: loading ? 'Creating...' : 'Sign up',
          onPressed: loading ? null : _submit,
        ),
        const SizedBox(height: 14),
        _divider(),
        const SizedBox(height: 10),
        _socialButtons(),
        const SizedBox(height: 14),
        Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              TextButton(
                onPressed: () => _switchMode(true),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Color(0xFFFF2EA6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFDF2F8), Color(0xFFF3F4F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/auth-right.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              children: const [
                Text(
                  'emirio',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1.2,
                    color: Color.fromRGBO(17, 24, 39, 0.18),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Un pas d'avance...un pas d'élégance!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Color.fromRGBO(255, 46, 166, 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlineAlert(String message, {required bool error}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: error ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: error ? const Color(0xFFB91C1C) : const Color(0xFF166534),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromRGBO(255, 46, 166, 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2EA6), Color(0xFFFF6ABF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(255, 46, 166, 0.20),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ],
    );
  }

  Widget _socialButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 420;
        final children = [
          Expanded(
            child: _socialButton(
              icon: 'G',
              label: 'Continue with Google',
              onTap: () {
                _showTopAlert('Google login not connected yet.');
              },
            ),
          ),
          if (!stack) const SizedBox(width: 10),
          Expanded(
            child: _socialButton(
              icon: 'f',
              label: 'Continue with Facebook',
              onTap: () {
                _showTopAlert('Facebook login not connected yet.');
              },
            ),
          ),
        ];

        if (stack) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: children[0]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: children[2]),
            ],
          );
        }
        return Row(children: children);
      },
    );
  }

  Widget _socialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFFF3F4F6),
              child: Text(
                icon,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopAlert extends StatefulWidget {
  final String message;
  final bool success;
  final VoidCallback onClose;

  const _TopAlert({
    required this.message,
    required this.success,
    required this.onClose,
  });

  @override
  State<_TopAlert> createState() => _TopAlertState();
}

class _TopAlertState extends State<_TopAlert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.success ? const Color(0xFF52C41A) : const Color(0xFFFF4D4F);

    return Positioned(
      top: 24,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420, minWidth: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        blurRadius: 35,
                        offset: Offset(0, 20),
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Color.alphaBlend(accent.withOpacity(.18), const Color(0xFF0F1014)),
                          const Color(0xFF0F1014),
                        ],
                      ),
                      border: Border(
                        left: BorderSide(color: accent, width: 5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.success ? '✅' : '⚠️',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '✕',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}