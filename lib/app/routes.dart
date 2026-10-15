abstract final class AppRoutes {
  /// The welcome pages, shown once before the first sign-in.
  static const welcome = '/welcome';
  static const login = '/login';
  static const verify = '/login/verify';
  static const selectGym = '/select-gym';
  static const noGym = '/no-gym';

  // The five bottom navigation tabs.
  static const home = '/home';
  static const membership = '/membership';
  static const qr = '/qr';
  static const payments = '/payments';
  static const profile = '/profile';

  // Pages inside a tab, with the navigation bar still showing.
  static const visits = '/home/visits';
  static const devices = '/profile/devices';
  static String invoice(String id) => '/payments/invoices/$id';

  // Full-screen, above the tabs.
  static String checkout(String attemptId) => '/checkout/$attemptId';

  /// [left] when the member closed the checkout before Chapa sent them back.
  static String paymentResult(String attemptId, {bool left = false}) =>
      '/payment-result/$attemptId${left ? '?left=1' : ''}';
}
