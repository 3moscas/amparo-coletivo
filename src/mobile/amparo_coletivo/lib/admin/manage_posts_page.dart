import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucket = "posts";

  // ----------------------------------------------------------
  // LISTAR TODOS OS POSTS
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> listAllPosts() async {
    final resp = await _supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(resp as List);
  }

  // ----------------------------------------------------------
  // LISTAR POSTS DE UMA ONG
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> listPostsByOng(String ongId) async {
    final resp = await _supabase
        .from('posts')
        .select()
        .eq('ong_id', ongId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(resp as List);
  }

  // ----------------------------------------------------------
  // CRIAR POST
  // ----------------------------------------------------------
  Future<void> createPost({
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    await _supabase.from('posts').insert({
      'title': title,
      'content': content,
      'ong_id': ongId,
      'image_url': imageUrl,
    });
  }

  // ----------------------------------------------------------
  // ATUALIZAR POST
  // ----------------------------------------------------------
  Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    await _supabase.from('posts').update({
      'title': title,
      'content': content,
      'ong_id': ongId,
      'image_url': imageUrl,
    }).eq('id', id);
  }

  // ----------------------------------------------------------
  // DELETAR POST
  // ----------------------------------------------------------
  Future<void> deletePost(String postId) async {
    await _supabase.from('posts').delete().eq('id', postId);
  }

  // ----------------------------------------------------------
  // UPLOAD DE IMAGEM
  // ----------------------------------------------------------
  static Future<String> uploadPostImage({
    required Uint8List bytes,
    String? postId,
  }) async {
    final id = postId ?? const Uuid().v4();

    final filePath = "post_$id.jpg";

    await _supabase.storage.from(bucket).uploadBinary(
          filePath,
          bytes,
          fileOptions:
              const FileOptions(contentType: "image/jpeg", upsert: true),
        );

    final url = _supabase.storage.from(bucket).getPublicUrl(filePath);
    return url;
  }

  // ----------------------------------------------------------
  // REMOVER IMAGEM DO STORAGE
  // ----------------------------------------------------------
  Future<void> removeFile(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    final fileName = imageUrl.split('/').last;
    await _supabase.storage.from(bucket).remove([fileName]);
  }
}
