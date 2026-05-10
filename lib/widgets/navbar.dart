// lib/widgets/navbar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

// Import both chat widgets!
import 'chatbot_overlay.dart'; // The AI Chatbot
import 'reclamation_floating_chat.dart'; // The Support/Reclamations Chat

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool showChat;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    this.showChat = true,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    // Check if trying to access admin panel
    if (index == 5) {
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    // Check if trying to access support/reclamations from bottom nav
    if (index == 6) {
      Navigator.pushReplacementNamed(context, '/support');
      return;
    }

    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/'); break;
      case 1: Navigator.pushReplacementNamed(context, '/catalog'); break;
      case 2: Navigator.pushReplacementNamed(context, '/cart'); break;
      case 3: Navigator.pushReplacementNamed(context, '/favorites'); break;
      case 4: Navigator.pushReplacementNamed(context, '/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;
    final userRole = auth.normalizedRole;

    // Build bottom navigation items
    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Shop'),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Cart'),
      const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Saved'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];

    // Add Support/Reclamations item for all users
    navItems.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.support_agent),
        label: 'Support',
      ),
    );

    // Add Admin item if user has admin role
    if (isAdmin) {
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    // Determine current index for bottom nav
    int displayIndex = currentIndex;

    // Ensure index is within bounds
    if (displayIndex >= navItems.length) {
      displayIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Emirio',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            // Show role badge for admin users
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      userRole.length > 15 ? '${userRole.substring(0, 12)}...' : userRole,
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
          ],
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Admin quick access icon
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.accent),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
              tooltip: 'Go to Admin Panel',
            ),
          // Support icon
          IconButton(
            icon: const Icon(Icons.support_agent, color: AppColors.accent),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/support');
            },
            tooltip: 'Support',
          ),
        ],
      ),
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: showChat ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            EmirioFloatingChat(),
            EmirioReclamationChat(),
          ],
        ),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: displayIndex,
        onTap: (i) => _onItemTapped(context, i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        items: navItems,
      ),
    );
  }
}