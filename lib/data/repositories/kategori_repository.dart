import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kategori_model.dart';

class KategoriRepository {
  final SupabaseClient _supabase;

  KategoriRepository(this._supabase);

  // Fungsi dinamis untuk mengambil data (Read)
  Future<List<KategoriModel>> getKategori(String tableName) async {
    try {
      final response = await _supabase
          .from(tableName)
          .select()
          .order('nama_kategori', ascending: true);
          
      return response.map((e) => KategoriModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Gagal memuat kategori dari $tableName: $e');
    }
  }

  // Fungsi dinamis untuk menambah data baru (Create)
  Future<KategoriModel> addKategori(String tableName, String namaKategori) async {
    try {
      // Insert dan langsung kembalikan data yang baru di-generate (termasuk ID-nya)
      final response = await _supabase
          .from(tableName)
          .insert({'nama_kategori': namaKategori})
          .select()
          .single();
          
      return KategoriModel.fromJson(response);
    } catch (e) {
      // Menangkap error jika ada nama kategori yang sama (Karena kolom UNIQUE)
      if (e.toString().contains('23505') || e.toString().contains('duplicate key')) {
        throw Exception('Kategori "$namaKategori" sudah ada di database!');
      }
      throw Exception('Gagal menyimpan kategori: $e');
    }
  }
}