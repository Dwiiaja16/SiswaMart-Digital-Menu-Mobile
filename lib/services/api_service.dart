import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/seller_model.dart';
import 'auth_session_manager.dart';

class ApiService {
  static const Map<String, String> headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _get(String endpoint, [Map<String, String>? queryParameters]) async {
    try {
      final baseUri = Uri.parse('$apiBaseUrl$endpoint');
      final cleanParams = <String, String>{};
      if (queryParameters != null) {
        queryParameters.forEach((key, value) {
          if (value.trim().isNotEmpty) {
            cleanParams[key] = value.trim();
          }
        });
      }

      final uri = cleanParams.isNotEmpty
          ? baseUri.replace(queryParameters: cleanParams)
          : baseUri;

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      } else {
        throw Exception(
          'Gagal memuat data dari server (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server: $e');
    }
  }

  /// GET /categories
  Future<List<Category>> getCategories() async {
    final data = await _get('/categories');
    if (data is List) {
      return data
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /products with optional filters:
  /// search, kategoriId, statusStok ('ready'/'po'), minHarga, maxHarga, sort ('terbaru'/'termurah'/'' default populer)
  Future<List<Product>> getProducts({
    String? search,
    int? categoryId,
    int? kategoriId,
    String? statusStok,
    dynamic minHarga,
    dynamic maxHarga,
    String? sort,
    Map<String, String>? query,
  }) async {
    final params = Map<String, String>.from(query ?? {});

    final effectiveCatId = kategoriId ?? categoryId;
    if (effectiveCatId != null && effectiveCatId > 0) {
      params['kategori_id'] = effectiveCatId.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (statusStok != null && statusStok.trim().isNotEmpty) {
      params['status_stok'] = statusStok.trim().toLowerCase();
    }
    if (minHarga != null && minHarga.toString().trim().isNotEmpty) {
      params['min_harga'] = minHarga.toString().trim();
    }
    if (maxHarga != null && maxHarga.toString().trim().isNotEmpty) {
      params['max_harga'] = maxHarga.toString().trim();
    }
    if (sort != null && sort.trim().isNotEmpty) {
      params['sort'] = sort.trim().toLowerCase();
    }

    final data = await _get('/products', params);
    if (data is List) {
      return data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /products/:id
  /// Server otomatis menambah views +1 saat endpoint ini dipanggil
  Future<ProductDetailModel> getProductDetail(int id) async {
    final data = await _get('/products/$id');
    return ProductDetailModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /products/:idProduk/reviews
  /// Body JSON: { "nama_pengunjung", "rating", "komentar" }
  /// Jika HTTP status 422, lempar pesan error dari field `message` JSON (validasi & filter kata kasar)
  Future<Map<String, dynamic>> submitReview(
    int idProduk,
    String namaPengunjung,
    int rating,
    String komentar,
  ) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/products/$idProduk/reviews');
      final body = jsonEncode({
        'nama_pengunjung': namaPengunjung.trim(),
        'rating': rating,
        'komentar': komentar.trim(),
      });

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'status': 'success'};
      } else if (response.statusCode == 422) {
        String errorMessage = 'Ulasan tidak dapat dikirim karena validasi gagal.';
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
        throw Exception(errorMessage);
      } else {
        String msg = 'Gagal mengirim ulasan (HTTP ${response.statusCode})';
        if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
          msg = decoded['message'].toString();
        }
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengirim ulasan: $e');
    }
  }

  /// Compatibility aliases
  Future<List<Category>> categories() => getCategories();
  Future<List<Product>> products({
    String? search,
    int? categoryId,
    int? kategoriId,
    String? statusStok,
    dynamic minHarga,
    dynamic maxHarga,
    String? sort,
    Map<String, String>? query,
  }) =>
      getProducts(
        search: search,
        categoryId: categoryId,
        kategoriId: kategoriId,
        statusStok: statusStok,
        minHarga: minHarga,
        maxHarga: maxHarga,
        sort: sort,
        query: query,
      );

  Future<ProductDetailModel> product(int id) => getProductDetail(id);

  // ==========================================
  // SELLER / PENJUAL API ENDPOINTS (STAGE 1)
  // ==========================================

  /// POST /api/seller/login
  /// Autentikasi Penjual & perolehan Bearer Token
  Future<SellerLoginResult> loginSeller({
    required String login,
    required String password,
    bool persistSession = true,
  }) async {
    try {
      final uri = Uri.parse('$sellerApiBaseUrl/login');
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'login': login.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final result = SellerLoginResult.fromJson(
            decoded['data'] as Map<String, dynamic>,
          );
          if (persistSession) {
            await AuthSessionManager.saveSession(
              token: result.token,
              user: result.user,
              stand: result.stand,
            );
          }
          return result;
        }
        throw Exception('Format respon server tidak valid.');
      } else {
        final message = (decoded is Map<String, dynamic> && decoded['message'] != null)
            ? decoded['message'].toString()
            : 'Login gagal (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server login: $e');
    }
  }

  /// POST /api/seller/logout
  /// Menghapus token autentikasi di server & membersihkan sesi lokal
  Future<void> logoutSeller({String? token}) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    try {
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        final uri = Uri.parse('$sellerApiBaseUrl/logout');
        await _client.post(
          uri,
          headers: {
            ...headers,
            'Authorization': 'Bearer $effectiveToken',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Abaikan error jaringan saat logout agar sesi lokal tetap bersih
    } finally {
      await AuthSessionManager.clearSession();
    }
  }

  /// GET /api/seller/me
  /// Mengambil profil autentikasi dan data stand terkini dari server
  Future<Map<String, dynamic>> getSellerMe({String? token}) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }

