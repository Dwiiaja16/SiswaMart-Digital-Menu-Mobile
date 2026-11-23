import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../models/seller_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_session_manager.dart';
import 'seller_dashboard_tab.dart';
import 'seller_menu_tab.dart';
import 'seller_profile_tab.dart';

/// Navigasi utama Penjual — BottomNavigationBar 3 tab:
/// 0 = Dashboard, 1 = Menu Saya, 2 = Profil Stand
class SellerHomeScreen extends StatefulWidget {
  final SellerUser? initialUser;
  final SellerStand? initialStand;

  const SellerHomeScreen({
    super.key,
    this.initialUser,
    this.initialStand,
  });

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;
  int? _pressedIndex;

  SellerUser? _user;
  SellerStand? _stand;
  bool _sessionLoaded = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null || widget.initialStand != null) {
      _user = widget.initialUser;
      _stand = widget.initialStand;
      _sessionLoaded = true;
    }
    _loadSession();
  }

  Future<void> _loadSession() async {
    final user = await AuthSessionManager.getUser();
    final stand = await AuthSessionManager.getStand();
    if (!mounted) return;
    setState(() {
      _user = user;
      _stand = stand;
      _sessionLoaded = true;
    });
  }

  void _onStandUpdated(SellerStand updatedStand) {
    if (!mounted) return;
    setState(() {
      _stand = updatedStand;
    });
  }

  Future<void> _doLogout() async {
    if (_isLoggingOut) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.red,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sesi login penjual pada perangkat ini akan dihapus.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.border,
                        side: const BorderSide(color: AppColors.border, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border, width: 2),
                        ),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
      _user = null;
      _stand = null;
    });

    try {
      await _apiService.logoutSeller();
    } catch (_) {
      // Tetap lanjutkan pembersihan sesi lokal meskipun request API gagal
    }

    await AuthSessionManager.clearSession();
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionLoaded || _isLoggingOut) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    final tabs = [
      SellerDashboardTab(
        user: _user,
        stand: _stand,
        onStandStatusChanged: (s) {
          if (mounted) setState(() => _stand = s);
        },
        onAddMenuTap: () {
          if (mounted) setState(() => _currentIndex = 1);
        },
      ),
      const SellerMenuTab(),
      SellerProfileTab(
        stand: _stand,
        onStandUpdated: _onStandUpdated,
        onLogout: _doLogout,
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(2.5, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                activeIcon: Icons.dashboard_rounded,
                inactiveIcon: Icons.dashboard_outlined,
                label: 'Dashboard',
              ),
              _buildNavItem(
                index: 1,
                activeIcon: Icons.restaurant_menu_rounded,
                inactiveIcon: Icons.restaurant_menu_outlined,
                label: 'Menu Saya',
              ),
              _buildNavItem(
                index: 2,
                activeIcon: Icons.store_rounded,
                inactiveIcon: Icons.store_outlined,
                label: 'Profil Stand',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    final bool isPressed = _pressedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressedIndex = index),
        onTapUp: (_) {
          setState(() {
            _pressedIndex = null;
            _currentIndex = index;
          });
        },
        onTapCancel: () => setState(() => _pressedIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          transform: Matrix4.translationValues(
            isPressed ? 1.5 : 0,
            isPressed ? 1.5 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.border : Colors.transparent,
              width: 1.8,
            ),
            boxShadow: isSelected && !isPressed
                ? const [
                    BoxShadow(
                      color: AppColors.border,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: 17,
                  color: isSelected ? AppColors.border : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected ? AppColors.border : AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}