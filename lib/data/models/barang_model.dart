enum BarangKategori {
  kelistrikan('Kelistrikan'),
  filterOli('Filter Oli'),
  filterSolar('Filter Solar'),
  filterUdara('Filter Udara'),
  karetRem('Karet Rem'),
  karetChamber('Karet Chamber'),
  repairKit('Repair Kit'),
  perPolos('Per Polos'),
  umum('Umum'); // Sebagai fallback/cadangan jika ada data lama

  final String label;
  const BarangKategori(this.label);

  static BarangKategori? fromString(String? text) {
    if (text == null) return null;
    return BarangKategori.values.firstWhere(
      (e) => e.label.toLowerCase() == text.toLowerCase(),
      orElse: () => BarangKategori.umum,
    );
  }
}

class BarangModel {
  final String? idBarang;
  final String namaBarang;
  final BarangKategori? kategori;
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
      kategori: BarangKategori.fromString(json['kategori']?.toString()), 
      stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBarang != null && idBarang!.isNotEmpty) 'id_barang': int.tryParse(idBarang!),
      'nama_barang': namaBarang,
      'kategori': kategori?.label, 
      'stock': stock,
    };
  }

  BarangModel copyWith({
    String? idBarang,
    String? namaBarang,
    BarangKategori? kategori,
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