    try {
      final uri = Uri.parse('$sellerApiBaseUrl/me');
      final response = await _client.get(
        uri,
        headers: {
          ...headers,
          'Authorization': 'Bearer $effectiveToken',
        },
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final data = decoded['data'] as Map<String, dynamic>;
          if (data['stand'] != null) {
            final stand = SellerStand.fromJson(data['stand'] as Map<String, dynamic>);
            await AuthSessionManager.updateStand(stand);
          }
          return data;
        }
        return decoded as Map<String, dynamic>;
      } else {
        final message = decoded is Map<String, dynamic> && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Gagal memuat profil (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengambil profil penjual: $e');
    }
  }

  /// GET /api/seller/dashboard
  /// Statistik ringkasan produk & stand penjual
  Future<SellerDashboardStats> getSellerDashboard({String? token}) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }

    try {
      final uri = Uri.parse('$sellerApiBaseUrl/dashboard');
      final response = await _client.get(
        uri,
        headers: {
          ...headers,
          'Authorization': 'Bearer $effectiveToken',
        },
      ).timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('data') &&
            decoded['data'] is Map<String, dynamic> &&
            decoded['data']['statistik'] != null) {
          return SellerDashboardStats.fromJson(
            decoded['data']['statistik'] as Map<String, dynamic>,
          );
        }
        throw Exception('Data statistik tidak valid.');
      } else {
        final message = decoded is Map<String, dynamic> && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Gagal memuat dashboard stand (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memuat dashboard stand: $e');
    }
  }

  /// PATCH /api/seller/stand/status
  /// Buka / tutup stand penjual ('buka' | 'tutup')
  Future<String> updateStandStatus({
    required String status,
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }

    try {
      final uri = Uri.parse('$sellerApiBaseUrl/stand/status');
      final response = await _client
          .patch(
            uri,
            headers: {
              ...headers,
              'Authorization': 'Bearer $effectiveToken',
            },
            body: jsonEncode({'status': status.toLowerCase()}),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final normalized = status.toLowerCase();
        await AuthSessionManager.updateStandStatus(normalized);
        return normalized;
      } else {
        final message = decoded is Map<String, dynamic> && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Gagal mengubah status stand (${response.statusCode})';
        throw Exception(message);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghubungi server untuk ubah status: $e');
    }
  }

  // ==========================================
  // SELLER PRODUCT CRUD ENDPOINTS (STAGE 2)
  // ==========================================

  Map<String, String> _authHeader(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/seller/products
  Future<List<Map<String, dynamic>>> getSellerProducts({
    String? search,
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    try {
      var baseUri = Uri.parse('$sellerApiBaseUrl/products');
      if (search != null && search.trim().isNotEmpty) {
        baseUri = baseUri.replace(queryParameters: {'search': search.trim()});
      }
      final response = await _client
          .get(baseUri, headers: _authHeader(effectiveToken))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        if (raw is List) {
          return raw.cast<Map<String, dynamic>>();
        }
        return [];
      }
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal memuat produk (${response.statusCode})';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal memuat produk penjual: $e');
    }
  }

  /// PATCH /api/seller/products/{id}/stock
  Future<void> updateSellerProductStock({
    required int productId,
    required String statusStok,
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    try {
      final uri = Uri.parse('$sellerApiBaseUrl/products/$productId/stock');
      final response = await _client
          .patch(
            uri,
            headers: {
              ..._authHeader(effectiveToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'status_stok': statusStok}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal mengubah stok (${response.statusCode})';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal mengubah stok: $e');
    }
  }

  /// DELETE /api/seller/products/{id}
  Future<void> deleteSellerProduct({
    required int productId,
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    try {
      final uri = Uri.parse('$sellerApiBaseUrl/products/$productId');
      final response = await _client
          .delete(uri, headers: _authHeader(effectiveToken))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Gagal menghapus produk (${response.statusCode})';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  /// POST /api/seller/products  (tambah, multipart/form-data)
  /// POST /api/seller/products/{id}  dengan field _method=PUT (edit)
  Future<Map<String, dynamic>> upsertSellerProduct({
    required Map<String, String> fields,
    String? imagePath,
    int? productId,
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    try {
      final endpoint = productId != null
          ? '$sellerApiBaseUrl/products/$productId'
          : '$sellerApiBaseUrl/products';
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $effectiveToken'
        ..headers['Accept'] = 'application/json';
      if (productId != null) {
        request.fields['_method'] = 'PUT';
      }
      fields.forEach((k, v) => request.fields[k] = v);
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('foto', imagePath));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded is Map<String, dynamic> ? decoded : {'status': 'success'};
      }
      String msg = 'Gagal menyimpan produk (${response.statusCode})';
      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'].toString();
      } else if (decoded is Map && decoded['errors'] != null) {
        final errors = decoded['errors'] as Map;
        msg = errors.values.first is List
            ? (errors.values.first as List).first.toString()
            : errors.values.first.toString();
      }
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal menyimpan produk: $e');
    }
  }

  /// GET /api/seller/categories  (untuk form)
  Future<List<Map<String, dynamic>>> getSellerCategories({
    String? token,
  }) async {
    final effectiveToken = token ?? await AuthSessionManager.getToken();
    if (effectiveToken == null || effectiveToken.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
    try {
      final uri = Uri.parse('$apiBaseUrl/categories');
      final response = await _client
          .get(uri, headers: _authHeader(effectiveToken))
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final raw = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        if (raw is List) return raw.cast<Map<String, dynamic>>();
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
