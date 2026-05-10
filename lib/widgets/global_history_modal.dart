import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/models/history_entry_model.dart';

class GlobalHistoryModal extends StatefulWidget {
  final Future<List<HistoryEntryModel>> Function({
  String? action,
  String? targetType,
  String? searchTerm,
  DateTime? dateFrom,
  DateTime? dateTo,
  int limit,
  }) fetchGlobalHistory;

  const GlobalHistoryModal({
    super.key,
    required this.fetchGlobalHistory,
  });

  @override
  State<GlobalHistoryModal> createState() => _GlobalHistoryModalState();
}

class _GlobalHistoryModalState extends State<GlobalHistoryModal> {
  List<HistoryEntryModel> _entries = [];
  List<HistoryEntryModel> _filteredEntries = [];
  bool _isLoading = true;
  String _error = '';

  String _action = 'ALL';
  String _targetType = 'ALL';
  String _searchTerm = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final entries = await widget.fetchGlobalHistory();
      setState(() {
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<HistoryEntryModel>.from(_entries);

    if (_action != 'ALL') {
      filtered = filtered.where((e) => e.action == _action).toList();
    }
    if (_targetType != 'ALL') {
      filtered = filtered.where((e) => e.targetType == _targetType).toList();
    }
    if (_searchTerm.isNotEmpty) {
      final searchLower = _searchTerm.toLowerCase();
      filtered = filtered.where((e) =>
      (e.articleName?.toLowerCase().contains(searchLower) ?? false) ||
          (e.variationLabel?.toLowerCase().contains(searchLower) ?? false) ||
          e.summary.toLowerCase().contains(searchLower) ||
          e.actorName.toLowerCase().contains(searchLower)
      ).toList();
    }
    if (_dateFrom != null) {
      filtered = filtered.where((e) => e.actionAt.isAfter(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      final endOfDay = DateTime(_dateTo!.year, _dateTo!.month, _dateTo!.day, 23, 59, 59, 999);
      filtered = filtered.where((e) => e.actionAt.isBefore(endOfDay)).toList();
    }

    setState(() => _filteredEntries = filtered);
  }

  void _resetFilters() {
    setState(() {
      _action = 'ALL';
      _targetType = 'ALL';
      _searchTerm = '';
      _dateFrom = null;
      _dateTo = null;
      _filteredEntries = _entries;
    });
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'CREATE': return AppColors.success;
      case 'DELETE': return AppColors.error;
      case 'UPDATE': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _getTargetTypeLabel(String targetType) {
    switch (targetType) {
      case 'ARTICLE': return 'Article';
      case 'VARIATION': return 'Variation';
      default: return targetType;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final stats = {
      'total': _entries.length,
      'created': _entries.where((e) => e.action == 'CREATE').length,
      'updated': _entries.where((e) => e.action == 'UPDATE').length,
      'deleted': _entries.where((e) => e.action == 'DELETE').length,
    };

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HISTORY', style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text('Catalog Activity History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Track who created, edited, or deleted articles and variations.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildStatCard('Total', stats['total']!),
                _buildStatCard('Created', stats['created']!, color: AppColors.success),
                _buildStatCard('Edited', stats['updated']!, color: AppColors.warning),
                _buildStatCard('Deleted', stats['deleted']!, color: AppColors.error),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        _searchTerm = value;
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: _action,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Action',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['ALL', 'CREATE', 'UPDATE', 'DELETE'].map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text(a, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _action = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: _targetType,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['ALL', 'ARTICLE', 'VARIATION'].map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _targetType = value!);
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'From',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _dateFrom = date);
                          _applyFilters();
                        }
                      },
                      controller: TextEditingController(
                        text: _dateFrom != null ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}' : '',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'To',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _dateTo = date);
                          _applyFilters();
                        }
                      },
                      controller: TextEditingController(
                        text: _dateTo != null ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}' : '',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                    label: const Text('Clear filters', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Text('${_filteredEntries.length} results', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                if (_action != 'ALL')
                  Chip(
                    label: Text(_action, style: const TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.border,
                    onDeleted: () {
                      setState(() => _action = 'ALL');
                      _applyFilters();
                    },
                  ),
                if (_targetType != 'ALL')
                  Chip(
                    label: Text(_getTargetTypeLabel(_targetType), style: const TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.border,
                    onDeleted: () {
                      setState(() => _targetType = 'ALL');
                      _applyFilters();
                    },
                  ),
                if (_searchTerm.isNotEmpty)
                  Chip(
                    label: Text(_searchTerm, style: const TextStyle(color: AppColors.textPrimary)),
                    backgroundColor: AppColors.border,
                    onDeleted: () {
                      setState(() => _searchTerm = '');
                      _applyFilters();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: AppColors.error)))
                  : _filteredEntries.isEmpty
                  ? const Center(child: Text('No history matches these filters.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                itemCount: _filteredEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final e = _filteredEntries[i];
                  return _buildHistoryCard(e);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color ?? AppColors.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoryEntryModel entry) {
    final actionColor = _getActionColor(entry.action);

    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(entry.actorName),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(entry.action, style: TextStyle(fontSize: 10, color: actionColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_getTargetTypeLabel(entry.targetType), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.articleName ?? entry.variationLabel ?? entry.summary,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (entry.summary.isNotEmpty && entry.summary != entry.articleName)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(entry.summary, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(entry.actorName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(_formatDate(entry.actionAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  if (entry.detailsJson != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ExpansionTile(
                        title: const Text('View Details', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        backgroundColor: AppColors.card,
                        collapsedBackgroundColor: AppColors.card,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(entry.detailsJson!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}