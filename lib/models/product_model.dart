import 'package:intl/intl.dart';
import 'review_model.dart';

class ProductModel {
  final int id;
  final String name;
  final int price;
  final String stockStatus;
  final int views;
  final double ratingAvg;
  final String imageUrl;
  final String category;
  final String storeName;
  final String storeStatus;
  final String description;
  final String whatsappNumber;
  final List<String> allImages;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stockStatus,
    required this.views,
    required this.ratingAvg,
    required this.imageUrl,
    required this.category,
    required this.storeName,
    required this.storeStatus,
    this.description = '',
    this.whatsappNumber = '',
    this.allImages = const [],
  });

  // Alias getters
  int get idProduk => id;
  String get namaProduk => name;
  int get harga => price;
  String get statusStok => stockStatus;
  String get stock => stockStatus;
  double get rating => ratingAvg;
  String get fotoUrl => imageUrl;
  String get image => imageUrl;
  String get kategori => category;
  String get namaToko => storeName;
  String get store => storeName;
  String get statusToko => storeStatus;
  String get storeStatusVal => storeStatus;
  String get deskripsi => description;
  String get nomorWhatsapp => whatsappNumber;
  String get phone => whatsappNumber;
  List<String> get semuaFotoUrl => allImages;
  List<String> get images => allImages;

  // Case-insensitive status checks
  bool get isReady => stockStatus.trim().toLowerCase() == 'ready';
  bool get isPo => !isReady;
  bool get isStoreOpen => storeStatus.trim().toLowerCase() == 'buka';
  bool get isOpen => isStoreOpen;

  // Formatted price with intl
  String get formattedPrice {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final seller = json['penjual'] is Map<String, dynamic>
        ? json['penjual'] as Map<String, dynamic>
        : null;

    final storeName = json['nama_toko']?.toString() ??
        seller?['nama_toko']?.toString() ??
        '-';

    final storeStatus = json['status_toko']?.toString() ??
        seller?['status_toko']?.toString() ??
        'buka';

    final whatsappNumber = json['nomor_whatsapp']?.toString() ??
        seller?['nomor_whatsapp']?.toString() ??
        '';

    final rawImages = json['semua_foto_url'];
    final List<String> images = [];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item != null && item.toString().isNotEmpty) {
          images.add(item.toString());
        }
      }
    }

    final mainImage = json['foto_url']?.toString() ??
        (images.isNotEmpty ? images.first : '');

    return ProductModel(
      id: (json['id_produk'] as num?)?.toInt() ?? 0,
      name: json['nama_produk']?.toString() ?? '-',
      price: (json['harga'] as num?)?.toInt() ?? 0,
      stockStatus: json['status_stok']?.toString() ?? 'ready',
      views: (json['views'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      imageUrl: mainImage,
      category: json['kategori']?.toString() ?? '-',
      storeName: storeName,
      storeStatus: storeStatus,
      description: json['deskripsi']?.toString() ?? '',
      whatsappNumber: whatsappNumber,
      allImages: images,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_produk': id,
    'nama_produk': name,
    'harga': price,
    'status_stok': stockStatus,
    'views': views,
    'rating_avg': ratingAvg,
    'foto_url': imageUrl,
    'kategori': category,
    'nama_toko': storeName,
    'status_toko': storeStatus,
    'deskripsi': description,
    'nomor_whatsapp': whatsappNumber,
    'semua_foto_url': allImages,
  };
}

typedef Product = ProductModel;

class SellerModel {
  final String namaToko;
  final String nomorWhatsapp;
  final String statusToko;

  const SellerModel({
    required this.namaToko,
    required this.nomorWhatsapp,
    required this.statusToko,
  });

  String get storeName => namaToko;
  String get whatsappNumber => nomorWhatsapp;
  String get storeStatus => statusToko;

  bool get isOpen => statusToko.trim().toLowerCase() == 'buka';
  bool get isStoreOpen => isOpen;

  factory SellerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SellerModel(
        namaToko: '-',
        nomorWhatsapp: '',
        statusToko: 'buka',
      );
    }
    return SellerModel(
      namaToko: json['nama_toko']?.toString() ?? '-',
      nomorWhatsapp: json['nomor_whatsapp']?.toString() ?? '',
      statusToko: json['status_toko']?.toString() ?? 'buka',
    );
  }

  Map<String, dynamic> toJson() => {
    'nama_toko': namaToko,
    'nomor_whatsapp': nomorWhatsapp,
    'status_toko': statusToko,
  };
}

