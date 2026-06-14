class PencatatanModel {
  final int idPencatatan;
  final DateTime tglPencatatan;
  final double totalHarga;
  final List<DetailPencatatanModel> details; 

  PencatatanModel({
    required this.idPencatatan,
    required this.tglPencatatan,
    required this.totalHarga,
    this.details = const [],
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
  final String namaKategori;
  final String? imgKwitansi;
  final DateTime? tglJatuhTempo;
  final DateTime? tglPelunasan;

  DetailPencatatanModel({
    required this.idDetail,
    required this.qty,
    required this.hargaPembelian,
    required this.subtotal,
    required this.status,
    required this.namaBarang,
    required this.noPlatMobil,
    required this.namaToko,
    required this.namaKategori,
    required this.tglJatuhTempo,
    required this.tglPelunasan,
    this.imgKwitansi,
  });

  factory DetailPencatatanModel.fromJson(Map<String, dynamic> json) {
    final barang = json['barang'] as Map<String, dynamic>?;
    final mobil = json['mobil'] as Map<String, dynamic>?;
    final toko = json['toko'] as Map<String, dynamic>?;
    final kwitansi = json['kwitansi'] as Map<String, dynamic>?;
    
    final kategoriBarang = barang?['kategori_barang'] as Map<String, dynamic>?;
    return DetailPencatatanModel(
      idDetail: json['id_detail_pencatatan'] as int,
      qty: json['qty'] as int,
      hargaPembelian: double.tryParse(json['harga_pembelian_barang'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      
      namaBarang: barang?['nama_barang']?.toString() ?? '-',
      
      namaKategori: kategoriBarang?['nama_kategori']?.toString() ?? 
                    barang?['kategori']?.toString() ?? 
                    'Tanpa Kategori',
                    
      noPlatMobil: mobil?['no_plat']?.toString() ?? '-',
      namaToko: toko?['nama_toko']?.toString() ?? '-',
      imgKwitansi: kwitansi?['img_url']?.toString(),
      
      tglJatuhTempo: json['tgl_jatuh_tempo'] != null 
          ? DateTime.parse(json['tgl_jatuh_tempo'].toString()) 
          : null,
      tglPelunasan: json['tgl_pelunasan'] != null 
          ? DateTime.parse(json['tgl_pelunasan'].toString()) 
          : null,
    );
  }
}