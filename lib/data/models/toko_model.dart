class TokoModel {
  final String? idToko;
  final String namaToko;
  final String noTelp;
  final String alamat;

  TokoModel({
    this.idToko,
    required this.namaToko,
    required this.noTelp,
    required this.alamat,
  });

  factory TokoModel.fromJson(Map<String, dynamic> json) {
    return TokoModel(
      idToko: json['id_toko']?.toString(),
      namaToko: json['nama_toko']?.toString() ?? '',
      noTelp: json['no_telpon']?.toString() ?? '-',
      alamat: json['alamat']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idToko != null && idToko!.isNotEmpty) 'id_toko': int.tryParse(idToko!),
      'nama_toko': namaToko,
      'no_telpon': noTelp,
      'alamat': alamat,
    };
  }

  TokoModel copyWith({
    String? idToko,
    String? namaToko,
    String? noTelp,
    String? alamat,
  }) {
    return TokoModel(
      idToko: idToko ?? this.idToko,
      namaToko: namaToko ?? this.namaToko,
      noTelp: noTelp ?? this.noTelp,
      alamat: alamat ?? this.alamat,
    );
  }
}