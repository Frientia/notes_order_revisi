class TokoModel {
  final String? idToko;
  final String namaToko;
  final String alamat;
  final String noTelpon;

  TokoModel({
    this.idToko,
    required this.namaToko,
    required this.alamat,
    required this.noTelpon,
  });

  factory TokoModel.fromJson(Map<String, dynamic> json) {
    return TokoModel(
      idToko: json['id_toko'] as String?,
      namaToko: json['nama_toko'] as String,
      alamat: json['alamat'] as String,
      noTelpon: json['no_telpon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idToko != null) 'id_toko': idToko,
      'nama_toko': namaToko,
      'alamat': alamat,
      'no_telpon': noTelpon,
    };
  }
}
