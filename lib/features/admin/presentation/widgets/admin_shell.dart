import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class AdminPalette {
  static const bg = Color(0xFFF6F7FB);
  static const bgSoft = Color(0xFFF5F7FF);
  static const card = Colors.white;
  static const card2 = Color(0xFFFAFBFF);
  static const text = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const muted2 = Color(0xFF94A3B8);
  static const stroke = Color(0xFFE5E7EB);
  static const stroke2 = Color(0xFFECEFFC);

  static const primary = Color(0xFF5B5EF7);
  static const primary2 = Color(0xFF7C3AED);
  static const ok = Color(0xFF0F7A3A);
  static const okBg = Color(0xFFE8FFF1);
  static const danger = Color(0xFFB42318);
  static const dangerBg = Color(0xFFFFECEC);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFF7E8);

  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 22.0;
}

class AdminShell extends StatelessWidget {
  final String title;
  final String panelTitle;
  final String currentPath;
  final Widget child;

  const AdminShell({
    super.key,
    required this.title,
    required this.panelTitle,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(
        label: 'Clients',
        path: '/admin/clients',
        icon: Icons.groups_rounded,
      ),
      const _NavItem(
        label: 'Workers',
        path: '/admin/workers',
        icon: Icons.badge_rounded,
      ),
      const _NavItem(
        label: 'Reclamations',
        path: '/admin/reclamations',
        icon: Icons.support_agent_rounded,
      ),
      const _NavItem(
        label: 'Catalog',
        path: '/admin/catalog',
        icon: Icons.inventory_2_rounded,
      ),
      const _NavItem(
        label: 'Dashboard',
        path: '/admin/dashboard',
        icon: Icons.dashboard_rounded,
      ),
      const _NavItem(
        label: 'Orders',
        path: '/admin/orders',
        icon: Icons.receipt_long_rounded,
      ),
      const _NavItem(
        label: 'Vendeur Dashboard',
        path: '/vendeur/dashboard',
        icon: Icons.storefront_rounded,
      ),
      const _NavItem(
        label: 'Vendeur Catalog',
        path: '/vendeur/catalog',
        icon: Icons.view_list_rounded,
      ),
      const _NavItem(
        label: 'Vendeur Orders',
        path: '/vendeur/orders',
        icon: Icons.local_shipping_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AdminPalette.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AdminPalette.card,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AdminPalette.text,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AdminPalette.text,
              ),
            ),
            Text(
              panelTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminPalette.muted,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AdminPalette.card,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminPalette.primary, AdminPalette.primary2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AdminPalette.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AdminPalette.primary.withValues(alpha: 0.20),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Text(
                        'E',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMIRIO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Admin Control Panel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AdminPalette.bgSoft,
                  borderRadius: BorderRadius.circular(AdminPalette.radiusMd),
                  border: Border.all(color: AdminPalette.stroke),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.language_rounded, size: 18, color: AdminPalette.muted),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Language: EN',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final active = currentPath == item.path;
                    return _SidebarTile(
                      item: item,
                      active: active,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(item.path);
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}

class AdminPageFrame extends StatelessWidget {
  final Widget child;

  const AdminPageFrame({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AdminPalette.bg, AdminPalette.bgSoft],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }
}

class AdminSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AdminSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminPalette.card,
        borderRadius: BorderRadius.circular(AdminPalette.radiusLg),
        border: Border.all(color: AdminPalette.stroke),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF202754).withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminPalette.muted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminPalette.radiusLg),
        border: Border.all(color: AdminPalette.stroke),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.muted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AdminPalette.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  const AdminActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? ElevatedButton.styleFrom(
      backgroundColor: AdminPalette.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    )
        : OutlinedButton.styleFrom(
      foregroundColor: AdminPalette.text,
      side: const BorderSide(color: AdminPalette.stroke),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );

    return primary
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}

class AdminBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const AdminBadge({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class AdminListTileCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? footer;

  const AdminListTileCard({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminPalette.card2,
        borderRadius: BorderRadius.circular(AdminPalette.radiusMd),
        border: Border.all(color: AdminPalette.stroke),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AdminPalette.text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdminPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  final String hint;

  const AdminSearchField({
    super.key,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AdminPalette.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AdminPalette.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String path;
  final IconData icon;

  const _NavItem({
    required this.label,
    required this.path,
    required this.icon,
  });
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? const LinearGradient(
      colors: [AdminPalette.primary, AdminPalette.primary2],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    )
        : const LinearGradient(
      colors: [Colors.transparent, Colors.transparent],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? Colors.transparent
                : AdminPalette.stroke.withValues(alpha: 0.9),
          ),
          boxShadow: active
              ? [
            BoxShadow(
              color: AdminPalette.primary.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: active ? Colors.white : AdminPalette.text,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: active ? Colors.white : AdminPalette.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}