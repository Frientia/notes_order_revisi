import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/barang_model.dart';
import '../../domain/providers/barang_provider.dart';

class BarangScreen extends ConsumerWidget {
  const BarangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau state barang dari Controller
    final barangState = ref.watch(barangControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Barang'),
      ),
      body: barangState.when(
        data: (listBarang) {
          if (listBarang.isEmpty) {
            return const Center(child: Text('Belum ada data barang.'));
          }
          return ListView.builder(
            itemCount: listBarang.length,
            itemBuilder: (context, index) {
              final barang = listBarang[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(barang.namaBarang[0].toUpperCase()),
                  ),
                  title: Text(barang.namaBarang, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Kategori: ${barang.kategori ?? '-'} | Stok: ${barang.stock}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormBottomSheet(context, ref, barang: barang),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, barang),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Terjadi kesalahan: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormBottomSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Fungsi untuk memunculkan konfirmasi hapus
  void _confirmDelete(BuildContext context, WidgetRef ref, BarangModel barang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Yakin ingin menghapus ${barang.namaBarang}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(barangControllerProvider.notifier).deleteBarang(barang.idBarang!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk memunculkan form Tambah/Edit (BottomSheet)
  void _showFormBottomSheet(BuildContext context, WidgetRef ref, {BarangModel? barang}) {
    final isEdit = barang != null;
    final namaCtrl = TextEditingController(text: barang?.namaBarang);
    final kategoriCtrl = TextEditingController(text: barang?.kategori);
    final stockCtrl = TextEditingController(text: barang?.stock.toString() ?? '0');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar form tidak tertutup keyboard
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Barang' : 'Tambah Barang Baru',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Barang', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kategoriCtrl,
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok Awal', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.square(50), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newBarang = BarangModel(
                      idBarang: barang?.idBarang,
                      namaBarang: namaCtrl.text.trim(),
                      kategori: kategoriCtrl.text.trim(),
                      stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
                    );

                    try {
                      if (isEdit) {
                        await ref.read(barangControllerProvider.notifier).updateBarang(newBarang);
                      } else {
                        await ref.read(barangControllerProvider.notifier).addBarang(newBarang);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Barang'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}