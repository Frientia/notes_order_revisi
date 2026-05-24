enum MobilKategori {
  trailer('Trailer'),
  gandengan('Gandengan'),
  tronton('Tronton'),
  engkel('Engkel'),
  lt('LT');

  final String label;
  const MobilKategori(this.label);

  static MobilKategori? fromString(String? text) {
    if (text == null) return null;
    return MobilKategori.values.firstWhere(
      (e) => e.label.toLowerCase() == text.toLowerCase(),
      orElse: () => MobilKategori.engkel,
    );
  }
}

class MobilModel {
  final String? idMobil; // UBAH: Menjadi nullable (String?)
  final String noPlat;
  final MobilKategori? kategori;
  final int? tahun;

  MobilModel({
    this.idMobil, // UBAH: Hapus 'required'
    required this.noPlat, 
    this.kategori, 
    this.tahun
  });

  factory MobilModel.fromJson(Map<String, dynamic> json) {
    return MobilModel(
      idMobil: json['id_mobil']?.toString() ?? '',
      noPlat: json['no_plat']?.toString() ?? '',
      kategori: MobilKategori.fromString(json['kategori']?.toString()),
      tahun: json['tahun'] != null ? int.tryParse(json['tahun'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMobil != null && idMobil!.isNotEmpty) 'id_mobil': int.tryParse(idMobil!),
      'no_plat': noPlat,
      'kategori': kategori?.label,
      'tahun': tahun,
    };
  }
}