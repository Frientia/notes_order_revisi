import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mobil_model.dart';

final mobilRepositoryProvider = Provider<MobilRepository>((ref) {
  return MobilRepository(Supabase.instance.client);
});

class MobilRepository {
  final SupabaseClient _supabase;

  MobilRepository(this._supabase);

  Future<List<MobilModel>> getMobil() async {
    try {
      final response = await _supabase
          .from('mobil')
          .select('*, kategori_mobil(*)')
          .order('no_plat', ascending: true);

      return response.map((e) => MobilModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat master mobil: $e');
    }
  }

  Future<MobilModel> addMobil(MobilModel mobil) async {
    try {
      final response = await _supabase
          .from('mobil')
          .insert(mobil.toJson())
          .select()
          .single();
          
      return MobilModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('23505') || e.toString().contains('duplicate key')) {
        throw Exception('Nomor Plat sudah terdaftar! Gunakan plat lain.');
      }
      throw Exception('Gagal menambah mobil: $e');
    }
  }

  Future<void> updateMobil(MobilModel mobil) async {
    try {
      await _supabase
          .from('mobil')
          .update(mobil.toJson())
          .eq('id_mobil', mobil.idMobil!);
    } catch (e) {
      if (e.toString().contains('23505')) {
        throw Exception('Nomor Plat ini sudah dipakai oleh mobil lain!');
      }
      throw Exception('Gagal mengupdate mobil: $e');
    }
  }

  Future<void> deleteMobil(int idMobil) async {
    try {
      await _supabase
          .from('mobil')
          .delete()
          .eq('id_mobil', idMobil);
    } catch (e) {
      throw Exception('Gagal menghapus mobil: $e');
    }
  }
}