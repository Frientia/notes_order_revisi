import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barang_model.dart';

final barangRepositoryProvider = Provider<BarangRepository>((ref) {
  return BarangRepository(Supabase.instance.client);
});

class BarangRepository {
  final SupabaseClient _supabase;

  BarangRepository(this._supabase);

  Future<List<BarangModel>> getBarang() async {
    final response = await _supabase
        .from('barang')
        .select()
        .order('nama_barang', ascending: true);
    
    return response.map((e) => BarangModel.fromJson(e)).toList();
  }

  Future<BarangModel> addBarang(BarangModel barang) async {
    final cekBarang = await _supabase.from('barang').select().eq('nama_barang', barang.namaBarang);
    if (cekBarang.isNotEmpty) throw Exception('Nama Barang sudah terdaftar!');

    final response = await _supabase
        .from('barang')
        .insert(barang.toJson())
        .select()
        .single();
    return BarangModel.fromJson(response);
  }

  Future<void> updateBarang(BarangModel barang) async {
    await _supabase
        .from('barang')
        .update(barang.toJson())
        .eq('id_barang', int.parse(barang.idBarang!));
  }

  // Parameter disinkronkan menggunakan String
  Future<void> deleteBarang(String idBarang) async {
    await _supabase
        .from('barang')
        .delete()
        .eq('id_barang', int.parse(idBarang));
  }
}