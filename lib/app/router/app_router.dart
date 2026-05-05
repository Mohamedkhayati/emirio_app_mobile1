import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/catalog/presentation/pages/product_details_page.dart';
import '../../features/cart/presentation/pages/cart_checkout_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/static_pages/presentation/pages/about_page.dart';
import '../../features/static_pages/presentation/pages/contact_page.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/signature_pad_page.dart';
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/admin/presentation/pages/admin_view_page.dart';
import '../../features/admin/presentation/pages/admin_clients_page.dart';
import '../../features/admin/presentation/pages/dashboard_page.dart' as admin_dashboard;
import '../../features/admin/presentation/pages/catalog_page.dart' as admin_catalog;
import '../../features/admin/presentation/pages/orders_page.dart' as admin_orders;
import '../../features/admin/presentation/pages/reclamations_page.dart';
import '../../features/admin/presentation/pages/workers_page.dart';
import '../../features/vendeur/presentation/pages/vendeur_dashboard_page.dart';
import '../../features/vendeur/presentation/pages/vendeur_catalog_wrapper.dart';
import '../../features/vendeur/presentation/pages/vendeur_orders_page.dart';
import '../../core/constants/api_constants.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Public routes
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/catalog',
      builder: (context, state) => const CatalogPage(),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductDetailsPage(
        productId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CartCheckoutPage(),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/orders/history',
      builder: (context, state) => const OrderHistoryPage(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(path: '/about', builder: (context, state) => const AboutPage()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactPage()),

    // Auth routes
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    GoRoute(
      path: '/signature',
      builder: (context, state) => const SignaturePadPage(),
    ),

    // Admin routes
    GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
    GoRoute(
      path: '/admin/view',
      builder: (context, state) => const AdminViewPage(),
    ),
    GoRoute(
      path: '/admin/clients',
      builder: (context, state) => const AdminClientsPage(),
    ),
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const admin_dashboard.DashboardPage(),
    ),
    GoRoute(
      path: '/admin/catalog',
      builder: (context, state) => admin_catalog.CatalogPage(
        baseUrl: ApiConstants.baseUrl,
        authToken: null,
        isAdminGeneral: true,
        isCatalogManager: true,
        isEcommerceManager: true,
      ),
    ),
    GoRoute(
      path: '/admin/orders',
      builder: (context, state) => const admin_orders.OrdersPage(),
    ),
    GoRoute(
      path: '/admin/reclamations',
      builder: (context, state) => const ReclamationsPage(),
    ),
    GoRoute(
      path: '/admin/workers',
      builder: (context, state) => const WorkersPage(),
    ),

    // Vendeur routes
    GoRoute(
      path: '/vendeur/dashboard',
      builder: (context, state) => const VendeurDashboardPage(),
    ),
    GoRoute(
      path: '/vendeur/catalog',
      builder: (context, state) => const VendeurCatalogWrapper(),
    ),
    GoRoute(
      path: '/vendeur/orders',
      builder: (context, state) => const VendeurOrdersPage(),
    ),
  ],
);