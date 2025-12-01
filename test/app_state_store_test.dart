import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repairmybike/data/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Normalization maps multiple phone formats to one store profile',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppState.clearAuth();
      await AppState.setLastCustomerPhone(null);

      await AppState.setAuth(phone: '9876543210', session: 's1', refresh: 'r1');
      await AppState.setProfile(
        name: 'Alice',
        addr: 'Street 1',
        mail: 'alice@example.com',
      );
      await AppState.setVehicleBrand('TVS');
      await AppState.setVehicleName('NTORQ');

      await AppState.init();
      expect(AppState.fullName, 'Alice');
      expect(AppState.vehicleBrand, 'TVS');
      expect(AppState.vehicleName, 'NTORQ');

      await AppState.setAuth(
        phone: '+91 98765-43210',
        session: 's2',
        refresh: 'r2',
      );
      await AppState.init();
      expect(AppState.fullName, 'Alice');
      expect(AppState.vehicleBrand, 'TVS');
      expect(AppState.vehicleName, 'NTORQ');
    },
  );
}
