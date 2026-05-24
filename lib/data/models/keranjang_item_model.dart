import 'dart:typed_data';

class KeranjangItem {
  final String idBarang;
  final String namaBarang;
  final String idMobil;
  final String noPlatMobil;
  final String idToko;
  final String namaToko;
  final int qty;
  final double hargaPembelian;
  final double subtotal;
  
  final String statusPembayaran; 
  final Uint8List imageBytes;   
  final String imageName; 

  KeranjangItem({
    required this.idBarang,
    required this.namaBarang,
    required this.idMobil,
    required this.noPlatMobil,
    required this.idToko,
    required this.namaToko,
    required this.qty,
    required this.hargaPembelian,
    required this.statusPembayaran,
    required this.imageBytes,
    required this.imageName,
  }) : subtotal = qty * hargaPembelian;
}