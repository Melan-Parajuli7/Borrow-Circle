/// Central location for all application-wide constants.
///
/// Holds the backend base URL, API endpoint paths, and local storage keys.
/// Update [baseUrl] to point to your running Node.js Express server.
class AppConstants {
  AppConstants._();

  /// Base URL of the Node.js Express backend.
  ///
  /// - Android emulator: `http://10.0.2.2:5000` (default)
  /// - iOS simulator:    `http://localhost:5000`
  /// - Physical device:  your computer's LAN IP, e.g.
  ///   `http://192.168.x.x:5000`
  static const String baseUrl = 'http://10.0.2.2:5000';

  /// Base path for all API endpoints.
  static const String apiPrefix = '/api';

  // ---- auth endpoints ----
  static const String registerEndpoint = '/users/register';
  static const String loginEndpoint = '/users/login';
  static const String logoutEndpoint = '/users/logout';
  static const String meEndpoint = '/users/me';
  static const String refreshEndpoint = '/users/refresh';

  // ---- item endpoints ----
  static const String itemsEndpoint = '/items';
  static const String myItemsEndpoint = '/items/my';

  // ---- request endpoints ----
  static const String requestsEndpoint = '/requests';
  static const String myRequestsEndpoint = '/requests/my';
  static const String incomingRequestsEndpoint = '/requests/incoming';

  // ---- loan endpoints ----
  static const String loansEndpoint = '/loans';
  static const String borrowingEndpoint = '/loans/borrowing';
  static const String lendingEndpoint = '/loans/lending';

  // ---- review endpoints ----
  static const String reviewsEndpoint = '/reviews';
  static const String receivedReviewsEndpoint = '/reviews/received';
  static const String givenReviewsEndpoint = '/reviews/given';
  static const String userReviewsEndpoint = '/reviews/user';

  // ---- chat endpoints ----
  static const String chatsEndpoint = '/chats';
  static String chatMessagesEndpoint(int id) => '/chats/$id/messages';
  static String chatReadEndpoint(int id) => '/chats/$id/read';
  static String startLoanChatEndpoint(int loanId) => '/chats/loan/$loanId';
  static const String startAdminChatEndpoint = '/chats/admin';

  /// SharedPreferences key under which the JWT access token is stored.
  static const String tokenKey = 'accessToken';

  /// SharedPreferences key under which the JWT refresh token is stored.
  static const String refreshTokenKey = 'refreshToken';

  /// Google Maps API key (from madpcpsgit2026).
  static const String mapsApiKey = 'AIzaSyDmMzGmGbjESph5OSbXVTktwB3OkVd6W18';
}
