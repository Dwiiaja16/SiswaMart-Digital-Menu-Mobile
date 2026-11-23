import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller_model.dart';

class AuthSessionManager {
  static const String _keyToken = 'siswamart_seller_token';
  static const String _keyUser = 'siswamart_seller_user';
  static const String _keyStand = 'siswamart_seller_stand';

  /// Menyimpan sesi login penjual lengkap secara persisten
  static Future<void> saveSession({
    required String token,
    required SellerUser user,
    SellerStand? stand,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (stand != null) {
      await prefs.setString(_keyStand, jsonEncode(stand.toJson()));
    } else {
      await prefs.remove(_keyStand);
    }
  }

  /// Mengambil Bearer Token yang tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token.trim();
  }

  /// Cek apakah penjual sedang login dan memiliki token valid
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Mengambil data user penjual yang tersimpan
  static Future<SellerUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return SellerUser.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Mengambil data stand penjual yang tersimpan
  static Future<SellerStand?> getStand() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyStand);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return SellerStand.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Memperbarui data stand secara lokal
  static Future<void> updateStand(SellerStand stand) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStand, jsonEncode(stand.toJson()));
  }

  /// Memperbarui status buka/tutup stand pada cache lokal
  static Future<void> updateStandStatus(String newStatus) async {
    final currentStand = await getStand();
    if (currentStand != null) {
      final updated = currentStand.copyWith(statusToko: newStatus);
      await updateStand(updated);
    }
  }

  /// Menghapus seluruh sesi penjual (Logout lokal)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    await prefs.remove(_keyStand);
  }
}
