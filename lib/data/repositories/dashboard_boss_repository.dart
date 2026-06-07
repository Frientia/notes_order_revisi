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
    // Batas awal untuk grafik 6 bulan ke belakang (Tanggal 1 dari 5 bulan lalu)
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    // Batas awal khusus untuk bulan berjalan ini saja (Tanggal 1 bulan ini jam 00:00)
    final awalBulanIni = DateTime(now.year, now.month, 1);

    // 1. QUERY PENCATATAN (Untuk total belanja & grafik 6 bulan berjalan)
    final pencatatanRes = await _supabase
        .from('pencatatan')
        .select('tgl_pencatatan, total_harga')
        .eq('status_transaksi', 'SELESAI')
        .gte('tgl_pencatatan', sixMonthsAgo.toIso8601String());

    // 2. QUERY HUTANG (DI-FIX: Sekarang dikunci ketat hanya mengambil inputan BULAN INI saja)
    final hutangRes = await _supabase
        .from('detail_pencatatan')
        .select(
          'qty, harga_pembelian_barang, pencatatan!inner(status_transaksi, tgl_pencatatan)',
        )
        .eq('status', 'PENDING') 
        .eq('pencatatan.status_transaksi', 'SELESAI')
        // --- KUNCI FILTER: Mengabaikan hutang bulan lalu, hanya ambil tanggal >= 1 bulan ini ---
        .gte('pencatatan.tgl_pencatatan', awalBulanIni.toIso8601String());

    // -- PERHITUNGAN TOTAL HUTANG KHUSUS BULAN INI --
    double totalHutangBulanIni = 0;
    for (var row in hutangRes) {
      final qty = row['qty'] ?? 0;
      final harga = row['harga_pembelian_barang'] ?? 0;
      totalHutangBulanIni += (qty as int) * (harga as num).toDouble();
    }

    // -- PERSIAPAN WADAH DATA GRAFIK 6 BULAN --
    double totalBelanjaBulanIni = 0;
    int totalTransaksiBulanIni = 0;

    List<double> belanja6Bulan = List.filled(6, 0.0);
    List<int> transaksi6Bulan = List.filled(6, 0);
    List<String> labelBulan = List.filled(6, '');
    
    const namaBulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
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

      // Akumulasi data pengadaan khusus untuk bulan berjalan saat ini
      if (tgl.year == now.year && tgl.month == now.month) {
        totalBelanjaBulanIni += total;
        totalTransaksiBulanIni += 1;
      }

      // Pilah data otomatis menggunakan math delta rentang index grafik (0-5)
      int selisihBulan = (tgl.year - sixMonthsAgo.year) * 12 + (tgl.month - sixMonthsAgo.month);
      if (selisihBulan >= 0 && selisihBulan < 6) {
        belanja6Bulan[selisihBulan] += total;
        transaksi6Bulan[selisihBulan] += 1;
      }
    }

    return DashboardData(
      totalBelanjaBulanIni: totalBelanjaBulanIni,
      totalHutang: totalHutangBulanIni, // Sekarang nominalnya bersih, hanya tagihan bulan ini!
      totalTransaksiBulanIni: totalTransaksiBulanIni,
      belanja6Bulan: belanja6Bulan,
      transaksi6Bulan: transaksi6Bulan,
      labelBulan: labelBulan,
    );
  }
}