class BarangModel {
  final String? idBarang;
  final String namaBarang;
  final String? kategori;
  final int stock;

  BarangModel({
    this.idBarang,
    required this.namaBarang,
    this.kategori,
    this.stock = 0,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      idBarang: json['id_barang']?.toString(), 
      namaBarang: json['nama_barang']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBarang != null) 'id_barang': idBarang,
      'nama_barang': namaBarang,
      'kategori': kategori,
      'stock': stock,
    };
  }

  BarangModel copyWith({
    String? idBarang,
    String? namaBarang,
    String? kategori,
    int? stock,
  }) {
    return BarangModel(
      idBarang: idBarang ?? this.idBarang,
      namaBarang: namaBarang ?? this.namaBarang,
      kategori: kategori ?? this.kategori,
      stock: stock ?? this.stock,
    );
  }
}