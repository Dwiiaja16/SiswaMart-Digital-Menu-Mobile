import 'package:intl/intl.dart';

class ReviewModel {
  final int idUlasan;
  final String namaPengunjung;
  final int rating;
  final String komentar;
  final String createdAt;

  const ReviewModel({
    required this.idUlasan,
    required this.namaPengunjung,
    required this.rating,
    required this.komentar,
    required this.createdAt,
  });

  // Alias getters
  int get id => idUlasan;
  String get name => namaPengunjung;
  String get comment => komentar;
  String get date => createdAt;

  /// Tanggal format ramah (contoh: 19 Nov 2026)
  String get formattedDate {
    if (createdAt.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(createdAt);
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      try {
        final dateTime = DateTime.parse(createdAt);
        return DateFormat('d MMM yyyy').format(dateTime);
      } catch (_) {
        return createdAt;
      }
    }
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      idUlasan: (json['id_ulasan'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      namaPengunjung: json['nama_pengunjung']?.toString() ??
          json['name']?.toString() ??
          'Pengunjung',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      komentar: json['komentar']?.toString() ??
          json['comment']?.toString() ??
          '',
      createdAt: json['created_at']?.toString() ??
          json['date']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id_ulasan': idUlasan,
    'nama_pengunjung': namaPengunjung,
    'rating': rating,
    'komentar': komentar,
    'created_at': createdAt,
  };
}

typedef Review = ReviewModel;
