import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/rekap_hutang_provider.dart';
import '../../core/utils/formatters.dart';

class RekapHutangScreen extends ConsumerStatefulWidget {
  const RekapHutangScreen({super.key});

  @override
  ConsumerState<RekapHutangScreen> createState() => _RekapHutangScreenState();
}

class _RekapHutangScreenState extends ConsumerState<RekapHutangScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchHutangProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hutangFilteredState = ref.watch(rekapHutangFilteredProvider);
    final keywordPencarian = ref.watch(searchHutangProvider);
    final filterBulanAktif = ref.watch(bulanHutangProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Rekap Hutang Toko',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: filterBulanAktif != null ? Colors.amber : Colors.white,
            ),
            tooltip: 'Filter & Urutkan',
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                ref
                    .watch(rekapHutangRawProvider)
                    .when(
                      data: (listMentah) {
                        final dataBulanIni = filterBulanAktif == null
                            ? listMentah
                            : listMentah.where(
                                (item) =>
                                    item.tglPencatatan.year ==
                                        filterBulanAktif.year &&
                                    item.tglPencatatan.month ==
                                        filterBulanAktif.month,
                              );

                        final totalHutangTeks = dataBulanIni.fold<double>(
                          0,
                          (sum, item) => sum + item.subtotal,
                        );

                        // Membuat label dinamis untuk Grand Total
                        String labelTotal = 'Total Hutang Berjalan (Semua)';
                        if (filterBulanAktif != null) {
                          final namaBulan = [
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
                          labelTotal =
                              'Hutang Periode: ${namaBulan[filterBulanAktif.month - 1]} ${filterBulanAktif.year}';
                        }

                        return Column(
                          children: [
                            Text(
                              labelTotal,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppFormatters.rupiah(totalHutangTeks),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const Text('Gagal menghitung total'),
                    ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama toko suku cadang...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: keywordPencarian.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchHutangProvider.notifier).state =
                                  '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.indigo,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) =>
                      ref.read(searchHutangProvider.notifier).state = value,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: hutangFilteredState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Terjadi kesalahan:\n$err')),
              data: (listData) {
                if (listData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada tagihan hutang ditemukan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(rekapHutangRawProvider);
                    return ref.read(rekapHutangRawProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];
                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.red.withOpacity(0.08),
                            child: const Icon(
                              Icons.store,
                              color: Colors.red,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            item.namaToko,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${item.jumlahItemPending} barang pending',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          trailing: Text(
                            AppFormatters.rupiah(item.totalHutang),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () => _showDetailHutangToko(
                            context,
                            item.idToko,
                            item.namaToko,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- MENU FILTER BOTTOM SHEET ---
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSort = ref.watch(sortirHutangProvider);
            final currentBulan = ref.watch(bulanHutangProvider);
            final now = DateTime.now();

            // Cek status bulan apa yang sedang aktif
            final isBulanIni =
                currentBulan != null &&
                currentBulan.month == now.month &&
                currentBulan.year == now.year;
            final isCustomBulan = currentBulan != null && !isBulanIni;

            // Format teks untuk tombol custom bulan
            final List<String> namaBulanSingkat = [
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
            String labelCustom = 'Pilih Bulan...';
            if (isCustomBulan) {
              labelCustom =
                  '${namaBulanSingkat[currentBulan.month - 1]} ${currentBulan.year}';
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Filter & Urutkan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Periode Monitoring',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Menggunakan Wrap agar tidak overflow ke samping
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua Waktu'),
                        selected: currentBulan == null,
                        onSelected: (selected) {
                          if (selected)
                            ref.read(bulanHutangProvider.notifier).state = null;
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Bulan Ini'),
                        selected: isBulanIni,
                        onSelected: (selected) {
                          if (selected)
                            ref.read(bulanHutangProvider.notifier).state =
                                DateTime(now.year, now.month);
                        },
                      ),
                      // TOMBOL PILIH BULAN CUSTOM
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 16),
                            const SizedBox(width: 6),
                            Text(labelCustom),
                          ],
                        ),
                        selected: isCustomBulan,
                        onSelected: (selected) =>
                            _showBulanPicker(context, ref),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text(
                    'Urutkan Daftar Toko',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SortirHutang>(
                    value: currentSort,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SortirHutang.tertinggi,
                        child: Text('Hutang Tertinggi (Paling Besar)'),
                      ),
                      DropdownMenuItem(
                        value: SortirHutang.terendah,
                        child: Text('Hutang Terendah (Paling Kecil)'),
                      ),
                      DropdownMenuItem(
                        value: SortirHutang.abjad,
                        child: Text('Nama Toko (A - Z)'),
                      ),
                    ],
                    onChanged: (val) {
                      ref.read(sortirHutangProvider.notifier).state = val!;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DIALOG PEMILIHAN BULAN SPESIFIK ---
  void _showBulanPicker(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // Menyiapkan daftar 12 bulan terakhir untuk mempermudah pemilihan
    final List<DateTime> pastMonths = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
    final namaBulanPanjang = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Pilih Bulan Spesifik',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Batasi tinggi dialog agar bisa di-scroll
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pastMonths.length,
              itemBuilder: (ctx, i) {
                final date = pastMonths[i];
                final text = '${namaBulanPanjang[date.month - 1]} ${date.year}';

                return ListTile(
                  leading: const Icon(Icons.date_range, color: Colors.indigo),
                  title: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    // Update state dengan bulan yang dipilih dan tutup dialog
                    ref.read(bulanHutangProvider.notifier).state = date;
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- MUNCULKAN RINCIAN NOTA PER TOKO ---
  void _showDetailHutangToko(
    BuildContext context,
    int idToko,
    String namaToko,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Rincian Hutang: $namaToko',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final detailState = ref.watch(
                        detailHutangTokoProvider(idToko),
                      );

                      return detailState.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text('Gagal memuat rincian:\n$err')),
                        data: (rincianData) {
                          if (rincianData.isEmpty) {
                            return const Center(
                              child: Text('Tidak ada rincian data ditemukan.'),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: rincianData.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final item = rincianData[index];

                              final pencatatan =
                                  item['pencatatan'] as Map<String, dynamic>?;
                              final tglString = pencatatan?['tgl_pencatatan'];
                              final idNota =
                                  pencatatan?['id_pencatatan'] ?? '-';

                              String tglFormat = '-';
                              if (tglString != null) {
                                tglFormat = DateFormat(
                                  'dd MMM yyyy',
                                ).format(DateTime.parse(tglString));
                              }

                              final qty = item['qty'] as int;
                              final harga =
                                  (item['harga_pembelian_barang'] as num)
                                      .toDouble();
                              final subtotal = qty * harga;

                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nota ID: #$idNota',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$qty Item x ${AppFormatters.rupiah(harga)}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Tanggal: $tglFormat',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.rupiah(subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
