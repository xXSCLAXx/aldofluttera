import 'package:backend/backend.dart';
import 'package:test/test.dart';

void main() {
  test('healthResponse returns the service status', () {
    expect(healthResponse(), {'status': 'ok', 'service': 'backend'});
  });
}
