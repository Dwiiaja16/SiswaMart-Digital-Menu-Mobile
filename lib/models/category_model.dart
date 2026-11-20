class CategoryModel {
  final int id;
  final String name;
  final int productCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.productCount = 0,
  });

  int get idKategori => id;
  String get namaKategori => name;
  int get count => productCount;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id_kategori'] as num?)?.toInt() ?? 0,
      name: json['nama_kategori']?.toString() ?? '',
      productCount: (json['produk_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_kategori': id,
    'nama_kategori': name,
    'produk_count': productCount,
  };
}

typedef Category = CategoryModel;
