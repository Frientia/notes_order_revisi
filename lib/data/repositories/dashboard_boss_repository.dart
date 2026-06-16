import 'package:supabase_flutter/supabase_flutter.dart';

// Model khusus untuk membungkus semua data dashboard
class DashboardData {
  final double totalBelanjaBulanIni;
  final double totalHutangBulanIni;
  final int totalTransaksiBulanIni;
  final double totalBelanjaSemua;
  final double totalHutangSemua;
  final int totalTransaksiSemua;
  final List<double> belanja6Bulan;
  final List<int> transaksi6Bulan;
  final List<String> labelBulan;

  DashboardData({
    required this.totalBelanjaBulanIni,
    required this.totalHutangBulanIni,
    required this.totalTransaksiBulanIni,
    required this.totalBelanjaSemua,
    required this.totalHutangSemua,
    required this.totalTransaksiSemua,
    required this.belanja6Bulan,
    required this.transaksi6Bulan,
    required this.labelBulan,
  });
}

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<DashboardData> getDashboardData() async {
    final now = DateTime.now();
    // Batas awal untuk grafik 6 bulan ke belakang (Tanggal 1 dari 5 bulan lalu)
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    // 1. QUERY PENCATATAN (Untuk total belanja & grafik 6 bulan berjalan)
    final pencatatanRes = await _supabase
        .from('pencatatan')
        .select('tgl_pencatatan, total_harga')
        .eq('status_transaksi', 'SELESAI');

    // 2. QUERY HUTANG (semua transaksi pending yang sudah berstatus selesai di pencatatan)
    final hutangRes = await _supabase
        .from('detail_pencatatan')
        .select(
          'qty, harga_pembelian_barang, pencatatan!inner(status_transaksi, tgl_pencatatan)',
        )
        .eq('status', 'PENDING')
        .eq('pencatatan.status_transaksi', 'SELESAI');

    // -- PERHITUNGAN TOTAL HUTANG --
    double totalHutangBulanIni = 0;
    double totalHutangSemua = 0;
    for (var row in hutangRes) {
      final qty = row['qty'] ?? 0;
      final harga = row['harga_pembelian_barang'] ?? 0;
      final subtotal = (qty as int) * (harga as num).toDouble();
      totalHutangSemua += subtotal;

      final pencatatan = row['pencatatan'];
      if (pencatatan != null) {
        final tglString = pencatatan['tgl_pencatatan'];
        if (tglString != null) {
          final tgl = DateTime.parse(tglString);
          if (tgl.year == now.year && tgl.month == now.month) {
            totalHutangBulanIni += subtotal;
          }
        }
      }
    }

    // -- PERSIAPAN WADAH DATA GRAFIK 6 BULAN --
    double totalBelanjaBulanIni = 0;
    int totalTransaksiBulanIni = 0;
    double totalBelanjaSemua = 0;
    int totalTransaksiSemua = 0;

    List<double> belanja6Bulan = List.filled(6, 0.0);
    List<int> transaksi6Bulan = List.filled(6, 0);
    List<String> labelBulan = List.filled(6, '');

    const namaBulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    // Inisialisasi urutan nama label bulan di sumbu X
    for (int i = 0; i < 6; i++) {
      DateTime target = DateTime(now.year, now.month - (5 - i), 1);
      labelBulan[i] = namaBulan[target.month - 1];
    }

    // -- PERHITUNGAN TOTAL BELANJA & TRANSAKSI --
    for (var row in pencatatanRes) {
      if (row['tgl_pencatatan'] == null) continue;

      DateTime tgl = DateTime.parse(row['tgl_pencatatan']);
      double total = ((row['total_harga'] ?? 0) as num).toDouble();
      totalBelanjaSemua += total;
      totalTransaksiSemua += 1;

      // Akumulasi data pengadaan khusus untuk bulan berjalan saat ini
      if (tgl.year == now.year && tgl.month == now.month) {
        totalBelanjaBulanIni += total;
        totalTransaksiBulanIni += 1;
      }

      // Pilah data otomatis menggunakan math delta rentang index grafik (0-5)
      int selisihBulan =
          (tgl.year - sixMonthsAgo.year) * 12 +
          (tgl.month - sixMonthsAgo.month);
      if (selisihBulan >= 0 && selisihBulan < 6) {
        belanja6Bulan[selisihBulan] += total;
        transaksi6Bulan[selisihBulan] += 1;
      }
    }

    return DashboardData(
      totalBelanjaBulanIni: totalBelanjaBulanIni,
      totalHutangBulanIni: totalHutangBulanIni,
      totalTransaksiBulanIni: totalTransaksiBulanIni,
      totalBelanjaSemua: totalBelanjaSemua,
      totalHutangSemua: totalHutangSemua,
      totalTransaksiSemua: totalTransaksiSemua,
      belanja6Bulan: belanja6Bulan,
      transaksi6Bulan: transaksi6Bulan,
      labelBulan: labelBulan,
    );
  }
}
