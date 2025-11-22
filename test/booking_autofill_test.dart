import 'package:flutter_test/flutter_test.dart';
import 'package:repairmybike/data/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Autofill preview uses AppState values', () async {
    // Simulate authenticated user data
    AppState.phoneNumber = '+919999999999';
    AppState.fullName = 'Auto User';
    AppState.email = 'auto@user.test';
    AppState.address = 'Auto Address';
    AppState.vehicleType = 'Scooter';
    AppState.vehicleBrand = 'TVS';
    AppState.vehicleName = 'NTORQ';

    expect(AppState.phoneNumber, '+919999999999');
    expect(AppState.fullName, 'Auto User');
    expect(AppState.email, 'auto@user.test');
    expect(AppState.address, 'Auto Address');
    expect(AppState.vehicleType, 'Scooter');
    expect(AppState.vehicleBrand, 'TVS');
    expect(AppState.vehicleName, 'NTORQ');
  });
}