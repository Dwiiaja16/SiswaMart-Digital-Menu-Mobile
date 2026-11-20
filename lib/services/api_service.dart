import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

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
}
