import 'package:flutter/material.dart';
import '../core/theme.dart';

class HowToOrderScreen extends StatelessWidget {
  const HowToOrderScreen({super.key});

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
              'Cara Pesan & Info',
              style: TextStyle(
                color: AppColors.border,
                fontWeight: FontWeight.w900,
                fontSize: 20,
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
          child: Container(
            color: AppColors.border,
            height: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // 1. Panduan 4 Langkah Pemesanan
          _buildOrderingSteps(),

          const SizedBox(height: 16),

          // 2. Info Status Stok & Toko
          _buildStockInfoSection(),

          const SizedBox(height: 16),

          // 3. FAQ Pembeli
          _buildFaqSection(),

          const SizedBox(height: 16),

          // 4. Tentang SiswaMart
          _buildAboutSection(),
        ],
      ),
    );
  }

  /// 1. Panduan 4 Langkah Pemesanan
  Widget _buildOrderingSteps() {
    return NeoBrutalistCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PANDUAN 4 LANGKAH PESAN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildStepItem(
            stepNumber: '1',
            title: 'Cari & Pilih Menu Favorit',
            description:
                'Jelajahi beragam produk jajanan, makanan berat, dan karya kreatif siswa di Beranda atau Katalog.',
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            stepNumber: '2',
            title: 'Cek Status Stok & Stand Toko',
            description:
                'Pastikan produk berstatus READY (siap saji) atau PO (Pre-Order), serta toko dalam kondisi BUKA.',
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            stepNumber: '3',
            title: 'Tekan "Pesan via WhatsApp"',
            description:
                'Aplikasi akan membuka WhatsApp secara otomatis dengan pesan format pemesanan yang rapi langsung ke penjual.',
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            stepNumber: '4',
            title: 'Konfirmasi & Ambil Pesanan',
            description:
                'Sepakati waktu pengambilan di stand siswa SMKN 11 Bandung atau opsi antar di lingkungan sekolah.',
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 2. Info Status Stok
  Widget _buildStockInfoSection() {
    return NeoBrutalistCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'INFO STATUS STOK & TOKO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // READY badge explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeoBrutalistBadge(
                label: 'READY',
                color: AppColors.greenLight,
                textColor: Color(0xFF14532D),
                fontSize: 10,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tersedia Langsung. Makanan atau produk sudah siap saji di stand siswa dan dapat langsung diambil saat istirahat.',
                  style: TextStyle(fontSize: 11, color: AppColors.border, height: 1.35),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // PO badge explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeoBrutalistBadge(
                label: 'PO',
                color: AppColors.primary,
                textColor: Colors.white,
                fontSize: 10,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pre-Order (Pesanan Khusus). Produk dibuat sesuai pesanan untuk menjaga kesegaran. Pesan terlebih dahulu kepada penjual.',
                  style: TextStyle(fontSize: 11, color: AppColors.border, height: 1.35),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Buka / Tutup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NeoBrutalistBadge(
                label: 'BUKA / TUTUP',
                color: AppColors.accent,
                textColor: AppColors.border,
                fontSize: 9,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Menandakan ketersediaan stand penjual melayani pesanan hari ini. Jika TUTUP, penjual mungkin sedang dalam sesi praktikum/belajar.',
                  style: TextStyle(fontSize: 11, color: AppColors.border, height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. FAQ Pembeli
  Widget _buildFaqSection() {
    return NeoBrutalistCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: AppColors.border,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PERTANYAAN UMUM (FAQ)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.border,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildFaqItem(
            question: 'Apakah perlu membuat akun atau login?',
            answer:
                'Tidak perlu! SiswaMart 100% bebas akun untuk calon pembeli. Anda dapat langsung memilih produk dan terhubung via WhatsApp tanpa repot registrasi.',
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            question: 'Bagaimana cara memberikan ulasan produk?',
            answer:
                'Buka menu produk yang Anda coba, lalu tekan "Tulis Ulasan". Masukkan nama Anda, pilih bintang 1–5, dan ketik pengalaman rasa. Nama Anda akan disimpan otomatis untuk ulasan berikutnya!',
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            question: 'Bagaimana metode pembayarannya?',
            answer:
                'Pembayaran dilakukan langsung ke stand siswa saat pengambilan, atau via transfer/QRIS sesuai opsi yang disediakan oleh masing-masing penjual di chat WhatsApp.',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.border,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Tentang SiswaMart
  Widget _buildAboutSection() {
    return NeoBrutalistCard(
      color: AppColors.accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'TENTANG SISWAMART',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.border,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'SMKN 11 Bandung',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'SiswaMart adalah platform digital menu & katalog karya siswa-siswi SMKN 11 Bandung. Platform ini dirancang untuk memfasilitasi program pembelajaran kewirausahaan (SPW) dan Teaching Factory, menghubungkan kreativitas kuliner siswa langsung kepada warga sekolah dan masyarakat sekitar.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.border,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Text(
                  '100% GUEST MODE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Text(
                  'KARYA SISWA SMKN 11 BDG',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

