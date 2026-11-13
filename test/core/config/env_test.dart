import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/config/env.dart';

void main() {
  test('the front desk app\'s flavors talk to the same backends as the member app\'s', () {
    for (final (flavor, environment) in [
      ('dev', AppEnvironment.dev),
      ('staffDev', AppEnvironment.dev),
      ('staging', AppEnvironment.staging),
      ('staffStaging', AppEnvironment.staging),
      ('prod', AppEnvironment.prod),
      ('staffProd', AppEnvironment.prod),
      (null, AppEnvironment.dev),
    ]) {
      expect(Env.fromFlavor(flavor).environment, environment, reason: '$flavor');
    }
    expect(Env.fromFlavor('staffProd').usesFakeBackend, isFalse);
  });
}
