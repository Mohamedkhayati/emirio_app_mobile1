import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../providers/auth_provider.dart';

class EmirioReclamationChat extends StatefulWidget {
  const EmirioReclamationChat({super.key});

  @override
  State<EmirioReclamationChat> createState() => _EmirioReclamationChatState();
}

class _EmirioReclamationChatState extends State<EmirioReclamationChat> {
  bool _isOpen = false;
  List<dynamic> _reclamations = [];
  Map<String, dynamic>? _selected;

  bool _loading = false;
  bool _sending = false;
  bool _showNewForm = false;

  final _replyCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _replyCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReclamations() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/reclamations/my');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _reclamations = data is List ? data : [];
          if (_reclamations.isNotEmpty && _selected == null) {
            _selected = _reclamations[0];
            _fetchDetail(_selected!['id']);
          }
        });
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchDetail(int id) async {
    try {
      final res = await ApiClient.get('/api/reclamations/$id');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _selected = data;
          final idx = _reclamations.indexWhere((r) => r['id'] == id);
          if (idx != -1) _reclamations[idx] = data;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _handleSendReply() async {
    if (_replyCtrl.text.trim().isEmpty || _selected == null) return;
    setState(() => _sending = true);

    try {
      final res = await ApiClient.post('/api/reclamations/${_selected!['id']}/client-messages', {'content': _replyCtrl.text.trim()});
      if (res.statusCode == 200 || res.statusCode == 201) {
        _replyCtrl.clear();
        await _fetchDetail(_selected!['id']);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending message')));
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _handleCreateReclamation() async {
    if (_subjectCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);

    try {
      final res = await ApiClient.post('/api/reclamations', {
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        final newRec = jsonDecode(res.body);
        setState(() {
          _reclamations.insert(0, newRec);
          _selected = newRec;
          _showNewForm = false;
          _subjectCtrl.clear();
          _descCtrl.clear();
        });
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error creating claim')));
    } finally {
      setState(() => _sending = false);
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status) {
      case "OPEN": return const Color(0xFFFEE2E2);
      case "IN_PROGRESS": return const Color(0xFFFEF3C7);
      case "RESOLVED": return const Color(0xFFDCFCE7);
      case "CLOSED": return const Color(0xFFF3F4F6);
      default: return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case "OPEN": return const Color(0xFF991B1B);
      case "IN_PROGRESS": return const Color(0xFF92400E);
      case "RESOLVED": return const Color(0xFF166534);
      case "CLOSED": return const Color(0xFF1F2937);
      default: return const Color(0xFF1F2937);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isClient = auth.user?.role == "Client" || auth.user?.role == "USER";

    if (!isLoggedIn) {
      return Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            heroTag: "reclamationBtn",
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/auth'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Stack(
          alignment: Alignment.bottomRight,
          clipBehavior: Clip.none,
          children: [
            if (_isOpen)
              Positioned(
                bottom: 70,
                right: 0,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width > 400 ? 384 : MediaQuery.of(context).size.width - 32,
                    height: 500,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(color: Color(0xFF2563EB), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Customer Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => setState(() => _isOpen = false),
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                decoration: const BoxDecoration(color: Color(0xFFF9FAFB), border: Border(right: BorderSide(color: Color(0xFFE5E7EB)))),
                                child: Column(
                                  children: [
                                    if (isClient)
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => setState(() => _showNewForm = !_showNewForm),
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                                            child: const Text('+ New', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: _loading
                                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                          : _reclamations.isEmpty
                                          ? Padding(padding: const EdgeInsets.all(8), child: Text(isClient ? 'No claims yet' : 'No claims', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)))
                                          : ListView.builder(
                                        itemCount: _reclamations.length,
                                        itemBuilder: (ctx, i) {
                                          final rec = _reclamations[i];
                                          final isSelected = _selected?['id'] == rec['id'] && !_showNewForm;
                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                _selected = rec;
                                                _showNewForm = false;
                                              });
                                              _fetchDetail(rec['id']);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: isSelected ? const Color(0xFFDBEAFE) : Colors.transparent, border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(rec['subject'] ?? 'No subject', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(color: _getStatusBgColor(rec['status']), borderRadius: BorderRadius.circular(4)),
                                                    child: Text(rec['status'] ?? 'Unknown', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _getStatusTextColor(rec['status']))),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _showNewForm && isClient
                                    ? _buildNewForm()
                                    : _selected != null
                                    ? _buildChatArea()
                                    : Center(child: Text(isClient ? "Select a claim or create new" : "Only customers can create claims.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

            FloatingActionButton(
              heroTag: "reclamationBtnActive",
              backgroundColor: const Color(0xFF2563EB),
              child: Icon(_isOpen ? Icons.close : Icons.support_agent, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isOpen = !_isOpen;
                  if (_isOpen) _fetchReclamations();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewForm() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Claim', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(hintText: 'Subject', isDense: true, border: OutlineInputBorder()), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(child: TextField(controller: _descCtrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top, decoration: const InputDecoration(hintText: 'Description', border: OutlineInputBorder()), style: const TextStyle(fontSize: 13))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _sending ? null : _handleCreateReclamation, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white), child: const Text('Submit'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () => setState(() => _showNewForm = false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5E7EB), foregroundColor: Colors.black), child: const Text('Cancel'))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final messages = _selected!['messages'] ?? [];
    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                final isClientMsg = msg['senderRole'] == "Client" || msg['senderRole'] == "USER";
                return Align(
                  alignment: isClientMsg ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(maxWidth: 200),
                    decoration: BoxDecoration(color: isClientMsg ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${msg['senderName']} • ${msg['senderRole']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClientMsg ? Colors.white70 : Colors.black54)),
                        const SizedBox(height: 4),
                        Text(msg['content'] ?? '', style: TextStyle(color: isClientMsg ? Colors.white : const Color(0xFF1F2937), fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _replyCtrl, decoration: const InputDecoration(hintText: 'Type your reply...', isDense: true, border: OutlineInputBorder()), style: const TextStyle(fontSize: 13))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _sending ? null : _handleSendReply, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, minimumSize: const Size(60, 40), padding: EdgeInsets.zero), child: const Text('Send')),
            ],
          ),
        )
      ],
    );
  }
}