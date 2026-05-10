import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _loading = false;
  bool _isOk = false;
  String _msg = '';

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        _emailCtrl.text = args;
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _msg = '';
      _isOk = false;
    });

    try {
      final res = await ApiClient.post('/api/auth/password/reset/confirm', {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'newPassword': _newPassCtrl.text.trim()
      }, auth: false);

      setState(() {
        _msg = (res.body is String && res.body.isNotEmpty) ? res.body : "Mot de passe modifié. Vous pouvez vous connecter.";
        _isOk = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/auth');
      });
    } catch (err) {
      setState(() {
        _msg = "Erreur de validation";
        _isOk = false;
      });
      _shakeCtrl.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: CustomPaint(
        painter: _GradientPainter(),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final sineValue = sin(4 * pi * _shakeCtrl.value);
                return Transform.translate(offset: Offset(sineValue * 8, 0), child: child);
              },
              child: Container(
                width: isMobile ? MediaQuery.of(context).size.width * 0.92 : 1100,
                constraints: const BoxConstraints(minHeight: 560),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 80, offset: Offset(0, 25))],
                ),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    // LEFT SIDE (Form)
                    Expanded(
                      flex: isMobile ? 0 : 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 54),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFFBFBFF)]),
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Confirmer le code', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF15151D))),
                              const SizedBox(height: 6),
                              const Text('Saisissez le code reçu + votre nouveau mot de passe.', style: TextStyle(color: Color(0xFF6B6B78))),
                              const SizedBox(height: 26),

                              _buildInput('Email', 'name@example.com', _emailCtrl, false),
                              const SizedBox(height: 10),
                              _buildInput('Code de vérification', '123456', _codeCtrl, false),
                              const SizedBox(height: 10),
                              _buildInput('Nouveau mot de passe', 'Min 6 caractères', _newPassCtrl, true),
                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]), // Purple gradient
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: _loading
                                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ),
                              ),

                              if (_msg.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isOk ? const Color(0xFFE9FFF2) : const Color(0xFFFFECEC),
                                    border: Border.all(color: _isOk ? const Color(0xFFBFF0D3) : const Color(0xFFFFC6C6)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_msg, style: TextStyle(fontWeight: FontWeight.bold, color: _isOk ? const Color(0xFF0A7A3B) : const Color(0xFFB42318))),
                                ),

                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/forgot-password'),
                                child: const Text('← Renvoyer un code', style: TextStyle(color: Color(0xFFFF2AA1), fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    // RIGHT SIDE (Branding)
                    if (!isMobile)
                      Expanded(
                        flex: 11,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 54),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x19FF0099), Color(0x198B5CF6)]),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('emirio', style: TextStyle(fontSize: 96, letterSpacing: 2, color: Color(0xFF111111), fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Un pas d’avance… un pas d’élégance!', style: TextStyle(fontSize: 26, color: Color(0xFF2A2A33), fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController ctrl, bool isPass) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B78))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: isPass,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E7F2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x8C8B5CF6))),
          ),
        ),
      ],
    );
  }
}

class _GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0B10), Color(0xFF07070B)]
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final glow1 = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x2EFF0099), Colors.transparent],
      ).createShader(Rect.fromCenter(center: Offset(size.width * 0.7, size.height * 0.4), width: 800, height: 800));
    canvas.drawRect(rect, glow1);

    final glow2 = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x388B5CF6), Colors.transparent],
      ).createShader(Rect.fromCenter(center: Offset(size.width * 0.3, size.height * 0.6), width: 650, height: 650));
    canvas.drawRect(rect, glow2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}