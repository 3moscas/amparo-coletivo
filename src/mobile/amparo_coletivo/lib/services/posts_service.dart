// lib/services/posts_service.dart
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class PostsService {
  static const String bucket = 'post_images';

  // ======================================================
  // UPLOAD DE IMAGEM
  // ======================================================
  static Future<String?> uploadPostImage({
    required Uint8List bytes,
    String? postId,
  }) async {
    try {
      final id = postId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'post_$id.jpg';

      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return fileName;
    } catch (e) {
      developer.log('Erro uploadPostImage: $e');
      return null;
    }
  }

  // ======================================================
  // DELETE IMAGE
  // ======================================================
  static Future<void> deleteImageIfExists(String? imagePathOrUrl) async {
    if (imagePathOrUrl == null || imagePathOrUrl.isEmpty) return;

    try {
      String filePath = imagePathOrUrl;

      if (filePath.contains('$bucket/')) {
        filePath = filePath.split('$bucket/').last;
      }

      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
      developer.log('Erro deleteImageIfExists: $e');
    }
  }

  // ======================================================
  // CREATE POST
  // ======================================================
  Future<void> createPost({
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    try {
      await _supabase.from('posts').insert({
        'title': title,
        'content': content,
        'ong_id': ongId,
        'image_url': imageUrl,
      });
    } catch (e) {
      developer.log('Erro createPost: $e');
      rethrow;
    }
  }

  // ======================================================
  // UPDATE POST
  // ======================================================
  Future<void> updatePost({
    required String id,
    required String title,
    required String content,
    required String ongId,
    String? imageUrl,
  }) async {
    try {
      await _supabase.from('posts').update({
        'title': title,
        'content': content,
        'ong_id': ongId,
        'image_url': imageUrl,
      }).eq('id', id);
    } catch (e) {
      developer.log('Erro updatePost: $e');
      rethrow;
    }
  }

  // ======================================================
  // DELETE POST
  // ======================================================
  Future<void> deletePost(String id) async {
    try {
      await _supabase.from('posts').delete().eq('id', id);
    } catch (e) {
      developer.log('Erro deletePost: $e');
      rethrow;
    }
  }

  // ======================================================
  // LISTAR POSTS DA ONG
  // ======================================================
  Future<List<Map<String, dynamic>>> listPostsByOng(String ongId) async {
    try {
      final res = await _supabase.from('posts').select('''
        id,
        title,
        content,
        created_at,
        image_url,
        ong_id,
        post_likes(count),
        post_comments(count)
      ''').eq('ong_id', ongId).order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);

      return list.map((post) {
        final path = post['image_url'];
        if (path != null && path.toString().isNotEmpty) {
          post['image_url'] = _supabase.storage.from(bucket).getPublicUrl(path);
        }

        post['likes_count'] =
            post['post_likes'] != null && post['post_likes'].isNotEmpty
                ? post['post_likes'][0]['count']
                : 0;

        post['comments_count'] =
            post['post_comments'] != null && post['post_comments'].isNotEmpty
                ? post['post_comments'][0]['count']
                : 0;

        return post;
      }).toList();
    } catch (e) {
      developer.log('Erro listPostsByOng: $e');
      return [];
    }
  }

  // ======================================================
  // LIKES
  // ======================================================
  Future<bool> hasUserLiked(String postId, String userId) async {
    try {
      final res = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .limit(1);

      return res.isNotEmpty;
    } catch (e) {
      developer.log('Erro hasUserLiked: $e');
      return false;
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      await _supabase.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } catch (e) {
      developer.log('Erro likePost: $e');
      rethrow;
    }
  }

  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (e) {
      developer.log('Erro unlikePost: $e');
      rethrow;
    }
  }

  // ======================================================
  // COMMENTS
  // ======================================================
  Future<void> createComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      const uuid = Uuid();
      final commentId = uuid.v4();

      final res = await _supabase.from('post_comments').insert({
        'id': commentId,
        'post_id': postId,
        'user_id': userId,
        'comment': content,
      }).select();

      developer.log('Comentário inserido: $res');
    } catch (e) {
      developer.log('Erro createComment: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> listComments(String postId,
      {int limit = 50}) async {
    try {
      final commentsRes = await _supabase
          .from('post_comments')
          .select('id, comment, created_at, user_id')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(limit);

      final List<Map<String, dynamic>> comments =
          List<Map<String, dynamic>>.from(commentsRes);

      if (comments.isEmpty) return [];

      // IDs de usuários
      final userIds = comments.map((c) => c['user_id'] as String).toList();

      // Buscar usuários corretamente usando filter 'in' com lista
      final usersRes = await _supabase
          .from('usuarios')
          .select('id, first_name, last_name, avatar_url')
          .filter('id', 'in', userIds); // <-- CORREÇÃO

      final users = List<Map<String, dynamic>>.from(usersRes);

      final Map<String, Map<String, dynamic>> userMap = {
        for (var u in users) u['id']: u,
      };

      return comments.map((c) {
        final user = userMap[c['user_id']];
        return {
          'id': c['id'],
          'comment': c['comment'],
          'created_at': c['created_at'],
          'usuarios': user,
        };
      }).toList();
    } catch (e) {
      developer.log('Erro listComments: $e');
      return [];
    }
  }
}
