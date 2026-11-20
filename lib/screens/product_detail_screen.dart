import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int idProduk;

  const ProductDetailScreen({
    super.key,
    required this.idProduk,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();

  ProductDetailModel? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _apiService.getProductDetail(widget.idProduk);
      if (mounted) {
        setState(() {
          _product = detail;
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

  Future<void> _orderViaWhatsApp(ProductDetailModel product) async {
    final rawPhone = product.penjual.nomorWhatsapp.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WhatsApp penjual belum tersedia.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Bersihkan nomor WhatsApp: ubah 08xxx menjadi 628xxx
    String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final message =
        'Halo ${product.namaToko}, saya tertarik memesan *${product.namaProduk}* (${product.formattedPrice}) yang ada di aplikasi SiswaMart. Apakah masih tersedia?';
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp terpasang.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka WhatsApp: $e'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showReviewBottomSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('saved_visitor_name') ?? '';

    if (!mounted) return;

    final nameController = TextEditingController(text: savedName);
    final commentController = TextEditingController();
    int selectedRating = 5;
    bool isSubmitting = false;
    String? formError;

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
                14,
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

                    // Header Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.border, width: 1.6),
                              ),
                              child: const Icon(
                                Icons.rate_review_rounded,
                                size: 18,
                                color: AppColors.border,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Tulis Ulasan Produk',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.border,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
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
                    const SizedBox(height: 14),

                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.red, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.red, size: 19),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'Rating Bintang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= selectedRating;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedRating = star),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              isFilled
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 32,
                              color: isFilled
                                  ? Colors.amber[700]
                                  : AppColors.textMuted,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Nama Anda',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.border,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Rian / Siswa XII RPL 1',
                          hintStyle: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Komentar Ulasan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: TextField(
                        controller: commentController,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.border,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Ceritakan rasa, porsi, atau rekomendasi menu ini...',
                          hintStyle: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    NeoBrutalistButton(
                      label: isSubmitting ? 'Mengirim...' : 'Kirim Ulasan',
                      icon: isSubmitting ? null : Icons.send_rounded,
                      color: AppColors.primary,
                      textColor: Colors.white,
                      fontSize: 13,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final comment = commentController.text.trim();

                              if (name.isEmpty) {
                                setModalState(() {
                                  formError = 'Nama Anda wajib diisi.';
                                });
                                return;
                              }

                              if (comment.isEmpty) {
                                setModalState(() {
                                  formError = 'Komentar ulasan wajib diisi.';
                                });
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                                formError = null;
                              });

                              try {
                                await _apiService.submitReview(
                                  widget.idProduk,
                                  name,
                                  selectedRating,
                                  comment,
                                );

                                await prefs.setString(
                                    'saved_visitor_name', name);

                                if (mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Ulasan berhasil dikirim. Terima kasih!'),
                                      backgroundColor: AppColors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  _loadProductDetail();
                                }
                              } catch (err) {
                                setModalState(() {
                                  formError = err
                                      .toString()
                                      .replaceAll('Exception: ', '');
                                  isSubmitting = false;
                                });
                              }
                            },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
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
                  Icons.arrow_back_rounded,
                  size: 19,
                  color: AppColors.border,
                ),
              ),
            ),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detail Menu',
                style: TextStyle(
                  color: AppColors.border,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.3,
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
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: AppColors.border,
            height: 2,
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar:
          _product != null ? _buildStickyBottomBar(_product!) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: 12),
            Text(
              'Memuat detail menu...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: NeoBrutalistCard(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.red,
                  size: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gagal Memuat Detail',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'Terjadi kesalahan sistem.',
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
                  onPressed: _loadProductDetail,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: _loadProductDetail,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // 1. Galeri Foto Produk
          _buildImageGallery(product),

          const SizedBox(height: 14),

          // 2. Info Utama Produk
          _buildMainInfo(product),

          const SizedBox(height: 14),

          // 3. Kartu Toko Penjual
          _buildSellerCard(product),

          const SizedBox(height: 14),

          // 4. Deskripsi Produk
          _buildDescriptionCard(product),

          const SizedBox(height: 14),

          // 5. Bagian Ulasan Pembeli
          _buildReviewsSection(product),
        ],
      ),
    );
  }

  /// 1. Galeri Foto Produk
  Widget _buildImageGallery(ProductDetailModel product) {
    final images = product.displayImages;

    return Container(
      height: 245,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            offset: Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (images.isNotEmpty)
              PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.fastfood_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            else
              const Center(
                child: Icon(
                  Icons.fastfood_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),

            if (images.length > 1) ...[
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${images.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    final active = index == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.border, width: 1.2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 2. Info Utama Produk
  Widget _buildMainInfo(ProductDetailModel product) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.4),
                ),
                child: Text(
                  product.kategori,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isReady
                      ? AppColors.greenLight
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.4),
                ),
                child: Text(
                  product.isReady ? 'READY' : 'PO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: product.isReady
                        ? const Color(0xFF14532D)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.namaProduk,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.border,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.views}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 3),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Kartu Toko Penjual
  Widget _buildSellerCard(ProductDetailModel product) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.8),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 22,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stand Penjual Siswa',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.namaToko,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  product.isOpen ? AppColors.greenLight : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: product.isOpen ? AppColors.green : AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  product.isOpen ? 'BUKA' : 'TUTUP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: product.isOpen
                        ? const Color(0xFF14532D)
                        : AppColors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Deskripsi Produk
  Widget _buildDescriptionCard(ProductDetailModel product) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            children: [
              Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DESKRIPSI PRODUK',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.deskripsi.trim().isNotEmpty
                ? product.deskripsi
                : 'Tidak ada deskripsi rinci untuk produk ini.',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.border,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Bagian Ulasan Pembeli
  Widget _buildReviewsSection(ProductDetailModel product) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ULASAN PEMBELI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showReviewBottomSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.border,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Tulis Ulasan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 6),
                Text(
                  product.ratingAvg.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${product.totalUlasan} ulasan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (product.ulasan.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: const [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 30,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Belum ada ulasan untuk produk ini.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jadilah yang pertama memberikan ulasan.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: product.ulasan.length,
              separatorBuilder: (context, index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 1,
                color: AppColors.border.withOpacity(0.14),
              ),
              itemBuilder: (context, index) {
                final review = product.ulasan[index];
                return _buildReviewItem(review);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                review.namaPengunjung,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(5, (starIndex) {
                final star = starIndex + 1;
                return Icon(
                  star <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: star <= review.rating
                      ? Colors.amber[700]
                      : AppColors.textMuted,
                );
              }),
            ),
          ],
        ),
        if (review.formattedDate.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            review.formattedDate,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
        if (review.komentar.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            review.komentar,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.border,
              height: 1.38,
            ),
          ),
        ],
      ],
    );
  }

  /// 6. Sticky Bottom Bar dengan Logo WhatsApp
  Widget _buildStickyBottomBar(ProductDetailModel product) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _orderViaWhatsApp(product),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WhatsAppMarkIcon(size: 20, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Pesan via WhatsApp',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.1,
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

/// Logo WhatsApp (gelembung pesan + gagang telepon)
class _WhatsAppMarkIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _WhatsAppMarkIcon({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WhatsAppMarkPainter(color: color),
      ),
    );
  }
}

