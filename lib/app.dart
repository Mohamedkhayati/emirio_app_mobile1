import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'core/constants/app_colors.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/catalog_page.dart';
import 'pages/favorites_page.dart';
import 'pages/cart_checkout_page.dart';
import 'pages/order_history_page.dart';
import 'pages/profile_page.dart';
import 'pages/about_page.dart';
import 'pages/contact_page.dart';
import 'pages/product_details_page.dart';
import 'pages/auth/auth_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/auth/reset_password_page.dart';
import 'pages/admin/admin_shell_page.dart';
import 'pages/content/articles_page.dart';
import 'pages/content/article_details_page.dart';
import 'pages/reclamations_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class EmirioApp extends StatelessWidget {
  const EmirioApp({super.key});

  Route<dynamic> _route(RouteSettings settings) {
    final name = settings.name ?? '/';
    final uri = Uri.parse(name);

    // Dynamic Route for Product Details
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'product') {
      final id = int.tryParse(uri.pathSegments[1]) ?? 0;
      return MaterialPageRoute(
        builder: (_) => ProductDetailsPage(productId: id),
        settings: settings,
      );
    }

    // Dynamic Route for Article Details
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'articles') {
      final id = int.tryParse(uri.pathSegments[1]) ?? 0;
      return MaterialPageRoute(
        builder: (_) => ArticleDetailsPage(articleId: id),
        settings: settings,
      );
    }

    // Static Routes
    switch (name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
      case '/catalog':
        return MaterialPageRoute(builder: (_) => const CatalogPage(), settings: settings);
      case '/favorites':
        return MaterialPageRoute(builder: (_) => const FavoritesPage(), settings: settings);
      case '/cart':
        return MaterialPageRoute(builder: (_) => const CartCheckoutPage(), settings: settings);
      case '/orders':
        return MaterialPageRoute(builder: (_) => const OrderHistoryPage(), settings: settings);
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage(), settings: settings);
      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutPage(), settings: settings);
      case '/contact':
        return MaterialPageRoute(builder: (_) => const ContactPage(), settings: settings);
      case '/support':
        return MaterialPageRoute(builder: (_) => const ReclamationsPage(), settings: settings);
      case '/auth':
        return MaterialPageRoute(builder: (_) => const AuthPage(), settings: settings);
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage(), settings: settings);
      case '/reset-password':
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage(), settings: settings);
      case '/articles':
        return MaterialPageRoute(builder: (_) => const ArticlesPage(), settings: settings);
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminShellPage(), settings: settings);
      default:
        return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
      ],
      child: MaterialApp(
        title: 'Emirio',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        onGenerateRoute: _route,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
          ),
        ),
      ),
    );
  }
}