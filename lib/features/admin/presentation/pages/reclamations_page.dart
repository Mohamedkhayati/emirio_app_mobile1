import 'package:flutter/material.dart';
import '../widgets/admin_shell.dart';

class ReclamationsPage extends StatelessWidget {
  const ReclamationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 860;

    return AdminShell(
      title: 'Reclamations',
      panelTitle: 'Administrator Panel',
      currentPath: '/admin/reclamations',
      child: AdminPageFrame(
        child: wide
            ? const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _ReclamationsListPanel(),
            ),
            SizedBox(width: 14),
            Expanded(
              flex: 6,
              child: _ReclamationChatPanel(),
            ),
          ],
        )
            : const Column(
          children: [
            _ReclamationsListPanel(),
            SizedBox(height: 14),
            _ReclamationChatPanel(),
          ],
        ),
      ),
    );
  }
}

class _ReclamationsListPanel extends StatelessWidget {
  const _ReclamationsListPanel();

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(18),
            child: AdminSectionTitle(
              title: 'Claims list',
              subtitle: 'Left panel like your React reclamations page.',
            ),
          ),
          Divider(height: 1, color: AdminPalette.stroke),
          _ClaimTile(
            subject: 'Order delivery problem',
            customer: 'Client: Mohamed',
            preview: 'My package is late and tracking did not update.',
            active: true,
            status: 'Open',
          ),
          _ClaimTile(
            subject: 'Damaged product',
            customer: 'Client: Sarra',
            preview: 'The received item has a visible defect.',
            active: false,
            status: 'In Progress',
          ),
          _ClaimTile(
            subject: 'Wrong size sent',
            customer: 'Client: Ali',
            preview: 'I ordered size 42 but received size 41.',
            active: false,
            status: 'Resolved',
          ),
        ],
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final String subject;
  final String customer;
  final String preview;
  final bool active;
  final String status;

  const _ClaimTile({
    required this.subject,
    required this.customer,
    required this.preview,
    required this.active,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFEFF6FF) : Colors.transparent;
    final left = active ? const Color(0xFF3B82F6) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          left: BorderSide(color: left, width: 4),
          bottom: const BorderSide(color: AdminPalette.stroke),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AdminPalette.text,
                  ),
                ),
              ),
              AdminBadge(
                text: status,
                bg: status == 'Resolved'
                    ? AdminPalette.okBg
                    : status == 'In Progress'
                    ? AdminPalette.warningBg
                    : AdminPalette.dangerBg,
                fg: status == 'Resolved'
                    ? AdminPalette.ok
                    : status == 'In Progress'
                    ? const Color(0xFF92400E)
                    : AdminPalette.danger,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customer,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminPalette.muted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AdminPalette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReclamationChatPanel extends StatelessWidget {
  const _ReclamationChatPanel();

  @override
  Widget build(BuildContext context) {
    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminPalette.stroke)),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order delivery problem',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AdminPalette.text,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'From Mohamed • Created 2 hours ago',
                        style: TextStyle(
                          color: AdminPalette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AdminBadge(
                  text: 'Open',
                  bg: AdminPalette.dangerBg,
                  fg: AdminPalette.danger,
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: const [
                _Bubble(
                  isAdmin: false,
                  sender: 'Mohamed',
                  message: 'Hello, my order did not arrive yet. Can you check it please?',
                  time: '10:12',
                ),
                SizedBox(height: 12),
                _Bubble(
                  isAdmin: true,
                  sender: 'Support',
                  message: 'We are checking the shipment now and will update you shortly.',
                  time: '10:17',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                TextField(
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your reply here...',
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AdminPalette.stroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AdminPalette.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: AdminActionButton(
                        text: 'Send reply',
                        onPressed: null,
                        primary: true,
                        icon: Icons.send_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isAdmin;
  final String sender;
  final String message;
  final String time;

  const _Bubble({
    required this.isAdmin,
    required this.sender,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isAdmin ? const Color(0xFF2563EB) : Colors.white;
    final fg = isAdmin ? Colors.white : AdminPalette.text;
    final border = isAdmin ? Colors.transparent : AdminPalette.stroke;

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: TextStyle(
                color: fg.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: fg.withValues(alpha: 0.72),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}