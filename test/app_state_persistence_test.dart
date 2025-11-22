import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repairmybike/data/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('No cross-session contamination between different phone numbers', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.init();

    // Simulate phone1
    await AppState.setAuth(phone: '+910000000001', session: 's1', refresh: 'r1');
    await AppState.setVehicleForPhone(phone: '+910000000001', type: 'Bike', brand: 'BAJAJ', name: 'Pulsar');
    await AppState.setProfile(name: 'User One', addr: 'Addr1', mail: 'one@example.com');

    // Simulate logout
    await AppState.clearAuth();

    // Simulate phone2
    await AppState.setAuth(phone: '+910000000002', session: 's2', refresh: 'r2');

    // Ensure no leakage from phone1
    expect(AppState.vehicleBrand, isNull);
    expect(AppState.vehicleName, isNull);
    expect(AppState.fullName, isNull);
    expect(AppState.address, isNull);
    expect(AppState.email, isNull);

    // Now set phone2 data
    await AppState.setVehicleForPhone(phone: '+910000000002', type: 'Scooter', brand: 'TVS', name: 'NTORQ');
    await AppState.setProfile(name: 'User Two', addr: 'Addr2', mail: 'two@example.com');

    // Switch back to phone1 and validate persistence
    await AppState.setAuth(phone: '+910000000001', session: 's1a', refresh: 'r1a');
    expect(AppState.vehicleBrand, 'BAJAJ');
    expect(AppState.vehicleName, 'Pulsar');
    expect(AppState.fullName, 'User One');
    expect(AppState.address, 'Addr1');
    expect(AppState.email, 'one@example.com');
  });
}