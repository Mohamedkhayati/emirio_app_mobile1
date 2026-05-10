import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../providers/auth_provider.dart';

class EmirioFloatingChat extends StatefulWidget {
  const EmirioFloatingChat({super.key});

  @override
  State<EmirioFloatingChat> createState() => _EmirioFloatingChatState();
}

class _EmirioFloatingChatState extends State<EmirioFloatingChat> {
  bool _isOpen = false;
  bool _stylistMode = false;

  List<Map<String, dynamic>> _normalMessages = [];
  List<Map<String, dynamic>> _stylistMessages = [];

  bool _sending = false;
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentMessages => _stylistMode ? _stylistMessages : _normalMessages;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final normalData = prefs.getString('chat_normal_messages');
    final stylistData = prefs.getString('chat_stylist_messages');

    if (normalData != null) {
      _normalMessages = List<Map<String, dynamic>>.from(jsonDecode(normalData));
    }
    if (stylistData != null) {
      _stylistMessages = List<Map<String, dynamic>>.from(jsonDecode(stylistData));
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_normal_messages', jsonEncode(_normalMessages));
    await prefs.setString('chat_stylist_messages', jsonEncode(_stylistMessages));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sending) return;

    final userMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'text': text.trim(),
      'sender': 'user',
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      if (_stylistMode) {
        _stylistMessages.add(userMsg);
      } else {
        _normalMessages.add(userMsg);
      }
      _sending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();
    _saveHistory();

    try {
      final endpoint = _stylistMode ? '/api/stylist/advice' : '/api/chat/send';
      final res = await ApiClient.post(endpoint, {'question': userMsg['text']});

      final botMsg = {
        'id': DateTime.now().millisecondsSinceEpoch + 1,
        'text': res.statusCode == 200 ? jsonDecode(res.body)['answer'] : 'Error loading response',
        'sender': 'bot',
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        if (_stylistMode) {
          _stylistMessages.add(botMsg);
        } else {
          _normalMessages.add(botMsg);
        }
      });
    } catch (err) {
      final errorMsg = {
        'id': DateTime.now().millisecondsSinceEpoch + 1,
        'text': 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        'sender': 'bot',
        'timestamp': DateTime.now().toIso8601String(),
        'isError': true,
      };
      setState(() {
        if (_stylistMode) {
          _stylistMessages.add(errorMsg);
        } else {
          _normalMessages.add(errorMsg);
        }
      });
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
      _saveHistory();
    }
  }

  List<String> get _suggestedQuestions => _stylistMode
      ? [
    "Quelles chaussures avec un jean bleu ?",
    "Conseille-moi une tenue pour un mariage",
    "Quel style de basket pour le sport ?",
    "Sandales élégantes pour l'été ?",
    "Bottines pour une robe noire ?"
  ]
      : [
    "Quels sont vos horaires d'ouverture ?",
    "Où se trouve votre boutique ?",
    "Avez-vous des chaussures Nike en stock ?",
    "Quel est l'article le plus vendu ?",
    "Y a-t-il des promotions en cours ?",
    "Listez tous les articles disponibles"
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Not logged in -> button goes to Auth page
    if (!auth.isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 16), // Adjusted to bottom left
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF2563EB),
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16), // React version was aligned left
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            if (_isOpen)
              Positioned(
                bottom: 70, // Above the FAB
                left: 0,
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: MediaQuery.of(context).size.width > 400 ? 380 : MediaQuery.of(context).size.width - 32,
                    height: 550,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        // --- HEADER ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🤖 ${_stylistMode ? "Conseiller Style" : "Assistant Emirio"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _stylistMode = !_stylistMode);
                                      _scrollToBottom();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _stylistMode ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: _stylistMode ? const [BoxShadow(color: Color(0xFF10B981), blurRadius: 5)] : [],
                                      ),
                                      child: Text('💡 ${_stylistMode ? "Mode Style ON" : "Conseil Style"}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => setState(() => _isOpen = false),
                                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        // --- MESSAGES AREA ---
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.all(16),
                            child: _currentMessages.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                              controller: _scrollCtrl,
                              itemCount: _currentMessages.length + (_sending ? 1 : 0),
                              itemBuilder: (ctx, i) {
                                if (i == _currentMessages.length) {
                                  return _buildTypingIndicator();
                                }

                                final msg = _currentMessages[i];
                                final isUser = msg['sender'] == 'user';

                                DateTime dt;
                                try { dt = DateTime.parse(msg['timestamp']); } catch (_) { dt = DateTime.now(); }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Align(
                                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isUser ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(18).copyWith(
                                          bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                                          bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
                                        ),
                                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(msg['text'] ?? '', style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1F2937), fontSize: 14, height: 1.4)),
                                          const SizedBox(height: 5),
                                          Text('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 10, color: isUser ? Colors.white70 : Colors.black54)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // --- INPUT FORM ---
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0))), borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _inputCtrl,
                                  maxLines: 2, minLines: 1,
                                  decoration: InputDecoration(
                                    hintText: _stylistMode ? "💡 Conseil style – Posez votre question..." : "Écrivez votre message...",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFF2563EB))),
                                    isDense: true,
                                  ),
                                  onSubmitted: (val) => _sendMessage(val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _sendMessage(_inputCtrl.text),
                                child: Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(color: _sending ? Colors.grey : const Color(0xFF2563EB), shape: BoxShape.circle),
                                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

            // MAIN FAB TOGGLE
            FloatingActionButton(
              backgroundColor: _isOpen ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
              onPressed: () {
                setState(() => _isOpen = !_isOpen);
                if (_isOpen) _scrollToBottom();
              },
              child: Icon(_isOpen ? Icons.close : Icons.chat_bubble_outline, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _stylistMode
                  ? [
                const Text('✨ Mode Conseil Style activé ! ✨', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Posez-moi vos questions sur les tenues, les couleurs et les chaussures qui correspondent.'),
                const SizedBox(height: 8),
                const Text('Exemples :'),
                const Text('👖 "Quelles chaussures avec un jean noir ?"'),
                const Text('👗 "Bottines pour une robe rouge ?"'),
                const Text('🏃 "Baskets confortables pour la ville ?"'),
              ]
                  : [
                const Text('👋 Bonjour ! Je suis l\'assistant d\'Emirio Chaussures.', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Posez-moi des questions sur :'),
                const SizedBox(height: 8),
                const Text('📍 Nos boutiques et coordonnées'),
                const Text('👟 Disponibilité des articles'),
                const Text('🏆 Meilleures ventes'),
                const Text('🔥 Promotions en cours'),
                const Text('📋 Catalogue complet'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Cliquez sur une question :', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: _suggestedQuestions.map((q) => GestureDetector(
              onTap: () => _sendMessage(q),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(20)),
                child: Text(q, style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12)),
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFE5E7EB),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _typingDot(), const SizedBox(width: 4), _typingDot(), const SizedBox(width: 4), _typingDot(),
          ],
        ),
      ),
    );
  }

  Widget _typingDot() {
    return Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF9CA3AF), shape: BoxShape.circle));
  }
}