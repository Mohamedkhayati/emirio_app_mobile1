import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  String _error = '';
  String _msg = '';

  // Form Controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  String _dateNaissance = '';
  String _sexe = '';

  File? _localImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/api/profile');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _profileData = data;
          _nomCtrl.text = data['nom'] ?? '';
          _prenomCtrl.text = data['prenom'] ?? '';
          _dateNaissance = data['dateNaissance'] ?? '';
          _sexe = data['sexe'] ?? '';
        });
      }
    } catch (e) {
      _error = 'Failed to load profile';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _calcAge(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final birthDate = DateTime.parse(dateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return '—';
    }
  }

  Future<void> _saveProfile() async {
    if (_nomCtrl.text.trim().isEmpty) return _showError('Last name is required');
    if (_prenomCtrl.text.trim().isEmpty) return _showError('First name is required');

    setState(() {
      _saving = true;
      _error = '';
      _msg = '';
    });

    try {
      final payload = {
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'dateNaissance': _dateNaissance.isNotEmpty ? _dateNaissance : null,
        'sexe': _sexe.isNotEmpty ? _sexe : null,
      };

      final res = await ApiClient.put('/api/profile', payload);

      if (res.statusCode == 200) {
        setState(() {
          _profileData = jsonDecode(res.body);
          _editMode = false;
          _msg = 'Profile updated successfully.';
        });
      } else {
        _showError('Failed to save profile');
      }
    } catch (e) {
      _showError('Error updating profile');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _localImage = File(pickedFile.path);
      _uploadingPhoto = true;
      _error = '';
      _msg = '';
    });

    try {
      final token = await ApiClient.getToken();
      final uri = Uri.parse('${ApiClient.baseUrl}/api/profile/photo');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', _localImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() => _msg = 'Profile photo updated successfully.');
        await _loadProfile();
        setState(() => _localImage = null);
      } else {
        _showError('Failed to upload profile photo.');
      }
    } catch (e) {
      _showError('Error uploading photo.');
    } finally {
      setState(() => _uploadingPhoto = false);
    }
  }

  void _showError(String err) {
    setState(() => _error = err);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _error = '');
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    if (!_editMode) return;

    DateTime? initialDate;
    try { initialDate = DateTime.parse(_dateNaissance); } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFEC4899)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateNaissance = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return MainScaffold(
        currentIndex: 4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: AppColors.border),
              const SizedBox(height: 16),
              const Text('Please login to view your profile', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/auth'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                ),
                child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && _profileData == null) {
      return const MainScaffold(
          currentIndex: 4,
          child: Center(child: CircularProgressIndicator(color: Colors.black))
      );
    }

    final data = _profileData ?? {};
    final avatarInitials = (_prenomCtrl.text.isNotEmpty ? _prenomCtrl.text[0].toUpperCase() : '') +
        (_nomCtrl.text.isNotEmpty ? _nomCtrl.text[0].toUpperCase() : 'U');

    return MainScaffold(
      currentIndex: 4,
      child: Container(
        color: const Color(0xFFF7F7FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP BAR - Fixed overflow with Expanded
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${data['prenom'] ?? 'User'}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Manage your personal information and profile photo.',
                              style: TextStyle(color: Color(0xFF6B7280)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text('Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await auth.logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                          const SizedBox(width: 12),
                          _buildAvatar(null, avatarInitials, size: 40),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // STATS GRID
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Age', _calcAge(_dateNaissance))),
                      const SizedBox(width: 14),
                      Expanded(child: _buildStatCard('Gender', _sexe.isNotEmpty ? _sexe : '—')),
                      const SizedBox(width: 14),
                      Expanded(child: _buildStatCard('Profile status', (data['profileCompleted'] == true) ? 'Complete' : 'Incomplete')),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // MAIN CARD
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.black.withOpacity(0.06)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 40, offset: Offset(0, 16))]
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HERO SECTION
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildAvatar(_localImage, avatarInitials, size: 160, isHero: true),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_prenomCtrl.text} ${_nomCtrl.text}',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(data['email'] ?? '', style: const TextStyle(color: Color(0xFF6B7280))),
                                  const SizedBox(height: 8),
                                  Text(
                                      (data['hasPhoto'] == true || _localImage != null)
                                          ? 'Your profile photo is ready.'
                                          : 'No profile photo yet. Upload one now.',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton(
                                    onPressed: _uploadingPhoto ? null : _pickImage,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF111827),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                                    ),
                                    child: Text(_uploadingPhoto ? 'Uploading...' : 'Upload profile photo', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),

                        if (_error.isNotEmpty || _msg.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: _error.isNotEmpty ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                                border: Border.all(color: _error.isNotEmpty ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
                                borderRadius: BorderRadius.circular(14)
                            ),
                            child: Text(
                                _error.isNotEmpty ? _error : _msg,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _error.isNotEmpty ? const Color(0xFFBE123C) : const Color(0xFF047857)
                                )
                            ),
                          )
                        ],

                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        const SizedBox(height: 16),

                        // HEADER EDIT / SAVE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Personal information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                            Row(
                              children: [
                                if (_editMode)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _editMode = false;
                                        _error = '';
                                        _nomCtrl.text = data['nom'] ?? '';
                                        _prenomCtrl.text = data['prenom'] ?? '';
                                        _dateNaissance = data['dateNaissance'] ?? '';
                                        _sexe = data['sexe'] ?? '';
                                      });
                                    },
                                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_editMode) {
                                      _saveProfile();
                                    } else {
                                      setState(() => _editMode = true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEC4899),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(_editMode ? (_saving ? 'Saving...' : 'Save') : 'Edit', style: const TextStyle(fontWeight: FontWeight.bold)),
                                )
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // FORM FIELDS
                        LayoutBuilder(
                            builder: (context, constraints) {
                              final isMobile = constraints.maxWidth < 600;
                              return GridView.count(
                                crossAxisCount: isMobile ? 1 : 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: isMobile ? 4 : 5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                children: [
                                  _buildTextField('Nom', _nomCtrl),
                                  _buildTextField('Prenom', _prenomCtrl),
                                  _buildReadOnlyField('Email', data['email'] ?? ''),
                                  _buildDatePickerField(context),
                                  _buildDropdownField(),
                                  _buildReadOnlyField('Age', _calcAge(_dateNaissance)),
                                ],
                              );
                            }
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(File? localFile, String initials, {required double size, bool isHero = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF111827),
        border: isHero ? Border.all(color: Colors.white, width: 4) : null,
        boxShadow: isHero ? [const BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))] : [],
      ),
      child: ClipOval(
        child: localFile != null
            ? Image.file(localFile, fit: BoxFit.cover)
            : (_profileData?['hasPhoto'] == true
            ? CachedNetworkImage(
            imageUrl: '${ApiClient.baseUrl}/api/profile/photo',
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => Center(
                child: Text(initials, style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.bold))
            )
        )
            : Center(
            child: Text(initials, style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.bold))
        )
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: _editMode,
            decoration: InputDecoration(
              filled: true,
              fillColor: _editMode ? Colors.white : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB))
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date of birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: _editMode ? Colors.white : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB))
              ),
              child: Text(
                  _dateNaissance.isEmpty ? 'YYYY-MM-DD' : _dateNaissance,
                  style: TextStyle(color: _dateNaissance.isEmpty ? Colors.grey : Colors.black)
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                color: _editMode ? Colors.white : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB))
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sexe.isEmpty ? null : _sexe,
                hint: const Text('Select gender'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                onChanged: _editMode ? (val) => setState(() => _sexe = val ?? '') : null,
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}