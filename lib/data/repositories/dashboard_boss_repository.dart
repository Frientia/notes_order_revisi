import 'package:supabase_flutter/supabase_flutter.dart';

// Model khusus untuk membungkus semua data dashboard
class DashboardData {
  final double totalBelanjaBulanIni;
  final double totalHutang;
  final int totalTransaksiBulanIni;
  final List<double> belanja6Bulan;
  final List<int> transaksi6Bulan;
  final List<String> labelBulan;

  DashboardData({
    required this.totalBelanjaBulanIni,
    required this.totalHutang,
    required this.totalTransaksiBulanIni,
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
    // Tarik batas waktu 6 bulan ke belakang dari tanggal 1
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    // 1. QUERY PENCATATAN (Untuk total transaksi & belanja 6 bulan terakhir)
    final pencatatanRes = await _supabase
        .from('pencatatan')
        .select('tgl_pencatatan, total_harga')
        .gte('tgl_pencatatan', sixMonthsAgo.toIso8601String());

    // 2. QUERY HUTANG (Ambil dari detail_pencatatan yang statusnya PENDING)
    final hutangRes = await _supabase
        .from('detail_pencatatan')
        .select('qty, harga_pembelian_barang')
        .eq('status', 'PENDING');

    // -- PERHITUNGAN TOTAL HUTANG --
    double totalHutang = 0;
    for (var row in hutangRes) {
      totalHutang +=
          (row['qty'] as int) *
          (row['harga_pembelian_barang'] as num).toDouble();
    }

    // -- PERSIAPAN KERANJANG DATA GRAFIK 6 BULAN --
    double totalBelanjaBulanIni = 0;
    int totalTransaksiBulanIni = 0;

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

    // Inisialisasi label bulan di sumbu X (contoh: Jan, Feb, Mar...)
    for (int i = 0; i < 6; i++) {
      DateTime target = DateTime(now.year, now.month - (5 - i), 1);
      labelBulan[i] = namaBulan[target.month - 1];
    }

    // -- PERHITUNGAN TOTAL BELANJA & TRANSAKSI --
    for (var row in pencatatanRes) {
      DateTime tgl = DateTime.parse(row['tgl_pencatatan']);
      double total = (row['total_harga'] ?? 0 as num).toDouble();

      // Jika data tersebut ada di bulan ini
      if (tgl.year == now.year && tgl.month == now.month) {
        totalBelanjaBulanIni += total;
        totalTransaksiBulanIni += 1;
      }

      // Pilah data ke dalam indeks 6 bulan grafik
      for (int i = 0; i < 6; i++) {
        DateTime target = DateTime(now.year, now.month - (5 - i), 1);
        if (tgl.year == target.year && tgl.month == target.month) {
          belanja6Bulan[i] += total;
          transaksi6Bulan[i] += 1;
          break;
        }
      }
    }

    return DashboardData(
      totalBelanjaBulanIni: totalBelanjaBulanIni,
      totalHutang: totalHutang,
      totalTransaksiBulanIni: totalTransaksiBulanIni,
      belanja6Bulan: belanja6Bulan,
      transaksi6Bulan: transaksi6Bulan,
      labelBulan: labelBulan,
    );
  }
}
