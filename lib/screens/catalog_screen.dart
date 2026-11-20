import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialSearch;
  final int? initialKategoriId;

  const CatalogScreen({
    super.key,
    this.initialSearch,
    this.initialKategoriId,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Toggle layout: true = Grid 2 kolom, false = List ringkas
  bool _isGridView = true;

  // Filter state
  int? _selectedCategoryId;
  String _selectedSort = ''; // '' = Paling Populer, 'terbaru', 'termurah'
  String _selectedStock = ''; // '' = Semua, 'ready', 'po'
  int? _minHarga;
  int? _maxHarga;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialSearch ?? '';
    _selectedCategoryId = widget.initialKategoriId;
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldReload = false;
    if (widget.initialSearch != oldWidget.initialSearch &&
        widget.initialSearch != null &&
        widget.initialSearch != _searchController.text) {
      _searchController.text = widget.initialSearch!;
      shouldReload = true;
    }
    if (widget.initialKategoriId != oldWidget.initialKategoriId &&
        widget.initialKategoriId != _selectedCategoryId) {
      _selectedCategoryId = widget.initialKategoriId;
      shouldReload = true;
    }
    if (shouldReload) {
      _fetchProducts();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
          search: _searchController.text.trim(),
          categoryId: _selectedCategoryId,
          statusStok: _selectedStock,
          minHarga: _minHarga,
          maxHarga: _maxHarga,
          sort: _selectedSort,
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _apiService.getProducts(
        search: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        statusStok: _selectedStock,
        minHarga: _minHarga,
        maxHarga: _maxHarga,
        sort: _selectedSort,
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

  void _onSearchChanged(String query) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchProducts();
    });
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId =
          (_selectedCategoryId == categoryId) ? null : categoryId;
    });
    _fetchProducts();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedSort.isNotEmpty) count++;
    if (_selectedStock.isNotEmpty) count++;
    if (_minHarga != null && _minHarga! > 0) count++;
    if (_maxHarga != null && _maxHarga! > 0) count++;
    return count;
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedSort = '';
      _selectedStock = '';
      _minHarga = null;
      _maxHarga = null;
    });
    _fetchProducts();
  }

  int get _totalProductCount {
    if (_categories.isEmpty) return _products.length;
    return _categories.fold<int>(0, (sum, cat) => sum + cat.productCount);
  }

  Future<void> _openProductDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(idProduk: product.idProduk),
      ),
    );
    if (mounted) {
      _fetchProducts();
    }
  }

  void _showFilterBottomSheet() {
    String tempSort = _selectedSort;
    String tempStock = _selectedStock;
    final minController = TextEditingController(
      text: _minHarga != null ? _minHarga.toString() : '',
    );
    final maxController = TextEditingController(
      text: _maxHarga != null ? _maxHarga.toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                22 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 2),
                  left: BorderSide(color: AppColors.border, width: 2),
                  right: BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Urutkan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.border,
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.border, width: 1.5),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Urutkan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Paling Populer',
                          isSelected: tempSort.isEmpty,
                          onTap: () => setModalState(() => tempSort = ''),
                        ),
                        _buildFilterOptionChip(
                          label: 'Terbaru',
                          isSelected: tempSort == 'terbaru',
                          onTap: () =>
                              setModalState(() => tempSort = 'terbaru'),
                        ),
                        _buildFilterOptionChip(
                          label: 'Termurah',
                          isSelected: tempSort == 'termurah',
                          onTap: () =>
                              setModalState(() => tempSort = 'termurah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Status Ketersediaan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: 'Semua',
                          isSelected: tempStock.isEmpty,
                          onTap: () => setModalState(() => tempStock = ''),
                        ),
                        _buildFilterOptionChip(
                          label: 'Ready Stock',
                          isSelected: tempStock == 'ready',
                          onTap: () =>
                              setModalState(() => tempStock = 'ready'),
                        ),
                        _buildFilterOptionChip(
                          label: 'Pre-Order (PO)',
                          isSelected: tempStock == 'po',
                          onTap: () => setModalState(() => tempStock = 'po'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rentang Harga (Rp)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.border, width: 2),
                            ),
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.border,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Minimum',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '–',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: AppColors.border, width: 2),
                            ),
                            child: TextField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.border,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Maksimum',
                                hintStyle: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: NeoBrutalistButton(
                            label: 'Reset',
                            color: Colors.white,
                            textColor: AppColors.border,
                            fontSize: 13,
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              setState(() {
                                _selectedSort = '';
                                _selectedStock = '';
                                _minHarga = null;
                                _maxHarga = null;
                              });
                              _fetchProducts();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: NeoBrutalistButton(
                            label: 'Terapkan',
                            color: AppColors.primary,
                            textColor: Colors.white,
                            fontSize: 13,
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              setState(() {
                                _selectedSort = tempSort;
                                _selectedStock = tempStock;
                                _minHarga =
                                    int.tryParse(minController.text.trim());
                                _maxHarga =
                                    int.tryParse(maxController.text.trim());
                              });
                              _fetchProducts();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(10),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: AppColors.border,
          ),
        ),
      ),
    );
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
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              // 1. Pinned Search Bar + Tombol Filter
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedSearchHeaderDelegate(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AppColors.border, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.border,
                                  offset: Offset(2.5, 2.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.border,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Cari jajanan atau minuman...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.border,
                                  size: 21,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.border,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _fetchProducts();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showFilterBottomSheet,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _activeFilterCount > 0
                                      ? AppColors.primary
                                      : AppColors.accent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.border, width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.border,
                                      offset: Offset(2.5, 2.5),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: _activeFilterCount > 0
                                      ? Colors.white
                                      : AppColors.border,
                                ),
                              ),
                              if (_activeFilterCount > 0)
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: Container(
                                    width: 19,
                                    height: 19,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.border, width: 1.5),
                                    ),
                                    child: Text(
                                      '$_activeFilterCount',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.border,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Chip Kategori Horizontal
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
              ),

              // 3. Filter Aktif & Bar Info + Toggle Grid/List
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeFilterCount > 0) ...[
                        _buildActiveFilterStrip(),
                        const SizedBox(height: 12),
                      ],
                      _buildToolbarBar(),
                    ],
                  ),
                ),
              ),

              // 4. Konten Produk
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: _buildProductSliver(),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildActiveFilterStrip() {
    final List<Widget> chips = [];

    if (_selectedSort.isNotEmpty) {
      final sortLabel = _selectedSort == 'terbaru' ? 'Terbaru' : 'Termurah';
      chips.add(_buildRemovableFilterTag(sortLabel, () {
        setState(() => _selectedSort = '');
        _fetchProducts();
      }));
    }

    if (_selectedStock.isNotEmpty) {
      final stockLabel =
          _selectedStock == 'ready' ? 'Ready Stock' : 'Pre-Order';
      chips.add(_buildRemovableFilterTag(stockLabel, () {
        setState(() => _selectedStock = '');
        _fetchProducts();
      }));
    }

    if (_minHarga != null && _minHarga! > 0) {
      chips.add(_buildRemovableFilterTag('Min Rp $_minHarga', () {
        setState(() => _minHarga = null);
        _fetchProducts();
      }));
    }

    if (_maxHarga != null && _maxHarga! > 0) {
      chips.add(_buildRemovableFilterTag('Maks Rp $_maxHarga', () {
        setState(() => _maxHarga = null);
        _fetchProducts();
      }));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips.map((c) =>
              Padding(padding: const EdgeInsets.only(right: 8), child: c)),
          GestureDetector(
            onTap: _resetAllFilters,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Reset',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemovableFilterTag(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.border,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.close_rounded, size: 13, color: AppColors.border),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarBar() {
    String selectedCatName = 'Semua Menu';
    if (_selectedCategoryId != null) {
      final found = _categories.where((c) => c.id == _selectedCategoryId);
      if (found.isNotEmpty) {
        selectedCatName = found.first.name;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            selectedCatName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: AppColors.border,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              _buildViewModeButton(
                icon: Icons.grid_view_rounded,
                isActive: _isGridView,
                onTap: () => setState(() => _isGridView = true),
              ),
              _buildViewModeButton(
                icon: Icons.view_agenda_rounded,
                isActive: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: AppColors.border,
        ),
      ),
    );
  }

  Widget _buildProductSliver() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
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
                  'Memuat katalog menu...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: NeoBrutalistCard(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 40),
              const SizedBox(height: 10),
              const Text(
                'Gagal Memuat Menu',
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
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
        ),
      );
    }

    if (_products.isEmpty) {
      return SliverToBoxAdapter(
        child: NeoBrutalistCard(
          color: Colors.white,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Menu Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Coba ubah kata kunci pencarian atau hapus filter yang sedang aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              NeoBrutalistButton(
                label: 'Reset Pencarian',
                icon: Icons.restart_alt_rounded,
                isFullWidth: false,
                color: AppColors.primary,
                textColor: Colors.white,
                fontSize: 12,
                onPressed: _resetAllFilters,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isGridView) {
      return SliverList.separated(
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildHorizontalMenuCard(_products[index]),
      );
    }

    return SliverGrid.builder(
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) => _buildGridCatalogCard(_products[index]),
    );
  }

  /// Kartu Grid Mobile-Clean
  Widget _buildGridCatalogCard(Product product) {
    return GestureDetector(
      onTap: () => _openProductDetail(product),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    height: 112,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: _buildProductImage(product.imageUrl, iconSize: 32),
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
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    product.formattedPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '${product.views}x',
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
      ),
    );
  }

  /// Kartu List Ringkas
  Widget _buildHorizontalMenuCard(Product product) {
    return GestureDetector(
      onTap: () => _openProductDetail(product),
      child: Container(
        height: 102,
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
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    width: 84,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: _buildProductImage(product.imageUrl, iconSize: 30),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.isReady
                          ? AppColors.greenLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      product.isReady ? 'READY' : 'PO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: product.isReady
                            ? const Color(0xFF14532D)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color:
                              product.isOpen ? AppColors.green : AppColors.red,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded,
                          size: 13, color: Colors.amber[700]),
                      const SizedBox(width: 2),
                      Text(
                        product.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.border,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                      height: 1.2,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${product.views}x dilihat',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
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
  }

  Widget _buildProductImage(String url, {double iconSize = 34}) {
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

class _PinnedSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PinnedSearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedSearchHeaderDelegate oldDelegate) {
    return true;
  }
}