import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mobil_model.dart';
import '../../domain/providers/mobil_provider.dart';

class MobilScreen extends ConsumerWidget {
  const MobilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobilState = ref.watch(mobilControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data Mobil')),
      body: mobilState.when(
        data: (listMobil) {
          if (listMobil.isEmpty) return const Center(child: Text('Belum ada data mobil.'));
          return ListView.builder(
            itemCount: listMobil.length,
            itemBuilder: (context, index) {
              final mobil = listMobil[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.directions_car, color: Colors.white),
                  ),
                  title: Text(mobil.noPlat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('${mobil.kategori ?? 'Tanpa Kategori'} | Tahun: ${mobil.tahun ?? '-'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFormBottomSheet(context, ref, mobil: mobil),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, mobil),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormBottomSheet(context, ref),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MobilModel mobil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mobil'),
        content: Text('Yakin ingin menghapus mobil dengan plat ${mobil.noPlat}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              ref.read(mobilControllerProvider.notifier).deleteMobil(mobil.idMobil!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFormBottomSheet(BuildContext context, WidgetRef ref, {MobilModel? mobil}) {
    final isEdit = mobil != null;
    final platCtrl = TextEditingController(text: mobil?.noPlat);
    final kategoriCtrl = TextEditingController(text: mobil?.kategori);
    final tahunCtrl = TextEditingController(text: mobil?.tahun?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'Edit Mobil' : 'Tambah Mobil Baru',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: platCtrl,
                textCapitalization: TextCapitalization.characters, // Otomatis huruf besar
                decoration: const InputDecoration(labelText: 'No. Plat (Contoh: B 1234 CD)', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'No. Plat wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kategoriCtrl,
                decoration: const InputDecoration(labelText: 'Kategori (Truk/Pickup/Minibus)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: tahunCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tahun Kendaraan', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.square(50), padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newMobil = MobilModel(
                      idMobil: mobil?.idMobil,
                      noPlat: platCtrl.text.trim().toUpperCase(),
                      kategori: kategoriCtrl.text.trim(),
                      tahun: int.tryParse(tahunCtrl.text.trim()),
                    );

                    try {
                      if (isEdit) {
                        await ref.read(mobilControllerProvider.notifier).updateMobil(newMobil);
                      } else {
                        await ref.read(mobilControllerProvider.notifier).addMobil(newMobil);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      // Membersihkan pesan error jika ada awalan "Exception:"
                      final errMsg = e.toString().replaceAll('Exception: ', '');
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errMsg), backgroundColor: Colors.red));
                    }
                  }
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Mobil'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}