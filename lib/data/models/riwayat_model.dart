class PencatatanModel {
  final int idPencatatan;
  final DateTime tglPencatatan;
  final double totalHarga;
  // TAMBAHAN: Variabel ini yang akan menampung daftar barang di dalam 1 nota
  final List<DetailPencatatanModel> details; 

  PencatatanModel({
    required this.idPencatatan,
    required this.tglPencatatan,
    required this.totalHarga,
    this.details = const [], // Beri nilai default list kosong
  });

  factory PencatatanModel.fromJson(Map<String, dynamic> json) {
    String tglStr = json['tgl_pencatatan'].toString();
    
    if (!tglStr.endsWith('Z') && !tglStr.contains('+')) {
      tglStr += 'Z'; 
    }
    
    DateTime wibTime = DateTime.parse(tglStr).add(const Duration(hours: 7));

    // TAMBAHAN: Logika untuk memproses (mapping) data detail anak dari Supabase
    var detailsList = json['detail_pencatatan'] as List?;
    List<DetailPencatatanModel> parsedDetails = [];
    if (detailsList != null) {
      parsedDetails = detailsList.map((e) => DetailPencatatanModel.fromJson(e)).toList();
    }

    return PencatatanModel(
      idPencatatan: json['id_pencatatan'],
      tglPencatatan: wibTime, // Menggunakan waktu yang sudah +7 Jam
      totalHarga: double.parse(json['total_harga'].toString()),
      details: parsedDetails, // Masukkan daftar barang ke model utama
    );
  }
}

class DetailPencatatanModel {
  final int idDetail;
  final int qty;
  final double hargaPembelian;
  final double subtotal;
  final String status;
  
  final String namaBarang;
  final String noPlatMobil;
  final String namaToko;
  final String? imgKwitansi;

  DetailPencatatanModel({
    required this.idDetail,
    required this.qty,
    required this.hargaPembelian,
    required this.subtotal,
    required this.status,
    required this.namaBarang,
    required this.noPlatMobil,
    required this.namaToko,
    this.imgKwitansi,
  });

  factory DetailPencatatanModel.fromJson(Map<String, dynamic> json) {
    return DetailPencatatanModel(
      idDetail: json['id_detail_pencatatan'],
      qty: json['qty'],
      hargaPembelian: double.parse(json['harga_pembelian_barang'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      status: json['status'] ?? 'PENDING',
      
      namaBarang: json['barang']?['nama_barang'] ?? '-',
      noPlatMobil: json['mobil']?['no_plat'] ?? '-',
      namaToko: json['toko']?['nama_toko'] ?? '-',
      imgKwitansi: json['kwitansi']?['img_url'],
    );
  }
}