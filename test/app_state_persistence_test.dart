import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repairmybike/data/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Secure logout wipes all sensitive and cached data', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.init();

    // 1. Setup authenticated state
    await AppState.setAuth(phone: '+910000000001', session: 's1', refresh: 'r1');
    await AppState.setVehicle(name: 'Pulsar', type: 'Bike', brand: 'BAJAJ');
    await AppState.setProfile(name: 'User One', addr: 'Addr1', mail: 'one@example.com');

    // Verify memory state is set
    expect(AppState.isAuthenticated, isTrue);
    expect(AppState.vehicleName, 'Pulsar');
    expect(AppState.fullName, 'User One');

    // 2. Perform logout
    await AppState.clearAuth();

    // 3. Verify EVERYTHING is wiped
    expect(AppState.isAuthenticated, isFalse);
    expect(AppState.sessionToken, isNull);
    expect(AppState.refreshToken, isNull);
    expect(AppState.phoneNumber, isNull);
    expect(AppState.vehicleName, isNull);
    expect(AppState.vehicleBrand, isNull);
    expect(AppState.vehicleType, isNull);
    expect(AppState.fullName, isNull);
    expect(AppState.address, isNull);
    expect(AppState.email, isNull);
  });
}