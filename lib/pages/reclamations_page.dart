import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/navbar.dart';

class ReclamationsPage extends StatefulWidget {
  const ReclamationsPage({super.key});

  @override
  State<ReclamationsPage> createState() => _ReclamationsPageState();
}

class _ReclamationsPageState extends State<ReclamationsPage> {
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
  void initState() {
    super.initState();
    _fetchReclamations();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReclamations() async {
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
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendReply() async {
    if (_replyCtrl.text.trim().isEmpty || _selected == null) return;
    setState(() => _sending = true);

    try {
      final res = await ApiClient.post(
        '/api/reclamations/${_selected!['id']}/client-messages',
        {'content': _replyCtrl.text.trim()},
      );
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
      case "OPEN":
        return const Color(0xFFFEE2E2);
      case "IN_PROGRESS":
        return const Color(0xFFFEF3C7);
      case "RESOLVED":
        return const Color(0xFFDCFCE7);
      case "CLOSED":
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case "OPEN":
        return const Color(0xFF991B1B);
      case "IN_PROGRESS":
        return const Color(0xFF92400E);
      case "RESOLVED":
        return const Color(0xFF166534);
      case "CLOSED":
        return const Color(0xFF1F2937);
      default:
        return const Color(0xFF1F2937);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isLoggedIn;
    final isClient = auth.user?.role == "Client" || auth.user?.role == "USER";

    if (!isLoggedIn) {
      return MainScaffold(
        currentIndex: 4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view your claims', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return MainScaffold(
      currentIndex: 4,
      showChat: false,
      child: Container(
        color: const Color(0xFFF3F4F6),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 0 : 24.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 0 : 16),
              boxShadow: isMobile ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: isMobile ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Customer Support Center',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      if (isMobile && _selected != null && !_showNewForm)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => setState(() => _selected = null),
                        ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isMobile) {
                        // Mobile layout - show either list or chat
                        if (_selected != null && !_showNewForm) {
                          return _buildChatArea();
                        } else if (_showNewForm) {
                          return _buildNewForm();
                        } else {
                          return _buildListArea(isClient);
                        }
                      } else {
                        // Desktop layout - side by side
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 320,
                              child: _buildListArea(isClient),
                            ),
                            Expanded(
                              child: _showNewForm && isClient
                                  ? _buildNewForm()
                                  : _selected != null
                                  ? _buildChatArea()
                                  : const Center(
                                child: Text(
                                  "Select a claim on the left to view messages.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListArea(bool isClient) {
    return Column(
      children: [
        if (isClient)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showNewForm = true;
                    _selected = null;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New claim', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : _reclamations.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              isClient ? 'No claims yet.\nClick "New claim" to start.' : 'No customer claims to display.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
              : ListView.builder(
            itemCount: _reclamations.length,
            itemBuilder: (ctx, i) {
              final rec = _reclamations[i];
              final isSelected = _selected?['id'] == rec['id'] && !_showNewForm;

              DateTime dt;
              try {
                dt = DateTime.parse(rec['createdAt']);
              } catch (_) {
                dt = DateTime.now();
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selected = rec;
                    _showNewForm = false;
                  });
                  _fetchDetail(rec['id']);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDBEAFE) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec['subject'] ?? 'No subject',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${dt.day}/${dt.month}/${dt.year}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(rec['status']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rec['status'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getStatusTextColor(rec['status']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submit a new claim',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe your issue below and our support team will get back to you shortly.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Missing item in my order',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _descCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Please provide as much detail as possible...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _sending ? null : _handleCreateReclamation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Claim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _showNewForm = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF1F2937),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final messages = _selected!['messages'] ?? [];

    DateTime dt;
    try {
      dt = DateTime.parse(_selected!['createdAt']);
    } catch (_) {
      dt = DateTime.now();
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selected!['subject'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF111827)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(_selected!['status']),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selected!['status'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(_selected!['status']),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ticket created on ${dt.day}/${dt.month}/${dt.year} • ID: #${_selected!['id']}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),

        // Chat History
        Expanded(
          child: Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.all(20),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                final isClientMsg = msg['senderRole'] == "Client" || msg['senderRole'] == "USER";

                DateTime mDt;
                try {
                  mDt = DateTime.parse(msg['timestamp']);
                } catch (_) {
                  mDt = DateTime.now();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isClientMsg ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isClientMsg) ...[
                        const CircleAvatar(
                          backgroundColor: Color(0xFF2563EB),
                          radius: 16,
                          child: Icon(Icons.support_agent, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isClientMsg ? const Color(0xFF3B82F6) : Colors.white,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isClientMsg ? Radius.zero : const Radius.circular(16),
                              bottomLeft: !isClientMsg ? Radius.zero : const Radius.circular(16),
                            ),
                            border: isClientMsg ? null : Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['senderName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isClientMsg ? Colors.blue[100] : const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isClientMsg ? Colors.white : const Color(0xFF1F2937),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${mDt.hour}:${mDt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isClientMsg ? Colors.blue[100] : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isClientMsg) ...[
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          backgroundColor: Color(0xFF1F2937),
                          radius: 16,
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                width: 48,
                child: FloatingActionButton(
                  onPressed: _sending ? null : _handleSendReply,
                  backgroundColor: const Color(0xFF2563EB),
                  elevation: 2,
                  child: _sending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}