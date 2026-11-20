import 'package:flutter_test/flutter_test.dart';
import 'package:siswamart_mobile/models/category_model.dart';
import 'package:siswamart_mobile/models/product_model.dart';
import 'package:siswamart_mobile/models/review_model.dart';

void main() {
  group('CategoryModel Tests', () {
    test('Parse category from JSON correctly', () {
      final json = {
        "id_kategori": 1,
        "nama_kategori": "Makanan Ringan",
        "produk_count": 2,
      };

      final category = Category.fromJson(json);

      expect(category.id, 1);
      expect(category.idKategori, 1);
      expect(category.name, 'Makanan Ringan');
      expect(category.namaKategori, 'Makanan Ringan');
      expect(category.productCount, 2);
      expect(category.count, 2);
    });

    test('Parse category with missing/null values safely', () {
      final json = <String, dynamic>{};
      final category = Category.fromJson(json);

      expect(category.id, 0);
      expect(category.name, '');
      expect(category.productCount, 0);
    });
  });

  group('ProductModel Tests', () {
    test('Parse product from JSON correctly according to spec', () {
      final json = {
        "id_produk": 1,
        "nama_produk": "Risoles Mayo",
        "harga": 3000,
        "status_stok": "ready",
        "views": 28,
        "rating_avg": 4.5,
        "foto_url": "https://example.com/risoles.jpg",
        "kategori": "Makanan Ringan",
        "nama_toko": "ExxStoree",
        "status_toko": "buka",
      };

      final product = Product.fromJson(json);

      expect(product.id, 1);
      expect(product.name, 'Risoles Mayo');
      expect(product.price, 3000);
      expect(product.stockStatus, 'ready');
      expect(product.views, 28);
      expect(product.ratingAvg, 4.5);
      expect(product.imageUrl, 'https://example.com/risoles.jpg');
      expect(product.category, 'Makanan Ringan');
      expect(product.storeName, 'ExxStoree');
      expect(product.storeStatus, 'buka');

      // Case-insensitive checks
      expect(product.isReady, isTrue);
      expect(product.isPo, isFalse);
      expect(product.isStoreOpen, isTrue);
      expect(product.isOpen, isTrue);

      // Price format
      expect(product.formattedPrice.replaceAll('\u00A0', ' '), contains('3.000'));
    });

    test('Case-insensitive checks for READY / READY / Ready / PO / BUKA / TUTUP', () {
      final jsonUpper = {
        "id_produk": 2,
        "nama_produk": "Cireng Isi",
        "harga": 5000,
        "status_stok": "READY",
        "views": 10,
        "rating_avg": 5.0,
        "foto_url": "",
        "kategori": "Camilan",
        "nama_toko": "Toko Enak",
        "status_toko": "BUKA",
      };
      final p1 = Product.fromJson(jsonUpper);
      expect(p1.isReady, isTrue);
      expect(p1.isPo, isFalse);
      expect(p1.isOpen, isTrue);

      final jsonPo = {
        "id_produk": 3,
        "nama_produk": "Brownies Kukus",
        "harga": 25000,
        "status_stok": "PO",
        "views": 5,
        "rating_avg": 4.8,
        "foto_url": "",
        "kategori": "Kue",
        "nama_toko": "Sweet Bakery",
        "status_toko": "tutup",
      };
      final p2 = Product.fromJson(jsonPo);
      expect(p2.isReady, isFalse);
      expect(p2.isPo, isTrue);
      expect(p2.isOpen, isFalse);
    });
  });

  group('ProductDetailModel & ReviewModel Tests', () {
    test('Parse ProductDetailModel with nested penjual and ulasan', () {
      final json = {
        "id_produk": 1,
        "nama_produk": "Risoles Mayo Spesial",
        "deskripsi": "Risoles isi mayo lumer dengan daging asap pilihan.",
        "harga": 3000,
        "status_stok": "ready",
        "views": 29,
        "foto_url": "https://example.com/risoles.jpg",
        "semua_foto_url": [
          "https://example.com/risoles1.jpg",
          "https://example.com/risoles2.jpg"
        ],
        "kategori": "Makanan Ringan",
        "penjual": {
          "nama_toko": "ExxStoree",
          "nomor_whatsapp": "6281234567890",
          "status_toko": "buka"
        },
        "rating_avg": 4.5,
        "total_ulasan": 2,
        "ulasan": [
          {
            "id_ulasan": 101,
            "nama_pengunjung": "Andi",
            "rating": 5,
            "komentar": "Enak banget mayonya melimpah!",
            "created_at": "2026-11-19T10:00:00Z"
          },
          {
            "id_ulasan": 102,
            "nama_pengunjung": "Budi",
            "rating": 4,
            "komentar": "Mantap dan gurih.",
            "created_at": "2026-11-19T11:00:00Z"
          }
        ]
      };

      final detail = ProductDetailModel.fromJson(json);

      expect(detail.idProduk, 1);
      expect(detail.namaProduk, "Risoles Mayo Spesial");
      expect(detail.deskripsi, "Risoles isi mayo lumer dengan daging asap pilihan.");
      expect(detail.harga, 3000);
      expect(detail.statusStok, "ready");
      expect(detail.views, 29);
      expect(detail.fotoUrl, "https://example.com/risoles.jpg");
      expect(detail.semuaFotoUrl.length, 2);
      expect(detail.displayImages.length, 2);
      expect(detail.kategori, "Makanan Ringan");
      expect(detail.namaToko, "ExxStoree");
      expect(detail.nomorWhatsapp, "6281234567890");
      expect(detail.statusToko, "buka");
      expect(detail.isReady, isTrue);
      expect(detail.isOpen, isTrue);
      expect(detail.ratingAvg, 4.5);
      expect(detail.totalUlasan, 2);
      expect(detail.ulasan.length, 2);

      final firstReview = detail.ulasan.first;
      expect(firstReview.idUlasan, 101);
      expect(firstReview.namaPengunjung, "Andi");
      expect(firstReview.rating, 5);
      expect(firstReview.komentar, "Enak banget mayonya melimpah!");
    });
  });
}
