class SellerUser {
  final int userId;
  final String username;
  final String email;
  final String role;

  const SellerUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  factory SellerUser.fromJson(Map<String, dynamic> json) {
    return SellerUser(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'penjual').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}

class SellerStand {
  final int idPenjual;
  final String namaLengkap;
  final String namaToko;
  final String namaKelas;
  final String nisn;
  final String nomorWhatsapp;
  final String deskripsi;
  final String statusToko;
  final String? fotoPenjualUrl;

  const SellerStand({
    required this.idPenjual,
    required this.namaLengkap,
    required this.namaToko,
    required this.namaKelas,
    required this.nisn,
    required this.nomorWhatsapp,
    required this.deskripsi,
    required this.statusToko,
    this.fotoPenjualUrl,
  });

  bool get isOpen => statusToko.toLowerCase() == 'buka';

  factory SellerStand.fromJson(Map<String, dynamic> json) {
    return SellerStand(
      idPenjual: json['id_penjual'] is int
          ? json['id_penjual'] as int
          : int.tryParse(json['id_penjual']?.toString() ?? '0') ?? 0,
      namaLengkap: (json['nama_lengkap'] ?? '').toString(),
      namaToko: (json['nama_toko'] ?? '').toString(),
      namaKelas: (json['nama_kelas'] ?? '').toString(),
      nisn: (json['nisn'] ?? '').toString(),
      nomorWhatsapp: (json['nomor_whatsapp'] ?? '').toString(),
      deskripsi: (json['deskripsi'] ?? json['alamat'] ?? '').toString(),
      statusToko: (json['status_toko'] ?? json['status_stand'] ?? 'buka').toString(),
      fotoPenjualUrl: json['foto_penjual_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_penjual': idPenjual,
      'nama_lengkap': namaLengkap,
      'nama_toko': namaToko,
      'nama_kelas': namaKelas,
      'nisn': nisn,
      'nomor_whatsapp': nomorWhatsapp,
      'deskripsi': deskripsi,
      'status_toko': statusToko,
      'foto_penjual_url': fotoPenjualUrl,
    };
  }

  SellerStand copyWith({
    int? idPenjual,
    String? namaLengkap,
    String? namaToko,
    String? namaKelas,
    String? nisn,
    String? nomorWhatsapp,
    String? deskripsi,
    String? statusToko,
    String? fotoPenjualUrl,
  }) {
    return SellerStand(
      idPenjual: idPenjual ?? this.idPenjual,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      namaToko: namaToko ?? this.namaToko,
      namaKelas: namaKelas ?? this.namaKelas,
      nisn: nisn ?? this.nisn,
      nomorWhatsapp: nomorWhatsapp ?? this.nomorWhatsapp,
      deskripsi: deskripsi ?? this.deskripsi,
      statusToko: statusToko ?? this.statusToko,
      fotoPenjualUrl: fotoPenjualUrl ?? this.fotoPenjualUrl,
    );
  }
}

class SellerDashboardStats {
  final int totalMenu;
  final int tersedia;
  final int habis;
  final int menungguModerasi;
  final int disetujui;
  final int ditolak;
  final int totalViews;

  const SellerDashboardStats({
    required this.totalMenu,
    required this.tersedia,
    required this.habis,
    required this.menungguModerasi,
    required this.disetujui,
    required this.ditolak,
    required this.totalViews,
  });

  factory SellerDashboardStats.fromJson(Map<String, dynamic> json) {
    return SellerDashboardStats(
      totalMenu: int.tryParse(json['total_menu']?.toString() ?? '0') ?? 0,
      tersedia: int.tryParse(json['tersedia']?.toString() ?? '0') ?? 0,
      habis: int.tryParse(json['habis']?.toString() ?? '0') ?? 0,
      menungguModerasi: int.tryParse(json['menunggu_moderasi']?.toString() ?? '0') ?? 0,
      disetujui: int.tryParse(json['disetujui']?.toString() ?? '0') ?? 0,
      ditolak: int.tryParse(json['ditolak']?.toString() ?? '0') ?? 0,
      totalViews: int.tryParse(json['total_views']?.toString() ?? '0') ?? 0,
    );
  }
}

class SellerLoginResult {
  final String token;
  final String tokenType;
  final SellerUser user;
  final SellerStand? stand;

  const SellerLoginResult({
    required this.token,
    required this.tokenType,
    required this.user,
    this.stand,
  });

  factory SellerLoginResult.fromJson(Map<String, dynamic> json) {
    final token = (json['token'] ?? '').toString();
    final tokenType = (json['token_type'] ?? 'Bearer').toString();
    final user = SellerUser.fromJson(
      (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
    final stand = json['stand'] != null && json['stand'] is Map<String, dynamic>
        ? SellerStand.fromJson(json['stand'] as Map<String, dynamic>)
        : null;

    return SellerLoginResult(
      token: token,
      tokenType: tokenType,
      user: user,
      stand: stand,
    );
  }
}
