import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/admin_models.dart';
import '../../core/services/admin_service.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  List<AdminCustomer> _customers = [];
  List<AdminCustomer> _filteredCustomers = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

  // Selected customer for profile dialog
  AdminCustomer? _selectedCustomer;
  List<CustomerHistoryEntry> _historyEntries = [];
  bool _isLoadingProfile = false;
  int? _busyId;

  // Create customer dialog
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'CLIENT';
  String _selectedStatus = 'ACTIVE';
  bool _isCreating = false;

  final List<String> _roleOptions = ['CLIENT', 'VENDEUR', 'CONTROLEUR'];
  final List<String> _statusOptions = ['ACTIVE', 'BLOCKED', 'DISABLED'];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final customers = await AdminService.fetchCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCustomers = _customers.where((c) =>
        c.fullName.toLowerCase().contains(lowerQuery) ||
            c.email.toLowerCase().contains(lowerQuery)
        ).toList();
      }
    });
  }

  Future<void> _showProfileDialog(AdminCustomer customer) async {
    setState(() {
      _selectedCustomer = customer;
      _isLoadingProfile = true;
      _historyEntries = [];
    });

    try {
      final profile = await AdminService.fetchCustomer(customer.id);
      final history = await AdminService.fetchCustomerHistory(customer.id);

      setState(() {
        _selectedCustomer = profile;
        _historyEntries = history;
        _isLoadingProfile = false;
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => _CustomerProfileDialog(
          customer: _selectedCustomer!,
          historyEntries: _historyEntries,
          isLoading: false,
          busyId: _busyId,
          onStatusChange: _updateStatus,
          onRoleChange: _updateRole,
          onDelete: _deleteCustomer,
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    final action = newStatus == 'ACTIVE' ? 'ACTIVATE' : 'BLOCK';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'ACTIVATE' ? 'Activate' : 'Block'} Customer'),
        content: Text(action == 'ACTIVATE'
            ? 'Are you sure you want to ACTIVATE this customer?'
            : 'Are you sure you want to BLOCK this customer? They will not be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action == 'ACTIVATE' ? 'Activate' : 'Block',
              style: TextStyle(color: action == 'ACTIVATE' ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busyId = id);

    try {
      await AdminService.updateCustomerStatus(id, newStatus);
      await _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyId = null);
    }
  }

  Future<void> _updateRole(int id, String newRole) async {
    setState(() => _busyId = id);

    try {
      final updated = await AdminService.updateCustomerRole(id, newRole);
      await _loadCustomers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to ${AdminService.getRoleDisplayName(newRole)}')),
        );

        // Close dialog if moving from CLIENT to worker role
        if (_selectedCustomer?.role == 'CLIENT' && newRole != 'CLIENT') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User moved to Workers section')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyId = null);
    }
  }

  Future<void> _deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Delete this customer permanently? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busyId = id);

    try {
      await AdminService.deleteCustomer(id);
      await _loadCustomers();
      // Close profile dialog if open
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _busyId = null);
    }
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final request = CreateCustomerRequest(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        statutCompte: _selectedStatus,
      );

      await AdminService.createCustomer(request);

      // Clear form
      _nomController.clear();
      _prenomController.clear();
      _emailController.clear();
      _passwordController.clear();
      _selectedRole = 'CLIENT';
      _selectedStatus = 'ACTIVE';

      await _loadCustomers();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showCreateDialog() {
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRole = 'CLIENT';
    _selectedStatus = 'ACTIVE';

    showDialog(
      context: context,
      builder: (context) => _CreateCustomerDialog(
        formKey: _formKey,
        nomController: _nomController,
        prenomController: _prenomController,
        emailController: _emailController,
        passwordController: _passwordController,
        selectedRole: _selectedRole,
        selectedStatus: _selectedStatus,
        roleOptions: _roleOptions,
        statusOptions: _statusOptions,
        isCreating: _isCreating,
        onRoleChanged: (value) {
          if (value != null) setState(() => _selectedRole = value);
        },
        onStatusChanged: (value) {
          if (value != null) setState(() => _selectedStatus = value);
        },
        onCreate: _createCustomer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
            tooltip: 'Create client',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name / email...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: _filterCustomers,
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredCustomers.length} customers found',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Customers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : _error.isNotEmpty
                ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCustomers,
                  child: const Text('Retry'),
                ),
              ],
            ))
                : _filteredCustomers.isEmpty
                ? const Center(child: Text('No customers found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredCustomers.length,
              itemBuilder: (_, i) {
                final customer = _filteredCustomers[i];
                final isBusy = _busyId == customer.id;
                final statusColor = AdminService.getStatusColor(customer.statutCompte);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppColors.card,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accent.withOpacity(0.2),
                      child: Text(
                        customer.initials,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      customer.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.email, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.statutCompte,
                                style: TextStyle(fontSize: 10, color: statusColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AdminService.getRoleDisplayName(customer.role),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_outline),
                          onPressed: isBusy ? null : () => _showProfileDialog(customer),
                          tooltip: 'Profile',
                        ),
                        if (customer.statutCompte != 'ACTIVE')
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                            onPressed: isBusy ? null : () => _updateStatus(customer.id, 'ACTIVE'),
                            tooltip: 'Activate',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.block, color: AppColors.error),
                            onPressed: isBusy ? null : () => _updateStatus(customer.id, 'BLOCKED'),
                            tooltip: 'Block',
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
    );
  }
}

