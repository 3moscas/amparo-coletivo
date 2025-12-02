import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ong_model.dart';
import '../constants/app_constants.dart';

class OngService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buscar todas as ONGs
  Future<List<Ong>> getOngs() async {
    final response =
        await _supabase.from(AppConstants.ongsTable).select().order('title');

    return (response as List).map((json) => Ong.fromJson(json)).toList();
  }

  // Buscar ONG por ID
  Future<Ong> getOngById(String id) async {
    final response = await _supabase
        .from(AppConstants.ongsTable)
        .select()
        .eq('id', id)
        .single();

    return Ong.fromJson(response);
  }

  // Criar nova ONG
  Future<Ong> createOng(Ong ong) async {
    final response = await _supabase
        .from(AppConstants.ongsTable)
        .insert(ong.toJson())
        .select()
        .single();

    return Ong.fromJson(response);
  }

  // Atualizar ONG existente
  Future<Ong> updateOng(Ong ong) async {
    final response = await _supabase
        .from(AppConstants.ongsTable)
        .update(ong.toJson())
        .eq('id', ong.id)
        .select()
        .single();

    return Ong.fromJson(response);
  }

  // Deletar ONG
  Future<void> deleteOng(String id) async {
    await _supabase.from(AppConstants.ongsTable).delete().eq('id', id);
  }

  // Upload de imagem para o bucket (compatível com web)
  Future<String?> uploadImageBytes(Uint8List bytes, String fileName) async {
    try {
      // Faz o upload para o bucket 'ongsimages' com upsert para sobrescrever se existir
      await _supabase.storage.from('ongsimages').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Retorna a URL pública
      final url = _supabase.storage.from('ongsimages').getPublicUrl(fileName);

      return url;
    } catch (e) {
      print('Erro ao fazer upload: $e');
      rethrow; // Propaga o erro para mostrar na UI
    }
  }
}
