// 1. Definisikan Enum sesuai dengan nilai di database Supabase
enum MobilKategori {
  trailer('Trailer'),
  gandengan('Gandengan'),
  tronton('Tronton'),
  engkel('Engkel'),
  lt('LT');

  final String label;
  const MobilKategori(this.label);

  // Fungsi helper untuk mengubah String dari database kembali menjadi Enum
  static MobilKategori? fromString(String? text) {
    if (text == null) return null;
    return MobilKategori.values.firstWhere(
      (e) => e.label.toLowerCase() == text.toLowerCase(),
      // Jika suatu saat ada data kosong/tidak cocok, kita beri default Engkel (atau bisa diubah sesuai kebutuhan)
      orElse: () => MobilKategori.engkel,
    );
  }
}

class MobilModel {
  final int? idMobil; // <--- UBAH DARI String? MENJADI int?
  final String noPlat;
  final MobilKategori? kategori;
  final int? tahun;

  MobilModel({this.idMobil, required this.noPlat, this.kategori, this.tahun});

  factory MobilModel.fromJson(Map<String, dynamic> json) {
    return MobilModel(
      idMobil: json['id_mobil'] as int?, // <--- PASTIKAN DI-CAST SEBAGAI int?
      noPlat: json['no_plat'] as String,
      kategori: MobilKategori.fromString(json['kategori'] as String?),
      tahun: json['tahun'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMobil != null) 'id_mobil': idMobil,
      'no_plat': noPlat,
      'kategori': kategori?.label,
      'tahun': tahun,
    };
  }
}
