import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/seller_model.dart';
import '../services/api_service.dart';
import '../services/auth_session_manager.dart';
import 'seller_login_screen.dart';
import 'seller/seller_home_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isLoggedIn = false;
  SellerUser? _user;
  SellerStand? _stand;

  @override
  void initState() {
    super.initState();
    _loadSessionAndData(autoOpenPortal: true);
  }

  void _resetLocalSellerState({bool loading = false}) {
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _user = null;
      _stand = null;
      _isLoading = loading;
    });
  }

  Future<void> _loadSessionAndData({bool autoOpenPortal = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final token = await AuthSessionManager.getToken();
    if (token == null || token.isEmpty) {
      await AuthSessionManager.clearSession();
      _resetLocalSellerState(loading: false);
      return;
    }

    final localUser = await AuthSessionManager.getUser();
    final localStand = await AuthSessionManager.getStand();

    if (!mounted) return;

    if (autoOpenPortal) {
      _isLoggedIn = true;
      _user = localUser;
      _stand = localStand;
      await _openSellerPortal();
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _user = localUser;
      _stand = localStand;
      _isLoading = false;
    });
  }

  Future<void> _handleLoginSuccess() async {
    final localUser = await AuthSessionManager.getUser();
    final localStand = await AuthSessionManager.getStand();
    if (!mounted) return;

    _isLoggedIn = true;
    _user = localUser;
    _stand = localStand;

    await _openSellerPortal();
  }

  Future<void> _openSellerPortal() async {
    final alreadyLoggedIn = await AuthSessionManager.isLoggedIn();
    if (!mounted) return;

    if (!alreadyLoggedIn) {
      _resetLocalSellerState(loading: false);
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, animation, _) => SellerHomeScreen(
          initialUser: _user,
          initialStand: _stand,
        ),
        transitionsBuilder: (ctx, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.025),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );

    if (mounted) {
      await _loadSessionAndData(autoOpenPortal: false);
    }
  }

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 2.5),
        ),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: AppColors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Keluar Akun Penjual?',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.border,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Anda akan keluar dari sesi penjual SiswaMart pada perangkat ini.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.border,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      _resetLocalSellerState(loading: true);

      try {
        await _apiService.logoutSeller();
      } catch (_) {}

      await AuthSessionManager.clearSession();
      _resetLocalSellerState(loading: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 2),
            ),
            content: const Text(
              'Anda telah keluar dari akun penjual.',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Akun & Portal Stand',
              style: TextStyle(
                color: AppColors.border,
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            Text(
              'SMKN 11 Bandung',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.border, height: 2),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            )
          : !_isLoggedIn
              ? SellerLoginScreen(
                  embedded: true,
                  onLoginSuccess: _handleLoginSuccess,
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: NeoBrutalistCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 30,
                              color: AppColors.border,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _stand?.namaToko.isNotEmpty == true
                                ? _stand!.namaToko
                                : (_user?.username ?? 'Stand Penjual'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.border,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_stand?.namaLengkap ?? '-'} • ${_stand?.namaKelas ?? '-'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openSellerPortal,
                              icon: const Icon(Icons.dashboard_rounded, size: 18),
                              label: const Text(
                                'Masuk ke Dashboard Penjual',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showLogoutDialog,
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text(
                                'Keluar dari Akun',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.red,
                                side: const BorderSide(
                                  color: AppColors.red,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}