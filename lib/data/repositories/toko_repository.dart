import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/toko_model.dart';

final tokoRepositoryProvider = Provider<TokoRepository>((ref) {
  return TokoRepository(Supabase.instance.client);
});

class TokoRepository {
  final SupabaseClient _supabase;

  TokoRepository(this._supabase);

  Future<List<TokoModel>> getToko() async {
    final response = await _supabase
        .from('toko')
        .select()
        .order('nama_toko', ascending: true);

    return response.map((e) => TokoModel.fromJson(e)).toList();
  }

  Future<TokoModel> addToko(TokoModel toko) async {
    // Mengecek apakah nama_toko sudah ada agar tidak error unique constraint / duplikat
    final cekToko = await _supabase
        .from('toko')
        .select()
        .eq('nama_toko', toko.namaToko);
    if (cekToko.isNotEmpty) throw Exception('Nama Toko sudah terdaftar!');

    final response = await _supabase
        .from('toko')
        .insert(toko.toJson())
        .select()
        .single();
    return TokoModel.fromJson(response);
  }

  Future<void> updateToko(TokoModel toko) async {
    await _supabase
        .from('toko')
        .update(toko.toJson())
        .eq('id_toko', toko.idToko!);
  }

  // Ubah String idToko menjadi int idToko
  Future<void> deleteToko(int idToko) async {
    await _supabase.from('toko').delete().eq('id_toko', idToko);
  }
}
