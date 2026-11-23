import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/seller_model.dart';
import '../../services/auth_session_manager.dart';

typedef JsonMap = Map<String, dynamic>;

/// Tab 2 — Profil Toko
class SellerProfileTab extends StatefulWidget {
  final SellerStand? stand;
  final ValueChanged<SellerStand>? onStandUpdated;
  final VoidCallback? onLogout;

  const SellerProfileTab({
    super.key,
    this.stand,
    this.onStandUpdated,
    this.onLogout,
  });

  @override
  State<SellerProfileTab> createState() => _SellerProfileTabState();
}

class _SellerProfileTabState extends State<SellerProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _waController = TextEditingController();

  Uint8List? _pickedImageBytes;
  bool _isSaving = false;
  String? _saveError;
  String? _saveSuccess;

  @override
  void initState() {
    super.initState();
    _prefillForm();
  }

  @override
  void didUpdateWidget(covariant SellerProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stand != widget.stand) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    _namaController.text = widget.stand?.namaToko ?? '';
    _deskripsiController.text = widget.stand?.deskripsi ?? '';
    _waController.text = widget.stand?.nomorWhatsapp ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _waController.dispose();
    super.dispose();
  }

  // ── Pilih gambar dari kamera / galeri (Kompatibel Web & Mobile) ────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null || !mounted) return;

      Uint8List? finalBytes;
      if (!kIsWeb) {
        finalBytes = await FlutterImageCompress.compressWithFile(
          picked.path,
          quality: 80,
          minWidth: 800,
          minHeight: 800,
        );
      }
      finalBytes ??= await picked.readAsBytes();

      if (!mounted) return;
      setState(() => _pickedImageBytes = finalBytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = 'Gagal memilih foto: $e';
        });
      }
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ImageSourceSheet(
        onCamera: () {
          Navigator.of(ctx).pop();
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.of(ctx).pop();
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  // ── Simpan profil toko ke API ──────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
      _saveSuccess = null;
    });

    try {
      final token = await AuthSessionManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi telah berakhir. Silakan login kembali.');
      }

      final uri = Uri.parse('$sellerApiBaseUrl/stand/profile');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['nama_toko'] = _namaController.text.trim()
        ..fields['deskripsi'] = _deskripsiController.text.trim()
        ..fields['nomor_whatsapp'] = _waController.text.trim();

      if (_pickedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto_stand',
            _pickedImageBytes!,
            filename: 'toko_photo.jpg',
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final updatedStand = await AuthSessionManager.getStand();
        if (decoded is JsonMap && decoded['data'] is JsonMap) {
          final dataMap = decoded['data'] as JsonMap;
          final standData = dataMap['stand'] is JsonMap
              ? dataMap['stand'] as JsonMap
              : (dataMap.containsKey('nama_toko') ? dataMap : null);

          if (standData != null) {
            final newStand = SellerStand.fromJson(standData);
            await AuthSessionManager.updateStand(newStand);
            widget.onStandUpdated?.call(newStand);
          } else if (updatedStand != null) {
            final patched = updatedStand.copyWith(
              namaToko: _namaController.text.trim(),
              deskripsi: _deskripsiController.text.trim(),
              nomorWhatsapp: _waController.text.trim(),
            );
            await AuthSessionManager.updateStand(patched);
            widget.onStandUpdated?.call(patched);
          }
        }

        if (mounted) {
          setState(() {
            _saveSuccess = 'Profil toko berhasil diperbarui!';
            _pickedImageBytes = null;
            _isSaving = false;
          });
        }
      } else {
        final msg = decoded is JsonMap && decoded['message'] != null
            ? decoded['message'].toString()
            : 'Gagal menyimpan profil (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError = e.toString().replaceAll('Exception: ', '');
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokoName = (widget.stand?.namaToko.trim().isNotEmpty == true)
        ? widget.stand!.namaToko
        : 'Nama Toko Belum Diatur';
    final ownerName = widget.stand?.namaLengkap ?? 'Pemilik Toko';
    final kelasName = widget.stand?.namaKelas ?? '';
    final isOpen = widget.stand?.isOpen ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Profil Toko',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.border,
              ),
            ),
            Text(
              'Kelola identitas & kontak WhatsApp toko Anda',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: AppColors.border, height: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Kartu Header Identitas Toko (Gaya Web) ───────────────
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    _PhotoPicker(
                      currentUrl: widget.stand?.fotoPenjualUrl,
                      pickedBytes: _pickedImageBytes,
                      onTap: _showImageSourceSheet,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? AppColors.greenLight
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.3,
                              ),
                            ),
                            child: Text(
                              isOpen ? 'TOKO BUKA' : 'TOKO TUTUP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: isOpen ? AppColors.green : AppColors.red,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tokoName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.border,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            kelasName.isNotEmpty
                                ? '$ownerName • $kelasName'
                                : ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: const Text(
                              'Ketuk foto untuk mengganti logo toko',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Feedback Simpan ──────────────────────────────────────────
              if (_saveSuccess != null) ...[
                _FeedbackBanner(
                  message: _saveSuccess!,
                  isError: false,
                  onDismiss: () => setState(() => _saveSuccess = null),
                ),
                const SizedBox(height: 14),
              ],
              if (_saveError != null) ...[
                _FeedbackBanner(
                  message: _saveError!,
                  isError: true,
                  onDismiss: () => setState(() => _saveError = null),
                ),
                const SizedBox(height: 14),
              ],

              // ── 2. Form Pengaturan Toko ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('Pengaturan Informasi Toko'),
                    const SizedBox(height: 14),

                    // Nama Toko
                    _FieldLabel('Nama Toko', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _namaController,
                      textInputAction: TextInputAction.next,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hintText: 'Contoh: Kedai RPL Mantap',
                        prefixIcon: Icons.storefront_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama toko tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Deskripsi Toko
                    _FieldLabel('Deskripsi Toko'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _deskripsiController,
                      textInputAction: TextInputAction.next,
                      maxLines: 3,
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hintText:
                            'Ceritakan menu andalan, lokasi kelas, atau jam jualan...',
                        prefixIcon: Icons.description_rounded,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Nomor WhatsApp
                    _FieldLabel('Nomor WhatsApp Pemesanan', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _waController,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: _inputTextStyle,
                      decoration: _inputDecoration(
                        hintText: 'Contoh: 081234567890',
                        prefixIcon: Icons.chat_rounded,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nomor WhatsApp wajib diisi untuk pesanan pembeli.';
                        }
                        if (v.trim().length < 9) {
                          return 'Nomor WhatsApp minimal 9 digit.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nomor ini dihubungkan langsung ke tombol Pesan via WhatsApp di halaman pembeli.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tombol Simpan Perubahan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.55),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 2,
                            ),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simpan Profil Toko',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Identitas Pemilik Toko (Read-only) ────────────────────
              if (widget.stand != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
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
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionTitle('Identitas Pemilik Toko'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: const Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.border,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.badge_rounded,
                        label: 'Nama Siswa',
                        value: widget.stand!.namaLengkap,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.class_rounded,
                        label: 'Kelas',
                        value: widget.stand!.namaKelas,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.numbers_rounded,
                        label: 'NISN',
                        value: widget.stand!.nisn,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 4. Tombol Logout ─────────────────────────────────────────
              GestureDetector(
                onTap: widget.onLogout,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.red, width: 2),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.red, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.red,
                              ),
                            ),
                            Text(
                              'Hapus sesi login penjual dari perangkat ini',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: AppColors.border,
  );

  static Widget _FieldLabel(String text, {bool isRequired = false}) => Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.border,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
        ],
      );

  static InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFFA1A1AA),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      prefixIcon: Icon(prefixIcon, color: AppColors.border, size: 19),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 2.2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Photo Picker
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final String? currentUrl;
  final Uint8List? pickedBytes;
  final VoidCallback onTap;

  const _PhotoPicker({
    this.currentUrl,
    this.pickedBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 2.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.5),
              child: pickedBytes != null
                  ? Image.memory(pickedBytes!, fit: BoxFit.cover)
                  : (currentUrl != null && currentUrl!.isNotEmpty
                      ? Image.network(
                          currentUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _AvatarFallback(),
                        )
                      : const _AvatarFallback()),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.border, width: 1.8),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.storefront_rounded, size: 34, color: AppColors.primary),
        SizedBox(height: 2),
        Text(
          'Foto Toko',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widget: Bottom Sheet pilih sumber gambar
// ─────────────────────────────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImageSourceSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Sumber Foto Toko',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.border,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: AppColors.primary,
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: const Color(0xFF7C3AED),
                  onTap: onGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
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
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.8),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers kecil
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.textMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.border,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _FeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError ? const Color(0xFFFEE2E2) : AppColors.greenLight;
    final border = isError ? AppColors.red : AppColors.green;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final textColor = isError ? AppColors.red : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }
}