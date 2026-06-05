import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/providers/riwayat_provider_boss.dart';
import '../../domain/providers/rekap_hutang_provider.dart';
import '../../core/utils/formatters.dart';

class RiwayatScreenBoss extends ConsumerStatefulWidget {
  const RiwayatScreenBoss({super.key});

  @override
  ConsumerState<RiwayatScreenBoss> createState() => _RiwayatScreenBossState();
}

class _RiwayatScreenBossState extends ConsumerState<RiwayatScreenBoss> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(searchRiwayatProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riwayatState = ref.watch(riwayatFilteredProvider);
    final filterWaktu = ref.watch(filterWaktuRiwayatProvider);
    final customTanggal = ref.watch(filterTanggalCustomProvider);

    // Menghitung jumlah filter lanjutan yang aktif
    int activeAdvancedFilters = 0;
    if (ref.watch(filterKategoriBarangProvider) != null)activeAdvancedFilters++;
    if (ref.watch(filterKategoriMobilProvider) != null) activeAdvancedFilters++;
    if (ref.watch(filterPetugasProvider) != null) activeAdvancedFilters++;
    if (ref.watch(filterNamaBarangProvider) != null) activeAdvancedFilters++;
    if (ref.watch(filterNoPlatProvider) != null) activeAdvancedFilters++;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // --- HEADER & SEARCH BAR ---
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.blueGrey[900],
              foregroundColor: Colors.white,
              expandedHeight: 140,
              title: const Text(
                'Riwayat Transaksi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filter Lanjutan',
                      onPressed: () => _showAdvancedFilter(context, ref),
                    ),
                    if (activeAdvancedFilters > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$activeAdvancedFilters',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        ref.read(searchRiwayatProvider.notifier).state = val,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Cari barang, nopol, atau petugas...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- FILTER WAKTU (QUICK FILTERS - DIURUTKAN ULANG) ---
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        ref,
                        'Hari Ini',
                        FilterWaktu.hariIni,
                        filterWaktu,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        '7 Hari Terakhir',
                        FilterWaktu.mingguIni,
                        filterWaktu,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        'Bulan Ini',
                        FilterWaktu.bulanIni,
                        filterWaktu,
                      ),
                      const SizedBox(width: 8),

                      // --- TOMBOL PILIH TANGGAL (KALENDER) ---
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              customTanggal != null &&
                                      filterWaktu == FilterWaktu.pilihTanggal
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(customTanggal)
                                  : 'Pilih Tanggal',
                            ),
                          ],
                        ),
                        selected: filterWaktu == FilterWaktu.pilihTanggal,
                        selectedColor: Colors.indigo.shade100,
                        onSelected: (_) async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: customTanggal ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            ref
                                    .read(filterTanggalCustomProvider.notifier)
                                    .state =
                                pickedDate;
                            ref
                                    .read(filterWaktuRiwayatProvider.notifier)
                                    .state =
                                FilterWaktu.pilihTanggal;
                          }
                        },
                      ),

                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        ref,
                        'Semua Waktu',
                        FilterWaktu.semua,
                        filterWaktu,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- KARTU TOTAL PENGELUARAN ---
            SliverToBoxAdapter(
              child: riwayatState.when(
                data: (data) {
                  final totalBelanja = data.fold<double>(
                    0,
                    (sum, item) => sum + item.subtotal,
                  );
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade700,
                            Colors.indigo.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pengeluaran (Periode Filter)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.rupiah(totalBelanja),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${data.length} Transaksi Tercatat',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),

            // --- DAFTAR TRANSAKSI ---
            riwayatState.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Terjadi Kesalahan:\n$err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada riwayat transaksi.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = data[index];
                    final tglFormat = DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(item.tanggal);
                    final isLunas =
                        item.status == 'LUNAS' || item.status == 'SELESAI';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showKwitansiDialog(context, ref, item),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'NOTA #${item.idNota} • $tglFormat',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLunas
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isLunas ? 'LUNAS' : 'HUTANG',
                                      style: TextStyle(
                                        color: isLunas
                                            ? Colors.green
                                            : Colors.orange.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item.namaBarang,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.store,
                                    item.namaToko,
                                    Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    Icons.directions_car,
                                    item.nopolMobil,
                                    Colors.teal,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.grey[200],
                                        child: const Icon(
                                          Icons.person,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.namaPetugas,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.qty} x ${AppFormatters.rupiah(item.harga)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.rupiah(item.subtotal),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: data.length),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    FilterWaktu value,
    FilterWaktu currentValue,
  ) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.indigo.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo.shade900 : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) =>
          ref.read(filterWaktuRiwayatProvider.notifier).state = value,
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM SHEET FILTER LANJUTAN (Kombinasi Dinamis & Hierarki) ---
  void _showAdvancedFilter(BuildContext context, WidgetRef ref) {
    final rawData = ref.read(riwayatDataProvider).value ?? [];

    // Ekstraksi nilai Kategori & Petugas (selalu statis dari seluruh data)
    final List<String> listKatBarang =
        rawData.map((e) => e.kategoriBarang).toSet().toList()..sort();
    final List<String> listKatMobil =
        rawData.map((e) => e.kategoriMobil).toSet().toList()..sort();
    final List<String> listPetugas =
        rawData.map((e) => e.namaPetugas).toSet().toList()..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            // Pantau State saat ini
            final selKatBarang = ref.watch(filterKategoriBarangProvider);
            final selKatMobil = ref.watch(filterKategoriMobilProvider);
            final selNamaBarang = ref.watch(filterNamaBarangProvider);
            final selNoPlat = ref.watch(filterNoPlatProvider);
            final selPetugas = ref.watch(filterPetugasProvider);

            // List Dinamis: Barang dan Plat akan tersaring otomatis mengikuti Kategori yang dipilih atasnya
            final listNamaBarang =
                rawData
                    .where(
                      (e) =>
                          selKatBarang == null ||
                          e.kategoriBarang == selKatBarang,
                    )
                    .map((e) => e.namaBarang)
                    .toSet()
                    .toList()
                  ..sort();

            final listNoPlat =
                rawData
                    .where(
                      (e) =>
                          selKatMobil == null || e.kategoriMobil == selKatMobil,
                    )
                    .map((e) => e.nopolMobil)
                    .toSet()
                    .toList()
                  ..sort();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
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
                      const Text(
                        'Filter Lanjutan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 16),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 1. Dropdown Kategori Barang
                            const Text(
                              'Kategori Barang',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: selKatBarang,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua Kategori Barang'),
                                ),
                                ...listKatBarang.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                        .read(
                                          filterKategoriBarangProvider.notifier,
                                        )
                                        .state =
                                    val;
                                ref
                                        .read(filterNamaBarangProvider.notifier)
                                        .state =
                                    null; // Auto-reset barang jika kategori berubah
                              },
                            ),
                            const SizedBox(height: 16),

                            // 2. Dropdown Nama Barang (Dinamis bergantung Kategori Barang)
                            const Text(
                              'Nama Barang',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: selNamaBarang,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    selKatBarang == null
                                        ? 'Semua Barang'
                                        : 'Semua Barang di Kategori Ini',
                                  ),
                                ),
                                ...listNamaBarang.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  ref
                                          .read(
                                            filterNamaBarangProvider.notifier,
                                          )
                                          .state =
                                      val,
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),

                            // 3. Dropdown Kategori Mobil
                            const Text(
                              'Kategori Mobil',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: selKatMobil,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua Kategori Mobil'),
                                ),
                                ...listKatMobil.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                        .read(
                                          filterKategoriMobilProvider.notifier,
                                        )
                                        .state =
                                    val;
                                ref.read(filterNoPlatProvider.notifier).state =
                                    null; // Auto-reset plat jika kategori berubah
                              },
                            ),
                            const SizedBox(height: 16),

                            // 4. Dropdown No Plat Mobil (Dinamis bergantung Kategori Mobil)
                            const Text(
                              'No Plat Mobil',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: selNoPlat,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    selKatMobil == null
                                        ? 'Semua Plat Mobil'
                                        : 'Semua Plat di Kategori Ini',
                                  ),
                                ),
                                ...listNoPlat.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  ref
                                          .read(filterNoPlatProvider.notifier)
                                          .state =
                                      val,
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),

                            // 5. Dropdown Petugas
                            const Text(
                              'Nama Petugas',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String?>(
                              value: selPetugas,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua Petugas'),
                                ),
                                ...listPetugas.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  ref
                                          .read(filterPetugasProvider.notifier)
                                          .state =
                                      val,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Tombol Reset
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          onPressed: () {
                            ref
                                    .read(filterKategoriBarangProvider.notifier)
                                    .state =
                                null;
                            ref.read(filterNamaBarangProvider.notifier).state =
                                null;
                            ref
                                    .read(filterKategoriMobilProvider.notifier)
                                    .state =
                                null;
                            ref.read(filterNoPlatProvider.notifier).state =
                                null;
                            ref.read(filterPetugasProvider.notifier).state =
                                null;
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset Filter'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // --- POP-UP DETAIL & KWITANSI ---
  void _showKwitansiDialog(
    BuildContext context,
    WidgetRef ref,
    RiwayatTransaksi item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  _detailRow(
                    'ID Nota / Detail:',
                    '#${item.idNota} / #${item.idDetail}',
                  ),
                  _detailRow(
                    'Tanggal:',
                    DateFormat('dd MMM yyyy, HH:mm').format(item.tanggal),
                  ),
                  _detailRow(
                    'Barang:',
                    '${item.namaBarang} (${item.kategoriBarang})',
                    isBold: true,
                  ),
                  _detailRow('Toko:', item.namaToko),
                  _detailRow(
                    'Mobil:',
                    '${item.nopolMobil} (${item.kategoriMobil})',
                  ),
                  _detailRow('Petugas:', item.namaPetugas),
                  _detailRow(
                    'Status:',
                    item.status == 'PENDING' ? 'HUTANG' : 'LUNAS',
                    color: item.status == 'PENDING'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppFormatters.rupiah(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Bukti Kwitansi:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final urlState = ref.watch(
                        urlKwitansiProvider(item.idNota),
                      );

                      return urlState.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, stack) => const Center(
                          child: Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        data: (url) {
                          if (url == null || url.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Petugas tidak mengupload foto kwitansi.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[900],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold || color != null
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
