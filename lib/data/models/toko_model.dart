class TokoModel {
  final String? idToko;
  final String namaToko;
  final String? alamat;
  final String? noTelpon;

  TokoModel({
    this.idToko,
    required this.namaToko,
    this.alamat,
    this.noTelpon,
  });

  factory TokoModel.fromJson(Map<String, dynamic> json) {
    return TokoModel(
      idToko: json['id_toko']?.toString(),
      namaToko: json['nama_toko']?.toString() ?? '',
      alamat: json['alamat']?.toString(),
      noTelpon: json['no_telpon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idToko != null) 'id_toko': int.tryParse(idToko!), 
      'nama_toko': namaToko,
      'alamat': alamat,
      'no_telpon': noTelpon,
    };
  }

  TokoModel copyWith({
    String? idToko,
    String? namaToko,
    String? alamat,
    String? noTelpon,
  }) {
    return TokoModel(
      idToko: idToko ?? this.idToko,
      namaToko: namaToko ?? this.namaToko,
      alamat: alamat ?? this.alamat,
      noTelpon: noTelpon ?? this.noTelpon,
    );
  }
}