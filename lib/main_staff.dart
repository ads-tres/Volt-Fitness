import 'app/bootstrap.dart';
import 'staff/app/staff_app.dart';
import 'staff/app/staff_overrides.dart';

/// The front desk app: `flutter run --flavor staffDev -t lib/main_staff.dart`.
Future<void> main() => bootstrap(app: const StaffApp(), overrides: staffOverrides);
