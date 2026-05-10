import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _ok = false;
  String _msg = '';

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _msg = '';
      _ok = false;
    });

    try {
      final res = await ApiClient.post('/api/auth/password/reset/request', {'email': _emailCtrl.text.trim()}, auth: false);
      setState(() {
        _msg = (res.body is String && res.body.isNotEmpty) ? res.body : "Code envoyé. Vérifiez votre email.";
        _ok = true;
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/reset-password', arguments: _emailCtrl.text.trim());
        }
      });
    } catch (err) {
      setState(() {
        _msg = "Erreur d'envoi";
        _ok = false;
      });
      _shakeCtrl.forward(from: 0); // Trigger shake!
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
                return Transform.translate(
                  offset: Offset(sineValue * 8, 0), // Shake left/right 8px
                  child: child,
                );
              },
              child: Container(
                width: isMobile ? MediaQuery.of(context).size.width * 0.92 : 1100,
                constraints: const BoxConstraints(minHeight: 520),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Réinitialiser son mot de passe', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF15151D))),
                            const SizedBox(height: 6),
                            const Text('Entrez votre email, on vous envoie un code.', style: TextStyle(color: Color(0xFF6B6B78))),
                            const SizedBox(height: 26),

                            const Text('Email', style: TextStyle(fontSize: 12, color: Color(0xFF6B6B78))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'name@example.com',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E7F2))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0x8CFF0099))),
                              ),
                            ),
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
                                    gradient: const LinearGradient(colors: [Color(0xFFFF2AA1), Color(0xFFFF48C1)]),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _loading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Envoyer le code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                            ),

                            if (_msg.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _ok ? const Color(0xFFE9FFF2) : const Color(0xFFFFECEC),
                                  border: Border.all(color: _ok ? const Color(0xFFBFF0D3) : const Color(0xFFFFC6C6)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_msg, style: TextStyle(fontWeight: FontWeight.bold, color: _ok ? const Color(0xFF0A7A3B) : const Color(0xFFB42318))),
                              )
                          ],
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