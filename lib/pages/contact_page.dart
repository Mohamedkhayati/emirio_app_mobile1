import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../widgets/navbar.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _msgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _sending = true);
    await ApiClient.post('/api/contact', {
      'name': _nameCtrl.text,
      'email': _emailCtrl.text,
      'message': _msgCtrl.text,
    });
    _nameCtrl.clear(); _emailCtrl.clear(); _msgCtrl.clear();
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent!'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Contact Us', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Container(height: 4, width: 60, color: AppColors.accent),
          const SizedBox(height: 24),
          TextField(controller: _nameCtrl, decoration: _deco('Your Name', Icons.person_outline)),
          const SizedBox(height: 14),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: _deco('Email Address', Icons.email_outlined)),
          const SizedBox(height: 14),
          TextField(controller: _msgCtrl, maxLines: 5,
              decoration: _deco('Your Message', Icons.message_outlined)),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                  label: _sending
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Message', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),
          _infoRow(Icons.location_on_outlined, 'Address', 'Sfax, Tunisia'),
          _infoRow(Icons.email_outlined, 'Email', 'contact@emirio.com'),
          _infoRow(Icons.phone_outlined, 'Phone', '+216 XX XXX XXX'),
        ]),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent)));

  Widget _infoRow(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ]),
      ]));
}