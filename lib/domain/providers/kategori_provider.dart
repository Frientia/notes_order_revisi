import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/kategori_model.dart';
import '../../data/repositories/kategori_repository.dart';

final kategoriRepositoryProvider = Provider<KategoriRepository>((ref) {
  return KategoriRepository(Supabase.instance.client);
});

final kategoriBarangProvider = FutureProvider<List<KategoriModel>>((ref) async {
  final repo = ref.watch(kategoriRepositoryProvider);
  return await repo.getKategori('kategori_barang');
});

final kategoriMobilProvider = FutureProvider<List<KategoriModel>>((ref) async {
  final repo = ref.watch(kategoriRepositoryProvider);
  return await repo.getKategori('kategori_mobil');
});