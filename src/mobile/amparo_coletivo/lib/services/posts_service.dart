import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class PostsService {
  // --------------------------------------------------------------------------
  // UPLOAD DE IMAGEM (WEB + MOBILE)
  // --------------------------------------------------------------------------
  static Future<String?> uploadPostImage({
    required Uint8List bytes,
    String? postId,
  }) async {
    try {
      final id = postId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = "post_$id.jpg";

      await supabase.storage.from('posts').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: "image/jpeg"),
          );

      final imageUrl = supabase.storage.from('posts').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print("Erro ao fazer upload da imagem: $e");
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // APAGAR IMAGEM ANTIGA SE EXISTIR
  // --------------------------------------------------------------------------
  static Future<void> deleteImageIfExists(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      if (!segments.contains("posts")) return;

      final index = segments.indexOf("posts");
      final fileName = segments.sublist(index + 1).join("/");

      if (fileName.isEmpty) return;

      await supabase.storage.from("posts").remove([fileName]);
    } catch (e) {
      print("Erro ao apagar imagem antiga: $e");
    }
  }

  // --------------------------------------------------------------------------
  // CRIAR POST
  // --------------------------------------------------------------------------
  Future<void> createPost({
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    try {
      await supabase.from('posts').insert({
        'title': title,
        'content': content,
        'ong_id': ongId,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Erro ao criar post: $e");
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // ATUALIZAR POST
  // --------------------------------------------------------------------------
  Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    try {
      await supabase.from('posts').update({
        'title': title,
        'content': content,
        'ong_id': ongId,
        'image_url': imageUrl,
      }).eq('id', id);
    } catch (e) {
      print("Erro ao atualizar post: $e");
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // DELETAR POST
  // --------------------------------------------------------------------------
  Future<void> deletePost(String id) async {
    try {
      await supabase.from('posts').delete().eq('id', id);
    } catch (e) {
      print("Erro ao deletar post: $e");
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // LISTAR TODOS OS POSTS
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listAllPosts() async {
    try {
      final res = await supabase
          .from('posts')
          .select('id, title, content, image_url, created_at, ong_id')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Erro ao listar posts: $e");
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // LISTAR POSTS POR ONG
  // --------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> listPostsByOng(String ongId) async {
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('ong_id', ongId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Erro ao listar posts por ONG: $e");
      return [];
    }
  }
}
