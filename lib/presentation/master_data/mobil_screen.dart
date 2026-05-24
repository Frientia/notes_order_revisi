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
          if (listMobil.isEmpty)
            return const Center(child: Text('Belum ada data mobil.'));
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
                  title: Text(
                    mobil.noPlat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  // UPDATE: Ambil value dari enum menggunakan .label
                  subtitle: Text(
                    '${mobil.kategori?.label ?? 'Tanpa Kategori'} | Tahun: ${mobil.tahun ?? '-'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showFormBottomSheet(context, ref, mobil: mobil),
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
        content: Text(
          'Yakin ingin menghapus mobil dengan plat ${mobil.noPlat}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(mobilControllerProvider.notifier)
                  .deleteMobil(mobil.idMobil!);
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
    MobilModel? mobil,
  }) {
    final isEdit = mobil != null;
    final platCtrl = TextEditingController(text: mobil?.noPlat);
    final tahunCtrl = TextEditingController(
      text: mobil?.tahun?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    MobilKategori? selectedKategori = mobil?.kategori;
    bool isSubmitting = false; // Tambahan: state untuk efek loading pada tombol

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Ubah penamaan context di sini agar tidak bentrok dengan context halaman
      builder: (sheetContext) => StatefulBuilder(
        builder: (BuildContext innerContext, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(innerContext).viewInsets.bottom,
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
                    isEdit ? 'Edit Mobil' : 'Tambah Mobil Baru',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: platCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'No. Plat (Contoh: B 1234 CD)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val!.isEmpty ? 'No. Plat wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<MobilKategori>(
                    value: selectedKategori,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: MobilKategori.values.map((kategori) {
                      return DropdownMenuItem(
                        value: kategori,
                        child: Text(kategori.label),
                      );
                    }).toList(),
                    onChanged: (MobilKategori? newValue) {
                      setModalState(() {
                        selectedKategori = newValue;
                      });
                    },
                    validator: (val) =>
                        val == null ? 'Kategori wajib dipilih' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: tahunCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tahun Kendaraan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // Jika sedang loading, tombol di-disable (null)
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              // Ubah state jadi loading agar tombol memutar indikator
                              setModalState(() {
                                isSubmitting = true;
                              });

                              final newMobil = MobilModel(
                                idMobil: mobil?.idMobil,
                                noPlat: platCtrl.text.trim().toUpperCase(),
                                kategori: selectedKategori,
                                tahun: int.tryParse(tahunCtrl.text.trim()),
                              );

                              try {
                                if (isEdit) {
                                  await ref
                                      .read(mobilControllerProvider.notifier)
                                      .updateMobil(newMobil);
                                } else {
                                  await ref
                                      .read(mobilControllerProvider.notifier)
                                      .addMobil(newMobil);
                                }

                                // PENTING: Gunakan innerContext untuk menutup bottom sheet
                                if (innerContext.mounted) {
                                  Navigator.pop(innerContext);
                                }
                              } catch (e) {
                                // Jika gagal, matikan loading agar user bisa coba lagi
                                setModalState(() {
                                  isSubmitting = false;
                                });

                                final errMsg = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                                if (innerContext.mounted) {
                                  ScaffoldMessenger.of(
                                    innerContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(errMsg),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                    // Tampilkan indikator loading atau teks biasa
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Mobil'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
