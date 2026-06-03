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
        data: _buildTokoList,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormBottomSheet(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTokoList(List<TokoModel> listToko) {
    if (listToko.isEmpty) {
      return const Center(child: Text('Belum ada data toko.'));
    }

    return ListView.builder(
      itemCount: listToko.length,
      itemBuilder: (context, index) {
        return _TokoListItem(toko: listToko[index]);
      },
    );
  }
}

class _TokoListItem extends ConsumerWidget {
  final TokoModel toko;

  const _TokoListItem({required this.toko});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.store, color: Colors.white),
        ),
        title: Text(
          toko.namaToko,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          '${toko.noTelp}\n${toko.alamat}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showFormBottomSheet(context, toko: toko),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref, toko),
            ),
          ],
        ),
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
              ref.read(tokoControllerProvider.notifier).deleteToko(toko.idToko!);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

void _showFormBottomSheet(BuildContext context, {TokoModel? toko}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TokoFormSheet(toko: toko),
  );
}

class _TokoFormSheet extends ConsumerStatefulWidget {
  final TokoModel? toko;

  const _TokoFormSheet({this.toko});

  @override
  ConsumerState<_TokoFormSheet> createState() => _TokoFormSheetState();
}

class _TokoFormSheetState extends ConsumerState<_TokoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaTokoCtrl;
  late final TextEditingController _telponCtrl;
  late final TextEditingController _alamatCtrl;

  @override
  void initState() {
    super.initState();
    _namaTokoCtrl = TextEditingController(text: widget.toko?.namaToko);
    _telponCtrl = TextEditingController(text: widget.toko?.noTelp);
    _alamatCtrl = TextEditingController(text: widget.toko?.alamat);
  }

  @override
  void dispose() {
    _namaTokoCtrl.dispose();
    _telponCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final newToko = TokoModel(
      idToko: widget.toko?.idToko,
      namaToko: _namaTokoCtrl.text.trim(),
      noTelp: _telponCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
    );

    try {
      if (widget.toko != null) {
        await ref.read(tokoControllerProvider.notifier).updateToko(newToko);
      } else {
        await ref.read(tokoControllerProvider.notifier).addToko(newToko);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String errorMessage) {
    if (!mounted) return;
    final sanitizedMessage = errorMessage.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sanitizedMessage), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.toko != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEdit ? 'Edit Toko' : 'Tambah Toko Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _namaTokoCtrl,
              label: 'Nama Toko',
              textCapitalization: TextCapitalization.words,
              validator: (val) => val!.isEmpty ? 'Nama toko wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _telponCtrl,
              label: 'Nomor Telepon',
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _alamatCtrl,
              label: 'Alamat Lengkap',
              maxLines: 3,
              validator: (val) => val!.isEmpty ? 'Alamat wajib diisi' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              onPressed: _submitForm,
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Simpan Toko',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Nomor telepon wajib diisi';
    if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Hanya boleh berisi angka';
    return null;
  }
}