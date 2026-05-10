import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/reclamation_model.dart';

class AdminReclamationsPage extends StatefulWidget {
  const AdminReclamationsPage({super.key});

  @override
  State<AdminReclamationsPage> createState() => _AdminReclamationsPageState();
}

class _AdminReclamationsPageState extends State<AdminReclamationsPage> {
  List<ReclamationModel> _reclamations = [];
  bool _loading = true;
  String _error = '';
  String _selectedFilter = 'ALL';

  // Selected reclamation for chat view
  ReclamationModel? _selectedReclamation;

  // Reply message
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;
  bool _updatingStatus = false;

  // Scroll controller for messages
  final ScrollController _messagesScrollController = ScrollController();

  // History data
  List<ReclamationHistoryEntry> _historyEntries = [];
  bool _loadingHistory = false;

  final List<String> _statuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

  final Map<String, StatusConfig> _statusConfig = {
    'OPEN': StatusConfig(label: 'Open', color: AppColors.warning),
    'IN_PROGRESS': StatusConfig(label: 'In Progress', color: AppColors.accent),
    'RESOLVED': StatusConfig(label: 'Resolved', color: AppColors.success),
    'CLOSED': StatusConfig(label: 'Closed', color: AppColors.textSecondary),
  };

  @override
  void initState() {
    super.initState();
    _loadReclamations();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReclamations() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await ApiClient.get(ApiRoutes.reclamations());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _reclamations = data.map((json) => ReclamationModel.fromJson(json)).toList();
          _loading = false;
        });
      } else {
        throw Exception('Failed to load reclamations');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReclamationDetail(int id) async {
    try {
      final response = await ApiClient.get(ApiRoutes.reclamationDetail(id));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updated = ReclamationModel.fromJson(data);

        setState(() {
          final index = _reclamations.indexWhere((r) => r.id == id);
          if (index != -1) {
            _reclamations[index] = updated;
          }
          _selectedReclamation = updated;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messagesScrollController.hasClients) {
            _messagesScrollController.jumpTo(_messagesScrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading detail: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty || _selectedReclamation == null) return;

    setState(() => _sending = true);

    try {
      final response = await ApiClient.post(
        ApiRoutes.reclamationMessages(_selectedReclamation!.id),
        {'content': _replyController.text.trim()},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _replyController.clear();
        await _loadReclamationDetail(_selectedReclamation!.id);
        await _loadReclamations();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_selectedReclamation == null) return;

    setState(() => _updatingStatus = true);

    try {
      final response = await ApiClient.patch(
        ApiRoutes.reclamationStatus(_selectedReclamation!.id),
        body: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        await _loadReclamationDetail(_selectedReclamation!.id);
        await _loadReclamations();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to ${_statusConfig[newStatus]?.label ?? newStatus}')),
          );
        }
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _updatingStatus = false);
    }
  }

  Future<void> _showHistoryModal() async {
    if (_selectedReclamation == null) return;

    setState(() {
      _loadingHistory = true;
      _historyEntries = [];
    });

    try {
      final response = await ApiClient.get(ApiRoutes.reclamationHistory(_selectedReclamation!.id));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _historyEntries = data.map((json) => ReclamationHistoryEntry.fromJson(json)).toList();
          _loadingHistory = false;
        });

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => _HistoryModal(
            historyEntries: _historyEntries,
            loadingHistory: _loadingHistory,
            formatDate: _formatDate,
          ),
        );
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      setState(() {
        _historyEntries = [];
        _loadingHistory = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<ReclamationModel> get _filteredReclamations {
    if (_selectedFilter == 'ALL') return _reclamations;
    return _reclamations.where((r) => r.status == _selectedFilter).toList();
  }

  int get _userClaimCount {
    if (_selectedReclamation?.userEmail == null) return 0;
    return _reclamations.where((r) => r.userEmail == _selectedReclamation!.userEmail).length;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return _formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReclamations, child: const Text('Retry')),
          ],
        ),
      )
          : Row(
        children: [
          // Left sidebar
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer Claims', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('OPEN', 'Open'),
                            const SizedBox(width: 8),
                            _buildFilterChip('IN_PROGRESS', 'In Progress'),
                            const SizedBox(width: 8),
                            _buildFilterChip('RESOLVED', 'Resolved'),
                            const SizedBox(width: 8),
                            _buildFilterChip('CLOSED', 'Closed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredReclamations.isEmpty
                      ? const Center(child: Text('No reclamations found'))
                      : ListView.builder(
                    itemCount: _filteredReclamations.length,
                    itemBuilder: (_, i) {
                      final rec = _filteredReclamations[i];
                      final isSelected = _selectedReclamation?.id == rec.id;
                      final statusConfig = _statusConfig[rec.status] ?? _statusConfig['OPEN']!;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedReclamation = rec);
                          _loadReclamationDetail(rec.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      rec.subject,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusConfig.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      statusConfig.label,
                                      style: TextStyle(fontSize: 10, color: statusConfig.color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec.userName ?? rec.userEmail ?? 'Unknown',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right side - chat panel
          Expanded(
            child: _selectedReclamation == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Select a claim to view conversation', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
                : Column(
              children: [
                // Chat header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedReclamation!.subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'From: ${_selectedReclamation!.userName ?? _selectedReclamation!.userEmail ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Created ${_formatTimeAgo(_selectedReclamation!.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildActionButton('👤 Client Info', () => _showClientInfoModal()),
                          const SizedBox(width: 8),
                          _buildActionButton('📜 History', _showHistoryModal),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedReclamation!.status,
                              underline: const SizedBox(),
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: AppColors.textPrimary),
                              items: _statuses.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(_statusConfig[status]?.label ?? status),
                                );
                              }).toList(),
                              onChanged: _updatingStatus ? null : (value) {
                                if (value != null) _updateStatus(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Messages area
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: ListView.builder(
                      controller: _messagesScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _selectedReclamation!.messages.length,
                      itemBuilder: (_, i) {
                        final msg = _selectedReclamation!.messages[i];
                        final isAdmin = msg.senderRole.toLowerCase() == 'admin';

                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Column(
                              crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? AppColors.accent : AppColors.card,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.senderName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isAdmin ? Colors.white70 : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.content,
                                        style: TextStyle(
                                          color: isAdmin ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isAdmin ? Colors.white60 : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Reply area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _replyController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Type your reply here... (customer will receive an email)',
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _sending || _replyController.text.trim().isEmpty ? null : _sendReply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                            ),
                            child: _sending
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Text('Send reply'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'The customer will receive an email with your reply.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      backgroundColor: AppColors.card,
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showClientInfoModal() {
    if (_selectedReclamation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Expanded(child: Text('Customer Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name:', _selectedReclamation!.userName ?? '—'),
            _infoRow('Email:', _selectedReclamation!.userEmail ?? '—'),
            _infoRow('User ID:', _selectedReclamation!.userId?.toString() ?? '—'),
            _infoRow('Total claims:', _userClaimCount.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// History Modal Widget (separate class to avoid duplication)
class _HistoryModal extends StatelessWidget {
  final List<ReclamationHistoryEntry> historyEntries;
  final bool loadingHistory;
  final String Function(DateTime) formatDate;

  const _HistoryModal({
    required this.historyEntries,
    required this.loadingHistory,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Expanded(child: Text('Reclamation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: loadingHistory
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : historyEntries.isEmpty
            ? const Center(child: Text('No history available'))
            : ListView.separated(
          itemCount: historyEntries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final entry = historyEntries[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.getActionIcon(), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(entry.actorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Text('(${entry.actorRole})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.getActionDisplayName(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (entry.action == 'STATUS_CHANGED')
                          Text(
                            'Changed from ${entry.oldValue ?? '-'} → ${entry.newValue ?? '-'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        if (entry.details != null)
                          Text(entry.details!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(entry.createdAt),
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class StatusConfig {
  final String label;
  final Color color;

  StatusConfig({required this.label, required this.color});
}