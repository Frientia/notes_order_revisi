import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/toko_model.dart';
import '../../domain/providers/toko_provider.dart';

class TokoScreen extends ConsumerWidget {
  const TokoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokoState = ref.watch(tokoControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data Toko')),
      body: tokoState.when(
        data: (listToko) {
          if (listToko.isEmpty)
            return const Center(child: Text('Belum ada data toko.'));
          return ListView.builder(
            itemCount: listToko.length,
            itemBuilder: (context, index) {
              final toko = listToko[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                        Colors.green,
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(
                    toko.namaToko,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${toko.noTelpon}\n${toko.alamat}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showFormBottomSheet(context, ref, toko: toko),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, toko),
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
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TokoModel toko) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Toko'),
        content: Text('Yakin ingin menghapus toko ${toko.namaToko}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(tokoControllerProvider.notifier)
                  .deleteToko(toko.idToko!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFormBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    TokoModel? toko,
  }) {
    final isEdit = toko != null;
    final namaTokoCtrl = TextEditingController(text: toko?.namaToko);
    final telponCtrl = TextEditingController(text: toko?.noTelpon);
    final alamatCtrl = TextEditingController(text: toko?.alamat);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true,
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
                isEdit ? 'Edit Toko' : 'Tambah Toko Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaTokoCtrl,
                textCapitalization:
                    TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Nama toko wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telponCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Nomor telepon wajib diisi';
                  if (!RegExp(r'^[0-9]+$').hasMatch(val))
                    return 'Hanya boleh berisi angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: alamatCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.square(50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Colors.green,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newToko = TokoModel(
                      idToko: toko!.idToko,
                      namaToko: namaTokoCtrl.text.trim(),
                      noTelpon: telponCtrl.text.trim(),
                      alamat: alamatCtrl.text.trim(),
                    );

                    try {
                      if (isEdit) {
                        await ref
                            .read(tokoControllerProvider.notifier)
                            .updateToko(newToko);
                      } else {
                        await ref
                            .read(tokoControllerProvider.notifier)
                            .addToko(newToko);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      final errMsg = e.toString().replaceAll('Exception: ', '');
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(errMsg),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  isEdit ? 'Simpan Perubahan' : 'Simpan Toko',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