class ProductDetailModel {
  final int idProduk;
  final String namaProduk;
  final String deskripsi;
  final int harga;
  final String statusStok;
  final int views;
  final String fotoUrl;
  final List<String> semuaFotoUrl;
  final String kategori;
  final SellerModel penjual;
  final double ratingAvg;
  final int totalUlasan;
  final List<ReviewModel> ulasan;

  const ProductDetailModel({
    required this.idProduk,
    required this.namaProduk,
    required this.deskripsi,
    required this.harga,
    required this.statusStok,
    required this.views,
    required this.fotoUrl,
    required this.semuaFotoUrl,
    required this.kategori,
    required this.penjual,
    required this.ratingAvg,
    required this.totalUlasan,
    required this.ulasan,
  });

  // Alias getters
  int get id => idProduk;
  String get name => namaProduk;
  String get description => deskripsi;
  int get price => harga;
  String get stockStatus => statusStok;
  String get stock => statusStok;
  String get imageUrl => fotoUrl;
  String get image => fotoUrl;
  List<String> get allImages => semuaFotoUrl;
  List<String> get images => semuaFotoUrl;
  String get category => kategori;
  SellerModel get seller => penjual;
  String get namaToko => penjual.namaToko;
  String get storeName => penjual.namaToko;
  String get nomorWhatsapp => penjual.nomorWhatsapp;
  String get whatsappNumber => penjual.nomorWhatsapp;
  String get statusToko => penjual.statusToko;
  String get storeStatus => penjual.statusToko;
  double get rating => ratingAvg;
  int get totalReviews => totalUlasan;
  List<ReviewModel> get reviews => ulasan;

  // Case-insensitive status checks
  bool get isReady => statusStok.trim().toLowerCase() == 'ready';
  bool get isPo => !isReady;
  bool get isOpen => penjual.isOpen;
  bool get isStoreOpen => penjual.isOpen;

  // Formatted price with intl
  String get formattedPrice {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(harga);
  }

  // Display images list for gallery: fallback to [fotoUrl] if empty
  List<String> get displayImages {
    final list = semuaFotoUrl.where((img) => img.trim().isNotEmpty).toList();
    if (list.isNotEmpty) return list;
    if (fotoUrl.trim().isNotEmpty) return [fotoUrl.trim()];
    return [];
  }

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['semua_foto_url'];
    final List<String> images = [];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item != null && item.toString().trim().isNotEmpty) {
          images.add(item.toString().trim());
        }
      }
    }

    final rawReviews = json['ulasan'];
    final List<ReviewModel> reviews = [];
    if (rawReviews is List) {
      for (final item in rawReviews) {
        if (item is Map<String, dynamic>) {
          reviews.add(ReviewModel.fromJson(item));
        }
      }
    }

    final mainImage = json['foto_url']?.toString() ??
        (images.isNotEmpty ? images.first : '');

    return ProductDetailModel(
      idProduk: (json['id_produk'] as num?)?.toInt() ?? 0,
      namaProduk: json['nama_produk']?.toString() ?? '-',
      deskripsi: json['deskripsi']?.toString() ?? '',
      harga: (json['harga'] as num?)?.toInt() ?? 0,
      statusStok: json['status_stok']?.toString() ?? 'ready',
      views: (json['views'] as num?)?.toInt() ?? 0,
      fotoUrl: mainImage,
      semuaFotoUrl: images,
      kategori: json['kategori']?.toString() ?? '-',
      penjual: SellerModel.fromJson(
        json['penjual'] is Map<String, dynamic>
            ? json['penjual'] as Map<String, dynamic>
            : null,
      ),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      totalUlasan: (json['total_ulasan'] as num?)?.toInt() ?? reviews.length,
      ulasan: reviews,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_produk': idProduk,
    'nama_produk': namaProduk,
    'deskripsi': deskripsi,
    'harga': harga,
    'status_stok': statusStok,
    'views': views,
    'foto_url': fotoUrl,
    'semua_foto_url': semuaFotoUrl,
    'kategori': kategori,
    'penjual': penjual.toJson(),
    'rating_avg': ratingAvg,
    'total_ulasan': totalUlasan,
    'ulasan': ulasan.map((u) => u.toJson()).toList(),
  };
}

typedef ProductDetail = ProductDetailModel;
