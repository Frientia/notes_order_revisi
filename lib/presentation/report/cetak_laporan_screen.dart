import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_order/domain/providers/cetak_laporan_provider.dart';
import 'package:notes_order/core/services/export_service.dart';
import 'package:notes_order/core/utils/formatters.dart';

class CetakLaporanScreen extends ConsumerWidget {
  const CetakLaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tglMulai = ref.watch(cetakTanggalMulaiProvider);
    final tglSelesai = ref.watch(cetakTanggalSelesaiProvider);
    final selStatus = ref.watch(cetakFilterStatusProvider);
    final selNoPlat = ref.watch(cetakFilterNoPlatProvider);

    final rawDataAsync = ref.watch(cetakRawDataProvider);
    final listFinalCetak = ref.watch(cetakFilteredDataProvider);

    final formatTeksTgl = DateFormat('dd MMM yyyy');
    final stringPeriode =
        "${formatTeksTgl.format(tglMulai)} - ${formatTeksTgl.format(tglSelesai)}";

    final double totalHargaCetak = listFinalCetak.fold(
      0,
      (sum, item) => sum + item.subtotal,
    );

    final List<String> listPlatUnik =
        rawDataAsync.value?.map((e) => e.nopolMobil).toSet().toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Pusat Pelaporan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfigurasi Dokumen Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tentukan parameter data yang ingin Anda konversikan ke file fisik.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.indigo, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rentang Waktu Evaluasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pilihTanggalFilter(
                              context,
                              ref,
                              isMulai: true,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dari Tanggal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTeksTgl.format(tglMulai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pilihTanggalFilter(
                              context,
                              ref,
                              isMulai: false,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sampai Tanggal',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTeksTgl.format(tglSelesai),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_alt, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Saringan Data Spesifik',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Status Pembayaran',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: selStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Semua Status (Lunas & Hutang)'),
                        ),
                        DropdownMenuItem(
                          value: 'SELESAI',
                          child: Text('Khusus LUNAS'),
                        ),
                        DropdownMenuItem(
                          value: 'PENDING',
                          child: Text('Khusus HUTANG PENDING'),
                        ),
                      ],
                      onChanged: (val) =>
                          ref.read(cetakFilterStatusProvider.notifier).state =
                              val,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Batasi Per Plat Mobil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: selNoPlat,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Semua Armada Operasional'),
                        ),
                        ...listPlatUnik.map(
                          (plat) =>
                              DropdownMenuItem(value: plat, child: Text(plat)),
                        ),
                      ],
                      onChanged: (val) =>
                          ref.read(cetakFilterNoPlatProvider.notifier).state =
                              val,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Pratinjau Jumlah Cetak',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Volume Item Antrean:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${listFinalCetak.length} Baris Transaksi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Akumulasi:',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        AppFormatters.rupiah(totalHargaCetak),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'Cetak PDF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: listFinalCetak.isEmpty
                          ? null
                          : () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sedang memproses unduhan PDF...',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );

                              final namaFile = await ExportService.cetakPdf(
                                data: listFinalCetak,
                                periode: stringPeriode,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.green[800],
                                    content: Text(
                                      'Berhasil memproses dokumen: $namaFile',
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      icon: const Icon(Icons.grid_on),
                      label: const Text(
                        'Ekspor Excel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: listFinalCetak.isEmpty
                          ? null
                          : () => ExportService.eksporExcel(
                              data: listFinalCetak,
                              periode: stringPeriode,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _pilihTanggalFilter(
    BuildContext context,
    WidgetRef ref, {
    required bool isMulai,
  }) async {
    final tglSkrg = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isMulai
          ? ref.read(cetakTanggalMulaiProvider)
          : ref.read(cetakTanggalSelesaiProvider),
      firstDate: DateTime(2023),
      lastDate: tglSkrg,
    );

    if (picked != null) {
      if (isMulai) {
        ref.read(cetakTanggalMulaiProvider.notifier).state = picked;
      } else {
        ref.read(cetakTanggalSelesaiProvider.notifier).state = picked;
      }
      ref.invalidate(cetakRawDataProvider);
    }
  }
}
