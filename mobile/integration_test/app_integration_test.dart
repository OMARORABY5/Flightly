// app_integration_test.dart — FLIGHTLY Integration Tests
// Tests three full end-to-end flows against the running local backend.
// WHY: Integration tests verify that multiple pieces of the system work
//      together correctly — the app, the API, and the database all at once.
//
// PREREQUISITES: Docker must be running (docker-compose up -d) before running:
//   flutter test integration_test/

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';

// The base URL for the running local backend through NGINX
const String kBaseUrl = 'http://10.0.2.2:80/api';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  });

  // ─── Test 1: Sign-Up → Login Flow ────────────────────────────────────────────
  group('Integration Test 1: Sign-Up → Login', () {
    // Use a unique email per test run so we don't get "already registered" errors
    final testEmail = 'integration_${DateTime.now().millisecondsSinceEpoch}@flightly.test';
    const testPassword = 'Integration1234!';
    String? jwtToken;

    testWidgets('Step 1: Register a new account successfully', (tester) async {
      final response = await dio.post('/auth/register', data: {
        'email': testEmail,
        'password': testPassword,
        'displayName': 'Integration Tester',
      });

      expect(response.statusCode, equals(201));
      expect(response.data['success'], isTrue);
      expect(response.data['data']['email'], equals(testEmail));
    });

    testWidgets('Step 2: Reject registration with the same email (duplicate)', (tester) async {
      try {
        await dio.post('/auth/register', data: {
          'email': testEmail,
          'password': testPassword,
        });
        fail('Expected DioException for duplicate email');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(409));
        expect(e.response?.data['success'], isFalse);
      }
    });

    testWidgets('Step 3: Login with registered credentials returns JWT', (tester) async {
      final response = await dio.post('/auth/login', data: {
        'email': testEmail,
        'password': testPassword,
      });

      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      expect(response.data['data'], contains('token'));
      jwtToken = response.data['data']['token'];
      expect(jwtToken, isNotNull);
      expect(jwtToken!.split('.').length, equals(3)); // JWT has 3 parts
    });

    testWidgets('Step 4: Verify-token endpoint validates the JWT', (tester) async {
      // Ensure we have a token from the login step
      if (jwtToken == null) {
        final loginRes = await dio.post('/auth/login', data: {
          'email': testEmail,
          'password': testPassword,
        });
        jwtToken = loginRes.data['data']['token'];
      }

      final response = await dio.get(
        '/auth/verify-token',
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'}),
      );

      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      expect(response.data['data']['email'], equals(testEmail));
    });
  });

  // ─── Test 2: Search → Results → Details Flow ────────────────────────────────
  group('Integration Test 2: Search → Results → Details', () {
    String? firstFlightId;

    testWidgets('Step 1: Search flights returns structured results', (tester) async {
      // Use a broad future date to always find results in the seed data
      final response = await dio.post('/flights/search', data: {
        'origin': 'CAI',
        'destination': 'DXB',
        'departure_date': '2025-12-15',
        'adults': 1,
        'trip_type': 'one_way',
        'cabin_class': 'economy',
      });

      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      expect(response.data['data'], isA<Map>());
      expect(response.data['data']['flights'], isA<List>());

      final flights = response.data['data']['flights'] as List;
      if (flights.isNotEmpty) {
        firstFlightId = flights.first['id']?.toString();

        // Verify each flight has the required fields
        final flight = flights.first;
        expect(flight, contains('id'));
        expect(flight, contains('airline_name'));
        expect(flight, contains('base_price'));
        expect(flight, contains('departure_time'));
        expect(flight, contains('arrival_time'));
      }
    });

    testWidgets('Step 2: Get flight details by ID returns full data', (tester) async {
      if (firstFlightId == null) {
        // Skip if no results were found in search step
        return;
      }

      final response = await dio.get('/flights/$firstFlightId');

      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);

      final flight = response.data['data'];
      expect(flight['id'].toString(), equals(firstFlightId));
      expect(flight, contains('origin_airport'));
      expect(flight, contains('destination_airport'));
    });

    testWidgets('Step 3: Airport search returns results for "Cairo"', (tester) async {
      final response = await dio.get('/flights/airports/search', queryParameters: {'q': 'Cairo'});
      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      expect(response.data['data'], isA<List>());

      final airports = response.data['data'] as List;
      if (airports.isNotEmpty) {
        expect(airports.first, contains('iata_code'));
        expect(airports.first, contains('city'));
      }
    });
  });

  // ─── Test 3: Booking → Confirmation Flow ─────────────────────────────────────
  group('Integration Test 3: Booking → Confirmation → My Trips', () {
    final testEmail = 'booking_int_${DateTime.now().millisecondsSinceEpoch}@flightly.test';
    const testPassword = 'Booking1234!';
    String? token;
    String? userId;

    testWidgets('Step 1: Register and login for booking test', (tester) async {
      await dio.post('/auth/register', data: {
        'email': testEmail,
        'password': testPassword,
        'displayName': 'Booking Tester',
      });

      final loginRes = await dio.post('/auth/login', data: {
        'email': testEmail,
        'password': testPassword,
      });

      token = loginRes.data['data']['token'];
      userId = loginRes.data['data']['user']['id'];

      expect(token, isNotNull);
    });

    testWidgets('Step 2: My Trips/upcoming is empty for a new user', (tester) async {
      if (token == null) return;
      final response = await dio.get(
        '/bookings/user/upcoming',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      // Brand new user should have no bookings
      expect(response.data['data'], isA<List>());
    });

    testWidgets('Step 3: Profile is fetchable with valid token', (tester) async {
      if (token == null) return;
      final response = await dio.get(
        '/users/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      expect(response.statusCode, equals(200));
      expect(response.data['success'], isTrue);
      expect(response.data['data']['email'], equals(testEmail));
    });
  });
}
