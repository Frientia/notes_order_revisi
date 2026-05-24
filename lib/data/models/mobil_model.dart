class MobilModel {
  final String? idMobil;
  final String noPlat;
  final String? kategori;
  final int? tahun;

  MobilModel({
    this.idMobil,
    required this.noPlat,
    this.kategori,
    this.tahun,
  });

  factory MobilModel.fromJson(Map<String, dynamic> json) {
    return MobilModel(
      idMobil: json['id_mobil']?.toString(),
      noPlat: json['no_plat']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      tahun: json['tahun'] != null ? int.tryParse(json['tahun'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMobil != null) 'id_mobil': idMobil,
      'no_plat': noPlat,
      'kategori': kategori,
      'tahun': tahun,
    };
  }

  MobilModel copyWith({
    String? idMobil,
    String? noPlat,
    String? kategori,
    int? tahun,
  }) {
    return MobilModel(
      idMobil: idMobil ?? this.idMobil,
      noPlat: noPlat ?? this.noPlat,
      kategori: kategori ?? this.kategori,
      tahun: tahun ?? this.tahun,
    );
  }
}