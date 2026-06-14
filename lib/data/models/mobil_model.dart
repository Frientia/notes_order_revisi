import 'package:notes_order/data/models/kategori_model.dart';

class MobilModel {
  final int? idMobil;
  final String noPlat;
  final int? idKategori;
  final KategoriModel? kategori;
  final int? tahun;

  MobilModel({
    this.idMobil,
    required this.noPlat,
    this.idKategori,
    this.kategori,
    this.tahun,
  });

  factory MobilModel.fromJson(Map<String, dynamic> json) {
    return MobilModel(
      idMobil: json['id_mobil'] as int?,
      noPlat: json['no_plat']?.toString() ?? '',
      idKategori: json['id_kategori'] as int?,
      
      kategori: json['kategori_mobil'] != null 
          ? KategoriModel.fromJson(json['kategori_mobil']) 
          : null,
          
      tahun: json['tahun'] != null ? int.tryParse(json['tahun'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMobil != null) 'id_mobil': idMobil,
      'no_plat': noPlat,
      if (idKategori != null) 'id_kategori': idKategori,
      if (tahun != null) 'tahun': tahun,
    };
  }

  MobilModel copyWith({
    int? idMobil,
    String? noPlat,
    int? idKategori,
    KategoriModel? kategori,
    int? tahun,
  }) {
    return MobilModel(
      idMobil: idMobil ?? this.idMobil,
      noPlat: noPlat ?? this.noPlat,
      idKategori: idKategori ?? this.idKategori,
      kategori: kategori ?? this.kategori,
      tahun: tahun ?? this.tahun,
    );
  }
}