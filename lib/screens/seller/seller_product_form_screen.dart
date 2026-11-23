import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme.dart';
import '../../services/api_service.dart';

typedef CategoryMap = Map<String, dynamic>;

/// Form Tambah / Edit produk penjual
class SellerProductFormScreen extends StatefulWidget {
  final CategoryMap? product; // null = tambah, non-null = edit

  const SellerProductFormScreen({super.key, this.product});

  @override
  State<SellerProductFormScreen> createState() =>
      _SellerProductFormScreenState();
}

class _SellerProductFormScreenState extends State<SellerProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;

  String _statusStok = 'ready'; // ready | po
  String? _selectedCategory;
  List<CategoryMap> _categories = [];
  bool _catsLoading = true;

  String? _pickedImagePath;
  Uint8List? _pickedImageBytes;
  bool _saving = false;

  bool get _isEdit => widget.product != null;
  int? get _productId =>
      widget.product != null ? widget.product!['id_produk'] as int? : null;

  @override
  void initState() {
    super.initState();
    final p0 = widget.product;
    _nameCtrl = TextEditingController(text: p0?['nama_produk']?.toString() ?? '');
    _priceCtrl = TextEditingController(
      text: p0 != null ? (p0['harga'] ?? '').toString() : '',
    );
    _descCtrl = TextEditingController(text: p0?['deskripsi']?.toString() ?? '');

    final rawStok = (p0?['status_stok']?.toString() ?? 'ready').toLowerCase();
    _statusStok = (rawStok == 'po') ? 'po' : 'ready';

    // Ekstrak ID atau nama kategori awal (baik berupa Map maupun String/int)
    final dynamic rawKat =
        p0?['kategori_id'] ?? p0?['id_kategori'] ?? p0?['kategori'];
    String? initialKatStr;
    if (rawKat is Map) {
      initialKatStr =
          (rawKat['id_kategori'] ?? rawKat['nama_kategori'])?.toString();
    } else if (rawKat != null) {
      initialKatStr = rawKat.toString();
    }

    _loadCategories(initialKategori: initialKatStr);
  }

  Future<void> _loadCategories({String? initialKategori}) async {
    try {
      final cats = await _api.getSellerCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _catsLoading = false;
          if (initialKategori != null && initialKategori.isNotEmpty) {
            final CategoryMap emptyMap = {};
            final match = cats.firstWhere(
              (c) =>
                  c['id_kategori']?.toString() == initialKategori ||
                  c['nama_kategori']?.toString().toLowerCase() ==
                      initialKategori.toLowerCase(),
              orElse: () => emptyMap,
            );
            _selectedCategory =
                match.isNotEmpty ? match['id_kategori']?.toString() : null;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _catsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (xfile == null) return;

      if (kIsWeb) {
        final bytes = await xfile.readAsBytes();
        if (mounted) {
          setState(() {
            _pickedImagePath = xfile.path;
            _pickedImageBytes = bytes;
          });
        }
      } else {
        final compressed = await _compressImage(xfile.path);
        final bytes = await compressed.readAsBytes();
        if (mounted) {
          setState(() {
            _pickedImagePath = compressed.path;
            _pickedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal mengambil gambar: $e');
      }
    }
  }

  /// Kompres gambar hingga maks ~800KB (Mobile)
  Future<File> _compressImage(String originalPath) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    int quality = 85;
    XFile? result;
    for (int q = quality; q >= 40; q -= 15) {
      result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        quality: q,
        format: CompressFormat.jpeg,
      );
      if (result == null) break;
      final size = await result.length();
      if (size <= 800 * 1024) break;
    }

    return result != null ? File(result.path) : File(originalPath);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final Map<String, String> fields = {
        'nama_produk': _nameCtrl.text.trim(),
        'harga': _priceCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'status_stok': _statusStok,
        if (!_isEdit) 'status_moderasi': 'pending',
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty)
          'kategori_id': _selectedCategory!,
      };

      await _api.upsertSellerProduct(
        fields: fields,
        imagePath: _pickedImagePath,
        productId: _productId,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border, width: 2),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceBtn(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ImageSourceBtn(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.product?['foto_url']?.toString() ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1.8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.border,
                size: 18,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? 'Edit Menu Toko' : 'Tambah Menu Baru',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
              Text(
                _isEdit
                    ? 'Perbarui detail produk di katalog toko'
                    : 'Daftarkan produk baru untuk diverifikasi admin',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: AppColors.border),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner Status Moderasi (Pending / Info Edit) ──────────
                _buildModerationBanner(),
                const SizedBox(height: 18),

                // ── Foto Produk ──────────────────────────────────────────
                const _SectionLabel(label: 'Foto Produk'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showImageSourceSheet,
                  child: Container(
                    height: 185,
                    width: double.infinity,
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
                    clipBehavior: Clip.antiAlias,
                    child: _buildImagePreview(existingImageUrl),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Format JPG/PNG • Kompresi otomatis maks. 800 KB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Nama Produk ──────────────────────────────────────────
                const _SectionLabel(label: 'Nama Produk', isRequired: true),
                const SizedBox(height: 8),
                _NeoTextField(
                  controller: _nameCtrl,
                  hint: 'Contoh: Risoles Mayo Spesial',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama produk wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Harga ────────────────────────────────────────────────
                const _SectionLabel(label: 'Harga Jual', isRequired: true),
                const SizedBox(height: 8),
                _NeoTextField(
                  controller: _priceCtrl,
                  hint: 'Contoh: 5000',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Harga harus lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Kategori ─────────────────────────────────────────────
                const _SectionLabel(label: 'Kategori Produk', isRequired: true),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: _catsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Memuat kategori...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Silakan pilih kategori produk'
                              : null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            errorStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red,
                            ),
                          ),
                          hint: const Text(
                            'Pilih kategori menu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          isExpanded: true,
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c['id_kategori']?.toString() ?? '',
                                  child: Text(
                                    c['nama_kategori']?.toString() ?? '-',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Status Stok (Tersedia | Pre Order) ───────────────────
                const _SectionLabel(label: 'Status Ketersediaan', isRequired: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StockRadio(
                      label: 'Tersedia',
                      subtitle: 'Ready stock',
                      value: 'ready',
                      groupValue: _statusStok,
                      color: AppColors.green,
                      bgColor: AppColors.greenLight,
                      onChanged: (v) => setState(() => _statusStok = v!),
                    ),
                    const SizedBox(width: 10),
                    _StockRadio(
                      label: 'Pre Order',
                      subtitle: 'Pesan dulu',
                      value: 'po',
                      groupValue: _statusStok,
                      color: const Color(0xFFB45309),
                      bgColor: const Color(0xFFFEF3C7),
                      onChanged: (v) => setState(() => _statusStok = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Deskripsi ─────────────────────────────────────────────
                const _SectionLabel(label: 'Deskripsi Menu'),
                const SizedBox(height: 8),
                _NeoTextField(
                  controller: _descCtrl,
                  hint: 'Tuliskan komposisi, rasa, atau catatan pemesanan...',
                  maxLines: 4,
                ),
                const SizedBox(height: 28),

                // ── Tombol Simpan ─────────────────────────────────────────
                GestureDetector(
                  onTap: _saving ? null : _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _saving ? AppColors.textMuted : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: _saving
                          ? null
                          : const [
                              BoxShadow(
                                color: AppColors.border,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit
                                ? 'Simpan Perubahan'
                                : 'Ajukan Menu (Status Pending)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModerationBanner() {
    if (!_isEdit) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(
              Icons.schedule_rounded,
              size: 18,
              color: Color(0xFFB45309),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Menu baru akan masuk dengan status Pending dan ditinjau oleh Admin sebelum tampil di halaman pembeli.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.border,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final rawMod =
        (widget.product?['status_moderasi']?.toString() ?? 'pending')
            .toLowerCase();
    final isApproved = rawMod == 'disetujui' || rawMod == 'approved';
    final isRejected = rawMod == 'ditolak' || rawMod == 'rejected';

    final Color bg = isApproved
        ? const Color(0xFFE0F2FE)
        : isRejected
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final Color accent = isApproved
        ? const Color(0xFF0369A1)
        : isRejected
            ? AppColors.red
            : const Color(0xFFB45309);
    final IconData icon = isApproved
        ? Icons.verified_rounded
        : isRejected
            ? Icons.cancel_rounded
            : Icons.schedule_rounded;
    final String title = isApproved
        ? 'Status Moderasi: Disetujui Admin'
        : isRejected
            ? 'Status Moderasi: Ditolak Admin'
            : 'Status Moderasi: Pending (Menunggu Admin)';

    final rejectReason = (widget.product?['catatan_admin'] ??
            widget.product?['alasan_ditolak'] ??
            widget.product?['keterangan_moderasi'])
        ?.toString()
        .trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                if (isRejected &&
                    rejectReason != null &&
                    rejectReason.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Catatan: $rejectReason',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.border,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String existingUrl) {
    if (_pickedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ganti Foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (existingUrl.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            existingUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _NoImagePlaceholder(),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ganti Foto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _NoImagePlaceholder();
  }
}

class _NoImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.8),
          ),
          child: const Icon(
            Icons.add_photo_alternate_rounded,
            size: 26,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ketuk untuk unggah foto menu',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.border,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Kamera atau Galeri',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ImageSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.border,
              offset: Offset(2.5, 2.5),
              blurRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _SectionLabel({required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.border,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.red,
            ),
          ),
      ],
    );
  }
}

class _NeoTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefixText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _NeoTextField({
    required this.controller,
    required this.hint,
    this.prefixText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.border,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
          hintStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          errorStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

class _StockRadio extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final String groupValue;
  final Color color;
  final Color bgColor;
  final ValueChanged<String?> onChanged;

  const _StockRadio({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.color,
    required this.bgColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.border : AppColors.border,
              width: selected ? 2.2 : 1.8,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.border,
                      offset: Offset(2.5, 2.5),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.white,
                  border: Border.all(
                    color: selected ? AppColors.border : AppColors.textMuted,
                    width: 1.8,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: selected ? color : AppColors.border,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}