import 'kategori_model.dart'; // Pastikan mengimpor KategoriModel yang baru saja kita buat

class BarangModel {
  final int? idBarang;
  final String namaBarang;
  final int? idKategori; 
  final KategoriModel? kategori; // Menampung objek kategori utuh hasil JOIN Supabase
  final int stock;

  BarangModel({
    this.idBarang,
    required this.namaBarang,
    this.idKategori,
    this.kategori,
    this.stock = 0,
  });

  factory BarangModel.fromJson(Map<String, dynamic> json) {
    return BarangModel(
      idBarang: json['id_barang'] as int?,
      namaBarang: json['nama_barang']?.toString() ?? '',
      idKategori: json['id_kategori'] as int?,
      
      kategori: json['kategori_barang'] != null 
          ? KategoriModel.fromJson(json['kategori_barang']) 
          : null,
          
      stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) ?? 0 : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idBarang != null) 'id_barang': idBarang,
      'nama_barang': namaBarang,
      if (idKategori != null) 'id_kategori': idKategori,
      'stock': stock, 
    };
  }

  BarangModel copyWith({
    int? idBarang,
    String? namaBarang,
    int? idKategori,
    KategoriModel? kategori,
    int? stock,
  }) {
    return BarangModel(
      idBarang: idBarang ?? this.idBarang,
      namaBarang: namaBarang ?? this.namaBarang,
      idKategori: idKategori ?? this.idKategori,
      kategori: kategori ?? this.kategori,
      stock: stock ?? this.stock,
    );
  }
}