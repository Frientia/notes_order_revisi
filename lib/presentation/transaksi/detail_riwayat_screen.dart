import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/riwayat_repository.dart';
import '../../core/utils/formatters.dart';

class DetailRiwayatScreen extends ConsumerWidget {
  final int idPencatatan;
  const DetailRiwayatScreen({super.key, required this.idPencatatan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailRiwayatProvider(idPencatatan));
    final primaryColor = const Color(0xFF1E3A5F);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 120,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Detail Transaksi #$idPencatatan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          detailAsync.when(
            data: (listDetail) {
              if (listDetail.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Detail Tidak Ditemukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text('Data rincian untuk transaksi ini kosong.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = listDetail[index];
                      final isSelesai = item.status == 'SELESAI';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.namaBarang,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelesai ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSelesai ? Colors.green.shade200 : Colors.orange.shade200),
                                  ),
                                  child: Text(
                                    isSelesai ? 'LUNAS' : 'HUTANG',
                                    style: TextStyle(
                                      color: isSelesai ? Colors.green.shade700 : Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.store, size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.namaToko,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.directions_car, size: 16, color: Colors.blue.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.noPlatMobil,
                                            style: TextStyle(fontSize: 13, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Kuantitas', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text('${item.qty} Unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Harga Satuan', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(AppFormatters.rupiah(item.hargaPembelian), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Subtotal', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppFormatters.rupiah(item.subtotal),
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                                      ),
                                    ],
                                  ),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onPressed: () => _showImageDialog(context, item.imgKwitansi),
                                    icon: const Icon(Icons.receipt_long, size: 18),
                                    label: const Text('Kwitansi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    childCount: listDetail.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: primaryColor))),
            error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Terjadi kesalahan: $error'))),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String? imgUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bukti Kwitansi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                        child: Icon(Icons.close, size: 18, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              if (imgUrl == null || imgUrl.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada gambar kwitansi.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Padding(
                          padding: EdgeInsets.all(60),
                          child: CircularProgressIndicator(color: const Color(0xFF1E3A5F)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Gagal memuat gambar.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}