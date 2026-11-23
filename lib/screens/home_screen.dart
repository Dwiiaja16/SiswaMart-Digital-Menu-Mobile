import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function({String? search, int? categoryId}) onNavigateToCatalog;
  final VoidCallback? onNavigateToAccount;

  const HomeScreen({
    super.key,
    required this.onNavigateToCatalog,
    this.onNavigateToAccount,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getProducts(
          categoryId: _selectedCategoryId,
          search: _searchQuery,
        ),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _products = results[1] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProductsOnly() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _products = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId =
          (_selectedCategoryId == categoryId) ? null : categoryId;
    });
    _fetchProductsOnly();
  }

  void _applySearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isNotEmpty) {
      widget.onNavigateToCatalog(search: trimmed);
    } else {
      setState(() {
        _searchQuery = '';
      });
      _fetchProductsOnly();
    }
  }

  int get _totalProductCount {
    if (_categories.isEmpty) return _products.length;
    return _categories.fold<int>(0, (sum, cat) => sum + cat.productCount);
  }

  List<Product> get _spotlightProducts {
    if (_products.length <= 4) return _products;
    return _products.take(4).toList();
  }

  Future<void> _openDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(idProduk: product.idProduk),
      ),
    );
    if (mounted) {
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: _loadInitialData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // 0. Top Bar SiswaMart & Tombol Akses Portal Penjual
              _buildTopBar(),

              const SizedBox(height: 12),

              // 1. Hero Card Mobile-Native
              _buildEditorialHero(),

              const SizedBox(height: 16),

              // 2. Search Bar Cepat
              _buildSearchBar(),

              const SizedBox(height: 20),

              // 3. Kategori Pilihan
              _buildCategorySection(),

              const SizedBox(height: 22),

              // 4. Spotlight Horizontal (4 Produk Unggulan)
              if (!_isLoading &&
                  _errorMessage == null &&
                  _products.isNotEmpty) ...[
                _buildSpotlightSection(),
                const SizedBox(height: 22),
              ],

              // 5. Header Grid Produk Populer
              _buildPopularHeader(),

              const SizedBox(height: 12),

              // 6. Grid Produk / Loading / Error
              _buildProductSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: const TextSpan(
            text: 'SISWA',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.border,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'MART',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (widget.onNavigateToAccount != null) {
              widget.onNavigateToAccount!();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.border,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'Portal Penjual',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorialHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Text(
              'Karya Siswa Lokal',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Jajan enak, dukung karya teman sendiri.',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppColors.border,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih menu favoritmu dan langsung terhubung ke WhatsApp penjual tanpa ribet.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.border,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text(
                    '$_totalProductCount Menu Tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => widget.onNavigateToCatalog(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.border,
                        offset: Offset(2.5, 2.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Jelajahi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        onSubmitted: _applySearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.border,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Mau cari risoles, matcha, atau snack apa?',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.border,
            size: 21,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.border,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    _applySearch('');
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _applySearch(_searchController.text),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Text(
                      'Cari',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.border,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KATEGORI PILIHAN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
                letterSpacing: 0.4,
              ),
            ),
            if (_selectedCategoryId != null)
              GestureDetector(
                onTap: () => _onCategorySelected(null),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(
                label: 'Semua',
                count: _totalProductCount,
                isSelected: _selectedCategoryId == null,
                onTap: () => _onCategorySelected(null),
              ),
              ..._categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildCategoryChip(
                    label: cat.name,
                    count: cat.productCount,
                    isSelected: _selectedCategoryId == cat.id,
                    onTap: () => _onCategorySelected(cat.id),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: AppColors.border,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : AppColors.border,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlightSection() {
    final items = _spotlightProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SOROTAN HARI INI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 134,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = items[index];
              return GestureDetector(
                onTap: () => _openDetail(p),
                child: Container(
                  width: 245,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Container(
                          width: 96,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border:
                                Border.all(color: AppColors.border, width: 1.5),
                          ),
                          child: _buildProductThumb(p.imageUrl, iconSize: 28),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.isReady
                                    ? AppColors.greenLight
                                    : AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.border, width: 1.2),
                              ),
                              child: Text(
                                p.isReady ? 'READY' : 'PO',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.border,
                                ),
                              ),
                            ),
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.border,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              p.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    p.formattedPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 13, color: Colors.amber[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      p.ratingAvg.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MENU POPULER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        if (_products.isNotEmpty)
          Text(
            '${_products.length} item',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildProductSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 44),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: 12),
              Text(
                'Menyiapkan menu favorit...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return NeoBrutalistCard(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.red,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Gagal Memuat Produk',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            NeoBrutalistButton(
              label: 'Coba Lagi',
              icon: Icons.refresh_rounded,
              isFullWidth: false,
              color: AppColors.accent,
              textColor: AppColors.border,
              fontSize: 12,
              onPressed: _loadInitialData,
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return NeoBrutalistCard(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 10),
            const Text(
              'Tidak ada produk ditemukan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coba pilih kategori lain atau reset filter yang aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            if (_selectedCategoryId != null || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              NeoBrutalistButton(
                label: 'Reset Filter',
                icon: Icons.restart_alt_rounded,
                isFullWidth: false,
                color: AppColors.primary,
                textColor: Colors.white,
                fontSize: 11,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                borderRadius: 8,
                onPressed: () {
                  _searchController.clear();
                  _selectedCategoryId = null;
                  _searchQuery = '';
                  _fetchProductsOnly();
                },
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => _buildProductCard(_products[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _openDetail(product),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.border,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto + Badge Ready/PO + Rating
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    height: 116,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: _buildProductThumb(product.imageUrl, iconSize: 34),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.isReady
                          ? AppColors.greenLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Text(
                      product.isReady ? 'READY' : 'PO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: product.isReady
                            ? const Color(0xFF14532D)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 12, color: Colors.amber[700]),
                        const SizedBox(width: 2),
                        Text(
                          product.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Nama Toko + Status Buka/Tutup
            Row(
              children: [
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: product.isOpen ? AppColors.green : AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    product.storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Nama Produk
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.border,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Harga & Views
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${product.views}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductThumb(String url, {double iconSize = 34}) {
    if (url.isEmpty) {
      return Center(
        child: Icon(Icons.fastfood_rounded,
            color: AppColors.primary, size: iconSize),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(Icons.fastfood_rounded,
              color: AppColors.primary, size: iconSize),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}