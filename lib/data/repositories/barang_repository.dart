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
    try {
      final response = await _supabase
          .from('barang')
          .select('*, kategori_barang(*)')
          .order('nama_barang', ascending: true);
      
      return response.map((e) => BarangModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat master barang: $e');
    }
  }

  Future<List<BarangModel>> getBarangSesuaiMobil(int idMobil) async {
    try {
      final response = await _supabase
          .from('barang')
          .select('*, kategori_barang(*), barang_mobil!inner(*)') 
          .eq('barang_mobil.id_mobil', idMobil)
          .order('nama_barang', ascending: true);
          
      return response.map((e) => BarangModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Gagal memfilter barang: $e');
    }
  }

  Future<BarangModel> addBarang(BarangModel barang, {List<int> listIdMobilCocok = const []}) async {
    try {
      final response = await _supabase
          .from('barang')
          .insert(barang.toJson())
          .select()
          .single();
          
      final newBarang = BarangModel.fromJson(response);

      if (listIdMobilCocok.isNotEmpty && newBarang.idBarang != null) {
        final List<Map<String, dynamic>> relasiData = listIdMobilCocok.map((idMobil) => {
          'id_barang': newBarang.idBarang,
          'id_mobil': idMobil,
        }).toList();
        
        await _supabase.from('barang_mobil').insert(relasiData);
      }
      
      return newBarang;
    } catch (e) {
      if (e.toString().contains('23505') || e.toString().contains('duplicate key')) {
        throw Exception('Nama Barang sudah terdaftar! Gunakan nama lain.');
      }
      throw Exception('Gagal menambah barang: $e');
    }
  }

  Future<void> updateBarang(BarangModel barang, {List<int>? listIdMobilCocok}) async {
    try {
      await _supabase
          .from('barang')
          .update(barang.toJson())
          .eq('id_barang', barang.idBarang!);
          
      if (listIdMobilCocok != null) {
        await _supabase.from('barang_mobil').delete().eq('id_barang', barang.idBarang!);
        
        if (listIdMobilCocok.isNotEmpty) {
           final List<Map<String, dynamic>> relasiData = listIdMobilCocok.map((idMobil) => {
            'id_barang': barang.idBarang,
            'id_mobil': idMobil,
          }).toList();
          await _supabase.from('barang_mobil').insert(relasiData);
        }
      }
    } catch (e) {
       if (e.toString().contains('23505')) {
         throw Exception('Nama Barang ini sudah dipakai oleh barang lain!');
       }
       throw Exception('Gagal mengupdate barang: $e');
    }
  }

  Future<void> deleteBarang(int idBarang) async {
    try {
      await _supabase
          .from('barang')
          .delete()
          .eq('id_barang', idBarang);
    } catch (e) {
      throw Exception('Gagal menghapus barang: $e');
    }
  }
}