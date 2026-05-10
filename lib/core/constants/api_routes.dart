class ApiRoutes {
  static const profile = '/api/profile';

  static const authLogin = '/api/auth/login';
  static const authRegister = '/api/auth/register';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';

  static const products = '/api/products';
  static const favorites = '/api/favorites';
  static const cart = '/api/cart';
  static const contact = '/api/contact';

  static const ordersMy = '/api/orders/my';
  static const ordersPlace = '/api/orders/place';

  static const adminDashboard = '/api/admin/dashboard';
  static const adminCustomers = '/api/admin/customers';
  static const adminWorkers = '/api/admin/workers';
  static const adminOrders = '/api/admin/orders';
  static const adminCatalog = '/api/admin/catalog';
  static const adminReclamations = '/api/admin/reclamations';

  static const chatbotMessage = '/api/chatbot/message';
  static const chatbotHistory = '/api/chatbot/history';
  static const chatbotReset = '/api/chatbot/reset';

  static const articles = '/api/articles';
  static const information = '/api/information';

  // Reclamation routes - no duplicate, just the methods
  static String reclamations() => '/api/reclamations';
  static String reclamationDetail(int id) => '/api/reclamations/$id';
  static String reclamationHistory(int id) => '/api/reclamations/$id/history';
  static String reclamationMessages(int id) => '/api/reclamations/$id/messages';
  static String reclamationStatus(int id) => '/api/reclamations/$id/status';
}