class _WhatsAppMarkPainter extends CustomPainter {
  final Color color;

  _WhatsAppMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lingkaran/gelembung luar
    final bubblePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11;

    final center = Offset(w * 0.52, h * 0.48);
    final radius = w * 0.41;
    canvas.drawCircle(center, radius, bubblePaint);

    // Ekor gelembung di kiri bawah
    final tailPath = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.10, h * 0.90)
      ..lineTo(w * 0.34, h * 0.83)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = color);

    // Gagang telepon sederhana di dalam lingkaran
    final phonePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final phonePath = Path()
      ..moveTo(w * 0.36, h * 0.33)
      ..quadraticBezierTo(w * 0.34, h * 0.36, w * 0.37, h * 0.41)
      ..quadraticBezierTo(w * 0.43, h * 0.52, w * 0.55, h * 0.58)
      ..quadraticBezierTo(w * 0.60, h * 0.61, w * 0.63, h * 0.58)
      ..lineTo(w * 0.68, h * 0.53)
      ..quadraticBezierTo(w * 0.70, h * 0.51, w * 0.67, h * 0.49)
      ..lineTo(w * 0.61, h * 0.46)
      ..quadraticBezierTo(w * 0.59, h * 0.45, w * 0.58, h * 0.47)
      ..lineTo(w * 0.56, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.47, w * 0.46, h * 0.41)
      ..lineTo(w * 0.49, h * 0.38)
      ..quadraticBezierTo(w * 0.50, h * 0.37, w * 0.49, h * 0.35)
      ..lineTo(w * 0.45, h * 0.29)
      ..quadraticBezierTo(w * 0.43, h * 0.27, w * 0.41, h * 0.29)
      ..close();

    // Putar sedikit agar gagang telepon miring khas WhatsApp
    canvas.save();
    canvas.translate(w * 0.52, h * 0.48);
    canvas.rotate(math.pi * 0.04);
    canvas.translate(-w * 0.52, -h * 0.48);
    canvas.drawPath(phonePath, phonePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhatsAppMarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}