// Profile Dialog Widget
class _CustomerProfileDialog extends StatefulWidget {
  final AdminCustomer customer;
  final List<CustomerHistoryEntry> historyEntries;
  final bool isLoading;
  final int? busyId;
  final Function(int, String) onStatusChange;
  final Function(int, String) onRoleChange;
  final Function(int) onDelete;

  const _CustomerProfileDialog({
    required this.customer,
    required this.historyEntries,
    required this.isLoading,
    required this.busyId,
    required this.onStatusChange,
    required this.onRoleChange,
    required this.onDelete,
  });

  @override
  State<_CustomerProfileDialog> createState() => _CustomerProfileDialogState();
}

class _CustomerProfileDialogState extends State<_CustomerProfileDialog> {
  final List<String> _statusOptions = ['ACTIVE', 'BLOCKED', 'DISABLED'];
  final List<String> _roleOptions = ['CLIENT', 'VENDEUR', 'CONTROLEUR'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Client Profile',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: widget.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.customer.initials,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.customer.fullName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AdminService.getRoleDisplayName(widget.customer.role)} • ${widget.customer.statutCompte}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Customer info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow('ID', widget.customer.id.toString()),
                    _infoRow('Status', widget.customer.statutCompte),
                    _infoRow('Created', _formatDate(widget.customer.dateDeCreation)),
                    _infoRow('Email', widget.customer.email),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status management
              const Text('Change Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusOptions.map((status) {
                  final isSelected = widget.customer.statutCompte == status;
                  final isBusy = widget.busyId == widget.customer.id;
                  return ElevatedButton(
                    onPressed: isBusy || isSelected
                        ? null
                        : () => widget.onStatusChange(widget.customer.id, status),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.accent : AppColors.card,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: Text(status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Role management
              const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._roleOptions.map((role) {
                    final isSelected = widget.customer.role == role;
                    final isBusy = widget.busyId == widget.customer.id;
                    return ElevatedButton(
                      onPressed: isBusy || isSelected
                          ? null
                          : () => widget.onRoleChange(widget.customer.id, role),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.accent : AppColors.card,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(AdminService.getRoleDisplayName(role)),
                    );
                  }),
                  ElevatedButton(
                    onPressed: widget.busyId == widget.customer.id
                        ? null
                        : () => widget.onDelete(widget.customer.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // History
              const Text('History', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              widget.historyEntries.isEmpty
                  ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('No history', style: TextStyle(color: AppColors.textSecondary))),
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.historyEntries.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                itemBuilder: (_, i) {
                  final entry = widget.historyEntries[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.action,
                              style: const TextStyle(fontSize: 10, color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(entry.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(entry.details ?? '-', style: const TextStyle(color: AppColors.textSecondary)),
                      if (entry.actorEmail != null)
                        Text(
                          'By: ${entry.actorEmail}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Create Customer Dialog
class _CreateCustomerDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomController;
  final TextEditingController prenomController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String selectedRole;
  final String selectedStatus;
  final List<String> roleOptions;
  final List<String> statusOptions;
  final bool isCreating;
  final Function(String?) onRoleChanged;
  final Function(String?) onStatusChanged;
  final VoidCallback onCreate;

  const _CreateCustomerDialog({
    required this.formKey,
    required this.nomController,
    required this.prenomController,
    required this.emailController,
    required this.passwordController,
    required this.selectedRole,
    required this.selectedStatus,
    required this.roleOptions,
    required this.statusOptions,
    required this.isCreating,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Client', style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: prenomController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'First Name *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nomController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Last Name *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Password * (min 8 characters)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: roleOptions.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        AdminService.getRoleDisplayName(role),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: onRoleChanged,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(),
                  ),
                  items: statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status, style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: onStatusChanged,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: isCreating ? null : onCreate,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: isCreating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create Client'),
        ),
      ],
    );
  }
}