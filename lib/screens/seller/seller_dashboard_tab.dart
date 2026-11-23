import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/seller_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_session_manager.dart';

/// Tab 0 — Dashboard Toko
class SellerDashboardTab extends StatefulWidget {
  final SellerUser? user;
  final SellerStand? stand;
  final ValueChanged<SellerStand>? onStandStatusChanged;
  final VoidCallback? onAddMenuTap;

  const SellerDashboardTab({
    super.key,
    this.user,
    this.stand,
    this.onStandStatusChanged,
    this.onAddMenuTap,
  });

  @override
  State<SellerDashboardTab> createState() => _SellerDashboardTabState();
}

class _SellerDashboardTabState extends State<SellerDashboardTab> {
  final ApiService _api = ApiService();

  SellerDashboardStats? _stats;
  bool _statsLoading = true;
  String? _statsError;

  bool _statusLoading = false;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.stand?.isOpen ?? true;
    _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant SellerDashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stand?.statusToko != widget.stand?.statusToko &&
        widget.stand != null) {
      _isOpen = widget.stand!.isOpen;
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });
    try {
      final stats = await _api.getSellerDashboard();
      if (mounted) {
        setState(() {
          _stats = stats;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString().replaceAll('Exception: ', '');
          _statsLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStandStatus() async {
    if (_statusLoading) return;
    final newStatus = _isOpen ? 'tutup' : 'buka';
    setState(() => _statusLoading = true);
    try {
      await _api.updateStandStatus(status: newStatus);
      await AuthSessionManager.updateStandStatus(newStatus);
      final updatedStand = await AuthSessionManager.getStand();
      if (mounted) {
        setState(() {
          _isOpen = newStatus == 'buka';
          _statusLoading = false;
        });
        if (updatedStand != null) {
          widget.onStandStatusChanged?.call(updatedStand);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 2),
            ),
            content: Row(
              children: [
                Icon(
                  newStatus == 'buka'
                      ? Icons.check_circle_rounded
                      : Icons.block_rounded,
                  color: newStatus == 'buka' ? AppColors.accent : AppColors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newStatus == 'buka'
                        ? 'Toko kini BUKA untuk pembeli.'
                        : 'Toko kini TUTUP sementara.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokoName = widget.stand?.namaToko.trim().isNotEmpty == true
        ? widget.stand!.namaToko
        : (widget.user?.username ?? 'Toko Saya');

    final firstName = widget.stand?.namaLengkap.trim().isNotEmpty == true
        ? widget.stand!.namaLengkap.trim().split(' ').first
        : (widget.user?.username ?? 'Penjual');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                text: 'SISWA',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: AppColors.border,
                ),
                children: [
                  TextSpan(
                    text: 'MART',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Text(
                'PANEL TOKO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loadDashboard,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.border,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: AppColors.border,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.border, height: 2),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // 1. Hero Card Toko + Kontrol Status (Gaya Web Header Card)
            _TokoHeroCard(
              firstName: firstName,
              tokoName: tokoName,
              kelas: widget.stand?.namaKelas,
              fotoUrl: widget.stand?.fotoPenjualUrl,
              isOpen: _isOpen,
              isLoading: _statusLoading,
              onToggle: _toggleStandStatus,
            ),

            const SizedBox(height: 18),

            // 2. Ringkasan Statistik Toko (Grid Bento 2x2)
            Row(
              children: [
                const Text(
                  'Ringkasan Toko',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
                const Spacer(),
                Text(
                  'Data Realtime',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_statsLoading)
              const _StatsSkeleton()
            else if (_statsError != null)
              _StatsError(message: _statsError!, onRetry: _loadDashboard)
            else if (_stats != null)
              _StatsBentoGrid(stats: _stats!),

            const SizedBox(height: 18),

            // 3. Pintasan Cepat
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            _QuickActionButton(
              icon: Icons.add_circle_rounded,
              label: 'Tambah Menu Baru',
              description: 'Daftarkan produk makanan/minuman baru ke toko Anda',
              color: AppColors.primary,
              iconBg: Colors.white,
              iconColor: AppColors.primary,
              onTap: widget.onAddMenuTap,
            ),
            const SizedBox(height: 10),
            _QuickActionButton(
              icon: Icons.restaurant_menu_rounded,
              label: 'Kelola Semua Menu',
              description: 'Atur stok tersedia, harga, dan edit daftar menu toko',
              color: Colors.white,
              iconBg: AppColors.accent,
              iconColor: AppColors.border,
              textColor: AppColors.border,
              onTap: widget.onAddMenuTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Hero Card Toko & Kontrol Status
// ─────────────────────────────────────────────────────────────────────────────
class _TokoHeroCard extends StatelessWidget {
  final String firstName;
  final String tokoName;
  final String? kelas;
  final String? fotoUrl;
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onToggle;

  const _TokoHeroCard({
    required this.firstName,
    required this.tokoName,
    this.kelas,
    this.fotoUrl,
    required this.isOpen,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOpen ? AppColors.green : AppColors.red;
    final statusBg = isOpen ? AppColors.greenLight : const Color(0xFFFEE2E2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Atas: Identitas Pemilik & Toko
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (fotoUrl != null && fotoUrl!.isNotEmpty)
                        ? Image.network(
                            fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront_rounded,
                              size: 26,
                              color: AppColors.border,
                            ),
                          )
                        : const Icon(
                            Icons.storefront_rounded,
                            size: 26,
                            color: AppColors.border,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $firstName! 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tokoName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.border,
                          height: 1.15,
                        ),
                      ),
                      if (kelas != null && kelas!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          kelas!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah
          Container(height: 2, color: AppColors.border),

          // Bagian Bawah: Status Toko + Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'TOKO BUKA' : 'TOKO TUTUP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        isOpen
                            ? 'Pembeli dapat melihat menu toko Anda'
                            : 'Toko disembunyikan sementara dari pembeli',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: isLoading ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isLoading ? AppColors.textMuted : statusColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.8),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment:
                          isOpen ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(3),
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Grid Statistik Bento 2x2
// ─────────────────────────────────────────────────────────────────────────────
class _StatsBentoGrid extends StatelessWidget {
  final SellerDashboardStats stats;
  const _StatsBentoGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Menu',
                value: stats.totalMenu.toString(),
                icon: Icons.restaurant_menu_rounded,
                badgeColor: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Tersedia',
                value: stats.tersedia.toString(),
                icon: Icons.check_circle_rounded,
                badgeColor: AppColors.greenLight,
                iconColor: AppColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Stok Habis',
                value: stats.habis.toString(),
                icon: Icons.cancel_rounded,
                badgeColor: const Color(0xFFFEE2E2),
                iconColor: AppColors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Views Toko',
                value: stats.totalViews.toString(),
                icon: Icons.visibility_rounded,
                badgeColor: const Color(0xFFFEF9C3),
                iconColor: const Color(0xFFA16207),
              ),
            ),
          ],
        ),
        if (stats.menungguModerasi > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.8),
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
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 18,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Menu menunggu moderasi admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.border,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text(
                    stats.menungguModerasi.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color badgeColor;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.badgeColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Skeleton & Error State
// ─────────────────────────────────────────────────────────────────────────────
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(2, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row == 0 ? 10 : 0),
          child: Row(
            children: List.generate(2, (col) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: col == 0 ? 10 : 0),
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _StatsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _StatsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.red, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.red,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Quick Action Button
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color iconBg;
  final Color iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.iconBg,
    required this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: effectiveTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: effectiveTextColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: effectiveTextColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}