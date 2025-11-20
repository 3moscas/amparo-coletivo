import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

final supabase = Supabase.instance.client;

class PostsService {
  static const String bucket = "post_images"; // 🔥 ATUALIZADO

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

      await supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: "image/jpeg",
              upsert: true,
            ),
          );

      return fileName; // retorna somente o path (ex.: post_123.jpg)
    } catch (e) {
      developer.log("Erro ao fazer upload da imagem: $e");
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // APAGAR IMAGEM ANTIGA SE EXISTIR
  // --------------------------------------------------------------------------
  static Future<void> deleteImageIfExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      await supabase.storage.from(bucket).remove([imagePath]);
    } catch (e) {
      developer.log("Erro ao apagar imagem antiga: $e");
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
      developer.log("Erro ao criar post: $e");
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
      developer.log("Erro ao atualizar post: $e");
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
      developer.log("Erro ao deletar post: $e");
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

      final list = List<Map<String, dynamic>>.from(res);

      return list.map((post) {
        final path = post['image_url'];
        if (path != null && path != "") {
          post['image_url'] = supabase.storage.from(bucket).getPublicUrl(path);
        }
        return post;
      }).toList();
    } catch (e) {
      developer.log("Erro ao listar posts: $e");
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

      final list = List<Map<String, dynamic>>.from(res);

      return list.map((post) {
        final path = post['image_url'];
        if (path != null && path != "") {
          post['image_url'] = supabase.storage.from(bucket).getPublicUrl(path);
        }
        return post;
      }).toList();
    } catch (e) {
      developer.log("Erro ao listar posts por ONG: $e");
      return [];
    }
  }
}
