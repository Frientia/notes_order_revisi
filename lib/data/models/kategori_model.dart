class KategoriModel {
  final int? idKategori;
  final String namaKategori;

  KategoriModel({
    this.idKategori,
    required this.namaKategori,
  });

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      idKategori: json['id_kategori'] as int?,
      namaKategori: json['nama_kategori'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idKategori != null) 'id_kategori': idKategori,
      'nama_kategori': namaKategori,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KategoriModel && other.idKategori == idKategori;
  }

  @override
  int get hashCode => idKategori.hashCode;
}