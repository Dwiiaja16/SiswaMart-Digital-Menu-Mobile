import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siswamart_mobile/models/seller_model.dart';
import 'package:siswamart_mobile/services/api_service.dart';
import 'package:siswamart_mobile/services/auth_session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SellerModel Tests', () {
    test('Parse SellerUser correctly from JSON', () {
      final json = {
        'user_id': 10,
        'username': 'penjual_spw',
        'email': 'stand@smkn11bdg.sch.id',
        'role': 'penjual',
      };

      final user = SellerUser.fromJson(json);

      expect(user.userId, 10);
      expect(user.username, 'penjual_spw');
      expect(user.email, 'stand@smkn11bdg.sch.id');
      expect(user.role, 'penjual');
      expect(user.toJson(), json);
    });

    test('Parse SellerStand correctly from JSON', () {
      final json = {
        'id_penjual': 5,
        'nama_lengkap': 'Ahmad Dahlan',
        'nama_toko': 'Stand Aneka Gorengan',
        'nama_kelas': 'XII RPL 1',
        'nisn': '0051234567',
        'nomor_whatsapp': '6281234567890',
        'deskripsi': 'Stand kantin depan lantai 1',
        'status_toko': 'buka',
        'foto_penjual_url': 'https://example.com/stand.jpg',
      };

      final stand = SellerStand.fromJson(json);

      expect(stand.idPenjual, 5);
      expect(stand.namaLengkap, 'Ahmad Dahlan');
      expect(stand.namaToko, 'Stand Aneka Gorengan');
      expect(stand.namaKelas, 'XII RPL 1');
      expect(stand.nisn, '0051234567');
      expect(stand.nomorWhatsapp, '6281234567890');
      expect(stand.deskripsi, 'Stand kantin depan lantai 1');
      expect(stand.statusToko, 'buka');
      expect(stand.isOpen, isTrue);
      expect(stand.fotoPenjualUrl, 'https://example.com/stand.jpg');

      final closedStand = stand.copyWith(statusToko: 'tutup');
      expect(closedStand.isOpen, isFalse);
      expect(closedStand.namaToko, stand.namaToko);
    });

    test('Parse SellerDashboardStats correctly from JSON', () {
      final json = {
        'total_menu': 8,
        'tersedia': 6,
        'habis': 2,
        'menunggu_moderasi': 1,
        'disetujui': 7,
        'ditolak': 0,
        'total_views': 350,
      };

      final stats = SellerDashboardStats.fromJson(json);

      expect(stats.totalMenu, 8);
      expect(stats.tersedia, 6);
      expect(stats.habis, 2);
      expect(stats.menungguModerasi, 1);
      expect(stats.disetujui, 7);
      expect(stats.ditolak, 0);
      expect(stats.totalViews, 350);
    });

    test('Parse SellerLoginResult correctly from JSON', () {
      final json = {
        'token': 'mock-sanctum-token-12345',
        'token_type': 'Bearer',
        'user': {
          'user_id': 1,
          'username': 'penjual1',
          'email': 'penjual1@test.com',
          'role': 'penjual',
        },
        'stand': {
          'id_penjual': 1,
          'nama_lengkap': 'Budi Santoso',
          'nama_toko': 'Stand Snack Gurih',
          'nama_kelas': 'XI RPL 2',
          'nisn': '0069876543',
          'nomor_whatsapp': '628987654321',
          'deskripsi': 'Kantin blok B',
          'status_toko': 'buka',
          'foto_penjual_url': null,
        },
      };

      final result = SellerLoginResult.fromJson(json);

      expect(result.token, 'mock-sanctum-token-12345');
      expect(result.tokenType, 'Bearer');
      expect(result.user.username, 'penjual1');
      expect(result.stand?.namaToko, 'Stand Snack Gurih');
      expect(result.stand?.isOpen, isTrue);
    });
  });

  group('AuthSessionManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Save session, retrieve token/user/stand, update status, and clear', () async {
      expect(await AuthSessionManager.isLoggedIn(), isFalse);
      expect(await AuthSessionManager.getToken(), isNull);
      expect(await AuthSessionManager.getUser(), isNull);
      expect(await AuthSessionManager.getStand(), isNull);

      const testUser = SellerUser(
        userId: 2,
        username: 'penjual2',
        email: 'penjual2@smk.id',
        role: 'penjual',
      );

      const testStand = SellerStand(
        idPenjual: 3,
        namaLengkap: 'Siti Aminah',
        namaToko: 'Kedai Minuman Segar',
        namaKelas: 'X Kuliner 1',
        nisn: '0071112223',
        nomorWhatsapp: '6285551234',
        deskripsi: 'Dekat lapangan basket',
        statusToko: 'buka',
      );

      await AuthSessionManager.saveSession(
        token: 'token-abc-xyz',
        user: testUser,
        stand: testStand,
      );

      expect(await AuthSessionManager.isLoggedIn(), isTrue);
      expect(await AuthSessionManager.getToken(), 'token-abc-xyz');

      final savedUser = await AuthSessionManager.getUser();
      expect(savedUser?.username, 'penjual2');

      final savedStand = await AuthSessionManager.getStand();
      expect(savedStand?.namaToko, 'Kedai Minuman Segar');
      expect(savedStand?.isOpen, isTrue);

      // Update stand status
      await AuthSessionManager.updateStandStatus('tutup');
      final updatedStand = await AuthSessionManager.getStand();
      expect(updatedStand?.statusToko, 'tutup');
      expect(updatedStand?.isOpen, isFalse);

      // Clear session
      await AuthSessionManager.clearSession();
      expect(await AuthSessionManager.isLoggedIn(), isFalse);
      expect(await AuthSessionManager.getToken(), isNull);
      expect(await AuthSessionManager.getUser(), isNull);
      expect(await AuthSessionManager.getStand(), isNull);
    });
  });

  group('ApiService Seller Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loginSeller saves session and returns SellerLoginResult', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/seller/login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['login'] == 'valid_user' && body['password'] == 'secret123') {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'message': 'Login penjual berhasil.',
                'data': {
                  'token': 'bearer-mock-token-999',
                  'token_type': 'Bearer',
                  'user': {
                    'user_id': 12,
                    'username': 'valid_user',
                    'email': 'valid@smkn11bdg.sch.id',
                    'role': 'penjual',
                  },
                  'stand': {
                    'id_penjual': 8,
                    'nama_lengkap': 'Rian Hidayat',
                    'nama_toko': 'Rian Dimsum',
                    'nama_kelas': 'XII AKL',
                    'nisn': '0044332211',
                    'nomor_whatsapp': '628111222333',
                    'deskripsi': 'Lantai 2',
                    'status_toko': 'buka',
                    'foto_penjual_url': null,
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          } else {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'message': 'Email/Username atau password salah.',
              }),
              401,
              headers: {'content-type': 'application/json'},
            );
          }
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);

      // Test valid login
      final result = await apiService.loginSeller(
        login: 'valid_user',
        password: 'secret123',
      );

      expect(result.token, 'bearer-mock-token-999');
      expect(result.user.username, 'valid_user');
      expect(result.stand?.namaToko, 'Rian Dimsum');

      // Verify token persisted
      expect(await AuthSessionManager.getToken(), 'bearer-mock-token-999');
      expect(await AuthSessionManager.isLoggedIn(), isTrue);

      // Test invalid credentials
      expect(
        () => apiService.loginSeller(login: 'wrong', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('updateStandStatus sends patch and updates local cache', () async {
      await AuthSessionManager.saveSession(
        token: 'mock-valid-token',
        user: const SellerUser(
          userId: 1,
          username: 'user1',
          email: 'u1@test.com',
          role: 'penjual',
        ),
        stand: const SellerStand(
          idPenjual: 1,
          namaLengkap: 'Test',
          namaToko: 'Toko Test',
          namaKelas: 'X',
          nisn: '123',
          nomorWhatsapp: '081',
          deskripsi: 'Desk',
          statusToko: 'buka',
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/seller/stand/status') &&
            request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'Status stand berhasil diubah.',
              'data': {'status_stand': body['status']},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final newStatus = await apiService.updateStandStatus(status: 'tutup');

      expect(newStatus, 'tutup');
      final updatedStand = await AuthSessionManager.getStand();
      expect(updatedStand?.statusToko, 'tutup');
      expect(updatedStand?.isOpen, isFalse);
    });

    test('logoutSeller deletes server token and clears local session', () async {
      await AuthSessionManager.saveSession(
        token: 'mock-valid-token-to-delete',
        user: const SellerUser(
          userId: 1,
          username: 'user1',
          email: 'u1@test.com',
          role: 'penjual',
        ),
      );

      bool serverLogoutCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/seller/logout')) {
          serverLogoutCalled = true;
          return http.Response(
            jsonEncode({
              'status': 'success',
              'message': 'Logout berhasil.',
              'data': null,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      await apiService.logoutSeller();

      expect(serverLogoutCalled, isTrue);
      expect(await AuthSessionManager.isLoggedIn(), isFalse);
      expect(await AuthSessionManager.getToken(), isNull);
    });
  });
}
